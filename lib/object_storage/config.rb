# frozen_string_literal: true

module ObjectStorage
  class Config
    AWS_PROVIDER = 'AWS'
    AZURE_PROVIDER = 'AzureRM'
    GOOGLE_PROVIDER = 'Google'

    LOCATIONS = {
      artifacts: Gitlab.config.artifacts,
      ci_secure_files: Gitlab.config.ci_secure_files,
      dependency_proxy: Gitlab.config.dependency_proxy,
      external_diffs: Gitlab.config.external_diffs,
      lfs: Gitlab.config.lfs,
      packages: Gitlab.config.packages,
      pages: Gitlab.config.pages,
      terraform_state: Gitlab.config.terraform_state,
      uploads: Gitlab.config.uploads
    }.freeze

    attr_reader :options

    def initialize(options)
      @options = options.to_hash.deep_symbolize_keys
    end

    def credentials
      @credentials ||= connection_params
    end

    def storage_options
      @storage_options ||= options[:storage_options] || {}
    end

    def enabled?
      options[:enabled]
    end

    def bucket
      options[:remote_directory]
    end

    def consolidated_settings?
      options.fetch(:consolidated_settings, false)
    end

    # AWS-specific options
    def aws?
      provider == AWS_PROVIDER
    end

    def use_iam_profile?
      Gitlab::Utils.to_boolean(credentials[:use_iam_profile], default: false)
    end

    def use_path_style?
      Gitlab::Utils.to_boolean(credentials[:path_style], default: false)
    end

    def server_side_encryption
      storage_options[:server_side_encryption]
    end

    def server_side_encryption_kms_key_id
      storage_options[:server_side_encryption_kms_key_id]
    end

    def provider
      credentials[:provider].to_s
    end
    # End AWS-specific options

    # Begin Azure-specific options
    def azure_storage_domain
      credentials[:azure_storage_domain]
    end
    # End Azure-specific options

    def google?
      provider == GOOGLE_PROVIDER
    end

    def azure?
      provider == AZURE_PROVIDER
    end

    def fog_attributes
      @fog_attributes ||= begin
        return {} unless aws_server_side_encryption_enabled?

        aws_server_side_encryption_headers.compact
      end
    end

    def aws_server_side_encryption_enabled?
      aws? && server_side_encryption.present?
    end

    private

    def connection_params
      base_params = options[:connection] || {}

      return base_params unless base_params[:provider].to_s == AWS_PROVIDER
      return base_params unless ::Gitlab::FIPS.enabled?

      # In fog-aws, this disables the use of Content-Md5: https://github.com/fog/fog-aws/pull/668
      base_params.merge({ disable_content_md5_validation: true })
    end

    # This returns a Hash of HTTP encryption headers to send along to S3.
    #
    # They can also be passed in as Fog::AWS::Storage::File attributes, since there
    # are aliases defined for them:
    # https://github.com/fog/fog-aws/blob/ab288f29a0974d64fd8290db41080e5578be9651/lib/fog/aws/models/storage/file.rb#L24-L25
    def aws_server_side_encryption_headers
      {
        'x-amz-server-side-encryption' => server_side_encryption,
        'x-amz-server-side-encryption-aws-kms-key-id' => server_side_encryption_kms_key_id
      }
    end
  end
end
