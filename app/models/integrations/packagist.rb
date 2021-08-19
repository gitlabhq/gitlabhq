# frozen_string_literal: true

module Integrations
  class Packagist < Integration
    include HasWebHook
    extend Gitlab::Utils::Override

    prop_accessor :username, :token, :server

    validates :username, presence: true, if: :activated?
    validates :token, presence: true, if: :activated?

    default_value_for :push_events, true
    default_value_for :tag_push_events, true

    def title
      'Packagist'
    end

    def description
      s_('Integrations|Keep your PHP dependencies updated on Packagist.')
    end

    def self.to_param
      'packagist'
    end

    def fields
      [
        {
          type: 'text',
          name: 'username',
          title: _('Username'),
          help: s_('Enter your Packagist username.'),
          placeholder: '',
          required: true
        },
        {
          type: 'text',
          name: 'token',
          title: _('Token'),
          help: s_('Enter your Packagist token.'),
          placeholder: '',
          required: true
        },
        {
          type: 'text',
          name: 'server',
          title: _('Server (optional)'),
          help: s_('Enter your Packagist server. Defaults to https://packagist.org.'),
          placeholder: 'https://packagist.org',
          required: false
        }
      ]
    end

    def self.supported_events
      %w(push merge_request tag_push)
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      execute_web_hook!(data)
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

    override :hook_url
    def hook_url
      base_url = server.presence || 'https://packagist.org'
      "#{base_url}/api/update-package?username=#{username}&apiToken=#{token}"
    end
  end
end
