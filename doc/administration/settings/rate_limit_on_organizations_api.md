---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limit on Organizations API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/470613) in GitLab 17.5 with a [flag](../feature_flags.md) named `allow_organization_creation`. Disabled by default. This feature is an [experiment](../../policy/development_stages_support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 400 for `POST /organizations`, requests to the API endpoint that
exceed a rate of 400 within one minute are blocked. Access to the endpoint is restored after one minute.

You can configure the per minute rate limit per user for requests to the [POST /organizations API](../../api/organizations.md#create-organization). The default is 10.

## Change the rate limit

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Organizations API rate limits**.
1. Change the value of any rate limit. The rate limits are per minute per user.
   To disable a rate limit, set the value to `0`.
1. Select **Save changes**.
