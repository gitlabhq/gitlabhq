---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Datadog integration **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/270123) in GitLab 14.1

This integration enables you to send CI/CD pipeline and job information to
[Datadog](https://www.datadoghq.com/). Datadog's [CI Visibility](https://app.datadoghq.com/ci)
product helps you monitor for job failures and performance issues, then troubleshoot them.
It's based on [Webhooks](../user/project/integrations/webhooks.md),
and only requires configuration on GitLab.

## Configure the integration

Users with the **Administrator** role can configure the integration at the
project, group, or instance level:

1. If you do not have a Datadog API key:
   1. Sign in to Datadog.
   1. Go to the **Integrations** section.
   1. Generate an API key in the [APIs tab](https://app.datadoghq.com/account/settings#api).
      Copy this value, as you need it in a later step.
1. *For project-level or group-level integrations:* In GitLab, go to your project or group.
1. *For instance-level integrations:*
   1. Sign in to GitLab as a user with the [Administrator role](../user/permissions.md).
   1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Integrations**.
1. Scroll to **Add an integration**, and select **Datadog**.
1. Select **Active** to enable the integration.
1. Specify the [**Datadog site**](https://docs.datadoghq.com/getting_started/site/) to send data to.
1. (Optional) To override the API URL used to send data directly, provide an **API URL**.
   Used only in advanced scenarios.
1. Provide your Datadog **API key**.
1. (Optional) If you use more than one GitLab instance, provide a unique **Service** name
   to differentiate between your GitLab instances.
1. (Optional) If you use groups of GitLab instances (such as staging and production
   environments), provide an **Env** name. This value is attached to each span
   the integration generates.
1. (Optional) Select **Test settings** to test your integration.
1. Select **Save changes**.

When the integration sends data, you can view it in the [CI Visibility](https://app.datadoghq.com/ci)
section of your Datadog account.

## Related links

- [Datadog's CI Visibility](https://docs.datadoghq.com/continuous_integration/) documentation.
