# frozen_string_literal: true

module Integrations
  module Base
    module MicrosoftTeams
      extend ActiveSupport::Concern
      include Base::ChatNotification

      class_methods do
        def title
          'Microsoft Teams notifications'
        end

        def description
          'Send notifications about project events to Microsoft Teams.'
        end

        def to_param
          'microsoft_teams'
        end

        # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- legacy use
        def help
          '<p>Use this service to send notifications about events in ' \
            'GitLab projects to your Microsoft Teams channels. ' \
            '<a href="https://docs.gitlab.com/ee/user/project/integrations/microsoft_teams.html" target="_blank" ' \
            'rel="noopener noreferrer">How do I configure this integration?</a></p>'
        end
        # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl

        def supported_events
          %w[push issue confidential_issue merge_request note confidential_note tag_push
            pipeline wiki_page]
        end
      end

      included do
        field :webhook,
          section: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
          help: -> { _('The Microsoft Teams webhook (for example, `https://outlook.office.com/webhook/...`).') },
          required: true

        field :notify_only_broken_pipelines,
          type: :checkbox,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          description: -> { _('Send notifications for broken pipelines.') },
          help: 'If selected, successful pipelines do not trigger a notification event.'

        field :branches_to_be_notified,
          type: :select,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          title: -> { s_('Integrations|Branches for which notifications are to be sent') },
          description: -> do
            _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, and ' \
              '`default_and_protected`. The default value is `default`.')
          end,
          choices: -> { branch_choices }

        def default_channel_placeholder; end

        private

        def notify(message, _opts)
          ::MicrosoftTeams::Notifier.new(webhook).ping(
            title: message.project_name,
            activity: message.activity,
            attachments: message.attachments
          )
        end

        def custom_data(data)
          super.merge(markdown: true)
        end
      end
    end
  end
end
