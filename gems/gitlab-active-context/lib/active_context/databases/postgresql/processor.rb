# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Processor
        include ActiveContext::Databases::Concerns::Processor

        # Transforms a query node into a PostgreSQL query using ActiveRecord
        def self.transform(collection, node)
          ActiveContext.adapter.client.with_model_for(collection) do |model|
            relation = new(model).process(node)
            relation.to_sql
          end
        end

        def initialize(model)
          @model = model
          @base_relation = model.all
        end

        # Processes a query node and returns the corresponding ActiveRecord relation
        def process(node)
          case node.type
          when :all    then process_all
          when :filter then process_filter(node.value)
          when :prefix then process_prefix(node.value)
          when :and    then process_and(node.children)
          when :or     then process_or(node.children)
          when :knn    then process_knn(node)
          when :limit  then process_limit(node)
          else
            raise ArgumentError, "Unsupported node type: #{node.type}"
          end
        end

        private

        attr_reader :model, :base_relation

        def process_all
          base_relation
        end

        def process_filter(conditions)
          relation = base_relation
          conditions.each do |key, value|
            relation = relation.where(key => value)
          end
          relation
        end

        def process_prefix(conditions)
          relation = base_relation
          conditions.each do |key, value|
            relation = relation.where("#{model.connection.quote_column_name(key)} LIKE ?", "#{value}%")
          end
          relation
        end

        def process_and(children)
          relation = base_relation
          children.each do |child|
            relation = relation.merge(process(child))
          end
          relation
        end

        def process_or(children)
          if contains_knn?(children)
            process_or_with_knn(children)
          else
            process_simple_or(children)
          end
        end

        def contains_knn?(children)
          children.any? { |child| child.type == :knn }
        end

        def process_or_with_knn(children)
          knn_children, non_knn_children = children.partition { |child| child.type == :knn }
          relation = non_knn_children.empty? ? base_relation : process_simple_or(non_knn_children)
          process_knn(knn_children.first, relation)
        end

        def process_simple_or(children)
          # Start with the first child as the base relation: WHERE X
          relation = process(children.first)

          # OR with each subsequent child
          children[1..].each do |child|
            relation = relation.or(process(child))
          end

          relation
        end

        def process_knn(node, relation = base_relation)
          # Start with base relation or filtered relation if there are children
          relation = node.children.any? ? process(node.children.first) : relation

          column = node.value[:target]
          vector = node.value[:vector]
          limit = node.value[:limit]
          vector_str = "[#{vector.join(',')}]"

          relation
            .order(Arel.sql("#{model.connection.quote_column_name(column)} <=> #{model.connection.quote(vector_str)}"))
            .limit(limit)
        end

        def process_limit(node)
          child_relation = process(node.children.first)

          # Create a subquery
          subquery = child_relation.arel.as('subq')
          model.unscoped.select('subq.*').from(subquery).limit(node.value)
        end
      end
    end
  end
end
