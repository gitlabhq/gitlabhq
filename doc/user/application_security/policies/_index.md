---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Policies
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Policies provide security and compliance teams with a way to enforce controls globally in
their organization.

Security teams can ensure:

- Security scanners are enforced in development team pipelines with proper configuration.
- All scan jobs execute without any changes or alterations.
- Proper approvals are provided on merge requests, based on results from those findings.
- Vulnerabilities that are no longer detected are resolved automatically, reducing the workload of
  triaging vulnerabilities.

Compliance teams can:

- Centrally enforce multiple approvers on all merge requests
- Enforce various settings on projects in scope of organizational requirements, such as enabling or
  locking merge request and repository settings.

The following policy types are available:

- [Scan execution policy](scan_execution_policies.md). Enforce security scans, either as part of the
  pipeline or on a specified schedule.
- [Merge request approval policy](merge_request_approval_policies.md). Enforce project-level settings and
  approval rules based on scan results.
- [Pipeline execution policy](pipeline_execution_policies.md). Enforce CI/CD jobs as part of project pipelines.
- [Vulnerability management policy](vulnerability_management_policy.md). Automatically resolve
  vulnerabilities that are no longer detected in the default branch.

## Security policy project

A security policy project is a special type of project used only to contain policies. The
policies are stored in the `.gitlab/security-policies/policy.yml` YAML file.

To enforce the policies contained in an security policy project you link it to a project, subgroup,
group, or multiples of each. A security policy project can contain multiple policies but they are
enforced together. A security policy project enforced on a group or subgroup applies to everything
below in the hierarchy, including all subgroups and their projects.

Policy changes made in a merge request take effect as soon as the merge request is merged. Those
that do not go through a merge request, but instead are committed directly to the default branch,
may require up to 10 minutes before the policy changes take effect.

## Deleting security policy projects

> - The deletion protection for security policy projects was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/482967) in GitLab 17.8 [with a flag](../../../administration/feature_flags.md) named `reject_security_policy_project_deletion`. Disabled by default.
> - The deletion protection for groups that contain security policy projects was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/512043) in GitLab 17.9 [with a flag](../../../administration/feature_flags.md) named `reject_security_policy_project_deletion_groups`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

To delete a security policy project or one of its parent groups, you must remove the link to it
from all other projects or groups. Otherwise, an error message is displayed when you attempt
to delete a linked security policy project or a parent group.

## Policy design guidelines

When designing your policies, your goals should be to:

- Design policy enforcement for minimum overhead but maximum coverage
- Ensure separation of duties

### Enforcement

To enforce policies to meet your requirements, consider the following factors:

- **Inheritance:** By default, a policy is enforced on the organizational units it's linked to, and
  all their descendent subgroups and their projects.
- **Scope:** To customize policy enforcement, you can define a policy's scope to match your needs.

#### Inheritance

To maximize policy coverage, link a security policy project to the highest organizational units that
achieves your objectives: groups, subgroups, or projects. A policy is enforced on the organizational
units it's linked to, and all their descendent subgroups and their projects. Enforcement at the
highest point minimizes the number of security policies required, minimizing the management
overhead.

You can use policy inheritance to incrementally roll out policies. For example, when rolling out a
new policy, you can enforce it on a single project, then conduct testing. If the tests pass, you can
then remove it from the project and enforce it on a group, moving up the hierarchy until the policy
is enforced on all applicable projects.

Policies enforced on an existing group or subgroup are automatically enforced in any new subgroups and projects created under them, provided that all of the following are true:

- The new subgroups and projects are included in the scope definition of the policy (for example, the scope includes all projects in this group).
- The existing group or subgroup is already linked to the security policy project.

NOTE:
GitLab.com users can enforce policies against their top-level group or across subgroups, but cannot
enforce policies across GitLab.com top-level groups. GitLab Self-Managed administrators can enforce policies
across multiple top-level groups in their instance.

The following example illustrates two groups and their structure:

- Alpha group contains two subgroups, each of which contains multiple projects.
- Security and compliance group contains two policies.

**Alpha** group (contains code projects)

- **Finance** (subgroup)
  - Project A
  - Accounts receiving (subgroup)
    - Project B
    - Project C
- **Engineering** (subgroup)
  - Project K
  - Project L
  - Project M

**Security and compliance** group (contains security policy projects)

- Security Policy Management
- Security Policy Management - security policy project
  - SAST policy
  - Secret Detection policy

Assuming no policies are enforced, consider the following examples:

- If the "SAST" policy is enforced at group Alpha, it applies to its subgroups, Finance and
  Engineering, and all their projects and subgroups. If the "Secret Detection" policy is enforced
  also at subgroup "Accounts receiving", both policies apply to projects B and C. However, only the
  "SAST" policy applies to project A.
- If the "SAST" policy is enforced at subgroup "Accounts receiving", it applies only to projects B
  and C. No policy applies to project A.
- If the "Secret Detection" policy is enforced at project K, it applies only to project K. No other
  subgroups or projects have a policy apply to them.

#### Scope

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135398) in GitLab 16.7 [with a flag](../../../administration/feature_flags.md) named `security_policies_policy_scope`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/443594) in GitLab 16.11. Feature flag `security_policies_policy_scope` removed.
> - Scoping by group [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468384) in GitLab 17.4.

You can refine a policy's scope by:

- Compliance frameworks: Enforce a policy on projects with selected compliance frameworks.
- Group:
  - All projects in a group, including all its descendent subgroups and their projects. Optionally
    exclude specific projects.
  - All projects in multiple groups, including their descendent subgroups and their projects. Only
    groups linked to the same security policy project can be listed in the policy. Optionally
    exclude specific projects.
- Projects: Include or exclude specific projects. Only projects linked to the same security policy
  project can be listed in the policy.

These options can be used together in the same policy. However, exclusion takes precedence over
inclusion.

##### `policy_scope` keyword

Use the `policy_scope` keyword to enforce the policy on only those groups, projects, compliance
frameworks, or a combination, that you specify.

| Field                   | Type     | Possible values          | Description |
|-------------------------|----------|--------------------------|-------------|
| `compliance_frameworks` | `array`  | Not applicable           | List of IDs of the compliance frameworks in scope for enforcement, in an array of objects with key `id`. |
| `projects`              | `object` | `including`, `excluding` | Use `excluding:` or `including:` then list the IDs of the projects you wish to include or exclude, in an array of objects with key `id`. |
| `groups`                | `object` | `including`              | Use `including:` then list the IDs of the groups you wish to include, in an array of objects with key `id`. Only groups linked to the same security policy project can be listed in the policy. |

##### Scope examples

In this example, the scan execution policy enforces a SAST scan in every release pipeline, on
every project with the compliance frameworks with an ID either `2` or `11` applied to them.

```yaml
---
scan_execution_policy:
- name: Enforce specified scans in every release pipeline
  description: This policy enforces a SAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: sast
  policy_scope:
    compliance_frameworks:
      - id: 2
      - id: 11
```

In this example, the scan execution policy enforces a secret detection and SAST scan on pipelines
for the default branch, on all projects in the group with ID `203` (including all descendent
subgroups and their projects), excluding the project with ID `64`.

```yaml
- name: Enforce specified scans in every default branch pipeline
  description: This policy enforces Secret Detection and SAST scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
  policy_scope:
    groups:
      including:
        - id: 203
    projects:
      excluding:
        - id: 64
```

### Separation of duties

Separation of duties is vital to successfully implementing policies. Implement policies that achieve
the necessary compliance and security requirements, while allowing development teams to achieve
their goals.

Security and compliance teams:

- Should be responsible for defining policies and working with development teams to ensure the
  policies meet their needs.

Development teams:

- Should not be able to disable, modify, or circumvent the policies in any way.

To enforce a security policy project on a group, subgroup, or project, you must have either:

- The Owner role in that group, subgroup, or project.
- A [custom role](../../custom_roles.md) in that group, subgroup, or project with the `manage_security_policy_link` permission.

The Owner role and custom roles with the `manage_security_policy_link` permission follow the standard hierarchy rules across groups, subgroups, and projects:

| Organization unit | Group owner or group `manage_security_policy_link` permission | Subgroup owner or subgroup `manage_security_policy_link` permission | Project owner or project `manage_security_policy_link` permission |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| Group             | **{check-circle}** Yes                                        | **{dotted-circle}** No                                              | **{dotted-circle}** No                                            |
| Subgroup          | **{check-circle}** Yes                                        | **{check-circle}** Yes                                              | **{dotted-circle}** No                                            |
| Project           | **{check-circle}** Yes                                        | **{check-circle}** Yes                                              | **{check-circle}** Yes                                            |

#### Required permissions

To create and manage security policies:

- For policies enforced on groups: You must have at least the Maintainer role for the group.
- For policies enforced on projects:
  - You must be the project owner.
  - You must be a group member with permissions to create projects in the group.

NOTE:
If you're not a group member, you may face limitations in adding or editing policies for your project. The ability to create and manage policies requires permissions to create projects in the group. Make sure you have the required permissions in the group, even when working with project-level policies.

## Policy implementation

Implementation options for security policy projects differ slightly between GitLab.com, GitLab
Dedicated, and GitLab Self-Managed. The main difference is that on GitLab.com it's only possible to
create subgroups. Ensuring separation of duties requires more granular permission configuration.

### Enforce policies globally in your GitLab.com namespace

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

Prerequisites:

- You must have the Owner role or [custom role](../../custom_roles.md) with the
  `manage_security_policy_link` permission to link to the security policy project. For more
  information, see [separation of duties](#separation-of-duties).

The high-level workflow for enforcing policies globally across all subgroups and projects in your GitLab.com namespace:

1. Visit the **Policies** tab from your top-level group.
1. In the subgroup, go to the **Policies** tab and create a test policy.

   (Tip: You can create a policy as disabled for testing.) Creating the policy automatically creates
   a new security policy project under your top-level group. This project is used to store your
   `policy.yml` or policy-as-code.
1. Check and set permissions in the newly created project as desired.

   By default, Owners and Maintainers are able to create, edit, and delete policies. Developers can
   propose policy changes but cannot merge them.
1. In the security policy project created within your subgroup, create the policies required.

   You can use the policy editor in the `Security Policy Management` project you created, under the
   **Policies** tab. Or you can directly update the policies in the `policy.yml` file stored in the
   newly-created security policy project `Security Policy Management - security policy project`.
1. Link up groups, subgroups, or projects to the security policy project.

   As a subgroup owner, or project owner with proper permissions, you can visit the **Policies**
   page and create a link to the security policy project. Include the full path and the project's
   name should end with "- security policy project". All linked groups, subgroups, and projects
   become "enforceable" by any policies created in the security policy project. For details, see
   [Link to a security policy project](#link-to-a-security-policy-project).
1. By default, when a policy is enabled, it is enforced on all projects in linked groups,
   subgroups, and projects.

   For more granular enforcement, add a "policy scope". Policy scopes allow you to enforce policies
   against a specific set of projects or against projects containing a given set of compliance
   framework labels.
1. If you need additional restrictions, for example to block inherited permissions or require
   additional review or approval of policy changes, you can create an additional policy scoped only
   to your security policy project and enforce additional approvals.

### Enforce policies globally in GitLab Dedicated or GitLab Self-Managed

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Prerequisites:

- You must have the Owner role or [custom role](../../custom_roles.md) with the
  `manage_security_policy_link` permission to link to the security policy project. For more
  information, see [separation of duties](#separation-of-duties).
- To support approval groups globally across your instance, enable
  `security_policy_global_group_approvers_enabled` in your
  [GitLab instance application settings](../../../api/settings.md).

The high-level workflow for enforcing policies across multiple groups:

1. Create a separate group to contain your policies and ensure separation of duties.

   By creating a separate standalone group, you can minimize the number of users who inherit
   permissions.
1. In the new group, visit the **Policies** tab.

   This serves as the primary location of the policy editor, allowing you to
   create and manage policies in the UI.
1. Create a test policy (you can create a policy as disabled for testing).

   Creating the policy automatically creates a new security policy project under your group. This
   project is used to store your `policy.yml` or policy-as-code.
1. Check and set permissions in the newly created project as desired.

   By default, Owners and Maintainers are able to create, edit, and delete policies. Developers can
   propose policy changes but cannot merge them.
1. In the security policy project created in your subgroup, create the policies required.

   You can use the policy editor in the `Security Policy Management` project you created, under the
   Policies tab. Or you can directly update the policies in the `policy.yml` file stored in the
   newly-created security policy project `Security Policy Management - security policy project`.
1. Link up groups, subgroups, or projects to the security policy project.

   As a subgroup owner, or project owner with proper permissions, you can visit the **Policies**
   page and create a link to the security policy project. Include the full path and the project's
   name should end with "-security policy project". All linked groups, subgroups, and projects
   become "enforceable" by any policies created in the security policy project. For more information, see
   [link to a security policy project](#link-to-a-security-policy-project).
1. By default, when a policy is enabled, it is enforced on all projects in linked groups, subgroups,
   and projects. For more granular enforcement, add a policy scope. Policy scopes allow you to
   enforce policies against a specific set of projects or against projects containing a given set of
   compliance framework labels.
1. If you need additional restrictions, for example to block inherited permissions or require
   additional review or approval of policy changes, you can create an additional policy scoped only
   to your security policy project and enforce additional approvals.

## Link to a security policy project

To enforce the policies contained in a security policy project against a group, subgroup, or
project, you link them. By default, all linked entities are enforced. To enforce policies
granularly per policy, you can set a "policy scope" in each policy.

Prerequisites:

- You must have the Owner role or [custom role](../../custom_roles.md) with the`manage_security_policy_link` permission to link to the security policy project. For more information, see [separation of duties](#separation-of-duties).

To link a group, subgroup, or project to a security policy project:

1. On the left sidebar, select **Search or go to** and find your project, subgroup, or group.
1. Select **Secure > Policies**.
1. Select **Edit Policy Project**, then search for and select the project you would like to link
   from the dropdown list.
1. Select **Save**.

To unlink a security policy project, follow the same steps but instead select the trash can icon in
the dialog.
You can link to a security policy project from a different subgroup in the same top-level group, or from an entirely different top-level group.
However, when you enforce a
[pipeline execution policy](../policies/pipeline_execution_policies.md#pipeline-execution-policy-schema), users must have at least read-only access to the project that contains the CI/CD configuration referenced in the policy to trigger the pipeline.

### Viewing the linked security policy project

All users who have access to the project policy page and are not project owners instead view a
button linking out to the associated security policy project.

## Policy recommendations

When implementing policies, consider the following recommendations.

### Branch names

When specifying branch names in a policy, use a generic category of protected branches, such as
**default branch** or **all protected branches**, not individual branch names.

A policy is enforced on a project only if the specified branch exists in that project. For example,
if your policy enforces rules on branch `main` but some projects in scope are using `production` as
their default branch, the policy is not applied for the latter.

### Push rules

In GitLab 17.3 and earlier, if you use push rules to
[validate branch names](../../project/repository/push_rules.md#validate-branch-names)
ensure they allow creation of branches with the prefix `update-policy-`. This branch naming prefix
is used when a security policy is created or amended. For example, `update-policy-1659094451`, where
`1659094451` is the timestamp. If push rules block the creation of the branch the following error
occurs:

> Branch name `update-policy-<timestamp>` does not follow the pattern `<branch_name_regex>`.

In [GitLab 17.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/463064), security policy
projects are excluded from push rules that enforce branch name validation.

## Policy management

The Policies page displays deployed policies for all available environments. You can check a
policy's information (for example, description or enforcement status), and create and edit deployed
policies:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Policies**.

![Policies List Page](img/policies_list_v17_7.png)

A green checkmark in the first column indicates that the policy is enabled and enforced on all groups and projects within its scope. A gray checkmark indicates that the policy is currently not enabled.

## Policy editor

Use the policy editor to create, edit, and delete policies:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Policies**.
   - To create a new policy, select **New policy** which is located in the **Policies** page's header.
     You can then select which type of policy to create.
   - To edit an existing policy, select **Edit policy** in the selected policy drawer.

   The policy editor has two modes:

   - The visual _Rule_ mode allows you to construct and preview policy
     rules using rule blocks and related controls.

     ![Policy Editor Rule Mode](img/policy_rule_mode_v15_9.png)

   - YAML mode allows you to enter a policy definition in `.yaml` format
     and is aimed at expert users and cases that the Rule mode doesn't
     support.

     ![Policy Editor YAML Mode](img/policy_yaml_mode_v15_9.png)

     You can use both modes interchangeably and switch between them at any time. If a YAML resource
     is incorrect or contains data not supported by the Rule mode, Rule mode is automatically
     disabled. If the YAML is incorrect, you must use YAML mode to fix your policy before Rule mode
     is available again.

1. Select **Configure with a merge request** to save and apply the changes.

   The policy's YAML is validated and any resulting errors are displayed.

1. Review and merge the resulting merge request.

   If you are a project owner and a security policy project is not associated with this project,
   a security policy project is created and linked to this project when the merge request is created.

## Troubleshooting

When working with security policies, consider these troubleshooting tips:

- You should not link a security policy project to both a development project and the group or
  subgroup the development project belongs to. Linking this way results in approval
  rules from the merge request approval policies not being applied to merge requests in the development project.
- When creating a merge request approval policy, neither the array `severity_levels` nor the array
  `vulnerability_states` in the [`scan_finding` rule](../policies/merge_request_approval_policies.md#scan_finding-rule-type)
  can be left empty. For a working rule, at least one entry must exist for each array.
- The owner of a project can enforce policies for that project, provided they also have permissions to create projects in the group.
  Project owners who are not group members may face limitations in adding or editing policies. If you're unable to manage policies for your project,
  contact your group administrator to ensure you have the necessary permissions in the group.

If you are still experiencing issues, you can [view recent reported bugs](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=popularity&state=opened&label_name%5B%5D=group%3A%3Asecurity%20policies&label_name%5B%5D=type%3A%3Abug&first_page_size=20) and raise new unreported issues.
