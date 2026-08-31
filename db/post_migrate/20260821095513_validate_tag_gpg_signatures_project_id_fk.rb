# frozen_string_literal: true

class ValidateTagGpgSignaturesProjectIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  FK_NAME = 'fk_ebf091e1c4'

  def up
    # FK was validated asynchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238703
    validate_foreign_key :tag_gpg_signatures, :project_id, name: FK_NAME
  end

  def down
    # no-op: validating a foreign key does not require a rollback step
  end
end
