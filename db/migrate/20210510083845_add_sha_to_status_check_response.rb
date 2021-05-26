# frozen_string_literal: true

class AddShaToStatusCheckResponse < ActiveRecord::Migration[6.0]
  def up
    execute('DELETE FROM status_check_responses')

    add_column :status_check_responses, :sha, :binary, null: false # rubocop:disable Rails/NotNullColumn
  end

  def down
    remove_column :status_check_responses, :sha
  end
end
