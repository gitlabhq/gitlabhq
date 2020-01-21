# frozen_string_literal: true

class ExternalWikiService < Service
  prop_accessor :external_wiki_url

  validates :external_wiki_url, presence: true, public_url: true, if: :activated?

  def title
    s_('ExternalWikiService|External Wiki')
  end

  def description
    s_('ExternalWikiService|Replaces the link to the internal wiki with a link to an external wiki.')
  end

  def self.to_param
    'external_wiki'
  end

  def fields
    [
      {
        type: 'text',
        name: 'external_wiki_url',
        placeholder: s_('ExternalWikiService|The URL of the external Wiki'),
        required: true
      }
    ]
  end

  def execute(_data)
    response = Gitlab::HTTP.get(properties['external_wiki_url'], verify: true)
    response.body if response.code == 200
  rescue
    nil
  end

  def self.supported_events
    %w()
  end
end
