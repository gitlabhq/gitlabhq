# frozen_string_literal: true

class CopyAdoptionSegmentsNamespace < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
    UPDATE analytics_devops_adoption_segments SET display_namespace_id = namespace_id
    WHERE display_namespace_id IS NULL
    SQL
  end

  def down
    execute 'UPDATE analytics_devops_adoption_segments SET display_namespace_id = NULL'
  end
end
