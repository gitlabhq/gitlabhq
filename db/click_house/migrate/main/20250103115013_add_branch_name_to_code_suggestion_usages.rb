# frozen_string_literal: true

class AddBranchNameToCodeSuggestionUsages < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE code_suggestion_usages
        ADD COLUMN IF NOT EXISTS branch_name String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE code_suggestion_usages
        DROP COLUMN IF EXISTS branch_name
    SQL
  end
end
