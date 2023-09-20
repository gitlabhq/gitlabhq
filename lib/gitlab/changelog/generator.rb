# frozen_string_literal: true

module Gitlab
  module Changelog
    # Parsing and generating of Markdown changelogs.
    class Generator
      # The regex used to parse a release header.
      RELEASE_REGEX =
        /^##\s+(?<version>#{Gitlab::Regex.unbounded_semver_regex})/

      # The `input` argument must be a `String` containing the existing
      # changelog Markdown. If no changelog exists, this should be an empty
      # `String`.
      def initialize(input = '')
        @lines = input.lines
        @locations = {}

        @lines.each_with_index do |line, index|
          matches = line.match(RELEASE_REGEX)

          next if !matches || !matches[:version]

          @locations[matches[:version]] = index
        end
      end

      # Generates the Markdown for the given release and returns the new
      # changelog Markdown content.
      #
      # The `release` argument must be an instance of
      # `Gitlab::Changelog::Release`.
      def add(release)
        versions = [release.version, *@locations.keys]

        VersionSorter.rsort!(versions)

        new_index = versions.index(release.version)
        new_lines = @lines.dup
        markdown = release.to_markdown

        if (insert_after = versions[new_index + 1])
          line_index = @locations[insert_after]

          new_lines.insert(line_index, markdown)
        else
          # When adding to the end of the changelog, the previous section only
          # has a single newline, resulting in the release section title
          # following it immediately. When this is the case, we insert an extra
          # empty line to keep the changelog readable in its raw form.
          new_lines.push("\n") if versions.length > 1
          new_lines.push(markdown.rstrip)
          new_lines.push("\n")
        end

        new_lines.join
      end
    end
  end
end
