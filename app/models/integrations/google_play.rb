# frozen_string_literal: true

module Integrations
  class GooglePlay < Integration
    PACKAGE_NAME_REGEX = /\A[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*){1,20}\z/

    SECTION_TYPE_GOOGLE_PLAY = 'google_play'

    with_options if: :activated? do
      validates :service_account_key, presence: true, json_schema: {
        filename: "google_service_account_key", parse_json: true
      }
      validates :service_account_key_file_name, presence: true
      validates :package_name, presence: true, format: { with: PACKAGE_NAME_REGEX }
    end

    field :package_name,
      section: SECTION_TYPE_CONNECTION,
      placeholder: 'com.example.myapp',
      required: true

    field :service_account_key_file_name,
      section: SECTION_TYPE_CONNECTION,
      required: true

    field :service_account_key, api_only: true

    def title
      s_('GooglePlay|Google Play')
    end

    def description
      s_('GooglePlay|Use GitLab to build and release an app in Google Play.')
    end

    def help
      variable_list = [
        '<code>SUPPLY_PACKAGE_NAME</code>',
        '<code>SUPPLY_JSON_KEY_DATA</code>'
      ]

      # rubocop:disable Layout/LineLength
      texts = [
        s_("Use the Google Play integration to connect to Google Play with fastlane in CI/CD pipelines."),
        s_("After you enable the integration, the following protected variable is created for CI/CD use:"),
        variable_list.join('<br>'),
        s_(format("To generate a Google Play service account key and use this integration, see the <a href='%{url}' target='_blank'>integration documentation</a>.", url: Rails.application.routes.url_helpers.help_page_url('user/project/integrations/google_play'))).html_safe
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
      client.list_reviews(package_name)
      { success: true }
    rescue Google::Apis::ClientError => error
      { success: false, message: error }
    end

    def ci_variables
      return [] unless activated?

      [
        { key: 'SUPPLY_JSON_KEY_DATA', value: service_account_key, masked: true, public: false },
        { key: 'SUPPLY_PACKAGE_NAME', value: package_name, masked: false, public: false }
      ]
    end

    private

    def client
      service = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new # rubocop: disable CodeReuse/ServiceClass

      service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(service_account_key),
        scope: [Google::Apis::AndroidpublisherV3::AUTH_ANDROIDPUBLISHER]
      )

      service
    end
  end
end
