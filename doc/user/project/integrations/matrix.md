---
stage: Foundations
group: Personal Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Matrix
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/) in GitLab 17.3.

You can configure GitLab to send notifications to a Matrix room.

## Set up the Matrix integration in GitLab

After you join to a Matrix room, you can configure GitLab to send notifications:

1. To enable the integration:
   - **For your group or project:**
     1. On the left sidebar, select **Search or go to** and find your project or group.
     1. Select **Settings > Integrations**.
   - **For your instance:**
     1. On the left sidebar, at the bottom, select **Admin area**.
     1. Select **Settings > Integrations**.
1. Select **Matrix**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Optional. In **Hostname**, enter the hostname of your server.
1. In **Token**, paste the token value from the Matrix's user.
1. In the **Trigger** section, select the checkboxes for the GitLab events you want to receive in Matrix.
1. In the **Notification settings** section:
   - In **Room identifier**, paste the Matrix room identifier.
   - Optional. Select the **Notify only broken pipelines** checkbox
     to receive notifications for failed pipelines only.
   - Optional. From the **Branches for which notifications are to be sent** dropdown list,
     select the branches you want to receive notifications for.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

The Matrix room can now receive all selected GitLab events.
