# frozen_string_literal: true

# This class includes overriding Kernel#format method
# what makes impossible to use it here
# rubocop:disable Style/FormatString
module Gitlab
  module GithubImport
    class MarkdownText
      include Gitlab::EncodingHelper

      ISSUE_REF_MATCHER = '%{github_url}/%{import_source}/issues'
      PULL_REF_MATCHER = '%{github_url}/%{import_source}/pull'

      MEDIA_TYPES = %w[gif jpeg jpg mov mp4 png svg webm].freeze
      DOC_TYPES = %w[
        csv docx fodg fodp fods fodt gz log md odf odg odp ods
        odt pdf pptx tgz txt xls xlsx zip
      ].freeze
      ALL_TYPES = (MEDIA_TYPES + DOC_TYPES).freeze

      # On github.com we have base url for docs and CDN url for media.
      # On github EE as far as we can know there is no CDN urls and media is placed on base url.
      # To no escape the escaping symbol we use single quotes instead of double with interpolation.
      # rubocop:disable Style/StringConcatenation
      CDN_URL_MATCHER = '(!\[.+\]\(%{github_media_cdn}/\d+/(\w|-)+\.(' + MEDIA_TYPES.join('|') + ')\))'
      BASE_URL_MATCHER = '(\[.+\]\(%{github_url}/.+/.+/files/\d+/.+\.(' + ALL_TYPES.join('|') + ')\))'
      # rubocop:enable Style/StringConcatenation

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

        def fetch_attachment_urls(text)
          cdn_url_matcher = CDN_URL_MATCHER % { github_media_cdn: Regexp.escape(github_media_cdn) }
          doc_url_matcher = BASE_URL_MATCHER % { github_url: Regexp.escape(github_url) }

          text.scan(Regexp.new(cdn_url_matcher)).map(&:first) +
            text.scan(Regexp.new(doc_url_matcher)).map(&:first)
        end

        private

        def github_media_cdn
          'https://user-images.githubusercontent.com'
        end

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
# rubocop:enable Style/FormatString
