# frozen_string_literal: true

module Integrations
  class ExternalWiki < Integration
    validates :external_wiki_url, presence: true, public_url: true, if: :activated?

    field :external_wiki_url,
      section: SECTION_TYPE_CONNECTION,
      title: -> { s_('ExternalWikiService|External wiki URL') },
      description: -> { s_('ExternalWikiService|URL of the external wiki.') },
      placeholder: -> { s_('ExternalWikiService|https://example.com/xxx/wiki/...') },
      help: -> { s_('ExternalWikiService|Enter the URL to the external wiki.') },
      required: true

    def self.title
      s_('ExternalWikiService|External wiki')
    end

    def self.description
      s_('ExternalWikiService|Link to an external wiki from the sidebar.')
    end

    def self.help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/wiki/index', anchor: 'link-an-external-wiki'), target: '_blank', rel: 'noopener noreferrer'

      s_('Link an external wiki from the project\'s sidebar. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'external_wiki'
    end

    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Connection details'),
          description: help
        }
      ]
    end

    def execute(_data)
      response = Gitlab::HTTP.get(properties['external_wiki_url'], verify: true)
      response.body if response.code == 200
    rescue StandardError
      nil
    end

    def self.supported_events
      %w[]
    end
  end
end
