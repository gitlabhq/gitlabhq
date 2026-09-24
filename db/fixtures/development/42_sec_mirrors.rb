# frozen_string_literal: true

# Mirrors namespaces and projects into the sec database, so that sec tables can
# be joined on organization_id and traversal_ids without querying main.
# Upserts keyed on the natural primary keys, so re-running is a no-op.
Gitlab::Seeder.quiet do
  Namespace.each_batch do |batch|
    rows = batch.pluck(:id, :organization_id, :traversal_ids).map do |id, organization_id, traversal_ids|
      { namespace_id: id, organization_id: organization_id, traversal_ids: traversal_ids }
    end

    Security::NamespaceMirror.upsert_all(rows, unique_by: :namespace_id) if rows.any?
  end

  Project.each_batch do |batch|
    rows = batch.pluck(:id, :namespace_id, :organization_id).map do |id, namespace_id, organization_id|
      { project_id: id, namespace_id: namespace_id, organization_id: organization_id }
    end

    Security::ProjectMirror.upsert_all(rows, unique_by: :project_id) if rows.any?
  end
end
