# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module ExtensionHelpers
        def create_extension(extension)
          execute("CREATE EXTENSION IF NOT EXISTS #{extension}")
        rescue ActiveRecord::StatementInvalid => e
          dbname = ApplicationRecord.database.database_name
          user = ApplicationRecord.database.username

          warn(<<~MSG) if e.to_s.include?('permission denied')
            GitLab requires the PostgreSQL extension '#{extension}' installed in database '#{dbname}', but
            the database user is not allowed to install the extension.

            You can either install the extension manually using a database superuser:

              CREATE EXTENSION IF NOT EXISTS #{extension}

            Or, you can solve this by logging in to the GitLab
            database (#{dbname}) using a superuser and running:

                ALTER #{user} WITH SUPERUSER

            This query will grant the user superuser permissions, ensuring any database extensions
            can be installed through migrations.

            For more information, refer to https://docs.gitlab.com/ee/install/postgresql_extensions.html.
          MSG

          raise
        end

        def drop_extension(extension)
          execute("DROP EXTENSION IF EXISTS #{extension}")
        rescue ActiveRecord::StatementInvalid => e
          dbname = ApplicationRecord.database.database_name
          user = ApplicationRecord.database.username

          warn(<<~MSG) if e.to_s.include?('permission denied')
            This migration attempts to drop the PostgreSQL extension '#{extension}'
            installed in database '#{dbname}', but the database user is not allowed
            to drop the extension.

            You can either drop the extension manually using a database superuser:

              DROP EXTENSION IF EXISTS #{extension}

            Or, you can solve this by logging in to the GitLab
            database (#{dbname}) using a superuser and running:

                ALTER #{user} WITH SUPERUSER

            This query will grant the user superuser permissions, ensuring any database extensions
            can be dropped through migrations.

            For more information, refer to https://docs.gitlab.com/ee/install/postgresql_extensions.html.
          MSG

          raise
        end
      end
    end
  end
end
