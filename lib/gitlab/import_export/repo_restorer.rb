# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :importable

      def initialize(importable:, shared:, path_to_bundle:)
        @path_to_bundle = path_to_bundle
        @shared = shared
        @importable = importable
      end

      def restore
        return true unless File.exist?(path_to_bundle)

        ensure_repository_does_not_exist!

        repository.create_from_bundle(path_to_bundle)
        update_importable_repository_info

        true
      rescue StandardError => e
        shared.error(e)
        false
      end

      def repository
        @repository ||= importable.repository
      end

      private

      attr_accessor :path_to_bundle, :shared

      def update_importable_repository_info
        # No-op. Overridden in EE
      end

      def ensure_repository_does_not_exist!
        if repository.exists?
          shared.logger.info(
            message: %(Deleting existing "#{repository.disk_path}" to re-import it.)
          )

          ::Repositories::DestroyService.new(repository).execute

          # Because Gitlab::Git::Repository#remove happens inside a run_after_commit
          # callback in the ::Repositories::DestroyService#execute we need to trigger
          # the callback.
          repository.project.touch
        end
      end
    end
  end
end

Gitlab::ImportExport::RepoRestorer.prepend_mod_with('Gitlab::ImportExport::RepoRestorer')
