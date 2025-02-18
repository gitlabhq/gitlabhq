# frozen_string_literal: true

module Integrations
  module Base
    module ExternalWiki
      extend ActiveSupport::Concern

      class_methods do
        def title
          s_('ExternalWikiService|External wiki')
        end

        def description
          s_('ExternalWikiService|Link to an external wiki from the sidebar.')
        end

        def help
          build_help_page_url(
            'user/project/wiki/_index.md',
            s_('Link an external wiki from the project\'s sidebar.'),
            { anchor: 'link-an-external-wiki' }
          )
        end

        def to_param
          'external_wiki'
        end

        def supported_events
          %w[]
        end
      end

      included do
        validates :external_wiki_url, presence: true, public_url: true, if: :activated?

        field :external_wiki_url,
          section: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
          title: -> { s_('ExternalWikiService|External wiki URL') },
          description: -> { s_('ExternalWikiService|URL of the external wiki.') },
          placeholder: -> { s_('ExternalWikiService|https://example.com/xxx/wiki/...') },
          help: -> { s_('ExternalWikiService|Enter the URL to the external wiki.') },
          required: true

        def sections
          [
            {
              type: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
              title: s_('Integrations|Connection details'),
              description: help
            }
          ]
        end
      end

      def execute(_data)
        response = Gitlab::HTTP.get(properties['external_wiki_url'], verify: true)
        response.body if response.code == 200
      rescue StandardError
        nil
      end
    end
  end
end
