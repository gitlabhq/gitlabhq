# frozen_string_literal: true

class RemoveCreationsInGitlabSubscriptionHistories < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  GITLAB_SUBSCRIPTION_CREATED = 0

  def up
    return unless Gitlab.com?

    delete_sql = "DELETE FROM gitlab_subscription_histories WHERE change_type=#{GITLAB_SUBSCRIPTION_CREATED} RETURNING *"

    records = execute(delete_sql)

    logger = Gitlab::BackgroundMigration::Logger.build
    records.to_a.each do |record|
      logger.info record.as_json.merge(message: "gitlab_subscription_histories with change_type=0 was deleted")
    end
  end

  def down
    # There's no way to restore, and the data is useless
    # all the data to be deleted in case needed https://gitlab.com/gitlab-org/gitlab/uploads/7409379b0ed658624f5d33202b5668a1/gitlab_subscription_histories_change_type_0.sql.txt
  end
end
