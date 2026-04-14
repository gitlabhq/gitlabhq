# frozen_string_literal: true

module DatabaseHelper
  def self.test_database_name
    @test_database_name ||= "gitlab_data_isolation_test_#{SecureRandom.alphanumeric(6)}"
  end

  def self.database_config
    config_path = File.expand_path('../../../../config/database.yml', __dir__)

    unless ApplicationRecord.configurations.configurations.any?
      ApplicationRecord.configurations = ActiveRecord::DatabaseConfigurations.new(
        YAML.safe_load_file(config_path)
      )
    end

    ApplicationRecord.configurations.configs_for(env_name: 'test', name: 'main').configuration_hash
  end

  def self.setup_database
    db_name = test_database_name
    db_config = database_config

    # Load from `gitlab-rails/config/database.yml`
    # Inject a `gitlab_data_isolation_test` database
    ApplicationRecord.establish_connection(db_config.merge(database: "postgres"))
    ApplicationRecord.connection.drop_database(db_name)
    ApplicationRecord.connection.create_database(db_name)
    ApplicationRecord.establish_connection(db_config.merge(database: db_name))
  end

  def self.teardown_database
    db_name = test_database_name
    db_config = database_config

    ApplicationRecord.establish_connection(db_config.merge(database: "postgres"))
    ApplicationRecord.connection.drop_database(db_name)
  end
end
