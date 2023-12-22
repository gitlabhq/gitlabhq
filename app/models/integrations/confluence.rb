# frozen_string_literal: true

module Integrations
  class Confluence < BaseThirdPartyWiki
    VALID_SCHEME_MATCH = %r{\Ahttps?\Z}
    VALID_HOST_MATCH = %r{\A.+\.atlassian\.net\Z}
    VALID_PATH_MATCH = %r{\A/wiki(/|\Z)}

    validates :confluence_url, presence: true, if: :activated?
    validate :validate_confluence_url_is_cloud, if: :activated?

    field :confluence_url,
      title: -> { _('Confluence Workspace URL') },
      description: -> { _("URL of the Confluence Workspace hosted on `atlassian.net`.") },
      placeholder: 'https://example.atlassian.net/wiki',
      required: true

    def avatar_url
      ActionController::Base.helpers.image_path('confluence.svg')
    end

    def self.to_param
      'confluence'
    end

    def self.title
      s_('ConfluenceService|Confluence Workspace')
    end

    def self.description
      s_('ConfluenceService|Link to a Confluence Workspace from the sidebar.')
    end

    def help
      return unless project&.wiki_enabled?

      if activated?
        wiki_url = project.wiki.web_url

        s_(
          'ConfluenceService|Your GitLab wiki is still available at %{wiki_link}. To re-enable the link to the GitLab wiki, disable this integration.' %
          { wiki_link: ActionController::Base.helpers.link_to(wiki_url, wiki_url) }
        ).html_safe
      else
        s_('ConfluenceService|Link to a Confluence Workspace from the sidebar. Enabling this integration replaces the "Wiki" sidebar link with a link to the Confluence Workspace. The GitLab wiki is still available at the original URL.').html_safe
      end
    end

    def testable?
      false
    end

    private

    def validate_confluence_url_is_cloud
      unless confluence_uri_valid?
        errors.add(:confluence_url, 'URL must be to a Confluence Cloud Workspace hosted on atlassian.net')
      end
    end

    def confluence_uri_valid?
      return false unless confluence_url

      uri = URI.parse(confluence_url)

      (uri.scheme&.match(VALID_SCHEME_MATCH) &&
        uri.host&.match(VALID_HOST_MATCH) &&
        uri.path&.match(VALID_PATH_MATCH)).present?

    rescue URI::InvalidURIError
      false
    end
  end
end
