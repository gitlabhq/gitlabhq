# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

class BuildsEmailService < Service
  prop_accessor :recipients
  boolean_accessor :add_pusher
  boolean_accessor :notify_only_broken_builds
  validates :recipients, presence: true, if: :activated?

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

    if should_build_be_notified?(push_data)
      BuildEmailWorker.perform_async(
        push_data[:build_id],
        all_recipients(push_data),
        push_data,
      )
    end
  end

  def fields
    [
      { type: 'textarea', name: 'recipients', placeholder: 'Emails separated by comma' },
      { type: 'checkbox', name: 'add_pusher', label: 'Add pusher to recipients list' },
      { type: 'checkbox', name: 'notify_only_broken_builds' },
    ]
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
    all_recipients = recipients.split(',')

    if add_pusher? && data[:user][:email]
      all_recipients << "#{data[:user][:email]}"
    end

    all_recipients
  end
end
