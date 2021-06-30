# frozen_string_literal: true

module Integrations
  class ExternalWiki < Integration
    include ActionView::Helpers::UrlHelper

    prop_accessor :external_wiki_url
    validates :external_wiki_url, presence: true, public_url: true, if: :activated?

    def title
      s_('ExternalWikiService|External wiki')
    end

    def description
      s_('ExternalWikiService|Link to an external wiki from the sidebar.')
    end

    def self.to_param
      'external_wiki'
    end

    def fields
      [
        {
          type: 'text',
          name: 'external_wiki_url',
          title: s_('ExternalWikiService|External wiki URL'),
          placeholder: s_('ExternalWikiService|https://example.com/xxx/wiki/...'),
          help: 'Enter the URL to the external wiki.',
          required: true
        }
      ]
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/wiki/index', anchor: 'link-an-external-wiki'), target: '_blank', rel: 'noopener noreferrer'

      s_('Link an external wiki from the project\'s sidebar. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def execute(_data)
      response = Gitlab::HTTP.get(properties['external_wiki_url'], verify: true, use_read_total_timeout: true)
      response.body if response.code == 200
    rescue StandardError
      nil
    end

    def self.supported_events
      %w()
    end
  end
end
