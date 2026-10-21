# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class RefConverter
      REPO_MATCHER = 'https://bitbucket.org/%s'
      UNWANTED_NOTE_REF_HTML = "{: data-inline-card='' }"

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def convert_note(note)
        repo_url = REPO_MATCHER % project.import_source
        # A Bitbucket slug can contain letters, digits, `_`, `-` and `.`, so a `.` ends the
        # repo name only when no slug character follows it. This keeps `repo.git` and
        # `repo.name` out, but still converts a link that ends a sentence.
        url_pattern = %r{#{Regexp.escape(repo_url)}(?!\.*[\w-])[^\s)\]]*}

        return note unless note.match?(url_pattern)

        note.gsub(UNWANTED_NOTE_REF_HTML, '')
            .gsub(url_pattern) { |url| convert_url(url, repo_url) }
            .strip
      end

      private

      # Issues are not imported, so a converted issue link would point to a missing GitLab issue.
      def convert_url(url, repo_url)
        path = url.delete_prefix(repo_url)

        return url if path.start_with?('/issues')

        path = path.sub(%r{\A/pull-requests}, '/-/merge_requests')
                   .sub(%r{\A/src}, '/-/blob')
                   .sub('#lines-', '#L')

        "#{url_helpers.project_url(project)}#{path}"
      end

      def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
