# frozen_string_literal: true

module ActiveContext
  class Query
    # WARNING: This is a toy example processor that is NOT safe for production use.
    # It is vulnerable to SQL injection attacks because it directly interpolates user input into SQL strings.
    # For a production-safe implementation, please use proper SQL parameter binding
    # (see ActiveRecord::Sanitization, PG::Connection#exec_params, etc.)
    #
    # Examples of vulnerabilities:
    # - Direct string interpolation of values (e.g., "#{k} = '#{v}'")
    # - Unquoted identifiers (column names)
    # - Direct interpolation of arrays and limits
    class ProcessorExample
      include ActiveContext::Databases::Concerns::Processor

      def self.transform(node)
        new.process(node)
      end

      def process(node)
        case node.type
        when :filter  then process_filter(node.value)
        when :prefix  then process_prefix(node.value)
        when :or      then process_or(node)
        when :and     then process_and(node.children)
        when :knn     then process_knn(node)
        when :limit   then process_limit(node)
        else
          raise "Unknown node type: #{node.type}"
        end
      end

      private

      def process_filter(conditions)
        conditions.map { |k, v| "#{k} = '#{v}'" }.join(" AND ")
      end

      def process_prefix(conditions)
        conditions.map { |k, v| "#{k} LIKE '#{v}%'" }.join(" AND ")
      end

      def process_or(node)
        if contains_knn?(node)
          process_or_with_knn(node)
        else
          process_simple_or(node.children)
        end
      end

      def process_simple_or(children)
        children.map { |child| "(#{process(child)})" }.join(" OR ")
      end

      def process_or_with_knn(node)
        knn_child = find_knn_child(node)
        conditions = build_or_conditions(node, knn_child)
        build_knn_query(knn_child, conditions)
      end

      def process_and(children)
        children.map { |child| "(#{process(child)})" }.join(" AND ")
      end

      def process_knn(node)
        conditions = node.children.any? ? "WHERE #{process(node.children.first)}" : ""
        build_knn_query(node, conditions)
      end

      def process_limit(node)
        "SELECT * FROM (#{process(node.children.first)}) subq LIMIT #{node.value}"
      end

      def contains_knn?(node)
        node.children.any? { |child| child.type == :knn }
      end

      def find_knn_child(node)
        node.children.find { |child| child.type == :knn }
      end

      def build_or_conditions(node, knn_child)
        conditions = node.children.filter_map do |child|
          next if child == knn_child

          "(#{process(child)})"
        end.join(" OR ")

        conditions.empty? ? "" : "WHERE #{conditions}"
      end

      def build_knn_query(node, conditions)
        target = node.value[:target]
        vector = node.value[:vector]
        limit = node.value[:limit]

        [
          "SELECT * FROM items",
          conditions,
          "ORDER BY #{target} <-> '[#{vector.join(',')}]'",
          "LIMIT #{limit}"
        ].reject(&:empty?).join(" ")
      end
    end
  end
end
