class MigrateOldElasticsearchSettings < ActiveRecord::Migration
  include Gitlab::Database::ArelMethods
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    settings = Arel::Table.new(:application_settings)

    finder =
      settings
        .where(settings[:elasticsearch_host].not_eq(nil))
        .project(:id, :elasticsearch_host, :elasticsearch_port)

    result = connection.exec_query(finder.to_sql)

    # There are only a few rows in the `application_settings` table
    result.rows.each do |id, hosts, port|
      # elasticsearch_host may look like "1.example.com,2.example.com, 3.example.com"
      urls = hosts.split(',').map do |host|
        url = URI.parse('http://' + host.strip)
        url.port = port
        url.to_s
      end

      updater =
        arel_update_manager
          .table(settings)
          .set(settings[:elasticsearch_url] => urls.join(','))
          .where(settings[:id].eq(id))

      connection.exec_update(updater.to_sql, self.class.name, [])
    end
  end

  def down
    # no-op
  end
end
