# frozen_string_literal: true

module ObjectStorage
  class Config
    AWS_PROVIDER = 'AWS'
    AZURE_PROVIDER = 'AzureRM'
    GOOGLE_PROVIDER = 'Google'

    attr_reader :options

    def initialize(options)
      @options = options.to_hash.deep_symbolize_keys
    end

    def load_provider
      if aws?
        require 'fog/aws'
      elsif google?
        require 'fog/google'
      elsif azure?
        require 'fog/azurerm'
      end
    end

    def credentials
      @credentials ||= options[:connection] || {}
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
        return {} unless enabled? && aws?
        return {} unless server_side_encryption.present?

        aws_server_side_encryption_headers.compact
      end
    end

    private

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
