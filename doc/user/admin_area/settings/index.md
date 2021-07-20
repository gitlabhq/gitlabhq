---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index
---

# Admin Area settings **(FREE SELF)**

As an administrator of a GitLab self-managed instance, you can manage the behavior of your deployment. To do so, select **Admin Area > Settings**.

The Admin Area is not accessible on GitLab.com, and settings can only be changed by the
GitLab.com administrators. See the [GitLab.com settings](../../gitlab_com/index.md)
documentation for all current settings and limits on the GitLab.com instance.

## General

To access the default page for Admin Area settings:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**.

| Option | Description |
| ------ | ----------- |
| [Visibility and access controls](visibility_and_access_controls.md) | Set default and restrict visibility levels. Configure import sources and Git access protocol. |
| [Account and limit](account_and_limit_settings.md) | Set projects and maximum size limits, session duration, user options, and check feature availability for namespace plan. |
| [Diff limits](../diff_limits.md) | Diff content limits. |
| [Sign-up restrictions](sign_up_restrictions.md) | Configure the way a user creates a new account. |
| [Sign in restrictions](sign_in_restrictions.md) | Set requirements for a user to sign in. Enable mandatory two-factor authentication. |
| [Terms of Service and Privacy Policy](terms.md) | Include a Terms of Service agreement and Privacy Policy that all users must accept. |
| [External Authentication](external_authorization.md#configuration) | External Classification Policy Authorization |
| [Web terminal](../../../administration/integration/terminal.md#limiting-websocket-connection-time) | Set max session time for web terminal. |
| [Web IDE](../../project/web_ide/index.md#enable-live-preview) | Manage Web IDE features. |
| [FLoC](floc.md) | Enable or disable [Federated Learning of Cohorts (FLoC)](https://en.wikipedia.org/wiki/Federated_Learning_of_Cohorts) tracking. |

## Integrations

| Option | Description |
| ------ | ----------- |
| [Elasticsearch](../../../integration/elasticsearch.md#enabling-advanced-search) | Elasticsearch integration. Elasticsearch AWS IAM. |
| [Kroki](../../../administration/integration/kroki.md#enable-kroki-in-gitlab) | Allow rendering of diagrams in AsciiDoc and Markdown documents using [kroki.io](https://kroki.io). |
| [PlantUML](../../../administration/integration/plantuml.md) | Allow rendering of PlantUML diagrams in documents. |
| [Slack application](../../../user/project/integrations/gitlab_slack_application.md#configuration) **(FREE SAAS)** | Slack integration allows you to interact with GitLab via slash commands in a chat window. This option is only available on GitLab.com, though it may be [available for self-managed instances in the future](https://gitlab.com/gitlab-org/gitlab/-/issues/28164). |
| [Third party offers](third_party_offers.md) | Control the display of third party offers. |
| [Snowplow](../../../development/snowplow/index.md) | Configure the Snowplow integration. |
| [Google GKE](../../project/clusters/add_gke_clusters.md) | Google GKE integration allows you to provision GKE clusters from GitLab. |
| [Amazon EKS](../../project/clusters/add_eks_clusters.md) | Amazon EKS integration allows you to provision EKS clusters from GitLab. |

## Repository

| Option | Description |
| ------ | ----------- |
| [Repository's custom initial branch name](../../project/repository/branches/default.md#instance-level-custom-initial-branch-name) | Set a custom branch name for new repositories created in your instance. |
| [Repository mirror](visibility_and_access_controls.md#allow-mirrors-to-be-set-up-for-projects) | Configure repository mirroring. |
| [Repository storage](../../../administration/repository_storage_types.md) | Configure storage path settings. |
| Repository maintenance | ([Repository checks](../../../administration/repository_checks.md) and [Housekeeping](../../../administration/housekeeping.md)). Configure automatic Git checks and housekeeping on repositories. |
| [Repository static objects](../../../administration/static_objects_external_storage.md) | Serve repository static objects (for example, archives, blobs, ...) from an external storage (for example, a CDN). |

## Templates **(PREMIUM SELF)**

| Option | Description |
| ------ | ----------- |
| [Templates](instance_template_repository.md#configuration) | Set instance-wide template repository. |
| [Custom project templates](../custom_project_templates.md) | Select the custom project template source group. |

## CI/CD

| Option | Description |
| ------ | ----------- |
| [Continuous Integration and Deployment](continuous_integration.md) | Auto DevOps, runners and job artifacts. |
| [Required pipeline configuration](continuous_integration.md#required-pipeline-configuration) **(PREMIUM SELF)** | Set an instance-wide auto included [pipeline configuration](../../../ci/yaml/index.md). This pipeline configuration is run after the project's own configuration. |
| [Package Registry](continuous_integration.md#package-registry-configuration) | Settings related to the use and experience of using the GitLab Package Registry. Note there are [risks involved](../../packages/container_registry/index.md#use-with-external-container-registries) in enabling some of these settings. |

## Reporting

| Option | Description |
| ------ | ----------- |
| [Spam and Anti-bot Protection](../../../integration/recaptcha.md) | Enable reCAPTCHA or Akismet and set IP limits. For reCAPTCHA, we currently only support [v2](https://developers.google.com/recaptcha/docs/versions). |
| [Abuse reports](../review_abuse_reports.md) | Set notification email for abuse reports. |

## Metrics and profiling

| Option | Description |
| ------ | ----------- |
| [Metrics - Prometheus](../../../administration/monitoring/prometheus/gitlab_metrics.md) | Enable and configure Prometheus metrics. |
| [Metrics - Grafana](../../../administration/monitoring/performance/grafana_configuration.md#integration-with-gitlab-ui) | Enable and configure Grafana. |
| [Profiling - Performance bar](../../../administration/monitoring/performance/performance_bar.md#enable-the-performance-bar-via-the-admin-area) | Enable access to the Performance Bar for a given group. |
| [Self monitoring](../../../administration/monitoring/gitlab_self_monitoring_project/index.md#creating-the-self-monitoring-project) | Enable or disable instance self monitoring. |
| [Usage statistics](usage_statistics.md) | Enable or disable version check and Service Ping. |
| [Pseudonymizer data collection](../../../administration/pseudonymizer.md) **(ULTIMATE)** | Enable or disable the Pseudonymizer data collection. |

## Network

| Option | Description |
| ------ | ----------- |
| Performance optimization | [Write to "authorized_keys" file](../../../administration/operations/fast_ssh_key_lookup.md#setting-up-fast-lookup-via-gitlab-shell) and [Push event activities limit and bulk push events](push_event_activities_limit.md). Various settings that affect GitLab performance. |
| [User and IP rate limits](user_and_ip_rate_limits.md) | Configure limits for web and API requests. |
| [Package Registry Rate Limits](package_registry_rate_limits.md) | Configure specific limits for Packages API requests that supersede the user and IP rate limits. |
| [Outbound requests](../../../security/webhooks.md) | Allow requests to the local network from hooks and services. |
| [Protected Paths](protected_paths.md) | Configure paths to be protected by Rack Attack. |
| [Incident Management](../../../operations/incident_management/index.md) Limits | Configure limits on the number of inbound alerts able to be sent to a project. |
| [Notes creation limit](rate_limit_on_notes_creation.md)| Set a rate limit on the note creation requests. |

## Geo

| Option | Description |
| ------ | ----------- |
| Geo    | Geo allows you to replicate your GitLab instance to other geographical locations. Redirects to **Admin Area > Geo > Settings** are no longer available at **Admin Area > Settings > Geo** in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/36896). |

## Preferences

| Option | Description |
| ------ | ----------- |
| [Email](email.md) | Various email settings. |
| [What's new](../../../administration/whats-new.md) | Configure What's new drawer and content. |
| [Help page](help_page.md) | Help page text and support page URL. |
| [Pages](../../../administration/pages/index.md#custom-domain-verification) | Size and domain settings for static websites |
| [Real-time features](../../../administration/polling.md) | Change this value to influence how frequently the GitLab UI polls for updates. |
| [Gitaly timeouts](gitaly_timeouts.md) | Configure Gitaly timeouts. |
| Localization | [Default first day of the week](../../profile/preferences.md) and [Time tracking](../../project/time_tracking.md#limit-displayed-units-to-hours). |

### Default first day of the week

You can change the [Default first day of the week](../../profile/preferences.md)
for the entire GitLab instance:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Preferences**.
1. Scroll to the **Localization** section, and select your desired first day of the week.
