# frozen_string_literal: true

module Integrations
  class Assembla < Integration
    prop_accessor :token, :subdomain
    validates :token, presence: true, if: :activated?

    def title
      'Assembla'
    end

    def description
      _('Manage projects.')
    end

    def self.to_param
      'assembla'
    end

    def fields
      [
        {
          type: 'password',
          name: 'token',
          non_empty_password_title: s_('ProjectService|Enter new token'),
          non_empty_password_help: s_('ProjectService|Leave blank to use your current token.'),
          placeholder: '',
          required: true
        },
        {
          type: 'text',
          name: 'subdomain',
          placeholder: ''
        }
      ]
    end

    def self.supported_events
      %w(push)
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      url = "https://atlas.assembla.com/spaces/#{subdomain}/github_tool?secret_key=#{token}"
      Gitlab::HTTP.post(url, body: { payload: data }.to_json, headers: { 'Content-Type' => 'application/json' })
    end
  end
end
