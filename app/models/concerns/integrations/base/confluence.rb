# frozen_string_literal: true

module Integrations
  module Base
    module Confluence
      extend ActiveSupport::Concern
      include Base::ThirdPartyWiki

      VALID_SCHEME_MATCH = Gitlab::UntrustedRegexp.new('^https?$')
      VALID_HOST_MATCH = Gitlab::UntrustedRegexp.new('^.+\\.atlassian\\.net$')
      VALID_PATH_MATCH = Gitlab::UntrustedRegexp.new('^/wiki(/|$)')

      class_methods do
        def to_param
          'confluence'
        end

        def title
          s_('ConfluenceService|Confluence Workspace')
        end

        def description
          s_('ConfluenceService|Link to a Confluence Workspace from the sidebar.')
        end
      end

      included do
        validates :confluence_url, presence: true, if: :activated?
        validate :validate_confluence_url_is_cloud, if: :activated?

        field :confluence_url,
          title: -> { _('Confluence Workspace URL') },
          description: -> { _("URL of the Confluence Workspace hosted on `atlassian.net`.") },
          placeholder: 'https://example.atlassian.net/wiki',
          required: true
      end

      def avatar_url
        ActionController::Base.helpers.image_path('confluence.svg')
      end

      def help
        return unless project&.wiki_enabled?

        if activated?
          wiki_url = project.wiki.web_url

          docs_link = ActionController::Base.helpers.link_to('', wiki_url, target: '_blank', rel: 'noopener noreferrer')
          tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

          safe_format(
            s_("'ConfluenceService|Your GitLab wiki is still available at %{link_start}%{wiki_url}%{link_end}. " \
              "To re-enable the link to the GitLab wiki, disable this integration."), tag_pair_docs_link, wiki_url:)
        else
          s_('ConfluenceService|Link to a Confluence Workspace from the sidebar. Enabling this integration replaces ' \
            'the "Wiki" sidebar link with a link to the Confluence Workspace. The GitLab wiki is still available at ' \
            'the original URL.')
        end
      end

      def testable?
        false
      end

      private

      def validate_confluence_url_is_cloud
        return if confluence_uri_valid?

        errors.add(:confluence_url, 'URL must be to a Confluence Cloud Workspace hosted on atlassian.net')
      end

      def confluence_uri_valid?
        return false unless confluence_url

        uri = URI.parse(confluence_url)

        (
          VALID_SCHEME_MATCH.match?(uri.scheme) &&
          VALID_HOST_MATCH.match?(uri.host) &&
          VALID_PATH_MATCH.match?(uri.path)
        ).present?

      rescue URI::InvalidURIError
        false
      end
    end
  end
end
