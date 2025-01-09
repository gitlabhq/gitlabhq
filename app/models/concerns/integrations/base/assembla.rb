# frozen_string_literal: true

module Integrations
  module Base
    module Assembla
      extend ActiveSupport::Concern

      class_methods do
        def title
          'Assembla'
        end

        def description
          _('Manage projects.')
        end

        def to_param
          'assembla'
        end

        def supported_events
          %w[push]
        end
      end

      included do
        validates :token, presence: true, if: :activated?

        field :token,
          type: :password,
          description: -> { s_('The authentication token.') },
          non_empty_password_title: -> { s_('ProjectService|Enter new token') },
          non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
          placeholder: '',
          required: true

        field :subdomain,
          description: -> { s_('The subdomain setting.') },
          exposes_secrets: true,
          placeholder: ''
      end

      def execute(data)
        return unless supported_events.include?(data[:object_kind])

        url = "https://atlas.assembla.com/spaces/#{URI.encode_www_form_component(subdomain)}/github_tool?secret_key=#{URI.encode_www_form_component(token)}"
        body = { payload: data }

        Gitlab::HTTP.post(
          url,
          body: Gitlab::Json.dump(body),
          headers: { 'Content-Type' => 'application/json' }
        )
      end
    end
  end
end
