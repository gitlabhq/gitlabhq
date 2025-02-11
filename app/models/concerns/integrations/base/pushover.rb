# frozen_string_literal: true

module Integrations
  module Base
    module Pushover
      extend ActiveSupport::Concern

      BASE_URI = 'https://api.pushover.net/1'

      class_methods do
        def title
          'Pushover'
        end

        def description
          s_('PushoverService|Get real-time notifications on your device.')
        end

        def to_param
          'pushover'
        end

        def supported_events
          %w[push]
        end
      end

      included do
        include HasAvatar

        validates :api_key, :user_key, :priority, presence: true, if: :activated?

        field :api_key,
          type: :password,
          title: -> { _('API key') },
          help: -> { s_('PushoverService|Enter your application key.') },
          non_empty_password_title: -> { s_('ProjectService|Enter new API key') },
          non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current API key.') },
          description: -> { s_('PushoverService|The application key.') },
          placeholder: '',
          required: true

        field :user_key,
          type: :password,
          title: -> { _('User key') },
          help: -> { s_('PushoverService|Enter your user key.') },
          non_empty_password_title: -> { s_('PushoverService|Enter new user key') },
          non_empty_password_help: -> { s_('PushoverService|Leave blank to use your current user key.') },
          description: -> { s_('PushoverService|The user key.') },
          placeholder: '',
          required: true

        field :device,
          title: -> { _('Devices (optional)') },
          help: -> { s_('PushoverService|Leave blank for all active devices.') },
          placeholder: ''

        field :priority,
          type: :select,
          required: true,
          help: -> { s_('PushoverService|The priority.') },
          choices: -> do
            [
              [s_('PushoverService|Lowest priority'), -2],
              [s_('PushoverService|Low priority'), -1],
              [s_('PushoverService|Normal priority'), 0],
              [s_('PushoverService|High priority'), 1]
            ]
          end

        field :sound,
          type: :select,
          help: -> { s_('PushoverService|The sound of the notification.') },
          choices: -> do
            [
              ['Device default sound', nil],
              ['Pushover (default)', 'pushover'],
              %w[Bike bike],
              %w[Bugle bugle],
              ['Cash Register', 'cashregister'],
              %w[Classical classical],
              %w[Cosmic cosmic],
              %w[Falling falling],
              %w[Gamelan gamelan],
              %w[Incoming incoming],
              %w[Intermission intermission],
              %w[Magic magic],
              %w[Mechanical mechanical],
              ['Piano Bar', 'pianobar'],
              %w[Siren siren],
              ['Space Alarm', 'spacealarm'],
              ['Tug Boat', 'tugboat'],
              ['Alien Alarm (long)', 'alien'],
              ['Climb (long)', 'climb'],
              ['Persistent (long)', 'persistent'],
              ['Pushover Echo (long)', 'echo'],
              ['Up Down (long)', 'updown'],
              ['None (silent)', 'none']
            ]
          end

        def execute(data)
          return unless supported_events.include?(data[:object_kind])

          ref = Gitlab::Git.ref_name(data[:ref])
          before = data[:before]
          after = data[:after]

          message =
            if Gitlab::Git.blank_ref?(before)
              format(
                s_("PushoverService|%{user_name} pushed new branch \"%{ref}\"."),
                user_name: data[:user_name],
                ref: ref
              )
            elsif Gitlab::Git.blank_ref?(after)
              format(
                s_("PushoverService|%{user_name} deleted branch \"%{ref}\"."),
                user_name: data[:user_name],
                ref: ref
              )
            else
              format(
                s_("PushoverService|%{user_name} push to branch \"%{ref}\"."),
                user_name: data[:user_name],
                ref: ref
              )
            end

          if data[:total_commits_count] > 0
            message = [
              message,
              format(
                s_("PushoverService|Total commits count: %{total_commits_count}"),
                total_commits_count: data[:total_commits_count]
              )
            ].join("\n")
          end

          pushover_data = {
            token: api_key,
            user: user_key,
            device: device,
            priority: priority,
            title: project.full_name.to_s,
            message: message,
            url: data[:project][:web_url],
            url_title: format(
              s_("PushoverService|See project %{project_full_name}"),
              project_full_name: project.full_name
            )
          }

          # Sound parameter MUST NOT be sent to API if not selected
          pushover_data[:sound] = sound if sound

          Gitlab::HTTP.post('/messages.json', base_uri: BASE_URI, body: pushover_data)
        end
      end
    end
  end
end
