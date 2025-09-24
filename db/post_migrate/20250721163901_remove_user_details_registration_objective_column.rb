# frozen_string_literal: true

class RemoveUserDetailsRegistrationObjectiveColumn < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  def up
    remove_column :user_details, :registration_objective
  end

  def down
    add_column(:user_details, :registration_objective, :smallint, if_not_exists: true)
  end
end
