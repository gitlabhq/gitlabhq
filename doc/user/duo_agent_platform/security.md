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
- A human user. The person who initiated the request.

This dual-identity approach solves a critical challenge:
agents need to act with access that does not exceed the access of the user who triggered them, or the access that the service account was granted,
while maintaining a distinct identity that clearly shows the action was
performed by an agent, not directly by the human user.

## Why composite identity matters

The composite identity is important because it helps ensure:

- Traceability: All agent activities are clearly attributed to a service account,
  making it easy to identify automated actions in audit logs and commit histories.
- Security: The agent can perform actions that only the service account and
  the triggering user have access to do. This intersectional access prevents privilege escalation.
- Accountability: The human user's identity is embedded in the token, creating an audit trail
  that links agent actions back to the person who initiated them.

For example, when you ask an agent to create tests for your code,
the resulting commits will show they were created by the service account on your behalf.

## Where composite identity is used

Composite identity is used for:

- Foundational flows.
- Custom flows.
- External agents.
- Any flow started through the endpoint `api/v4/ai/duo_workflows/workflows`.

## How composite identity works

The token that authenticates requests is a composite of two identities:

- Primary author: A [service account](../profile/service_accounts.md),
  which is the owner of the token and has the Developer role.
- Secondary author: The human user who started the agent or flow.
  The human user's `id` is included in the scopes of the token by using a [dynamic scope](https://github.com/doorkeeper-gem/doorkeeper/pull/1739).

This composite identity ensures that any activities authored by the GitLab Duo Agent Platform are
correctly attributed to the service account, while preventing
[privilege escalation](https://en.wikipedia.org/wiki/Privilege_escalation) for the human user.

## Composite identity workflow

The composite identity is part of the workflow.

1. Create a flow in the AI Catalog.
   - No composite identity-related changes occur.
1. Enable the flow for the top-level group.
   - You must be an Owner to enable it.
   - A service account is automatically created. (The name is similar to `ai-flowname-groupname`.)
1. Enable the flow for your project.
   - The flow must be enabled in the top-level group.
   - You must be a Maintainer to enable it in the project.
   - The service account is added to the project with the Developer role.
1. A user executes the flow. 
   - The flow is executed by a one-time composite identity.
     This identity has a combination of the user's role and the service account's Developer role,
     whichever is more restrictive. So if the user is a Maintainer,
     but the service account is a Developer, the Developer role is used.
   - The flow has access to all projects that both:
     - The user has access to.
     - The service account has been added to.

     For example, if the service account has been added to other projects, 
     and the user has access to those projects
     the flow can access those projects even if the user has not used the flow there before.

## Token permissions for AI Catalog flows

AI Catalog flows use different token types with different permission scopes:

- OAuth tokens used for composite identity in AI workflows have access restricted to the `ai_workflows` and `mcp` scopes.
  This OAuth token is passed to the AI gateway to run the flow.
- CI job tokens that are triggered as part of the flow have permissions further restricted by the
  [available job token permissions](../../ci/jobs/ci_job_token.md#job-token-access).

Because these are different token types with different scopes, the CI/CD job has different permissions than the OAuth token.
