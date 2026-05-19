# frozen_string_literal: true

class AddUniqueIndexOnProjectImportExportRelationExportUploadUploadsId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    # no-op to address https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/21955
  end

  def down
    # no-op to address https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/21955
  end
end
