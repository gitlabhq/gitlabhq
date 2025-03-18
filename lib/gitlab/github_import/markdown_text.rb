# frozen_string_literal: true

# This class includes overriding Kernel#format method
# what makes impossible to use it here
module Gitlab
  module GithubImport
    class MarkdownText
      include Gitlab::EncodingHelper
      include Gitlab::Import::UsernameMentionRewriter

      # On github.com we have base url for docs and CDN url for media.
      # On github EE as far as we can know there is no CDN urls and media is placed on base url.
      GITHUB_MEDIA_CDN = 'https://user-images.githubusercontent.com/'

      ISSUE_REF_MATCHER = '%{github_url}/%{import_source}/issues'
      PULL_REF_MATCHER = '%{github_url}/%{import_source}/pull'

      class << self
        def format(...)
          new(...).perform
        end

        def fetch_attachments(text)
          attachments = []
          return attachments if text.nil?

          doc = CommonMarker.render_doc(text)

          doc.walk do |node|
            attachment = extract_attachment(node)
            attachments << attachment if attachment
          end
          attachments
        end

        # Returns github domain without slash in the end
        def github_url
          oauth_config = Gitlab::Auth::OAuth::Provider.config_for('github') || {}
          url = oauth_config['url'].presence || 'https://github.com'
          url = url.chop if url.end_with?('/')
          url
        end

        private

        def extract_attachment(node)
          ::Gitlab::GithubImport::Markdown::Attachment.from_markdown(node)
        end
      end

      # text - The Markdown text as a String.
      # author - An instance of `Gitlab::GithubImport::Representation::User`
      # exists - Boolean that indicates the user exists in the GitLab database.
      # project - An instance of `Project`.
      def initialize(text, author = nil, exists = false, project: nil)
        @text = text
        @author = author
        @exists = exists
        @project = project
      end

      def perform
        return if text.blank?

        # Gitlab::EncodingHelper#clean remove `null` chars from the string
        text = clean(formatted_text)
        text = convert_ref_links(text, project) if project.present?
        wrap_mentions_in_backticks(text)
      end

      private

      attr_reader :text, :author, :exists, :project

      def formatted_text
        login = author.respond_to?(:fetch) ? author.fetch(:login, nil) : author.try(:login)
        return "*Created by: #{login}*\n\n#{text}" if login.present? && !exists

        text
      end

      # Links like `https://domain.github.com/<namespace>/<project>/pull/<iid>` needs to be converted
      def convert_ref_links(text, project)
        matcher_options = { github_url: self.class.github_url, import_source: project.import_source }
        issue_ref_matcher = ISSUE_REF_MATCHER % matcher_options
        pull_ref_matcher = PULL_REF_MATCHER % matcher_options

        url_helpers = Rails.application.routes.url_helpers
        text.gsub(issue_ref_matcher, url_helpers.project_issues_url(project))
            .gsub(pull_ref_matcher, url_helpers.project_merge_requests_url(project))
      end
    end
  end
end
