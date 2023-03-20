# frozen_string_literal: true

module Integrations
  class GooglePlay < Integration
    SECTION_TYPE_GOOGLE_PLAY = 'google_play'

    with_options if: :activated? do
      validates :service_account_key, presence: true, json_schema: {
        filename: "google_service_account_key", parse_json: true
      }
      validates :service_account_key_file_name, presence: true
    end

    field :service_account_key_file_name,
      section: SECTION_TYPE_CONNECTION,
      required: true,
      is_secret: false

    field :service_account_key, api_only: true, is_secret: false

    def title
      s_('GooglePlay|Google Play')
    end

    def description
      s_('GooglePlay|Use GitLab to build and release an app in Google Play.')
    end

    def help
      variable_list = [
        '<code>SUPPLY_JSON_KEY_DATA</code>'
      ]

      # rubocop:disable Layout/LineLength
      texts = [
        s_("Use the Google Play integration to connect to Google Play with fastlane in CI/CD pipelines."),
        s_("After you enable the integration, the following protected variable is created for CI/CD use:"),
        variable_list.join('<br>'),
        s_(format("To generate a Google Play service account key and use this integration, see the <a href='%{url}' target='_blank'>integration documentation</a>.", url: "#")).html_safe
      ]
      # rubocop:enable Layout/LineLength

      texts.join('<br><br>'.html_safe)
    end

    def self.to_param
      'google_play'
    end

    def self.supported_events
      []
    end

    def sections
      [
        {
          type: SECTION_TYPE_GOOGLE_PLAY,
          title: s_('Integrations|Integration details'),
          description: help
        }
      ]
    end

    def test(*_args)
      client.fetch_access_token!
      { success: true }
    rescue Signet::AuthorizationError => error
      { success: false, message: error }
    end

    def ci_variables
      return [] unless activated?

      [
        { key: 'SUPPLY_JSON_KEY_DATA', value: service_account_key, masked: true, public: false }
      ]
    end

    private

    def client
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(service_account_key),
        scope: ['https://www.googleapis.com/auth/androidpublisher']
      )
    end
  end
end
