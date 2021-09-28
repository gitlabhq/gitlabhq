# frozen_string_literal: true

class AddRegistrationObjectiveToUserDetail < Gitlab::Database::Migration[1.0]
  def change
    add_column :user_details, :registration_objective, :smallint
  end
end
