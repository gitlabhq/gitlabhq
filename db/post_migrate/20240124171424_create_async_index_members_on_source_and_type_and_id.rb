# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateAsyncIndexMembersOnSourceAndTypeAndId < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  INDEX_NAME = 'index_members_on_source_and_type_and_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/439262
  def up
    prepare_async_index(
      :members,
      %i[source_id source_type type id],
      where: 'invite_token IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    unprepare_async_index_by_name(:members, INDEX_NAME)
  end
end
