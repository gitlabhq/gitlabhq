---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits on pipeline creation
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362475) in GitLab 15.0 [with a flag](../feature_flags/_index.md) named `ci_enforce_throttle_pipelines_creation`. Disabled by default. Enabled on GitLab.com
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196545) in 18.3.

{{< /history >}}

You can set limits so that users and processes can't request more than a certain number of pipelines each minute. These limits can help save resources and improve stability.

GitLab enforces two types of rate limits for pipeline creation:

- **Per project, commit, and user**: Limits pipelines created for the same combination of project, commit SHA, and user. Disabled by default.
- **Per user**: Limits total pipelines created by a user across all projects. Defaults to 300 requests per minute.

For example, if you set a per-user limit of `100`, and a user sends `101` pipeline creation requests to the [trigger API](../../ci/triggers/_index.md) within one minute across different projects,
the 101st request is blocked. Access to the endpoint is allowed again after one minute.

These limits are not applied per IP address.

Requests that exceed the limits are logged in the `application_json.log` file.

## Set pipeline request limits

To limit the number of pipeline requests:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Pipelines Rate Limits**.
1. Under **Max requests per minute per project, user, and commit**, enter a value greater than `0` to limit pipelines for the same project, commit, and user combination.
1. Under **Max requests per minute per user**, enter a value greater than `0` to limit total pipelines created by each user. Set to 0 for unlimited requests per minute.
1. Select **Save changes**.

## How the limits work together

Both rate limits are evaluated independently:

- A user creating multiple pipelines for the same commit SHA in a project is subject to the **per project, user, and commit** limit.
- A user creating pipelines across different projects or commits is subject to the **per user** limit.
- If either limit is exceeded, the pipeline creation request is blocked.
