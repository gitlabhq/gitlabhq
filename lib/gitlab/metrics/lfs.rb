# frozen_string_literal: true

module Gitlab
  module Metrics
    module Lfs
      include Gitlab::Metrics::SliConfig

      sidekiq_enabled!

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:lfs_update_objects, [{}])
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:lfs_check_objects, [{}])
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:lfs_validate_link_objects, [{}])
        end

        def update_objects_error_rate
          Gitlab::Metrics::Sli::ErrorRate[:lfs_update_objects]
        end

        def check_objects_error_rate
          Gitlab::Metrics::Sli::ErrorRate[:lfs_check_objects]
        end

        def validate_link_objects_error_rate
          Gitlab::Metrics::Sli::ErrorRate[:lfs_validate_link_objects]
        end
      end
    end
  end
end
