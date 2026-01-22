# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Processor
        include ActiveContext::Databases::Concerns::Processor

        # Transforms a query node into a PostgreSQL query using ActiveRecord
        def self.transform(collection:, node:, user:)
          ActiveContext.adapter.client.with_model_for(collection.collection_name) do |model|
            relation = new(collection: collection, model: model, user: user).process(node)
            relation.to_sql
          end
        end

        def initialize(collection:, model:, user:)
          @collection = collection
          @model = model
          @user = user
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

        attr_reader :collection, :model, :user, :base_relation

        def process_all
          base_relation
        end

        def process_filter(conditions)
          relation = base_relation
          conditions.each do |key, value|
            quoted_column = quote_column(key)
            relation = if value.is_a?(Array)
                         relation.where("#{quoted_column} IN (#{sql_placeholders(value)})", *value)
                       else
                         relation.where("#{quoted_column} = ?", value)
                       end
          end
          relation
        end

        def process_prefix(conditions)
          relation = base_relation
          conditions.each do |key, value|
            quoted_column = quote_column(key)
            sanitized_value = model.sanitize_sql_like(value)
            relation = relation.where("#{quoted_column} LIKE ?", "#{sanitized_value}%")
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

          preset_values = collection.current_search_embedding_version

          column = node.value[:target] || preset_values[:field]
          vector = node.value[:vector] || get_embeddings(node.value[:content], preset_values)
          limit = node.value[:k]
          vector_str = "[#{vector.join(',')}]"

          relation
            .order(
              Arel.sql("#{quote_column(column)} <=> #{model.connection.quote(vector_str)}")
            )
            .limit(limit)
        end

        def process_limit(node)
          child_relation = process(node.children.first)

          # Subquery needed when KNN (k) and LIMIT are both present
          child_sql = child_relation.to_sql
          limit_value = node.value

          Struct.new(:to_sql).new("SELECT subq.* FROM (#{child_sql}) subq LIMIT #{limit_value}")
        end

        def quote_column(column)
          quoted = model.connection.quote_column_name(column)
          "#{model.connection.quote_table_name(model.table_name)}.#{quoted}"
        end

        def sql_placeholders(values)
          Array.new(values.size, '?').join(', ')
        end
      end
    end
  end
end
