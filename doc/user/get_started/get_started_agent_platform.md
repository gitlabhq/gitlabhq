---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Get started with the GitLab Duo Agent Platform
---

The GitLab Duo Agent Platform is an automated assistant that speeds up repetitive tasks
while maintaining your organization's standards and practices.

Use the Agent Platform for things like creating files, generating merge requests from issues,
analyzing and fixing security vulnerabilities, refactoring codebases,
fixing and converting CI/CD configurations, integrating with external systems, and more.

## Step 1: Access GitLab Duo Chat

GitLab Duo Chat (Agentic), in the UI or your IDE, is your interface
for asking questions and interacting with agents.
It can provide advice, but it can also propose and implement solutions.

Chat has access to your project, including issues, merge requests, commits,
and CI/CD pipelines, and Chat maintains context across conversations.
You can build up complexity gradually, reference previous responses, and iterate
until you reach the desired outcome.

GitLab Duo Chat is available in the GitLab UI and a variety of IDEs.

For more information, see:

- [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md).

## Step 2: Work with agents

Agents are specialized AI assistants designed for specific workflows.

- Foundational agents are available by default and handle common development tasks.
  The GitLab Duo Agent provides general assistance for questions, explanations, and code navigation.
  Other foundational agents help with things like planning releases or securing code.
- Custom agents are created by your organization to address team-specific workflows.
  You can build agents for code review standards, compliance checks, deployment automation,
  or any workflow that's unique to your team.
- External agents integrate GitLab with AI model providers you already use.
  You trigger external agents from issues, epics, and merge requests.

For more information, see:

- [Agents overview](../duo_agent_platform/agents/_index.md).
- [Foundational agents](../duo_agent_platform/agents/foundational_agents/_index.md).
- [Custom agents](../duo_agent_platform/agents/custom.md).
- [External agents](../duo_agent_platform/agents/external.md).

## Step 3: Use multiple agents together in a flow

A flow is a combination of one or more agents working together to complete a task.
Flows can help you automate multi-step workflows that would typically require
manual coordination between tools or team members.

For example, you can trigger a flow from a merge request, and the flow can do
a security scan, review code, generate tests, and draft documentation.

GitLab provides foundational flows, like the software development flow in your IDE,
or flows in the UI that do things like converting or fixing CI/CD pipelines.
You can also create your own custom flows.

The AI Catalog is the central location where you discover and create agents and flows,
and enable them for use in your projects.

For more information, see:

- [Flows](../duo_agent_platform/flows/_index.md).
- [AI Catalog](../duo_agent_platform/ai_catalog.md).
- [Triggers](../duo_agent_platform/triggers/_index.md).

## Step 4: Monitor and review agent activity

Actions an agent takes are tracked in a session with logs.
Sessions can help aid with debugging, facilitate learning, and support audit requirements.

To view sessions, go to your project and select **Automate** > **Sessions**.

For more information, see:

- [Sessions](../duo_agent_platform/sessions/_index.md).

## Step 5: Extend capabilities with integrations

To increase the knowledge of your AI agents, use the Knowledge Graph.
It creates structured representations of your code repositories and
helps agents and your team better understand relationships between files,
functions, and dependencies.

You can also extend the platform beyond GitLab by connecting with external tools
and data sources.

- Connect GitLab Duo features like GitLab Duo Chat (Agentic) to external MCP servers
  so that other MCP clients can provide more comprehensive assistance.
- MCP server works in the opposite direction: external AI tools like
  Claude Desktop or Cursor can securely connect to your
  GitLab instance, giving those tools access to your GitLab data.

For more information, see:

- [Knowledge Graph](../project/repository/knowledge_graph/_index.md).
- [MCP clients](../gitlab_duo/model_context_protocol/mcp_clients.md).
- [MCP server](../gitlab_duo/model_context_protocol/mcp_server.md).
