---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Scheduled pipeline execution policies
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14147) as an experiment in GitLab 18.0 with a flag named `scheduled_pipeline_execution_policy_type` defined in the `policy.yml` file.

{{< /history >}}

Pipeline execution policies enforce custom CI/CD jobs in your projects' pipelines. With scheduled pipeline execution policies, you can extend this enforcement to run the CI/CD job on a regular cadence (daily, weekly, or monthly), ensuring that compliance scripts, security scans, or other custom CI/CD job are executed even when there are no new commits.

## Scheduling your pipeline execution policies

Unlike regular pipeline execution policies that inject or override jobs in existing pipelines, scheduled policies create new pipelines that run independently on the schedule you define.
Scheduled pipelines are separate from your project's `.gitlab-ci.yml` and do not execute any of the project's CI/CD jobs.

Common use cases include:

- Enforce security scans on a regular cadence to meet compliance requirements.
- Check project configurations periodically.
- Run dependency scans on inactive repositories to detect newly discovered vulnerabilities.
- Execute compliance reporting scripts on a schedule.

## Enable scheduled pipeline execution policies

Scheduled pipeline execution policies are available as an experimental feature. To enable this feature in your environment, enable the `pipeline_execution_schedule_policy` experiment in the security policy configuration. The `.gitlab/security-policies/policy.yml` YAML configuration file is stored in your Security Policy Project:

```yaml
experiments:
  pipeline_execution_schedule_policy:
    enabled: true
```

> [!note]
> This feature is experimental and may change in future releases. You should test it thoroughly in a non-production environment only. You should not use this feature in production environments as it may be unstable.

## Configure schedule pipeline execution policies

To configure a scheduled pipeline execution policy, add additional configuration fields to the `pipeline_execution_schedule_policy` section of your security policy project's `.gitlab/security-policies/policy.yml` file:

```yaml
pipeline_execution_schedule_policy:
- name: Scheduled Pipeline Execution Policy
  description: ''
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: daily
    start_time: '10:00'
    time_window:
      value: 600
      distribution: random
```

### Schedule configuration schema

The `schedules` section allows you to configure when security policy jobs run automatically. You can create daily, weekly, or monthly schedules with specific execution times and distribution windows.

### Schedules configuration options

The `schedules` section supports the following options:

| Parameter | Description |
|-----------|-------------|
| `type` | Schedule type: `daily`, `weekly`, or `monthly` |
| `start_time` | Time to start the schedule in 24-hour format (HH:MM) |
| `time_window` | Time window in which to distribute the pipeline executions |
| `time_window.value` | Duration in seconds (minimum: 600, maximum: 2629746) |
| `time_window.distribution` | Distribution method (currently, only `random` is supported) |
| `timezone` | IANA timezone identifier (defaults to UTC if not specified) |
| `branches` | Optional array with names of the branches to schedule pipelines on. If `branches` is specified, pipelines run only on the specified branches and only if they exist in the project. If not specified, pipelines run only on the default branch. You can provide a maximum of five unique branch names per schedule. |
| `days` | Use with weekly schedules only: Array of days when the schedule runs (for example, `["Monday", "Friday"]`) |
| `days_of_month` | Use with monthly schedules only: Array of dates when the schedule runs (for example, `[1, 15]`, can include values from 1 to 31) |
| `snooze` | Optional configuration to temporarily pause the schedule |
| `snooze.until` | ISO8601 date and time when the schedule resumes after the snooze (format: `2025-06-13T20:20:00+00:00`) |
| `snooze.reason` | Optional documentation explaining why the schedule is snoozed |

### Schedule examples

Use daily, weekly, or monthly schedules.

#### Daily schedule example

```yaml
schedules:
  - type: daily
    start_time: "01:00"
    time_window:
      value: 3600  # 1 hour window
      distribution: random
    timezone: "America/New_York"
    branches:
      - main
      - develop
      - staging
```

#### Weekly schedule example

```yaml
schedules:
  - type: weekly
    days:
      - Monday
      - Wednesday
      - Friday
    start_time: "04:30"
    time_window:
      value: 7200  # 2 hour window
      distribution: random
    timezone: "Europe/Berlin"
```

#### Monthly schedule example

```yaml
schedules:
  - type: monthly
    days_of_month:
      - 1
      - 15
    start_time: "02:15"
    time_window:
      value: 14400  # 4 hour window
      distribution: random
    timezone: "Asia/Tokyo"
```

### Time window distribution

To prevent overwhelming your CI/CD infrastructure when applying policies to multiple projects, scheduled pipeline execution policies distribute the creation of the pipelines across a time window with some common rules:

- All pipelines are scheduled at `random`. Pipelines are randomly distributed during the specified time window.
- The minimum time window is 10 minutes (600 seconds), and the maximum is approximately 1 month (2,629,746 seconds).
- For monthly schedules, if you specify dates that don't exist in certain months (like 31 for February), those runs are skipped.
- A security policy project can contain up to five scheduled pipeline execution policies.
- A scheduled policy can only have one schedule configuration at a time.
- When you apply a policy to multiple projects, ensure your time window is large enough to accommodate the number of projects, based on your available runner capacity. For example, a policy applied to 1000 projects with a one hour time window distributes pipeline creation evenly throughout that hour (approximately 16 pipelines per minute). Verify that your runners can handle this pipeline creation rate or choose a larger time window to avoid queuing or delays.
- For monthly schedules, the interval between consecutive runs may vary due to random distribution during the time window. For example, a monthly schedule might run 20 days after the previous run, then 30 days later. This distribution is the expected behavior because it helps distribute load across your infrastructure.

## Snooze scheduled pipeline execution policies

You can temporarily pause scheduled pipeline execution policies using the snooze feature. Use the snooze feature during maintenance windows, holidays, or when you need to prevent scheduled pipelines from running for a specific time period.

### How snoozing works

When you snooze a scheduled pipeline execution policy:

- No new scheduled pipelines are created during the snooze period.
- Pipelines that were created before the snooze continue to execute.
- The policy remains enabled but in a snoozed state.
- After the snooze period expires, scheduled pipeline execution resumes automatically.

### Configuring snooze

To snooze a scheduled pipeline execution policy, add a `snooze` section to the schedule configuration:

```yaml
pipeline_execution_schedule_policy:
- name: Weekly Security Scan
  description: 'Run security scans every week'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    timezone: UTC
    days:
      - Monday
    snooze:
      until: "2025-06-26T16:27:00+00:00"  # ISO8601 format
      reason: "Critical production deployment"
```

The `snooze.until` parameter specifies when the snooze period ends using the ISO8601 format: `YYYY-MM-DDThh:mm:ss+00:00` where:

- `YYYY-MM-DD`: Year, month, and day
- `T`: Separator between date and time
- `hh:mm:ss`: Hours, minutes, and seconds in 24-hour format
- `+00:00`: Time zone offset from UTC (or Z for UTC)

For example, `2025-06-26T16:27:00+00:00` represents June 26, 2025, at 4:27 PM UTC.

### Removing a snooze

To remove a snooze before its expiration time, remove the `snooze` section from the policy configuration or set a date in the past for the `until` value.

## Schedule pipelines for specific branches

By default, schedules run on the default branch only. Scheduled pipeline execution policies support branch filtering, which allows you to schedule pipelines for additional branches. Use the `branches` property to perform regular scans or checks on other important branches in your project.

When you configure the `branches` property in your schedule:

- If you don't specify any branches, the scheduled pipeline runs only on the default branch.
- If you specify branches, the policy schedules pipelines for each specified branch that actually exists in the project.
- You can specify a maximum of five unique branch names per schedule.
- You must specify each branch name in full. Wildcard matching is not supported.

### Branch filtering example

```yaml
pipeline_execution_schedule_policy:
- name: Scan Multiple Branches
  description: 'Run security scans on main, staging and develop branches'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    days:
      - Monday
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    branches:
      - main
      - staging
      - develop
      - feature/new-authentication
```

In this example, if all of the specified branches exist in the project, the policy creates four separate pipelines (one for each branch).

## Prerequisites

To use scheduled pipeline execution policies, your project must meet the following requirements:

- Your CI/CD configuration file is stored in one of the following locations:
  - Your security policy project
  - A public project
  - A private project with access enabled (see [Enable access to CI/CD configuration files](#enable-access-to-cicd-configuration-files))
- Your CI/CD configuration file must include appropriate workflow rules for scheduled pipelines.

## Enable access to CI/CD configuration files

When your policy references CI/CD configuration files, the Security Policy Bot must have access to them.
Files in public projects are accessible by default.
For files in your security policy project or other private projects, enable access using one of the following options.

### Option 1: Grant access to files in the security policy project

If your CI/CD configuration files are stored in the security policy project itself, use this option.
This setting applies to any user who triggers a pipeline with pipeline execution policies injected.

1. In your security policy project, in the left sidebar, select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on **Grant security policy project access to CI/CD configuration**.
1. Select **Save changes**.

### Option 2: Allow Security Policy Bot access to private projects

If your policy `include:` value references a CI/CD configuration file stored in a private project
other than the security policy project, use this option.
This setting applies only to Security Policy Bot users and can be enabled on any project.

1. Enable the `pipeline_execution_policy_bot_access` experiment in your security policy project.
   In the `.gitlab/security-policies/policy.yml` file, add the following lines:

   ```yaml
   experiments:
     pipeline_execution_policy_bot_access:
       enabled: true
   ```

   > [!note]
   > Your private project or one of its parent groups must be linked to this security policy project.
   > If it is not already linked, you must [link the security policy project](enforcement/security_policy_projects.md#link-to-a-security-policy-project).

1. In the private project that stores CI/CD files, in the left sidebar, select **Settings** >
   **General**.
1. Expand **Visibility, project features, permissions**.
1. In **Security policy bot access**, select
   **Allow security policy bots to access CI/CD configuration files in this project**.
1. In **Allowed file patterns**, add one or more glob patterns to specify the files that bots can access, separated by commas.
1. Select **Save changes**.

The glob patterns for the allowed files must match the paths specified in the `include:file:` value. For example:

- For `include:file: ci/security-scan.yml`, use `ci/**/*.yml` or `ci/security-scan.yml`.
- For `include:file: policy-ci.yml`, use `*.yml` or `policy-ci.yml`.
- For multiple directories, use multiple patterns, separated by commas, like `ci/**/*.yml, templates/**/*.yml`.

## Security Policy Bot User

Scheduled pipelines are executed by the Security Policy Bot User, a dedicated system account that GitLab automatically creates for each project the security policy applies to.
To ensure that policy execution remains isolated and secure, the bot user has the following security restrictions:

- The bot user is a member of that specific project only. It cannot be added to groups or other projects.
- The bot user can access files in the security policy project and public projects.
- The bot user can access files in private projects only if those projects explicitly enable
  **Security policy bot access** and the file path matches the pattern specified in the project.

Because the bot user is not a member of other projects, it cannot complete any of the following actions:

- Access CI/CD configuration files from private projects that do not allow bot access or do not
  match allowed file patterns.
- Start multi-project child pipelines that target private projects.
- Access artifacts or resources from private projects.

> [!important]
> When you include files from a private project, enable **Security policy bot access** in that
> private project and set matching file patterns. Without these settings, pipeline execution fails
> with an access error.

## Scheduling limits

This feature is experimental and may change in future releases. Also, be aware of the following limits when creating scheduled pipeline execution policies:

- The maximum number of scheduled pipeline execution policies per security policy project is limited to one policy with one schedule.
- The maximum frequency for schedules is once per day (daily).
- If no branches are specified, scheduled pipeline execution policies run only on the default branch.
- You can specify up to five unique branch names in the `branches` array.
- Time windows must be at least 10 minutes (600 seconds) to ensure sufficient distribution of pipelines.
- Scheduled pipelines can be delayed if there are insufficient runners available.

## Troubleshooting

If your scheduled pipelines are not running as expected, follow these troubleshooting steps:

1. **Verify experimental flag**: Ensure that the `pipeline_execution_schedule_policy: enabled: true` flag is set in the `experiments` section of your `policy.yml` file.
1. **Check policy access**: Verify that:
   - The CI/CD configuration file is in the security policy project, in a public project, or in a
     private project with bot access enabled and matching file patterns.
   - The **Pipeline execution policies** setting is enabled in the security policy project (**Settings** > **General** > **Visibility, project features, permissions**).
1. **Validate CI configuration**:
   - Check that the CI/CD configuration file exists at the specified path.
   - Verify the configuration is valid by running a manual pipeline.
   - Ensure the configuration includes appropriate workflow rules for scheduled pipelines.
1. **Verify policy configuration**:
   - Ensure the policy is enabled (`enabled: true`).
   - Verify that the schedule configuration has the correct format and valid values.
   - If you've specified branches, verify that the branches exist in the project.
   - Verify that the time zone setting is correct (if specified).
1. **Review logs and activity**:
   - Check the security policy project's CI/CD pipeline logs for any errors.
1. **Check runner availability**:
   - Ensure that runners are available and configured properly.
   - Verify that runners have the capacity to handle the scheduled jobs.
