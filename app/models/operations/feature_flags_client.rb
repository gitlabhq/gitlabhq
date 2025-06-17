# frozen_string_literal: true

module Operations
  class FeatureFlagsClient < ApplicationRecord
    include TokenAuthenticatable

    DEFAULT_UNLEASH_API_VERSION = 1
    FEATURE_FLAGS_CLIENT_TOKEN_PREFIX = 'glffct-'

    self.table_name = 'operations_feature_flags_clients'

    belongs_to :project

    validates :project, presence: true
    validates :token, presence: true

    add_authentication_token_field :token,
      encrypted: :required,
      format_with_prefix: :prefix_for_feature_flags_client_token

    attr_accessor :unleash_app_name

    before_validation :ensure_token!

    def self.find_for_project_and_token(project_id, token)
      return unless project_id
      return unless token

      where(project_id: project_id).find_by_token(token)
    end

    def self.update_last_feature_flag_updated_at!(project)
      where(project: project).update_all(last_feature_flag_updated_at: Time.current)
    end

    def self.prefix_for_feature_flags_client_token
      return FEATURE_FLAGS_CLIENT_TOKEN_PREFIX unless Feature.enabled?(:custom_prefix_for_all_token_types, :instance)

      ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(FEATURE_FLAGS_CLIENT_TOKEN_PREFIX)
    end

    def unleash_api_version
      DEFAULT_UNLEASH_API_VERSION
    end

    def unleash_api_features
      return [] unless unleash_app_name.present?

      Operations::FeatureFlag.for_unleash_client(project, unleash_app_name)
    end

    def unleash_api_cache_key
      "api_version:#{unleash_api_version}:" \
        "app_name:#{unleash_app_name}:" \
        "updated_at:#{last_feature_flag_updated_at.to_i}"
    end

    def prefix_for_feature_flags_client_token
      self.class.prefix_for_feature_flags_client_token
    end
  end
end
