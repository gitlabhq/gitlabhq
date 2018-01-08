module EE
  module ApplicationSettingsHelper
    def visible_attributes
      raise NotImplementedError unless defined?(super)

      super + [
        :check_namespace_plan,
        :elasticsearch_aws,
        :elasticsearch_aws_access_key,
        :elasticsearch_aws_region,
        :elasticsearch_aws_secret_access_key,
        :elasticsearch_experimental_indexer,
        :elasticsearch_indexing,
        :elasticsearch_search,
        :elasticsearch_url,
        :geo_status_timeout,
        :help_text,
        :repository_size_limit,
        :shared_runners_minutes,
        :slack_app_enabled,
        :slack_app_id,
        :slack_app_secret,
        :slack_app_verification_token,
        :allow_group_owners_to_manage_ldap,
        :mirror_available
      ]
    end

    def self.repository_mirror_attributes
      [
        :mirror_max_capacity,
        :mirror_max_delay,
        :mirror_capacity_threshold
      ]
    end
  end
end
