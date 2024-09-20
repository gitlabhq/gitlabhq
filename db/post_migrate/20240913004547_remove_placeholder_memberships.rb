# frozen_string_literal: true

class RemovePlaceholderMemberships < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.5'

  PLACEHOLDER_TYPE_ID = 15

  def up
    connection.execute(
      <<~SQL
        DELETE FROM members
        WHERE members.id IN (
          SELECT members.id
          FROM members
          INNER JOIN users
          ON users.id = members.user_id
          WHERE users.user_type = #{PLACEHOLDER_TYPE_ID}
        );
      SQL
    )
  end

  def down
    # no-op
  end
end
