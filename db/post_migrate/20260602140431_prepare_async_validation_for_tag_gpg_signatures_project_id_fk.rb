# frozen_string_literal: true

class PrepareAsyncValidationForTagGpgSignaturesProjectIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  FK_NAME = 'fk_ebf091e1c4'

  # TODO: FK to be validated synchronously in a follow-up MR
  def up
    prepare_async_foreign_key_validation :tag_gpg_signatures, :project_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :tag_gpg_signatures, :project_id, name: FK_NAME
  end
end
