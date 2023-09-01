# frozen_string_literal: true

class AddFindingIdToVulnerabilities < Gitlab::Database::Migration[2.1]
  def up
    add_column :vulnerabilities, :finding_id, :bigint, if_not_exists: true
  end

  def down
    remove_column :vulnerabilities, :finding_id
  end
end
