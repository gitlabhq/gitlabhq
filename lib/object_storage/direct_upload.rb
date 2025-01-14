# frozen_string_literal: true

module ObjectStorage
  #
  # The DirectUpload class generates a set of presigned URLs
  # that can be used to upload data to object storage from untrusted component: Workhorse, Runner?
  #
  # For Google it assumes that the platform supports variable Content-Length.
  #
  # For AWS it initiates Multipart Upload and presignes a set of part uploads.
  #   Class calculates the best part size to be able to upload up to asked maximum size.
  #   The number of generated parts will never go above 100,
  #   but we will always try to reduce amount of generated parts.
  #   The part size is rounded-up to 5MB.
  #
  class DirectUpload
    include Gitlab::Utils::StrongMemoize

    TIMEOUT = 4.hours
    EXPIRE_OFFSET = 15.minutes

    MAXIMUM_MULTIPART_PARTS = 100
    MINIMUM_MULTIPART_SIZE = 5.megabytes

    attr_reader :config, :credentials, :bucket_name, :object_name
    attr_reader :has_length, :maximum_size, :skip_delete

    def initialize(config, object_name, has_length:, maximum_size: nil, skip_delete: false)
      unless has_length
        raise ArgumentError, 'maximum_size has to be specified if length is unknown' unless maximum_size
      end

      @config = config
      @credentials = config.credentials
      @bucket_name = config.bucket
      @object_name = object_name
      @has_length = has_length
      @maximum_size = maximum_size
      @skip_delete = skip_delete
    end

    def to_hash
      {
        Timeout: TIMEOUT,
        GetURL: get_url,
        StoreURL: store_url,
        DeleteURL: delete_url,
        SkipDelete: skip_delete,
        MultipartUpload: multipart_upload_hash,
        CustomPutHeaders: true,
        PutHeaders: upload_options
      }.merge(workhorse_client_hash).compact
    end

    def multipart_upload_hash
      return unless requires_multipart_upload?

      {
        PartSize: rounded_multipart_part_size,
        PartURLs: multipart_part_urls,
        CompleteURL: multipart_complete_url,
        AbortURL: multipart_abort_url
      }
    end

    def workhorse_client_hash
      if config.aws?
        workhorse_aws_hash
      elsif config.azure?
        workhorse_azure_hash
      elsif config.google?
        workhorse_google_hash
      else
        {}
      end
    end

    def workhorse_aws_hash
      {
        UseWorkhorseClient: use_workhorse_s3_client?,
        RemoteTempObjectID: object_name,
        ObjectStorage: {
          Provider: 'AWS',
          S3Config: {
            Bucket: bucket_name,
            Region: credentials[:region] || ::Fog::AWS::Storage::DEFAULT_REGION,
            Endpoint: credentials[:endpoint],
            PathStyle: config.use_path_style?,
            UseIamProfile: config.use_iam_profile?,
            ServerSideEncryption: config.server_side_encryption,
            SSEKMSKeyID: config.server_side_encryption_kms_key_id,
            AwsSDK: "v2"
          }.compact
        }
      }
    end

    def workhorse_azure_hash
      {
        # Azure requires Workhorse client because direct uploads can't
        # use pre-signed URLs without buffering the whole file to disk.
        UseWorkhorseClient: true,
        RemoteTempObjectID: object_name,
        ObjectStorage: {
          Provider: 'AzureRM',
          GoCloudConfig: {
            URL: azure_gocloud_url
          }
        }
      }
    end

    def azure_gocloud_url
      url = "azblob://#{bucket_name}"
      url += "?domain=#{config.azure_storage_domain}" if config.azure_storage_domain.present?
      url
    end

    def workhorse_google_hash
      {
        UseWorkhorseClient: use_workhorse_google_client?,
        RemoteTempObjectID: object_name,
        ObjectStorage: {
          Provider: 'Google',
          GoCloudConfig: {
            URL: google_gocloud_url
          }
        }
      }
    end

    def google_gocloud_url
      "gs://#{bucket_name}"
    end

    def use_workhorse_s3_client?
      return false unless config.use_iam_profile? || config.consolidated_settings?
      # The Golang AWS SDK does not support V2 signatures
      return false unless credentials.fetch(:aws_signature_version, 4).to_i >= 4

      true
    end

    def use_workhorse_google_client?
      return false unless config.consolidated_settings?
      return true if credentials[:google_application_default]
      return true if credentials[:google_json_key_location]
      return true if credentials[:google_json_key_string]

      false
    end

    def provider
      credentials[:provider].to_s
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectGET.html
    def get_url
      if config.google?
        connection.get_object_https_url(bucket_name, object_name, expire_at)
      else
        connection.get_object_url(bucket_name, object_name, expire_at)
      end
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html
    def delete_url
      connection.delete_object_url(bucket_name, object_name, expire_at)
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUT.html
    def store_url
      connection.put_object_url(bucket_name, object_name, expire_at, upload_options)
    end

    def multipart_part_urls
      Array.new(number_of_multipart_parts) do |part_index|
        multipart_part_upload_url(part_index + 1)
      end
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadUploadPart.html
    def multipart_part_upload_url(part_number)
      connection.signed_url({
        method: 'PUT',
        bucket_name: bucket_name,
        object_name: object_name,
        query: { 'uploadId' => upload_id, 'partNumber' => part_number },
        headers: upload_options
      }, expire_at)
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadComplete.html
    def multipart_complete_url
      connection.signed_url({
        method: 'POST',
        bucket_name: bucket_name,
        object_name: object_name,
        query: { 'uploadId' => upload_id },
        headers: { 'Content-Type' => 'application/xml' }
      }, expire_at)
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadAbort.html
    def multipart_abort_url
      connection.signed_url({
        method: 'DELETE',
        bucket_name: bucket_name,
        object_name: object_name,
        query: { 'uploadId' => upload_id }
      }, expire_at)
    end

    private

    def rounded_multipart_part_size
      # round multipart_part_size up to minimum_multipart_size
      (multipart_part_size + MINIMUM_MULTIPART_SIZE - 1) / MINIMUM_MULTIPART_SIZE * MINIMUM_MULTIPART_SIZE
    end

    def multipart_part_size
      return MINIMUM_MULTIPART_SIZE if maximum_size == 0

      maximum_size / number_of_multipart_parts
    end

    def number_of_multipart_parts
      # If we don't have max length, we can only assume the file is as large as possible.
      return MAXIMUM_MULTIPART_PARTS if maximum_size == 0

      [
        # round maximum_size up to minimum_mulitpart_size
        (maximum_size + MINIMUM_MULTIPART_SIZE - 1) / MINIMUM_MULTIPART_SIZE,
        MAXIMUM_MULTIPART_PARTS
      ].min
    end

    def requires_multipart_upload?
      return false unless config.aws?
      return false if use_workhorse_s3_client?

      !has_length
    end

    def upload_id
      return unless requires_multipart_upload?

      strong_memoize(:upload_id) do
        new_upload = connection.initiate_multipart_upload(bucket_name, object_name, config.fog_attributes)
        new_upload.body["UploadId"]
      end
    end

    def expire_at
      strong_memoize(:expire_at) do
        Time.now + TIMEOUT + EXPIRE_OFFSET
      end
    end

    def upload_options
      {}
    end

    def connection
      @connection ||= ::Fog::Storage.new(credentials.to_hash)
    end
  end
end
