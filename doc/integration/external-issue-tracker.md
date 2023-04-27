---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# External issue trackers **(FREE)**

GitLab has an [issue tracker](../user/project/issues/index.md), but you can
configure an external issue tracker per GitLab project.

After you configure the external tracker, you can reference external issues
in GitLab merge requests, commits, and comments
using the format `CODE-123`, where:

- `CODE` is a unique code for the tracker.
- `123` is the issue number in the tracker.

The references are automatically converted to links to the issues.

You can keep the GitLab issue tracker enabled in parallel or disable it. When enabled, the **Issues** link in the
GitLab menu always opens the internal issue tracker. When disabled, the link is not visible in the menu.

## Configure an external issue tracker

To enable an external issue tracker, you must configure the appropriate [integration](../user/project/integrations/index.md).

The following external issue tracker integrations are available:

- [Bugzilla](../user/project/integrations/bugzilla.md)
- [Custom Issue Tracker](../user/project/integrations/custom_issue_tracker.md)
- [Engineering Workflow Management](../user/project/integrations/ewm.md)
- [Jira](../integration/jira/index.md)
- [Redmine](../user/project/integrations/redmine.md)
- [YouTrack](../user/project/integrations/youtrack.md)
- [ZenTao](../user/project/integrations/zentao.md)
