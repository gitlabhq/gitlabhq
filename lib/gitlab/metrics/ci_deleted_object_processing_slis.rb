# frozen_string_literal: true

module Gitlab
  module Metrics
    module CiDeletedObjectProcessingSlis
      include Gitlab::Metrics::SliConfig

      sidekiq_enabled!

      CATEGORY_LABEL = { feature_category: :continuous_integration }.freeze
      POSSIBLE_LABELS = [CATEGORY_LABEL].freeze

      ACCEPTABLE_DELAY = 12.hours

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:ci_deleted_objects_processing, POSSIBLE_LABELS)
        end

        def record_error(error:)
          Gitlab::Metrics::Sli::ErrorRate[:ci_deleted_objects_processing].increment(
            labels: CATEGORY_LABEL,
            error: error
          )
        end

        def track_deletion(object)
          age_seconds = Time.current - object.created_at
          delayed = age_seconds > ACCEPTABLE_DELAY ? "true" : "false"
          age_bucket = age_bucket_label(age_seconds)

          deletions_counter.increment(delayed: delayed, age_bucket: age_bucket)
        end

        private

        def age_bucket_label(age_seconds)
          case age_seconds
          when 0...(1.hour) then "0-1h"
          when (1.hour)...(2.hours) then "1-2h"
          when (2.hours)...(4.hours) then "2-4h"
          when (4.hours)...(8.hours) then "4-8h"
          when (8.hours)...(12.hours) then "8-12h"
          when (12.hours)...(24.hours) then "12-24h"
          when (24.hours)...(48.hours) then "24-48h"
          when (48.hours)...(72.hours) then "48-72h"
          when (72.hours)...(168.hours) then "72-168h"
          else "168h+"
          end
        end

        def deletions_counter
          @deletions_counter ||= Gitlab::Metrics.counter(
            :ci_deleted_objects_total,
            'Total number of CI deleted objects processed'
          )
        end
      end
    end
  end
end
