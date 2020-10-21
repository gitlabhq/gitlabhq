---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Project integration management

Project integrations can be configured and enabled by project administrators. As a GitLab instance
administrator, you can set default configuration parameters for a given integration that all projects
can inherit and use. This enables the integration for all projects that are not already using custom
settings.

You can update these default settings at any time, changing the settings used for all projects that
are set to use instance-level defaults. Updating the default settings also enables the integration
for all projects that didn't have it already enabled.

Only the complete settings for an integration can be inherited. Per-field inheritance is
[planned](https://gitlab.com/groups/gitlab-org/-/epics/2137) as is
[group-level management](https://gitlab.com/groups/gitlab-org/-/epics/2543) of integration settings.

## Manage instance-level default settings for a project integration **(CORE ONLY)**

> [Introduced in](https://gitlab.com/groups/gitlab-org/-/epics/2137) GitLab 13.3.

1. Navigate to **Admin Area > Settings > Integrations**.
1. Select a project integration.
1. Enter configuration details and click **Save changes**.

CAUTION: **Caution:**
This may affect all or most of the projects on your GitLab instance. Please review the details
below.

If this is the first time you are setting up instance-level settings for an integration:

- The integration is enabled for all projects that don't already have this integration configured,
  if you have the **Enable integration** toggle turned on in the instance-level settings.
- Projects that already have the integration configured are not affected, but can choose to use the
  inherited settings at any time.

When you make further changes to the instance defaults:

- They are immediately applied to all projects that have the integration set to use default settings.
- They are immediately applied to newer projects, created since you last saved defaults for the
  integration. If your instance-level default setting has the **Enable integration** toggle turned
  on, the integration is automatically enabled for all such projects.
- Projects with custom settings selected for the integration are not immediately affected and may
  choose to use the latest defaults at any time.

Only the complete settings for an integration can be inherited. Per-field inheritance
is [planned](https://gitlab.com/groups/gitlab-org/-/epics/2137). This would allow
administrators to update settings inherited by projects without enabling the
integration on all non-configured projects by default.

## Use instance-level default settings for a project integration

1. Navigate to **Project > Settings > Integrations**.
1. Choose the integration you want to enable or update.
1. From the drop-down, select **Use default settings**.
1. Ensure the toggle is set to **Enable integration**.
1. Click **Save changes**.

## Use custom settings for a project integration

1. Navigate to project's **Settings > Integrations**.
1. Choose the integration you want to enable or update.
1. From the drop-down, select **Use custom settings**.
1. Ensure the toggle is set to **Enable integration** and enter all required settings.
1. Click **Save changes**.
