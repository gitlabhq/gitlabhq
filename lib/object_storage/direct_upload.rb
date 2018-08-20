module ObjectStorage
  #
  # The DirectUpload c;ass generates a set of presigned URLs
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

    attr_reader :credentials, :bucket_name, :object_name
    attr_reader :has_length, :maximum_size

    def initialize(credentials, bucket_name, object_name, has_length:, maximum_size: nil)
      unless has_length
        raise ArgumentError, 'maximum_size has to be specified if length is unknown' unless maximum_size
      end

      @credentials = credentials
      @bucket_name = bucket_name
      @object_name = object_name
      @has_length = has_length
      @maximum_size = maximum_size
    end

    def to_hash
      {
        Timeout: TIMEOUT,
        GetURL: get_url,
        StoreURL: store_url,
        DeleteURL: delete_url,
        MultipartUpload: multipart_upload_hash,
        CustomPutHeaders: true,
        PutHeaders: upload_options
      }.compact
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

    def provider
      credentials[:provider].to_s
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectGET.html
    def get_url
      connection.get_object_url(bucket_name, object_name, expire_at)
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
        query: { uploadId: upload_id, partNumber: part_number },
        headers: upload_options
      }, expire_at)
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadComplete.html
    def multipart_complete_url
      connection.signed_url({
        method: 'POST',
        bucket_name: bucket_name,
        object_name: object_name,
        query: { uploadId: upload_id },
        headers: { 'Content-Type' => 'application/xml' }
      }, expire_at)
    end

    # Implements https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadAbort.html
    def multipart_abort_url
      connection.signed_url({
        method: 'DELETE',
        bucket_name: bucket_name,
        object_name: object_name,
        query: { uploadId: upload_id }
      }, expire_at)
    end

    private

    def rounded_multipart_part_size
      # round multipart_part_size up to minimum_mulitpart_size
      (multipart_part_size + MINIMUM_MULTIPART_SIZE - 1) / MINIMUM_MULTIPART_SIZE * MINIMUM_MULTIPART_SIZE
    end

    def multipart_part_size
      maximum_size / number_of_multipart_parts
    end

    def number_of_multipart_parts
      [
        # round maximum_size up to minimum_mulitpart_size
        (maximum_size + MINIMUM_MULTIPART_SIZE - 1) / MINIMUM_MULTIPART_SIZE,
        MAXIMUM_MULTIPART_PARTS
      ].min
    end

    def aws?
      provider == 'AWS'
    end

    def requires_multipart_upload?
      aws? && !has_length
    end

    def upload_id
      return unless requires_multipart_upload?

      strong_memoize(:upload_id) do
        new_upload = connection.initiate_multipart_upload(bucket_name, object_name)
        new_upload.body["UploadId"]
      end
    end

    def expire_at
      strong_memoize(:expire_at) do
        Time.now + TIMEOUT + EXPIRE_OFFSET
      end
    end

    def upload_options
      { 'Content-Type' => 'application/octet-stream' }
    end

    def connection
      @connection ||= ::Fog::Storage.new(credentials)
    end
  end
end
