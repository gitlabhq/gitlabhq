module Gitlab
  module Geo
    module GeoTasks
      extend self

      def set_primary_geo_node
        node = GeoNode.new(primary: true, url: GeoNode.current_node_url)
        $stdout.puts "Saving primary Geo node with URL #{node.url} ..."
        node.save

        if node.persisted?
          $stdout.puts "#{node.url} is now the primary Geo node".color(:green)
        else
          $stdout.puts "Error saving Geo node:\n#{node.errors.full_messages.join("\n")}".color(:red)
        end
      end

      def update_primary_geo_node_url
        node = Gitlab::Geo.primary_node

        unless node.present?
          $stdout.puts 'This is not a primary node'.color(:red)
          exit 1
        end

        $stdout.puts "Updating primary Geo node with URL #{node.url} ..."

        if node.update(url: GeoNode.current_node_url)
          $stdout.puts "#{node.url} is now the primary Geo node URL".color(:green)
        else
          $stdout.puts "Error saving Geo node:\n#{node.errors.full_messages.join("\n")}".color(:red)
          exit 1
        end
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
