# frozen_string_literal: true

module Gitlab
  module Metrics
    module LooseForeignKeysSlis
      include Gitlab::Metrics::SliConfig

      sidekiq_enabled!

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:loose_foreign_key_clean_ups, possible_labels)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:loose_foreign_key_clean_ups, possible_labels)
        end

        def record_apdex(success:, db_config_name:)
          Gitlab::Metrics::Sli::Apdex[:loose_foreign_key_clean_ups].increment(
            labels: labels(db_config_name),
            success: success
          )
        end

        def record_error_rate(error:, db_config_name:)
          Gitlab::Metrics::Sli::ErrorRate[:loose_foreign_key_clean_ups].increment(
            labels: labels(db_config_name),
            error: error
          )
        end

        private

        def possible_labels
          ::Gitlab::Database.db_config_names(with_schema: :gitlab_shared).map do |db_config_name|
            {
              db_config_name: db_config_name,
              feature_category: :database
            }
          end
        end

        def labels(db_config_name)
          {
            db_config_name: db_config_name,
            feature_category: :database
          }
        end
      end
    end
  end
end
