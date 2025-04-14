# frozen_string_literal: true

require 'gitlab/housekeeper/push_options'

module Gitlab
  module Housekeeper
    class Change
      attr_accessor :identifiers,
        :title,
        :description,
        :changed_files,
        :labels,
        :keep_class,
        :changelog_type,
        :changelog_ee,
        :mr_web_url,
        :push_options,
        :non_housekeeper_changes
      attr_reader :assignees,
        :reviewers

      def initialize
        @labels = []
        @assignees = []
        @reviewers = []
        @non_housekeeper_changes = []
        @push_options = PushOptions.new
        @aborted = false
      end

      def assignees=(assignees)
        @assignees = Array(assignees)
      end

      def reviewers=(reviewers)
        @reviewers = Array(reviewers)
      end

      def abort!
        @aborted = true
      end

      def aborted?
        @aborted
      end

      def mr_description
        <<~MARKDOWN
        #{description}

        This change was generated by
        [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
        using the #{keep_class} keep.

        To provide feedback on your experience with `gitlab-housekeeper` please create an issue with the
        label ~"GitLab Housekeeper" and consider pinging the author of this keep.
        MARKDOWN
      end

      def commit_message
        <<~MARKDOWN.chomp
        #{title}

        #{mr_description}

        Changelog: #{changelog_type || 'other'}
        #{changelog_ee ? "EE: true\n" : ''}
        MARKDOWN
      end

      def update_required?(category)
        !category.in?(non_housekeeper_changes)
      end

      def already_approved?
        non_housekeeper_changes.include?(:approvals)
      end

      def valid?
        @identifiers && @title && @description && @changed_files.present?
      end
    end
  end
end
