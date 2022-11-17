# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class InProductMarketingEmailSentMetric < DatabaseMetric
          operation :count

          def initialize(metric_definition)
            super

            unless track.in?(allowed_track)
              raise ArgumentError, "track '#{track}' must be one of: #{allowed_track.join(', ')}"
            end

            return if series.in?(allowed_series)

            raise ArgumentError, "series '#{series}' must be one of: #{allowed_series.join(', ')}"
          end

          relation { Users::InProductMarketingEmail }

          private

          def relation
            scope = super
            scope = scope.where(series: series)
            scope.where(track: track)
          end

          def track
            options[:track]
          end

          def series
            options[:series]
          end

          def allowed_track
            Users::InProductMarketingEmail::ACTIVE_TRACKS.keys
          end

          def allowed_series
            @allowed_series ||= begin
              series_amount = Namespaces::InProductMarketingEmailsService.email_count_for_track(track)
              0.upto(series_amount - 1).to_a
            end
          end
        end
      end
    end
  end
end
