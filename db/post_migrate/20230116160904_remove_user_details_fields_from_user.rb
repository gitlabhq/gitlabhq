# frozen_string_literal: true

class RemoveUserDetailsFieldsFromUser < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    %i[linkedin twitter skype website_url].each do |column|
      remove_column :users, column, :string, null: false, default: ''
    end
    %i[location organization].each do |column|
      remove_column :users, column, :string, null: true
    end
  end
end
