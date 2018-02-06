# External issue tracker

GitLab has a great issue tracker but you can also use an external one such as
Jira, Redmine, or Bugzilla. Issue trackers are configurable per GitLab project and allow
you to do the following:

- you can reference these external issues inside GitLab interface
  (merge requests, commits, comments) and they will be automatically converted
  into links

You can have enabled both external and internal GitLab issue trackers in parallel. The **Issues** link always opens the internal issue tracker and in case the internal issue tracker is disabled the link is not visible in the menu.

## Configuration

The configuration is done via a project's **Services**.

### Project Service

To enable an external issue tracker you must configure the appropriate **Service**.
Visit the links below for details:

- [Redmine](../user/project/integrations/redmine.md)
- [Jira](../user/project/integrations/jira.md)
- [Bugzilla](../user/project/integrations/bugzilla.md)
- [Custom Issue Tracker](../user/project/integrations/custom_issue_tracker.md)

### Service Template

To save you the hassle from configuring each project's service individually,
GitLab provides the ability to set Service Templates which can then be
overridden in each project's settings.

Read more on [Services Templates](../user/project/integrations/services_templates.md).
