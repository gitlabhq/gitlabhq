# frozen_string_literal: true

class AddFkAiAuditEventsToNamespaces < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  # No-op: this migration originally added a partitioned foreign key from
  # `ai_audit_events.namespace_id` to `namespaces.id` using
  # `add_concurrent_partitioned_foreign_key`. The final parent-attach step takes
  # an `ACCESS EXCLUSIVE` lock on both tables, which timed out against the
  # GitLab.com `namespaces` table and was marked as skipped via ChatOps.
  #
  # The strict foreign key has been replaced with a loose foreign key. The
  # equivalent FK removal for environments that already ran this migration
  # successfully lives in
  # `db/post_migrate/20260505183632_remove_namespaces_ai_audit_events_namespace_id_fk.rb`.
  def up
    # No-op
  end

  def down
    # No-op
  end
end
