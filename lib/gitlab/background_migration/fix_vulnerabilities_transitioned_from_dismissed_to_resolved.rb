# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class FixVulnerabilitiesTransitionedFromDismissedToResolved < BatchedMigrationJob
      # The earliest that records could have appeared on .com was when the feature flag was enabled
      # on 2024-12-05: https://gitlab.com/gitlab-org/gitlab/-/issues/505711
      #
      # In self-managed, it could have appeared beginning in the 17.7 release on 2024-12-19.
      FIRST_APPEARANCE_DATE = Date.new(2024, 12, 5)
      COMMENT = "Status changed to dismissed. Reverts a bug that incorrectly set this vulnerability to resolved." \
        "For details, see [issue 523433](https://gitlab.com/gitlab-org/gitlab/-/issues/523433)"

      job_arguments :namespace_id
      operation_name :fix_vulnerabilities_transitioned_from_dismissed_to_resolved
      feature_category :vulnerability_management

      class Vulnerability < ::SecApplicationRecord
        self.table_name = 'vulnerabilities'

        has_many :state_transitions, -> { order(id: :desc) }, class_name: 'StateTransition'
        belongs_to :project, class_name: 'Project'

        enum :state, {
          detected: 1,
          confirmed: 4,
          resolved: 3,
          dismissed: 2
        }

        scope :with_state_transitions_author_and_project, -> { preload([{ state_transitions: :author }, :project]) }
        scope :transitioned_at_least_once, -> {
          where('EXISTS (SELECT 1 FROM vulnerability_state_transitions WHERE vulnerability_id = vulnerabilities.id)')
        }
      end

      class StateTransition < ::SecApplicationRecord
        self.table_name = 'vulnerability_state_transitions'

        belongs_to :author, class_name: 'User'

        def created_before_issue_first_appeared?
          created_at.before?(FIRST_APPEARANCE_DATE)
        end

        def transitioned_from_dismissed_to_resolved?
          from_state == 2 && to_state == 3
        end
      end

      class Project < ApplicationRecord
        self.table_name = 'projects'
      end

      class User < ApplicationRecord
        self.table_name = 'users'

        def security_policy_bot?
          user_type == 10
        end
      end

      class Note < ApplicationRecord
        self.table_name = 'notes'
      end

      def perform
        each_sub_batch do |batch|
          vulnerability_reads = scoped_vulnerability_reads(batch)

          next if vulnerability_reads.blank?

          data = affected_vulnerability_data(vulnerability_reads)

          next if data.blank?

          batch_timestamp = Time.current

          transition_states(data, batch_timestamp)
          insert_notes(data, batch_timestamp)
        end
      end

      def scoped_vulnerability_reads(vulnerability_reads)
        relation = vulnerability_reads.where(state: [Vulnerability.states[:detected], Vulnerability.states[:resolved]])

        return relation if namespace_id == 'instance'

        relation
          .where(vulnerability_reads.arel_table[:traversal_ids].gteq([namespace_id]))
          .where(vulnerability_reads.arel_table[:traversal_ids].lt([namespace_id.next]))
      end

      def affected_vulnerability_data(vulnerability_reads)
        Vulnerability
          .id_in(vulnerability_reads.pluck(:vulnerability_id))
          .transitioned_at_least_once
          .with_state_transitions_author_and_project
          .filter_map do |vulnerability|
            bug_transition = affected_transition(vulnerability)

            next if bug_transition.blank?

            {
              vulnerability: vulnerability,
              bug_transition: bug_transition,
              original_dismissal_transition: original_dismissal(vulnerability, bug_transition)
            }
          end
      end

      def affected_transition(vulnerability)
        vulnerability.state_transitions.find do |state_transition|
          break if state_transition.created_before_issue_first_appeared?
          # If the state has been transitioned by someone besides the security policy bot then we should
          # respect their decision. When a vulnerability is redetected by a scanner, the transition has no author.
          break if state_transition.author.present? && !state_transition.author.security_policy_bot?

          state_transition.transitioned_from_dismissed_to_resolved?
        end
      end

      def original_dismissal(vulnerability, bug_transition)
        bug_transition_index = vulnerability.state_transitions.index(bug_transition)
        prior_transitions = vulnerability.state_transitions[(bug_transition_index + 1)..]
        prior_transitions.find { |transition| transition.to_state == Vulnerability.states[:dismissed] }
      end

      def transition_states(data, timestamp)
        vulnerability_ids = data.map { |record| record[:vulnerability].id }

        Vulnerability.transaction do
          Vulnerability.id_in(vulnerability_ids).update_all(state: :dismissed, updated_at: timestamp)
          StateTransition.insert_all(state_transition_attributes(data, timestamp))
        end
      end

      def state_transition_attributes(data, timestamp)
        data.map do |record|
          {
            author_id: record[:bug_transition].author_id,
            from_state: Vulnerability.states[record[:vulnerability].state],
            to_state: Vulnerability.states[:dismissed],
            dismissal_reason: record[:original_dismissal_transition]&.dismissal_reason || 0,
            vulnerability_id: record[:vulnerability].id,
            comment: COMMENT,
            created_at: timestamp,
            updated_at: timestamp
          }
        end
      end

      def insert_notes(data, timestamp)
        Note.insert_all(note_attributes(data, timestamp))
      end

      def note_attributes(data, timestamp)
        data.map do |record|
          vulnerability = record[:vulnerability]
          {
            noteable_type: "Vulnerability",
            noteable_id: vulnerability.id,
            project_id: vulnerability.project.id,
            namespace_id: vulnerability.project.project_namespace_id,
            system: true,
            note: COMMENT,
            author_id: record[:bug_transition].author_id,
            created_at: timestamp,
            updated_at: timestamp
          }
        end
      end

      def connection
        ::SecApplicationRecord.connection
      end
    end
  end
end
