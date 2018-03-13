class PackagistService < Service
  prop_accessor :username, :token, :server

  validates :username, presence: true, if: :activated?
  validates :token, presence: true, if: :activated?

  default_value_for :push_events, true
  default_value_for :tag_push_events, true

  after_save :compose_service_hook, if: :activated?

  def title
    'Packagist'
  end

  def description
    'Update your project on Packagist, the main Composer repository'
  end

  def self.to_param
    'packagist'
  end

  def fields
    [
      { type: 'text', name: 'username', placeholder: '', required: true },
      { type: 'text', name: 'token', placeholder: '', required: true },
      { type: 'text', name: 'server', placeholder: 'https://packagist.org', required: false }
    ]
  end

  def self.supported_events
    %w(push merge_request tag_push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    service_hook.execute(data)
  end

  def test(data)
    begin
      result = execute(data)
      return { success: false, result: result[:message] } if result[:http_status] != 202
    rescue StandardError => error
      return { success: false, result: error }
    end

    { success: true, result: result[:message] }
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = hook_url
    hook.save
  end

  def hook_url
    base_url = server.present? ? server : 'https://packagist.org'
    "#{base_url}/api/update-package?username=#{username}&apiToken=#{token}"
  end
end
