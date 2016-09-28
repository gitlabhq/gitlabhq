class EmailsOnPushService < Service
  prop_accessor :send_from_committer_email
  prop_accessor :disable_diffs
  prop_accessor :recipients
  validates :recipients, presence: true, if: :activated?

  def title
    'Emails on push'
  end

  def description
    'Email the commits and diff of each push to a list of recipients.'
  end

  def to_param
    'emails_on_push'
  end

  def supported_events
    %w[push tag_push]
  end

  def execute(push_data)
    return unless supported_events.include?(push_data[:object_kind])

    EmailsOnPushWorker.perform_async(
      project_id, 
      recipients, 
      push_data, 
      send_from_committer_email:  send_from_committer_email?, 
      disable_diffs:              disable_diffs?
    )
  end

  def send_from_committer_email?
    self.send_from_committer_email == "1"
  end

  def disable_diffs?
    self.disable_diffs == "1"
  end

  def fields
    domains = Notify.allowed_email_domains.map { |domain| "user@#{domain}" }.join(", ")
    [
      { type: 'checkbox', name: 'send_from_committer_email', title: "Send from committer",
        help: "Send notifications from the committer's email address if the domain is part of the domain GitLab is running on (e.g. #{domains})." },
      { type: 'checkbox', name: 'disable_diffs', title: "Disable code diffs",
        help: "Don't include possibly sensitive code diffs in notification body." },
      { type: 'textarea', name: 'recipients', placeholder: 'Emails separated by whitespace' },
    ]
  end
end
