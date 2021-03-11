# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class GoModLinker < BaseLinker
      include Gitlab::Golang

      self.file_type = :go_mod

      private

      SEMVER = Gitlab::Regex.unbounded_semver_regex
      NAME = Gitlab::Regex.go_package_regex
      REGEX = Regexp.new("(?<name>#{NAME.source})(?:\\s+(?<version>v#{SEMVER.source}))?", SEMVER.options | NAME.options).freeze

      # rubocop: disable CodeReuse/ActiveRecord
      def link_dependencies
        highlighted_lines.map!.with_index do |rich_line, i|
          plain_line = plain_lines[i].chomp
          match = REGEX.match(plain_line)
          next rich_line unless match

          i, j = match.offset(:name)
          marker = StringRangeMarker.new(plain_line, rich_line.html_safe)
          marker.mark([i..(j - 1)]) do |text, left:, right:, mode:|
            url = package_url(text, match[:version])
            url ? link_tag(text, url) : text
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
