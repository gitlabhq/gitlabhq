# frozen_string_literal: true

module Gitlab
  module ImportExport
    class DesignRepoRestorer < RepoRestorer
      extend ::Gitlab::Utils::Override

      override :repository
      def repository
        @repository ||= importable.design_repository
      end

      # `restore` method is handled in super class
    end
  end
end
