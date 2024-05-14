# frozen_string_literal: true

module Keeps
  module Helpers
    class GitDiffParser
      def all_changed_files(diff)
        result = Set.new
        diff.each_line do |line|
          match = line.match(%r{^diff --git a/(.*) b/(.*)$})
          result.merge(match.captures) if match
        end

        result.to_a
      end
    end
  end
end
