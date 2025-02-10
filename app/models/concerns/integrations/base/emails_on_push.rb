# frozen_string_literal: true

module Integrations
  module Base
    module EmailsOnPush
      extend ActiveSupport::Concern
      include NotificationBranchSelection

      RECIPIENTS_LIMIT = 750

      class_methods do
        def valid_recipients(recipients)
          recipients.split.grep(Devise.email_regexp).uniq(&:downcase)
        end

        def title
          s_('EmailsOnPushService|Emails on push')
        end

        def description
          s_('EmailsOnPushService|Email the commits and diff of each push to a list of recipients.')
        end

        def to_param
          'emails_on_push'
        end

        def supported_events
          %w[push tag_push]
        end
      end

      included do
        validates :recipients, presence: true, if: :validate_recipients?
        validate :number_of_recipients_within_limit, if: :validate_recipients?

        field :send_from_committer_email,
          type: :checkbox,
          title: -> { s_("EmailsOnPushService|Send from committer") },
          description: -> { s_("EmailsOnPushService|Send from committer") },
          help: -> do
            @help ||= begin
              domains = Notify.allowed_email_domains.map { |domain| "user@#{domain}" }.join(", ")

              format(s_("EmailsOnPushService|Send notifications from the committer's " \
                "email address if the domain matches the domain used by your GitLab instance (such as %{domains})."),
                domains: domains
              )
            end
          end

        field :disable_diffs,
          type: :checkbox,
          title: -> { s_("EmailsOnPushService|Disable code diffs") },
          help: -> { s_("EmailsOnPushService|Don't include possibly sensitive code diffs in notification body.") },
          description: -> { s_("EmailsOnPushService|Disable code diffs") }

        field :branches_to_be_notified,
          type: :select,
          title: -> { s_('Integrations|Branches for which notifications are to be sent') },
          description: -> do
            _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, and ' \
              '`default_and_protected`. The default value is `default`.')
          end,
          choices: branch_choices

        field :recipients,
          type: :textarea,
          required: true,
          placeholder: -> { s_('EmailsOnPushService|tanuki@example.com gitlab@example.com') },
          help: -> { s_('EmailsOnPushService|Emails separated by whitespace.') }
      end

      def initialize_properties
        super

        self.branches_to_be_notified = 'all' if branches_to_be_notified.nil?
      end

      def execute(push_data)
        return unless project
        return unless supported_events.include?(push_data[:object_kind])
        return if project.emails_disabled?
        return unless notify_for_ref?(push_data)

        EmailsOnPushWorker.perform_async(
          project_id,
          recipients,
          push_data,
          send_from_committer_email: send_from_committer_email?,
          disable_diffs: disable_diffs?
        )
      end

      def notify_for_ref?(push_data)
        return true if push_data[:object_kind] == 'tag_push'
        return true if push_data.dig(:object_attributes, :tag)

        notify_for_branch?(push_data)
      end

      def send_from_committer_email?
        Gitlab::Utils.to_boolean(send_from_committer_email)
      end

      def disable_diffs?
        Gitlab::Utils.to_boolean(disable_diffs)
      end

      private

      def number_of_recipients_within_limit
        return if recipients.blank?
        return unless self.class.valid_recipients(recipients).size > RECIPIENTS_LIMIT

        errors.add(
          :recipients,
          format(
            s_("Integrations|can't exceed %{recipients_limit}"),
            recipients_limit: RECIPIENTS_LIMIT
          )
        )
      end
    end
  end
end
