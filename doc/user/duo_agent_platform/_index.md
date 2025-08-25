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

For more details, view this blog post about [what's next for intelligent DevSecOps](https://about.gitlab.com/blog/gitlab-duo-agent-platform-what-is-next-for-intelligent-devsecops/).

The Agent Platform is made up of [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md)
and [flows](flows/_index.md), which are available in the GitLab UI and IDEs.

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
