---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Shimo (deprecated) **(FREE ALL)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343386) in GitLab 14.5 [with a flag](../../../administration/feature_flags.md) named `shimo_integration`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/345356) in GitLab 15.4. Feature flag `shimo_integration` removed.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/377824) in GitLab 15.7.
This change is a breaking change.

[Shimo](https://shimo.im/) is a productivity suite that includes documents, spreadsheets, and slideshows in one interface.
With this integration, you can use the Shimo wiki directly in GitLab instead of the [GitLab group or project wiki](../wiki/index.md).

## Configure settings in GitLab

To enable the Shimo integration for your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Shimo**.
1. Under **Enable integration**, ensure the **Active** checkbox is selected.
1. Provide the **Shimo Workspace URL** you want to link to your group or project (for example, `https://shimo.im/space/aBAYV6VvajUP873j`).
1. Select **Save changes**.

On the left sidebar, **Shimo** now appears instead of **Wiki**.

## View the Shimo Workspace

To view the Shimo Workspace from your group or project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Shimo**.
1. On the **Shimo Workspace** page, select **Go to Shimo Workspace**.
