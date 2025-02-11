---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External issue trackers
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab has its own [issue tracker](../user/project/issues/_index.md),
but you can also configure an external issue tracker per GitLab project.
You can then use:

- The external issue tracker with the GitLab issue tracker
- The external issue tracker only

With an external tracker, you can use the format `CODE-123` to mention
external issues in GitLab merge requests, commits, and comments where:

- `CODE` is a unique code for the tracker.
- `123` is the issue number in the tracker.

References are displayed as issue links.

## Disable the GitLab issue tracker

To disable the GitLab issue tracker for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Issues**, turn off the toggle.
1. Select **Save changes**.

After you disable the GitLab issue tracker:

- If an [external issue tracker is configured](#configure-an-external-issue-tracker),
  **Issues** is visible on the left sidebar but redirects to the external issue tracker.
- If no external issue tracker is configured, **Issues** is not visible on the left sidebar.

## Configure an external issue tracker

You can configure any of the following external issue trackers:

- [Bugzilla](../user/project/integrations/bugzilla.md)
- [ClickUp](../user/project/integrations/clickup.md)
- [Custom issue tracker](../user/project/integrations/custom_issue_tracker.md)
- [Engineering Workflow Management (EWM)](../user/project/integrations/ewm.md)
- [Jira](jira/_index.md)
- [Phorge](../user/project/integrations/phorge.md)
- [Redmine](../user/project/integrations/redmine.md)
- [YouTrack](../user/project/integrations/youtrack.md)
