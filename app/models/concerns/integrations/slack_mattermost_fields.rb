# frozen_string_literal: true

module Integrations
  module SlackMattermostFields
    extend ActiveSupport::Concern

    included do
      undef :notify_only_broken_pipelines

      field :webhook,
        help: -> { webhook_help },
        required: true,
        if: -> { requires_webhook? }

      field :username,
        placeholder: 'GitLab-integration',
        if: -> { requires_webhook? }

      field :notify_only_broken_pipelines,
        type: :checkbox,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        help: 'Do not send notifications for successful pipelines.'

      field :branches_to_be_notified,
        type: :select,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        title: -> { s_('Integration|Branches for which notifications are to be sent') },
        choices: -> { branch_choices }

      field :labels_to_be_notified,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        placeholder: '~backend,~frontend',
        help: 'Send notifications for issue, merge request, and comment events with the listed labels only. ' \
              'Leave blank to receive notifications for all events.'

      field :labels_to_be_notified_behavior,
        type: :select,
        section: Integration::SECTION_TYPE_CONFIGURATION,
        choices: [
          ['Match any of the labels', Integrations::BaseChatNotification::MATCH_ANY_LABEL],
          ['Match all of the labels', Integrations::BaseChatNotification::MATCH_ALL_LABELS]
        ]
    end
  end
end
