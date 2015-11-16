# == Schema Information
#
# Table name: ci_services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

module Ci
  class HipChatService < Ci::Service
    prop_accessor :hipchat_token, :hipchat_room, :hipchat_server
    boolean_accessor :notify_only_broken_builds
    validates :hipchat_token, presence: true, if: :activated?
    validates :hipchat_room, presence: true, if: :activated?
    default_value_for :notify_only_broken_builds, true

    def title
      "HipChat"
    end

    def description
      "Private group chat, video chat, instant messaging for teams"
    end

    def help
    end

    def to_param
      'hip_chat'
    end

    def fields
      [
        { type: 'text', name: 'hipchat_token',  label: 'Token', placeholder: '' },
        { type: 'text', name: 'hipchat_room',   label: 'Room', placeholder: '' },
        { type: 'text', name: 'hipchat_server', label: 'Server', placeholder: 'https://hipchat.example.com', help: 'Leave blank for default' },
        { type: 'checkbox', name: 'notify_only_broken_builds', label: 'Notify only broken builds' }
      ]
    end

    def can_execute?(build)
      return if build.allow_failure?

      commit = build.commit
      return unless commit
      return unless commit.latest_builds.include? build

      case commit.status.to_sym
      when :failed
        true
      when :success
        true unless notify_only_broken_builds?
      else
        false
      end
    end

    def execute(build)
      msg = Ci::HipChatMessage.new(build)
      opts = default_options.merge(
        token: hipchat_token,
        room: hipchat_room,
        server: server_url,
        color: msg.status_color,
        notify: msg.notify?
      )
      Ci::HipChatNotifierWorker.perform_async(msg.to_s, opts)
    end

    private

    def default_options
      {
        service_name: 'GitLab CI',
        message_format: 'html'
      }
    end

    def server_url
      if hipchat_server.blank?
        'https://api.hipchat.com'
      else
        hipchat_server
      end
    end
  end
end
