# frozen_string_literal: true

# Measures and monitors deleted object processing
module Gitlab
  module Metrics
    module CiDeletedObjectProcessingSlis
      include Gitlab::Metrics::SliConfig

      sidekiq_enabled!

      CATEGORY_LABEL = { feature_category: :continuous_integration }.freeze
      POSSIBLE_LABELS = [CATEGORY_LABEL].freeze

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:ci_deleted_objects_processing, POSSIBLE_LABELS)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:ci_deleted_objects_processing, POSSIBLE_LABELS)
        end

        def record_apdex(success:)
          Gitlab::Metrics::Sli::Apdex[:ci_deleted_objects_processing].increment(
            labels: CATEGORY_LABEL,
            success: success)
        end

        def record_error(error:)
          Gitlab::Metrics::Sli::ErrorRate[:ci_deleted_objects_processing].increment(
            labels: CATEGORY_LABEL,
            error: error)
        end
      end
    end
  end
end
