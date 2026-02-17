---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Event data
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Toggle [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/510333) in GitLab 17.11.
- Environment variable override [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567724) in GitLab 18.9.

{{< /history >}}

## Data tracking for product usage at event level

For more information about changes to product usage data collection, read the blog post
[More granular product usage insights for GitLab Self-Managed and Dedicated](https://about.gitlab.com/blog/more-granular-product-usage-insights-for-gitlab-self-managed-and-dedicated/).

### Event data

Event data tracks interactions (or actions) within the GitLab platform.
These interactions or actions could be user initiated such as initiating CI/CD pipelines, merging a merge request, triggering a webhook, or creating an issue.
Actions can also result from background system processing like scheduled pipeline succeeding.
The focus of event data collection is on the users' actions and the metadata associated with those actions.

User IDs are pseudonymized to protect privacy, and GitLab does not undertake any processes to re-identify or associate the metrics with individual users.
Event data does not include source code or other customer-created content stored within GitLab.

For more information, see also:

- [Metrics dictionary](https://metrics.gitlab.com/?status=active) for a list of events and metrics
- [Customer product usage information](https://handbook.gitlab.com/handbook/legal/privacy/customer-product-usage-information/)

### Benefits of event data

Event-level data enhances several benefits of Service Ping by offering more granular insights without identifying users.

- Proactive support: Granular data allows our Customer Success Managers (CSMs) and support teams to access more detailed information, enabling them to drill down and create custom metrics tailored to your organization's unique needs, rather than relying on more generic, aggregated metrics.
- Targeted guidance: Event-level data provides a deeper understanding of how features are used, helping us uncover opportunities for optimization and improvement. The depth of data allows us to offer more precise, actionable recommendations to help you maximize the value of GitLab and enhance your workflows.
- Anonymized benchmarking reports: Granular event data enables more accurate and relevant performance comparisons with similar organizations by focusing on detailed usage patterns, rather than just high-level aggregated data.

### Enable or disable event-level data collection

> [!note]
> If Snowplow tracking is enabled, it will be automatically disabled when you enable product usage tracking. Only one data collection method can be active at a time.

To enable or disable event-level data collection:

1. Sign in as a user with administrator access.
1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Metrics and Profiling**.
1. Expand **Event tracking**.
1. To enable the setting, select the checkbox **Enable event tracking**. To disable the setting, clear the checkbox.
1. Select **Save changes**.

### Programmatically configure event-level data collection

You can configure event-level data collection programmatically using either:

- **Initial defaults**: Apply only during first-time installation
- **Environment variable override**: Apply at runtime and take precedence over database settings

#### Initial defaults (installation only)

These settings only apply during the initial installation of GitLab. Changing these settings after installation has no effect.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Set `gitlab_rails['initial_gitlab_product_usage_data']` to `false` in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['initial_gitlab_product_usage_data'] = false
```

Then reconfigure GitLab:

```shell
sudo gitlab-ctl reconfigure
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Set `global.appConfig.initialDefaults.gitlabProductUsageData` to `false` in your values file:

```yaml
global:
  appConfig:
    initialDefaults:
      gitlabProductUsageData: false
```

Or via command line:

```shell
helm install gitlab gitlab/gitlab \
  --set global.appConfig.initialDefaults.gitlabProductUsageData=false
```

{{< /tab >}}

{{< /tabs >}}

#### Environment variable override (runtime)

> [!note]
> Introduced in GitLab 18.9.

The `GITLAB_PRODUCT_USAGE_DATA_ENABLED` environment variable allows you to control event-level data collection at runtime. When set, this environment variable:

- Takes precedence over the database setting
- Cannot be changed through the Admin UI (the toggle is disabled)
- Applies immediately without requiring a database migration

This is useful for:

- Air-gapped environments requiring automated configuration
- Deployments that need consistent settings across upgrades
- Automated deployment workflows where UI access is not practical

Valid values are `true` or `false`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Set the environment variable in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['env']['GITLAB_PRODUCT_USAGE_DATA_ENABLED'] = 'false'
```

Then reconfigure GitLab:

```shell
sudo gitlab-ctl reconfigure
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Set the environment variable using `extraEnv` in your values file:

```yaml
gitlab:
  sidekiq:
    extraEnv:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
  webservice:
    extraEnv:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
```

Or via command line:

```shell
helm upgrade gitlab gitlab/gitlab \
  --set gitlab.sidekiq.extraEnv.GITLAB_PRODUCT_USAGE_DATA_ENABLED='false' \
  --set gitlab.webservice.extraEnv.GITLAB_PRODUCT_USAGE_DATA_ENABLED='false'
```

{{< /tab >}}

{{< tab title="Docker" >}}

Pass the environment variable when starting the container:

```shell
docker run --env GITLAB_PRODUCT_USAGE_DATA_ENABLED=false gitlab/gitlab-ee:latest
```

Or in a Docker Compose file:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ee:latest
    environment:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Set the environment variable before starting GitLab:

```shell
export GITLAB_PRODUCT_USAGE_DATA_ENABLED=false
```

Or add it to your systemd service file or init script.

{{< /tab >}}

{{< /tabs >}}

#### Check the current setting source

When the environment variable override is active, the Admin UI displays a warning banner indicating that the setting is controlled by an environment variable and cannot be changed through the UI.

You can also check the setting source through the API:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings" | jq '.gitlab_product_usage_data_enabled, .gitlab_product_usage_data_source'
```

The `gitlab_product_usage_data_source` field returns either:

- `environment`: The setting is controlled by the `GITLAB_PRODUCT_USAGE_DATA_ENABLED` environment variable
- `database`: The setting is controlled by the database (can be changed via Admin UI)

### Event delivery timing

Events are transmitted to GitLab almost immediately after they occur. The system collects events in small batches, sending data once 10 events have been gathered. This approach provides near real-time delivery while maintaining efficient network usage.

### Payload size and compression

Each event is approximately 10 kB in JSON format. Batches of 10 events result in an uncompressed payload size of about 100 kB. Before transmission, the payload is compressed to minimize data transfer size and optimize performance.

### Event data logs

Event-level tracking data is logged in the `product_usage_data.log` file. This log contains JSON-formatted entries of tracked product usage events, including payload information and context data. Each line represents a separate tracking event and all the data that was sent.

The log file is located at:

- `/var/log/gitlab/gitlab-rails/product_usage_data.log` on Linux package installations
- `/home/git/gitlab/log/product_usage_data.log` on self-compiled installations

While these logs provide thorough visibility into data transmission, they're designed specifically for inspection by security teams rather than feature usage analysis. For more detailed information about logging system, see the [Log system documentation](../logs/_index.md#product-usage-data-log).
