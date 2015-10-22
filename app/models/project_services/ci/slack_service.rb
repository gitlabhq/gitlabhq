# == Schema Information
#
# Table name: services
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
  class SlackService < Ci::Service
    prop_accessor :webhook
    boolean_accessor :notify_only_broken_builds
    validates :webhook, presence: true, if: :activated?

    default_value_for :notify_only_broken_builds, true

    def title
      'Slack'
    end

    def description
      'A team communication tool for the 21st century'
    end

    def to_param
      'slack'
    end

    def help
      'Visit https://www.slack.com/services/new/incoming-webhook. Then copy link and save project!' unless webhook.present?
    end

    def fields
      [
        { type: 'text', name: 'webhook', label: 'Webhook URL', placeholder: '' },
        { type: 'checkbox', name: 'notify_only_broken_builds', label: 'Notify only broken builds' }
      ]
    end

    def can_execute?(build)
      return if build.allow_failure?

      commit = build.commit
      return unless commit
      return unless commit.latest_builds.include?(build)

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
      message = Ci::SlackMessage.new(build.commit)
      options = default_options.merge(
        color: message.color,
        fallback: message.fallback,
        attachments: message.attachments
      )
      Ci::SlackNotifierWorker.perform_async(webhook, message.pretext, options)
    end

    private

    def default_options
      {
        username: 'GitLab CI'
      }
    end
  end
end
