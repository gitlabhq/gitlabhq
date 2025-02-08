# frozen_string_literal: true
#
# A Namespace::TraversalHierarchy is the collection of namespaces that descend
# from a root Namespace as defined by the Namespace#traversal_ids attributes.
#
# This class provides operations to be performed on the hierarchy itself,
# rather than individual namespaces.
#
# This includes methods for synchronizing traversal_ids attributes to a correct
# state. We use recursive methods to determine the correct state so we don't
# have to depend on the integrity of the traversal_ids attribute values
# themselves.
#
class Namespace
  class TraversalHierarchy
    include Transactions

    LOCK_TIMEOUT = '1000ms'

    attr_accessor :root

    def initialize(root)
      raise StandardError, 'Must specify a root node' if root.parent_id

      @root = root
    end

    # Update all traversal_ids in the current namespace hierarchy.
    def sync_traversal_ids!
      TraversalHierarchy.sync_traversal_ids!(root)
    end

    # Identify all incorrect traversal_ids in the current namespace hierarchy.
    def incorrect_traversal_ids
      Namespace
        .joins("INNER JOIN (#{TraversalHierarchy.recursive_traversal_ids(root)}) as cte ON namespaces.id = cte.id")
        .where('namespaces.traversal_ids::bigint[] <> cte.traversal_ids')
    end

    class << self
      def for_namespace(namespace)
        new(recursive_root_ancestor(namespace))
      end

      # Update all traversal_ids for the given namespace and it's descendants.
      def sync_traversal_ids!(node)
        Namespace.transaction do
          acquire_locks(node)
          sync_traversal_ids_tree!(node)
        end
      end

      # Determine traversal_ids for the node and it's descendants using recursive methods.
      # Generate a collection of [id, traversal_ids] rows.
      #
      # Note that the traversal_ids represent a calculated traversal path for the
      # namespace and not the value stored within the traversal_ids attribute.
      # rubocop:disable Cop/AvoidBecomes -- Normalize STI queries
      def recursive_traversal_ids(node)
        node_id = Integer(node.id)
        ancestor_ids = if node.parent_id
                         node
                           .becomes(Namespace)
                           .recursive_self_and_ancestor_ids
                           .reverse
                           .join(',')
                       else
                         node_id
                       end

        <<~SQL
        WITH RECURSIVE cte(id, traversal_ids, cycle) AS (
          VALUES(#{node_id}::bigint, ARRAY[#{ancestor_ids}]::bigint[], false)
        UNION ALL
          SELECT n.id, cte.traversal_ids || n.id::bigint, n.id = ANY(cte.traversal_ids)
          FROM namespaces n, cte
          WHERE n.parent_id = cte.id AND NOT cycle
        )
        SELECT id, traversal_ids FROM cte
        SQL
      end
      # rubocop:enable Cop/AvoidBecomes

      private

      # Update all traversal_ids in the current namespace hierarchy.
      # Not thread safe, ensure the appropriate nodes are locked before calling.
      def sync_traversal_ids_tree!(node)
        # An issue in Rails since 2013 prevents this kind of join based update in
        # ActiveRecord. https://github.com/rails/rails/issues/13496
        # Ideally it would be:
        #   `incorrect_traversal_ids.update_all('traversal_ids = cte.traversal_ids')`
        sql = <<-SQL
          UPDATE namespaces
          SET traversal_ids = cte.traversal_ids
          FROM (#{recursive_traversal_ids(node)}) as cte
          WHERE namespaces.id = cte.id
            AND namespaces.traversal_ids::bigint[] <> cte.traversal_ids
        SQL

        # Hint: when a user is created, it also creates a Namespaces::UserNamespace in
        # `ensure_namespace_correct`. This method is then called within the same
        # transaction of the user INSERT.
        Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
          %w[namespaces], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424279'
        ) do
          Namespace.connection.exec_query(sql)
        end
      end

      # This is essentially Namespace#root_ancestor which will soon be rewritten
      # to use traversal_ids. We replicate here as a reliable way to find the
      # root using recursive methods.
      def recursive_root_ancestor(namespace)
        Gitlab::ObjectHierarchy
          .new(Namespace.where(id: namespace))
          .base_and_ancestors
          .reorder(nil)
          .find_top_level
      end

      # rubocop:disable Database/RescueQueryCanceled -- Measuring specific query timeouts
      def acquire_locks(node)
        Gitlab::Database::Transaction::Settings.with('LOCK_TIMEOUT', LOCK_TIMEOUT) do
          # lock ancestors with shared lock
          node.recursive_ancestors.lock('FOR SHARE').load if node.parent_id

          # Lock self and descendants with update lock.
          # Locking self is sufficient provided descendants also acquire ancestoral locks.
          node.becomes(Namespace).lock!('FOR NO KEY UPDATE') # rubocop:disable Cop/AvoidBecomes -- Normalize STI queries
        end
      rescue ActiveRecord::QueryCanceled => e
        if e.message.include?("canceling statement due to statement timeout")
          db_query_timeout_counter.increment(source: 'Namespace#sync_traversal_ids!')
        end

        raise
      rescue ActiveRecord::Deadlocked
        db_deadlock_counter.increment(source: 'Namespace#sync_traversal_ids!')
        raise
      end

      def db_query_timeout_counter
        Gitlab::Metrics.counter(:db_query_timeout, 'Counts the times the query timed out')
      end

      def db_deadlock_counter
        Gitlab::Metrics.counter(:db_deadlock, 'Counts the times we have deadlocked in the database')
      end
    end
    # rubocop:enable Database/RescueQueryCanceled
  end
end
