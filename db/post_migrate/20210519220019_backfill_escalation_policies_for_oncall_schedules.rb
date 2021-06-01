# frozen_string_literal: true

class BackfillEscalationPoliciesForOncallSchedules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Creates a single new escalation policy for projects which have
  # existing on-call schedules. Only one schedule is expected
  # per project, but it is possible to have multiple.
  #
  # An escalation rule is created for each existing schedule,
  # configured to immediately notify the schedule of an incoming
  # alert payload unless the alert has already been acknowledged.
  # For projects with multiple schedules, the name of the first saved
  # schedule will be used for the policy's description.
  #
  # Skips projects which already have escalation policies & schedules.
  #
  # EX)
  # For these existing records:
  #   Project #3
  #   IncidentManagement::OncallSchedules #13
  #     project_id: 3
  #     name: 'Awesome Schedule'
  #     description: null
  #   IncidentManagement::OncallSchedules #14
  #     project_id: 3
  #     name: '2ndary sched'
  #     description: 'Backup on-call'
  #
  # These will be inserted:
  #   EscalationPolicy #1
  #     project_id: 3
  #     name: 'On-call Escalation Policy'
  #     description: 'Immediately notify Awesome Schedule'
  #   EscalationRule #1
  #     policy_id: 1,
  #     oncall_schedule_id: 13
  #     status: 1 # Acknowledged status
  #     elapsed_time_seconds: 0
  #   EscalationRule #2
  #     policy_id: 1,
  #     oncall_schedule_id: 14
  #     status: 1 # Acknowledged status
  #     elapsed_time_seconds: 0
  def up
    ApplicationRecord.connection.exec_query(<<~SQL.squish)
      WITH new_escalation_policies AS (
        INSERT INTO incident_management_escalation_policies (
          project_id,
          name,
          description
        )
        SELECT
          DISTINCT ON (project_id) project_id,
          'On-call Escalation Policy',
          CONCAT('Immediately notify ', name)
        FROM incident_management_oncall_schedules
        WHERE project_id NOT IN (
          SELECT DISTINCT project_id
          FROM incident_management_escalation_policies
        )
        ORDER BY project_id, id
        RETURNING id, project_id
      )

      INSERT INTO incident_management_escalation_rules (
        policy_id,
        oncall_schedule_id,
        status,
        elapsed_time_seconds
      )
      SELECT
        new_escalation_policies.id,
        incident_management_oncall_schedules.id,
        1,
        0
      FROM new_escalation_policies
      INNER JOIN incident_management_oncall_schedules
        ON new_escalation_policies.project_id = incident_management_oncall_schedules.project_id
    SQL
  end

  # There is no way to distinguish between policies created
  # via the backfill or as a result of a user creating a new
  # on-call schedule.
  def down
    # no-op
  end
end
