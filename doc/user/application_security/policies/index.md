---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Scan Policies **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5329) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.10.
> - Deployed behind a feature flag, disabled by default.
> - Disabled on GitLab.com.

Scan Policies in GitLab provide security teams a way to require scans of their choice to be run
whenever a project pipeline runs according to the configuration specified. Security teams can
therefore be confident that the scans they set up have not been changed, altered, or disabled. You
can access these by navigating to your project's **Security & Compliance > Scan Policies** page.

GitLab supports the following security policies:

- [Scan Execution Policy](#scan-execution-policy-schema)

WARNING:
Scan Policies is under development and is not ready for production use. It's deployed behind a
feature flag that's disabled by default.

NOTE:
We recommend using the [Security Policies project](#security-policies-project)
exclusively for managing policies for the project. Do not add your application's source code to such
projects.

## Enable or disable scan policies

Scan Policies is under development and is not ready for production use. It's deployed behind a
feature flag that's disabled by default.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it for your instance. Scan Policies can be enabled or disabled per-project.

To enable it:

```ruby
# Instance-wide
Feature.enable(:security_orchestration_policies_configuration)
# or by project
Feature.enable(:security_orchestration_policies_configuration, Project.find(<project ID>))
```

To disable it:

```ruby
# Instance-wide
Feature.disable(:security_orchestration_policies_configuration)
# or by project
Feature.disable(:security_orchestration_policies_configuration, Project.find(<project ID>))
```

## Security Policies project

The Security Policies feature is a repository to store policies. All security policies are stored as
the `.gitlab/security-policies/policy.yml` YAML file with this format:

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan
  enabled: true
  rules:
  - type: pipeline
    branches:
    - master
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST in every pipeline in main branch
  description: This policy enforces pipeline configuration to have a job with DAST scan for main branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
```

### Scan Execution Policies Schema

The YAML file with Scan Execution Policies consists of an array of objects matching Scan Execution Policy Schema nested under the `scan_execution_policy` key. You can configure a maximum of 5 policies under the `scan_execution_policy` key.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `scan_execution_policy` | `array` of Scan Execution Policy |  | List of scan execution policies (maximum 5) |

### Scan Execution Policy Schema

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `name` | `string` |  | Name of the policy. |
| `description` (optional) | `string` |  | Description of the policy. |
| `enabled` | `boolean` | `true`, `false` | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules` | `array` of rules |  | List of rules that the policy applies. |
| `actions` | `array` of actions |  | List of actions that the policy enforces. |

### `pipeline` rule type

This rule enforces the defined actions whenever the pipeline runs for a selected branch.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `type` | `string` | `pipeline` | The rule's type. |
| `branches` | `array` of `string` | `*` or the branch's name | The branch the given policy applies to (supports wildcard). |

### `schedule` rule type

This rule enforces the defined actions and schedules a scan on the provided date/time.

| Field      | Type | Possible values | Description |
|------------|------|-----------------|-------------|
| `type`     | `string` | `schedule` | The rule's type. |
| `branches` | `array` of `string` | `*` or the branch's name | The branch the given policy applies to (supports wildcard). |
| `cadence`  | `string` | CRON expression (for example, `0 0 * * *`) | A whitespace-separated string containing five fields that represents the scheduled time. |

### `scan` action type

This action executes the selected `scan` with additional parameters when conditions for at least one
rule in the defined policy are met.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `scan` | `string` | `dast` | The action's type. |
| `site_profile` | `string` | Name of the selected [DAST site profile](../dast/index.md#site-profile). | The DAST site profile to execute the DAST scan. |
| `scanner_profile` | `string` or `null` | Name of the selected [DAST scanner profile](../dast/index.md#scanner-profile). | The DAST scanner profile to execute the DAST scan. |

Note the following:

- You must create the [site profile](../dast/index.md#site-profile) and [scanner profile](../dast/index.md#scanner-profile)
  with selected names for each project that is assigned to the selected Security Policy Project.
  Otherwise, the policy is not applied and a job with an error message is created instead.
- Once you associate the site profile and scanner profile by name in the policy, it is not possible
  to modify or delete them. If you want to modify them, you must first disable the policy by setting
  the `active` flag to `false`.
- When configuring policies with a scheduled DAST scan, the author of the commit in the security
  policy project's repository must have access to the scanner and site profiles. Otherwise, the scan
  is not scheduled successfully.

Here's an example:

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
- name: Enforce DAST scan every 10 minutes
  description: This policy enforces a DAST scan to run every 10 minutes
  enabled: true
  rules:
  - type: schedule
    branches:
    - main
    cadence: */10 * * * *
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
```

In this example, the DAST scan runs with the scanner profile `Scanner Profile A` and the site
profile `Site Profile B` for every pipeline executed on branches that match the
`release/*` wildcard (for example, branch name `release/v1.2.1`); and the DAST scan runs with
the scanner profile `Scanner Profile C` and the site profile `Site Profile D` every 10 minutes.

## Security Policy project selection

When the Security Policy project is created and policies are created within that repository, you
must create an association between that project and the project you want to apply policies to. To do
this, navigate to your project's **Security & Compliance > Policies**, select
**Security policy project** from the dropdown menu, then select the **Create policy** button to save
changes.

You can always change the **Security policy project** by navigating to your project's
**Security & Compliance > Policies** and modifying the selected project.

NOTE:
Only project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

## Roadmap

See the [Category Direction page](https://about.gitlab.com/direction/protect/container_network_security/)
for more information on the product direction of Container Network Security.
