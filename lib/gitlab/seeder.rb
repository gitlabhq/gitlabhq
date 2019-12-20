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
    extend ActionView::Helpers::NumberHelper

    MASS_INSERT_PROJECT_START = 'mass_insert_project_'
    MASS_INSERT_USER_START = 'mass_insert_user_'
    ESTIMATED_INSERT_PER_MINUTE = 2_000_000
    MASS_INSERT_ENV = 'MASS_INSERT'

    module ProjectSeed
      extend ActiveSupport::Concern

      included do
        scope :not_mass_generated, -> do
          where.not("path LIKE '#{MASS_INSERT_PROJECT_START}%'")
        end
      end
    end

    module UserSeed
      extend ActiveSupport::Concern

      included do
        scope :not_mass_generated, -> do
          where.not("username LIKE '#{MASS_INSERT_USER_START}%'")
        end
      end
    end

    def self.with_mass_insert(size, model)
      humanized_model_name = model.is_a?(String) ? model : model.model_name.human.pluralize(size)

      if !ENV[MASS_INSERT_ENV] && !ENV['CI']
        puts "\nSkipping mass insertion for #{humanized_model_name}."
        puts "Consider running the seed with #{MASS_INSERT_ENV}=1"
        return
      end

      humanized_size = number_with_delimiter(size)
      estimative = estimated_time_message(size)

      puts "\nCreating #{humanized_size} #{humanized_model_name}."
      puts estimative

      yield

      puts "\n#{number_with_delimiter(size)} #{humanized_model_name} created!"
    end

    def self.estimated_time_message(size)
      estimated_minutes = (size.to_f / ESTIMATED_INSERT_PER_MINUTE).round
      humanized_minutes = 'minute'.pluralize(estimated_minutes)

      if estimated_minutes.zero?
        "Rough estimated time: less than a minute ⏰"
      else
        "Rough estimated time: #{estimated_minutes} #{humanized_minutes} ⏰"
      end
    end

    def self.quiet
      # Disable database insertion logs so speed isn't limited by ability to print to console
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      # Additional seed logic for models.
      Project.include(ProjectSeed)
      User.include(UserSeed)

      mute_notifications
      mute_mailer

      SeedFu.quiet = true

      yield

      SeedFu.quiet = false
      ActiveRecord::Base.logger = old_logger
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
