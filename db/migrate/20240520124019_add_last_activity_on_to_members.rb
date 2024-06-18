# frozen_string_literal: true

class AddLastActivityOnToMembers < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :members, :last_activity_on, :date, default: -> { 'NOW()' }
  end
end
