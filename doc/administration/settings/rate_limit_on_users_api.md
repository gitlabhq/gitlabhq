---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits on Users API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Rate limits for Users API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/452349) in GitLab 17.1 with a [flag](../feature_flags/_index.md) named `rate_limiting_user_endpoints`. Disabled by default.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) customizable rate limits in GitLab 17.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/524831) in GitLab 18.1. Feature flag `rate_limiting_user_endpoints` removed.

{{< /history >}}

You can configure the per minute rate limit per IP address and per user for requests to the following [Users API](../../api/users.md).

| Limit                                                           | Default |
|-----------------------------------------------------------------|---------|
| [`GET /users/:id/followers`](../../api/user_follow_unfollow.md#list-all-accounts-that-follow-a-user) | 100 each minute |
| [`GET /users/:id/following`](../../api/user_follow_unfollow.md#list-all-accounts-followed-by-a-user) | 100 each minute |
| [`GET /users/:id/status`](../../api/users.md#get-the-status-of-a-user)                               | 240 each minute |
| [`GET /users/:id/keys`](../../api/user_keys.md#list-all-ssh-keys-for-a-user)                         | 120 each minute |
| [`GET /users/:id/keys/:key_id`](../../api/user_keys.md#get-an-ssh-key)                               | 120 each minute |
| [`GET /users/:id/gpg_keys`](../../api/user_keys.md#list-all-gpg-keys-for-a-user)                     | 120 each minute |
| [`GET /users/:id/gpg_keys/:key_id`](../../api/user_keys.md#get-a-gpg-key-for-a-user)                 | 120 each minute |

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Users API rate limit**.
1. Set values for any available rate limit. The rate limits are per minute, per user for authenticated requests and per IP address for unauthenticated requests. Enter `0` to disable a rate limit.
1. Select **Save changes**.

Each rate limit:

- Applies per user if the request is authenticated.
- Applies per IP address if the request is unauthenticated.
- Can be set to `0` to disable rate limits.

Logs:

- Requests that exceed the rate limit are logged to the `auth.log` file.
- Rate limit modifications are logged to the `audit_json.log` file.

Example:

If you set a rate limit of 150 for `GET /users/:id/followers` and send 155 requests in a minute, the
final five requests are blocked. After a minute, you could continue sending requests until you
exceed the rate limit again.
