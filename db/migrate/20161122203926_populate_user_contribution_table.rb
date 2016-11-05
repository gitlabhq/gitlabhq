# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateUserContributionTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    base_delay = Time.now + 15.minutes

    (Date.today - 1.year).upto(Date.today).each_with_index do |date, index|
      job_time = base_delay + index.minutes

      Sidekiq::Client.enqueue_to_in(:cronjob, job_time, UserContributionWorker, date)
    end
  end

  def down
    execute 'TRUNCATE user_contributions'
  end
end
