# frozen_string_literal: true

class CleanupEventsPersonalNamespaceIdGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class PersonalNamespace < MigrationRecord
    self.table_name = 'namespaces'
  end

  def up
    return unless Gitlab.com_except_jh?

    events_model = define_batchable_model('events')
    events_model.where.not(personal_namespace_id: nil)
      .distinct_each_batch(column: :personal_namespace_id, of: 100) do |batch|
        namespace_ids = batch.pluck(:personal_namespace_id)
        namespaces_query = PersonalNamespace
          .where('events.personal_namespace_id = namespaces.id')
          .select(1)

        events_model
          .where(personal_namespace_id: namespace_ids)
          .where('NOT EXISTS (?)', namespaces_query)
          .delete_all
      end
  end

  def down
    # no-op
  end
end
