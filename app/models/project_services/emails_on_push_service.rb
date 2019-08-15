# frozen_string_literal: true

class EmailsOnPushService < Service
  boolean_accessor :send_from_committer_email
  boolean_accessor :disable_diffs
  prop_accessor :recipients
  validates :recipients, presence: true, if: :valid_recipients?

  def title
    s_('EmailsOnPushService|Emails on push')
  end

  def description
    s_('EmailsOnPushService|Email the commits and diff of each push to a list of recipients.')
  end

  def self.to_param
    'emails_on_push'
  end

  def self.supported_events
    %w(push tag_push)
  end

  def execute(push_data)
    return unless supported_events.include?(push_data[:object_kind])
    return if project.emails_disabled?

    EmailsOnPushWorker.perform_async(
      project_id,
      recipients,
      push_data,
      send_from_committer_email: send_from_committer_email?,
      disable_diffs:             disable_diffs?
    )
  end

  def send_from_committer_email?
    Gitlab::Utils.to_boolean(self.send_from_committer_email)
  end

  def disable_diffs?
    Gitlab::Utils.to_boolean(self.disable_diffs)
  end

  def fields
    domains = Notify.allowed_email_domains.map { |domain| "user@#{domain}" }.join(", ")
    [
      { type: 'checkbox', name: 'send_from_committer_email', title: s_("EmailsOnPushService|Send from committer"),
        help: s_("EmailsOnPushService|Send notifications from the committer's email address if the domain is part of the domain GitLab is running on (e.g. %{domains}).") % { domains: domains } },
      { type: 'checkbox', name: 'disable_diffs', title: s_("EmailsOnPushService|Disable code diffs"),
        help: s_("EmailsOnPushService|Don't include possibly sensitive code diffs in notification body.") },
      { type: 'textarea', name: 'recipients', placeholder: s_('EmailsOnPushService|Emails separated by whitespace') }
    ]
  end
end
