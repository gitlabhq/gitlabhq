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
- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on GitLab Duo with self-hosted models: Not supported

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../policy/development_stages_support.md) in GitLab 18.2.

{{< /history >}}

With the GitLab Duo Agent Platform, multiple AI agents can work in parallel, helping you create code,
research results, and perform tasks simultaneously.
The agents have full context across your entire software development lifecycle.

The Agent Platform is made up of [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md)
and [flows](flows/_index.md), which are available in the GitLab UI and IDEs.

{{< alert type="note" >}}

The Agent Platform public beta requires GitLab 18.2 or later. For the best experience and access to the latest agents and flows, use the latest version of GitLab.

{{< /alert >}}

For more details, view these blog posts about:

- [What's next for intelligent DevSecOps](https://about.gitlab.com/blog/gitlab-duo-agent-platform-what-is-next-for-intelligent-devsecops/)
- [GitLab Duo Agent Platform Public Beta: Next-gen AI orchestration and more](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/)
- [GitLab 18.3: Expanding AI orchestration in software engineering](https://about.gitlab.com/blog/gitlab-18-3-expanding-ai-orchestration-in-software-engineering/)

## Prerequisites

To use the Agent Platform:

- [GitLab Duo Core must be turned on](../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).
- [Beta and experimental features must be turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- For GitLab Self-Managed, you must [configure GitLab Duo](../../administration/gitlab_duo/setup.md).

In addition, to use the Agent Platform in your IDE:

- You must install an editor extension, like the GitLab Workflow extension for VS Code, and authenticate with GitLab.
- You must have a project in a [group namespace](../namespace/_index.md) and have at least the Developer role.
- You must [ensure an HTTP/2 connection to the backend service is possible](troubleshooting.md#network-issues).

To use flows in the GitLab UI, [turn on flows for your project](flows/_index.md#turn-on-flows-for-your-project).

## Related topics

- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
- [Flows](flows/_index.md)
