# frozen_string_literal: true

class ScheduleUpdateJiraTrackerDataDeploymentTypeBasedOnUrl < ActiveRecord::Migration[6.0]
  def up
    # no-op (being re-run in 20220324152945_update_jira_tracker_data_deployment_type_based_on_url.rb)
    # due to this migration causing this issue: https://gitlab.com/gitlab-org/gitlab/-/issues/336849
    # The migration is rescheduled in
    # db/post_migrate/20220725150127_update_jira_tracker_data_deployment_type_based_on_url.rb
    # Related discussion: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82103#note_862401816
  end

  def down
    # no-op
  end
end
