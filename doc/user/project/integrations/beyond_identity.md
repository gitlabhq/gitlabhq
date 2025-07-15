---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Integrate GitLab with Beyond Identity to verify GPG keys added to user accounts.
title: Beyond Identity
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/431433) in GitLab 16.9.

{{< /history >}}

In GitLab, users can sign their commits after [adding a GPG key to their profile](../repository/signed_commits/gpg.md).
The GitLab integration with [Beyond Identity](https://www.beyondidentity.com/) extends this feature.

When configured, this integration uses Beyond Identity to validate any new GPG key that a user adds
to their profile. Keys that do not pass validation are rejected, and the user must upload a new key.

When a user pushes a signed commit to the GitLab instance, GitLab runs a pre-receive
check to validate those commits against the GPG key stored in the user's profile.
This ensures that only commits signed with validated keys are accepted.

## Set up the Beyond Identity integration for your instance

Prerequisites:

- You must have administrator access to the GitLab instance.
- The email address used in the GitLab profile must be the same as the email assigned to the key in the Beyond Identity Authenticator.
- You must have a Beyond Identity API token. You can request it from their Sales Engineer.

To enable the Beyond Identity integration for your instance:

1. Sign in to GitLab as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select **Beyond Identity**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **API token**, paste the API token you received from Beyond Identity.
1. Select **Save changes**.

The Beyond Identity integration for your instance is now enabled.

## GPG key verification

When a user adds a GPG key to their profile, the key is verified:

- If the key wasn't issued by the Beyond Identity Authenticator, it's accepted.
- If the key was issued by the Beyond Identity Authenticator, but the key is invalid, it's rejected.
  For example: the email used in the user's GitLab profile is different from the email assigned to
  the key in the Beyond Identity Authenticator.

When a user pushes a commit, GitLab checks that the commit was signed by a GPG signature uploaded to the
user profile.
If the signature cannot be verified, the push is rejected.
Web commits are accepted without a signature.

## Skip push check for service accounts

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454369) in GitLab 16.11.

{{< /history >}}

Prerequisites:

- You must have administrator access to the GitLab instance.

To skip the push check for [service accounts](../../profile/service_accounts.md):

1. Sign in to GitLab as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select **Beyond Identity**.
1. Select the **Exclude service accounts** checkbox.
1. Select **Save changes**.

## Exclude groups or projects from the Beyond Identity check

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454372) in GitLab 17.0 [with a flag](../../../administration/feature_flags/_index.md) named `beyond_identity_exclusions`. Enabled by default.
- Option to exclude groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454372) in GitLab 17.1.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/457893) in GitLab 17.7. Feature flag `beyond_identity_exclusions` removed.

{{< /history >}}

Prerequisites:

- You must have administrator access to the GitLab instance.

To exclude groups or projects from the Beyond Identity check:

1. Sign in to GitLab as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select **Beyond Identity**.
1. Select the **Exclusions** tab.
1. Select **Add exclusions**.
1. On the drawer, search and select groups or projects to exclude.
1. Select **Add exclusions**.
