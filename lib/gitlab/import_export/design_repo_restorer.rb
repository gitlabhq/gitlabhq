# frozen_string_literal: true

module Gitlab
  module ImportExport
    class DesignRepoRestorer < RepoRestorer
      def initialize(project:, shared:, path_to_bundle:)
        super(project: project, shared: shared, path_to_bundle: path_to_bundle)

        @repository = project.design_repository
      end

      # `restore` method is handled in super class
    end
  end
end
