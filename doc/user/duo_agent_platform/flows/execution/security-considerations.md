---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand the security model for flows in CI/CD, the risks of the agent configuration file, and recommended protections.
title: Security considerations for flow execution
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When flows execute in GitLab CI/CD:

- They use a [composite identity](../../composite_identity.md) to limit access.
- They create an ephemeral [workload pipeline](../../../../ci/pipelines/pipeline_types.md#workload-pipeline),
  which is removed when the flow is complete.
- The tools at their disposal are specific to the purpose of the flow.
  These tools can include the creation of merge requests or the running of local shell commands in their execution environment.

By default, flows have network access to the GitLab instance only.
For more information about network access rules, see [how to configure a network policy](../../environment_sandbox.md#configure-a-network-policy).
This separate environment protects from unintended consequences of running shell commands.

To prevent flows from running autonomously in the GitLab UI, you can [turn off flow execution](../foundational_flows/_index.md#turn-foundational-flows-on-or-off).

## Security implications of `agent-config.yml`

The `.gitlab/duo/agent-config.yml` file controls how flows execute in CI/CD, including the
commands that run in `setup_script`. Because of how flows run, changes to this file affect more
than the user who commits them.

### Cross-user execution

Flows run under the identity of the user who triggers them through [composite identity](../../composite_identity.md).
Commands in `setup_script` execute with the triggering user's composite identity credentials,
not the credentials of the user who committed the configuration.

A user with write access to `.gitlab/duo/agent-config.yml` can influence what runs in another
user's runner environment. Modifications to this file affect the execution context of every
user who later triggers a flow in the project.

### Exposed environment variables

During `setup_script` execution, which runs outside Anthropic Sandbox Runtime (SRT),
the following sensitive variables are present in the environment:

- `GITLAB_OAUTH_TOKEN` and `GITLAB_TOKEN`: The triggering user's OAuth token
  through composite identity.
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: The Git HTTP password.
- `DUO_WORKFLOW_SERVICE_TOKEN`: The service token.
- `DUO_WORKFLOW_GIT_USER_EMAIL` and `DUO_WORKFLOW_GIT_USER_NAME`: The triggering user's
  email and name.

For the full list of exposed variables, see [flow execution variables](execution-variables.md).

### Recommended protections

To reduce the risk of unauthorized changes to the `.gitlab/duo/agent-config.yml` file:

- [Protect your default branch](../../../../user/project/repository/branches/protected.md) to prevent direct pushes.
- Use [Code Owners](../../../../user/project/codeowners/_index.md) to require approval from specific
  owners before changes to `.gitlab/duo/agent-config.yml` are merged.
  For example, add the following to your `CODEOWNERS` file:

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- Configure [approval rules](../../../../user/project/merge_requests/approvals/rules.md) that require
  review from trusted maintainers for merge requests that modify this file.
