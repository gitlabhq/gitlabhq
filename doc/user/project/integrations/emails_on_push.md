---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Emails on push
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use emails on push to receive email notifications for changes pushed to your GitLab project.
You can select the push events that trigger these notifications.

With emails on push, you can specify a list of email addresses to receive commits and diffs for each push.

## Set up the integration

Prerequisites:

- You must have at least the Maintainer role for the project.

To set up emails on push:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select **Emails on push**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **Recipients**, enter a list of email addresses separated by spaces or newlines.
   Invalid email addresses are automatically filtered out and do not receive notifications.
1. Configure the following options:

   - **Push events** - Email is triggered when a push event is received.
   - **Tag push events** - Email is triggered when a tag is created and pushed.
   - **Send from committer** - Send notifications from the committer's email address if the domain matches the domain used by your GitLab instance (such as `user@gitlab.com`).
   - **Disable code diffs** - Don't include possibly sensitive code diffs in notification body.
