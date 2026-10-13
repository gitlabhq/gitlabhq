# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        # Matches rows whose traversal path column starts with the traversal path of any
        # of the given groups, so a group matches together with all of its descendants.
        # Values are Group Global IDs; validation resolves them and rejects anything else.
        class DescendantsFilter < FilterDefinition
          def initialize(name, type, expression = nil, with_organization: true, **kwargs)
            super(name, type, expression, **kwargs)
            @with_organization = with_organization
          end

          def validate_part(part)
            super
            # Oversized requests are rejected before the PostgreSQL lookup runs.
            return if part.errors.any?

            paths = resolve_traversal_paths(part)
            return if part.errors.any?

            validate_trailing_slashes(part, paths)
            # `apply` only receives this hash, and the plan is validated once before it
            # executes, so the resolved paths travel with the configuration.
            part.configuration[:traversal_paths] = paths if part.errors.empty?
          end

          private

          def apply(query_builder, filter_config)
            path = column(query_builder)
            condition = filter_config.fetch(:traversal_paths).map do |prefix|
              query_builder.func('startsWith', [path, query_builder.quote(prefix)])
            end.reduce(:or)

            if merge_column?
              query_builder.having(condition)
            else
              query_builder.where(condition)
            end
          end

          def resolve_traversal_paths(part)
            ids = Array.wrap(part.configuration[:values]).map { |value| group_id_from(value) }.uniq
            groups = ids.present? && ids.all? ? ::Group.id_in(ids).to_a : []

            if ids.empty? || groups.size != ids.size
              part.errors.add(:values,
                format(s_("AggregationEngine|must be Global IDs of existing groups for filter `%{key}`"),
                  key: part.instance_key))
              return
            end

            groups.map { |group| group.traversal_path(with_organization: @with_organization) }
          end

          def group_id_from(value)
            gid = GlobalID.parse(value)

            gid.model_id.to_i if gid&.model_name == 'Group'
          end

          # `Namespace#traversal_path` always appends `/`; the guard stays because `1/2`
          # would also match `1/20/`, exposing rows of an unrelated group.
          def validate_trailing_slashes(part, paths)
            return if paths.all? { |path| path.end_with?('/') }

            part.errors.add(:values,
              format(s_("AggregationEngine|must be traversal paths ending with `/` for filter `%{key}`"),
                key: part.instance_key))
          end
        end
      end
    end
  end
end
