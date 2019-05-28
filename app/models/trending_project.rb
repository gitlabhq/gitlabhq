# frozen_string_literal: true

class TrendingProject < ApplicationRecord
  belongs_to :project

  # The number of months to include in the trending calculation.
  MONTHS_TO_INCLUDE = 1

  # The maximum number of projects to include in the trending set.
  PROJECTS_LIMIT = 100

  # Populates the trending projects table with the current list of trending
  # projects.
  def self.refresh!
    # The calculation **must** run in a transaction. If the removal of data and
    # insertion of new data were to run separately a user might end up with an
    # empty list of trending projects for a short period of time.
    transaction do
      delete_all

      timestamp = connection.quote(MONTHS_TO_INCLUDE.months.ago)

      connection.execute <<-EOF.strip_heredoc
        INSERT INTO #{table_name} (project_id)
        SELECT project_id
        FROM notes
        INNER JOIN projects ON projects.id = notes.project_id
        WHERE notes.created_at >= #{timestamp}
        AND notes.system IS FALSE
        AND projects.visibility_level = #{Gitlab::VisibilityLevel::PUBLIC}
        GROUP BY project_id
        ORDER BY count(*) DESC
        LIMIT #{PROJECTS_LIMIT};
      EOF
    end
  end
end
