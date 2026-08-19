---
stage: Tutorial
group: Tutorial
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Move from GitLab Duo Pro or Enterprise to the GitLab Duo Agent Platform.
title: Transition to the GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you transition from GitLab Duo (non-agentic) to the Agent Platform, you get
access to multiple assistants (called agents) throughout the software development lifecycle.

To transition your instance to the Agent Platform, complete the following steps:

1. Set up your environment
1. Validate your configuration
1. Configure Agent Platform settings
1. Validate usage

## Features available after transition

The following table lists the GitLab Duo non-agentic features and
the agentic version that your users can access after moving to the Agent Platform. For a complete list of features in the Agent Platform, see [Generally available features](../../../user/duo_agent_platform/_index.md#generally-available-features) and [Beta and experimental features](../../../user/duo_agent_platform/_index.md#beta-and-experimental-features-that-dont-consume-credits).

| Non-agentic feature | Agent Platform |
|---------------------|----------------|
| GitLab Duo Non-Agentic Chat | [Agentic Chat](../../../user/gitlab_duo_chat/agentic_chat.md) <br /> Answer complex questions and autonomously create and edit files. Connects to the Planner and Security Analyst agents. Merge request summary, discussion summary, refactor code, and test generation are now part of Agentic Chat. |
| GitLab Duo Code Review | [Code Review Flow](../../../user/duo_agent_platform/flows/foundational_flows/code_review/_index.md) <sup>1</sup>  <br /> Automate code review tasks and enforce coding standards across your team. |
| Root cause analysis | [Fix CI/CD pipeline flow](../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline.md) <sup>1</sup> <br /> Diagnose and automatically fix failing CI/CD pipelines. |
| Vulnerability explanation and resolution | [SAST vulnerability resolution flow](../../../user/duo_agent_platform/flows/foundational_flows/agentic_sast_vulnerability_resolution.md) <sup>1</sup> <br /> Automatically generate fixes and remediation steps for SAST vulnerabilities. |

**Footnotes**:

1. Requires a runner [configured to execute flows](#set-up-your-environment). If you don't configure a runner, after you transition to the Agent Platform these features appear unavailable to users who relied on them in GitLab Duo (non-agentic).

## Before you begin

You must have GitLab 19.0 or later.

## Set up your environment

Unlike GitLab Duo (non-agentic), the Agent Platform runs flows on runners and uses service accounts to create commits and pipelines. This requires configuration that non-agentic features did not have.

To set up your environment for the Agent Platform:

1. [Configure your instance](_index.md).
1. [Configure your network](_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) to allow outbound connections from your GitLab instance.
1. [Configure instance or group runners](../../../user/duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows) to use the flows. Flows that use CI/CD are executed on runners. Agentic Chat does not require runners.
1. [Allow connections](_index.md#allow-connections-from-the-runner) from the runner to your GitLab instance.
1. If you have an online license, [synchronize your subscription data](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data).

## Validate your configuration

After you set up your environment, run the following diagnostic checks:

- [GitLab Duo health check](_index.md#run-a-health-check-for-gitlab-duo)
- [Configuration diagnostic script](../../../user/duo_agent_platform/troubleshooting.md#run-the-configuration-diagnostic-script)

## Configure Agent Platform settings

After you set up your environment, configure the following settings:

1. [Turn on the Agent Platform](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
1. [Turn on foundational flows](../../../user/duo_agent_platform/flows/foundational_flows/_index.md).
1. [Configure push rules](../../../user/duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account) for the service account used by foundational flows.
1. [Set a default GitLab Duo namespace](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace).
1. Optional. For consistency and to control costs, [select a model for a feature](../../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature) so that all users use that model. If you're not sure about which model suits your requirements, see [Selecting the right model](../../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature).

## Validate usage

Before you roll out the Agent Platform to the majority of your users, ask a small group of users to confirm the following outcomes:

- They can access and use Agentic Chat in the GitLab UI.
- They can authenticate the Agent Platform in their IDE.
- They can run the Code Review Flow on a test merge request.
- They can run other foundational flows available on your subscription.

After these users have run some flows, you should also check the [Credits Dashboard](../../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) to confirm credit usage.

## Billing

After you change your subscription from GitLab Duo Pro or Enterprise to usage billing, you are charged based on [credit usage](../../../subscriptions/gitlab_credits.md) instead of seats.

To track your team's credit usage and to set usage caps, use the [Credits Dashboard](../../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard).

## Common issues during transition

When you first transition your instance to the Agent Platform, you might encounter the following issues.

| Issue | Likely cause | Resolution |
|---------|--------------|------------|
| Flows not visible in the UI | GitLab Duo or flow execution is not turned on, the group lacks permission to use flows, or the flow is not enabled at the project level. | [Flows not visible in the UI](../../../user/duo_agent_platform/troubleshooting.md#flows-not-visible-in-the-ui) |
| Flows do not run because no runner picks up the job | No runner has the `gitlab--duo` tag, or runners are not configured for flows. | [Configure runners](../../../user/duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows) |
| Session is stuck in the `created` state | Push rules block the service account. The commit author email or the `duo/feature/` branch prefix is not allowed. | [Configure push rules to allow a service account](../../../user/duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account) |
| `Error in creating workload: Insufficient permissions to create a new pipeline` | The foundational flow service account was set up before the imported or templated project existed. | [Insufficient permissions to create a new pipeline for imported projects](../../../user/duo_agent_platform/troubleshooting.md#insufficient-permissions-to-create-a-new-pipeline-for-imported-projects) |
| A foundational flow is turned on but does nothing | The service account was not created, or a group membership lock prevents it from being added to projects. | [Foundational flow service account not created](../../../user/duo_agent_platform/troubleshooting.md#foundational-flow-service-account-not-created) and [Group membership locked](../../../user/duo_agent_platform/troubleshooting.md#group-membership-locked) |
| The Agent Platform is off, or `Something went wrong while requesting a review from GitLab Duo` | The user belongs to multiple GitLab Duo namespaces and no default namespace is set. | [Default GitLab Duo namespace not set](../../../user/duo_agent_platform/troubleshooting.md#default-gitlab-duo-namespace-not-set) |
| `Your request was valid but Workflow failed to complete it` | The repository has no commits, so the flow cannot find a default branch. | [Error: Your request was valid but Workflow failed to complete it](../../../user/duo_agent_platform/troubleshooting.md#error-your-request-was-valid-but-workflow-failed-to-complete-it) |
| `SSL certificate OpenSSL verify result: unable to get local issuer certificate (20)` | On GitLab Self-Managed with a custom or self-signed CA, sandbox hardening blocks the runner's CA injection during `git clone`. | [Error: SSL certificate OpenSSL verify result](../../../user/duo_agent_platform/troubleshooting.md#error-ssl-certificate-openssl-verify-result-unable-to-get-local-issuer-certificate-20) |
| All GitLab Duo features fail for all users immediately after transition | Silent Mode is turned on, which prevents GitLab from reaching the AI gateway. | [Turn off Silent Mode](../../silent_mode/_index.md#turn-off-silent-mode) |
| Health check network test fails, or GitLab Duo features are unavailable after transition | Outbound HTTPS to `cloud.gitlab.com`, `customers.gitlab.com`, or `duo-workflow-svc.runway.gitlab.net` is blocked by a firewall or proxy. | [Allow outbound connections from the GitLab instance to GitLab Duo](_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) |
| Agent Platform features unavailable for all users right after conversion | Usage billing terms have not been accepted, or there are no credits available in the pool. | [On-Demand credits](../../../subscriptions/gitlab_credits.md#on-demand-credits) |

## Related topics

- [GitLab Duo Agent Platform](_index.md)
- [Troubleshooting the GitLab Duo Agent Platform](../../../user/duo_agent_platform/troubleshooting.md)
- [Usage caps](../../../subscriptions/gitlab_credits.md#usage-caps)
- [Self-Hosted models](../../gitlab_duo_self_hosted/_index.md)
- [GitLab University: GitLab Duo Agent Platform for administrators](https://university.gitlab.com/learning-paths/gitlab-duo-agent-platform-for-admins)
- [GitLab University: GitLab Duo Agent Platform setup](https://university.gitlab.com/courses/gitlab-duo-agent-platform-setup)
- [GitLab University: Moving from GitLab Duo Pro or Enterprise to the Agent Platform](https://university.gitlab.com/courses/gitlab-duo-agent-platform-setup)
