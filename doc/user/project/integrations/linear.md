---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linear
description: Configure the Linear integration to link a GitLab project to a Linear workspace and reference Linear issues in GitLab.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297) in GitLab 18.3.

{{< /history >}}

You can use [Linear](https://linear.app/) as an
[external issue tracker](../../../integration/external-issue-tracker.md).
To turn on the Linear integration in a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **Linear**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Fill in the required fields:

   - **Workspace URL**: The URL to the Linear workspace project to link to this GitLab project.

1. Optional. Select **Test settings**.
1. Select **Save changes**.

After you configure and turn on Linear, a link appears on the GitLab project pages.
The link directs you to your Linear workspace.

For example, this is a configuration for a workspace named `example`:

- Workspace URL: `https://linear.app/example`

You can also turn off [GitLab internal issue tracking](../issues/_index.md) in this project.
For more information about the steps and consequences of turning off GitLab issues, see:

- [Change project visibility](../../public_access.md#change-project-visibility).
- [Configure project features and permissions](../settings/_index.md#configure-project-features-and-permissions).

## Reference Linear issues in GitLab

You can reference your Linear issues using:

- `<TEAM>-<ID>`, for example `API-123`, where:
  - `<TEAM>` is a team identifier.
  - `<ID>` is a number.
