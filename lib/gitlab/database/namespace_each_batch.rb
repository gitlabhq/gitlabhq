# frozen_string_literal: true

module Gitlab
  module Database
    # This class implements an iterator over the namespace hierarchy which uses a recursive
    # depth-first algorithm.
    # You can read more about the algorithm here:
    # https://docs.gitlab.com/ee/development/database/poc_tree_iterator.html
    #
    # With the class, you can iterate over the whole hierarchy including subgroups and project namespaces
    # or just iterate over the subgroups.
    #
    # Usage:
    #
    # # To invoke the iterator, you can take any group id.
    # # Build the cursor object that will be used for tracking our position in the tree hierarchy.
    # cursor = { current_id: 9970, depth: [9970] }
    #
    # # Instantiate the object.
    # iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespace, cursor: cursor)
    #
    # iterator.each_batch(of: 100) do |ids|
    #   # return namespace ids which can be Group id or Namespaces::ProjectNamespace id
    #   puts ids
    # end
    #
    # # When you need to break out of the iteration and continue later, you can yield the cursor as a second parameter:
    # iterator.each_batch(of: 100) do |ids, new_cursor|
    #   save_cursor(new_cursor) && break if limit_reached?
    #   puts ids
    # end
    #
    # You can build a new iterator later and resume the processing.
    #
    # # Building an iterator that only returns groups:
    # iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Group, cursor: cursor)
    #
    class NamespaceEachBatch
      PROJECTIONS = %w[current_id depth ids count index].freeze

      def initialize(namespace_class:, cursor:)
        @namespace_class = namespace_class
        set_cursor!(cursor)
      end

      def each_batch(of: 500)
        current_cursor = cursor.dup

        first_iteration = true
        loop do
          new_cursor, ids = load_batch(cursor: current_cursor, of: of, first_iteration: first_iteration)
          break if new_cursor.nil?

          first_iteration = false
          current_cursor = new_cursor

          yield ids, new_cursor

          break if new_cursor[:depth].empty?
        end
      end

      private

      attr_reader :namespace_class, :cursor, :namespace_id

      def load_batch(cursor:, of:, first_iteration: false)
        recursive_scope = build_recursive_query(cursor, of, first_iteration)

        row = Namespace
          .select(*PROJECTIONS)
          .from(recursive_scope.arel.as(Namespace.table_name)).order(count: :desc)
          .limit(1)
          .first

        return [] unless row

        [{ current_id: row[:current_id], depth: row[:depth] }, row[:ids]]
      end

      # rubocop: disable Style/AsciiComments -- Rendering a graph
      # The depth-first algorithm is implemented here. Consider the following group hierarchy:
      #
      #               ┌──┐
      #               │10│
      #          ┌────┴──┴────┐
      #          │            │
      #        ┌─┴┐          ┌┴─┐
      #        │41│          │72│
      #        └─┬┘          └──┘
      #          │
      #        ┌─┴┐
      #   ┌────┤32├─────┐
      #   │    └─┬┘     │
      #   │      │      │
      # ┌─┴┐   ┌─┴┐    ┌┴─┐
      # │11│   │12│    │18│
      # └──┘   └──┘    └──┘
      #
      # 1. Start with node 10 and look up the left-hand child nodes until reaching the leaf. (walk_down)
      # 2. While walking down, record the depth in an array and also store them in the ids array.
      # 3. depth: 10, 41, 32, 11 | ids: 10, 41, 32, 11
      # 4. Start collecting the ids by looking at the nodes on the deepest level. (next_elements)
      # 5. This gives us the rest of the nodes on the same level (parent_id = 32 AND id > 11)
      # 6. depth: 10, 41, 32, 11 | ids: 10, 41, 32, 11, 12, 18
      # 7. When done, move one level up and pop the last value from the depth. (up_one_level)
      # 8. depth: 10, 41, 32 | ids: 10, 41, 32, 11, 12, 18
      # 9. Do the same, look at the nodes on the same level: no records, 32 was already collected
      # 10. depth: 10, 41, 32 | ids: 10, 41, 32, 11, 12, 18
      # 11. Move one level up again and look at the nodes on the same level.
      # 12. depth: 10, 41 | ids: 10, 41, 32, 11, 12, 18, 72
      # 13. Move one level up again, we reached the root node, iteration is done.
      # 14. depth: 10 | ids: 10, 41, 32, 11, 12, 18, 72
      #
      # By tracking the currently accessed node and the depth we can stop and restore the processing of
      # the hierarchy at any point.
      #
      # rubocop: enable Style/AsciiComments
      def build_recursive_query(cursor, of, first_iteration)
        ids = first_iteration ? cursor[:current_id] : ''

        recursive_cte = Gitlab::SQL::RecursiveCTE.new(:result,
          union_args: {
            remove_order: false,
            remove_duplicates: false
          })

        recursive_cte << base_namespace_class.select(
          Arel.sql("#{cursor[:current_id]}::bigint").as('current_id'),
          Arel.sql("ARRAY[#{cursor[:depth].join(',')}]::bigint[]").as('depth'),
          Arel.sql("ARRAY[#{ids}]::bigint[]").as('ids'),
          Arel.sql('1::bigint AS count'),
          Arel.sql('0::bigint AS index')
        ).from('(VALUES (1)) AS initializer_row')
          .where_exists(namespace_exists_query)

        cte = Gitlab::SQL::CTE.new(:cte, base_namespace_class.select('result.*').from('result'))

        union_query = base_namespace_class.with(cte.to_arel).from_union(
          walk_down,
          next_elements,
          up_one_level,
          remove_duplicates: false,
          remove_order: false
        ).select(*PROJECTIONS).order(base_namespace_class.arel_table[:index].asc).limit(1)

        recursive_cte << union_query

        base_namespace_class.with
          .recursive(recursive_cte.to_arel)
          .from(recursive_cte.alias_to(namespace_class.arel_table))
          .select(*PROJECTIONS)
          .limit(of + 1)
      end

      def namespace_exists_query
        Namespace.where(id: cursor[:current_id])
      end

      def walk_down
        lateral_query = namespace_class
          .select(:id)
          .where('parent_id = cte.current_id')
          .order(:id)
          .limit(1)

        base_namespace_class.select(
          base_namespace_class.arel_table[:id].as('current_id'),
          Arel.sql("cte.depth || #{base_namespace_table}.id::bigint").as('depth'),
          Arel.sql("cte.ids || #{base_namespace_table}.id::bigint").as('ids'),
          Arel.sql('cte.count + 1').as('count'),
          Arel.sql('1::bigint AS index')
        ).from("cte, LATERAL (#{lateral_query.to_sql}) #{base_namespace_table}")
      end

      def next_elements
        lateral_query = namespace_class
          .select(:id)
          .where("#{base_namespace_table}.parent_id = cte.depth[array_length(cte.depth, 1) - 1]")
          .where("#{base_namespace_table}.id > cte.depth[array_length(cte.depth, 1)]")
          .order(:id)
          .limit(1)

        base_namespace_class.select(
          base_namespace_class.arel_table[:id].as('current_id'),
          Arel.sql("cte.depth[:array_length(cte.depth, 1) - 1] || #{base_namespace_table}.id::bigint").as('depth'),
          Arel.sql("cte.ids || #{base_namespace_table}.id::bigint").as('ids'),
          Arel.sql('cte.count + 1').as('count'),
          Arel.sql('2::bigint AS index')
        ).from("cte, LATERAL (#{lateral_query.to_sql}) #{base_namespace_table}")
      end

      def up_one_level
        Namespace.select(
          Arel.sql('cte.current_id').as('current_id'),
          Arel.sql('cte.depth[:array_length(cte.depth, 1) - 1]').as('depth'),
          Arel.sql('cte.ids').as('ids'),
          Arel.sql('cte.count + 1').as('count'),
          Arel.sql('3::bigint AS index')
        ).from('cte')
          .where("cte.depth <> '{}'")
          .limit(1)
      end

      def base_namespace_class
        Namespace
      end

      def base_namespace_table
        Namespace.quoted_table_name
      end

      def set_cursor!(original_cursor)
        raise ArgumentError unless original_cursor[:depth].is_a?(Array)

        @cursor = {
          current_id: Integer(original_cursor[:current_id]),
          depth: original_cursor[:depth].map { |value| Integer(value) }
        }
      end
    end
  end
end
