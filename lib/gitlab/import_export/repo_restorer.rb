# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:, path_to_bundle:)
        @repository = project.repository
        @path_to_bundle = path_to_bundle
        @shared = shared
      end

      def restore
        return true unless File.exist?(path_to_bundle)

        ensure_repository_does_not_exist!

        repository.create_from_bundle(path_to_bundle)
      rescue => e
        shared.error(e)
        false
      end

      private

      attr_accessor :repository, :path_to_bundle, :shared

      def ensure_repository_does_not_exist!
        if repository.exists?
          shared.logger.info(
            message: %Q{Deleting existing "#{repository.path}" to re-import it.}
          )

          Repositories::DestroyService.new(repository).execute
        end
      end
    end
  end
end
