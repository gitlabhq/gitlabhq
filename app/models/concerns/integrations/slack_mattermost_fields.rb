# frozen_string_literal: true

module Integrations
  module SlackMattermostFields
    extend ActiveSupport::Concern

    included do
      field :webhook,
        help: -> { webhook_help },
        description: -> do
          Kernel.format(_("%{title} webhook (for example, `%{example}`)."), title: title, example: webhook_help)
        end,
        required: true,
        if: -> { requires_webhook? }

      field :username,
        placeholder: 'GitLab-integration',
        description: -> { Kernel.format(_("%{title} username."), title: title) },
        if: -> { requires_webhook? }

      field :channel,
        description: -> { _('Default channel to use if no other channel is configured.') },
        api_only: true

      field :notify_only_broken_pipelines,
        type: :checkbox,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        description: -> { _('Send notifications for broken pipelines.') },
        help: 'Do not send notifications for successful pipelines.'

      field :branches_to_be_notified,
        type: :select,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        title: -> { s_('Integration|Branches for which notifications are to be sent') },
        description: -> {
                       _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
                         'and `default_and_protected`. The default value is `default`.')
                     },
        choices: -> { branch_choices }

      field :labels_to_be_notified,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        description: -> { _('Labels to send notifications for. Leave blank to receive notifications for all events.') },
        placeholder: '~backend,~frontend',
        help: 'Send notifications for issue, merge request, and comment events with the listed labels only. ' \
              'Leave blank to receive notifications for all events.'

      field :labels_to_be_notified_behavior,
        type: :select,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        description: -> {
          _('Labels to be notified for. Valid options are `match_any` and `match_all`. ' \
            'The default value is `match_any`.')
        },
        choices: [
          ['Match any of the labels', Integrations::Base::ChatNotification::MATCH_ANY_LABEL],
          ['Match all of the labels', Integrations::Base::ChatNotification::MATCH_ALL_LABELS]
        ]
    end
  end
end
