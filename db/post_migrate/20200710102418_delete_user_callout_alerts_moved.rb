# frozen_string_literal: true

class DeleteUserCalloutAlertsMoved < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class UserCallout < ActiveRecord::Base
    include EachBatch

    self.table_name = 'user_callouts'
  end

  BATCH_SIZE = 1_000

  # Inlined from Enums::UserCallout.feature_names
  FEATURE_NAME_ALERTS_MOVED = 20

  def up
    UserCallout.each_batch(of: BATCH_SIZE, column: :user_id) do |callout|
      callout.where(feature_name: FEATURE_NAME_ALERTS_MOVED).delete_all
    end
  end

  def down
    # no-op
  end
end
