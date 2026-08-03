# frozen_string_literal: true

module Tasks
  module Gitlab
    module Siphon
      # Prepares each configured database for Siphon replication.
      #
      # Runs as the regular gitlab database user, which owns the database and every table but
      # is not a superuser.
      class SetupTask
        DEFAULT_USER_PREFIX = 'siphon'
        IDENTIFIER_REGEX = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
        FUNCTION_NAME = 'public.siphon_alter_publication'
        FUNCTION_SIGNATURE = "#{FUNCTION_NAME}(text, text, integer)".freeze

        ALTER_PUBLICATION_FUNCTION = <<~'SQL'
          CREATE OR REPLACE FUNCTION public.siphon_alter_publication(pbl TEXT, tbl TEXT, op INTEGER)
          RETURNS void
          LANGUAGE plpgsql
          SECURITY DEFINER
          SET search_path = ''
          AS $$
          DECLARE
            operation TEXT;
          BEGIN
            IF pbl !~ '^[a-zA-Z_][a-zA-Z0-9_]*$' THEN
              RAISE EXCEPTION 'Invalid publication name';
            END IF;

            IF tbl !~ '^[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*$' THEN
              RAISE EXCEPTION 'Invalid table name format: must be schema-qualified (e.g. public.users)';
            END IF;

            IF op = 0 THEN
              operation := 'ADD';
            ELSIF op = 1 THEN
              operation := 'DROP';
            ELSE
              RAISE EXCEPTION 'Invalid operation parameter: op must be 0 (ADD) or 1 (DROP)';
            END IF;

            EXECUTE pg_catalog.format('ALTER PUBLICATION %s %s TABLE %s', pbl, operation, tbl);
          END;
          $$;
        SQL

        def initialize(user_prefix: nil, database: nil, publication_name: nil)
          @user_prefix = user_prefix.presence || DEFAULT_USER_PREFIX
          @database = database.presence
          @publication_name_override = publication_name.presence
        end

        def execute
          validate!

          ::Gitlab::Database::EachDatabase.each_connection(only: @database, include_shared: false) do |connection, name|
            setup_database(connection, name)
          end

          puts
          puts 'Done. Set `replication.use_alter_publication_function: true` in the Siphon producer config.'
          puts 'Without it Siphon runs ALTER PUBLICATION directly as its own user, which does not own the'
          puts 'publication, and fails.'
        end

        private

        attr_reader :user_prefix

        def role_names
          [user_prefix, "#{user_prefix}_replicator", "#{user_prefix}_snapshot"]
        end

        def schemas
          ['public', *::Gitlab::Database::EXTRA_SCHEMAS].map(&:to_s)
        end

        def publication_name(database_name)
          @publication_name_override || "siphon_publication_#{database_name}_1"
        end

        def validate!
          [user_prefix, @publication_name_override].compact.each do |value|
            abort "Invalid identifier #{value.inspect}: must match #{IDENTIFIER_REGEX.source}" unless
              value.match?(IDENTIFIER_REGEX)
          end

          return unless @publication_name_override && @database.nil?

          abort 'SIPHON_PUBLICATION_NAME requires SIPHON_DATABASE: one name cannot serve several databases'
        end

        def setup_database(connection, database_name)
          puts
          puts "=== #{database_name} ==="

          roles = existing_roles(connection)
          (role_names - roles).each do |missing|
            warn "  WARNING: role #{missing} does not exist, skipping it"
          end

          if roles.empty?
            print_missing_roles_help
            return
          end

          grant_function_execute(connection, roles) if create_function(connection)
          create_publication(connection, database_name)
          grant_schema_privileges(connection, roles)
        end

        def existing_roles(connection)
          quoted = role_names.map { |name| connection.quote(name) }.join(', ')

          connection.select_values("SELECT rolname FROM pg_catalog.pg_roles WHERE rolname IN (#{quoted})")
        end

        def create_function(connection)
          connection.execute(ALTER_PUBLICATION_FUNCTION)
          puts "  Created or replaced #{FUNCTION_NAME}"
          true
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.cause.is_a?(PG::InsufficientPrivilege)

          warn "  WARNING: #{FUNCTION_NAME} exists and is owned by another role, leaving it alone."
          warn "  WARNING: have a superuser run: ALTER FUNCTION #{FUNCTION_SIGNATURE} " \
            "OWNER TO #{current_user(connection)};"
          false
        end

        def grant_function_execute(connection, roles)
          connection.execute("REVOKE EXECUTE ON FUNCTION #{FUNCTION_SIGNATURE} FROM PUBLIC")

          return unless roles.include?(user_prefix)

          connection.execute(
            "GRANT EXECUTE ON FUNCTION #{FUNCTION_SIGNATURE} TO #{connection.quote_column_name(user_prefix)}"
          )
          puts "  Granted EXECUTE on #{FUNCTION_NAME} to #{user_prefix} only"
        end

        def create_publication(connection, database_name)
          name = publication_name(database_name)

          connection.execute("CREATE PUBLICATION #{connection.quote_column_name(name)}")
          puts "  Created publication #{name}"
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.cause.is_a?(PG::DuplicateObject)

          puts "  Publication #{name} already exists"
          warn_on_foreign_publication_owner(connection, name)
        end

        def warn_on_foreign_publication_owner(connection, name)
          owner = connection.select_value(<<~SQL.squish)
            SELECT pg_catalog.pg_get_userbyid(pubowner)
            FROM pg_catalog.pg_publication
            WHERE pubname = #{connection.quote(name)}
          SQL

          return if owner.nil? || owner == current_user(connection)

          warn "  WARNING: publication #{name} is owned by #{owner}, so #{FUNCTION_NAME} cannot alter it."
          warn "  WARNING: have a superuser run: ALTER PUBLICATION #{name} OWNER TO #{current_user(connection)};"
        end

        def grant_schema_privileges(connection, roles)
          role_list = roles.map { |name| connection.quote_column_name(name) }.join(', ')

          schemas.each do |schema|
            next unless connection.schema_exists?(schema)

            grant_schema(connection, schema, role_list)
            puts "  Granted USAGE and SELECT on #{schema} to #{roles.join(', ')}"
          rescue ActiveRecord::StatementInvalid => e
            raise unless e.cause.is_a?(PG::InsufficientPrivilege)

            warn "  WARNING: could not grant on #{schema}, we do not own every table in it: #{e.cause.message.strip}"
          end
        end

        def grant_schema(connection, schema, role_list)
          connection.execute("GRANT USAGE ON SCHEMA #{schema} TO #{role_list}")
          connection.execute("GRANT SELECT ON ALL TABLES IN SCHEMA #{schema} TO #{role_list}")
          connection.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema} GRANT SELECT ON TABLES TO #{role_list}")
        end

        def current_user(connection)
          connection.select_value('SELECT current_user')
        end

        def print_missing_roles_help
          warn '  WARNING: no Siphon roles found, skipping this database.'
          warn '  WARNING: creating them needs a superuser (the REPLICATION attribute is superuser-only):'
          warn "    CREATE USER #{user_prefix} WITH PASSWORD '...' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;"
          warn "    CREATE USER #{user_prefix}_replicator WITH REPLICATION LOGIN PASSWORD '...' " \
            'NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;'
          warn "    CREATE USER #{user_prefix}_snapshot WITH PASSWORD '...' " \
            'NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;'
        end
      end
    end
  end
end
