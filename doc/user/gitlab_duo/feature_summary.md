---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AI-native features and functionality.
title: Summary of GitLab Duo features
---

The following features are part of the GitLab Duo Agent Platform.

| Feature | Description |
|---------|-------------|
| [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md) | Enhanced Chat that autonomously performs actions, searches multiple sources, and can create and edit files to answer complex questions. |
| [AI Catalog](../duo_agent_platform/ai_catalog.md) | Central list of agents and flows where you can discover, create, and enable them in your projects. |
| [Agents](../duo_agent_platform/agents/_index.md) | AI-powered assistants that help accomplish specific tasks. Includes foundational agents (pre-built), custom agents (team-specific), and external agents (third-party integrations). |
| [Flows](../duo_agent_platform/flows/_index.md) | One or more agents working together to solve complex problems and automate development tasks. |
| [MCP clients](model_context_protocol/mcp_clients.md) | Standardized way for GitLab Duo features to securely connect to external data sources and tools. |
| [MCP server](model_context_protocol/mcp_server.md) | Enables AI tools like Claude Desktop and Cursor to securely connect to your GitLab instance. |
| [Knowledge Graph](../project/repository/knowledge_graph/_index.md) | Framework that creates structured, queryable representations of code repositories to power AI features. |

## GitLab Duo classic features

{{< history >}}

- [GitLab Duo first introduced](https://about.gitlab.com/blog/2023/05/03/gitlab-ai-assisted-features/) in GitLab 16.0.
- [Removed third-party AI setting](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144) in GitLab 16.6.
- [Removed support for OpenAI from all GitLab Duo features](https://gitlab.com/groups/gitlab-org/-/epics/10964) in GitLab 16.6.

{{< /history >}}

The following features are generally available on GitLab.com, GitLab Self-Managed, and GitLab Dedicated.
They require a Premium or Ultimate subscription and one of the available add-ons.

The GitLab Duo with Amazon Q features are available as a separate add-on, and
are available on GitLab Self-Managed only.

| Feature | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------|---------|----------------|--------------------------|
| [Code Suggestions](../project/repository/code_suggestions/_index.md) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [GitLab Duo Chat (Classic)](../gitlab_duo_chat/_index.md) | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Code Explanation](../gitlab_duo_chat/examples.md#explain-selected-code) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Refactor Code](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Fix Code](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Code Explanation](../project/repository/code_explain.md) in GitLab UI | {{< no >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Discussion Summary](../discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Code Review](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code) <sup>1</sup> | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Vulnerability Explanation](../application_security/vulnerabilities/_index.md#vulnerability-explanation) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [GitLab Duo and SDLC trends](../analytics/duo_and_sdlc_trends.md) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Merge Commit Message Generation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< yes >}} |

**Footnotes**:

1. Amazon Q supports a different version of this feature.
   [View how to use Amazon Q to review code](../duo_amazon_q/_index.md#review-a-merge-request).

## Beta and experimental features

The following features are not yet generally available.

They require a Premium or Ultimate subscription and the GitLab Duo Enterprise add-on.

| Feature | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|-----------------|----------------|-----------------------|--------------------------|
| [Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Code Review Summary](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Issue Description Generation](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< no >}} | {{< no >}} | {{< yes >}} | {{< no >}} |

## Features available in GitLab Duo Self-Hosted

Your organization can self-host your language models.

To learn which GitLab Duo features are available with GitLab Duo Self-Hosted,
see the
[supported features list](../../administration/gitlab_duo_self_hosted/_index.md#supported-gitlab-duo-features).

## Amazon Q Developer Pro included with GitLab Duo With Amazon Q

License credits for [Amazon Q Developer Pro](https://aws.amazon.com/q/developer/) are included
with a subscription to GitLab Duo with Amazon Q.

This subscription includes access to agentic chat and command-line tools, including:

- [Amazon Q Developer in the IDE](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html), including Visual Studio, VS Code, JetBrains, and Eclipse.
- [Amazon Q Developer on the command line](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html).
- [Amazon Q Developer in the AWS Management Console](https://aws.amazon.com/q/developer/operate/).

For more information about the capabilities of Amazon Q Developer, see the [AWS website](https://aws.amazon.com/q/developer/).
