# frozen_string_literal: true

module Integrations
  class Packagist < Integration
    include HasWebHook

    field :username,
      title: -> { _('Username') },
      help: -> { _('Username of a Packagist account.') },
      placeholder: '',
      required: true

    field :token,
      type: :password,
      title: -> { _('Token') },
      help: -> { _('API token of the Packagist server.') },
      non_empty_password_title: -> { s_('ProjectService|Enter new token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
      placeholder: '',
      required: true

    field :server,
      title: -> { _('Server (optional)') },
      help: -> { _('URL of the Packagist server. The default value is `https://packagist.org`.') },
      placeholder: 'https://packagist.org',
      exposes_secrets: true,
      required: false

    validates :username, presence: true, if: :activated?
    validates :token, presence: true, if: :activated?

    def self.title
      'Packagist'
    end

    def self.description
      s_('Integrations|Keep your PHP dependencies updated on Packagist.')
    end

    def self.to_param
      'packagist'
    end

    def self.supported_events
      %w[push merge_request tag_push]
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      execute_web_hook!(data)
    end

    def test(data)
      begin
        result = execute(data)
        return { success: false, result: result.message } if result.payload[:http_status] != 202
      rescue StandardError => e
        return { success: false, result: e.message }
      end

      { success: true, result: result.message }
    end

    override :hook_url
    def hook_url
      base_url = server.presence || 'https://packagist.org'
      "#{base_url}/api/update-package?username={username}&apiToken={token}"
    end

    def url_variables
      { 'username' => username, 'token' => token }
    end
  end
end
