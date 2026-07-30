# frozen_string_literal: true

module Gitlab
  module Database
    class SchemaCleaner
      attr_reader :original_schema

      def initialize(original_schema)
        @original_schema = original_schema
      end

      def clean(io)
        structure = original_schema.dup

        # Remove noise
        structure.gsub!(/^COMMENT ON EXTENSION.*/, '')
        structure.gsub!(/^SET.+/, '')
        structure.gsub!(/^SELECT pg_catalog\.set_config\('search_path'.+/, '')
        structure.gsub!(/^\\restrict.+/, '')
        structure.gsub!(/^\\unrestrict.+/, '')
        structure.gsub!(/^--.*/, "\n")

        # We typically don't assume we're working with the public schema.
        # pg_dump uses fully qualified object names though, since we have multiple schemas
        # in the database.
        #
        # The intention here is to not introduce an assumption about the standard schema,
        # unless we have a good reason to do so.
        structure.gsub!(/public\.(\w+)/, '\1')
        structure.gsub!(
          /CREATE EXTENSION IF NOT EXISTS (\w+) WITH SCHEMA public;/,
          'CREATE EXTENSION IF NOT EXISTS \1;'
        )

        # Table lock-writes triggers should not be added to the schema
        # These triggers are added by the rake task gitlab:db:lock_writes for a decomposed database.
        structure.gsub!(
          %r{
            ^CREATE.TRIGGER.gitlab_schema_write_trigger_\w+
            \s
            BEFORE.INSERT.OR.DELETE.OR.UPDATE.OR.TRUNCATE.ON.[\w.]+
            \s
            FOR.EACH.STATEMENT.EXECUTE.FUNCTION.gitlab_schema_prevent_write\(\);$
          }x,
          ''
        )

        # Publications are replication configuration, not schema. They are created by rake tasks
        # (gitlab:siphon:setup, gitlab:geo:logical_replication:publication:create) against a live
        # database, so a developer who has run one of those would otherwise dump them in here.
        structure.gsub!(/^(?:CREATE|ALTER) PUBLICATION .*;$\n/, '')

        # Likewise the helper function installed by gitlab:siphon:setup. Note the `public.` prefix
        # has already been stripped above.
        structure.gsub!(/^CREATE FUNCTION siphon_alter_publication\(.*?^\$_\$;$\n/m, '')

        structure.gsub!(/\n{3,}/, "\n\n")

        io << structure.strip
        io << "\n"

        nil
      end
    end
  end
end
