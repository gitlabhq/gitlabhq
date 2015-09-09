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
  class MailService < Ci::Service
    delegate :email_recipients, :email_recipients=,
             :email_add_pusher, :email_add_pusher=,
             :email_only_broken_builds, :email_only_broken_builds=, to: :project, prefix: false

    before_save :update_project

    default_value_for :active, true

    def title
      'Mail'
    end

    def description
      'Email notification'
    end

    def to_param
      'mail'
    end

    def fields
      [
        { type: 'text', name: 'email_recipients', label: 'Recipients', help: 'Whitespace-separated list of recipient addresses' },
        { type: 'checkbox', name: 'email_add_pusher', label: 'Add pusher to recipients list' },
        { type: 'checkbox', name: 'email_only_broken_builds', label: 'Notify only broken builds' }
      ]
    end

    def can_execute?(build)
      return if build.allow_failure?

      # it doesn't make sense to send emails for retried builds
      commit = build.commit
      return unless commit
      return unless commit.builds_without_retry.include?(build)

      case build.status.to_sym
      when :failed
        true
      when :success
        true unless email_only_broken_builds
      else
        false
      end
    end

    def execute(build)
      build.commit.project_recipients.each do |recipient|
        case build.status.to_sym
        when :success
          mailer.build_success_email(build.id, recipient)
        when :failed
          mailer.build_fail_email(build.id, recipient)
        end
      end
    end

    private

    def update_project
      project.save!
    end

    def mailer
      Ci::Notify.delay
    end
  end
end
