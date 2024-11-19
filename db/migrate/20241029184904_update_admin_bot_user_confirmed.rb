# frozen_string_literal: true

class UpdateAdminBotUserConfirmed < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.6'

  def up
    execute <<~SQL
      UPDATE "users" SET "confirmed_at" = now(), "private_profile" = TRUE WHERE "users"."user_type" = 11
    SQL
  end

  def down
    # noop
  end
end
