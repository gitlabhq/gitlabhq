---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Validity checks
---

{{< details >}}

Status: Experiment

- Tier: Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/520923) in GitLab 18.0 [with a flag](../../../api/feature_flags.md) named `validity_checks`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

<i class="fa-youtube-play" aria-hidden="true"></i>
For a demonstration, see [Validity Checks Demo](https://www.youtube.com/watch?v=h0jR0CGNOhI).
<!-- Video published on 2025-05-20 -->

GitLab validity checks determines whether a secret, like an access token, is active.
A secret is active when:

- It is not expired.
- It can be used for authentication.

Because active secrets can be used to impersonate a legitimate user, they pose a
greater security risk than inactive secrets. If several secrets are leaked at once,
knowing which secrets are active is an important part of triage and remediation.

This feature is an [experiment](../../../policy/development_stages_support.md).

## Enable validity checks

Prerequisites:

- You must have a project with pipeline security scanning enabled.

To enable validity checks for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure** > **Security configuration**.
1. Under **Pipeline Secret Detection**, turn on the **Validity checks** toggle. 

GitLab checks the status of detected secrets when the `secret_detection` CI/CD job is complete.
To view a secret's status, view the vulnerability details page. To update the status of a secret,
for example after revoking it, re-run the `secret_detection` CI/CD job.

### Coverage

Validity checks supports the following secret types:

- GitLab personal access tokens
- Routable GitLab personal access tokens
- GitLab deploy tokens
- GitLab Runner authentication tokens
- Routable GitLab Runner authentication tokens
- GitLab Kubernetes agent tokens
- GitLab SCIM OAuth tokens
- GitLab CI/CD job tokens
- GitLab incoming email tokens
- GitLab feed tokens (v2)
- GitLab pipeline trigger tokens

## Secret status

A secret has one of the following statuses:

- **Possibly active** - GitLab couldn't verify the secret status, or the secret type is not supported by validity checks.
- **Active** - The secret is not expired and can be used for authentication.
- **Inactive** - The secret is expired or revoked and cannot be used for authentication.

You should rotate **Active** and **Possibly active** detected secrets as soon as possible.

## Troubleshooting

When working with validity checks, you might encounter the following issues.

### Unexpected token status

The **Possibly active** status appears when GitLab cannot definitively verify a secret's validity.
This might be because:

- The secret validation hasn't been run.
- The secret type is not supported by validity checks.
- There was a problem connecting to the token provider.

To resolve this issue, re-run the `secret_detection` job. If the status persists after a few attempts,
you might need to validate the secret manually.

Unless you're certain the token isn't active, you should revoke and replace possibly active secrets as soon as possible.
