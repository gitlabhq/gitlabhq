---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform authentication and authorization
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
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

Composite identity is an authentication and authorization mechanism that combines two identities into a single token:

- A service account. The machine user that performs the actual actions.
- A human user. The person who initiated the AI agent request.

This dual-identity approach solves a critical challenge for AI agents: they need to act with the same permissions as the user who triggered them, while maintaining a distinct identity that clearly shows the action was performed by an AI agent, not directly by the human user.

## Why composite identity matters

The composite identity is important because it helps ensure:

- Traceability: All AI agent activities are clearly attributed to a service account (like `@duo-developer`),
  making it easy to identify automated actions in audit logs and commit histories.
- Security: The AI agent can only perform actions that both the service account and
  the triggering user have permission to do. This prevents privilege escalation.
- Accountability: The human user's identity is embedded in the token, creating an audit trail
  that links AI agent actions back to the person who initiated them.

For example, when you ask an AI agent to create tests for your code, the agent can only access projects you have access to, and the resulting commits will show they were created by the AI agent service account on your behalf.

You must [turn on composite identity](../../administration/gitlab_duo/setup.md#turn-on-composite-identity)
to use the GitLab Duo Agent Platform.

## Flows that use composite identity

Composite identity is used for the following flows:

- [Fix CI/CD Pipeline](flows/fix_pipeline.md)
- [Convert to GitLab CI/CD](flows/convert_to_gitlab_ci.md)
- [Developer](flows/issue_to_mr.md)
- Any flow started through the endpoint `api/v4/ai/duo_workflows/workflows`
- AI Catalog flows added to top-level groups

## How composite identity tokens work

The token that authenticates requests is a composite of two identities:

- Primary author: The `@duo-developer` [service account](../profile/service_accounts.md) (or a group-specific service account for AI Catalog flows).
  This service account is the owner of the token and has the Developer role
  on the project where the GitLab Duo Agent Platform was used.
- Secondary author: The human user who started the flow.
  The human user's `id` is included in the scopes of the token using a [dynamic scope](https://github.com/doorkeeper-gem/doorkeeper/pull/1739).

This composite identity ensures that any activities authored by GitLab Duo Agent Platform are
correctly attributed to the service account, while preventing
[privilege escalation](https://en.wikipedia.org/wiki/Privilege_escalation) for the human user.

During authorization of API requests, GitLab validates that both the service account
and the user who originated the action have sufficient permissions. The effective permissions
are the intersection of what both identities can do.

## Composite identity for AI Catalog flows

When an AI Catalog flow is added to a top-level group, a group-specific service account is created.
This account is used instead of the `@duo-developer` service account for any actions the flow takes.

The service account is added as a member to any project where the flow is enabled, and also uses composite identity.
This means it will have the intersection of the permissions that both the triggering user and the service account have.

### Token permissions for AI Catalog flows

AI Catalog flows use different token types with different permission scopes:

- OAuth tokens used for composite identity in AI workflows have access restricted to the `ai_workflows` and `mcp` scopes.
  This OAuth token is passed to the AI gateway to run the flow.
- CI job tokens that are triggered as part of the flow have permissions further restricted by the
  [available job token permissions](../../ci/jobs/ci_job_token.md#job-token-access).

Because these are different token types with different scopes, the CI/CD job has different permissions than the OAuth token.
