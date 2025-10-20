---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Scan execution policies
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Support for custom CI/CD variables in the scan execution policies editor [introduced](https://gitlab.com/groups/gitlab-org/-/epics/9566) in GitLab 16.2.
- Enforcement of scan execution policies on projects with an existing GitLab CI/CD configuration [introduced](https://gitlab.com/groups/gitlab-org/-/epics/6880) in GitLab 16.2 [with a flag](../../../administration/feature_flags/_index.md) named `scan_execution_policy_pipelines`. Feature flag `scan_execution_policy_pipelines` removed in GitLab 16.5.
- Overriding predefined variables in scan execution policies [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440855) in GitLab 16.10 [with a flag](../../../administration/feature_flags/_index.md) named `allow_restricted_variables_at_policy_level`. Enabled by default. Feature flag `allow_restricted_variables_at_policy_level` removed in GitLab 17.5.

{{< /history >}}

Scan execution policies enforce GitLab security scans based on the default or latest [security CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs). You can deploy scan execution policies as part of the pipeline or on a
specified schedule.

Scan execution policies are enforced across all projects that are linked to the security policy project and are in the scope of the policy. For projects without a
`.gitlab-ci.yml` file, or where AutoDevOps is disabled, security policies create the
`.gitlab-ci.yml` file implicitly. The `.gitlab-ci.yml` file ensures policies that run secret detection,
static analysis, or other scanners that do not require a build in the project can always
run and be enforced.

Both scan execution policies and pipeline execution policies can configure GitLab security scans across multiple projects to manage security and compliance. Scan execution policies are faster to configure, but are not customizable.
If any of the following cases are true, use [pipeline execution policies](pipeline_execution_policies.md) instead:

- You require advanced configuration settings.
- You want to enforce custom CI/CD jobs or scripts.
- You want to enable third-party security scans through an enforced CI/CD job.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For a video walkthrough, see [How to set up Security Scan Policies in GitLab](https://youtu.be/ZBcqGmEwORA?si=aeT4EXtmHjosgjBY).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Learn more about [enforcing scan execution policies on projects with no GitLab CI/CD configuration](https://www.youtube.com/watch?v=sUfwQQ4-qHs).

## Restrictions

- You can assign a maximum of five rules to each policy.
- You can assign a maximum of five scan execution policies to each security policy project.
- Local project YAML files cannot override scan execution policies. These policies take precedence over any configurations defined for a pipeline, even if you use the same job name in your project's CI/CD configuration.
- Scheduled policies (`type: schedule`) execute according to their scheduled  `cadence` only. Updating a policy does not trigger an immediate scan.
- Policy updates that you make directly to the YAML configuration files (with a commit or push instead of in the policy editor) may take up to 10 minutes to propagate through the system. (See [issue 512615](https://gitlab.com/gitlab-org/gitlab/-/issues/512615) for proposed changes to this limitation.)

## Jobs

Policy jobs for scans, other than DAST scans, are created in the `test` stage of the pipeline. If
you remove the `test` stage from the default pipeline, jobs run in the `scan-policies` stage
instead. This stage is injected into the CI/CD pipeline at evaluation time if it doesn't exist. If
the `build` stage exists, `scan-policies` is injected just after the `build` stage, otherwise it is injected at
the beginning of the pipeline. DAST scans always run in the `dast` stage. If the `dast` stage does not
exist, then a `dast` stage is injected at the end of the pipeline.

To avoid job name conflicts, a hyphen and a number are appended to the job name. Each number is a unique
value for each policy action. For example, `secret-detection` becomes `secret-detection-1`.

## Scan execution policy editor

{{< history >}}

- `Merge Request Security Template` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) in GitLab 18.2 [with a flag](../../../administration/feature_flags/_index.md) named `flexible_scan_execution`. Disabled by default.
- `Merge Request Security Template` [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) in GitLab 18.3.

{{< /history >}}

Use the scan execution policy editor to create or edit a scan execution policy.

Prerequisites:

- By default, only group, subgroup, or project Owners have the [permissions](../../permissions.md#application-security)
  required to create or assign a security policy project. Alternatively, you can create a custom role with the permission to [manage security policy links](../../custom_roles/abilities.md#security-policy-management).

When you create your first scan execution policies, we provide you with templates to get started quickly with some of the most common use cases:

- Merge Request Security Template

  - Use case: You want security scans to run only when merge requests are created, not on every commit.
  - When to use: For projects using merge request pipelines that need security scans to run on
    source branches targeting default or protected branches.
  - Best for: Teams that want to align with merge request approval policies and reduce infrastructure
    costs by avoiding scans on every branch.
  - Pipeline sources: Primarily merge request pipelines.

- Scheduled Scanning Template

  - Use case: You want security scans to run automatically on a schedule (like daily or weekly) regardless of code changes.
  - When to use: For security scanning on a regular cadence, independent of development activity.
  - Best for: Compliance requirements, baseline security monitoring, or projects with infrequent commits.
  - Pipeline sources: Scheduled pipelines.

- Merge Release Security Template

  - Use case: You want security scans to run on all changes to your `main` or release branches.
  - When to use: For projects that need comprehensive scanning before releases, or on protected branches.
  - Best for: Release-gated workflows, production deployments, or high-security environments.
  - Pipeline sources: Push pipelines to protected branches, release pipelines.

If the available template do not meet your needs, or you require more customized scan execution policies, you can:

- Select the **Custom** option and create your own scan execution policy with custom requirements.
- Access more customizable options for security scan and CI enforcement using [pipeline execution policies](pipeline_execution_policies.md).

Once your policy is complete, save it by selecting **Configure with a merge request**
at the bottom of the editor. You are redirected to the merge request on the project's
configured security policy project. If one does not link to your project, a security
policy project is automatically created. You can remove existing policies from the
editor interface by selecting **Delete policy**
at the bottom of the editor. This action creates a merge request to remove the policy from your `policy.yml` file.

Most policy changes take effect as soon as the merge request is merged. Any changes
committed directly to the default branch instead of a merge request require up to 10 minutes
before the policy changes take effect.

![Scan Execution Policy Editor Rule Mode](img/scan_execution_policy_rule_mode_v17_5.png)

{{< alert type="note" >}}

For DAST execution policies, the way you apply site and scanner profiles in the rule mode editor depends on
where the policy is defined:

- For policies in projects, in the rule mode editor, choose from a list of profiles that are already defined in the project.
- For policies in groups, you must type in the names of the profiles to use. To prevent pipeline errors, profiles with
matching names must exist in all of the group's projects.

{{< /alert >}}

## Scan execution policies schema

A YAML configuration with scan execution policies consists of an array of objects matching the scan execution
policy schema. Objects are nested under the `scan_execution_policy` key. You can configure a maximum of five
policies under the `scan_execution_policy` key. Any other policies configured after
the first five are not applied.

When you save a new policy, GitLab validates the policy's contents against [this JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json).
If you're not familiar with [JSON schemas](https://json-schema.org/),
the following sections and tables provide an alternative.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `scan_execution_policy` | `array` of scan execution policy | true |  | List of scan execution policies (maximum 5) |

## Scan execution policy schema

{{< history >}}

- Limit of actions per policy [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/472213) in GitLab 17.4 [with flags](../../../administration/feature_flags/_index.md) named `scan_execution_policy_action_limit` (for projects) and `scan_execution_policy_action_limit_group` (for groups). Disabled by default.
- Limit of actions per policy [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/535605) in GitLab 18.0. Feature flags `scan_execution_policy_action_limit` (for projects) and `scan_execution_policy_action_limit_group` (for groups) removed.

{{< /history >}}

{{< alert type="flag" >}}

This feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

| Field          | Type                                         | Required | Description |
|----------------|----------------------------------------------|----------|-------------|
| `name`         | `string`                                     | true     | Name of the policy. Maximum of 255 characters. |
| `description`  | `string`                                     | false    | Description of the policy. |
| `enabled`      | `boolean`                                    | true     | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules`        | `array` of rules                             | true     | List of rules that the policy applies. |
| `actions`      | `array` of actions                           | true     | List of actions that the policy enforces. Limited to a maximum of 10 in GitLab 18.0 and later. |
| `policy_scope` | `object` of [`policy_scope`](_index.md#configure-the-policy-scope) | false    | Defines the scope of the policy based on the projects, groups, or compliance framework labels you specify. |
| `skip_ci` | `object` of [`skip_ci`](#skip_ci-type) | false | Defines whether users can apply the `skip-ci` directive. |

### `skip_ci` type

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/482952) in GitLab 17.9.

{{< /history >}}

Scan execution policies offer control over who can use the `[skip ci]` directive. You can specify certain users or service accounts that are allowed to use `[skip ci]` while still ensuring critical security and compliance checks are performed.

Use the `skip_ci` keyword to specify whether users are allowed to apply the `skip_ci` directive to skip the pipelines.
When the keyword is not specified, the `skip_ci` directive is ignored, preventing all users
from bypassing the pipeline execution policies.

| Field                   | Type     | Possible values          | Description |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`, `false` | Flag to allow (`true`) or prevent (`false`) the use of the `skip-ci` directive for pipelines with enforced pipeline execution policies. |
| `allowlist`             | `object` | `users` | Specify users who are always allowed to use `skip-ci` directive, regardless of the `allowed` flag. Use `users:` followed by an array of objects with `id` keys representing user IDs. |

{{< alert type="note" >}}

Scan execution policies that have the rule type `schedule` always ignore the `skip_ci` option. Scheduled scans run at their configured times regardless of whether `[skip ci]` (or any of its variations) appear in the last commit message. This ensures that security scans occur on a predictable schedule even when CI/CD pipelines are otherwise skipped.

{{< /alert >}}

## `pipeline` rule type

{{< history >}}

- The `branch_type` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404774) in GitLab 16.1 [with a flag](../../../administration/feature_flags/_index.md) named `security_policies_branch_type`. Generally available in GitLab 16.2. Feature flag removed.
- The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags/_index.md) named `security_policies_branch_exceptions`. Generally available in GitLab 16.5. Feature flag removed.
- The `pipeline_sources` field and the `branch_type` options `target_default` and `target_protected` were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) in GitLab 18.2 [with a flag](../../../administration/feature_flags/_index.md) named `flexible_scan_execution`.
- The `pipeline_sources` field and the `branch_type` options `target_default` and `target_protected` were [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) in GitLab 18.3.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

This rule enforces the defined actions whenever the pipeline runs for a selected branch.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `pipeline` | The rule's type. |
| `branches` <sup>1</sup> | `array` of `string` | true if `branch_type` field does not exist | `*` or the branch's name | The branch the given policy applies to (supports wildcard). For compatibility with merge request approval policies, you should target all branches to include the scans in the feature branch and default branch |
| `branch_type` <sup>1</sup> | `string` | true if `branches` field does not exist | `default`, `protected`, `all`, `target_default` <sup>2</sup>, or `target_protected` <sup>2</sup> | The types of branches the given policy applies to. |
| `branch_exceptions` | `array` of `string` | false |  Names of branches | Branches to exclude from this rule. |
| `pipeline_sources` <sup>2</sup> | `array` of `string` | false | `api`, `chat`, `external`, `external_pull_request_event`, `merge_request_event` <sup>3</sup>, `pipeline`, `push` <sup>3</sup>, `schedule`, `trigger`, `unknown`, `web` | The pipeline source that determines when the scan execution job triggers. See the [documentation](../../../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable) for more information. |

1. You must specify either `branches` or `branch_type`, but not both.
1. Some options are only available with the `flexible_scan_execution` feature flag enabled. See the history for details.
1. When the `branch_type` options `target_default` or `target_protected` are specified, the `pipeline_sources` field supports only the `merge_request_event` and `push` fields.

## `schedule` rule type

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404774) the `branch_type` field in GitLab 16.1 [with a flag](../../../administration/feature_flags/_index.md) named `security_policies_branch_type`. Generally available in GitLab 16.2. Feature flag removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) the `branch_exceptions` field in GitLab 16.3 [with a flag](../../../administration/feature_flags/_index.md) named `security_policies_branch_exceptions`. Generally available in GitLab 16.5. Feature flag removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147691) a new `scan_execution_pipeline_worker` worker to scheduled scans to create pipelines in GitLab 16.11 [with a flag](../../../administration/feature_flags/_index.md).
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152855) a new application setting `security_policy_scheduled_scans_max_concurrency` in GitLab 17.1. The concurrency limit applies when both the `scan_execution_pipeline_worker` and `scan_execution_pipeline_concurrency_control` are enabled.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158636) a concurrency limit for scan execution scheduled jobs in GitLab 17.3 [with a flag](../../../administration/feature_flags/_index.md) named  `scan_execution_pipeline_concurrency_control`.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/451890) the `scan_execution_pipeline_worker` feature flag on GitLab.com in GitLab 17.5.
- [Feature flag](https://gitlab.com/gitlab-org/gitlab/-/issues/451890) `scan_execution_pipeline_worker` removed in GitLab 17.6.
- [Feature flag](https://gitlab.com/gitlab-org/gitlab/-/issues/463802) `scan_execution_pipeline_concurrency_control` removed in GitLab 17.9.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178892) a new application setting `security_policy_scheduled_scans_max_concurrency` in GitLab 17.11

{{< /history >}}

{{< alert type="warning" >}}

In GitLab 16.1 and earlier, you should not use [direct transfer](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer) with scheduled scan execution policies. If you must use direct transfer, first upgrade to GitLab 16.2 and ensure security policy bots are enabled in the projects you are enforcing.

{{< /alert >}}

Use the `schedule` rule type to run security scanners on a schedule.

A scheduled pipeline:

- Runs only the scanners defined in the policy, not the jobs defined in the project's
  `.gitlab-ci.yml` file.
- Runs according to the schedule defined in the `cadence` field.
- Runs under a `security_policy_bot` user account in the project, with the Guest role and
  permissions to create pipelines and read the repository's content from a CI/CD job. This account
  is created when the policy is linked to a group or project.
- On GitLab.com, only the first 10 `schedule` rules in a scan execution policy are enforced. Rules
that exceed the limit have no effect.

| Field      | Type | Required | Possible values | Description |
|------------|------|----------|-----------------|-------------|
| `type`     | `string` | true | `schedule` | The rule's type. |
| `branches` <sup>1</sup> | `array` of `string` | true if either `branch_type` or `agents` fields does not exist | `*` or the branch's name | The branch the given policy applies to (supports wildcard). |
| `branch_type` <sup>1</sup> | `string` | true if either `branches` or `agents` fields does not exist | `default`, `protected` or `all` | The types of branches the given policy applies to. |
| `branch_exceptions` | `array` of `string` | false |  Names of branches | Branches to exclude from this rule. |
| `cadence`  | `string` | true | Cron expression with limited options. For example, `0 0 * * *` creates a schedule to run every day at midnight (12:00 AM). | A whitespace-separated string containing five fields that represents the scheduled time. |
| `timezone` | `string` | false | Time zone identifier (for example, `America/New_York`) | Time zone to apply to the cadence. Value must be an IANA Time Zone Database identifier. |
| `time_window` | `object` | false |  | Distribution and duration settings for scheduled security scans. |
| `agents` <sup>1</sup>   | `object` | true if either `branch_type` or `branches` fields do not exists  |  | The name of the [GitLab agents for Kubernetes](../../clusters/agent/_index.md) where [Operational Container Scanning](../../clusters/agent/vulnerabilities.md) runs. The object key is the name of the Kubernetes agent configured for your project in GitLab. |

1. You must specify only one of `branches`, `branch_type`, or `agents`.

### Cadence

Use the `cadence` field to schedule when you want the policy's actions to run. The `cadence` field
uses [cron syntax](../../../topics/cron/_index.md), but with some restrictions:

- Only the following types of cron syntax are supported:
  - A daily cadence of once per hour around specified time, for example: `0 18 * * *`
  - A weekly cadence of once per week on a specified day and around specified time, for example: `0 13 * * 0`
- Use of the comma (,), hyphens (-), or step operators (/) are not supported for minutes and hours.
  Any scheduled pipeline using these characters is skipped.

Consider the following when choosing a value for the `cadence` field:

- Timing is based on UTC for GitLab.com and GitLab Dedicated, and on the GitLab host's system time for GitLab Self-Managed.
  When testing new policies, pipelines may appear to run at incorrect times because they
  are scheduled in your server's time zone, not your local time zone.
- A scheduled pipeline doesn't start until the required resources become
  available to create it. In other words, the pipeline may not begin precisely at the timing
  specified in the policy.

When using the `schedule` rule type with the `agents` field:

- The GitLab agent for Kubernetes checks every 30 seconds to see if there is an applicable policy.
  When the agent finds a policy, the scans execute according to the defined `cadence`.
- The cron expression is evaluated using the system time of the Kubernetes agent pod.

When using the `schedule` rule type with the `branches` field:

- The cron worker runs on 15 minute intervals and starts any pipelines that were scheduled to run
  during the previous 15 minutes. Therefore, scheduled pipelines may run with an offset of up to 15
  minutes.
- If a policy is enforced on a large number of projects or branches, the policy is processed in
  batches, and may take some time to create all pipelines.

![A diagram showing how scheduled security scans are processed and executed with potential delays.](img/scheduled_scan_execution_policies_diagram_v18_04.png)

### `agent` schema

Use this schema to define `agents` objects in the [`schedule` rule type](#schedule-rule-type).

| Field        | Type                | Required | Description |
|--------------|---------------------|----------|-------------|
| `namespaces` | `array` of `string` | true | The namespace that is scanned. If empty, all namespaces are scanned. |

#### `agent` example

```yaml
- name: Enforce container scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

The keys for a schedule rule are:

- `cadence` (required): a [Cron expression](../../../topics/cron/_index.md) for when the scans are
  run.
- `agents:<agent-name>` (required): The name of the agent to use for scanning.
- `agents:<agent-name>:namespaces` (optional): The Kubernetes namespaces to scan. If omitted, all namespaces are scanned.

### `time_window` schema

Define how scheduled scans are distributed over time with the `time_window` object in the [`schedule` rule type](#schedule-rule-type). You can configure `time_window` only in YAML mode of the policy editor.

| Field          | Type      | Required | Description                                                                                                                                                                          |
|----------------|-----------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `distribution` | `string`  | true     | Distribution pattern for schedule scans. Supports only `random`, where scans are distributed randomly in the interval defined by the `value` key of the `time_window`. |
| `value`        | `integer` | true     | The time window in seconds the schedule scans should run. Enter a value between 3600 (1 hour) and 86400 (24 hours).                                               |

#### `time_window` example

```yaml
- name: Enforce container scanning with a time window of 1 hour
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    time_window:
      value: 3600
      distribution: random
  actions:
  - scan: container_scanning
```

### Optimize scheduled pipelines for projects at scale

When a policy enforces scheduled pipelines across multiple projects and branches, the pipelines run simultaneously. The first execution of a scheduled pipeline in each project creates a security bot user responsible for executing the schedules for that project.

To optimize performance for projects at scale:

- Roll out scheduled scan execution policies gradually, starting with a subset of projects. You can leverage security policy scopes to target specific groups, projects, or projects containing a given compliance framework label.
- You can configure the policy to run the schedules on runners with a specified `tag`. Consider setting up a dedicated runner in each project to handle schedules enforced from a policy to reduce impact to other runners.
- Test your implementation in a staging or lower environment before deploying to production. Monitor performance and adjust your rollout plan based on results.

### Concurrency control

GitLab applies concurrency control when you set the `time_window` property.

The concurrency control distributes the scheduled pipelines according to the [`time_window` settings](#time_window-schema) defined in the policy.

## `scan` action type

{{< history >}}

- Scan Execution Policies variable precedence was [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/424028) in GitLab 16.7 [with a flag](../../../administration/feature_flags/_index.md) named `security_policies_variables_precedence`. Enabled by default. [Feature flag removed in GitLab 16.8](https://gitlab.com/gitlab-org/gitlab/-/issues/435727).
- Selection of security templates for given action (for projects) was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415427) in GitLab 17.1 [with feature flag](../../../administration/feature_flags/_index.md) named `scan_execution_policies_with_latest_templates`. Disabled by default.
- Selection of security templates for given action (for groups) was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468981) in GitLab 17.2 [with feature flag](../../../administration/feature_flags/_index.md) named `scan_execution_policies_with_latest_templates_group`. Disabled by default.
- Selection of security templates for given action (for projects and groups) was enabled on GitLab Self-Managed, and GitLab Dedicated ([1](https://gitlab.com/gitlab-org/gitlab/-/issues/461474), [2](https://gitlab.com/gitlab-org/gitlab/-/issues/468981)) in GitLab 17.2.
- Selection of security templates for given action (for projects and groups) was generally available in GitLab 17.3. Feature flags `scan_execution_policies_with_latest_templates` and `scan_execution_policies_with_latest_templates_group` removed.

{{< /history >}}

This action executes the selected `scan` with additional parameters when conditions for at least one
rule in the defined policy are met.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `scan` | `string` | `sast`, `sast_iac`, `dast`, `secret_detection`, `container_scanning`, `dependency_scanning` | The action's type. |
| `site_profile` | `string` | Name of the selected [DAST site profile](../dast/profiles.md#site-profile). | The DAST site profile to execute the DAST scan. This field should only be set if `scan` type is `dast`. |
| `scanner_profile` | `string` or `null` | Name of the selected [DAST scanner profile](../dast/profiles.md#scanner-profile). | The DAST scanner profile to execute the DAST scan. This field should only be set if `scan` type is `dast`.|
| `variables` | `object` | | A set of CI/CD variables, supplied as an array of `key: value` pairs, to apply and enforce for the selected scan. The `key` is the variable name, with its `value` provided as a string. This parameter supports any variable that the GitLab CI/CD job supports for the specified scan. |
| `tags` | `array` of `string` | | A list of runner tags for the policy. The policy jobs are run by runner with the specified tags. |
| `template` | `string` | `default` or `latest` | CI/CD template version to enforce. The `latest` version may introduce breaking changes and supports only `pipeline_sources` related to merge requests. For details, see [customize security scanning](../../application_security/detect/security_configuration.md#customize-security-scanning). |
| `scan_settings` | `object` | | A set of scan settings, supplied as an array of `key: value` pairs, to apply and enforce for the selected scan. The `key` is the setting name, with its `value` provided as a boolean or string. This parameter supports the settings defined in [scan settings](#scan-settings). |

{{< alert type="note" >}}

If you have merge request pipelines enabled for your project, you must set the `AST_ENABLE_MR_PIPELINES` CI/CD variable to `"true"` in your policy for each enforced scan. For more information on using security scanning tools with merge request pipelines, refer to the [security scanning documentation](../../application_security/detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

{{< /alert >}}

### Scanner behavior

Some scanners behave differently in a `scan` action than they do in a regular CI/CD pipeline scan:

- Static application security testing (SAST): Runs only if the repository contains
  [files supported by SAST](../sast/_index.md#supported-languages-and-frameworks).
- Secret detection:
  - Only rules in the default ruleset are supported by default.
  - To customize a ruleset configuration, either:
    - Modify the default ruleset. Use a scan execution policy to specify the `SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD variable. By default, this points to a [remote configuration file](../secret_detection/pipeline/configure.md#with-a-remote-ruleset) that only overrides or disables rules from the default ruleset. Using only this variable does not support extending or replacing the default set of rules.
    - [Extend](../secret_detection/pipeline/configure.md#extend-the-default-ruleset) or [replace](../secret_detection/pipeline/configure.md#replace-the-default-ruleset) the default ruleset. Use the scan execution policy to specify the `SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD variable and a remote configuration file that uses [a Git passthrough](../secret_detection/pipeline/custom_rulesets_schema.md#passthrough-types) to extend or replace the default ruleset. For a detailed guide, see [How to set up a centrally managed pipeline secret detection configuration](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy).
  - For `scheduled` scan execution policies, secret detection by default runs first in `historic`
    mode (`SECRET_DETECTION_HISTORIC_SCAN` = `true`). All subsequent scheduled scans run in default
    mode with `SECRET_DETECTION_LOG_OPTIONS` set to the commit range between last run and current
    SHA. You can override this behavior by specifying CI/CD variables in the scan
    execution policy. For more information, see
    [Full history pipeline secret detection](../secret_detection/pipeline/_index.md#run-a-historic-scan).
  - For `triggered` scan execution policies, secret detection works just like regular scan
    [configured manually in the `.gitlab-ci.yml`](../secret_detection/pipeline/_index.md#edit-the-gitlab-ciyml-file-manually).
- Container scanning: A scan that is configured for the `pipeline` rule type ignores the agent
  defined in the `agents` object. The `agents` object is only considered for `schedule` rule types.
  An agent with a name provided in the `agents` object must be created and configured for the
  project.

### DAST profiles

The following requirements apply when enforcing Dynamic Application Security Testing (DAST):

- For every project in the policy's scope the specified
  [site profile](../dast/profiles.md#site-profile) and
  [scanner profile](../dast/profiles.md#scanner-profile) must exist. If these are not
  available, the policy is not applied and a job with an error message is created instead.
- When a DAST site profile or scanner profile is named in an enabled scan execution policy, the
  profile cannot be modified or deleted. To edit or delete the profile, you must first set the
  policy to **Disabled** in the policy editor or set `enabled: false` in the YAML mode.
- When configuring policies with a scheduled DAST scan, the author of the commit in the security
  policy project's repository must have access to the scanner and site profiles. Otherwise, the scan
  is not scheduled successfully.

### Scan settings

The following settings are supported by the `scan_settings` parameter:

| Setting | Type | Required | Possible values | Default | Description |
|-------|------|----------|-----------------|-------------|-----------|
| `ignore_default_before_after_script` | `boolean` | false | `true`, `false` | `false` | Specifies whether to exclude any default `before_script` and `after_script` definitions in the pipeline configuration from the scan job. |

## CI/CD variables

{{< alert type="warning" >}}

Don't store sensitive information or credentials in variables because they are stored as part of the plaintext policy configuration
in a Git repository.

{{< /alert >}}

Variables defined in a scan execution policy follow the standard [CI/CD variable precedence](../../../ci/variables/_index.md#cicd-variable-precedence).

Preconfigured values are used for the following CI/CD variables in any project on which a scan
execution policy is enforced. Their values can be overridden, but **only** if they are declared in
a policy. They **cannot** be overridden by group or project CI/CD variables:

```plaintext
DS_EXCLUDED_PATHS: spec, test, tests, tmp
SAST_EXCLUDED_PATHS: spec, test, tests, tmp
SECRET_DETECTION_EXCLUDED_PATHS: ''
SECRET_DETECTION_HISTORIC_SCAN: false
SAST_EXCLUDED_ANALYZERS: ''
DEFAULT_SAST_EXCLUDED_PATHS: spec, test, tests, tmp
DS_EXCLUDED_ANALYZERS: ''
SECURE_ENABLE_LOCAL_CONFIGURATION: true
```

In GitLab 16.9 and earlier:

- If the CI/CD variables suffixed `_EXCLUDED_PATHS` were declared in a policy, their values _could_
  be overridden by group or project CI/CD variables.
- If the CI/CD variables suffixed `_EXCLUDED_ANALYZERS` were declared in a policy, their values were
  ignored, regardless of where they were defined: policy, group, or project.

## Policy scope schema

To customize policy enforcement, you can define a policy's scope to either include, or exclude,
specified projects, groups, or compliance framework labels. For more details, see
[Scope](_index.md#configure-the-policy-scope).

## Policy update propagation

When you update a policy, the changes propagate differently depending on how you update the policy:

- With a merge request on the [security policy project](../_index.md): Changes take effect immediately after the merge request is merged.
- Direct commits to `.gitlab/security-policies/policy.yml`: Changes may take up to 10 minutes to take effect.

### Triggering behavior

Updates to pipeline-based policies (`type: pipeline`) do not trigger immediate pipelines or affect pipelines already in progress. The policy changes apply to future pipeline runs.

You cannot manually trigger the rules in a scheduled policy outside their scheduled cadence.

## Example security policy project

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](enforcement/security_policy_projects.md):

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every release pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST and secret detection scans every 10 minutes
  description: This policy enforces DAST and secret detection scans to run every 10 minutes
  enabled: true
  rules:
  - type: schedule
    branches:
    - main
    cadence: "*/10 * * * *"
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
  - scan: secret_detection
    scan_settings:
      ignore_default_before_after_script: true
- name: Enforce Secret Detection and container scanning in every default branch pipeline
  description: This policy enforces pipeline configuration to have a job with Secret Detection and container scanning scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
    variables:
      SAST_EXCLUDED_ANALYZERS: brakeman
  - scan: container_scanning
```

In this example:

- For every pipeline executed on branches that match the `release/*` wildcard (for example, branch
  `release/v1.2.1`)
  - DAST scans run with `Scanner Profile A` and `Site Profile B`.
- DAST and secret detection scans run every 10 minutes. The DAST scan runs with `Scanner Profile C`
  and `Site Profile D`.
- Secret detection, container scanning, and SAST scans run for every pipeline executed on the `main`
  branch. The SAST scan runs with the `SAST_EXCLUDED_ANALYZER` variable set to `"brakeman"`.

## Example for scan execution policy editor

You can use this example in the YAML mode of the [scan execution policy editor](#scan-execution-policy-editor).
It corresponds to a single object from the previous example.

```yaml
name: Enforce Secret Detection and container scanning in every default branch pipeline
description: This policy enforces pipeline configuration to have a job with Secret Detection and container scanning scans for the default branch
enabled: true
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: secret_detection
  - scan: container_scanning
```

## Avoiding duplicate scans

Scan execution policies can cause the same type of scanner to run more than once if developers include scan jobs in the project's
`.gitlab-ci.yml` file. This behavior is intentional as scanners can run more than once with different variables and settings. For example, a
developer may want to try running a SAST scan with different variables than the one enforced by the security and compliance team. In
this case, two SAST jobs run in the pipeline:

- One with the developer's variables.
- One with the security and compliance team's variables.

To avoid running duplicate scans, you can either remove the scans from the project's `.gitlab-ci.yml` file or skip your
local jobs with variables. Skipping jobs does not prevent any security jobs defined by scan execution
policies from running.

To skip scan jobs with variables, you can use:

- `SAST_DISABLED: "true"` to skip SAST jobs.
- `DAST_DISABLED: "true"` to skip DAST jobs.
- `CONTAINER_SCANNING_DISABLED: "true"` to skip container scanning jobs.
- `SECRET_DETECTION_DISABLED: "true"` to skip secret detection jobs.
- `DEPENDENCY_SCANNING_DISABLED: "true"` to skip dependency scanning jobs.

For an overview of all variables that can skip jobs, see [CI/CD variables documentation](../../../topics/autodevops/cicd_variables.md#job-skipping-variables)

## Troubleshooting

### Scan execution policy pipelines are not created

If scan execution policies do not create the pipelines defined in `type: pipeline` as expected, you may have [`workflow:rules`](../../../ci/yaml/workflow.md) in the project's `.gitlab-ci.yml` file that prevent the policy from creating the pipeline.

Scan execution policies with `type: pipeline` rules rely on the merged CI/CD configuration to create pipelines. If the project's `workflow:rules` filter out the pipeline entirely, the scan execution policy cannot create a pipeline.

For example, the following `workflow:rules` configuration prevents all pipelines from being created:

```yaml
# .gitlab-ci.yml
workflow:
  rules:
  - if: $CI_PIPELINE_SOURCE == "push"
    when: never
```

Resolution:

To resolve this issue, you can use any of these options:

- Modify the `workflow:rules` in your project's `.gitlab-ci.yml` file to allow scan execution policies to create pipelines. You can use the `$CI_PIPELINE_SOURCE` variable to identify pipelines that are triggered by policies:

  ```yaml
  workflow:
    rules:
    - if: $CI_PIPELINE_SOURCE == "security_orchestration_policy"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
  ```

- Use `type: schedule` rules instead of `type: pipeline` rules. Scheduled scan execution policies are not affected by `workflow:rules` and create pipelines according to their defined schedule.
- Use [pipeline execution policies](pipeline_execution_policies.md) for more control over when and how security scans are executed in your CI/CD pipelines.
