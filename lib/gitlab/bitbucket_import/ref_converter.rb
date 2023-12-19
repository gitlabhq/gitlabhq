# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class RefConverter
      REPO_MATCHER = 'https://bitbucket.org/%s'
      PR_NOTE_ISSUE_NAME_REGEX = "(issues\/.*\/(.*)\\))"
      UNWANTED_NOTE_REF_HTML = "{: data-inline-card='' }"

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def convert_note(note)
        repo_matcher = REPO_MATCHER % project.import_source

        return note unless note.match?(repo_matcher)

        note = note.gsub(repo_matcher, url_helpers.project_url(project))
                   .gsub(UNWANTED_NOTE_REF_HTML, '')
                   .strip

        if note.match?('issues')
          note.gsub!('issues', '-/issues')
          note.gsub!("/#{issue_name(note)}", '') if issue_name(note)
        else
          note.gsub!('pull-requests', '-/merge_requests')
          note.gsub!('src', '-/blob')
          note.gsub!('lines-', 'L')
        end

        note
      end

      private

      def url_helpers
        Rails.application.routes.url_helpers
      end

      def issue_name(note)
        match_data = note.match(PR_NOTE_ISSUE_NAME_REGEX)

        return unless match_data

        match_data[2]
      end
    end
  end
end
