# frozen_string_literal: true

class RemoveRecordsWithoutProjectFromProjectSavedRepliesTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ProjectsSavedReply < MigrationRecord
    self.table_name = 'project_saved_replies'

    include EachBatch
  end

  class Project < MigrationRecord
    self.table_name = 'projects'
  end

  def up
    ProjectsSavedReply.each_batch(of: 100) do |records|
      records.where('NOT EXISTS (?)', Project.where('project_saved_replies.project_id=projects.id')).delete_all
    end
  end

  def down
    # no-op
  end
end
