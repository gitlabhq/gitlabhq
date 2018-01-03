# rubocop:disable Migration/UpdateColumnInBatches
class RenameSlackAndMattermostNotificationServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:services, :type, 'SlackService') do |table, query|
      query.where(table[:type].eq('SlackNotificationService'))
    end

    update_column_in_batches(:services, :type, 'MattermostService') do |table, query|
      query.where(table[:type].eq('MattermostNotificationService'))
    end
  end

  def down
    update_column_in_batches(:services, :type, 'SlackNotificationService') do |table, query|
      query.where(table[:type].eq('SlackService'))
    end

    update_column_in_batches(:services, :type, 'MattermostNotificationService') do |table, query|
      query.where(table[:type].eq('MattermostService'))
    end
  end
end
