# frozen_string_literal: true

class RemoveFreeUserCapRemediationWorker < Gitlab::Database::Migration[2.0]
  def up
    Sidekiq::Cron::Job.find('free_user_cap_data_remediation')&.destroy
  end

  def down
    # no-op
  end
end
