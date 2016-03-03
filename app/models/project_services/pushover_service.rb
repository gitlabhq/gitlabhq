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

class PushoverService < Service
  include HTTParty
  base_uri 'https://api.pushover.net/1'

  prop_accessor :api_key, :user_key, :device, :priority, :sound
  validates :api_key, :user_key, :priority, presence: true, if: :activated?

  def title
    'Pushover'
  end

  def description
    'Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop.'
  end

  def to_param
    'pushover'
  end

  def fields
    [
      { type: 'text', name: 'api_key', placeholder: 'Your application key' },
      { type: 'text', name: 'user_key', placeholder: 'Your user key' },
      { type: 'text', name: 'device', placeholder: 'Leave blank for all active devices' },
      { type: 'select', name: 'priority', choices:
        [
          ['Lowest Priority', -2],
          ['Low Priority', -1],
          ['Normal Priority', 0],
          ['High Priority', 1]
        ],
        default_choice: 0
      },
      { type: 'select', name: 'sound', choices:
        [
          ['Device default sound', nil],
          ['Pushover (default)', 'pushover'],
          ['Bike', 'bike'],
          ['Bugle', 'bugle'],
          ['Cash Register', 'cashregister'],
          ['Classical', 'classical'],
          ['Cosmic', 'cosmic'],
          ['Falling', 'falling'],
          ['Gamelan', 'gamelan'],
          ['Incoming', 'incoming'],
          ['Intermission', 'intermission'],
          ['Magic', 'magic'],
          ['Mechanical', 'mechanical'],
          ['Piano Bar', 'pianobar'],
          ['Siren', 'siren'],
          ['Space Alarm', 'spacealarm'],
          ['Tug Boat', 'tugboat'],
          ['Alien Alarm (long)', 'alien'],
          ['Climb (long)', 'climb'],
          ['Persistent (long)', 'persistent'],
          ['Pushover Echo (long)', 'echo'],
          ['Up Down (long)', 'updown'],
          ['None (silent)', 'none']
        ]
      },
    ]
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    ref = Gitlab::Git.ref_name(data[:ref])
    before = data[:before]
    after = data[:after]

    if Gitlab::Git.blank_ref?(before)
      message = "#{data[:user_name]} pushed new branch \"#{ref}\"."
    elsif Gitlab::Git.blank_ref?(after)
      message = "#{data[:user_name]} deleted branch \"#{ref}\"."
    else
      message = "#{data[:user_name]} push to branch \"#{ref}\"."
    end

    if data[:total_commits_count] > 0
      message << "\nTotal commits count: #{data[:total_commits_count]}"
    end

    pushover_data = {
      token: api_key,
      user: user_key,
      device: device,
      priority: priority,
      title: "#{project.name_with_namespace}",
      message: message,
      url: data[:project][:web_url],
      url_title: "See project #{project.name_with_namespace}"
    }

    # Sound parameter MUST NOT be sent to API if not selected
    if sound
      pushover_data.merge!(sound: sound)
    end

    PushoverService.post('/messages.json', body: pushover_data)
  end
end
