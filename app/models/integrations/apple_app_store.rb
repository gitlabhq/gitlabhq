# frozen_string_literal: true

require 'app_store_connect'

module Integrations
  class AppleAppStore < Integration
    ISSUER_ID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/.freeze
    KEY_ID_REGEX = /\A(?=.*[A-Z])(?=.*[0-9])[A-Z0-9]+\z/.freeze

    with_options if: :activated? do
      validates :app_store_issuer_id, presence: true, format: { with: ISSUER_ID_REGEX }
      validates :app_store_key_id, presence: true, format: { with: KEY_ID_REGEX }
      validates :app_store_private_key, presence: true, certificate_key: true
    end

    field :app_store_issuer_id,
          section: SECTION_TYPE_CONNECTION,
          required: true,
          title: -> { s_('AppleAppStore|The Apple App Store Connect Issuer ID.') }

    field :app_store_key_id,
          section: SECTION_TYPE_CONNECTION,
          required: true,
          title: -> { s_('AppleAppStore|The Apple App Store Connect Key ID.') },
          is_secret: false

    field :app_store_private_key,
          section: SECTION_TYPE_CONNECTION,
          required: true,
          type: 'textarea',
          title: -> { s_('AppleAppStore|The Apple App Store Connect Private Key.') },
          is_secret: false

    def title
      'Apple App Store Connect'
    end

    def description
      s_('AppleAppStore|Use GitLab to build and release an app in the Apple App Store.')
    end

    def help
      variable_list = [
        '<code>APP_STORE_CONNECT_API_KEY_ISSUER_ID</code>',
        '<code>APP_STORE_CONNECT_API_KEY_KEY_ID</code>',
        '<code>APP_STORE_CONNECT_API_KEY_KEY</code>'
      ]

      # rubocop:disable Layout/LineLength
      texts = [
        s_("Use the Apple App Store Connect integration to easily connect to the Apple App Store with Fastlane in CI/CD pipelines."),
        s_("After the Apple App Store Connect integration is activated, the following protected variables will be created for CI/CD use."),
        variable_list.join('<br>'),
        s_(format("To get started, see the <a href='%{url}' target='_blank'>integration documentation</a> for instructions on how to generate App Store Connect credentials, and how to use this integration.", url: "https://docs.gitlab.com/ee/integration/apple_app_store.html")).html_safe
      ]
      # rubocop:enable Layout/LineLength

      texts.join('<br><br>'.html_safe)
    end

    def self.to_param
      'apple_app_store'
    end

    def self.supported_events
      []
    end

    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Integration details'),
          description: help
        }
      ]
    end

    def test(*_args)
      response = client.apps
      if response.has_key?(:errors)
        { success: false, message: response[:errors].first[:title] }
      else
        { success: true }
      end
    end

    def ci_variables
      return [] unless activated?

      [
        { key: 'APP_STORE_CONNECT_API_KEY_ISSUER_ID', value: app_store_issuer_id, masked: true, public: false },
        { key: 'APP_STORE_CONNECT_API_KEY_KEY', value: Base64.encode64(app_store_private_key), masked: true,
          public: false },
        { key: 'APP_STORE_CONNECT_API_KEY_KEY_ID', value: app_store_key_id, masked: true, public: false }
      ]
    end

    private

    def client
      config = {
        issuer_id: app_store_issuer_id,
        key_id: app_store_key_id,
        private_key: app_store_private_key
      }

      AppStoreConnect::Client.new(config)
    end
  end
end
