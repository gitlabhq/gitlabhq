---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project integrations

You can find the available integrations under your project's
**Settings > Integrations** page. You need to have at least
[maintainer permission](../../permissions.md) on the project.

## Integrations

Integrations allow you to integrate GitLab with other applications.
They are a bit like plugins in that they allow a lot of freedom in
adding functionality to GitLab.

Learn more [about integrations](overview.md).

## Project webhooks

Project webhooks allow you to trigger a URL if for example new code is pushed or
a new issue is created. You can configure webhooks to listen for specific events
like pushes, issues or merge requests. GitLab sends a POST request with data
to the webhook URL.

Learn more [about webhooks](webhooks.md).
