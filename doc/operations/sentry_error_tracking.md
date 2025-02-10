---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sentry error tracking
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[Sentry](https://sentry.io/) is an open source error tracking system. GitLab enables
administrators to connect Sentry to GitLab, so users can view a list of Sentry errors in GitLab.

GitLab integrates with both the cloud-hosted [Sentry](https://sentry.io) and Sentry
deployed in your [on-premise instance](https://github.com/getsentry/self-hosted).

## Enable Sentry integration for a project

GitLab provides a way to connect Sentry to your project.

Prerequisites:

- You must have at least the Maintainer role for the project.

To enable the Sentry integration:

1. Sign up to Sentry.io, or deploy your own [on-premise Sentry instance](https://github.com/getsentry/self-hosted).
1. [Create a new Sentry project](https://docs.sentry.io/product/sentry-basics/integrate-frontend/create-new-project/).
   For each GitLab project that you want to integrate, create a new Sentry project.
1. Find or generate a [Sentry auth token](https://docs.sentry.io/api/auth/#auth-tokens).
   For the SaaS version of Sentry, you can find or generate the auth token at [https://sentry.io/api/](https://sentry.io/api/).
   Give the token at least the following scopes: `project:read`, `event:read`, and
   `event:write` (for resolving events).
1. In GitLab, enable and configure Error Tracking:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Settings > Monitor**, then expand **Error Tracking**.
   1. For **Enable error tracking**, select **Active**.
   1. For **Error tracking backend**, select **Sentry**.
   1. For **Sentry API URL**, enter your Sentry hostname. For example,
      enter `https://sentry.example.com`.
      For the SaaS version of Sentry, the hostname is `https://sentry.io`.
      For the SaaS version of Sentry hosted in the EU, the hostname is `https://de.sentry.io`.
   1. For **Auth Token**, enter the token you generated previously.
   1. To test the connection to Sentry and populate the **Project** dropdown list,
      select **Connect**.
   1. From the **Project** list, choose a Sentry project to link to your GitLab project.
   1. Select **Save changes**.

To view a list of Sentry errors, on your project's sidebar, go to **Monitor > Error Tracking**.

## Enable Sentry's integration with GitLab

You might also want to enable Sentry's GitLab integration by following the steps
in the [Sentry documentation](https://docs.sentry.io/organization/integrations/source-code-mgmt/gitlab/).

## Troubleshooting

When working with Error Tracking, you might encounter the following issues.

### Error `Connection failed. Check auth token and try again`

If the **Monitor** feature is disabled in the
[project settings](../user/project/settings/_index.md#configure-project-features-and-permissions),
you might see an error when you try to [enable Sentry integration for a project](#enable-sentry-integration-for-a-project).
The resulting request to `/project/path/-/error_tracking/projects.json?api_host=https:%2F%2Fsentry.example.com%2F&token=<token>` returns a 404 error.

To fix this issue, enable the **Monitor** feature for the project.
