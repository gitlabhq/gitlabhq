# frozen_string_literal: true

# Set default values for object_store settings
class ObjectStoreSettings
  SUPPORTED_TYPES = %w[artifacts external_diffs lfs uploads packages dependency_proxy terraform_state pages
    ci_secure_files].freeze
  ALLOWED_OBJECT_STORE_OVERRIDES = %w[bucket enabled proxy_download cdn].freeze

  # To ensure the one Workhorse credential matches the Rails config, we
  # enforce consolidated settings on those accelerated
  # endpoints. Technically dependency_proxy and terraform_state fall
  # into this category, but they will likely be handled by Workhorse in
  # the future.
  #
  # ci_secure_files doesn't support Workhorse yet
  # (https://gitlab.com/gitlab-org/gitlab/-/issues/461124), and it was
  # introduced first as a storage-specific setting. To avoid breaking
  # consolidated settings for other object types, exclude it here.
  WORKHORSE_ACCELERATED_TYPES = SUPPORTED_TYPES - %w[pages ci_secure_files]

  # pages and ci_secure_files may be enabled but use legacy disk storage
  # we don't need to raise an error in that case
  ALLOWED_INCOMPLETE_TYPES = %w[pages ci_secure_files].freeze

  attr_accessor :settings

  # Legacy parser
  def self.legacy_parse(object_store, object_store_type)
    object_store ||= GitlabSettings::Options.build({})
    object_store['enabled'] = false if object_store['enabled'].nil?
    object_store['remote_directory'], object_store['bucket_prefix'] = split_bucket_prefix(
      object_store['remote_directory']
    )

    object_store['direct_upload'] = true

    object_store['proxy_download'] = false if object_store['proxy_download'].nil?
    object_store['storage_options'] ||= {}

    object_store
  end

  def self.split_bucket_prefix(bucket)
    return [nil, nil] unless bucket.present?

    # Strictly speaking, object storage keys are not Unix paths and
    # characters like '/' and '.' have no special meaning. But in practice,
    # we do treat them like paths, and somewhere along the line something or
    # somebody may turn '//' into '/' or try to resolve '/..'. To guard
    # against this we reject "bad" combinations of '/' and '.'.
    [%r{\A\.*/}, %r{/\.*/}, %r{/\.*\z}].each do |re|
      raise 'invalid bucket' if re.match(bucket)
    end

    bucket, prefix = bucket.split('/', 2)
    [bucket, prefix]
  end

  def self.enabled_endpoint_uris
    SUPPORTED_TYPES.filter_map do |type|
      section_setting = Gitlab.config.try(type)

      next unless section_setting && section_setting['enabled']

      object_store_setting = section_setting['object_store']

      next unless object_store_setting && object_store_setting['enabled']

      endpoint = object_store_setting.dig('connection', 'endpoint')

      next unless endpoint

      URI(endpoint)
    end.uniq
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
  # 3. direct_upload cannot be configured anymore.
  def parse!
    return unless use_consolidated_settings?

    main_config = settings['object_store']
    common_config = main_config.slice('enabled', 'connection', 'proxy_download', 'storage_options')

    # These are no longer configurable if common config is used
    common_config['direct_upload'] = true
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
      target_config['remote_directory'], target_config['bucket_prefix'] = self.class.split_bucket_prefix(
        target_config.delete('bucket')
      )
      target_config['consolidated_settings'] = true
      section['object_store'] = target_config
      # GitlabSettings::Options internally stores data as a Hash, but it also
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

    connection = settings.dig('object_store', 'connection')

    return false unless connection.present?

    WORKHORSE_ACCELERATED_TYPES.each do |store|
      section = settings.try(store)

      next unless section
      next unless section.dig('object_store', 'enabled')

      section_connection = section.dig('object_store', 'connection')

      # We can use consolidated settings if the main object store
      # connection matches the section-specific connection. This makes
      # it possible to automatically use consolidated settings as new
      # settings (such as ci_secure_files) get promoted to a supported
      # type. Omnibus defaults to an empty hash for the
      # section-specific connection.
      return false if section_connection.present? && section_connection.to_h != connection.to_h
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
