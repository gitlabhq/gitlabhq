# frozen_string_literal: true

module Integrations
  class Pushover < Integration
    BASE_URI = 'https://api.pushover.net/1'

    prop_accessor :api_key, :user_key, :device, :priority, :sound
    validates :api_key, :user_key, :priority, presence: true, if: :activated?

    def title
      'Pushover'
    end

    def description
      s_('PushoverService|Get real-time notifications on your device.')
    end

    def self.to_param
      'pushover'
    end

    def fields
      [
        { type: 'text', name: 'api_key', title: _('API key'), placeholder: s_('PushoverService|Your application key'), required: true },
        { type: 'text', name: 'user_key', placeholder: s_('PushoverService|Your user key'), required: true },
        { type: 'text', name: 'device', placeholder: s_('PushoverService|Leave blank for all active devices') },
        { type: 'select', name: 'priority', required: true, choices:
          [
            [s_('PushoverService|Lowest Priority'), -2],
            [s_('PushoverService|Low Priority'), -1],
            [s_('PushoverService|Normal Priority'), 0],
            [s_('PushoverService|High Priority'), 1]
          ],
          default_choice: 0 },
        { type: 'select', name: 'sound', choices:
          [
            ['Device default sound', nil],
            ['Pushover (default)', 'pushover'],
            %w(Bike bike),
            %w(Bugle bugle),
            ['Cash Register', 'cashregister'],
            %w(Classical classical),
            %w(Cosmic cosmic),
            %w(Falling falling),
            %w(Gamelan gamelan),
            %w(Incoming incoming),
            %w(Intermission intermission),
            %w(Magic magic),
            %w(Mechanical mechanical),
            ['Piano Bar', 'pianobar'],
            %w(Siren siren),
            ['Space Alarm', 'spacealarm'],
            ['Tug Boat', 'tugboat'],
            ['Alien Alarm (long)', 'alien'],
            ['Climb (long)', 'climb'],
            ['Persistent (long)', 'persistent'],
            ['Pushover Echo (long)', 'echo'],
            ['Up Down (long)', 'updown'],
            ['None (silent)', 'none']
          ] }
      ]
    end

    def self.supported_events
      %w(push)
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      ref = Gitlab::Git.ref_name(data[:ref])
      before = data[:before]
      after = data[:after]

      message =
        if Gitlab::Git.blank_ref?(before)
          s_("PushoverService|%{user_name} pushed new branch \"%{ref}\".") % { user_name: data[:user_name], ref: ref }
        elsif Gitlab::Git.blank_ref?(after)
          s_("PushoverService|%{user_name} deleted branch \"%{ref}\".") % { user_name: data[:user_name], ref: ref }
        else
          s_("PushoverService|%{user_name} push to branch \"%{ref}\".") % { user_name: data[:user_name], ref: ref }
        end

      if data[:total_commits_count] > 0
        message = [message, s_("PushoverService|Total commits count: %{total_commits_count}") % { total_commits_count: data[:total_commits_count] }].join("\n")
      end

      pushover_data = {
        token: api_key,
        user: user_key,
        device: device,
        priority: priority,
        title: "#{project.full_name}",
        message: message,
        url: data[:project][:web_url],
        url_title: s_("PushoverService|See project %{project_full_name}") % { project_full_name: project.full_name }
      }

      # Sound parameter MUST NOT be sent to API if not selected
      if sound
        pushover_data[:sound] = sound
      end

      Gitlab::HTTP.post('/messages.json', base_uri: BASE_URI, body: pushover_data)
    end
  end
end
