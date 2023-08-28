---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Service Ping

## Service Ping Payload drop

### Symptoms

You will be alerted by the [Data team](https://about.gitlab.com/handbook/business-technology/data-team/) and their [Monte Carlo alerting](https://about.gitlab.com/handbook/business-technology/data-team/platform/monte-carlo/).

### Locating the problem

First you need to identify at which stage in Service Ping data pipeline the drop is occurring.

Start at [Service Ping Health Dashboard](https://app.periscopedata.com/app/gitlab/968489) on Sisense.

You can use [this query](https://gitlab.com/gitlab-org/gitlab/-/issues/347298#note_836685350) as an example, to start detecting when the drop started.

### Troubleshoot the GitLab application layer

We conducted an investigation into an unexpected drop in Service ping Payload events volume.
GitLab team members can view more information in this confidential issue:
`https://gitlab.com/gitlab-data/analytics/-/issues/11071`

### Troubleshoot VersionApp layer

Check if the [export jobs](https://gitlab.com/gitlab-org/gitlab-services/version.gitlab.com/-/tree/main/#data-export-using-pipeline-schedules) are successful.

Check [Service Ping errors](https://app.periscopedata.com/app/gitlab/968489?widget=14609989&udv=0) in the [Service Ping Health Dashboard](https://app.periscopedata.com/app/gitlab/968489).

### Troubleshoot Google Storage layer

Check if the files are present in [Google Storage](https://console.cloud.google.com/storage/browser/cloudsql-gs-production-efd5e8-cloudsql-exports;tab=objects?project=gs-production-efd5e8&prefix=&forceOnObjectsSortingFiltering=false).

### Troubleshoot the data warehouse layer

Reach out to the [Data team](https://about.gitlab.com/handbook/business-technology/data-team/) to ask about current state of data warehouse. On their handbook page there is a [section with contact details](https://about.gitlab.com/handbook/business-technology/data-team/#how-to-connect-with-us).

### Cannot disable Service Ping with the configuration file

The method to disable Service Ping with the GitLab configuration file does not work in
GitLab versions 9.3.0 to 13.12.3. To disable it, you must use the Admin Area in
the GitLab UI instead. For more information, see
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/333269).

GitLab functionality and application settings cannot override or circumvent
restrictions at the network layer. If Service Ping is blocked by your firewall,
you are not impacted by this bug.

#### Check if you are affected

You can check if you were affected by this bug by using the Admin Area or by
checking the configuration file of your GitLab instance:

- Using the Admin Area:

  1. On the left sidebar, select **Search or go to**.
  1. Select **Admin Area**.
  1. On the left sidebar, select **Settings > Metrics and profiling**.
  1. Expand **Usage statistics**.
  1. Are you able to check or uncheck the checkbox to disable Service Ping?

     - If _yes_, your GitLab instance is not affected by this bug.
     - If you can't check or uncheck the checkbox, you are affected by this bug.
       See the steps on [how to fix this](#how-to-fix-the-cannot-disable-service-ping-bug).

- Checking your GitLab instance configuration file:

  To check whether you're impacted by this bug, check your instance configuration
  settings. The configuration file in which Service Ping can be disabled depends
  on your installation and deployment method, but is typically one of the following:

  - `/etc/gitlab/gitlab.rb` for Linux package installations and Docker.
  - `charts.yaml` for GitLab Helm and cloud-native Kubernetes deployments.
  - `gitlab.yml` for self-compiled installations.

  To check the relevant configuration file for strings that indicate whether
  Service Ping is disabled, you can use `grep`:

  ```shell
  # Linux package
  grep "usage_ping_enabled'\] = false" /etc/gitlab/gitlab.rb

  # Kubernetes charts
  grep "enableUsagePing: false" values.yaml

  # From source
  grep "usage_ping_enabled'\] = false" gitlab/config.yml
  ```

  If you see any output after running the relevant command, your GitLab instance
  may be affected by the bug. Otherwise, your instance is not affected.

#### How to fix the "Cannot disable Service Ping" bug

To work around this bug, you have two options:

- [Update](../../../update/index.md) to GitLab 13.12.4 or newer to fix this bug.
- If you can't update to GitLab 13.12.4 or newer, enable Service Ping in the
  configuration file, then disable Service Ping in the UI. For example, if you're
  using the Linux package:

  1. Edit `/etc/gitlab/gitlab.rb`:

     ```ruby
     gitlab_rails['usage_ping_enabled'] = true
     ```

  1. Reconfigure GitLab:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. On the left sidebar, select **Search or go to**.
  1. Select **Admin Area**.
  1. On the left sidebar, select **Settings > Metrics and profiling**.
  1. Expand **Usage statistics**.
  1. Clear the **Enable Service Ping** checkbox.
  1. Select **Save Changes**.

## Generate Service Ping

### Generate or get the cached Service Ping in rails console

Use the following method in the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

```ruby
Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values, cached: true)
```

### Generate a fresh new Service Ping

Use the following method in the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

This also refreshes the cached Service Ping displayed in the Admin Area.

```ruby
Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values)
```

### Generate and print

Generates Service Ping data in JSON format.

```shell
gitlab-rake gitlab:usage_data:generate
```

Generates Service Ping data in YAML format:

```shell
gitlab-rake gitlab:usage_data:dump_sql_in_yaml
```

### Generate and send Service Ping

Prints the metrics saved in `conversational_development_index_metrics`.

```shell
gitlab-rake gitlab:usage_data:generate_and_send
```
