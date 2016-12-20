class ChangeSlackServiceToSlackNotificationServiceInBatches < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    update_column_in_batches(:services, :type, 'SlackNotificationService') do |table, query|
      query.where(table[:type].eq('SlackService'))
    end
  end

  def down
    update_column_in_batches(:services, :type, 'SlackService') do |table, query|
      query.where(table[:type].eq('SlackNotificationService'))
    end
  end
end
