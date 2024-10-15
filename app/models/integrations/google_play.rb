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
      validates :google_play_protected_refs, inclusion: [true, false]
    end

    field :package_name,
      section: SECTION_TYPE_CONNECTION,
      placeholder: 'com.example.myapp',
      description: -> { _('Package name of the app in Google Play.') },
      required: true

    field :service_account_key_file_name,
      section: SECTION_TYPE_CONNECTION,
      required: true,
      description: -> { _('File name of the Google Play service account key.') }

    field :service_account_key,
      required: true,
      description: -> { _('Google Play service account key.') },
      api_only: true

    field :google_play_protected_refs,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('GooglePlayStore|Protected branches and tags only') },
      description: -> { _('Set variables on protected branches and tags only.') },
      checkbox_label: -> { s_('GooglePlayStore|Set variables on protected branches and tags only') }

    def self.title
      s_('GooglePlay|Google Play')
    end

    def self.description
      s_('GooglePlay|Use GitLab to build and release an app in Google Play.')
    end

    def self.help
      variable_list = [
        ActionController::Base.helpers.content_tag(:code, "SUPPLY_PACKAGE_NAME"),
        ActionController::Base.helpers.content_tag(:code, "SUPPLY_JSON_KEY_DATA")
      ]

      docs_link = ActionController::Base.helpers.link_to(
        '',
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/google_play.md'),
        target: '_blank',
        rel: 'noopener noreferrer'
      )
      tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

      texts = [
        s_("Use this integration to connect to Google Play with fastlane in CI/CD pipelines."),
        s_("After you enable the integration, the following protected variables are created for CI/CD use:"),
        ActionController::Base.helpers.safe_join(variable_list, ActionController::Base.helpers.tag(:br)),
        safe_format(s_("For more information, see the %{link_start}documentation%{link_end}."), tag_pair_docs_link)
      ]

      ActionController::Base.helpers.safe_join(texts, ActionController::Base.helpers.tag(:br) * 2)
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

    def ci_variables(protected_ref:)
      return [] unless activated?
      return [] if google_play_protected_refs && !protected_ref

      [
        { key: 'SUPPLY_JSON_KEY_DATA', value: service_account_key, masked: true, public: false },
        { key: 'SUPPLY_PACKAGE_NAME', value: package_name, masked: false, public: false }
      ]
    end

    def initialize_properties
      super
      self.google_play_protected_refs = true if google_play_protected_refs.nil?
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
