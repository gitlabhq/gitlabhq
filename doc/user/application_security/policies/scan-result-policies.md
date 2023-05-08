---
stage: Govern
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Scan result policies **(ULTIMATE)**

> Group-level scan result policies [introduced](https://gitlab.com/groups/gitlab-org/-/epics/7622) in GitLab 15.6.

You can use scan result policies to take action based on scan results. For example, one type of scan
result policy is a security approval policy that allows approval to be required based on the
findings of one or more security scan jobs. Scan result policies are evaluated after a CI scanning job is fully executed.

NOTE:
Scan result policies are applicable only to [protected](../../project/protected_branches.md) target branches.

The following video gives you an overview of GitLab scan result policies:

<div class="video-fallback">
  See the video: <a href="https://youtu.be/w5I9gcUgr9U">Overview of GitLab Scan Result Policies</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## Scan result policy editor

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77814) in GitLab 14.8.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/369473) in GitLab 15.6.

NOTE:
Only project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

Once your policy is complete, save it by selecting **Configure with a merge request** at the bottom of the
editor. This redirects you to the merge request on the project's configured security policy project.
If a security policy project doesn't link to your project, GitLab creates such a project for you.
Existing policies can also be removed from the editor interface by selecting **Delete policy** at
the bottom of the editor.

Most policy changes take effect as soon as the merge request is merged. Any changes that
do not go through a merge request and are committed directly to the default branch may require up to 10 minutes
before the policy changes take effect.

The [policy editor](index.md#policy-editor) supports YAML mode and rule mode.

NOTE:
Propagating scan result policies created for groups with a large number of projects take a while to complete.

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
| `name` | `string` |  | Name of the policy. Maximum of 255 characters.|
| `description` (optional) | `string` |  | Description of the policy. |
| `enabled` | `boolean` | `true`, `false` | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules` | `array` of rules |  | List of rules that the policy applies. |
| `actions` | `array` of actions |  | List of actions that the policy enforces. |

## `scan_finding` rule type

This rule enforces the defined actions based on security scan findings.

| Field      | Type | Possible values | Description |
|------------|------|-----------------|-------------|
| `type`     | `string` | `scan_finding` | The rule's type. |
| `branches` | `array` of `string` | `[]` or the branch's name | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. |
| `scanners`  | `array` of `string` | `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | The security scanners for this rule to consider. `sast` includes results from both SAST and SAST IaC scanners. |
| `vulnerabilities_allowed`  | `integer` | Greater than or equal to zero | Number of vulnerabilities allowed before this rule is considered. |
| `severity_levels`  | `array` of `string` | `info`, `unknown`, `low`, `medium`, `high`, `critical`| The severity levels for this rule to consider. |
| `vulnerability_states`  | `array` of `string` | `newly_detected`, `detected`, `confirmed`, `resolved`, `dismissed` | All vulnerabilities fall into two categories:<br><br>**Newly Detected Vulnerabilities** - the `newly_detected` policy option covers vulnerabilities identified in the merge request branch itself but that do not currently exist on the default branch. This policy option requires a pipeline to complete before the rule is evaluated so that it knows whether vulnerabilities are newly detected or not. Merge requests are blocked until the pipeline and necessary security scans are complete. The `newly_detected` option considers both of the following statuses:<br><br> • Detected<br> • Dismissed<br><br>**Pre-Existing Vulnerabilities** - these policy options are evaluated immediately and do not require a pipeline complete as they consider only vulnerabilities previously detected in the default branch.<br><br> • `Detected` - the policy looks for vulnerabilities in the detected state.<br> • `Confirmed` - the policy looks for vulnerabilities in the confirmed state.<br> • `Dismissed` - the policy looks for vulnerabilities in the dismissed state.<br> • `Resolved` - the policy looks for vulnerabilities in the resolved state. |

## `license_finding` rule type

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8092) in GitLab 15.9 [with a flag](../../../administration/feature_flags.md) named `license_scanning_policies`.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/397644) in GitLab 15.11. Feature flag `license_scanning_policies` removed.

This rule enforces the defined actions based on license findings.

| Field      | Type | Possible values | Description |
|------------|------|-----------------|-------------|
| `type` | `string` | `license_finding` | The rule's type. |
| `branches` | `array` of `string` | `[]` or the branch's name | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. |
| `match_on_inclusion` | `boolean` | `true`, `false` | Whether the rule matches inclusion or exclusion of licenses listed in `license_types`. |
| `license_types` | `array` of `string` | license types | License types to match on, for example `BSD` or `MIT`. |
| `license_states` | `array` of `string` | `newly_detected`, `detected` | Whether to match newly detected and/or previously detected licenses. The `newly_detected` state triggers approval when either a new package is introduced or when a new license for an existing package is detected. |

## `require_approval` action type

This action sets an approval rule to be required when conditions are met for at least one rule in
the defined policy.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `type` | `string` | `require_approval` | The action's type. |
| `approvals_required` | `integer` | Greater than or equal to zero | The number of MR approvals required. |
| `user_approvers` | `array` of `string` | Username of one of more users | The users to consider as approvers. Users must have access to the project to be eligible to approve. |
| `user_approvers_ids` | `array` of `integer` | ID of one of more users | The IDs of users to consider as approvers. Users must have access to the project to be eligible to approve. |
| `group_approvers` | `array` of `string` | Path of one of more groups | The groups to consider as approvers. Users with [direct membership in the group](../../project/merge_requests/approvals/rules.md#group-approvers) are eligible to approve. |
| `group_approvers_ids` | `array` of `integer` | ID of one of more groups | The IDs of groups to consider as approvers. Users with [direct membership in the group](../../project/merge_requests/approvals/rules.md#group-approvers) are eligible to approve. |
| `role_approvers` | `array` of `string` | One or more [roles](../../../user/permissions.md#roles) (for example: `owner`, `maintainer`)  | The roles to consider as approvers that are eligible to approve. |

Requirements and limitations:

- You must add the respective [security scanning tools](../index.md#application-coverage).
  Otherwise, scan result policies do not have any effect.
- The maximum number of policies is five.
- Each policy can have a maximum of five rules.

## Example security scan result policies project

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](index.md#security-policy-project):

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
    role_approvers:
    - owner
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

## Example situations where scan result policies require additional approval

There are several situations where the scan result policy requires an additional approval step. For example:

- The number of security jobs is reduced in the working branch and no longer matches the number of security jobs in the target branch. Users can't skip the Scanning Result Policies by removing scanning jobs from the CI configuration.
- Someone stops a pipeline security job, and users can't skip the security scan.
- A job in a merge request fails and is configured with `allow_failure: false`. As a result, the pipeline is in a blocked state.
- A pipeline has a manual job that must run successfully for the entire pipeline to pass.
