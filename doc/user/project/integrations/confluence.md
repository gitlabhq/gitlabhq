---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Confluence Workspace
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use a Confluence Cloud Workspace as your project wiki.

This integration adds a link to a Confluence wiki instead of the [GitLab wiki](../wiki/_index.md).
Any content you have in Confluence is not displayed in GitLab.

When you turn on the integration:

- A new menu item is added to the left sidebar: **Plan > Confluence**.
  It links to your Confluence wiki.
- The **Plan > Wiki** menu item is hidden.

  To access the GitLab wiki for the project, use its URL:
`<example_project_URL>/-/wikis/home`.
  To bring back the **Plan > Wiki** menu item, turn off this integration.

Creating a more comprehensive integration with Confluence Cloud is tracked in
[epic 3629](https://gitlab.com/groups/gitlab-org/-/epics/3629).

## Set up the integration

This integration can be turned on for a project or for all projects in a group or instance.

### For your project or all projects in a group

Prerequisites:

- You must have at least the Maintainer role for the project.
- You must use a Confluence Cloud URL (`https://example.atlassian.net/wiki/`).

To set up the integration for your project or group:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Integrations**.
1. Next to **Confluence Workspace**, select **Configure**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **Confluence Workspace URL**, enter your Confluence Workspace URL.
1. Select **Save changes**.

If the integration has been turned on for the group, you can still turn it off for individual projects.

### For all projects on the instance

DETAILS:
**Offering:** GitLab Self-Managed

Prerequisites:

- You must have administrator access to the instance.
- You must use a Confluence Cloud URL (`https://example.atlassian.net/wiki/`).

To set up the integration for your instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Integrations**.
1. Next to **Confluence Workspace**, select **Configure**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **Confluence Workspace URL**, enter your Confluence Workspace URL.
1. Select **Save changes**.

## Access your Confluence Workspace from GitLab

Prerequisites:

- You must set up the integration [for your project, group](#for-your-project-or-all-projects-in-a-group),
  or [for your instance](#for-all-projects-on-the-instance).

To access your Confluence Workspace from a GitLab project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Confluence**.
1. Select **Go to Confluence**.
