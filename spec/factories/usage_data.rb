# frozen_string_literal: true

FactoryBot.define do
  factory :usage_data, class: 'Gitlab::UsageData' do
    skip_create # non-model factories (i.e. without #save)

    initialize_with do
      projects = create_list(:project, 4)
      create(:board, project: projects[0])
      create(:jira_service, project: projects[0])
      create(:jira_service, :without_properties_callback, project: projects[1])
      create(:jira_service, :jira_cloud_service, project: projects[2])
      create(:jira_service, :without_properties_callback, project: projects[3],
             properties: { url: 'https://mysite.atlassian.net' })
      jira_label = create(:label, project: projects[0])
      create(:jira_import_state, :finished, project: projects[0], label: jira_label, failed_to_import_count: 2, imported_issues_count: 7, total_issue_count: 9)
      create(:jira_import_state, :finished, project: projects[1], label: jira_label, imported_issues_count: 3, total_issue_count: 3)
      create(:jira_import_state, :finished, project: projects[1], label: jira_label, imported_issues_count: 3)
      create(:jira_import_state, :scheduled, project: projects[1], label: jira_label)
      create(:prometheus_service, project: projects[1])
      create(:service, project: projects[0], type: 'SlackSlashCommandsService', active: true)
      create(:service, project: projects[1], type: 'SlackService', active: true)
      create(:service, project: projects[2], type: 'SlackService', active: true)
      create(:service, project: projects[2], type: 'MattermostService', active: false)
      create(:service, :template, type: 'MattermostService', active: true)
      create(:service, project: projects[2], type: 'CustomIssueTrackerService', active: true)
      create(:project_error_tracking_setting, project: projects[0])
      create(:project_error_tracking_setting, project: projects[1], enabled: false)
      create(:alerts_service, project: projects[0])
      create(:alerts_service, :inactive, project: projects[1])
      alert_bot_issues = create_list(:issue, 2, project: projects[0], author: User.alert_bot)
      create_list(:issue, 2, project: projects[1], author: User.alert_bot)
      issues = create_list(:issue, 4, project: projects[0])
      create_list(:prometheus_alert, 2, project: projects[0])
      create(:prometheus_alert, project: projects[1])
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

      # Incident Labeled Issues
      incident_label_attrs = IncidentManagement::CreateIssueService::INCIDENT_LABEL
      incident_label = create(:label, project: projects[0], **incident_label_attrs)
      create(:labeled_issue, project: projects[0], labels: [incident_label])
      incident_group = create(:group)
      incident_label_scoped_to_project = create(:label, project: projects[1], **incident_label_attrs)
      incident_label_scoped_to_group = create(:group_label, group: incident_group, **incident_label_attrs)
      create(:labeled_issue, project: projects[1], labels: [incident_label_scoped_to_project])
      create(:labeled_issue, project: projects[1], labels: [incident_label_scoped_to_group])

      # Alert Issues
      create(:alert_management_alert, issue: issues[0], project: projects[0])
      create(:alert_management_alert, issue: alert_bot_issues[0], project: projects[0])
      create(:self_managed_prometheus_alert_event, related_issues: [issues[1]], project: projects[0])

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

      # Applications
      create(:clusters_applications_helm, :installed, cluster: gcp_cluster)
      create(:clusters_applications_ingress, :installed, cluster: gcp_cluster)
      create(:clusters_applications_cert_manager, :installed, cluster: gcp_cluster)
      create(:clusters_applications_prometheus, :installed, cluster: gcp_cluster)
      create(:clusters_applications_crossplane, :installed, cluster: gcp_cluster)
      create(:clusters_applications_runner, :installed, cluster: gcp_cluster)
      create(:clusters_applications_knative, :installed, cluster: gcp_cluster)
      create(:clusters_applications_elastic_stack, :installed, cluster: gcp_cluster)
      create(:clusters_applications_jupyter, :installed, cluster: gcp_cluster)

      create(:grafana_integration, project: projects[0], enabled: true)
      create(:grafana_integration, project: projects[1], enabled: true)
      create(:grafana_integration, project: projects[2], enabled: false)

      ProjectFeature.first.update_attribute('repository_access_level', 0)
    end
  end
end
