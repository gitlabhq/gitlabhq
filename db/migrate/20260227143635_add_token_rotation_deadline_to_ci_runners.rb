# frozen_string_literal: true

class AddTokenRotationDeadlineToCiRunners < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    add_column :ci_runners, :token_rotation_deadline, :datetime_with_timezone, if_not_exists: true
  end

  def down
    remove_column :ci_runners, :token_rotation_deadline, if_exists: true
  end
end
