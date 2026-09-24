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
          # lenient: the allowed day range is enforced by the `in:` allowlist.
          DYNAMIC_GRANULARITY_PATTERN = /\A(?<days>\d+)d\z/
          # 1..399 days; bounds the bucket count by construction.
          DEFAULT_DYNAMIC_GRANULARITY_FORMAT = /\A([1-9]\d?|[1-3]\d{2})d\z/

          DEFAULT_PARAMETERS = {
            granularity: {
              type: :string,
              in: ['daily', 'weekly', 'monthly', DEFAULT_DYNAMIC_GRANULARITY_FORMAT],
              description: 'Date granularity: daily, weekly, monthly, or a fixed number of days ' \
                'between 1d and 399d (for example 30d)'
            },
            origin: {
              type: :datetime,
              description: 'Anchor for fixed-day granularities: buckets start at this timestamp ' \
                'and repeat every N days. Only valid with a fixed-day granularity'
            }
          }.freeze

          def initialize(*args, parameters: {}, **kwargs)
            super(*args, parameters: DEFAULT_PARAMETERS.merge(parameters || {}), **kwargs)
          end

          def to_outer_arel(context)
            configuration = context[name]
            granularity = instance_parameter(:granularity, configuration) || DEFAULT_GRANULARITY
            origin = instance_parameter(:origin, configuration)
            days = dynamic_granularity_days(granularity)

            column = super
            interval = interval_sql(granularity, days)
            scope = context[:scope]

            return scope.func('toStartOfInterval', [column, interval]) unless origin && days&.positive?

            anchored_bucket(scope, column, interval, origin_literal(scope, origin, days))
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

          # toStartOfInterval is evaluated over the whole block, so NULL positions of a
          # Nullable column arrive as the type default 1970-01-01 and trip the "origin
          # must be before the value" check. Filling them with the anchor keeps the
          # call valid; the outer `if` puts the NULL back.
          def anchored_bucket(scope, column, interval, anchor)
            bucketed = scope.func('toStartOfInterval', [scope.func('ifNull', [column, anchor]), interval, anchor])

            scope.func('if', [scope.func('isNull', [column]), Arel.sql('NULL'), bucketed])
          end

          # The origin is shifted to a phase-equivalent anchor in the first period after
          # the epoch, so it precedes every real value while leaving bucket boundaries
          # unchanged. It must not go earlier: ClickHouse 25.3 rejects any pre-epoch
          # origin outright, and GitLab still supports 25.x. The anchor is strftime'd
          # because the client renders a raw Time as a bare unix float.
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
