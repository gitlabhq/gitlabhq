# frozen_string_literal: true

class ConfirmProjectBotUsers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class User < ApplicationRecord
    self.table_name = 'users'

    include ::EachBatch

    USER_TYPE_PROJECT_BOT = 6

    scope :project_bots, -> { where(user_type: USER_TYPE_PROJECT_BOT) }
    scope :unconfirmed, -> { where(confirmed_at: nil) }
  end

  def up
    User.reset_column_information

    User.project_bots.unconfirmed.each_batch do |relation|
      relation.update_all('confirmed_at = created_at')
    end
  end

  def down
    # no-op
  end
end
