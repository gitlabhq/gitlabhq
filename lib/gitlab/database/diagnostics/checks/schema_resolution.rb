# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Checks
        class SchemaResolution
          USER_TOKEN = '$user'

          SCHEMAS_SQL = <<~SQL
            SELECT n.nspname AS name,
              (n.nspname = current_schema()) AS is_current,
              pg_catalog.pg_get_userbyid(n.nspowner) AS owner,
              EXISTS (
                SELECT 1 FROM pg_catalog.pg_class c
                WHERE c.relnamespace = n.oid AND c.relkind IN ('r', 'p', 'S')
              ) AS has_tables
            FROM pg_catalog.pg_namespace n
            WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
            ORDER BY is_current DESC, name ASC
          SQL

          # Sequences have no dictionary entry, so each resolves through pg_depend to its
          # owning table's name, or keeps its own when unowned. DISTINCT drops the duplicate
          # a table and its sequence produce.
          SCHEMA_TABLES_SQL = <<~SQL
            SELECT DISTINCT n.nspname AS schema_name,
              COALESCE(owner_table.relname, c.relname) AS table_name
            FROM pg_catalog.pg_namespace n
            JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
            LEFT JOIN pg_catalog.pg_depend d
              ON c.relkind = 'S' AND d.objid = c.oid
              AND d.classid = 'pg_class'::regclass AND d.refclassid = 'pg_class'::regclass
              AND d.deptype IN ('a', 'i')
            LEFT JOIN pg_catalog.pg_class owner_table ON owner_table.oid = d.refobjid
            WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
              AND c.relkind IN ('r', 'p', 'v', 'm', 'S')
          SQL

          def initialize(connection)
            @connection = connection
          end

          def execute
            findings = search_path_findings

            {
              current_user: current_user,
              search_path: search_path,
              schemas: schemas,
              findings: Findings.sort(findings),
              severity: Findings.worst(findings.pluck(:severity)),
              counts: Findings.counts(findings)
            }
          end

          private

          attr_reader :connection

          def search_path
            @search_path ||= connection.select_value('SHOW search_path').to_s
          end

          def current_user
            @current_user ||= connection.select_value('SELECT current_user').to_s
          end

          def schemas
            @schemas ||= begin
              boolean = ActiveModel::Type::Boolean.new

              connection.select_all(SCHEMAS_SQL).map do |row|
                {
                  name: row['name'],
                  current: boolean.cast(row['is_current']),
                  owner: row['owner'],
                  has_tables: boolean.cast(row['has_tables'])
                }
              end
            end
          end

          def schema_tables
            @schema_tables ||= connection.select_all(SCHEMA_TABLES_SQL).map do |row|
              [row['schema_name'], row['table_name']]
            end
          end

          def search_path_findings
            entries = parse_search_path(search_path)
            partition_schema_names = Gitlab::Database::EXTRA_SCHEMAS.map(&:to_s)

            findings = []

            if (entries & partition_schema_names).any?
              findings << {
                severity: Findings::WARNING,
                code: 'search_path_contains_partition_schema',
                message: s_('DatabaseDiagnostics|The search path contains a GitLab partition schema. ' \
                  'Partition schemas are expected to be referenced fully qualified, not via the search path.')
              }
            end

            # "$user" resolves to the connected role. Partition schemas are covered above.
            candidate_names = entries.map { |entry| entry == USER_TOKEN ? current_user : entry } -
              partition_schema_names
            candidates = schemas.select { |schema| candidate_names.include?(schema[:name]) }

            # Legitimate for an extension or DBA tooling, so only a warning.
            populated = candidates.select { |schema| schema[:has_tables] }
            if populated.size > 1
              findings << {
                severity: Findings::WARNING,
                code: 'search_path_objects_split_across_schemas',
                message: format(
                  s_('DatabaseDiagnostics|More than one schema in the search path contains objects: %{schemas}. ' \
                    'This can be intentional, but unqualified references resolve against the first match, so ' \
                    'objects spread across schemas can resolve unexpectedly.'),
                  schemas: populated.pluck(:name).join(', ')
                )
              }
            end

            # GitLab expects one schema, so this is a misconfiguration, not a possibility.
            gitlab_populated = candidates.select { |schema| schema_has_gitlab_objects?(schema[:name]) }
            if gitlab_populated.size > 1
              findings << {
                severity: Findings::ERROR,
                code: 'search_path_gitlab_objects_split_across_schemas',
                message: format(
                  s_('DatabaseDiagnostics|More than one schema in the search path contains GitLab objects: ' \
                    '%{schemas}. GitLab\'s objects should all live in a single schema. When they are split ' \
                    'across multiple schemas, unqualified references can resolve unexpectedly.'),
                  schemas: gitlab_populated.pluck(:name).join(', ')
                )
              }
            end

            # Unreachable by unqualified references, so never used. Partition schemas are
            # exempt: GitLab keeps partitions outside the search path by design.
            outside_names = schemas.pluck(:name) - candidate_names - partition_schema_names
            gitlab_outside = outside_names.select { |name| schema_has_gitlab_objects?(name) }
            if gitlab_outside.any?
              findings << {
                severity: Findings::WARNING,
                code: 'gitlab_objects_outside_search_path',
                message: format(
                  s_('DatabaseDiagnostics|Schemas outside the search path contain GitLab objects: %{schemas}. ' \
                    'GitLab does not resolve unqualified references against these schemas, so these objects are ' \
                    'never used. They may be leftovers from a restore or an earlier misconfiguration.'),
                  schemas: gitlab_outside.join(', ')
                )
              }
            end

            findings
          end

          def schema_has_gitlab_objects?(schema_name)
            schema_tables.any? { |(namespace, table_name)| namespace == schema_name && gitlab_object?(table_name) }
          end

          def gitlab_object?(table_name)
            schema = Gitlab::Database::GitlabSchema.table_schema(table_name)
            schema.present? && schema != :gitlab_internal
          end

          def parse_search_path(search_path)
            search_path.split(',').map do |entry|
              entry.strip.delete_prefix('"').delete_suffix('"')
            end
          end
        end
      end
    end
  end
end
