# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will fill the project_repositories table for projects that
    # are on hashed storage and an entry is is missing in this table.
    class BackfillHashedProjectRepositories < BackfillProjectRepositories
      private

      def projects
        Project.on_hashed_storage
      end
    end
  end
end
