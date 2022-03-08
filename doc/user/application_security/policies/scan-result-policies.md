---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Scan result policies **(ULTIMATE)**

You can use scan result policies to take action based on scan results. For example, one type of scan
result policy is a security approval policy that allows approval to be required based on the
findings of one or more security scan jobs. Scan result policies are evaluated after a CI scanning
job is fully executed.

## Scan result policy editor

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77814) in GitLab 14.8.

NOTE:
Only project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

Once your policy is complete, save it by selecting **Create merge request** at the bottom of the
editor. This redirects you to the merge request on the project's configured security policy project.
If a security policy project doesn't link to your project, GitLab creates such a project for you.
Existing policies can also be removed from the editor interface by selecting **Delete policy** at
the bottom of the editor.

All scan result policy changes are applied through a background job that runs once every 10 minutes.
Allow up to 10 minutes for any policy changes committed to this project to take effect.

The [policy editor](index.md#policy-editor) supports YAML mode and rule mode.

## Scan result policies schema

The YAML file with scan result policies consists of an array of objects matching the scan result
policy schema nested under the `scan_result_policy` key. You can configure a maximum of five
policies under the `scan_result_policy` key.

When you save a new policy, GitLab validates its contents against [this JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json).
If you're not familiar with how to read [JSON schemas](https://json-schema.org/),
the following sections and tables provide an alternative.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `scan_result_policy` | `array` of Scan Result Policy |  | List of scan result policies (maximum 5). |

## Scan result policy schema

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `name` | `string` |  | Name of the policy. |
| `description` (optional) | `string` |  | Description of the policy. |
| `enabled` | `boolean` | `true`, `false` | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules` | `array` of rules |  | List of rules that the policy applies. |
| `actions` | `array` of actions |  | List of actions that the policy enforces. |

## `scan_finding` rule type

This rule enforces the defined actions based on the information provided.

| Field      | Type | Possible values | Description |
|------------|------|-----------------|-------------|
| `type`     | `string` | `scan_finding` | The rule's type. |
| `branches` | `array` of `string` | `*` or the branch's name | The branch the given policy applies to (supports wildcard). |
| `scanners`  | `array` of `string` | `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | The security scanners for this rule to consider. |
| `vulnerabilities_allowed`  | `integer` | Greater than or equal to zero | Number of vulnerabilities allowed before this rule is considered. |
| `severity_levels`  | `array` of `string` | `info`, `unknown`, `low`, `medium`, `high`, `critical`| The severity levels for this rule to consider. |
| `vulnerability_states`  | `array` of `string` | `newly_detected`, `detected`, `confirmed`, `resolved`, `dismissed` | The vulnerability states for this rule to consider when the target branch is set to the default branch. |

## `require_approval` action type

This action sets an approval rule to be required when conditions are met for at least one rule in
the defined policy.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `type` | `string` | `require_approval` | The action's type. |
| `approvals_required` | `integer` | Greater than or equal to zero | The number of MR approvals required. |
| `user_approvers` | `array` of `string` | Username of one of more users | The users to consider as approvers. |
| `user_approvers_ids` | `array` of `integer` | ID of one of more users | The IDs of users to consider as approvers. |
| `group_approvers` | `array` of `string` | Path of one of more groups | The groups to consider as approvers. |
| `group_approvers_ids` | `array` of `integer` | ID of one of more groups | The IDs of groups to consider as approvers. |

Requirements and limitations:

- You must add the respective [security scanning tools](../index.md#security-scanning-tools).
  Otherwise, scan result policies won't have any effect.
- The maximum number of policies is five.
- Each policy can have a maximum of five rules.

## Example security scan result policies project

You can use this example in a `.gitlab/security-policies/policy.yml`, as described in
[Security policies project](index.md#security-policies-project):

```yaml
---
scan_result_policy:
- name: critical vulnerability CS approvals
  description: critical severity level only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    vulnerability_states:
    - newly_detected
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - adalberto.dare
- name: secondary CS approvals
  description: secondary only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
    - low
    - unknown
    vulnerability_states:
    - newly_detected
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - sam.white
```

In this example:

- Every MR that contains new `critical` vulnerabilities identified by container scanning requires
  one approval from `alberto.dare`.
- Every MR that contains more than one new `low` or `unknown` vulnerability identified by container
  scanning requires one approval from `sam.white`.

## Example for Scan Result Policy editor

You can use this example in the YAML mode of the [Scan Result Policy editor](#scan-result-policy-editor).
It corresponds to a single object from the previous example:

```yaml
- name: critical vulnerability CS approvals
  description: critical severity level only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
    - critical
    vulnerability_states:
    - newly_detected
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - adalberto.dare
```
