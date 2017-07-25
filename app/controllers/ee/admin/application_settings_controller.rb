module EE
  module Admin
    module ApplicationSettingsController
      def application_setting_params_attributes
        attrs = super + application_setting_params_attributes_ee
        attrs += repository_mirrors_params_attributes if License.feature_available?(:repository_mirrors)

        attrs
      end

      private

      def application_setting_params_attributes_ee
        [
          :help_text,
          :elasticsearch_url,
          :elasticsearch_indexing,
          :elasticsearch_aws,
          :elasticsearch_aws_access_key,
          :elasticsearch_aws_secret_access_key,
          :elasticsearch_aws_region,
          :elasticsearch_search,
          :repository_size_limit,
          :shared_runners_minutes,
          :geo_status_timeout,
          :elasticsearch_experimental_indexer,
          :check_namespace_plan,
          :authorized_keys_enabled,
          :slack_app_enabled,
          :slack_app_id,
          :slack_app_secret,
          :slack_app_verification_token
        ]
      end

      def repository_mirrors_params_attributes
        [
          :mirror_max_delay,
          :mirror_max_capacity,
          :mirror_capacity_threshold
        ]
      end
    end
  end
end
