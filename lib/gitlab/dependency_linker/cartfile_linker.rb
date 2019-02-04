# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class CartfileLinker < MethodLinker
      self.file_type = :cartfile

      private

      def link_dependencies
        link_method_call('github', REPO_REGEX, &method(:github_url))
        link_method_call(%w[github git binary], URL_REGEX, &:itself)
      end
    end
  end
end
