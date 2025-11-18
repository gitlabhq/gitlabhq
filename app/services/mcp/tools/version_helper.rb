# frozen_string_literal: true

module Mcp
  module Tools
    module VersionHelper
      def validate_semantic_version(version)
        return false if version.nil? || version.empty?

        ::Gitlab::Regex.semver_regex.match?(version.to_s)
      end
    end
  end
end
