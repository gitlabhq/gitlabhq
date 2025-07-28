# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUserDetailsRegistrationObjectiveColumn < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  def up
    remove_column :user_details, :registration_objective
  end

  def down
    add_column(:user_details, :registration_objective, :smallint, if_not_exists: true)
  end
end
