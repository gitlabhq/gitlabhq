class ExternalWikiService < Service
  prop_accessor :external_wiki_url

  validates :external_wiki_url, presence: true, url: true, if: :activated?

  def title
    'External Wiki'
  end

  def description
    'Replaces the link to the internal wiki with a link to an external wiki.'
  end

  def self.to_param
    'external_wiki'
  end

  def fields
    [
      { type: 'text', name: 'external_wiki_url', placeholder: 'The URL of the external Wiki', required: true }
    ]
  end

  def execute(_data)
    @response = Gitlab::HTTP.get(properties['external_wiki_url'], verify: true) rescue nil
    if @response != 200
      nil
    end
  end

  def self.supported_events
    %w()
  end
end
