module Gitlab
  module Geo
    module GeoTasks
      extend self

      def set_primary_geo_node
        node = GeoNode.new(primary: true, url: GeoNode.current_node_url)
        $stdout.puts "Saving primary GeoNode with URL #{node.url}".color(:green)
        node.save

        $stdout.puts "Error saving GeoNode:\n#{node.errors.full_messages.join("\n")}".color(:red) unless node.persisted?
      end

      def refresh_foreign_tables!
        sql = <<~SQL
            DROP SCHEMA IF EXISTS gitlab_secondary CASCADE;
            CREATE SCHEMA gitlab_secondary;
            IMPORT FOREIGN SCHEMA public
              FROM SERVER gitlab_secondary
              INTO gitlab_secondary;
        SQL

        Gitlab::Geo::DatabaseTasks.with_geo_db do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute(sql)
          end
        end
      end

      def foreign_server_configured?
        sql = <<~SQL
          SELECT count(1)
            FROM pg_foreign_server
           WHERE srvname = '#{Gitlab::Geo::FDW_SCHEMA}';
        SQL

        Gitlab::Geo::DatabaseTasks.with_geo_db do
          ActiveRecord::Base.connection.execute(sql).first.fetch('count').to_i == 1
        end
      end
    end
  end
end
