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

        repository.create_from_bundle(path_to_bundle)
      rescue => e
        Repositories::DestroyService.new(repository).execute

        shared.error(e)
        false
      end

      private

      attr_accessor :repository, :path_to_bundle, :shared
    end
  end
end
