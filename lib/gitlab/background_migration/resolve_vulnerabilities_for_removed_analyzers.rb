# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength -- we need to keep the logic in a single class
# rubocop:disable Gitlab/BulkInsert -- we want to use ApplicationRecord.legacy_bulk_insert so we execute raw SQL
module Gitlab
  module BackgroundMigration
    class ResolveVulnerabilitiesForRemovedAnalyzers < BatchedMigrationJob
      operation_name :resolve_vulnerabilities_for_removed_analyzers
      feature_category :static_application_security_testing

      RESOLVED_VULNERABILITY_COMMENT =
        'This vulnerability was automatically resolved because it was created by an analyzer that has ' \
          'been removed from GitLab SAST.'
      REMOVED_SCANNERS = %w[
        eslint
        gosec
        bandit
        security_code_scan
        brakeman
        flawfinder
        mobsf
        njsscan
        nodejs-scan
        nodejs_scan
        phpcs_security_audit
      ].index_with { true }

      module Migratable
        module Enums
          module Vulnerability
            VULNERABILITY_STATES = {
              detected: 1,
              confirmed: 4,
              resolved: 3,
              dismissed: 2
            }.freeze

            SEVERITY_LEVELS = {
              info: 1,
              unknown: 2,
              low: 4,
              medium: 5,
              high: 6,
              critical: 7
            }.freeze

            def self.severity_levels
              SEVERITY_LEVELS
            end

            def self.vulnerability_states
              VULNERABILITY_STATES
            end
          end
        end

        module Vulnerabilities
          class Feedback < ApplicationRecord
            self.table_name = "vulnerability_feedback"

            enum feedback_type: { dismissal: 0, issue: 1, merge_request: 2 }, _prefix: :for
          end

          class Read < ApplicationRecord
            self.table_name = "vulnerability_reads"
          end

          class Statistic < ApplicationRecord
            self.table_name = 'vulnerability_statistics'

            enum letter_grade: { a: 0, b: 1, c: 2, d: 3, f: 4 }
          end

          module Statistics
            class UpdateService
              # subtract the severity counts for the number of vulnerabilities
              # being resolved from the existing severity counts, and use that
              # to determine the letter grade.
              LETTER_GRADE_SQL = <<~SQL.freeze
                CASE
                  WHEN critical - %{critical} > 0 THEN
                    #{Migratable::Vulnerabilities::Statistic.letter_grades[:f]}
                  -- high is high + unknown
                  -- see https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/statistics/update_service.rb#L10
                  WHEN high + unknown - (%{high} + %{unknown}) > 0 THEN
                    #{Migratable::Vulnerabilities::Statistic.letter_grades[:d]}
                  WHEN medium - %{medium} > 0 THEN
                    #{Migratable::Vulnerabilities::Statistic.letter_grades[:c]}
                  WHEN low - %{low} > 0 THEN
                    #{Migratable::Vulnerabilities::Statistic.letter_grades[:b]}
                  ELSE
                    #{Migratable::Vulnerabilities::Statistic.letter_grades[:a]}
                END
              SQL

              # this implementation differs from https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/statistics/update_service.rb#L21-27
              # in that we only update records here, we don't insert new vulnerability_statistics records.
              #
              # The reason why we only update records is the following:
              #
              # 1. The original Vulnerabilities::Statistics::UpdateService code is called for new
              #    projects that don't yet have any vulnerabilities, and therefore doesn't have any
              #    vulnerability_statistics records.
              #
              #    However, in our case, we're resolving vulnerabilities that already exist
              #    for a given project, so we can assume that a vulnerability_statistics record
              #    must also exist, because a vulnerability_statistics record is created when
              #    a vulnerability is created. I've also verified this fact on production data.
              #
              # 2. Even if we were to create a new vulnerability_statistics record, it wouldn't
              #    make sense, because if we're resolving 20 critical vulnerabilities, we can't
              #    create a vulnerability_statistics record with `critical: -20` since statistics
              #    shouldn't be negative. At best, we could initialize the vulnerability_statistics
              #    record to contain zero for every severity level.
              UPDATE_SQL = <<~SQL
                UPDATE vulnerability_statistics
                SET    %{update_values}, letter_grade = (%{letter_grade}), updated_at = now()
                WHERE  project_id = %{project_id}
              SQL

              def self.update_for(vulnerability_tuples)
                new(vulnerability_tuples).execute
              end

              def initialize(vulnerability_tuples)
                self.changes_by_project = group_changes_by_project(vulnerability_tuples)
              end

              # Groups severity count changes by project and executes a single update statement
              # for each project. In the worst case, where every severity count change belongs
              # to a different project, we'll end up executing SUB_BATCH_SIZE updates (currently
              # set to 100 in QueueResolveVulnerabilitiesForRemovedAnalyzers::SUB_BATCH_SIZE) and
              # in the best case, where all 100 changes belong to the same project, we'll execute
              # a single update statement.
              def execute
                changes_by_project.each do |changes|
                  connection.execute(update_sql(changes))
                end
              end

              # Groups vulnerability changes by project and aggregates the severity counts for each project.
              #
              # This method takes an array of vulnerability tuples and returns an array of hashes,
              # where each hash contains a project_id and counts of severities grouped by severity level.
              #
              # @param vulnerability_tuples [Array<Hash>] An array of vulnerability tuples.
              #
              # Each tuple is a hash with keys:
              #
              #   - :vulnerability_id [Integer]
              #   - :project_id [Integer]
              #   - :namespace_id [Integer]
              #   - :severity [Integer]
              #   - :uuid [String]
              #
              # @return [Array<Hash>] an array of hashes, where each hash represents a project with its ID and a
              # hash of severity counts.
              #
              #   The format of the returned array of hashes is:
              #     [
              #       {
              #         project_id: Integer,
              #         severity_counts: {
              #           info: Integer,
              #           unknown: Integer,
              #           low: Integer,
              #           medium: Integer,
              #           high: Integer,
              #           critical: Integer,
              #           total: Integer
              #         }
              #       },
              #       ...
              #     ]
              #
              #   Keys for zero-value severity counts will be omitted
              #
              # @example
              #   vulnerability_tuples = [
              #     { vulnerability_id: 145, project_id: 10, namespace_id: 19, severity: 7, uuid: 'abc-1234' },
              #     { vulnerability_id: 146, project_id: 10, namespace_id: 19, severity: 7, uuid: 'abc-1234' },
              #     { vulnerability_id: 147, project_id: 10, namespace_id: 19, severity: 4, uuid: 'abc-1234' },
              #     { vulnerability_id: 148, project_id: 11, namespace_id: 19, severity: 7, uuid: 'abc-1234' },
              #     { vulnerability_id: 149, project_id: 11, namespace_id: 19, severity: 7, uuid: 'abc-1234' },
              #     { vulnerability_id: 150, project_id: 12, namespace_id: 19, severity: 4, uuid: 'abc-1234' },
              #     { vulnerability_id: 151, project_id: 12, namespace_id: 19, severity: 5, uuid: 'abc-1234' },
              #     { vulnerability_id: 152, project_id: 12, namespace_id: 19, severity: 6, uuid: 'abc-1234' }
              #   ]
              #
              #   group_changes_by_project(vulnerability_tuples)
              #     => [
              #          {
              #            project_id: 10,
              #            severity_counts: { critical: 2, low: 1, total: 3 }
              #          },
              #          {
              #            project_id: 11,
              #            severity_counts: { critical: 2, total: 2 }
              #          },
              #          {
              #            project_id: 12,
              #            severity_counts: { high: 1, medium: 1, low: 1, total: 3 }
              #          }
              #        ]
              def group_changes_by_project(vulnerability_tuples)
                severity_levels = Migratable::Enums::Vulnerability.severity_levels

                vulnerability_tuples.group_by { |tuple| tuple[:project_id] }.map do |project_id, tuples|
                  changes_hash = tuples.each_with_object(Hash.new(0)) do |tuple, counts|
                    severity = severity_levels.key(tuple[:severity])
                    counts[severity] += 1 if severity
                  end
                  changes_hash[:total] = changes_hash.values.sum
                  { project_id: project_id, severity_counts: changes_hash }
                end
              end

              private

              attr_accessor :changes_by_project

              delegate :connection, to: Migratable::Vulnerabilities::Statistic, private: true
              delegate :quote, :quote_column_name, to: :connection, private: true

              def update_sql(changes)
                format(
                  UPDATE_SQL,
                  project_id: changes[:project_id],
                  letter_grade: letter_grade(changes[:severity_counts]),
                  update_values: update_values(changes[:severity_counts])
                )
              end

              def letter_grade(severity_counts)
                format(
                  LETTER_GRADE_SQL,
                  critical: severity_counts[:critical],
                  high: severity_counts[:high],
                  unknown: severity_counts[:unknown],
                  medium: severity_counts[:medium],
                  low: severity_counts[:low]
                )
              end

              # when vulnerabilities are resolved, they're no longer considered a threat,
              # so we want to decrement the number of vulnerabilities matching the severity
              # level from the vulnerability_statistics table, as well as the total number of
              # vulnerabilities. We use GREATEST to ensure that we don't end up with a
              # negative value for any of these counts.
              #
              # For example, if we have the following vulnerability_statistics record:
              #
              # { project_id: 1, total: 11, critical: 4, medium: 6, low: 1 }
              #
              # and the following severity_counts
              #
              # { total: 9, critical: 4, medium: 5 }
              #
              # then we'll subtract the above severity_counts from the vulnerability_statistics
              # record and will end up with the following:
              #
              # { project_id: 1, total: 2, critical: 0, medium: 1, low: 1 }
              def update_values(severity_counts)
                severity_counts.map do |severity, count|
                  column_name = quote_column_name(severity)
                  quoted_value = quote(count)
                  "#{column_name} = GREATEST(#{column_name} - #{quoted_value}, 0)"
                end.join(', ')
              end
            end
          end
        end
      end

      scope_to ->(relation) do
        relation.where(state: [Migratable::Enums::Vulnerability.vulnerability_states[:detected]])
      end

      def perform
        user_id = Users::Internal.security_bot.id

        each_sub_batch do |sub_batch|
          cte = Gitlab::SQL::CTE.new(:batched_relation, sub_batch.limit(100))

          filtered_batch = cte
            .apply_to(Migratable::Vulnerabilities::Read.all)
            .joins('INNER JOIN vulnerability_scanners ON vulnerability_scanners.id = vulnerability_reads.scanner_id')
            .where('vulnerability_scanners.external_id': REMOVED_SCANNERS.keys)

          vulnerability_tuples = values_for_fields(
            filtered_batch, :vulnerability_id, 'vulnerability_reads.project_id', :namespace_id, :severity, :uuid
          )

          connection.transaction do
            perform_bulk_writes(user_id, vulnerability_tuples)
          end
        end
      end

      private

      def values_for_fields(relation, *field_names)
        relation.select(*field_names).map do |field|
          field.attributes.except('id').with_indifferent_access
        end
      end

      def perform_bulk_writes(user_id, vulnerability_tuples)
        return if vulnerability_tuples.empty?

        vulnerability_ids = vulnerability_tuples.pluck(:vulnerability_id)

        bulk_resolve(vulnerability_ids, user_id)
        bulk_create_state_transitions(vulnerability_ids, user_id)
        bulk_remove_dismissal_reason(vulnerability_ids)
        bulk_create_system_note_with_metadata(vulnerability_tuples, user_id)
        bulk_update_vulnerability_statistics(vulnerability_tuples)
        bulk_destroy_dismissal_feedback(vulnerability_tuples)
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/base_service.rb#L26
      def bulk_resolve(vulnerability_ids, user_id)
        connection.execute(<<~SQL)
          UPDATE vulnerabilities SET
          state          = #{Migratable::Enums::Vulnerability.vulnerability_states[:resolved]},
          resolved_by_id = #{user_id},
          resolved_at    = now()
          WHERE vulnerabilities.id in (#{vulnerability_ids.join(',')})
        SQL
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/base_state_transition_service.rb#L15
      def bulk_create_state_transitions(vulnerability_ids, user_id)
        current_time = Time.current

        rows = vulnerability_ids.map do |vulnerability_id|
          {
            vulnerability_id: vulnerability_id,
            from_state: Migratable::Enums::Vulnerability.vulnerability_states[:detected],
            to_state: Migratable::Enums::Vulnerability.vulnerability_states[:resolved],
            created_at: current_time,
            updated_at: current_time,
            author_id: user_id,
            comment: RESOLVED_VULNERABILITY_COMMENT
          }
        end

        ApplicationRecord.legacy_bulk_insert('vulnerability_state_transitions', rows)
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/base_state_transition_service.rb#L37
      def bulk_remove_dismissal_reason(vulnerability_ids)
        connection.execute(<<~SQL)
          UPDATE vulnerability_reads SET
          dismissal_reason = NULL
          WHERE vulnerability_reads.vulnerability_id in (#{vulnerability_ids.join(',')})
        SQL
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/app/models/discussion.rb#L71-71
      def discussion_id(vulnerability_id)
        # rubocop:disable Fips/SHA1 -- disable this cop to maintain parity with app/models/discussion.rb
        # a valid discussion_id is required for responding to vulnerability comments
        Digest::SHA1.hexdigest("discussion-vulnerability-#{vulnerability_id}-#{SecureRandom.hex}")
        # rubocop:enable Fips/SHA1
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/app/services/system_notes/base_service.rb#L19
      def bulk_create_system_note_with_metadata(vulnerability_tuples, user_id)
        current_time = Time.current

        system_notes_rows = vulnerability_tuples.map do |vulnerability_id_tuple|
          {
            note: RESOLVED_VULNERABILITY_COMMENT,
            noteable_type: 'Vulnerability',
            author_id: user_id,
            created_at: current_time,
            updated_at: current_time,
            project_id: vulnerability_id_tuple[:project_id],
            noteable_id: vulnerability_id_tuple[:vulnerability_id],
            system: 'TRUE',
            discussion_id: discussion_id(vulnerability_id_tuple[:vulnerability_id]),
            namespace_id: vulnerability_id_tuple[:namespace_id]
          }
        end

        system_note_ids = ApplicationRecord.legacy_bulk_insert('notes', system_notes_rows, return_ids: true)

        system_note_metadata_rows = system_note_ids.map do |system_note_id|
          {
            action: 'vulnerability_resolved',
            created_at: current_time,
            updated_at: current_time,
            note_id: system_note_id
          }
        end

        ApplicationRecord.legacy_bulk_insert('system_note_metadata', system_note_metadata_rows)
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/base_service.rb#L22
      def bulk_update_vulnerability_statistics(vulnerability_tuples)
        Migratable::Vulnerabilities::Statistics::UpdateService.update_for(vulnerability_tuples)
      end

      # https://gitlab.com/gitlab-org/gitlab/blob/18dc5fe8566e/ee/app/services/vulnerabilities/resolve_service.rb#L11
      def bulk_destroy_dismissal_feedback(vulnerability_tuples)
        uuid_values = vulnerability_tuples.pluck(:uuid).map { |uuid| connection.quote(uuid) }.join(',')

        connection.execute(<<~SQL)
          DELETE FROM vulnerability_feedback
          WHERE feedback_type = #{Migratable::Vulnerabilities::Feedback.feedback_types[:dismissal]}
          AND finding_uuid IN (#{uuid_values})
        SQL
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Gitlab/BulkInsert
