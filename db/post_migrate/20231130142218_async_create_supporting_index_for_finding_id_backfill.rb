# frozen_string_literal: true

class AsyncCreateSupportingIndexForFindingIdBackfill < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  INDEX_NAME = "tmp_index_vulnerabilities_on_id_finding_id_empty"

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/433253
  def up
    prepare_async_index(
      :vulnerabilities,
      :id,
      where: "finding_id IS NULL",
      name: INDEX_NAME
    )
  end

  def down
    unprepare_async_index(
      :vulnerabilities,
      :id,
      name: INDEX_NAME
    )
  end
end
