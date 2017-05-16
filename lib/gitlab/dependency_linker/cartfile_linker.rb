module Gitlab
  module DependencyLinker
    class CartfileLinker < MethodLinker
      self.file_type = :cartfile

      private

      def link_dependencies
        link_method_call(%w[github git binary]) do |value|
          case value
          when %r{\A#{REPO_REGEX}\z}
            github_url(value)
          when /\A#{URL_REGEX}\z/
            value
          end
        end
      end
    end
  end
end
