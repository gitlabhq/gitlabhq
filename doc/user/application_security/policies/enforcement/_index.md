---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to apply security policies across multiple groups and projects from a single, centralized location.
title: Policy enforcement
---

You can create a new security policy for each project or group, but duplicating the same policy settings across multiple top-level groups can be time-consuming and present compliance challenges. Before you create a policy, you should know whether the policy should be:

- Enforced on a specific project or group.
- Enforce on multiple projects.
- Enforced across an entire instance or top-level group

You can enforce policies in multiple ways:

- To enforce a policy in a single project or all of the projects in a group, create the policy in that project or group.
- To enforce a policy across multiple projects, use [security policy projects](security_policy_projects.md). A security policy project is a special type of project used only to contain policies. To enforce the policies from a security policy project in other groups and projects, link to the security policy project from groups or other projects.
- To enforce policies and compliance frameworks together across a GitLab Self-Managed instance, instance administrators can use [compliance and security policy management groups](compliance_and_security_policy_groups.md).

## Policy design guidelines

When designing your policies, your goals should be to:

- Design policy enforcement strategies for minimum overhead but maximum coverage
- Ensure separation of duties

### Enforcement

To enforce policies to meet your requirements, consider the following factors:

- **Inheritance**: By default, a policy is enforced on the organizational units it's linked to, and
  all their descendent subgroups and their projects.
- **Scope**: To customize policy enforcement, you can define a policy's scope to match your needs.

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

Policies enforced on an existing group or subgroup are automatically enforced in any new subgroups and projects created under them, provided that:

- The new subgroups and projects are included in the scope definition of the policy (for example, the scope includes all projects in this group).
- The existing group or subgroup is already linked to the security policy project.

{{< alert type="note" >}}

GitLab.com users can enforce policies against their top-level group or across subgroups, but cannot
enforce policies across GitLab.com top-level groups. GitLab Self-Managed administrators can enforce policies
across multiple top-level groups in their instance.

{{< /alert >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135398) in GitLab 16.7 [with a flag](../../../../administration/feature_flags/_index.md) named `security_policies_policy_scope`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/443594) in GitLab 16.11. Feature flag `security_policies_policy_scope` removed.
- Scoping by group [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468384) in GitLab 17.4.

{{< /history >}}

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

## Separation of duties

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
- A [custom role](../../../custom_roles/_index.md) in that group, subgroup, or project with the `manage_security_policy_link` permission.

The Owner role and custom roles with the `manage_security_policy_link` permission follow the standard hierarchy rules across groups, subgroups, and projects:

| Organization unit | Group owner or group `manage_security_policy_link` permission | Subgroup owner or subgroup `manage_security_policy_link` permission | Project owner or project `manage_security_policy_link` permission |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| Group             | {{< yes >}} | {{< no >}}  | {{< no >}} |
| Subgroup          | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Project           | {{< yes >}} | {{< yes >}} | {{< yes >}} |
