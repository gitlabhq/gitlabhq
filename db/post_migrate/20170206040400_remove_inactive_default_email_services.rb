class RemoveInactiveDefaultEmailServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    pool = create_connection_pool
    threads = []

    threads << Thread.new do
      pool.with_connection do |connection|
        connection.execute <<-SQL.strip_heredoc
        DELETE FROM services
          WHERE type = 'BuildsEmailService'
            AND active IS FALSE
            AND properties = '{"notify_only_broken_builds":true}';
        SQL
      end
    end

    threads << Thread.new do
      pool.with_connection do |connection|
        connection.execute <<-SQL.strip_heredoc
        DELETE FROM services
          WHERE type = 'PipelinesEmailService'
            AND active IS FALSE
            AND properties = '{"notify_only_broken_pipelines":true}';
        SQL
      end
    end

    threads.each(&:join)
    pool.disconnect!
  end

  def down
    # Nothing can be done to restore the records
  end

  private

  def create_connection_pool
    # See activerecord-4.2.7.1/lib/active_record/connection_adapters/connection_specification.rb
    env = Rails.env
    original_config = ActiveRecord::Base.configurations
    env_config = original_config[env].merge('pool' => 2)
    config = original_config.merge(env => env_config)

    spec =
      ActiveRecord::
        ConnectionAdapters::
        ConnectionSpecification::Resolver.new(config).spec(env.to_sym)

    ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
  end
end
