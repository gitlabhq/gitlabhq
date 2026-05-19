# frozen_string_literal: true

class AddForeignKeyOnProjectImportExportRelationExportUploadUploadStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    # no-op to address https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/2195
  end

  def down
    # no-op to address https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/2195
  end
end
