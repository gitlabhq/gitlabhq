---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform authentication and authorization
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/554156) in GitLab 18.3 [with a flag](../../administration/feature_flags/_index.md) named `duo_workflow_use_composite_identity`.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab Duo Agent Platform uses a service account `@duo-developer` to perform actions on behalf of a user.
This service account, when combined with the user account, is called a *composite identity*.
A composite identity helps you limit the access given to a user, because those privileges are given to the service account instead.

Composite identity is supported for the following flows:

- [Fix CI/CD Pipeline](flows/fix_pipeline.md)
- [Convert to GitLab CI/CD](flows/convert_to_gitlab_ci.md)
- [Issue to Merge Request](flows/issue_to_mr.md)
- Any flow started through the endpoint `api/v4/ai/duo_workflows/workflows`

## Turn on composite identity

For GitLab Self-Managed, you must turn on composite identity.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. Under **GitLab Duo Agent Platform composite identity**, select **Turn on composite identity**.

## Composite Identity tokens

The token that authenticates requests is a composite of two identities:

- The primary author, which is the `@duo-developer` [service account](../profile/service_accounts.md).
  This service account is instance-wide and has the Developer role
  on the project where the Duo Agent Platform was used. The service account is the owner of the token.
- The secondary author, which is the human user who started the flow.
  The human user's `id` is included in the scopes of the token.

This composite identity ensures that any activities authored by Duo Agent Platform are
correctly attributed to the Duo Agent Platform service account.
At the same time, the composite identity ensures that there is no
[privilege escalation](https://en.wikipedia.org/wiki/Privilege_escalation) for the human user.

This [dynamic scope](https://github.com/doorkeeper-gem/doorkeeper/pull/1739)
is checked during the authorization of the API request.
When authorization is requested, GitLab validates that both the service account
and the user who originated the quick action have sufficient permissions.
