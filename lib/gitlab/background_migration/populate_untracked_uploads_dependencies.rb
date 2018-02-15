# frozen_string_literal: true
module Gitlab
  module BackgroundMigration
    module PopulateUntrackedUploadsDependencies
      # Avoid using application code
      class Upload < ActiveRecord::Base
        self.table_name = 'uploads'
      end

      # Avoid using application code
      class Appearance < ActiveRecord::Base
        self.table_name = 'appearances'
      end

      # Avoid using application code
      class Namespace < ActiveRecord::Base
        self.table_name = 'namespaces'
      end

      # Avoid using application code
      class Note < ActiveRecord::Base
        self.table_name = 'notes'
      end

      # Avoid using application code
      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      # Since project Markdown upload paths don't contain the project ID, we have to find the
      # project by its full_path. Due to MySQL/PostgreSQL differences, and historical reasons,
      # the logic is somewhat complex, so I've mostly copied it in here.
      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        def self.find_by_full_path(path)
          binary = Gitlab::Database.mysql? ? 'BINARY' : ''
          order_sql = "(CASE WHEN #{binary} routes.path = #{connection.quote(path)} THEN 0 ELSE 1 END)"
          where_full_path_in(path).reorder(order_sql).take
        end

        def self.where_full_path_in(path)
          cast_lower = Gitlab::Database.postgresql?

          path = connection.quote(path)

          where =
            if cast_lower
              "(LOWER(routes.path) = LOWER(#{path}))"
            else
              "(routes.path = #{path})"
            end

          joins("INNER JOIN routes ON routes.source_id = projects.id AND routes.source_type = 'Project'").where(where)
        end
      end
    end
  end
end
