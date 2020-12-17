# frozen_string_literal: true

module Gitlab
  module Danger
    module Changelog
      NO_CHANGELOG_LABELS = [
        'tooling',
        'tooling::pipelines',
        'tooling::workflow',
        'ci-build',
        'meta'
      ].freeze
      NO_CHANGELOG_CATEGORIES = %i[docs none].freeze
      CREATE_CHANGELOG_COMMAND = 'bin/changelog -m %<mr_iid>s "%<mr_title>s"'
      CREATE_EE_CHANGELOG_COMMAND = 'bin/changelog --ee -m %<mr_iid>s "%<mr_title>s"'
      CHANGELOG_MODIFIED_URL_TEXT = "**CHANGELOG.md was edited.** Please remove the additions and create a CHANGELOG entry.\n\n"
      CHANGELOG_MISSING_URL_TEXT = "**[CHANGELOG missing](https://docs.gitlab.com/ee/development/changelog.html)**:\n\n"

      OPTIONAL_CHANGELOG_MESSAGE = <<~MSG
      If you want to create a changelog entry for GitLab FOSS, run the following:

          #{CREATE_CHANGELOG_COMMAND}

      If you want to create a changelog entry for GitLab EE, run the following instead:

          #{CREATE_EE_CHANGELOG_COMMAND}

      If this merge request [doesn't need a CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry), feel free to ignore this message.
      MSG

      REQUIRED_CHANGELOG_MESSAGE = <<~MSG
      To create a changelog entry, run the following:

          #{CREATE_CHANGELOG_COMMAND}

      This merge request requires a changelog entry because it [introduces a database migration](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).
      MSG

      def required?
        git.added_files.any? { |path| path =~ %r{\Adb/(migrate|post_migrate)/} }
      end
      alias_method :db_changes?, :required?

      def optional?
        categories_need_changelog? && without_no_changelog_label?
      end

      def found
        @found ||= git.added_files.find { |path| path =~ %r{\A(ee/)?(changelogs/unreleased)(-ee)?/} }
      end

      def ee_changelog?
        found.start_with?('ee/')
      end

      def modified_text
        CHANGELOG_MODIFIED_URL_TEXT +
          format(OPTIONAL_CHANGELOG_MESSAGE, mr_iid: mr_iid, mr_title: sanitized_mr_title)
      end

      def required_text
        CHANGELOG_MISSING_URL_TEXT +
          format(REQUIRED_CHANGELOG_MESSAGE, mr_iid: mr_iid, mr_title: sanitized_mr_title)
      end

      def optional_text
        CHANGELOG_MISSING_URL_TEXT +
          format(OPTIONAL_CHANGELOG_MESSAGE, mr_iid: mr_iid, mr_title: sanitized_mr_title)
      end

      private

      def mr_iid
        gitlab.mr_json["iid"]
      end

      def sanitized_mr_title
        helper.sanitize_mr_title(gitlab.mr_json["title"])
      end

      def categories_need_changelog?
        (helper.changes_by_category.keys - NO_CHANGELOG_CATEGORIES).any?
      end

      def without_no_changelog_label?
        (gitlab.mr_labels & NO_CHANGELOG_LABELS).empty?
      end
    end
  end
end
