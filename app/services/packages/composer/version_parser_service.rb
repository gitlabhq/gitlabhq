# frozen_string_literal: true

module Packages
  module Composer
    class VersionParserService
      def initialize(tag_name: nil, branch_name: nil)
        @tag_name = tag_name
        @branch_name = branch_name
      end

      def execute
        if @tag_name.present?
          @tag_name.delete_prefix('v')
        elsif @branch_name.present?
          branch_suffix_or_prefix(@branch_name.match(Gitlab::Regex.composer_package_version_regex))
        end
      end

      private

      def branch_suffix_or_prefix(match)
        if match
          captures = match.captures.reject(&:blank?)
          if captures[-1] == '.x'
            captures[0] + '-dev'
          else
            captures[0] + '.x-dev'
          end
        else
          "dev-#{@branch_name}"
        end
      end
    end
  end
end
