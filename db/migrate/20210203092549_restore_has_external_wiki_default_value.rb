# frozen_string_literal: true

class RestoreHasExternalWikiDefaultValue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class TmpProject < ActiveRecord::Base
    self.table_name = 'projects'
  end

  # This reverts the following migration: change_column_default(:projects, :has_external_wiki, from: nil, to: false)
  # We only change the column when the current default value is false
  def up
    # Find out the current default value
    column = TmpProject.columns.find { |c| c.name == 'has_external_wiki' }
    return unless column

    if column.default == 'false'
      with_lock_retries do
        change_column_default(:projects, :has_external_wiki, from: false, to: nil)
      end
    end
  end

  def down
    # no-op
  end
end
