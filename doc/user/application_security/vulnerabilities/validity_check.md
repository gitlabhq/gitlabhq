---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Validity checks
---

{{< details >}}

Status: Experiment

- Tier: Ultimate
- Offering: GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/520923) in GitLab 18.0 [with a flag](../../../api/feature_flags.md) named `validity_checks`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

## What is a validity check?

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

- Contact your GitLab representative and ask them to enable validity checks.

If validity checks are enabled, when the `secret_detection` CI/CD job is complete,
GitLab checks the status of supported detected secrets. The statuses are displayed on the
**Findings** page of the vulnerability report.

## Coverage

Validity checks supports the following secret types:

- GitLab personal access tokens
- Routable GitLab personal access tokens

## Secret status

A secret has one of the following statuses:

- **Possibly active** - GitLab couldn't verify the secret status, or the secret type is not supported by validity checks.
- **Active** - The secret is not expired and can be used for authentication.
- **Inactive** - The secret is expired or revoked and cannot be used for authentication.

You should rotate **Active** and **Possibly active** detected secrets as soon as possible.
If a secret has an unexpected status, run a new pipeline and wait for the `secret_detection`
job to finish.
