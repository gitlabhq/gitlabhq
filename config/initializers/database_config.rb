# frozen_string_literal: true

# when running on puma, scale connection pool size with the number
# of threads per worker process
if Gitlab::Runtime.puma?
  db_config = Gitlab::Database.config ||
      Rails.application.config.database_configuration[Rails.env]
  puma_options = Puma.cli_config.options

  # We use either the maximum number of threads per worker process, or
  # the user specified value, whichever is larger.
  desired_pool_size = [db_config['pool'].to_i, puma_options[:max_threads]].max

  db_config['pool'] = desired_pool_size

  # recreate the connection pool from the new config
  ActiveRecord::Base.establish_connection(db_config)
end
