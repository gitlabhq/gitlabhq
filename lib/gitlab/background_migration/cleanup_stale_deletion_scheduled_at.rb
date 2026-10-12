# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Clears namespace_details.deletion_scheduled_at on rows whose namespace is
    # not being deleted. Such rows predate the namespace state machine, which
    # now clears the column on cancel_deletion.
    class CleanupStaleDeletionScheduledAt < BatchedMigrationJob
      # namespaces.state values for namespaces that are actually being deleted.
      # Hard-coded so the job stays stable if the model's enum changes:
      # Namespace.states => { "deletion_scheduled" => 2, "deletion_in_progress" => 4 }.
      DELETING_STATES = [2, 4].freeze

      operation_name :cleanup_stale_deletion_scheduled_at
      feature_category :groups_and_projects

      # Uses the legacy primary-key strategy on purpose: the cursor strategy
      # ignores scope_to when computing batch bounds and would walk every
      # namespace_details row instead of the deletion_scheduled_at IS NOT NULL set.
      # rubocop:disable Database/AvoidScopeTo -- supporting index: index_namespace_details_on_id_and_deletion_scheduled_at ON namespace_details USING btree (namespace_id, deletion_scheduled_at) WHERE (deletion_scheduled_at IS NOT NULL)
      scope_to ->(relation) { relation.where.not(deletion_scheduled_at: nil) }
      # rubocop:enable Database/AvoidScopeTo

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where.not(deleting).update_all(deletion_scheduled_at: nil)
        end
      end

      private

      # Correlated on namespaces_pkey, so each check is an index lookup; there is
      # no index on namespaces.state that a NOT IN (SELECT ...) could use.
      def deleting
        define_batchable_model(:namespaces, connection: connection)
          .select(1)
          .where('namespaces.id = namespace_details.namespace_id')
          .where(state: DELETING_STATES)
          .arel.exists
      end
    end
  end
end
