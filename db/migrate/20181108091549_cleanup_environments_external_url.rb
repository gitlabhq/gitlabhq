# frozen_string_literal: true

class CleanupEnvironmentsExternalUrl < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:environments, :external_url, nil) do |table, query|
      query.where(table[:external_url].matches('javascript://%'))
    end
  end

  def down
  end
end
