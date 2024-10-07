# frozen_string_literal: true

require 'app_store_connect'

module Integrations
  class AppleAppStore < Integration
    ISSUER_ID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
    KEY_ID_REGEX = /\A(?=.*[A-Z])(?=.*[0-9])[A-Z0-9]+\z/
    IS_KEY_CONTENT_BASE64 = "true"

    SECTION_TYPE_APPLE_APP_STORE = 'apple_app_store'

    with_options if: :activated? do
      validates :app_store_issuer_id, presence: true, format: { with: ISSUER_ID_REGEX }
      validates :app_store_key_id, presence: true, format: { with: KEY_ID_REGEX }
      validates :app_store_private_key, presence: true, certificate_key: true
      validates :app_store_private_key_file_name, presence: true
      validates :app_store_protected_refs, inclusion: [true, false]
    end

    field :app_store_issuer_id,
      section: SECTION_TYPE_CONNECTION,
      required: true,
      title: -> { s_('AppleAppStore|Apple App Store Connect issuer ID') },
      description: -> { s_('AppleAppStore|Apple App Store Connect issuer ID.') }

    field :app_store_key_id,
      section: SECTION_TYPE_CONNECTION,
      required: true,
      title: -> { s_('AppleAppStore|Apple App Store Connect key ID') },
      description: -> { s_('AppleAppStore|Apple App Store Connect key ID.') }

    field :app_store_private_key_file_name,
      description: -> { s_('Apple App Store Connect private key file name.') },
      section: SECTION_TYPE_CONNECTION,
      required: true

    field :app_store_private_key,
      description: -> { s_('Apple App Store Connect private key.') },
      required: true,
      api_only: true

    field :app_store_protected_refs,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('AppleAppStore|Protected branches and tags only') },
      description: -> { s_('AppleAppStore|Set variables on protected branches and tags only.') },
      checkbox_label: -> { s_('AppleAppStore|Set variables on protected branches and tags only') }

    def self.title
      'Apple App Store Connect'
    end

    def self.description
      s_('AppleAppStore|Use GitLab to build and release an app in the Apple App Store.')
    end

    def self.help
      variable_list = [
        ActionController::Base.helpers.content_tag(:code, 'APP_STORE_CONNECT_API_KEY_ISSUER_ID'),
        ActionController::Base.helpers.content_tag(:code, 'APP_STORE_CONNECT_API_KEY_KEY_ID'),
        ActionController::Base.helpers.content_tag(:code, 'APP_STORE_CONNECT_API_KEY_KEY'),
        ActionController::Base.helpers.content_tag(:code, 'APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64')
      ]

      docs_link = ActionController::Base.helpers.link_to(
        '',
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/apple_app_store.md'),
        target: '_blank',
        rel: 'noopener noreferrer'
      )
      tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

      texts = [
        s_("Use this integration to connect to the Apple App Store with fastlane in CI/CD pipelines."),
        s_("After you enable the integration, the following protected variables are created for CI/CD use:"),
        ActionController::Base.helpers.safe_join(variable_list, ActionController::Base.helpers.tag(:br)),
        safe_format(s_("For more information, see the %{link_start}documentation%{link_end}."), tag_pair_docs_link)
      ]

      ActionController::Base.helpers.safe_join(texts, ActionController::Base.helpers.tag(:br) * 2)
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
          type: SECTION_TYPE_APPLE_APP_STORE,
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

    def ci_variables(protected_ref:)
      return [] unless activated?
      return [] if app_store_protected_refs && !protected_ref

      [
        { key: 'APP_STORE_CONNECT_API_KEY_ISSUER_ID', value: app_store_issuer_id, masked: true, public: false },
        { key: 'APP_STORE_CONNECT_API_KEY_KEY', value: Base64.encode64(app_store_private_key), masked: true,
          public: false },
        { key: 'APP_STORE_CONNECT_API_KEY_KEY_ID', value: app_store_key_id, masked: true, public: false },
        { key: 'APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64', value: IS_KEY_CONTENT_BASE64, masked: false,
          public: false }
      ]
    end

    def initialize_properties
      super
      self.app_store_protected_refs = true if app_store_protected_refs.nil?
    end

    private

    def client
      AppStoreConnect::Client.new(
        issuer_id: app_store_issuer_id,
        key_id: app_store_key_id,
        private_key: app_store_private_key
      )
    end
  end
end
