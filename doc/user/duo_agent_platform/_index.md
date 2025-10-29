---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md): Yes

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../policy/development_stages_support.md) in GitLab 18.2.
- For GitLab Duo Agent Platform on self-managed instances (both with [self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md) and cloud-connected GitLab models), [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19213) in GitLab 18.4, as an [experiment](../../policy/development_stages_support.md#experiment) with a [feature flag](../../administration/feature_flags/_index.md) named `self_hosted_agent_platform`. Disabled by default.

{{< /history >}}

With the GitLab Duo Agent Platform, multiple AI agents can work in parallel, helping you create code,
research results, and perform tasks simultaneously.
The agents have full context across your entire software development lifecycle.

The Agent Platform is made up of [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md),
[agents](agents/_index.md), and [flows](flows/_index.md), which are available in the GitLab UI and IDEs.

{{< alert type="note" >}}

The Agent Platform public beta requires GitLab 18.2 or later. For the best experience and access to the latest agents and flows, use the latest version of GitLab.

{{< /alert >}}

For more details, view these blog posts about:

- [What's next for intelligent DevSecOps](https://about.gitlab.com/blog/gitlab-duo-agent-platform-what-is-next-for-intelligent-devsecops/)
- [GitLab Duo Agent Platform Public Beta: Next-gen AI orchestration and more](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/)
- [GitLab 18.3: Expanding AI orchestration in software engineering](https://about.gitlab.com/blog/gitlab-18-3-expanding-ai-orchestration-in-software-engineering/)

## Prerequisites

To use the Agent Platform:

- [GitLab Duo, including GitLab Duo Core and flow execution, must be turned on](../gitlab_duo/turn_on_off.md).
- [Beta and experimental features must be turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- For GitLab Self-Managed, you must [ensure your instance is configured](../../administration/gitlab_duo/setup.md).
- For [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md),
  you must [install and run the AI gateway with GitLab Duo Agent Platform service](../../install/install_ai_gateway.md).

In addition, to use the Agent Platform in your IDE:

- You must install an editor extension, like the GitLab Workflow extension for VS Code, and authenticate with GitLab.
- You must have a project in a [group namespace](../namespace/_index.md) and have at least the Developer role.
- You must [ensure an HTTP/2 connection to the backend service is possible](troubleshooting.md#network-issues).
- For [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md), you must use [WebSocket connection instead of gRPC](troubleshooting.md#use-websocket-connection-instead-of-grpc).

## Related topics

- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
- [Flows](flows/_index.md)
