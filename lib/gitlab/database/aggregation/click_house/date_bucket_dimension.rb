# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class DateBucketDimension < DimensionDefinition
          include ParameterizedDefinition

          GRANULARITIES_MAP = {
            daily: :day,
            weekly: :week,
            monthly: :month,
            yearly: :year
          }.with_indifferent_access.freeze

          DEFAULT_GRANULARITY = :monthly

          # Shape of a dynamic day granularity (`30d`). Parsing is deliberately
          # lenient: the allowed day range is enforced by each engine's `in:`
          # allowlist.
          DYNAMIC_GRANULARITY_PATTERN = /\A(?<days>\d+)d\z/

          def to_outer_arel(context)
            configuration = context[name]
            granularity = instance_parameter(:granularity, configuration) || DEFAULT_GRANULARITY
            origin = instance_parameter(:origin, configuration)
            days = dynamic_granularity_days(granularity)

            arguments = [super, interval_sql(granularity, days)]
            arguments << origin_literal(context[:scope], origin, days) if origin && days&.positive?

            context[:scope].func('toStartOfInterval', arguments)
          end

          def validate_part(part)
            super

            validate_origin(part, instance_parameter(:granularity, part.configuration))
          end

          private

          def dynamic_granularity_days(granularity)
            match = DYNAMIC_GRANULARITY_PATTERN.match(granularity.to_s)

            match && match[:days].to_i
          end

          def interval_sql(granularity, days)
            # `days` is Integer-parsed and granularity is mapped through the frozen
            # GRANULARITIES_MAP, so raw interpolation is injection-safe.
            return Arel.sql("INTERVAL #{days} DAY") if days

            Arel.sql("INTERVAL 1 #{GRANULARITIES_MAP[granularity]}")
          end

          # ClickHouse requires the origin to be on or before every bucketed value,
          # so the user-supplied origin is shifted back to its phase-equivalent
          # anchor near the unix epoch. Bucket boundaries are unchanged; rows older
          # than the user-supplied origin land in earlier buckets instead of
          # failing the query. The anchor is strftime'd and quoted as a string
          # because the ClickHouse client renders a raw Ruby Time as a bare unix
          # float, which is not a valid DateTime64 literal.
          def origin_literal(scope, origin, days)
            # Callers must pass a Time: a String would silently anchor near the
            # epoch through String#to_i. GraphQL inputs are coerced by the API layer.
            raise ArgumentError, "origin must be a Time, got #{origin.class}" unless origin.acts_like?(:time)

            anchor = Time.at(origin.to_i % days.days.to_i).utc

            scope.func('toDateTime64', [scope.quote(anchor.strftime('%Y-%m-%d %H:%M:%S')), 6, scope.quote('UTC')])
          end

          def validate_origin(part, granularity)
            return unless part.configuration.dig(:parameters, :origin) && parameters[:origin]
            return if DYNAMIC_GRANULARITY_PATTERN.match?(granularity.to_s)

            part.errors.add(:origin,
              s_("AggregationEngine|Parameter `origin` requires a dynamic day granularity (for example `30d`)"))
          end
        end
      end
    end
  end
end
