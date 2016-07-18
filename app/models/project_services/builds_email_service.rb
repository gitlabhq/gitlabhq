class BuildsEmailService < Service
  prop_accessor :recipients
  boolean_accessor :add_pusher
  boolean_accessor :notify_only_broken_builds
  validates :recipients, presence: true, if: ->(s) { s.activated? && !s.add_pusher? }

  def initialize_properties
    if properties.nil?
      self.properties = {}
      self.notify_only_broken_builds = true
    end
  end

  def title
    'Builds emails'
  end

  def description
    'Email the builds status to a list of recipients.'
  end

  def to_param
    'builds_email'
  end

  def supported_events
    %w(build)
  end

  def execute(push_data)
    return unless supported_events.include?(push_data[:object_kind])
    return unless should_build_be_notified?(push_data)

    recipients = all_recipients(push_data)

    if recipients.any?
      BuildEmailWorker.perform_async(
        push_data[:build_id],
        recipients,
        push_data
      )
    end
  end

  def can_test?
    project.builds.count > 0
  end

  def disabled_title
    "Please setup a build on your repository."
  end

  def test_data(project = nil, user = nil)
    build = project.builds.last
    Gitlab::BuildDataBuilder.build(build)
  end

  def fields
    [
      { type: 'textarea', name: 'recipients', placeholder: 'Emails separated by comma' },
      { type: 'checkbox', name: 'add_pusher', label: 'Add pusher to recipients list' },
      { type: 'checkbox', name: 'notify_only_broken_builds' },
    ]
  end

  def test(data)
    begin
      # bypass build status verification when testing
      data[:build_status] = "failed"
      data[:build_allow_failure] = false

      result = execute(data)
    rescue StandardError => error
      return { success: false, result: error }
    end

    { success: true, result: result }
  end

  def should_build_be_notified?(data)
    case data[:build_status]
    when 'success'
      !notify_only_broken_builds?
    when 'failed'
      !allow_failure?(data)
    else
      false
    end
  end

  def allow_failure?(data)
    data[:build_allow_failure] == true
  end

  def all_recipients(data)
    all_recipients = []

    unless recipients.blank?
      all_recipients += recipients.split(',').compact.reject(&:blank?)
    end

    if add_pusher? && data[:user][:email]
      all_recipients << data[:user][:email]
    end

    all_recipients
  end
end
