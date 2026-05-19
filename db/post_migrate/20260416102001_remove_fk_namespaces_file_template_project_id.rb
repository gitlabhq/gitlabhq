# frozen_string_literal: true

class RemoveFkNamespacesFileTemplateProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    # no-op: replaced by 20260423130100_retry_remove_fk_namespaces_file_template_project_id
  end

  def down
    # no-op
  end
end
