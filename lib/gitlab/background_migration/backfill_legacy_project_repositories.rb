# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will fill the project_repositories table for projects that
    # are on legacy storage and an entry is is missing in this table.
    class BackfillLegacyProjectRepositories < BackfillProjectRepositories
      private

      def projects
        Project.with_parent.on_legacy_storage
      end
    end
  end
end
