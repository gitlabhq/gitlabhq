# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        # Groups rows by the namespace id found at a given depth of an
        # organization-scoped traversal path column (`7/12/34/`), so results can
        # be bucketed by one level of the group hierarchy. Depth counts from the
        # top-level group, skipping the leading organization segment. Paths
        # shorter than the depth and the `0/` placeholder path yield NULL.
        class TraversalPathDimension < DimensionDefinition
          include ParameterizedDefinition

          DEFAULT_DEPTH = 1
          # Bounds abuse without tying the framework to the application's nesting limit.
          MAX_DEPTH = 99
          DEFAULT_PARAMETERS = {
            depth: {
              type: :integer,
              in: 1..MAX_DEPTH,
              description: 'Depth in the group hierarchy, counted from the top-level group. Defaults to 1.'
            }
          }.freeze

          def initialize(*args, parameters: {}, **kwargs)
            super(*args, parameters: DEFAULT_PARAMETERS.deep_merge(parameters || {}), **kwargs)
          end

          def to_inner_arel(context)
            scope = context[:scope]
            # The first segment is the organization id, so depth 1 is the second segment.
            index = depth_for(context[name]) + 1

            segments = scope.func('splitByChar', [scope.quote('/'), super])
            segment_id = scope.func('toUInt64OrNull', [scope.func('arrayElement', [segments, index])])

            scope.func('nullIf', [segment_id, 0])
          end

          private

          def depth_for(configuration)
            instance_parameter(:depth, configuration) || DEFAULT_DEPTH
          end
        end
      end
    end
  end
end
