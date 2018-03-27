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

    def self.mute_notifications
      NotificationService.prepend(MuteNotifications)
    end

    def self.mute_mailer
      ActionMailer::MessageDelivery.prepend(DeliverNever)
    end
  end
end
# :nocov:
