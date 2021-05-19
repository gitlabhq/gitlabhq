# frozen_string_literal: true

# Set default values for object_store settings
class ObjectStoreSettings
  SUPPORTED_TYPES = %w(artifacts external_diffs lfs uploads packages dependency_proxy terraform_state pages).freeze
  ALLOWED_OBJECT_STORE_OVERRIDES = %w(bucket enabled proxy_download).freeze

  # To ensure the one Workhorse credential matches the Rails config, we
  # enforce consolidated settings on those accelerated
  # endpoints. Technically dependency_proxy and terraform_state fall
  # into this category, but they will likely be handled by Workhorse in
  # the future.
  WORKHORSE_ACCELERATED_TYPES = SUPPORTED_TYPES - %w(pages)

  # pages may be enabled but use legacy disk storage
  # we don't need to raise an error in that case
  ALLOWED_INCOMPLETE_TYPES = %w(pages).freeze

  attr_accessor :settings

  # Legacy parser
  def self.legacy_parse(object_store)
    object_store ||= Settingslogic.new({})
    object_store['enabled'] = false if object_store['enabled'].nil?
    object_store['remote_directory'] ||= nil
    object_store['direct_upload'] = false if object_store['direct_upload'].nil?
    object_store['background_upload'] = true if object_store['background_upload'].nil?
    object_store['proxy_download'] = false if object_store['proxy_download'].nil?
    object_store['storage_options'] ||= {}

    # Convert upload connection settings to use string keys, to make Fog happy
    object_store['connection']&.deep_stringify_keys!
    object_store
  end

  def initialize(settings)
    @settings = settings
  end

  # This method converts the common object storage settings to
  # the legacy, internal representation.
  #
  # For example, with the folowing YAML:
  #
  # object_store:
  #   enabled: true
  #   connection:
  #     provider: AWS
  #     aws_access_key_id: minio
  #     aws_secret_access_key: gdk-minio
  #     region: gdk
  #     endpoint: 'http://127.0.0.1:9000'
  #     path_style: true
  #   storage_options:
  #     server_side_encryption: AES256
  #   proxy_download: true
  #   objects:
  #     artifacts:
  #       bucket: artifacts
  #       proxy_download: false
  #     lfs:
  #       bucket: lfs-objects
  #
  # This method then will essentially call:
  #
  # Settings.artifacts['object_store'] = {
  #   "enabled" => true,
  #   "connection" => {
  #     "provider" => "AWS",
  #     "aws_access_key_id" => "minio",
  #     "aws_secret_access_key" => "gdk-minio",
  #     "region" => "gdk",
  #     "endpoint" => "http://127.0.0.1:9000",
  #     "path_style" => true
  #   },
  #   "storage_options" => {
  #     "server_side_encryption" => "AES256"
  #   },
  #   "direct_upload" => true,
  #   "background_upload" => false,
  #   "proxy_download" => false,
  #   "remote_directory" => "artifacts"
  # }
  #
  # Settings.lfs['object_store'] = {
  #   "enabled" => true,
  #   "connection" => {
  #     "provider" => "AWS",
  #     "aws_access_key_id" => "minio",
  #     "aws_secret_access_key" => "gdk-minio",
  #     "region" => "gdk",
  #     "endpoint" => "http://127.0.0.1:9000",
  #     "path_style" => true
  #   },
  #   "storage_options" => {
  #     "server_side_encryption" => "AES256"
  #   },
  #   "direct_upload" => true,
  #   "background_upload" => false,
  #   "proxy_download" => true,
  #   "remote_directory" => "lfs-objects"
  # }
  #
  # Note that with the common config:
  # 1. Only one object store credentials can now be used. This is
  #    necessary to limit configuration overhead when an object storage
  #    client (e.g. AWS S3) is used inside GitLab Workhorse.
  # 2. However, a bucket has to be specified for each object
  #    type. Reusing buckets is not really supported, but we don't
  #    enforce that yet.
  # 3. direct_upload and background_upload cannot be configured anymore.
  def parse!
    return unless use_consolidated_settings?

    main_config = settings['object_store']
    common_config = main_config.slice('enabled', 'connection', 'proxy_download', 'storage_options')
    # Convert connection settings to use string keys, to make Fog happy
    common_config['connection']&.deep_stringify_keys!
    # These are no longer configurable if common config is used
    common_config['direct_upload'] = true
    common_config['background_upload'] = false
    common_config['storage_options'] ||= {}

    SUPPORTED_TYPES.each do |store_type|
      overrides = main_config.dig('objects', store_type) || {}
      target_config = common_config.merge(overrides.slice(*ALLOWED_OBJECT_STORE_OVERRIDES))
      section = settings.try(store_type)

      # Admins can selectively disable object storage for a specific
      # type as an override in the consolidated settings.
      next unless overrides.fetch('enabled', true)
      next unless section

      if section['enabled'] && target_config['bucket'].blank?
        missing_bucket_for(store_type)
        next
      end

      # If a storage type such as Pages defines its own connection and does not
      # use Workhorse acceleration, we allow it to override the consolidated form.
      next if allowed_storage_specific_settings?(store_type, section.to_h)

      # Map bucket (external name) -> remote_directory (internal representation)
      target_config['remote_directory'] = target_config.delete('bucket')
      target_config['consolidated_settings'] = true
      section['object_store'] = target_config
      # Settingslogic internally stores data as a Hash, but it also
      # creates a Settings object for every key. To avoid confusion, we should
      # update both so that Settings.artifacts and Settings['artifacts'] return
      # the same result.
      settings[store_type]['object_store'] = target_config
    end

    settings
  end

  private

  # We only can use the common object storage settings if:
  # 1. The common settings are defined
  # 2. The legacy settings are not defined
  def use_consolidated_settings?
    return false unless settings.dig('object_store', 'enabled')
    return false unless settings.dig('object_store', 'connection').present?

    WORKHORSE_ACCELERATED_TYPES.each do |store|
      # to_h is needed because we define `default` as a Gitaly storage name
      # in stub_storage_settings. This causes Settingslogic to redefine Hash#default,
      # which causes Hash#dig to fail when the key doesn't exist: https://gitlab.com/gitlab-org/gitlab/-/issues/286873
      #
      # (byebug) section.dig
      # *** ArgumentError Exception: wrong number of arguments (given 0, expected 1+)
      # (byebug) section.dig('object_store')
      # *** ArgumentError Exception: wrong number of arguments (given 1, expected 0)
      section = settings.try(store)&.to_h

      next unless section

      return false if section.dig('object_store', 'enabled')
      # Omnibus defaults to an empty hash
      return false if section.dig('object_store', 'connection').present?
    end

    true
  end

  def missing_bucket_for(store_type)
    message = "Object storage for #{store_type} must have a bucket specified"

    if ALLOWED_INCOMPLETE_TYPES.include?(store_type)
      warn "[WARNING] #{message}"
    else
      raise message
    end
  end

  def allowed_storage_specific_settings?(store_type, section)
    return false if WORKHORSE_ACCELERATED_TYPES.include?(store_type)

    has_object_store_configured?(section)
  end

  def has_object_store_configured?(section)
    # Omnibus defaults to an empty hash for connection
    section.dig('object_store', 'enabled') && section.dig('object_store', 'connection').present?
  end
end
