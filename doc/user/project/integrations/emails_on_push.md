---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Emails on push **(FREE)**

When you enable emails on push, you receive email notifications for every change
that is pushed to your project.

To enable emails on push:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Emails on push**.
1. In the **Recipients** section, provide a list of emails separated by spaces or newlines.
1. Configure the following options:

   - **Push events** - Email is triggered when a push event is received.
   - **Tag push events** - Email is triggered when a tag is created and pushed.
   - **Send from committer** - Send notifications from the committer's email address if the domain matches the domain used by your GitLab instance (such as `user@gitlab.com`).
   - **Disable code diffs** - Don't include possibly sensitive code diffs in notification body.

| Settings | Notification |
| --- | --- |
| ![Email on push service settings](img/emails_on_push_service_v13_11.png) | ![Email on push notification](img/emails_on_push_email.png) |
