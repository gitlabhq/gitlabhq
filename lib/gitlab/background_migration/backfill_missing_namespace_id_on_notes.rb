# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Metrics/ClassLength -- Background migration requires multiple resolution strategies for different noteable types
    class BackfillMissingNamespaceIdOnNotes < BatchedMigrationJob
      operation_name :backfill_missing_namespace_id_on_notes
      feature_category :code_review_workflow

      # Only scope on project_id since we have an index for that
      scope_to ->(relation) { relation.where(project_id: nil) } # rubocop: disable Database/AvoidScopeTo -- column is indexed

      def perform
        each_sub_batch do |sub_batch|
          # Build common CTEs that will be reused for all update queries
          ctes = build_common_ctes(sub_batch)

          # Get distinct noteable types in this batch to avoid unnecessary queries
          noteable_types = fetch_noteable_types_in_batch(ctes)

          # Skip processing if no notes need updating
          next if noteable_types.empty?

          # Process only the noteable types that exist in this batch
          process_noteables_with_ctes(ctes, noteable_types)

          # Archive orphaned notes (those still without namespace_id)
          archive_orphaned_notes_with_ctes(ctes)
        end
      end

      private

      def build_common_ctes(sub_batch)
        <<~SQL
          filtered_relation AS (#{sub_batch.limit(sub_batch.size).to_sql})
        SQL
      end

      def fetch_noteable_types_in_batch(ctes)
        sql = <<~SQL
          WITH #{ctes}
          SELECT DISTINCT noteable_type
          FROM filtered_relation
        SQL

        connection.select_values(sql)
      end

      def process_noteables_with_ctes(ctes, noteable_types)
        # Process standard noteables with direct namespace lookup
        direct_namespace_updates.each do |noteable_type, table, field|
          next unless noteable_types.include?(noteable_type)

          execute_cte_update(ctes, noteable_type,
            "#{table} AS sources ON relation_by_type.noteable_id = sources.id",
            "sources.#{field}")
        end

        # Process noteables that need project lookup
        project_based_updates.each do |noteable_type, table, project_field|
          next unless noteable_types.include?(noteable_type)

          execute_cte_update(ctes, noteable_type,
            "#{table} ON relation_by_type.noteable_id = #{table}.id " \
              "JOIN projects AS sources ON sources.id = #{table}.#{project_field}",
            "sources.project_namespace_id")
        end

        # Process special cases only if they exist in the batch
        process_wiki_notes_with_ctes(ctes) if noteable_types.include?('WikiPage::Meta')
        process_snippet_notes_with_ctes(ctes) if noteable_types.include?('Snippet')
        process_vulnerability_notes_with_ctes(ctes) if noteable_types.include?('Vulnerability')
      end

      def direct_namespace_updates
        [
          %w[Issue issues namespace_id],
          # DesignManagement::Design excluded - namespace-level designs don't exist yet
          # and design_management_designs.namespace_id is unreliable
          %w[Epic epics group_id]
        ]
      end

      def project_based_updates
        [
          ['MergeRequest', 'merge_requests', 'target_project_id'],
          ['AlertManagement::Alert', 'alert_management_alerts', 'project_id']
        ]
      end

      def execute_cte_update(ctes, noteable_type, join_clause, namespace_field)
        update_sql = <<~SQL
          WITH
            #{ctes},
            relation_by_type AS (
              SELECT * FROM filtered_relation
              WHERE noteable_type = '#{noteable_type}'
            )
          UPDATE notes
          SET namespace_id = #{namespace_field}
          FROM relation_by_type
          JOIN #{join_clause}
          WHERE notes.id = relation_by_type.id
        SQL

        connection.execute(update_sql)
      end

      # rubocop:disable Metrics/MethodLength -- Complex SQL queries are more readable as a single method
      def process_wiki_notes_with_ctes(ctes)
        # Check if there are project wikis to update
        check_project_wikis = <<~SQL
          WITH
            #{ctes},
            wiki_notes AS (
              SELECT * FROM filtered_relation
              WHERE noteable_type = 'WikiPage::Meta'
            )
          SELECT EXISTS(
            SELECT 1
            FROM wiki_notes
            JOIN wiki_page_meta ON wiki_notes.noteable_id = wiki_page_meta.id
            WHERE wiki_page_meta.project_id IS NOT NULL
            LIMIT 1
          )
        SQL

        if connection.select_value(check_project_wikis)
          # Handle project wikis
          update_sql = <<~SQL
            WITH
              #{ctes},
              relation_by_type AS (
                SELECT * FROM filtered_relation
                WHERE noteable_type = 'WikiPage::Meta'
              )
            UPDATE notes
            SET namespace_id = projects.project_namespace_id
            FROM relation_by_type
            JOIN wiki_page_meta ON relation_by_type.noteable_id = wiki_page_meta.id
            JOIN projects ON wiki_page_meta.project_id = projects.id
            WHERE notes.id = relation_by_type.id
              AND wiki_page_meta.project_id IS NOT NULL
          SQL
          connection.execute(update_sql)
        end

        # Check if there are group wikis to update
        check_group_wikis = <<~SQL
          WITH
            #{ctes},
            wiki_notes AS (
              SELECT * FROM filtered_relation
              WHERE noteable_type = 'WikiPage::Meta'
            )
          SELECT EXISTS(
            SELECT 1
            FROM wiki_notes
            JOIN wiki_page_meta ON wiki_notes.noteable_id = wiki_page_meta.id
            WHERE wiki_page_meta.namespace_id IS NOT NULL
            LIMIT 1
          )
        SQL

        return unless connection.select_value(check_group_wikis)

        # Handle group wikis
        update_sql = <<~SQL
            WITH
              #{ctes},
              relation_by_type AS (
                SELECT * FROM filtered_relation
                WHERE noteable_type = 'WikiPage::Meta'
              )
            UPDATE notes
            SET namespace_id = wiki_page_meta.namespace_id
            FROM relation_by_type
            JOIN wiki_page_meta ON relation_by_type.noteable_id = wiki_page_meta.id
            WHERE notes.id = relation_by_type.id
              AND wiki_page_meta.namespace_id IS NOT NULL
        SQL
        connection.execute(update_sql)
      end
      # rubocop:enable Metrics/MethodLength

      def process_snippet_notes_with_ctes(ctes)
        update_sql = <<~SQL
          WITH
            #{ctes},
            relation_by_type AS (
              SELECT * FROM filtered_relation
              WHERE noteable_type = 'Snippet'
            )
          UPDATE notes
          SET namespace_id = NULL,
              organization_id = snippets.organization_id
          FROM relation_by_type
          JOIN snippets ON relation_by_type.noteable_id = snippets.id
          WHERE notes.id = relation_by_type.id
            AND snippets.project_id IS NULL
        SQL

        connection.execute(update_sql)
      end

      def process_vulnerability_notes_with_ctes(ctes)
        # Keep the check for CE/EE compatibility
        return unless defined?(::SecApplicationRecord)

        # Process vulnerability notes with cross-database join
        # We need to fetch vulnerability project mappings first
        vuln_sql = <<~SQL
          WITH #{ctes}
          SELECT noteable_id
          FROM filtered_relation
          WHERE noteable_type = 'Vulnerability'
        SQL

        vuln_ids = connection.select_values(vuln_sql)
        return if vuln_ids.empty?

        # Fetch vulnerability to project mapping from sec database
        vuln_to_project = fetch_vulnerability_projects(vuln_ids)
        return if vuln_to_project.empty?

        # Fetch project to namespace mapping
        project_to_namespace = fetch_project_namespaces(vuln_to_project.values.compact.uniq)

        # Build and execute bulk update
        update_vulnerability_notes_batch(ctes, vuln_to_project, project_to_namespace)
      end

      def fetch_vulnerability_projects(vuln_ids)
        sec_data = SecApplicationRecord.connection.select_all(<<~SQL)
          SELECT id, project_id
          FROM vulnerabilities
          WHERE id IN (#{vuln_ids.map(&:to_i).join(',')})
        SQL

        sec_data.rows.to_h
      end

      def fetch_project_namespaces(project_ids)
        return {} if project_ids.empty?

        project_data = connection.select_all(<<~SQL)
          SELECT id, project_namespace_id
          FROM projects
          WHERE id IN (#{project_ids.join(',')})
        SQL

        project_data.rows.to_h
      end

      def update_vulnerability_notes_batch(ctes, vuln_to_project, project_to_namespace)
        # Build value pairs for the update
        values = []
        vuln_to_project.each do |vuln_id, project_id|
          namespace_id = project_to_namespace[project_id]
          values << "(#{vuln_id.to_i}, #{namespace_id.to_i})" if namespace_id
        end

        return if values.empty?

        update_sql = <<~SQL
          WITH
            #{ctes},
            relation_by_type AS (
              SELECT * FROM filtered_relation
              WHERE noteable_type = 'Vulnerability'
            ),
            vuln_namespaces(noteable_id, namespace_id) AS (
              VALUES #{values.join(',')}
            )
          UPDATE notes
          SET namespace_id = vuln_namespaces.namespace_id
          FROM relation_by_type
          JOIN vuln_namespaces ON relation_by_type.noteable_id = vuln_namespaces.noteable_id
          WHERE notes.id = relation_by_type.id
        SQL

        connection.execute(update_sql)
      end

      # rubocop:disable Metrics/MethodLength -- Complex SQL queries with CTEs are more readable as a single method
      def archive_orphaned_notes_with_ctes(ctes)
        # After all updates, check if there are any notes that STILL have NULL namespace_id
        # These are true orphans that couldn't be matched to any valid noteable
        # EXCEPT for personal snippet notes which legitimately have NULL namespace_id
        check_sql = <<~SQL
          WITH
            #{ctes}
          SELECT EXISTS(
            SELECT 1
            FROM notes
            WHERE id IN (SELECT id FROM filtered_relation)
              AND namespace_id IS NULL
              AND NOT (noteable_type = 'Snippet' AND organization_id IS NOT NULL)
            LIMIT 1
          )
        SQL

        return unless connection.select_value(check_sql)

        # Log orphaned notes before archiving
        log_orphaned_notes_with_ctes(ctes)

        # Archive and delete only notes that still have NULL namespace_id after all updates
        # BUT exclude personal snippet notes which legitimately have NULL namespace_id
        delete_sql = <<~SQL
          WITH
            #{ctes},
            remaining_orphaned AS (
              SELECT notes.*
              FROM notes
              WHERE id IN (SELECT id FROM filtered_relation)
                AND namespace_id IS NULL
                AND NOT (noteable_type = 'Snippet' AND organization_id IS NOT NULL)
            ),
            deleted_notes AS (
              DELETE FROM notes
              WHERE id IN (SELECT id FROM remaining_orphaned)
              RETURNING #{notes_columns_for_archive}
            )
          INSERT INTO notes_archived (#{notes_columns_for_archive}, archived_at)
          SELECT #{notes_columns_for_archive}, CURRENT_TIMESTAMP
          FROM deleted_notes
        SQL

        result = connection.execute(delete_sql)

        # Log the result
        if result.cmd_tuples > 0
          Gitlab::BackgroundMigration::Logger.info(
            message: 'Archived and deleted orphaned notes',
            count: result.cmd_tuples
          )
        end
      rescue StandardError => e
        Gitlab::BackgroundMigration::Logger.error(
          message: 'Failed to archive orphaned notes',
          error: e.message
        )
        raise
      end
      # rubocop:enable Metrics/MethodLength

      def log_orphaned_notes_with_ctes(ctes)
        orphaned_sql = <<~SQL
          WITH
            #{ctes}
          SELECT notes.id, notes.noteable_type, notes.noteable_id, notes.author_id, notes.created_at
          FROM notes
          WHERE id IN (SELECT id FROM filtered_relation)
            AND namespace_id IS NULL
            AND NOT (noteable_type = 'Snippet' AND organization_id IS NOT NULL)
        SQL

        orphaned_details = connection.select_all(orphaned_sql)

        orphaned_details.each do |note|
          Gitlab::BackgroundMigration::Logger.warn(
            message: 'Orphaned note to be archived',
            note_id: note['id'],
            noteable_type: note['noteable_type'],
            noteable_id: note['noteable_id'],
            author_id: note['author_id'],
            created_at: note['created_at']
          )
        end
      end

      def notes_columns_for_archive
        @notes_columns ||= %w[
          id note noteable_type author_id created_at updated_at
          project_id line_code commit_id noteable_id system
          st_diff updated_by_id type position original_position
          resolved_at resolved_by_id discussion_id note_html
          cached_markdown_version change_position resolved_by_push
          review_id confidential last_edited_at internal
          namespace_id imported_from organization_id
        ].join(', ')
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
