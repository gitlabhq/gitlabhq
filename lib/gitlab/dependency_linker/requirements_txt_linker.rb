# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class RequirementsTxtLinker < BaseLinker
      self.file_type = :requirements_txt

      private

      def link_dependencies
        link_regex(/^(?<name>(?![a-z+]+:)[^#.-][^ ><=~!;\[]+)/) do |name|
          "https://pypi.org/project/#{name}/"
        end

        link_regex(%r{^(?<name>https?://[^ ]+)}, &:itself)
      end
    end
  end
end
