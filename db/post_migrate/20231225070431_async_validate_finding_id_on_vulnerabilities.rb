# frozen_string_literal: true

class AsyncValidateFindingIdOnVulnerabilities < Gitlab::Database::Migration[2.2]
  # obtained by running `\d vulnerabilities` on https://console.postgres.ai
  FK_NAME = :fk_4e64972902

  milestone '16.8'

  # TODO: FK to be validated synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/425409
  def up
    prepare_async_foreign_key_validation :vulnerabilities, :finding_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :vulnerabilities, :finding_id, name: FK_NAME
  end
end
