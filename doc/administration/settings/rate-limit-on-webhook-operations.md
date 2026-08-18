---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rate limits on webhook operations
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Rate limit for webhook testing [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150066) in GitLab 17.0 with a [flag](../feature_flags/_index.md) named `web_hook_test_api_endpoint_rate_limit`. Enabled by default.
- Rate limit for webhook event resends [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130) in GitLab 17.1 with a [flag](../feature_flags/_index.md) named `web_hook_event_resend_api_endpoint_rate_limit`. Enabled by default.
- Customizable rate limits [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587887) in GitLab 19.3. Feature flags `web_hook_test_api_endpoint_rate_limit` and `web_hook_event_resend_api_endpoint_rate_limit` removed.

{{< /history >}}

Configure the per-minute rate limit for requests that:

- [Test a webhook](../../user/project/integrations/webhooks.md#test-a-webhook).
- [Resend a webhook event](../../user/project/integrations/webhooks.md#inspect-request-and-response-details).

| Limit | Default |
|-------|---------|
| Webhook test requests | 5 each minute |
| Webhook event resend requests | 5 each minute |

Each rate limit applies per user, for a given project or group, and covers both the UI
and the API. All webhooks in the same project or group share the limit.

These limits are separate from the [webhook delivery rate limit](../instance_limits.md#webhook-rate-limit),
which limits how often webhooks can be triggered. Configuring webhook delivery rate limits depends on the
type of instance:

- On GitLab Self-Managed, administrators configure it with the [Plan limits API](../../api/plan_limits.md).
- On GitLab.com, the delivery limit [depends on your plan](../../user/gitlab_com/_index.md#webhooks) and cannot be changed.

For example, if you set the webhook test rate limit to 5 and try to test a webhook six
times in a minute, the final request is blocked. After a minute, you can test the
webhook again.

## Change the rate limit

Prerequisites:

- Administrator access.

To change the rate limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Webhook rate limits**.
1. Set values for the available rate limits. Enter `0` to disable a rate limit.
1. Select **Save changes**.

Requests that exceed the rate limit are logged to the `auth.log` file.
