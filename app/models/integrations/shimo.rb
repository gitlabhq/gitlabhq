# frozen_string_literal: true

module Integrations
  class Shimo < BaseThirdPartyWiki
    validates :external_wiki_url, presence: true, public_url: true, if: :activated?

    field :external_wiki_url,
      title: -> { s_('Shimo|Shimo Workspace URL') },
      required: true

    def render?
      valid? && activated?
    end

    def title
      s_('Shimo|Shimo')
    end

    def description
      s_('Shimo|Link to a Shimo Workspace from the sidebar.')
    end

    def self.to_param
      'shimo'
    end

    # support for `test` method
    def execute(_data)
      response = Gitlab::HTTP.get(properties['external_wiki_url'], verify: true)
      response.body if response.code == 200
    rescue StandardError
      nil
    end
  end
end
