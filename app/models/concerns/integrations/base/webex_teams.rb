# frozen_string_literal: true

module Integrations
  module Base
    module WebexTeams
      extend ActiveSupport::Concern
      include Base::ChatNotification

      class_methods do
        def title
          s_("WebexTeamsService|Webex Teams")
        end

        def description
          s_("WebexTeamsService|Send notifications about project events to Webex Teams.")
        end

        def to_param
          'webex_teams'
        end

        def help
          build_help_page_url(
            'user/project/integrations/webex_teams.md',
            s_("WebexTeamsService|Send notifications about project events to Webex Teams.")
          )
        end

        def supported_events
          %w[push issue confidential_issue merge_request note confidential_note tag_push pipeline wiki_page]
        end
      end

      included do
        field :webhook,
          section: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
          help: 'https://api.ciscospark.com/v1/webhooks/incoming/...',
          description: 'The Webex Teams webhook. For example, https://api.ciscospark.com/v1/webhooks/incoming/...',
          required: true

        field :notify_only_broken_pipelines,
          type: :checkbox,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          description: -> { _('Send notifications for broken pipelines.') }

        field :branches_to_be_notified,
          type: :select,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          title: -> { s_('Integrations|Branches for which notifications are to be sent') },
          description: -> do
            _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
              'and `default_and_protected`. The default value is `default`.')
          end,
          choices: -> { branch_choices }

        def notify(message, _opts)
          header = { 'Content-Type' => 'application/json' }
          response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump({ markdown: message.summary }))

          response if response.success?
        end

        private

        def custom_data(data)
          super.merge(markdown: true)
        end
      end

      def default_channel_placeholder; end
    end
  end
end
