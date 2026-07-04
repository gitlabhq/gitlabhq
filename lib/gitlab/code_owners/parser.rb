# frozen_string_literal: true

module Gitlab
  module CodeOwners
    # Represents a single CODEOWNERS rule.
    Entry = Struct.new(:pattern, :owners, :section, :optional, keyword_init: true)

    # Parses a CODEOWNERS file and resolves owners for any given path.
    #
    # File format (subset supported by GitHub / GitLab):
    #   # comment
    #   [Section Name]          <- named section (informational)
    #   ^[Optional Section]     <- optional section (approval not required)
    #   /path/pattern @owner1 @org/team user@example.com
    #
    # Last matching entry wins (same precedence rule as GitHub/GitLab EE).
    class Parser
      def initialize(blob_data)
        @blob_data = blob_data
      end

      # Returns parsed entries in file order.
      def entries
        @entries ||= parse
      end

      # Returns the array of owner strings for the given absolute path
      # (e.g. "/app/models/user.rb"). Returns [] when no rule matches.
      def owners_for_path(path)
        path = "/#{path}" unless path.start_with?('/')

        matched = nil
        entries.each { |e| matched = e if path_matches?(e.pattern, path) }

        matched ? matched.owners : []
      end

      private

      def parse
        result = []
        current_section = 'codeowners'
        current_optional = false

        @blob_data.each_line do |raw|
          line = raw.chomp.strip
          next if line.empty? || line.start_with?('#')

          # Section header: [Name] or ^[Name] (optional)
          if (m = line.match(/\A(\^?)\[([^\]]+)\]/))
            current_optional = m[1] == '^'
            current_section  = m[2]
            next
          end

          parts = line.split(/\s+/)
          next if parts.empty?

          result << Entry.new(
            pattern:  parts[0],
            owners:   parts[1..],
            section:  current_section,
            optional: current_optional
          )
        end

        result
      end

      # Copied and adapted from tooling/lib/tooling/find_codeowners.rb
      # (which itself was copied from ee/lib/gitlab/code_owners/file.rb).
      def path_matches?(pattern, path)
        flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME | ::File::FNM_EXTGLOB
        ::File.fnmatch?(normalize_pattern(pattern), path, flags)
      end

      def normalize_pattern(pattern)
        pattern = pattern.sub(/\A\\#/, '#')
        pattern = pattern.gsub(/\\\s+/, ' ')

        return '/**/*' if pattern == '*'

        pattern = "/**/#{pattern}" unless pattern.start_with?('/')
        pattern = "#{pattern}**/*"  if pattern.end_with?('/')

        pattern
      end
    end
  end
end
