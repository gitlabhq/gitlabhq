# frozen_string_literal: true

require 'active_support'
require 'active_record'

# rubocop:disable Database/MultipleDatabases -- simulate Rails environment
# rubocop:disable Database/EstablishConnection -- simulate Rails environment

module StubRails
  extend ActiveSupport::Concern

  included do
    class RailsApp < Rails::Application # rubocop:disable Lint/ConstantDefinitionInBlock -- load only when included
    end

    logger = Logger.new($stdout, level: Logger::INFO, formatter: ->(_, _, _, msg) { msg })

    # load timezones
    begin
      TZInfo::DataSource.get
    rescue TZInfo::DataSourceNotFound => e
      raise e.exception "tzinfo-data is not present. " \
                        "Please add gem 'tzinfo-data' to your Gemfile and run bundle install"
    end
    Time.zone_default = Time.find_zone!(Rails.application.config.time_zone)

    ActiveRecord::Base.configurations = Rails.application.config.database_configuration

    # Create and connect to main database
    begin
      rails_establish_connection(logger)
    rescue ActiveRecord::NoDatabaseError
      rails_create_main_database(logger)
      rails_establish_connection(logger)
    end
  end

  def rails_establish_connection(_logger)
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute("SELECT VERSION()")
  end

  def rails_create_main_database(logger)
    db_config = ActiveRecord::Base.configurations.find_db_config(Rails.env)
    logger.info("Creating database #{db_config.database}...")

    ActiveRecord::Base.establish_connection(db_config.configuration_hash.merge(
      database: "postgres",
      schema_search_path: "public"
    ))
    ActiveRecord::Base.connection.create_database(
      db_config.database, { encoding: 'utf8' }.merge(db_config.configuration_hash))
  end
end

# rubocop:enable Database/MultipleDatabases
# rubocop:enable Database/EstablishConnection
