# frozen_string_literal: true

# :nocov:
module DeliverNever
  def deliver_later
    self
  end
end

module MuteNotifications
  def new_note(note)
  end
end

module Gitlab
  class Seeder
    def self.quiet
      mute_notifications
      mute_mailer

      SeedFu.quiet = true

      yield

      SeedFu.quiet = false
      puts "\nOK".color(:green)
    end

    def self.without_gitaly_timeout
      # Remove Gitaly timeout
      old_timeout = Gitlab::CurrentSettings.current_application_settings.gitaly_timeout_default
      Gitlab::CurrentSettings.current_application_settings.update_columns(gitaly_timeout_default: 0)
      # Otherwise we still see the default value when running seed_fu
      ApplicationSetting.expire

      yield
    ensure
      Gitlab::CurrentSettings.current_application_settings.update_columns(gitaly_timeout_default: old_timeout)
      ApplicationSetting.expire
    end

    def self.mute_notifications
      NotificationService.prepend(MuteNotifications)
    end

    def self.mute_mailer
      ActionMailer::MessageDelivery.prepend(DeliverNever)
    end
  end
end
# :nocov:
