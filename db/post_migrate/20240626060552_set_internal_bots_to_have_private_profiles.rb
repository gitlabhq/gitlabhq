# frozen_string_literal: true

class SetInternalBotsToHavePrivateProfiles < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  # NOTE: There are some other internal users defined else where, but we'd like to
  # just focus on bots that are defined in Users::Internal
  BOT_TYPES = {
    support_bot: 1,
    alert_bot: 2,
    visual_review_bot: 3,
    migration_bot: 7,
    security_bot: 8,
    automation_bot: 9,
    admin_bot: 11,
    suggested_reviewers_bot: 12,
    llm_bot: 14,
    duo_code_review_bot: 16
  }

  class User < MigrationRecord
    self.table_name = 'users'
  end

  def up
    # We would have only 1 user per bot type so simple iteration should be fine
    User.where(user_type: BOT_TYPES.values).find_each do |user|
      user.private_profile = true

      # I suppose it won't matter much, but preserve existing value just in case
      user.confirmed_at = Time.zone.now unless user.confirmed_at.present?

      user.save
    end
  end

  def down
    # no op
  end
end
