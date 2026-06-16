# frozen_string_literal: true

class ReplaceTagGpgSignaturesProjectIdFkWithCascade < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  OLD_FK_NAME = 'fk_ebf091e1c4'

  def up
    remove_foreign_key_if_exists :tag_gpg_signatures, column: :project_id, on_delete: :nullify, name: OLD_FK_NAME
    add_concurrent_foreign_key :tag_gpg_signatures, :projects, column: :project_id, on_delete: :cascade,
      validate: false, name: OLD_FK_NAME
  end

  def down
    remove_foreign_key_if_exists :tag_gpg_signatures, column: :project_id, on_delete: :cascade, name: OLD_FK_NAME
    add_concurrent_foreign_key :tag_gpg_signatures, :projects, column: :project_id, on_delete: :nullify,
      name: OLD_FK_NAME
  end
end
