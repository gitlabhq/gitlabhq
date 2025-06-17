---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to enforce security rules in GitLab using merge request approval policies to automate scans, approvals, and compliance across your projects.
title: Merge request approval policies
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Group-level scan result policies [introduced](https://gitlab.com/groups/gitlab-org/-/epics/7622) in GitLab 15.6.
- Scan result policies feature was renamed to merge request approval policies in GitLab 16.9.

{{< /history >}}

{{< alert type="note" >}}

Scan result policies feature was renamed to merge request approval policies in GitLab 16.9.

{{< /alert >}}

You can use merge request approval policies for multiple purposes, including:

- Detect results from security and license scanners to enforce approval rules. For example, one type of merge request
policy is a security approval policy that allows approval to be required based on the
findings of one or more security scan jobs. Merge request approval policies are evaluated after a CI scanning job is fully executed and both vulnerability and license type policies are evaluated based on the job artifact reports that are published in the completed pipeline.
- Enforce approval rules on all merge requests that meet certain conditions. For example, enforce that MRs are reviewed by multiple users with Developer and Maintainer roles for all MRs that target default branches.
- Enforce settings for security and compliance on a project. For example, prevent users who have authored or committed changes to an MR from approving the MR. Or prevent users from pushing or force pushing to the default branch to ensure all changes go through an MR.

{{< alert type="note" >}}

When a protected branch is created or deleted, the policy approval rules synchronize, with a delay of 1 minute.

{{< /alert >}}

The following video gives you an overview of GitLab merge request approval policies (previously scan result policies):

<div class="video-fallback">
  See the video: <a href="https://youtu.be/w5I9gcUgr9U">Overview of GitLab Scan Result Policies</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## Restrictions

- You can enforce merge request approval policies only on [protected](../../project/repository/branches/protected.md)
  target branches.
- You can assign a maximum of five rules to each policy.
- You can assign a maximum of five merge request approval policies to each security policy project.
- Policies created for a group or subgroup can take some time to apply to all the merge requests in
  the group. The time it takes is determined by the number of projects and the number of merge requests
  in those projects. Typically, the time taken is a matter of seconds. For groups with many thousands of projects
  and merge requests, this could take several minutes, based on what we've previously observed.
- Merge request approval policies do not check the integrity or authenticity of the scan results
  generated in the artifact reports.
- A merge request approval policy is evaluated according to its rules. By default, if the rules are
  invalid, or can't be evaluated, approval is required. You can change this behavior with the
  [`fallback_behavior` field](#fallback_behavior).

## Pipeline requirements

A merge request approval policy is enforced according to the outcome of the pipeline. Consider the
following when implementing a merge request approval policy:

- A merge request approval policy evaluates completed pipeline jobs, ignoring manual jobs. When the
  manual jobs are run, the policy re-evaluates the merge request's jobs.
- For a merge request approval policy that evaluates the results of security scanners, all specified
  scanners must have output a security report. If not, approvals are enforced to minimize the risk
  of vulnerabilities being introduced. This behavior can affect:
  - New projects where security scans are not yet established.
  - Branches created before the security scans were configured.
  - Projects with inconsistent scanner configurations between branches.
- The pipeline must produce artifacts for all enabled scanners, for both the source and target
  branches. If not, there's no basis for comparison and so the policy can't be evaluated. You should
  use a scan execution policy to enforce this requirement.
- Policy evaluation depends on a successful and completed merge base pipeline. If the merge base
  pipeline is skipped, merge requests with the merge base pipeline are blocked.
- Security scanners specified in a policy must be configured and enabled in the projects on which
  the policy is enforced. If not, the merge request approval policy cannot be evaluated and the
  corresponding approvals are required.

## Best practices for using security scanners with merge request approval policies

When you create a new project, you can enforce both merge request approval policies and security scans on that project. However, incorrectly configured security scanners can affect the merge request approval policies.

There are multiple ways to configure security scans in new projects:

- In the project's CI/CD configuration by adding the scanners to the initial `.gitlab-ci.yml` configuration file.
- In a scan execution policy to enforce that pipelines run specific security scanners.
- In a pipeline execution policy to control which jobs must run in pipelines.

For simple use cases, you can use the project's CI/CD configuration. For a comprehensive security strategy, consider combining merge request approval policies with the other policy types.

To minimize unnecessary approval requirements and ensure accurate security evaluations:

- **Run security scans on your default branch first**: Before creating feature branches, ensure security scans have run successfully on your default branch.
- **Use consistent scanner configuration**: Run the same scanners in both source and target branches, preferably in a single pipeline.
- **Verify that scans produce artifacts**: Ensure that scans complete successfully and produce artifacts for comparison.
- **Keep branches synchronized**: Regularly merge changes from the default branch into feature branches.
- **Consider pipeline configurations**: For new projects, include security scanners in your initial `.gitlab-ci.yml` configuration.

### Verify security scanners before you apply merge request approval policies

By implementing your security scans in your new project before you apply a merge request approval policy, you can ensure security scanners run consistently before relying on merge request approval policies, which helps avoid situations where merge requests are blocked due to missing security scans.

To create and verify your security scanners and merge request approval policies together, use this recommended workflow:

1. Create the project.
1. Configure security scanners using the `.gitlab-ci.yml` configuration, a scan execution policy, or a pipeline execution policy.
1. Wait for the initial pipeline to complete on the default branch. Resolve any issues and rerun the pipeline to ensure it completes successfully before you continue.
1. Create merge requests using feature branches with the same security scanners configured. Again, ensure that the security scanners complete sucessfully.
1. Apply your merge request approval policies.

## Merge request with multiple pipelines

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/379108) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `multi_pipeline_scan_result_policies`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/409482) in GitLab 16.3. Feature flag `multi_pipeline_scan_result_policies` removed.
- Support for parent-child pipelines [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428591) in GitLab 16.11 [with a flag](../../../administration/feature_flags.md) named `approval_policy_parent_child_pipeline`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/451597) in GitLab 17.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/428591) in GitLab 17.1. Feature flag `approval_policy_parent_child_pipeline` removed.

{{< /history >}}

A project can have multiple pipeline types configured. A single commit can initiate multiple
pipelines, each of which may contain a security scan.

- In GitLab 16.3 and later, the results of all completed pipelines for the latest commit in
  the merge request's source and target branch are evaluated and used to enforce the merge request approval policy.
  On-demand DAST pipelines are not considered.
- In GitLab 16.2 and earlier, only the results of the latest completed pipeline were evaluated
  when enforcing merge request approval policies.

If a project uses [merge request pipelines](../../../ci/pipelines/merge_request_pipelines.md), you must set the CI/CD variable `AST_ENABLE_MR_PIPELINES` to `"true"` for the security scanning jobs to be present in the pipeline.
For more information see [Use security scanning tools with merge request pipelines](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

For projects where many pipelines have run on the latest commit (for example, dormant projects), policy evaluation considers a maximum of 1,000 pipelines from both the source and target branches of the merge request.

For parent-child pipelines, policy evaluation considers a maximum of 1,000 child pipelines.

## Merge request approval policy editor

{{< history >}}

- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/369473) in GitLab 15.6.

{{< /history >}}

{{< alert type="note" >}}

Only project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

{{< /alert >}}

Once your policy is complete, save it by selecting **Configure with a merge request** at the bottom of the
editor. This redirects you to the merge request on the project's configured security policy project.
If a security policy project doesn't link to your project, GitLab creates such a project for you.
Existing policies can also be removed from the editor interface by selecting **Delete policy** at
the bottom of the editor.

Most policy changes take effect as soon as the merge request is merged. Any changes that
do not go through a merge request and are committed directly to the default branch may require up to 10 minutes
before the policy changes take effect.

The [policy editor](_index.md#policy-editor) supports YAML mode and rule mode.

{{< alert type="note" >}}

Propagating merge request approval policies created for groups with a large number of projects take a while to complete.

{{< /alert >}}

## Merge request approval policies schema

The YAML file with merge request approval policies consists of an array of objects matching the merge request approval
policy schema nested under the `approval_policy` key. You can configure a maximum of five policies under the `approval_policy` key.

{{< alert type="note" >}}

Merge request approval policies were defined under the `scan_result_policy` key. Until GitLab 17.0, policies can be
defined under both keys. Starting from GitLab 17.0, only `approval_policy` key is supported.

{{< /alert >}}

When you save a new policy, GitLab validates its contents against [this JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json).
If you're not familiar with how to read [JSON schemas](https://json-schema.org/),
the following sections and tables provide an alternative.

| Field             | Type                                     | Required | Description                                          |
|-------------------|------------------------------------------|----------|------------------------------------------------------|
| `approval_policy` | `array` of merge request approval policy objects | true     | List of merge request approval policies (maximum 5). |

## Merge request approval policy schema

{{< history >}}

- The `approval_settings` fields were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) in GitLab 16.4 [with flags](../../../administration/feature_flags.md) named `scan_result_policies_block_unprotecting_branches`, `scan_result_any_merge_request`, or `scan_result_policies_block_force_push`. See the `approval_settings` section below for more information.

{{< /history >}}

| Field               | Type               | Required | Possible values | Description                                              |
|---------------------|--------------------|----------|-----------------|----------------------------------------------------------|
| `name`              | `string`           | true     |                 | Name of the policy. Maximum of 255 characters.           |
| `description`       | `string`           | false    |                 | Description of the policy.                               |
| `enabled`           | `boolean`          | true     | `true`, `false` | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules`             | `array` of rules   | true     |                 | List of rules that the policy applies.                   |
| `actions`           | `array` of actions | false    |                 | List of actions that the policy enforces.                |
| `approval_settings` | `object`           | false    |                 | Project settings that the policy overrides.              |
| `fallback_behavior` | `object`           | false    |                 | Settings that affect invalid or unenforceable rules.     |
| `policy_scope`      | `object` of [`policy_scope`](_index.md#scope) | false |  | Defines the scope of the policy based on the projects, groups, or compliance framework labels you specify. |
| `policy_tuning`     | `object`           | false    |                 | (Experimental) Settings that affect policy comparison logic.     |

## `scan_finding` rule type

{{< history >}}

- The merge request approval policy field `vulnerability_attributes` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123052) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `enforce_vulnerability_attributes_rules`. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/418784) in GitLab 16.3. Feature flag removed.
- The merge request approval policy field `vulnerability_age` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123956) in GitLab 16.2.
- The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753) in GitLab 16.5. Feature flag removed.
- The `vulnerability_states` option `newly_detected` was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/422414) in GitLab 17.0 and the options `new_needs_triage` and `new_dismissed` were added to replace it.

{{< /history >}}

This rule enforces the defined actions based on security scan findings.

| Field                      | Type                | Required                                   | Possible values                                                                                                    | Description |
|----------------------------|---------------------|--------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | true                                       | `scan_finding`                                                                                                     | The rule's type. |
| `branches`                 | `array` of `string` | true if `branch_type` field does not exist | `[]` or the branch's name                                                                                          | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. Cannot be used with the `branch_type` field. |
| `branch_type`              | `string`            | true if `branches` field does not exist    | `default` or `protected`                                                                                           | The types of protected branches the given policy applies to. Cannot be used with the `branches` field. Default branches must also be `protected`. |
| `branch_exceptions`        | `array` of `string` | false                                      | Names of branches                                                                                                  | Branches to exclude from this rule. |
| `scanners`                 | `array` of `string` | true                                       | `[]` or `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | The security scanners for this rule to consider. `sast` includes results from both SAST and SAST IaC scanners. An empty array, `[]`, applies the rule to all security scanners.|
| `vulnerabilities_allowed`  | `integer`           | true                                       | Greater than or equal to zero                                                                                      | Number of vulnerabilities allowed before this rule is considered. |
| `severity_levels`          | `array` of `string` | true                                       | `info`, `unknown`, `low`, `medium`, `high`, `critical`                                                             | The severity levels for this rule to consider. |
| `vulnerability_states`     | `array` of `string` | true                                       | `[]` or `detected`, `confirmed`, `resolved`, `dismissed`, `new_needs_triage`, `new_dismissed`                      | All vulnerabilities fall into two categories:<br><br>**Newly Detected Vulnerabilities** - Vulnerabilities identified in the merge request branch itself but that do not currently exist on the MR's target branch. This policy option requires a pipeline to complete before the rule is evaluated so that it knows whether vulnerabilities are newly detected or not. Merge requests are blocked until the pipeline and necessary security scans are complete. The `new_needs_triage` option considers the status<br><br> • Detected<br><br> The `new_dismissed` option considers the status<br><br> • Dismissed<br><br>**Pre-Existing Vulnerabilities** - these policy options are evaluated immediately and do not require a pipeline complete as they consider only vulnerabilities previously detected in the default branch.<br><br> • `Detected` - the policy looks for vulnerabilities in the detected state.<br> • `Confirmed` - the policy looks for vulnerabilities in the confirmed state.<br> • `Dismissed` - the policy looks for vulnerabilities in the dismissed state.<br> • `Resolved` - the policy looks for vulnerabilities in the resolved state. <br><br>An empty array, `[]`, covers the same statuses as `['new_needs_triage', 'new_dismissed']`. |
| `vulnerability_attributes` | `object`            | false                                      | `{false_positive: boolean, fix_available: boolean}`                                                                | All vulnerability findings are considered by default. But filters can be applied for attributes to consider only vulnerability findings: <br><br> • With a fix available (`fix_available: true`)<br><br> • With no fix available (`fix_available: false`)<br> • That are false positive (`false_positive: true`)<br> • That are not false positive (`false_positive: false`)<br> • Or a combination of both. For example (`fix_available: true, false_positive: false`) |
| `vulnerability_age`        | `object`            | false                                      | N/A                                                                                                                | Filter pre-existing vulnerability findings by age. A vulnerability's age is calculated as the time since it was detected in the project. The criteria are `operator`, `value`, and `interval`.<br>- The `operator` criterion specifies if the age comparison used is older than (`greater_than`) or younger than (`less_than`).<br>- The `value` criterion specifies the numeric value representing the vulnerability's age.<br>- The `interval` criterion specifies the unit of measure of the vulnerability's age: `day`, `week`, `month`, or `year`.<br><br>Example: `operator: greater_than`, `value: 30`, `interval: day`. |

## `license_finding` rule type

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8092) in GitLab 15.9 [with a flag](../../../administration/feature_flags.md) named `license_scanning_policies`.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/397644) in GitLab 15.11. Feature flag `license_scanning_policies` removed.
- The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`. Enabled by default. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753) in GitLab 16.5. Feature flag removed.
- The `licenses` field was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/10203) in GitLab 17.11 [with a flag](../../../administration/feature_flags.md) named `exclude_license_packages`. Feature flag removed.

{{< /history >}}

This rule enforces the defined actions based on license findings.

| Field          | Type     | Required                                      | Possible values              | Description                                                                                                                                                                                                         |
|----------------|----------|-----------------------------------------------|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`         | `string` | true                                          | `license_finding`            | The rule's type.                                                                                                                                                                                                    |
| `branches`     | `array` of `string` | true if `branch_type` field does not exist    | `[]` or the branch's name    | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. Cannot be used with the `branch_type` field.                                                 |
| `branch_type`  | `string` | true if `branches` field does not exist       | `default` or `protected`     | The types of protected branches the given policy applies to. Cannot be used with the `branches` field. Default branches must also be `protected`.                                                                   |
| `branch_exceptions` | `array` of `string` | false                                         | Names of branches            | Branches to exclude from this rule.                                                                                                                                                                                 |
| `match_on_inclusion_license` | `boolean` | true if `licenses` field does not exists      | `true`, `false`              | Whether the rule matches inclusion or exclusion of licenses listed in `license_types`.                                                                                                                              |
| `license_types` | `array` of `string` | true if `licenses` field does not exists      | license types                | [SPDX license names](https://spdx.org/licenses) to match on, for example `Affero General Public License v1.0` or `MIT License`.                                                                                     |
| `license_states` | `array` of `string` | true                                          | `newly_detected`, `detected` | Whether to match newly detected and/or previously detected licenses. The `newly_detected` state triggers approval when either a new package is introduced or when a new license for an existing package is detected. |
| `licenses`     | `object` | true if `license_types` field does not exists | `licenses` object            | [SPDX license names](https://spdx.org/licenses) to match on including package exceptions.                                                                                                                        |

### `licenses` object

| Field     | Type     | Required                                | Possible values                                      | Description                                                |
|-----------|----------|-----------------------------------------|------------------------------------------------------|------------------------------------------------------------|
| `denied`  | `object` | true if `allowed` field does not exist | `array` of `licenses_with_package_exclusion` objects  | The list of denied licenses including package exceptions.  |
| `allowed` | `object` | true if `denied` field does not exist  | `array` of `licenses_with_package_exclusion` objects  | The list of allowed licenses including package exceptions. |

### `licenses_with_package_exclusion` object

| Field  | Type     | Required | Possible values   | Description                                        |
|--------|----------|----------|-------------------|----------------------------------------------------|
| `name` | `string` | true     | SPDX license name | [SPDX license name](https://spdx.org/licenses).    |
| `packages` | `object` | false    | `packages` object | List of packages exceptions for the given license. |

### `packages` object

| Field  | Type     | Required | Possible values                                       | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|--------|----------|----------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `excluding` | `object` | true     | {purls: `array` of `strings` using the `uri` format} | List of package exceptions for the given license. Define the list of packages exceptions using the [`purl`](https://github.com/package-url/purl-spec?tab=readme-ov-file#purl) components `scheme:type/name@version`. The `scheme:type/name` components are required. The `@` and `version` are optional. If a version is specified, only that version is considered an exception. If no version is specified and the `@` character is added at the end of the `purl`, only packages with the exact name is considered a match. If the `@` character is not added to the package name, all packages with the same prefix for the given license are matches. For example, a purl `pkg:gem/bundler` matches the `bundler` and `bundler-stats` packages because both packages use the same license. Defining a `purl` `pkg:gem/bundler@` matches only the `bundler` package. |

## `any_merge_request` rule type

{{< history >}}

- The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`. Enabled by default. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753) in GitLab 16.5. Feature flag removed.
- The `any_merge_request` rule type was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) in GitLab 16.4. Enabled by default. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136298) in GitLab 16.6. Feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/432127).

{{< /history >}}

This rule enforces the defined actions for any merge request based on the commits signature.

| Field               | Type                | Required                                   | Possible values           | Description |
|---------------------|---------------------|--------------------------------------------|---------------------------|-------------|
| `type`              | `string`            | true                                       | `any_merge_request`       | The rule's type. |
| `branches`          | `array` of `string` | true if `branch_type` field does not exist | `[]` or the branch's name | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. Cannot be used with the `branch_type` field. |
| `branch_type`       | `string`            | true if `branches` field does not exist    | `default` or `protected`  | The types of protected branches the given policy applies to. Cannot be used with the `branches` field. Default branches must also be `protected`. |
| `branch_exceptions` | `array` of `string` | false                                      | Names of branches         | Branches to exclude from this rule. |
| `commits`           | `string`            | true                                       | `any`, `unsigned`         | Whether the rule matches for any commits, or only if unsigned commits are detected in the merge request. |

## `require_approval` action type

{{< history >}}

- [Added](https://gitlab.com/groups/gitlab-org/-/epics/12319) support for up to five separate `require_approval` actions in GitLab 17.7 [with a flag](../../../administration/feature_flags.md) named `multiple_approval_actions`.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/505374) in GitLab 17.8. Feature flag `multiple_approval_actions` removed.
- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13550) support to specify custom roles as `role_approvers` in GitLab 17.9 [with a flag](../../../administration/feature_flags.md) named `security_policy_custom_roles`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/505742) in GitLab 17.10. Feature flag `security_policy_custom_roles` removed.

{{< /history >}}

This action makes an approval rule required when the conditions are met for at least one rule in
the defined policy.

If you specify multiple approvers in the same `require_approval` block, any of the eligible approvers can satisfy the approval requirement. For example, if you specify two `group_approvers` and `approvals_required` as `2`, both of the approvals can come from the same group. To require multiple approvals from unique approver types, use multiple `require_approval` actions.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `require_approval` | The action's type. |
| `approvals_required` | `integer` | true | Greater than or equal to zero | The number of MR approvals required. |
| `user_approvers` | `array` of `string` | false | Username of one of more users | The users to consider as approvers. Users must have access to the project to be eligible to approve. |
| `user_approvers_ids` | `array` of `integer` | false | ID of one of more users | The IDs of users to consider as approvers. Users must have access to the project to be eligible to approve. |
| `group_approvers` | `array` of `string` | false | Path of one of more groups | The groups to consider as approvers. Users with [direct membership in the group](../../project/merge_requests/approvals/rules.md#group-approvers) are eligible to approve. |
| `group_approvers_ids` | `array` of `integer` | false | ID of one of more groups | The IDs of groups to consider as approvers. Users with [direct membership in the group](../../project/merge_requests/approvals/rules.md#group-approvers) are eligible to approve. |
| `role_approvers` | `array` of `string` | false | One or more [roles](../../permissions.md#roles) (for example: `owner`, `maintainer`). You can also specify custom roles (or custom role identifiers in YAML mode) as `role_approvers` if the custom roles have the permission to approve merge requests. The custom roles can be selected along with user and group approvers. | The roles that are eligible to approve. |

## `send_bot_message` action type

{{< history >}}

- The `send_bot_message` action type was [introduced for projects](https://gitlab.com/gitlab-org/gitlab/-/issues/438269) in GitLab 16.11 [with a flag](../../../administration/feature_flags.md) named `approval_policy_disable_bot_comment`. Disabled by default.
- [Enabled on GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/454852) in GitLab 17.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/454852) in GitLab 17.3. Feature flag `approval_policy_disable_bot_comment` removed.
- The `send_bot_message` action type was [introduced for groups](https://gitlab.com/gitlab-org/gitlab/-/issues/469449) in GitLab 17.2 [with a flag](../../../administration/feature_flags.md) named `approval_policy_disable_bot_comment_group`. Disabled by default.
- [Enabled on GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/469449) in GitLab 17.2.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/469449) in GitLab 17.3. Feature flag `approval_policy_disable_bot_comment_group` removed.

{{< /history >}}

This action enables configuration of the bot message in merge requests when policy violations are detected.
If the action is not specified, the bot message is enabled by default. If there are multiple policies defined,
the bot message is sent as long as at least one of those policies has the `send_bot_message` action is enabled.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `send_bot_message` | The action's type. |
| `enabled` | `boolean` | true | `true`, `false` | Whether a bot message should be created when policy violations are detected. Default: `true` |

### Example bot messages

![scan_results_example_bot_message_v17_0](img/scan_result_policy_example_bot_message_vulnerabilities_v17_0.png)

![scan_results_example_bot_message_v17_0](img/scan_result_policy_example_bot_message_artifacts_v17_0.png)

## Warn mode

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15552) in GitLab 17.8 [with a flag](../../../administration/feature_flags.md) named `security_policy_approval_warn_mode`. Disabled by default

{{< /history >}}

When warn mode is enabled and a merge request triggers a security policy that doesn't require any additional approvers, a bot comment is added to the merge request. The comment directs users to the policy for more information.

## `approval_settings`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420724) the `block_group_branch_modification` field in GitLab 16.8 [with flag](../../../administration/feature_flags.md) named `scan_result_policy_block_group_branch_modification`.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/437306) in GitLab 17.6.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/503930) in GitLab 17.7. Feature flag `scan_result_policy_block_group_branch_modification` removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423101) the `block_unprotecting_branches` field in GitLab 16.4 [with flag](../../../administration/feature_flags.md) named `scan_result_policy_settings`. Disabled by default.
- The `scan_result_policy_settings` feature flag was replaced by the `scan_result_policies_block_unprotecting_branches` feature flag in 16.4.
- The `block_unprotecting_branches` field was [replaced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137153) by `block_branch_modification` field in GitLab 16.7.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/423901) in GitLab 16.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/433415) in GitLab 16.11. Feature flag `scan_result_policies_block_unprotecting_branches` removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) the `prevent_approval_by_author`, `prevent_approval_by_commit_author`, `remove_approvals_with_new_commit`, and `require_password_to_approve` fields in GitLab 16.4 [with flag](../../../administration/feature_flags.md) named `scan_result_any_merge_request`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/423988) in GitLab 16.6.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/423988) in GitLab 16.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/432127) in GitLab 16.8. Feature flag `scan_result_any_merge_request` removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420629) the `prevent_pushing_and_force_pushing` field in GitLab 16.4 [with flag](../../../administration/feature_flags.md) named `scan_result_policies_block_force_push`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/427260) in GitLab 16.6.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/427260) in GitLab 16.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/432123) in GitLab 16.9. Feature flag `scan_result_policies_block_force_push` removed.

{{< /history >}}

The settings set in the policy overwrite settings in the project.

| Field                               | Type                  | Required | Possible values                                               | Applicable rule type | Description |
|-------------------------------------|-----------------------|----------|---------------------------------------------------------------|----------------------|-------------|
| `block_branch_modification`         | `boolean`             | false    | `true`, `false`                                               | All                  | When enabled, prevents a user from removing a branch from the protected branches list, deleting a protected branch, or changing the default branch if that branch is included in the security policy. This ensures users cannot remove protection status from a branch to merge vulnerable code. Enforced based on `branches`, `branch_type` and `policy_scope` and regardless of detected vulnerabilities. |
| `block_group_branch_modification`   | `boolean` or `object` | false    | `true`, `false`, `{ enabled: boolean, exceptions: [{ id: Integer}] }` | All                  | When enabled, prevents a user from removing group-level protected branches on every group the policy applies to. If `block_branch_modification` is `true`, implicitly defaults to `true`. Add top-level groups that support [group-level protected branches](../../project/repository/branches/protected.md#in-a-group) as `exceptions` |
| `prevent_approval_by_author`        | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | When enabled, merge request authors cannot approve their own MRs. This ensures code authors cannot introduce vulnerabilities and approve code to merge. |
| `prevent_approval_by_commit_author` | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | When enabled, users who have contributed code to the MR are ineligible for approval. This ensures code committers cannot introduce vulnerabilities and approve code to merge. |
| `remove_approvals_with_new_commit`  | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | When enabled, if an MR receives all necessary approvals to merge, but then a new commit is added, new approvals are required. This ensures new commits that may include vulnerabilities cannot be introduced. |
| `require_password_to_approve`       | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | When enabled, there will be password confirmation on approvals. Password confirmation adds an extra layer of security. |
| `prevent_pushing_and_force_pushing` | `boolean`             | false    | `true`, `false`                                               | All                  | When enabled, prevents users from pushing and force pushing to a protected branch if that branch is included in the security policy. This ensures users do not bypass the merge request process to add vulnerable code to a branch. |

## `fallback_behavior`

{{< history >}}

- The `fallback_behavior` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/451784) in GitLab 17.0 [with a flag](../../../administration/feature_flags.md) named `security_scan_result_policies_unblock_fail_open_approval_rules`. Disabled by default.
- The `fallback_behavior` field was [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/10816) in GitLab 17.0.

{{< /history >}}

{{< alert type="flag" >}}

On GitLab Self-Managed, by default the `fallback_behavior` field is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `security_scan_result_policies_unblock_fail_open_approval_rules`. On GitLab.com and GitLab Dedicated, this feature is available.

{{< /alert >}}

| Field  | Type     | Required | Possible values    | Description                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `fail` | `string` | false    | `open` or `closed` | `closed` (default): Invalid or unenforceable rules of a policy require approval. `open`: Invalid or unenforceable rules of a policy do not require approval. |

## `policy_tuning`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/498624) support for use in pipeline execution policies in GitLab 17.10 [with a flag](../../../administration/feature_flags.md) named `unblock_rules_using_pipeline_execution_policies`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of support for pipeline execution policies is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

| Field  | Type     | Required | Possible values    | Description                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `unblock_rules_using_execution_policies` | `boolean` | false    | `true`, `false` | When enabled, approval rules do not block merge requests when a scan is required by a scan execution policy or a pipeline execution policy but a required scan artifact is missing from the target branch. This option only works when the project or group has an existing scan execution policy or pipeline execution policy with matching scanners. |

### Examples

#### Example of `policy_tuning` with a scan execution policy

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](security_policy_projects.md):

```yaml
scan_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
approval_policy:
- name: Dependency scanning approvals
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: scan_finding
    scanners:
    - dependency_scanning
    vulnerabilities_allowed: 0
    severity_levels: []
    vulnerability_states: []
    branch_type: protected
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - developer
  - type: send_bot_message
    enabled: true
  fallback_behavior:
    fail: closed
  policy_tuning:
    unblock_rules_using_execution_policies: true
```

#### Example of `policy_tuning` with a pipeline execution policy

{{< alert type="warning" >}}

This feature does not work with pipeline execution policies created before GitLab 17.10.
To use this feature with older pipeline execution policies, copy, delete, and recreate the policies.
For more information, see [Recreate pipeline execution policies created before GitLab 17.10](#recreate-pipeline-execution-policies-created-before-gitlab-1710).

{{< /alert >}}

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](security_policy_projects.md):

```yaml
---
pipeline_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
      ref: main # optional
```

The linked pipeline execution policy CI/CD configuration in `policy-ci.yml`:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
```

##### Recreate pipeline execution policies created before GitLab 17.10

Pipeline execution policies created before GitLab 17.10 do not contain the data required
to use the `policy_tuning` feature. To use this feature with older pipeline execution policies,
copy and delete the old policies, then recreate them.

<i class="fa-youtube-play" aria-hidden="true"></i>
For a video walkthrough, see [Security policies: Recreate a pipeline execution policy for use with `policy_tuning`](https://youtu.be/XN0jCQWlk1A).
<!-- Video published on 2025-03-07 -->

To recreate a pipeline execution policy:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Policies**.
1. Select the pipeline execution policy you want to recreate.
1. On the right sidebar, select the **YAML** tab and copy the contents of the entire policy file.
1. Next to the policies table, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}), and select **Delete**.
1. Merge the generated merge request.
1. Go back to **Secure > Policies** and select **New policy**.
1. In the **Pipeline execution policy** section, select **Select policy**.
1. In the **.YAML mode**, paste the contents of the old policy.
1. Select **Update via merge request** and merge the generated merge request.

## Policy scope schema

To customize policy enforcement, you can define a policy's scope to either include or exclude
specified projects, groups, or compliance framework labels. For more details, see
[Scope](_index.md#scope).

## Example `policy.yml` in a security policy project

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](security_policy_projects.md):

```yaml
---
approval_policy:
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
    vulnerability_states: []
    vulnerability_attributes:
      false_positive: true
      fix_available: true
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
    - detected
    vulnerability_age:
      operator: greater_than
      value: 30
      interval: day
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - owner
    - 1002816 # Example custom role identifier called "AppSec Engineer"
```

In this example:

- Every MR that contains new `critical` vulnerabilities identified by container scanning requires
  one approval from `alberto.dare`.
- Every MR that contains more than one preexisting `low` or `unknown` vulnerability older than 30 days identified by
  container scanning requires one approval from either a project member with the Owner role or a user with the custom role `AppSec Engineer`.

## Example for Merge Request Approval Policy editor

You can use this example in the YAML mode of the [Merge Request Approval Policy editor](#merge-request-approval-policy-editor).
It corresponds to a single object from the previous example:

```yaml
type: approval_policy
name: critical vulnerability CS approvals
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
  vulnerability_states: []
actions:
- type: require_approval
  approvals_required: 1
  user_approvers:
  - adalberto.dare
```

## Understanding merge request approval policy approvals

{{< history >}}

- The branch comparison logic for `scan_finding` was [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/428518) in GitLab 16.8 [with a flag](../../../administration/feature_flags.md) named `scan_result_policy_merge_base_pipeline`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435297) in GitLab 16.9. Feature flag `scan_result_policy_merge_base_pipeline` removed.

{{< /history >}}

### Scope of merge request approval policy comparison

- To determine when approval is required on a merge request, we compare completed pipelines for each supported pipeline source for the source and target branch (for example, `feature`/`main`). This ensures the most comprehensive evaluation of scan results.
- For the source branch, the comparison pipelines are all completed pipelines for each supported pipeline source for the latest commit in the source branch.
- If the merge request approval policy looks only for the newly detected states (`new_needs_triage` & `new_dismissed`), the comparison is performed against all the supported pipeline sources in the common ancestor between the source and the target branch. An exception is when using Merged Results pipelines, in which case the comparison is done against the tip of the MR's target branch.
- If the merge request approval policy looks for pre-existing states (`detected`, `confirmed`, `resolved`, `dismissed`), the comparison is always done against the tip of the default branch (for example, `main`).
- If the merge request approval policy looks for a combination of new and pre-existing vulnerability states, the comparison is done against the common ancestor of the source and target branches.
- Merge request approval policies considers all supported pipeline sources (based on the [`CI_PIPELINE_SOURCE` variable](../../../ci/variables/predefined_variables.md)) when comparing results from both the source and target branches when determining if a merge request requires approval. Pipelines with source `webide` are not supported.
- In GitLab 16.11 and later, the child pipelines of each of the selected pipelines are also considered for comparison.

### Accepting risk and ignoring vulnerabilities in future merge requests

For merge request approval policies that are scoped to newly detected findings (`new_needs_triage` or `new_dismissed` statuses), it's important to understand the implications of this vulnerability state. A finding is considered newly detected if it exists on the merge request's branch but not on the target branch. When a merge request with a branch that contains newly detected findings is approved and merged, approvers are "accepting the risk" of those vulnerabilities. If one or more of the same vulnerabilities is detected after this time, the status would be `detected` and thus ignored by a policy configured to consider `new_needs_triage` or `new_dismissed` findings. For example:

- A merge request approval policy is created to block critical SAST findings. If a SAST finding for CVE-1234 is approved, future merge requests with the same violation will not require approval in the project.

When using `new_needs_triage` and `new_dismissed` vulnerability states, the policy will block MRs for any findings matching policy rules if they are new and not yet triaged, even if they have been dismissed. If you want to ignore vulnerabilities newly detected and then dismissed within the merge request, you may use only the `new_needs_triage` status.

When using license approval policies, the combination of project, component (dependency), and license are considered in the evaluation. If a license is approved as an exception, future merge requests don't require approval for the same combination of project, component (dependency), and license. The component's version is not be considered in this case. If a previously approved package is updated to a new version, approvers will not need to re-approve. For example:

- A license approval policy is created to block merge requests with newly detected licenses matching `AGPL-1.0`. A change is made in project `demo` for component `osframework` that violates the policy. If approved and merged, future merge requests to `osframework` in project `demo` with the license `AGPL-1.0` don't require approval.

### Additional approvals

Merge request approval policies require an additional approval step in some situations. For example:

- The number of security jobs is reduced in the working branch and no longer matches the number of
  security jobs in the target branch. Users can't skip the Scanning Result Policies by removing
  scanning jobs from the CI/CD configuration. Only the security scans that are configured in the
  merge request approval policy rules are checked for removal.

  For example, consider a situation where the default branch pipeline has four security scans:
  `sast`, `secret_detection`, `container_scanning`, and `dependency_scanning`. A merge request approval
  policy enforces two scanners: `container_scanning` and `dependency_scanning`. If an MR removes a
  scan that is configured in merge request approval policy, `container_scanning` for example, an additional
  approval is required.
- Someone stops a pipeline security job, and users can't skip the security scan.
- A job in a merge request fails and is configured with `allow_failure: false`. As a result, the pipeline is in a blocked state.
- A pipeline has a manual job that must run successfully for the entire pipeline to pass.

### Managing scan findings used to evaluate approval requirements

Merge request approval policies evaluate the artifact reports generated by scanners in your pipelines after the pipeline has completed. Merge request approval policies focus on evaluating the results and determining approvals based on the scan result findings to identify potential risks, block merge requests, and require approval.

Merge request approval policies do not extend beyond that scope to reach into artifact files or scanners. Instead, we trust the results from artifact reports. This gives teams flexibility in managing their scan execution and supply chain, and customizing scan results generated in artifact reports (for example, to filter out false positives) if needed.

Lock file tampering, for example, is outside of the scope of security policy management, but may be mitigated through use of [Code owners](../../project/codeowners/_index.md#codeowners-file) or [external status checks](../../project/merge_requests/status_checks.md). For more information, see [issue 433029](https://gitlab.com/gitlab-org/gitlab/-/issues/433029).

![Evaluating scan result findings](img/scan_results_evaluation_white-bg_v16_8.png)

### Filter out policy violations with the attributes "Fix Available" or "False Positive"

To avoid unnecessary approval requirements, these additional filters help ensure you only block MRs on the most actionable findings.

By setting `fix_available` to `false` in YAML, or **is not** and **Fix Available** in the policy editor, the finding is not considered a policy violation when the finding has a solution or remediation available. Solutions appear at the bottom of the vulnerability object under the heading **Solution**. Remediations appear as a **Resolve with Merge Request** button within the vulnerability object.

The **Resolve with Merge Request** button only appears when one of the following criteria is met:

1. A SAST vulnerability is found in a project that is on the Ultimate Tier with GitLab Duo Enterprise.
1. A container scanning vulnerability is found in a project that is on the Ultimate Tier in a job where `GIT_STRATEGY: fetch` has been set. Additionally, the vulnerability must have a package containing a fix that is available for the repositories enabled for the container image.
1. A dependency scanning vulnerability is found in a Node.js project that is managed by yarn and a fix is available. Additionally, the project must be on the Ultimate Tier and FIPS mode must be disabled for the instance.

**Fix Available** only applies to dependency scanning and container scanning.

By using the **False Positive** attribute, similarly, you can ignore findings detected by a policy by setting `false_positive` to `false` (or set attribute to **Is not** and **False Positive** in the policy editor).

The **False Positive** attribute only applies to findings detected by our Vulnerability Extraction Tool for SAST results.

## Troubleshooting

### Merge request rules widget shows a merge request approval policy is invalid or duplicated

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

On GitLab Self-Managed from 15.0 to 16.4, the most likely cause is that the project was exported from a group and imported into another, and had merge request approval policy rules. These rules are stored in a separate project to the one that was exported. As a result, the project contains policy rules that reference entities that don't exist in the imported project's group. The result is policy rules that are invalid, duplicated, or both.

To remove all invalid merge request approval policy rules from a GitLab instance, an administrator can run the following script in the [Rails console](../../../administration/operations/rails_console.md).

```ruby
Project.joins(:approval_rules).where(approval_rules: { report_type: %i[scan_finding license_scanning] }).where.not(approval_rules: { security_orchestration_policy_configuration_id: nil }).find_in_batches.flat_map do |batch|
  batch.map do |project|
    # Get projects and their configuration_ids for applicable project rules
    [project, project.approval_rules.where(report_type: %i[scan_finding license_scanning]).pluck(:security_orchestration_policy_configuration_id).uniq]
  end.uniq.map do |project, configuration_ids| # We take only unique combinations of project + configuration_ids
    # If we find more configurations than what is available for the project, we take records with the extra configurations
    [project, configuration_ids - project.all_security_orchestration_policy_configurations.pluck(:id)]
  end.select { |_project, configuration_ids| configuration_ids.any? }
end.each do |project, configuration_ids|
  # For each found pair project + ghost configuration, we remove these rules for a given project
  Security::OrchestrationPolicyConfiguration.where(id: configuration_ids).each do |configuration|
    configuration.delete_scan_finding_rules_for_project(project.id)
  end
  # Ensure we sync any potential rules from new group's policy
  Security::ScanResultPolicies::SyncProjectWorker.perform_async(project.id)
end
```

### Newly detected CVEs

When using `new_needs_triage` and `new_dismissed`, some findings may require approval when they are not introduced by the merge request (such as a new CVE on a related dependency). These findings will not be present within the MR widget, but will be highlighted in the policy bot comment and pipeline report.

### Policies still have effect after `policy.yml` was manually invalidated

In GitLab 17.2 and earlier, you may find that policies defined in a `policy.yml` file are enforced,
even though the file was manually edited and no longer validates
against the [policy schema](#merge-request-approval-policies-schema). This issue occurs because of
a bug in the policy synchronization logic.

Potential symptoms include:

- `approval_settings` still block the removal of branch protections, block force-pushes or otherwise affect open merge requests.
- `any_merge_request` policies still apply to open merge requests.

To resolve this you can:

- Manually edit the `policy.yml` file that defines the policy so that it becomes valid again.
- Unassign and re-assign the security policy projects where the `policy.yml` file is stored.

### Missing security scans

When using merge request approval policies, you may encounter situations where merge requests are blocked, including in new projects or when certain security scans are not executed. This behavior is by design to reduce the risk of introducing vulnerabilities into your system.

Example scenarios:

- Missing scans on source or target branches

  If security scans are missing on either the source or target branch, GitLab cannot effectively evaluate whether the merge request is introducing new vulnerabilities. In such cases, approval is required as a precautionary measure.

- New projects

  For new projects where security scans have not yet been set up or executed on the target branch, all merge requests require approval. This ensures that security checks are active from the project's inception.

- Projects with no files to scan

  Even in projects that contain no files relevant to the selected security scans, the approval requirement is still enforced. This maintains consistent security practices across all projects.

- First merge request

  The very first merge request in a new project may be blocked if the default branch doesn't have a security scan, even if the source branch has no vulnerabilities.

To resolve these issues:

- Ensure that all required security scans are configured and running successfully on both source and target branches.
- For new projects, set up and run the necessary security scans on the default branch before creating merge requests.
- Consider using scan execution policies or pipeline execution policies to ensure consistent execution of security scans across all branches.
- Consider using [`fallback_behavior`](#fallback_behavior) with `open` to prevent invalid or unenforceable rules in a policy from requiring approval.
- Consider using the [`policy tuning`](#policy_tuning) setting `unblock_rules_using_execution_policies` to address scenarios where security scan artifacts are missing, and scan execution policies are enforced. When enabled, this setting makes approval rules optional when scan artifacts are missing from the target branch and a scan is required by a scan execution policy. This feature only works with an existing scan execution policy that has matching scanners. It offers flexibility in the merge request process when certain security scans cannot be performed due to missing artifacts.

### `Target: none` in security bot comments

If you see `Target: none` in security bot comments, it means GitLab couldn't find a security report for the target branch. To resolve this:

1. Run a pipeline on the target branch that includes the required security scanners.
1. Ensure the pipeline completes successfully and produces security reports.
1. Re-run the pipeline on the source branch. Creating a new commit also triggers the pipeline to re-run

#### Security bot messages

When the target branch has no security scans:

- The security bot may list all vulnerabilities found in the source branch.
- Some of the vulnerabilities might already exist in the target branch, but without a target branch scan, GitLab cannot determine which ones are new.

Potential solutions:

1. **Manual approvals**: Temporarily approve merge requests manually for new projects until security scans are established.
1. **Targeted policies**: Create separate policies for new projects with different approval requirements.
1. **Fallback behavior**: Consider using `fail: open` for policies on new projects, but be aware this may allow users to merge vulnerabilities even if scans fail.

### Support request for debugging of merge request approval policy

GitLab.com users may submit a [support ticket](https://about.gitlab.com/support/) titled "Merge request approval policy debugging". Provide the following details:

- Group path, project path and optionally merge request ID
- Severity
- Current behavior
- Expected behavior

#### GitLab.com

Support teams will investigate [logs](https://log.gprd.gitlab.net/) (`pubsub-sidekiq-inf-gprd*`) to identify the failure `reason`. Below is an example response snippet from logs. You can use this query to find logs related to approvals: `json.event.keyword: "update_approvals"` and `json.project_path: "group-path/project-path"`. Optionally, you can further filter by the merge request identifier using `json.merge_request_iid`:

```json
"json": {
  "project_path": "group-path/project-path",
  "merge_request_iid": 2,
  "missing_scans": [
    "api_fuzzing"
  ],
  "reason": "Scanner removed by MR",
  "event": "update_approvals",
}
```

#### GitLab Self-Managed

Search for keywords such as the `project-path`, `api_fuzzing`, and `merge_request`. Example: `grep group-path/project-path`, and `grep merge_request`. If you know the correlation ID you can search by correlation ID. For example, if the value of `correlation_id` is 01HWN2NFABCEDFG, search for `01HWN2NFABCEDFG`.
Search in the following files:

- `/gitlab/gitlab-rails/production_json.log`
- `/gitlab/sidekiq/current`

Common failure reasons:

- Scanner removed by MR: Merge request approval policy expects that the scanners defined in the policy are present and that they successfully produce an artifact for comparison.

### Inconsistent approvals from merge request approval policies

If you notice any inconsistencies in your merge request approval rules, you can take either of the following steps to resynchronize your policies:

- Unassign and then reassign the security policy project to the affected group or project.
- Alternatively, you can update a policy to trigger that policy to resynchronize for the affected group or project.
- Confirm that the syntax of the YAML file in the security policy project is valid.

These actions help ensure that your merge request approval policies are correctly applied and consistent across all merge requests.

If you continue to experience issues with merge request approval policies after taking these steps, contact GitLab support for assistance.

### Merge requests that fix a detected vulnerability require approval

If your policy configuration includes the `detected` state, merge requests that
fix previously detected vulnerabilities still require approval. The merge request
approval policy evaluates based on vulnerabilities that existed before the changes
in the merge request, which adds an additional layer of review for any changes that affect
known vulnerabilities.

If you want to allow merge requests that fix vulnerabilities to proceed without
any additional approvals due to a detected vulnerability, consider removing the
`detected` state from your policy configuration.
