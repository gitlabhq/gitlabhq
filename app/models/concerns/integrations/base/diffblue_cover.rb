# frozen_string_literal: true

module Integrations
  module Base
    module DiffblueCover
      extend ActiveSupport::Concern

      class_methods do
        def title
          'Diffblue Cover'
        end

        def description
          s_('DiffblueCover|Automatically write comprehensive, human-like Java unit tests.')
        end

        def to_param
          'diffblue_cover'
        end

        def help
          s_('DiffblueCover|Automatically write comprehensive, human-like Java unit tests.')
        end

        def supported_events
          []
        end

        def diffblue_link
          ActionController::Base.helpers.link_to(
            s_('DiffblueCover|Try Diffblue Cover'),
            'https://www.diffblue.com/try-cover/gitlab/',
            target: '_blank',
            rel: 'noopener noreferrer'
          )
        end
      end

      included do
        field :diffblue_license_key,
          section: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
          type: :password,
          title: -> { s_('DiffblueCover|License key') },
          description: -> { s_('DiffblueCover|Diffblue Cover license key.') },
          non_empty_password_title: -> { s_('DiffblueCover|License key') },
          non_empty_password_help: -> {
            s_(
              'DiffblueCover|Leave blank to use your current license key.'
            )
          },
          exposes_secrets: true,
          required: true,
          is_secret: true,
          placeholder: 'XXXX-XXXX-XXXX-XXXX',
          help: -> {
            format(
              s_(
                'DiffblueCover|Enter your Diffblue Cover license key or ' \
                  'go to %{diffblue_link} to obtain a free trial license.'
              ),
              diffblue_link: diffblue_link
            )
          }

        field :diffblue_access_token_name,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          title: -> { s_('DiffblueCover|Name') },
          description: -> { s_('DiffblueCover|Access token name used by Diffblue Cover in pipelines.') },
          required: true,
          placeholder: -> { s_('DiffblueCover|My token name') }

        field :diffblue_access_token_secret,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          type: :password,
          title: -> { s_('DiffblueCover|Secret') },
          description: -> { s_('DiffblueCover|Access token secret used by Diffblue Cover in pipelines.') },
          non_empty_password_title: -> { s_('DiffblueCover|Secret') },
          non_empty_password_help: -> { s_('DiffblueCover|Leave blank to use your current secret value.') },
          required: true,
          is_secret: true,
          placeholder: 'glpat-XXXXXXXXXXXXXXXXXXXX' # gitleaks:allow

        with_options if: :activated? do
          validates :diffblue_license_key, presence: true
          validates :diffblue_access_token_name, presence: true
          validates :diffblue_access_token_secret, presence: true
        end
      end

      def avatar_url
        ActionController::Base.helpers.image_path('illustrations/third-party-logos/integrations-logos/diffblue.svg')
      end

      def sections
        [
          {
            type: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
            title: s_('DiffblueCover|Integration details'),
            description:
              s_(
                'DiffblueCover|Diffblue Cover is a generative AI platform that automatically ' \
                  'writes comprehensive, human-like Java unit tests. Integrate Diffblue ' \
                  'Cover into your CI/CD workflow for fully autonomous operation.'
              )
          },
          {
            type: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
            title: s_('DiffblueCover|Access token'),
            description:
              'You must have a GitLab access token for Diffblue Cover to access your project. ' \
              'Use a GitLab access token with at least the Developer role and ' \
              'the <code>api</code> and <code>write_repository</code> permissions.'
          }
        ]
      end

      def execute(_data) end

      def ci_variables
        return [] unless activated?

        [
          { key: 'DIFFBLUE_LICENSE_KEY', value: diffblue_license_key, public: false, masked: true },
          { key: 'DIFFBLUE_ACCESS_TOKEN_NAME', value: diffblue_access_token_name, public: false, masked: true },
          { key: 'DIFFBLUE_ACCESS_TOKEN', value: diffblue_access_token_secret, public: false, masked: true }
        ]
      end

      def testable?
        false
      end
    end
  end
end
