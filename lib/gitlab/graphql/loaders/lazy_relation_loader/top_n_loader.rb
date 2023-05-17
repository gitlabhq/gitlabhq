# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord
module Gitlab
  module Graphql
    module Loaders
      class LazyRelationLoader
        # Loads the top-n records for each given parent record.
        # For example; if you want to load only 5 confidential issues ordered by
        # their updated_at column per project for a list of projects by issuing only a single
        # SQL query then this class can help you.
        # Note that the limit applies per parent record which means that if you apply limit as 5
        # for 10 projects, this loader will load 50 records in total.
        class TopNLoader
          def self.load(original_relation, parents)
            new(original_relation, parents).load
          end

          def initialize(original_relation, parents)
            @original_relation = original_relation
            @parents = parents
          end

          def load
            klass.select(klass.arel_table[Arel.star])
                 .from(from)
                 .joins("JOIN LATERAL (#{lateral_relation.to_sql}) AS #{klass.arel_table.name} ON true")
                 .includes(original_includes)
                 .preload(original_preload)
                 .eager_load(original_eager_load)
                 .load
          end

          private

          attr_reader :original_relation, :parents

          delegate :proxy_association, to: :original_relation, private: true
          delegate :reflection, to: :proxy_association, private: true
          delegate :klass, :foreign_key, :active_record, :active_record_primary_key,
            to: :reflection, private: true

          # This only works for HasMany and HasOne.
          def lateral_relation
            original_relation
              .unscope(where: foreign_key) # unscoping the where condition generated for the placeholder_record.
              .where(klass.arel_table[foreign_key].eq(active_record.arel_table[active_record_primary_key]))
          end

          def from
            grouping_arel_node.as("#{active_record.arel_table.name}(#{active_record.primary_key})")
          end

          def grouping_arel_node
            Arel::Nodes::Grouping.new(id_list_arel_node)
          end

          def id_list_arel_node
            parent_ids.map { |id| [id] }
                      .then { |ids| Arel::Nodes::ValuesList.new(ids) }
          end

          def parent_ids
            parents.pluck(active_record.primary_key)
          end

          def original_includes
            original_relation.includes_values
          end

          def original_preload
            original_relation.preload_values
          end

          def original_eager_load
            original_relation.eager_load_values
          end
        end
      end
    end
  end
end
# rubocop:enable CodeReuse/ActiveRecord
