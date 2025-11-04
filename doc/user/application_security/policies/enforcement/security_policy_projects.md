---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to enforce security rules in GitLab using merge request approval policies to automate scans, approvals, and compliance across your projects.
title: Security policy projects
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Security policy projects enforce policies across multiple projects. A security policy project is a
special type of project used only to contain policies. To enforce the policies contained in a
security policy project, link the security policy project to the projects, subgroups, or groups
you want to enforce the policies on. A security policy project can contain multiple policies but they are
enforced together. A security policy project enforced on a group or subgroup applies to everything
below in the hierarchy, including all subgroups and their projects.

Policy changes made in a merge request take effect as soon as the merge request is merged. Those
that do not go through a merge request, but instead are committed directly to the default branch,
may require up to 10 minutes before the policy changes take effect.

Policies are stored in the `.gitlab/security-policies/policy.yml` YAML file.

## Security policy project implementation

Implementation options for security policy projects differ slightly between GitLab.com, GitLab
Dedicated, and GitLab Self-Managed. The main difference is that on GitLab.com it's only possible to
create subgroups. Ensuring separation of duties requires more granular permission configuration.

### Enforce policies globally in your GitLab.com namespace

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com

{{< /details >}}

Prerequisites:

- You must have the Owner role or a [custom role](../../../custom_roles/_index.md) with the
  `manage_security_policy_link` permission to link to the security policy project. For more
  information, see [separation of duties](_index.md#separation-of-duties).

The high-level workflow for enforcing policies globally across all subgroups and projects in your GitLab.com namespace:

1. Visit the **Policies** tab from your top-level group.
1. In the subgroup, go to the **Policies** tab and create a test policy.

   You can create a policy as disabled for testing. Creating the policy automatically creates
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

   For more granular enforcement, add a policy scope. A policy scope allow you to enforce policies
   against a specific set of projects or against projects containing a set of compliance
   framework labels.
1. If you need additional restrictions, for example to block inherited permissions or require
   additional review or approval of policy changes, you can create an additional policy scoped only
   to your security policy project and enforce additional approvals.

### Enforce policies globally in GitLab Dedicated or GitLab Self-Managed

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

In GitLab Self-Managed, you can also use [compliance and security policy groups](compliance_and_security_policy_groups.md) to enforce security policies across your instance.

{{< /alert >}}

Prerequisites:

- You must have the Owner role or a [custom role](../../../custom_roles/_index.md) with the
  `manage_security_policy_link` permission to link to the security policy project. For more
  information, see [separation of duties](_index.md#separation-of-duties).
- To support approval groups globally across your instance, enable
  `security_policy_global_group_approvers_enabled` in your
  [GitLab instance application settings](../../../../api/settings.md).

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
   name should end with "- security policy project". All linked groups, subgroups, and projects
   become "enforceable" by any policies created in the security policy project. For more information, see
   [link to a security policy project](#link-to-a-security-policy-project).
1. By default, when a policy is enabled, it is enforced on all projects in linked groups, subgroups,
   and projects. For more granular enforcement, add a policy scope. A policy scope allows you to
   enforce policies against a specific set of projects or against projects that contain a set of
   compliance framework labels.
1. If you need additional restrictions, for example to block inherited permissions or require
   additional review or approval of policy changes, you can create an additional policy scoped only
   to your security policy project and enforce additional approvals.

## Link to a security policy project

To enforce the policies contained in a security policy project against a group, subgroup, or
project, you link them. By default, all linked entities are enforced. To enforce policies
granularly per policy, you can set a policy scope in each policy.

Prerequisites:

- You must have the Owner role or [custom role](../../../custom_roles/_index.md) with the`manage_security_policy_link` permission to link to the security policy project. For more information, see [separation of duties](../_index.md#separation-of-duties).

To link a group, subgroup, or project to a security policy project:

1. On the left sidebar, select **Search or go to** and find your project, subgroup, or group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Policies**.
1. Select **Edit Policy Project**, then search for and select the project you would like to link
   from the dropdown list.
1. Select **Save**.

To unlink a security policy project, follow the same steps but instead select the trash can icon in
the dialog.
You can link to a security policy project from a different subgroup in the same top-level group, or from an entirely different top-level group.
However, when you enforce a
[pipeline execution policy](../pipeline_execution_policies.md#schema), users must have at least read-only access to the project that contains the CI/CD configuration referenced in the policy to trigger the pipeline.

### Viewing the linked security policy project

Users with access to the project policy page and aren't project owners instead view a
button linking to the associated security policy project.

You can link a security policy project to more than one group or project. Anyone with permission to view the security policies in one linked group or project can determine which security policies are enforced in other linked groups and project.

## Changing policy limits

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Configurable limits introduced](https://gitlab.com/groups/gitlab-org/-/epics/8084) in GitLab 18.3.

{{< /history >}}

For performance reasons, GitLab limits the number of policies that can be configured in a security policy project.

{{< alert type="warning" >}}

If you reduce the limit below the number of policies currently stored in a security policy project, GitLab does not enforce any policies after the limit. To re-enable the policies, increase the limit to match the number of policies in the largest security policy project.

{{< /alert >}}

The default limits are:

| Policy type                       | Default policy limit   |
| --------------------------------- | ---------------------- |
| Merge request approval policies   | 5                      |
| Scan execution policies           | 5                      |
| Pipeline execution policies       | 5                      |
| Vulnerability management policies | 5                      |

On GitLab Self-Managed instances, instance administrators can adjust the limits for the entire instance, up to a maximum of 20 of each type of policy.
Administrator can also change the limits for a specific top-level group.

### Change the policy limits for an instance

To change the maximum number of policies your organization can store in a security policy project:

1. Go to **Admin Area** > **Settings** > **Security and compliance**.
1. Expand the **Security policies** section.
1. For each type of policy you want to change, set a new value for **Maximum number of {policy type} allowed per security policy configuration**.
1. Select **Save changes**.

#### Change the policy limits for a top-level group

Group limits can exceed the configured or default instance limits. To change the maximum number of policies your organization can store in a security policy project for a top-level group:

{{< alert type="note" >}}

Increasing these limits can affect system performance, especially if you apply a large number of complex policies.

{{< /alert >}}

To adjust the limit for a top-level group:

1. Go to **Admin Area** > **Overview** > **Groups**.
1. In the row of the top-level group you want to modify, select **Edit**.
1. For each type of policy you want to change, set a new value for **Maximum number of {policy type} allowed per security policy configuration**.
1. Select **Save changes**.

If you set the limit for an individual group to `0`, the system uses the instance-wide default value. This ensures that groups with a zero limit can still create policies according to the default instance configuration.

## Delete a security policy project

{{< history >}}

- Deletion protection for security policy projects was introduced in GitLab 17.8 with a flag named `reject_security_policy_project_deletion`. Enabled by default.
- Deletion protection for groups that contain security policy projects was introduced in GitLab 17.9 with a flag named `reject_security_policy_project_deletion_groups`. Enabled by default.
- Deletion protection for security policy projects and groups that contain security policy projects is generally available in GitLab 17.10. Feature flags `reject_security_policy_project_deletion` and `reject_security_policy_project_deletion_groups` removed.

{{< /history >}}

To delete a security policy project or one of its parent groups, you must remove the link to it
from all other projects or groups. Otherwise, an error message is displayed when you attempt
to delete a linked security policy project or a parent group.
