# frozen_string_literal: true

class ValidateFindingIdOnVulnerabilities < Gitlab::Database::Migration[2.2]
  # obtained by running `\d vulnerabilities` on https://console.postgres.ai
  FK_NAME = :fk_4e64972902

  milestone '16.8'

  # validated asynchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131979
  def up
    validate_foreign_key :vulnerabilities, :finding_id, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
    # https://docs.gitlab.com/ee/development/database/add_foreign_key_to_existing_column.html#add-a-migration-to-validate-the-fk-synchronously
  end
end
