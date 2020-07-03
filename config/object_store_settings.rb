# Set default values for object_store settings
class ObjectStoreSettings
  SUPPORTED_TYPES = %w(artifacts external_diffs lfs uploads packages dependency_proxy terraform_state).freeze
  ALLOWED_OBJECT_STORE_OVERRIDES = %w(bucket enabled proxy_download).freeze

  attr_accessor :settings

  # Legacy parser
  def self.legacy_parse(object_store)
    object_store ||= Settingslogic.new({})
    object_store['enabled'] = false if object_store['enabled'].nil?
    object_store['remote_directory'] ||= nil
    object_store['direct_upload'] = false if object_store['direct_upload'].nil?
    object_store['background_upload'] = true if object_store['background_upload'].nil?
    object_store['proxy_download'] = false if object_store['proxy_download'].nil?

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
  #   "connection"=> {
  #     "provider" => "AWS",
  #     "aws_access_key_id" => "minio",
  #     "aws_secret_access_key" => "gdk-minio",
  #     "region" => "gdk",
  #     "endpoint" => "http://127.0.0.1:9000",
  #     "path_style" => true
  #   },
  #   "direct_upload" => true,
  #   "background_upload" => false,
  #   "proxy_download" => false,
  #   "remote_directory" => "artifacts"
  #  }
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
  #   "direct_upload" => true,
  #   "background_upload" => false,
  #   "proxy_download" => true,
  #   "remote_directory" => "lfs-objects"
  #  }
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
    common_config = main_config.slice('enabled', 'connection', 'proxy_download')
    # Convert connection settings to use string keys, to make Fog happy
    common_config['connection']&.deep_stringify_keys!
    # These are no longer configurable if common config is used
    common_config['direct_upload'] = true
    common_config['background_upload'] = false

    SUPPORTED_TYPES.each do |store_type|
      overrides = main_config.dig('objects', store_type) || {}
      target_config = common_config.merge(overrides.slice(*ALLOWED_OBJECT_STORE_OVERRIDES))
      section = settings.try(store_type)

      next unless section

      raise "Object storage for #{store_type} must have a bucket specified" if section['enabled'] && target_config['bucket'].blank?

      # Map bucket (external name) -> remote_directory (internal representation)
      target_config['remote_directory'] = target_config.delete('bucket')
      target_config['consolidated_settings'] = true
      section['object_store'] = target_config
    end
  end

  private

  # We only can use the common object storage settings if:
  # 1. The common settings are defined
  # 2. The legacy settings are not defined
  def use_consolidated_settings?
    return false unless settings.dig('object_store', 'enabled')
    return false unless settings.dig('object_store', 'connection').present?

    SUPPORTED_TYPES.each do |store|
      # to_h is needed because something strange happens to
      # Settingslogic#dig when stub_storage_settings is run in tests:
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
end
