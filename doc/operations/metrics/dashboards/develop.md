---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Developing templates for custom dashboards (DEPRECATED) **(FREE)**

> [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/346541) in GitLab 14.7.

WARNING:
This feature is in its end-of-life process. It is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/346541)
for use in GitLab 14.7, and is planned for removal in GitLab 15.0.

GitLab provides a template to make it easier for you to create templates for
[custom dashboards](index.md). Templates provide helpful guidance and
commented-out examples you can use.

## Apply a dashboard template

Navigate to the browser-based editor of your choice:

- In the **Repository view**:

  1. Navigate to **{doc-text}** **Repository > Files**.
  1. Click **{plus}** **Add to tree** and select **New file**,
     then click **Select a template type** to see a list of available templates:
     ![Metrics dashboard template selection](img/metrics_dashboard_template_selection_v13_3.png)

- In the **[Web IDE](../../../user/project/web_ide/index.md)**:

  1. Click **Web IDE** when viewing your repository.
  1. Click **{doc-new}** **New file**, then click **Choose a template** to see a list of available templates:
     ![Metrics dashboard template selection WebIDE](img/metrics_dashboard_template_selection_web_ide_v13_3.png)

## Custom dashboard templates **(PREMIUM SELF)**

To enable and use a custom dashboard templates on your GitLab instance, read the
[guide for creating custom templates](../../../user/admin_area/settings/instance_template_repository.md).
