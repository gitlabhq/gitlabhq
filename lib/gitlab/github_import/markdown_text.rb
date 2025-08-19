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

        def fetch_attachments(text, web_endpoint)
          attachments = []
          return attachments if text.nil?

          doc = CommonMarker.render_doc(text)

          doc.walk do |node|
            attachment = extract_attachment(node, web_endpoint)
            attachments << attachment if attachment
          end
          attachments
        end

        private

        def extract_attachment(node, web_endpoint)
          ::Gitlab::GithubImport::Markdown::Attachment.from_markdown(node, web_endpoint)
        end
      end

      # text - The Markdown text as a String.
      # author - An instance of `Gitlab::GithubImport::Representation::User`
      # exists - Boolean that indicates the user exists in the GitLab database.
      # project - An instance of `Project`.
      def initialize(text, author = nil, exists = false, project: nil, client: nil)
        @text = text
        @author = author
        @exists = exists
        @project = project
        @web_endpoint = client&.web_endpoint || ::Octokit::Default.web_endpoint
      end

      def perform
        return if text.blank?

        # Gitlab::EncodingHelper#clean remove `null` chars from the string
        text = clean(formatted_text)
        text = convert_ref_links(text, project, web_endpoint) if project.present?
        wrap_mentions_in_backticks(text)
      end

      private

      attr_reader :text, :author, :exists, :project, :web_endpoint

      def formatted_text
        login = author.respond_to?(:fetch) ? author.fetch(:login, nil) : author.try(:login)
        return "*Created by: #{login}*\n\n#{text}" if login.present? && !exists

        text
      end

      # Links like `https://domain.github.com/<namespace>/<project>/pull/<iid>` needs to be converted
      def convert_ref_links(text, project, web_endpoint)
        web_endpoint = web_endpoint.chop if web_endpoint.end_with?('/')
        matcher_options = { github_url: web_endpoint, import_source: project.import_source }
        issue_ref_matcher = ISSUE_REF_MATCHER % matcher_options
        pull_ref_matcher = PULL_REF_MATCHER % matcher_options

        url_helpers = Rails.application.routes.url_helpers
        text.gsub(issue_ref_matcher, url_helpers.project_issues_url(project))
            .gsub(pull_ref_matcher, url_helpers.project_merge_requests_url(project))
      end
    end
  end
end
