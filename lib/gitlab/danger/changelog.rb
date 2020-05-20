# frozen_string_literal: true

module Gitlab
  module Danger
    module Changelog
      NO_CHANGELOG_LABELS = %w[backstage ci-build meta].freeze
      NO_CHANGELOG_CATEGORIES = %i[docs none].freeze

      def needed?
        categories_need_changelog? && (gitlab.mr_labels & NO_CHANGELOG_LABELS).empty?
      end

      def found
        @found ||= git.added_files.find { |path| path =~ %r{\A(ee/)?(changelogs/unreleased)(-ee)?/} }
      end

      def sanitized_mr_title
        gitlab.mr_json["title"].gsub(/^WIP: */, '').gsub(/`/, '\\\`')
      end

      def ee_changelog?
        found.start_with?('ee/')
      end

      private

      def categories_need_changelog?
        (helper.changes_by_category.keys - NO_CHANGELOG_CATEGORIES).any?
      end
    end
  end
end
