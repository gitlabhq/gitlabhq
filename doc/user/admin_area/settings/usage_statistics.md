---
type: reference
---

# Usage statistics **(CORE ONLY)**

GitLab Inc. will periodically collect information about your instance in order
to perform various actions.

All statistics are opt-out. You can enable/disable them in the
**Admin Area > Settings > Metrics and profiling** section **Usage statistics**.

## Network configuration

Allow network traffic from your GitLab instance to IP address `104.196.17.203:443`, to send
usage statistics to GitLab Inc.

If your GitLab instance is behind a proxy, set the appropriate [proxy configuration variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

## Version Check **(CORE ONLY)**

If enabled, version check will inform you if a new version is available and the
importance of it through a status. This is shown on the help page (i.e. `/help`)
for all signed in users, and on the admin pages. The statuses are:

- Green: You are running the latest version of GitLab.
- Orange: An updated version of GitLab is available.
- Red: The version of GitLab you are running is vulnerable. You should install
  the latest version with security fixes as soon as possible.

![Orange version check example](img/update-available.png)

GitLab Inc. collects your instance's version and hostname (through the HTTP
referer) as part of the version check. No other information is collected.

This information is used, among other things, to identify to which versions
patches will need to be backported, making sure active GitLab instances remain
secure.

If you disable version check, this information will not be collected. Enable or
disable the version check in **Admin Area > Settings > Metrics and profiling > Usage statistics**.

### Request flow example

The following example shows a basic request/response flow between the self-managed GitLab instance
and the GitLab Version Application:

```mermaid
sequenceDiagram
    participant GitLab instance
    participant Version Application
    GitLab instance->>Version Application: Is there a version update?
    loop Version Check
        Version Application->>Version Application: Record version info
    end
    Version Application->>GitLab instance: Response (PNG/SVG)
```

## Usage Ping **(CORE ONLY)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/557) in GitLab Enterprise Edition 8.10.
> - More statistics [were added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/735) in GitLab Enterprise Edition 8.12.
> - [Moved to GitLab Core](https://gitlab.com/gitlab-org/gitlab-foss/issues/23361) in 9.1.
> - More statistics [were added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6602) in GitLab Ultimate 11.2.

GitLab sends a weekly payload containing usage data to GitLab Inc. The usage
ping uses high-level data to help our product, support, and sales teams. It does
not send any project names, usernames, or any other specific data. The
information from the usage ping is not anonymous, it is linked to the hostname
of the instance.

You can view the exact JSON payload in the administration panel. To view the payload:

1. Navigate to the **Admin Area > Settings > Metrics and profiling**.
1. Expand the **Usage statistics** section.
1. Click the **Preview payload** button.

You can see how [the usage ping data maps to different stages of the product](https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/version_usage_stats_to_stage_mappings.csv).

Usage ping is important to GitLab as we use it to calculate our [Action Monthly Active Users (AMAU)](https://about.gitlab.com/handbook/product/metrics/#action-monthly-active-users-amau) which helps us measure the success of our features.

### Request flow example

The following example shows a basic request/response flow between the self-managed GitLab instance, GitLab Version Application,
GitLab License Application and Salesforce:

```mermaid
sequenceDiagram
    participant GitLab instance
    participant Version Application
    participant License Application
    participant Salesforce
    GitLab instance->>Version Application: Usage Ping data
    loop Process Usage Data
        Version Application->>Version Application: Parse Usage Data
        Version Application->>Version Application: Record Usage Data
        Version Application->>Version Application: Update license ping time
    end
    Version Application-xLicense Application: Request Zuora subscription id
    License Application-xVersion Application: Zuora subscription id
    Version Application-xSalesforce: Request Zuora account id  by Zuora subscription id
    Salesforce-xVersion Application: Zuora account id
    Version Application-xSalesforce: Usage data for the Zuora account
    Version Application->>GitLab instance: Conversational Development Index
```

### Deactivate the usage ping

The usage ping is opt-out. If you want to deactivate this feature, go to
the Settings page of your administration panel and uncheck the Usage ping
checkbox.

To disable the usage ping and prevent it from being configured in future through
the administration panel, Omnibus installs can set the following in
[`gitlab.rb`](https://docs.gitlab.com/omnibus/settings/configuration.html#configuration-options):

```ruby
gitlab_rails['usage_ping_enabled'] = false
```

And source installs can set the following in `gitlab.yml`:

```yaml
production: &base
  # ...
  gitlab:
    # ...
    usage_ping_enabled: false
```

## Instance statistics visibility **(CORE ONLY)**

Once usage ping is enabled, GitLab will gather data from other instances and
will be able to show [usage statistics](../../instance_statistics/index.md)
of your instance to your users.

To make this visible only to admins, go to **Admin Area > Settings > Metrics and profiling**, expand
**Usage statistics**, and set the **Instance Statistics visibility** option to **Only admins**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

## Usage Statistics Collected

| Statistic  | Section  | Stage    | Description   |
|---|---|---|---|
|uuid|||
|hostname|||
|version|||
|installation_type|||
|active_user_count|||
|recorded_at|||
|edition|||
|license_md5|||
|license_id|||
|historical_max_users|||
|Name|licensee||
|Email|licensee||
|Company|licensee||
|license_user_count|||
|license_starts_at|||
|license_expires_at|||
|license_plan|||
|license_trial|||
|assignee_lists|counts||
|boards|counts||
|ci_builds|counts||
|ci_internal_pipelines|counts||
|ci_external_pipelines|counts||
|ci_pipeline_config_auto_devops|counts||
|ci_pipeline_config_repository|counts||
|ci_runners|counts||
|ci_triggers|counts||
|ci_pipeline_schedules|counts||
|auto_devops_enabled|counts||
|auto_devops_disabled|counts||
|deploy_keys|counts||
|deployments|counts||
|dast_jobs|counts||
|successful_deployments|counts||
|failed_deployments|counts||
|environments|counts||
|clusters|counts||
|clusters_enabled|counts||
|project_clusters_enabled|counts||
|group_clusters_enabled|counts||
|instance_clusters_enabled|counts||
|clusters_disabled|counts||
|project_clusters_disabled|counts||
|group_clusters_disabled|counts||
|instance_clusters_disabled|counts||
|clusters_platforms_eks|counts||
|clusters_platforms_gke|counts||
|clusters_platforms_user|counts||
|clusters_applications_helm|counts||
|clusters_applications_ingress|counts||
|clusters_applications_cert_managers|counts||
|clusters_applications_crossplane|counts||
|clusters_applications_prometheus|counts||
|clusters_applications_runner|counts||
|clusters_applications_knative|counts||
|clusters_applications_elastic_stack|counts||
|clusters_management_project|counts||
|in_review_folder|counts||
|grafana_integrated_projects|counts||
|groups|counts||
|issues|counts||
|issues_created_from_gitlab_error_tracking_ui|counts||
|issues_with_associated_zoom_link|counts||
|issues_using_zoom_quick_actions|counts||
|issues_with_embedded_grafana_charts_approx|counts||
|issues_with_health_status|counts||
|keys|counts||
|label_lists|counts||
|lfs_objects|counts||
|milestone_lists|counts||
|milestones|counts||
|pages_domains|counts||
|pool_repositories|counts||
|projects|counts||
|projects_imported_from_github|counts||
|projects_with_repositories_enabled|counts||
|projects_with_error_tracking_enabled|counts||
|protected_branches|counts||
|releases|counts||
|remote_mirrors|counts||
|requirements_created|counts||
|snippets|counts||
|suggestions|counts||
|todos|counts||
|uploads|counts||
|web_hooks|counts||
|projects_alerts_active|counts||
|projects_asana_active|counts||
|projects_assembla_active|counts||
|projects_bamboo_active|counts||
|projects_bugzilla_active|counts||
|projects_buildkite_active|counts||
|projects_campfire_active|counts||
|projects_custom_issue_tracker_active|counts||
|projects_discord_active|counts||
|projects_drone_ci_active|counts||
|projects_emails_on_push_active|counts||
|projects_external_wiki_active|counts||
|projects_flowdock_active|counts||
|projects_github_active|counts||
|projects_hangouts_chat_active|counts||
|projects_hipchat_active|counts||
|projects_irker_active|counts||
|projects_jenkins_active|counts||
|projects_jenkins_deprecated_active|counts||
|projects_jira_active -|counts||
|projects_mattermost_active|counts||
|projects_mattermost_slash_commands_active|counts||
|projects_microsoft_teams_active|counts||
|projects_packagist_active|counts||
|projects_pipelines_email_active|counts||
|projects_pivotaltracker_active|counts||
|projects_prometheus_active|counts||
|projects_pushover_active|counts||
|projects_redmine_active|counts||
|projects_slack_active|counts||
|projects_slack_slash_commands_active|counts||
|projects_teamcity_active|counts||
|projects_unify_circuit_active|counts||
|projects_youtrack_active|counts||
|projects_slack_notifications_active|counts||
|projects_slack_slash_active|counts||
|projects_jira_server_active|counts||
|projects_jira_cloud_active|counts||
|projects_jira_dvcs_cloud_active|counts||
|projects_jira_dvcs_server_active|counts||
|labels|counts||
|merge_requests|counts||
|notes|counts||
|wiki_pages_create|counts||
|wiki_pages_update|counts||
|wiki_pages_delete|counts||
|web_ide_commits|counts||
|web_ide_views|counts||
|web_ide_merge_requests|counts||
|web_ide_previews|counts||
|snippet_comment|counts||
|commit_comment|counts||
|merge_request_comment|counts||
|snippet_create|counts||
|snippet_update|counts||
|navbar_searches|counts||
|cycle_analytics_views|counts||
|productivity_analytics_views|counts||
|source_code_pushes|counts||
|merge_request_create|counts||
|design_management_designs_create|counts||
|design_management_designs_update|counts||
|design_management_designs_delete|counts||
|licenses_list_views|counts||
|user_preferences_group_overview_details|counts||
|user_preferences_group_overview_security_dashboard|counts||
|ingress_modsecurity_logging|counts||
|ingress_modsecurity_blocking|counts||
|ingress_modsecurity_disabled|counts||
|ingress_modsecurity_not_installed|counts||
|dependency_list_usages_total|counts||
|epics|counts||
|feature_flags|counts||
|geo_nodes|counts||
|incident_issues|counts||
|ldap_group_links|counts||
|ldap_keys|counts||
|ldap_users|counts||
|pod_logs_usages_total|counts||
|projects_enforcing_code_owner_approval|counts||
|projects_mirrored_with_pipelines_enabled|counts||
|projects_reporting_ci_cd_back_to_github|counts||
|projects_with_packages|counts||
|projects_with_prometheus_alerts|counts||
|projects_with_tracing_enabled|counts||
|projects_with_alerts_service_enabled|counts||
|template_repositories|counts||
|container_scanning_jobs|counts||
|dependency_scanning_jobs|counts||
|license_management_jobs|counts||
|sast_jobs|counts||
|status_page_projects|counts|monitor|
|status_page_issues|counts|monitor|
|epics_deepest_relationship_level|counts||
|operations_dashboard_default_dashboard|counts||
|operations_dashboard_users_with_projects_added|counts||
|container_registry_enabled|||
|dependency_proxy_enabled|||
|gitlab_shared_runners_enabled|||
|gravatar_enabled|||
|influxdb_metrics_enabled|||
|ldap_enabled|||
|mattermost_enabled|||
|omniauth_enabled|||
|prometheus_metrics_enabled|||
|reply_by_email_enabled|||
|signup_enabled|||
|web_ide_clientside_preview_enabled|||
|ingress_modsecurity_enabled|||
|elasticsearch_enabled|||
|license_trial_ends_on|||
|geo_enabled|||
|version|Git||
|version|Gitaly||
|servers|Gitaly||
|filesystems|Gitaly||
|enabled|gitlab_pages||
|version|gitlab_pages||
|adapter|database||
|version|database||
|average|avg_cycle_analytics - issue||
|sd|avg_cycle_analytics - issue||
|missing|avg_cycle_analytics - issue||
|average|avg_cycle_analytics - plan||
|sd|avg_cycle_analytics - plan||
|missing|avg_cycle_analytics - plan||
|average|avg_cycle_analytics - code||
|sd|avg_cycle_analytics - code||
|missing|avg_cycle_analytics - code||
|average|avg_cycle_analytics - test||
|sd|avg_cycle_analytics - test||
|missing|avg_cycle_analytics - test||
|average|avg_cycle_analytics - review||
|sd|avg_cycle_analytics - review||
|missing|avg_cycle_analytics - review||
|average|avg_cycle_analytics - staging||
|sd|avg_cycle_analytics - staging||
|missing|avg_cycle_analytics - staging||
|average|avg_cycle_analytics - production||
|sd|avg_cycle_analytics - production||
|missing|avg_cycle_analytics - production||
|total|avg_cycle_analytics||
|clusters_applications_cert_managers|usage_activity_by_stage|configure|
|clusters_applications_helm|usage_activity_by_stage|configure|
|clusters_applications_ingress|usage_activity_by_stage|configure|
|clusters_applications_knative|usage_activity_by_stage|configure|
|clusters_management_project|usage_activity_by_stage|configure|
|clusters_disabled|usage_activity_by_stage|configure|
|clusters_enabled|usage_activity_by_stage|configure|
|clusters_platforms_gke|usage_activity_by_stage|configure|
|clusters_platforms_eks|usage_activity_by_stage|configure|
|clusters_platforms_user|usage_activity_by_stage|configure|
|instance_clusters_disabled|usage_activity_by_stage|configure|
|instance_clusters_enabled|usage_activity_by_stage|configure|
|group_clusters_disabled|usage_activity_by_stage|configure|
|group_clusters_enabled|usage_activity_by_stage|configure|
|project_clusters_disabled|usage_activity_by_stage|configure|
|project_clusters_enabled|usage_activity_by_stage|configure|
|projects_slack_notifications_active|usage_activity_by_stage|configure|
|projects_slack_slash_active|usage_activity_by_stage|configure|
|projects_with_prometheus_alerts: 0|usage_activity_by_stage|configure|
|deploy_keys|usage_activity_by_stage|create|
|keys|usage_activity_by_stage|create|
|merge_requests|usage_activity_by_stage|create|
|projects_enforcing_code_owner_approval|usage_activity_by_stage|create|
|projects_imported_from_github|usage_activity_by_stage|create|
|projects_with_repositories_enabled|usage_activity_by_stage|create|
|protected_branches|usage_activity_by_stage|create|
|remote_mirrors|usage_activity_by_stage|create|
|snippets|usage_activity_by_stage|create|
|suggestions:|usage_activity_by_stage|create|
|groups|usage_activity_by_stage|manage|
|ldap_keys|usage_activity_by_stage|manage|
|ldap_users: 0|usage_activity_by_stage|manage|
|users_created|usage_activity_by_stage|manage|
|clusters|usage_activity_by_stage|monitor|
|clusters_applications_prometheus|usage_activity_by_stage|monitor|
|operations_dashboard_default_dashboard|usage_activity_by_stage|monitor|
|operations_dashboard_users_with_projects_added|usage_activity_by_stage|monitor|
|projects_prometheus_active|usage_activity_by_stage|monitor|
|projects_with_error_tracking_enabled|usage_activity_by_stage|monitor|
|projects_with_tracing_enabled: 0|usage_activity_by_stage|monitor|
|projects_with_packages: 0|usage_activity_by_stage|package|
|assignee_lists|usage_activity_by_stage|plan|
|epics|usage_activity_by_stage|plan|
|issues|usage_activity_by_stage|plan|
|label_lists|usage_activity_by_stage|plan|
|milestone_lists|usage_activity_by_stage|plan|
|notes|usage_activity_by_stage|plan|
|projects|usage_activity_by_stage|plan|
|projects_jira_active|usage_activity_by_stage|plan|
|projects_jira_dvcs_cloud_active|usage_activity_by_stage|plan|
|projects_jira_dvcs_server_active|usage_activity_by_stage|plan|
|service_desk_enabled_projects|usage_activity_by_stage|plan|
|service_desk_issues|usage_activity_by_stage|plan|
|todos: 0|usage_activity_by_stage|plan|
|deployments|usage_activity_by_stage|release|
|failed_deployments|usage_activity_by_stage|release|
|projects_mirrored_with_pipelines_enabled|usage_activity_by_stage|release|
|releases|usage_activity_by_stage|release|
|successful_deployments: 0|usage_activity_by_stage|release|
|user_preferences_group_overview_security_dashboard: 0|usage_activity_by_stage|secure|
|ci_builds|usage_activity_by_stage|verify|
|ci_external_pipelines|usage_activity_by_stage|verify|
|ci_internal_pipelines|usage_activity_by_stage|verify|
|ci_pipeline_config_auto_devops|usage_activity_by_stage|verify|
|ci_pipeline_config_repository|usage_activity_by_stage|verify|
|ci_pipeline_schedules|usage_activity_by_stage|verify|
|ci_pipelines|usage_activity_by_stage|verify|
|ci_triggers|usage_activity_by_stage|verify|
|clusters_applications_runner|usage_activity_by_stage|verify|
|projects_reporting_ci_cd_back_to_github: 0|usage_activity_by_stage|verify|
