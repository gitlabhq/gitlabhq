# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Count < MetricDefinition
          attr_reader :distinct

          def initialize(name = 'total', type = :integer, expression = nil, distinct: false, **kwargs)
            @distinct = distinct
            super
          end

          def identifier
            dotted_name? ? name : :"#{name}_count"
          end

          def to_inner_arel(...)
            expression&.call
          end

          def secondary_arel(context)
            conditions = parameter_conditions(context)
            custom_condition = super
            conditions << custom_condition if custom_condition
            return if conditions.empty?
            return conditions.first if conditions.one?

            Arel::Nodes::Grouping.new(Arel::Nodes::And.new(conditions))
          end

          # The `if:` expression may return nil (for example, when its optional
          # parameters were not supplied), in which case no secondary projection
          # exists and the metric compiles to a plain count.
          def to_outer_arel(context)
            secondary_alias = context[:local_secondary_alias]
            return regular_count(context) unless secondary_alias

            inner_condition_column = Arel::Table.new(context[:inner_query_name])[secondary_alias]
            Arel::Nodes::NamedFunction.new('countIf', [inner_condition_column.eq(1)])
          end

          def regular_count(context)
            inner_column = Arel::Table.new(context[:inner_query_name])[context[:local_alias]] if context[:local_alias]
            Arel::Nodes::Count.new([inner_column || Arel.star], distinct)
          end

          private

          # Parameters declared with an `in:` allowlist automatically contribute
          # a `column IN (values)` condition (the parameter key is the column
          # name). Values are validated against the allowlist before the query
          # is built; an optional `formatter:` maps them to stored values (for
          # example, enum names to integers).
          def parameter_conditions(context)
            parameters.filter_map do |param_key, param_opts|
              next unless param_opts[:in]

              values = Array.wrap(instance_parameter(param_key, context[name]))
              values = param_opts[:formatter].call(values) if param_opts[:formatter]
              next if values.blank?

              context[:scope][param_key.to_s].in(values)
            end
          end
        end
      end
    end
  end
end
