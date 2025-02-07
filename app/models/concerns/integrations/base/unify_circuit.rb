# frozen_string_literal: true

module Integrations
  module Base
    module UnifyCircuit
      extend ActiveSupport::Concern
      include Base::ChatNotification

      class_methods do
        def title
          'Unify Circuit'
        end

        def description
          s_('Integrations|Send notifications about project events to Unify Circuit.')
        end

        def to_param
          'unify_circuit'
        end

        def help
          build_help_page_url(
            'user/project/integrations/unify_circuit.md',
            s_("Integrations|Send notifications about project events to a Unify Circuit conversation.")
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
          help: -> do
            _('The Unify Circuit webhook (for example, `https://circuit.com/rest/v2/webhooks/incoming/...`).')
          end,
          required: true

        field :notify_only_broken_pipelines,
          type: :checkbox,
          description: -> { _('Send notifications for broken pipelines.') },
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION

        field :branches_to_be_notified,
          type: :select,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          title: -> { s_('Integrations|Branches for which notifications are to be sent') },
          description: -> {
            _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
              'and `default_and_protected`. The default value is `default`.')
          },
          choices: -> { branch_choices }

        private

        def notify(message, _opts)
          body = {
            subject: message.project_name,
            text: message.summary,
            markdown: true
          }

          response = Gitlab::HTTP.post(webhook, body: Gitlab::Json.dump(body))

          response if response.success?
        end

        def custom_data(data)
          super.merge(markdown: true)
        end
      end

      def default_channel_placeholder; end
    end
  end
end
