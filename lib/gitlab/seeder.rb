# frozen_string_literal: true

module Gitlab
  class Seeder
    extend ActionView::Helpers::NumberHelper

    MASS_INSERT_PREFIX = 'mass_insert'
    MASS_INSERT_PROJECT_START = "#{MASS_INSERT_PREFIX}_project_"
    MASS_INSERT_GROUP_START = "#{MASS_INSERT_PREFIX}_group_"
    MASS_INSERT_USER_START = "#{MASS_INSERT_PREFIX}_user_"
    REPORTED_USER_START = 'reported_user_'
    ESTIMATED_INSERT_PER_MINUTE = 250_000
    MASS_INSERT_ENV = 'MASS_INSERT'

    module NamespaceSeed
      extend ActiveSupport::Concern

      included do
        scope :not_mass_generated, -> do
          where.not("path LIKE '#{MASS_INSERT_GROUP_START}%'")
        end
      end
    end

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
          where.not("username LIKE '#{MASS_INSERT_USER_START}%' OR username LIKE '#{REPORTED_USER_START}%'")
        end
      end
    end

    def self.log_message(message)
      puts "#{Time.current}: #{message}"
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

      if estimated_minutes == 0
        "Rough estimated time: less than a minute ⏰"
      else
        "Rough estimated time: #{estimated_minutes} #{humanized_minutes} ⏰"
      end
    end

    def self.quiet
      # Additional seed logic for models.
      Namespace.include(NamespaceSeed)
      Project.include(ProjectSeed)
      User.include(UserSeed)

      old_perform_deliveries = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = false

      SeedFu.quiet = true

      without_database_logging do
        without_statement_timeout do
          without_new_note_notifications do
            yield
          end
        end
      end

      puts Rainbow("\nOK").green
    ensure
      SeedFu.quiet = false
      ActionMailer::Base.perform_deliveries = old_perform_deliveries
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

    def self.without_new_note_notifications
      NotificationService.alias_method :original_new_note, :new_note
      NotificationService.define_method(:new_note) { |note| }

      yield
    ensure
      NotificationService.alias_method :new_note, :original_new_note
      NotificationService.remove_method :original_new_note
    end

    def self.without_statement_timeout
      Gitlab::Database::EachDatabase.each_connection do |connection|
        connection.execute('SET statement_timeout=0')
      end
      yield
    ensure
      Gitlab::Database::EachDatabase.each_connection do |connection|
        connection.execute('RESET statement_timeout')
      end
    end

    def self.without_database_logging
      old_loggers = Gitlab::Database.database_base_models.transform_values do |model|
        model.logger
      end

      Gitlab::Database.database_base_models.each do |_, model|
        model.logger = nil
      end

      yield
    ensure
      Gitlab::Database.database_base_models.each do |connection_name, model|
        model.logger = old_loggers[connection_name]
      end
    end
  end
end
# :nocov:
