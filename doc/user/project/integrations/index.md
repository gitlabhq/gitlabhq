---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project integrations **(FREE)**

You can find the available integrations under your project's
**Settings > Integrations** page. You need to have at least
the [Maintainer role](../../permissions.md) on the project.

## Integrations

Like plugins, integrations allow you to integrate GitLab with other applications, adding additional features.
For more information, read the
[overview of integrations](overview.md) or learn how to manage your integrations:

- *For GitLab 13.3 and later,* read [Project integration management](../../admin_area/settings/project_integration_management.md).
- *For GitLab 13.2 and earlier,* read [Service Templates](services_templates.md),
  which are deprecated and [scheduled to be removed](https://gitlab.com/gitlab-org/gitlab/-/issues/268032)
  in GitLab 14.0.

## Project webhooks

Project webhooks allow you to trigger a URL if for example new code is pushed or
a new issue is created. You can configure webhooks to listen for specific events
like pushes, issues or merge requests. GitLab sends a POST request with data
to the webhook URL.

Learn more [about webhooks](webhooks.md).
