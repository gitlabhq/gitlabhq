# frozen_string_literal: true

class AddTextLimitToTimelogsSummary < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :timelogs, :summary, 255
  end

  def down
    remove_text_limit :timelogs, :summary
  end
end
