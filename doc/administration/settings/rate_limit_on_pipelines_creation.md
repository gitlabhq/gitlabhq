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

You can set a limit so that users and processes can't request more than a certain number of pipelines each minute. This limit can help save resources and improve stability.

For example, if you set a limit of `10`, and `11` requests are sent to the [trigger API](../../ci/triggers/_index.md) within one minute,
the eleventh request is blocked. Access to the endpoint is allowed again after one minute.

This limit is:

- Applied to the number of pipelines created for the same combination of project, commit, and user.
- Not applied per IP address.
- Disabled by default.

Requests that exceed the limit are logged in the `application_json.log` file.

## Set a pipeline request limit

To limit the number of pipeline requests:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Pipelines Rate Limits**.
1. Under **Max requests per minute**, enter a value greater than `0`.
1. Select **Save changes**.
