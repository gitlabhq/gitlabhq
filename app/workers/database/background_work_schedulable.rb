# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Database Framework
  module BackgroundWorkSchedulable
    extend ActiveSupport::Concern

    class_methods do
      # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Global FF
      # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- It's different for each sub-class.
      def enabled?
        return false if Feature.enabled?(:disallow_database_ddl_feature_flags, type: :ops)

        schedule_feature_flag_name.present? ? Feature.enabled?(schedule_feature_flag_name, type: :ops) : true
      end
      # rubocop:enable Gitlab/FeatureFlagWithoutActor
      # rubocop:enable Gitlab/FeatureFlagKeyDynamic
    end

    included do
      include Gitlab::Utils::StrongMemoize

      private

      def validate!
        unless base_model
          Sidekiq.logger.info(
            class: self.class.name,
            database: tracking_database,
            message: "Skipping #{self.class.name} execution for unconfigured database #{tracking_database}")

          return false
        end

        return true unless shares_db_config?

        Sidekiq.logger.info(
          class: self.class.name,
          database: tracking_database,
          message: "Skipping #{self.class.name} execution for database that " \
            "shares database configuration with another database")

        false
      end

      def max_running_migrations
        execution_worker_class.max_running_jobs
      end

      def tracking_database
        self.class.tracking_database
      end
      strong_memoize_attr :tracking_database

      def base_model
        Gitlab::Database.database_base_models[tracking_database]
      end
      strong_memoize_attr :base_model

      def shares_db_config?
        base_model && Gitlab::Database.db_config_share_with(base_model.connection_db_config).present?
      end
    end
  end
end
