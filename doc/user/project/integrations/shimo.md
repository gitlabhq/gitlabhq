---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<!--- start_remove The following content will be removed on remove_date: '2023-08-22' -->

# Shimo (deprecated) **(FREE)**

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/377824) in GitLab 15.7
and is planned for removal in 16.0.
This change is a breaking change.

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343386) in GitLab 14.5 with a feature flag named `shimo_integration`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/345356) in GitLab 15.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/345356) in GitLab 15.4. [Feature flag `shimo_integration`](https://gitlab.com/gitlab-org/gitlab/-/issues/345356) removed.

[Shimo](https://shimo.im/) is a productivity suite that includes documents, spreadsheets, and slideshows in one interface. With this integration, you can use the Shimo Wiki directly within GitLab instead of the [GitLab group/project wiki](../wiki/index.md).

## Configure settings in GitLab

To enable the Shimo integration for your group or project:

1. On the top bar, select **Main menu** and find your group or project.
1. On the left sidebar, select **Settings > Integrations**.
1. In **Add an integration**, select **Shimo**.
1. In **Enable integration**, ensure the **Active** checkbox is selected.
1. Provide the **Shimo Workspace URL** you want to link to your group or project (for example, `https://shimo.im/space/aBAYV6VvajUP873j`).
1. Select **Save changes**.

On the left sidebar, **Shimo** now appears instead of **Wiki**.

## View the Shimo Workspace

To view the Shimo Workspace from your group or project:

1. On the top bar, select **Main menu** and find your group or project.
1. On the left sidebar, select **Shimo**.
1. On the **Shimo Workspace** page, select **Go to Shimo Workspace**.

<!--- end_remove -->
