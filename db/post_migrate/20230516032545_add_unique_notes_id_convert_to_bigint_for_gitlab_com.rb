# frozen_string_literal: true

class AddUniqueNotesIdConvertToBigintForGitlabCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = :notes
  INDEX_NAME = :index_notes_on_id_convert_to_bigint

  def up
    return unless should_run?

    # This was created async for GitLab.com with
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119913
    # and will replace the existing PK index when we swap the integer and bigint columns in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119705
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint,
      unique: true,
      name: INDEX_NAME
  end

  def down
    return unless should_run?

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
