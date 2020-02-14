# frozen_string_literal: true

class RemovePackagesDeprecatedDependencies < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute('DELETE FROM packages_dependency_links WHERE dependency_type = 5')
  end

  def down
    # There is nothing to do to reverse this migration
  end
end
