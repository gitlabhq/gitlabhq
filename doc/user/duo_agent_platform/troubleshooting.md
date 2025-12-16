---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting the GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

If you are working with the GitLab Duo Agent Platform,
you might encounter the following issues.

## View logs

After a flow is created, you can view the flow's session by going to **Automate** > **Sessions**.

The **Details** tab shows a link to the CI/CD job logs.
These logs can contain troubleshooting information.

## Flows not visible in the UI

If you are trying to run a flow but it's not visible in the GitLab UI:

1. Ensure you have at least Developer role in the project.
1. Ensure GitLab Duo is [turned on and flows are allowed to execute](../gitlab_duo/turn_on_off.md).
1. Ensure the required feature flags are enabled for the flow you're trying to use.
   For the latest flag information, check the documentation history for the feature.

## Session is stuck in created state

If a session for your flow does not start:

- Ensure you're not preventing members from being added to projects.
- Ensure push rules are configured.

### Allow members to be added to projects

Flows that use a [composite identity](security.md) need to add the `@duo-developer`
service account to your project. If your group is restricted, you cannot add users directly to projects,
and your flows will not run.

Prior to running a flow in your project, turn off the setting that
[prevents members from being added to projects]( ../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group).
This step only needs to be done one time, for the first flow to run.
After that, you can turn the setting back on.

### Configure push rules to allow a service account

In the GitLab UI, foundational flows use a service account that:

- Creates commits with its own email address.
- Creates branches with the `workloads/` prefix (for example, `workloads/a1b2c3d4e5f`).

To configure push rules for a project:

1. Find the email address associated with the service account:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. Select **Overview** > **Users** and search for `duo-developer`.
   1. Locate the `duo-developer` user and copy the email address.

1. Allow the email address to push to the project:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Settings** > **Repository**.
   1. Expand **Push rules**.
   1. In **Commit author's email**, add a regular expression that allows the email address you just copied.
   1. Select **Save push rules**.

1. Allow the `workloads/` branch prefix:
   1. In the **Push rules** section, find **Branch name**.
   1. Add a regular expression that allows branches starting with `workloads/`.
      For example: `^workloads/.*$`
   1. Select **Save push rules**.

If you are an administrator, you can create push rules for the instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Push rules**.
1. Follow the previous steps to allow **Commit author's email** and **Branch name**.
1. Select **Save push rules**.
