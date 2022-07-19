# frozen_string_literal: true

module Gitlab
  module GithubImport
    class MarkdownText
      include Gitlab::EncodingHelper

      ISSUE_REF_MATCHER = '%{github_url}/%{import_source}/issues'
      PULL_REF_MATCHER = '%{github_url}/%{import_source}/pull'

      class << self
        def format(*args)
          new(*args).to_s
        end

        # Links like `https://domain.github.com/<namespace>/<project>/pull/<iid>` needs to be converted
        def convert_ref_links(text, project)
          matcher_options = { github_url: github_url, import_source: project.import_source }
          issue_ref_matcher = ISSUE_REF_MATCHER % matcher_options
          pull_ref_matcher = PULL_REF_MATCHER % matcher_options

          url_helpers = Rails.application.routes.url_helpers
          text.gsub(issue_ref_matcher, url_helpers.project_issues_url(project))
              .gsub(pull_ref_matcher, url_helpers.project_merge_requests_url(project))
        end

        private

        # Returns github domain without slash in the end
        def github_url
          oauth_config = Gitlab::Auth::OAuth::Provider.config_for('github') || {}
          url = oauth_config['url'].presence || 'https://github.com'
          url = url.chop if url.end_with?('/')
          url
        end
      end

      # text - The Markdown text as a String.
      # author - An instance of `Gitlab::GithubImport::Representation::User`
      # exists - Boolean that indicates the user exists in the GitLab database.
      def initialize(text, author, exists = false)
        @text = text.to_s
        @author = author
        @exists = exists
      end

      def to_s
        # Gitlab::EncodingHelper#clean remove `null` chars from the string
        clean(format)
      end

      private

      attr_reader :text, :author, :exists

      def format
        if author&.login.present? && !exists
          "*Created by: #{author.login}*\n\n#{text}"
        else
          text
        end
      end
    end
  end
end
