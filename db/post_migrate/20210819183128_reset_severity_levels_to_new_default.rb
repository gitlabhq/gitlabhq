# frozen_string_literal: true

class ResetSeverityLevelsToNewDefault < ActiveRecord::Migration[6.1]
  ALL_SEVERITY_LEVELS = 6 # ::Enums::Vulnerability::SEVERITY_LEVELS.count

  def up
    execute(<<~SQL.squish)
      UPDATE approval_project_rules
      SET severity_levels = '{unknown, high, critical}'
      WHERE array_length(severity_levels, 1) = #{ALL_SEVERITY_LEVELS};
    SQL
  end

  def down
    # no-op
  end
end
