# frozen_string_literal: true

class RemoveLastEditedAtColumnFromVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  enable_lock_retries!

  def up
    remove_column :vulnerabilities, :last_edited_at
  end

  def down
    add_column :vulnerabilities, :last_edited_at, :datetime_with_timezone
  end
end
