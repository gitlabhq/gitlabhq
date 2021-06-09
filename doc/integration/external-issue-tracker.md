---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# External issue tracker **(FREE)**

GitLab has a great [issue tracker](../user/project/issues/index.md) but you can also use an external
one. External issue trackers are configurable per GitLab project.

Once configured, you can reference external issues using the format `CODE-123`, where:

- `CODE` is a unique code for the tracker.
- `123` is the issue number in the tracker.

These references in GitLab merge requests, commits, or comments are automatically converted to links to the issues.

You can keep the GitLab issue tracker enabled in parallel or disable it. When enabled, the **Issues** link in the
GitLab menu always opens the internal issue tracker. When disabled, the link is not visible in the menu.

## Configuration

The configuration is done via a project's **Settings > Integrations**.

### Integration

To enable an external issue tracker you must configure the appropriate **Integration**.
Visit the links below for details:

- [Bugzilla](../user/project/integrations/bugzilla.md)
- [Custom Issue Tracker](../user/project/integrations/custom_issue_tracker.md)
- [Engineering Workflow Management](../user/project/integrations/ewm.md)
- [Jira](../integration/jira/index.md)
- [Redmine](../user/project/integrations/redmine.md)
- [YouTrack](../user/project/integrations/youtrack.md)
