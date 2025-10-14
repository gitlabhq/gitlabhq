# frozen_string_literal: true

FactoryBot.define do
  factory :usage_data, class: 'Gitlab::UsageData' do
    skip_create # non-model factories (i.e. without #save)

    initialize_with do
      projects = create_list(:project, 4, :repository)
      group = create(:group)
      create(:board, project: projects[0])
      create(:jira_integration, project: projects[0])
      create(:jira_integration, :without_properties_callback, project: projects[1])
      create(:jira_integration, :jira_cloud, project: projects[2])
      create(:jira_integration, :without_properties_callback, project: projects[3], properties: { url: 'https://mysite.atlassian.net' })
      jira_label = create(:label, project: projects[0])
      create(:jira_import_state, :finished, project: projects[0], label: jira_label, failed_to_import_count: 2, imported_issues_count: 7, total_issue_count: 9)
      create(:jira_import_state, :finished, project: projects[1], label: jira_label, imported_issues_count: 3, total_issue_count: 3)
      create(:jira_import_state, :finished, project: projects[1], label: jira_label, imported_issues_count: 3)
      create(:jira_import_state, :scheduled, project: projects[1], label: jira_label)
      create(:prometheus_integration, project: projects[1])
      create(:jenkins_integration, project: projects[1])

      # slack
      create(:slack_slash_commands_integration, project: projects[0])
      create(:integrations_slack, project: projects[1])
      create(:integrations_slack, project: projects[2])

      # mattermost
      create(:mattermost_integration, project: projects[2], active: false)
      create(:mattermost_integration, group: group, project: nil)
      mattermost_instance = create(:mattermost_integration, :instance)
      create(:mattermost_integration, project: projects[1], inherit_from_id: mattermost_instance.id)
      create(:integrations_slack, group: group, project: nil, active: true, inherit_from_id: mattermost_instance.id)

      create(:custom_issue_tracker_integration, project: projects[2], active: true)
      create(:project_error_tracking_setting, project: projects[0])
      create(:project_error_tracking_setting, project: projects[1], enabled: false)
      create_list(:incident, 2, project: projects[0], author: Users::Internal.alert_bot)
      create_list(:incident, 2, project: projects[1], author: Users::Internal.alert_bot)
      create_list(:issue, 4, project: projects[0])
      create(:merge_request, :simple, :with_terraform_reports, source_project: projects[0])
      create(:merge_request, :rebased, :with_terraform_reports, source_project: projects[0])
      create(:merge_request, :simple, :with_terraform_reports, source_project: projects[1])
      create(:terraform_state, project: projects[0])
      create(:terraform_state, project: projects[0])
      create(:terraform_state, project: projects[1])
      create(:zoom_meeting, project: projects[0], issue: projects[0].issues[0], issue_status: :added)
      create_list(:zoom_meeting, 2, project: projects[0], issue: projects[0].issues[1], issue_status: :removed)
      create(:zoom_meeting, project: projects[0], issue: projects[0].issues[2], issue_status: :added)
      create_list(:zoom_meeting, 2, project: projects[0], issue: projects[0].issues[2], issue_status: :removed)
      create(:sentry_issue, issue: projects[0].issues[0])
      create(:protected_branch, project: projects[0])
      create(:protected_branch, name: 'main', project: projects[0])

      # Alert Management
      create(:alert_management_http_integration, project: projects[0], name: 'DataDog')
      create(:alert_management_http_integration, project: projects[0], name: 'DataCat')
      create(:alert_management_http_integration, :inactive, project: projects[1], name: 'DataFox')

      # Kubernetes agents
      create(:cluster_agent, project: projects[0])
      create(:cluster_agent_token, agent: create(:cluster_agent, project: projects[1]))

      # Enabled clusters
      gcp_cluster = create(:cluster_provider_gcp, :created).cluster
      create(:cluster_provider_aws, :created)
      create(:cluster_platform_kubernetes)
      create(:cluster, :management_project, management_project: projects[0])
      create(:cluster, :group)
      create(:cluster, :instance, :production_environment)

      # Disabled clusters
      create(:cluster, :disabled)
      create(:cluster, :group, :disabled)
      create(:cluster, :instance, :disabled)

      # Cluster Integrations
      create(:clusters_integrations_prometheus, cluster: gcp_cluster)

      create(:generic_package, project: projects[0], created_at: 3.days.ago)
      create(:generic_package, project: projects[0], created_at: 3.days.ago)
      create(:generic_package, project: projects[1], created_at: 3.days.ago)
      create(:generic_package, created_at: 2.months.ago, project: projects[1])

      # User Preferences
      create(:user_preference, gitpod_enabled: true)

      ProjectFeature.first.update_attribute('repository_access_level', 0)

      # Create fresh & a month (28-days SMAU) old  data
      env = create(:environment, project: projects[3])
      [3, 31].each do |n|
        deployment_options = { created_at: n.days.ago, project: env.project, environment: env }
        create(:deployment, :failed, **deployment_options)
        create(:deployment, :success, **deployment_options)
        create_list(:project_snippet, 2, project: projects[0], created_at: n.days.ago)
        create(:personal_snippet, created_at: n.days.ago)
      end

      create(:operations_feature_flag, project: projects[0])
    end
  end
end
