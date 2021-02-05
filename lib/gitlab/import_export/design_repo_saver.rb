# frozen_string_literal: true

module Gitlab
  module ImportExport
    class DesignRepoSaver < RepoSaver
      extend ::Gitlab::Utils::Override

      override :repository
      def repository
        @repository ||= exportable.design_repository
      end

      private

      override :bundle_filename
      def bundle_filename
        ::Gitlab::ImportExport.design_repo_bundle_filename
      end
    end
  end
end
