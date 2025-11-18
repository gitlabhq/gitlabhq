---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create structured, queryable representations of code repositories to power AI features and enhance developer productivity with the GitLab Knowledge Graph.
title: GitLab Knowledge Graph
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/rust/-/epics/11) as an [experiment](../../../../policy/development_stages_support.md#experiment) in GitLab 18.3.
- Changed to [beta](../../../../policy/development_stages_support.md#beta) in GitLab 18.4.

{{< /history >}}

The [GitLab Duo Agent Platform](../../../duo_agent_platform/_index.md) uses the
[GitLab Knowledge Graph](https://gitlab-org.gitlab.io/rust/knowledge-graph) to increase the
accuracy of AI agents. You can use the Knowledge Graph framework in your AI projects to enable rich
code intelligence across your codebase. For example, when building Retrieval-Augmented Generation (RAG)
applications, the Knowledge Graph turns your codebase into a live, embeddable graph database
for AI agents. The Knowledge Graph also creates architectural visualizations. This provides insightful
diagrams of your system's structure and dependencies.

You can install the Knowledge Graph framework with a one-line script. It parses local repositories, and
connects using Model Context Protocol (MCP) to query your projects. The Knowledge Graph captures entities like files,
directories, classes, functions, and their relationships. This added context enables advanced code
understanding and AI features. For example, this allows GitLab Duo agents to understand relationships
across your local workspace and enables faster and more precise responses to complex questions.

The Knowledge Graph scans your code to identify:

- Structural Elements: Files, directories, classes, functions, and modules that form the
  backbone of your application.
- Code Relationships: Intricate connections like function calls, inheritance hierarchies,
  and module dependencies.

The Knowledge Graph also features a CLI. For more information about the Knowledge Graph CLI (`gkg`)
and framework, see the
[Knowledge Graph project documentation](https://gitlab-org.gitlab.io/rust/knowledge-graph).

## Feedback

This feature is in beta status. Provide feedback in [issue 160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160).
