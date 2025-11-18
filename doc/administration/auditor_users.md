---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auditor users
description: Provide read-only access for auditing and compliance monitoring across all resources.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Auditor users have read-only access to all groups, projects, and other resources in the instance.

Auditor users:

- Have read-only access to all groups and projects.
  - Due to a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/542815), users must have at least the Reporter role to perform read-only tasks.
- Can have additional [permissions](../user/permissions.md) to groups and projects based on their assigned role.
- Can create groups, projects, or snippets in their personal namespace.
- Cannot view the Admin area or perform any administration actions.
- Cannot access group or projects settings.
- Cannot view job logs when [debug logging](../ci/variables/variables_troubleshooting.md#enable-debug-logging) is enabled.
- Cannot access areas designed for editing, including the [pipeline editor](../ci/pipeline_editor/_index.md).

Auditor users are sometimes used in situations where:

- An organization needs to test security policy compliance across an entire GitLab instance.
  An auditor user can do this without being added to every project or given administrator access.
- A specific user needs to view a large number of projects in the GitLab instance. Instead of
  manually adding the user to every project, you can create an auditor user that can access
  every project automatically.

{{< alert type="note" >}}

An auditor user counts as a billable user and consumes a license seat.

{{< /alert >}}

## Create an auditor user

To create a new auditor user:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Overview** > **Users**.
1. Select **New user**.
1. In the **Account** section, enter the required account information.
1. For **User type**, select **Auditor**.
1. Select **Create user**.

You can also create auditor users with:

- [SAML groups](../integration/saml.md#auditor-groups).
- The [users API](../api/users.md).
