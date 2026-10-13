# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        # Pairs attached partition child indexes by table and parent index, because PostgreSQL names them by
        # creation order. The indexes left over on both sides match by schema and name, so a name held by a paired
        # child does not hide an unpaired index.
        class PartitionIndexMatcher
          def initialize(structure_sql, database)
            @structure_sql_children = children(structure_sql.indexes)
            @database_children = children(database.indexes)
            @structure_sql_leftovers = leftovers(structure_sql.indexes, database_children)
            @database_leftovers = leftovers(database.indexes, structure_sql_children)
            @structure_sql_keys = structure_sql.indexes.to_set { |index| key(index) }
            @database_keys = database.indexes.to_set { |index| key(index) }
          end

          # A child of a parent index that is itself missing is not reported, the parent is.
          def missing?(index)
            return counterpart(index).nil? unless index.attachment

            database_keys.include?(index.parent) && counterpart(index).nil?
          end

          def extra?(index)
            return !structure_sql_leftovers.key?(key(index)) unless index.attachment

            !structure_sql_children.key?(index.attachment) && structure_sql_keys.include?(index.parent)
          end

          def counterpart(index)
            return database_children[index.attachment] if index.attachment

            database_leftovers[key(index)]
          end

          private

          attr_reader :structure_sql_children, :database_children, :structure_sql_leftovers, :database_leftovers,
            :structure_sql_keys, :database_keys

          def key(index)
            [index.schema_name, index.name]
          end

          def children(indexes)
            indexes.select(&:attachment).each_with_object({}) do |index, map| # rubocop:disable Rails/IndexBy -- This gem does not depend on ActiveSupport.
              map[index.attachment] = index
            end
          end

          def leftovers(indexes, other_children)
            unpaired = indexes.reject { |index| index.attachment && other_children.key?(index.attachment) }

            unpaired.each_with_object({}) do |index, map| # rubocop:disable Rails/IndexBy -- This gem does not depend on ActiveSupport.
              map[key(index)] = index
            end
          end
        end
      end
    end
  end
end
