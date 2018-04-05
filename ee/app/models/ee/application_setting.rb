module EE
  # ApplicationSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `ApplicationSetting` model
  module ApplicationSetting
    extend ActiveSupport::Concern

    prepended do
      include IgnorableColumn

      EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT = 10_000

      ignore_column :minimum_mirror_sync_time

      validates :shared_runners_minutes,
                numericality: { greater_than_or_equal_to: 0 }

      validates :mirror_max_delay,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: :mirror_max_delay_in_minutes }

      validates :mirror_max_capacity,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validates :mirror_capacity_threshold,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validate :mirror_capacity_threshold_less_than

      validates :repository_size_limit,
                presence: true,
                numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      validates :elasticsearch_url,
                presence: { message: "can't be blank when indexing is enabled" },
                if: ->(setting) { setting.elasticsearch_indexing? }

      validates :elasticsearch_aws_region,
                presence: { message: "can't be blank when using aws hosted elasticsearch" },
                if: ->(setting) { setting.elasticsearch_indexing? && setting.elasticsearch_aws? }

      validates :email_additional_text,
                allow_blank: true,
                length: { maximum: EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT }

      validates :external_authorization_service_default_label,
                presence: true,
                if: :external_authorization_service_enabled?

      validates :external_authorization_service_url,
                url: true, allow_blank: true,
                if: :external_authorization_service_enabled?

      validates :external_authorization_service_timeout,
                numericality: { greater_than: 0, less_than_or_equal_to: 10 },
                if: :external_authorization_service_enabled?

      validates :external_auth_client_key,
                presence: true,
                if: -> (setting) { setting.external_auth_client_cert.present? }

      validates_with X509CertificateCredentialsValidator,
                     certificate: :external_auth_client_cert,
                     pkey: :external_auth_client_key,
                     pass: :external_auth_client_key_pass,
                     if: -> (setting) { setting.external_auth_client_cert.present? }

      attr_encrypted :external_auth_client_key,
                     mode: :per_attribute_iv,
                     key: ::Gitlab::Application.secrets.db_key_base,
                     algorithm: 'aes-256-gcm',
                     encode: true

      attr_encrypted :external_auth_client_key_pass,
                     mode: :per_attribute_iv,
                     key: ::Gitlab::Application.secrets.db_key_base,
                     algorithm: 'aes-256-gcm',
                     encode: true
    end

    module ClassMethods
      extend ::Gitlab::Utils::Override

      override :defaults
      def defaults
        super.merge(
          allow_group_owners_to_manage_ldap: true,
          default_project_creation: ::EE::Gitlab::Access::DEVELOPER_MASTER_PROJECT_ACCESS,
          elasticsearch_aws: false,
          elasticsearch_aws_region: ENV['ELASTIC_REGION'] || 'us-east-1',
          elasticsearch_url: ENV['ELASTIC_URL'] || 'http://localhost:9200',
          email_additional_text: nil,
          mirror_capacity_threshold: Settings.gitlab['mirror_capacity_threshold'],
          mirror_max_capacity: Settings.gitlab['mirror_max_capacity'],
          mirror_max_delay: Settings.gitlab['mirror_max_delay'],
          mirror_available: true,
          repository_size_limit: 0,
          slack_app_enabled: false,
          slack_app_id: nil,
          slack_app_secret: nil,
          slack_app_verification_token: nil
        )
      end
    end

    def should_check_namespace_plan?
      check_namespace_plan? && ::Gitlab.dev_env_or_com?
    end

    def elasticsearch_indexing
      return false unless elasticsearch_indexing_column_exists?

      License.feature_available?(:elastic_search) && super
    end
    alias_method :elasticsearch_indexing?, :elasticsearch_indexing

    def elasticsearch_search
      return false unless elasticsearch_search_column_exists?

      License.feature_available?(:elastic_search) && super
    end
    alias_method :elasticsearch_search?, :elasticsearch_search

    def elasticsearch_url
      read_attribute(:elasticsearch_url).split(',').map(&:strip)
    end

    def elasticsearch_url=(values)
      cleaned = values.split(',').map {|url| url.strip.gsub(%r{/*\z}, '') }

      write_attribute(:elasticsearch_url, cleaned.join(','))
    end

    def elasticsearch_config
      {
        url:                   elasticsearch_url,
        aws:                   elasticsearch_aws,
        aws_access_key:        elasticsearch_aws_access_key,
        aws_secret_access_key: elasticsearch_aws_secret_access_key,
        aws_region:            elasticsearch_aws_region
      }
    end

    def email_additional_text
      return false unless email_additional_text_column_exists?

      License.feature_available?(:email_additional_text) && super
    end

    def email_additional_text_character_limit
      EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT
    end

    def external_authorization_service_enabled
      License.feature_available?(:external_authorization_service) && super
    end
    alias_method :external_authorization_service_enabled?,
                 :external_authorization_service_enabled

    private

    def mirror_max_delay_in_minutes
      ::Gitlab::Mirror.min_delay_upper_bound / 60
    end

    def mirror_capacity_threshold_less_than
      return unless mirror_max_capacity && mirror_capacity_threshold

      if mirror_capacity_threshold > mirror_max_capacity
        errors.add(:mirror_capacity_threshold, "Project's mirror capacity threshold can't be higher than it's maximum capacity")
      end
    end

    def elasticsearch_indexing_column_exists?
      ::Gitlab::Database.cached_column_exists?(:application_settings, :elasticsearch_indexing)
    end

    def elasticsearch_search_column_exists?
      ::Gitlab::Database.cached_column_exists?(:application_settings, :elasticsearch_search)
    end

    def email_additional_text_column_exists?
      ::Gitlab::Database.cached_column_exists?(:application_settings, :email_additional_text)
    end
  end
end
