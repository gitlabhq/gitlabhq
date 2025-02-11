# frozen_string_literal: true

module Integrations
  module Base
    module Pumble
      extend ActiveSupport::Concern

      include Base::ChatNotification
      include HasAvatar

      class_methods do
        def title
          'Pumble'
        end

        def description
          s_("PumbleIntegration|Send notifications about project events to Pumble.")
        end

        def to_param
          'pumble'
        end

        def help
          build_help_page_url(
            'user/project/integrations/pumble.md',
            s_("PumbleIntegration|Send notifications about project events to Pumble.")
          )
        end

        def supported_events
          %w[push issue confidential_issue merge_request note confidential_note tag_push
            pipeline wiki_page]
        end
      end

      included do
        field :webhook,
          section: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
          help: -> { _('The Pumble webhook (for example, `https://api.pumble.com/workspaces/x/...`).') },
          required: true

        field :notify_only_broken_pipelines,
          type: :checkbox,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          help: 'If selected, successful pipelines do not trigger a notification event.',
          description: -> { _('Send notifications for broken pipelines.') }

        field :branches_to_be_notified,
          type: :select,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          title: -> { s_('Integrations|Branches for which notifications are to be sent') },
          description: -> {
            _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
              'and `default_and_protected`. The default value is `default`.')
          },
          choices: -> { branch_choices }

        def default_channel_placeholder; end

        private

        def notify(message, _opts)
          header = { 'Content-Type' => 'application/json' }
          response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump({ text: message.summary }))

          response if response.success?
        end
      end
    end
  end
end
