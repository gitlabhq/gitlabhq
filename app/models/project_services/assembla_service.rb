class AssemblaService < Service
  include HTTParty

  prop_accessor :token, :subdomain
  validates :token, presence: true, if: :activated?

  def title
    'Assembla'
  end

  def description
    'Project Management Software (Source Commits Endpoint)'
  end

  def to_param
    'assembla'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' },
      { type: 'text', name: 'subdomain', placeholder: '' }
    ]
  end

  def supported_events
    %w[push]
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    url = "https://atlas.assembla.com/spaces/#{subdomain}/github_tool?secret_key=#{token}"
    AssemblaService.post(url, body: { payload: data }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
