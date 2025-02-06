---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipeline status emails
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can send notifications about pipeline status changes in a group or
project to a list of email addresses.

## Enable pipeline status email notifications

To enable pipeline status emails:

1. In your project or group, on the left sidebar, select **Settings > Integrations**.
1. Select **Pipeline status emails**.
1. Ensure the **Active** checkbox is selected.
1. In **Recipients**, enter a comma-separated list of email addresses.
1. Optional. To receive notifications for broken pipelines only, select
   **Notify only broken pipelines**.
1. Select the branches to send notifications for.
1. Select **Save changes**.

In [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89546)
and later, pipeline notifications triggered by blocked users are not delivered.
