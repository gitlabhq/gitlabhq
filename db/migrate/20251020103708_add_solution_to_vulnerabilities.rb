# frozen_string_literal: true

class AddSolutionToVulnerabilities < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :vulnerabilities, :solution, :text, if_not_exists: true
    end

    add_text_limit :vulnerabilities, :solution, 7000, validate: false
  end

  def down
    with_lock_retries do
      remove_column :vulnerabilities, :solution, if_exists: true
    end
  end
end
