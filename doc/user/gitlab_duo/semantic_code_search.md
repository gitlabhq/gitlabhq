---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Find relevant code snippets in your repository based on meaning rather than keyword matching.
title: Semantic code search
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16910) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 18.7.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259) to GitLab Duo Core in GitLab 18.8.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/590394) to GitLab Premium in GitLab 18.9.

{{< /history >}}

> [!note]
> For administrator documentation, see [semantic code search administration](../../administration/semantic_code_search.md).

Use semantic code search to find relevant code snippets in your repository
based on meaning rather than keyword matching.

Semantic code search converts your codebase into vector embeddings stored in a vector database.
When you search, your query is converted into an embedding and compared against your code embeddings
to find semantically similar results.
This approach finds relevant code even when keywords do not match.

## Prerequisites

- On GitLab Self-Managed, have semantic code search turned on [for the instance](../../administration/semantic_code_search.md).
  On GitLab.com, semantic code search is turned on by default.
- Have beta and experimental features turned on:
  - On GitLab.com, [for the top-level group](../duo_agent_platform/turn_on_off.md#on-gitlabcom-3).
  - On GitLab Self-Managed, [for the instance](../duo_agent_platform/turn_on_off.md#on-gitlab-self-managed-3).
- Have GitLab Duo turned on [for the project](../duo_agent_platform/turn_on_off.md).

## Use semantic code search

Semantic code search is available through multiple interfaces:

- REST API: Use the [`GET /api/v4/projects/:id/search/semantic` endpoint](../../api/search.md#semantic-search) to search your codebase programmatically.
- MCP server tool: Use the [`semantic_code_search`](model_context_protocol/mcp_server_tools.md#semantic_code_search) tool in agentic workflows.
- CLI: Use the [`glab search semantic`](https://docs.gitlab.com/cli/search/semantic/) command for command-line access.

## Ad-hoc initial indexing

When you first use semantic code search in a GitLab project:

- Your repository code is indexed and converted into vector embeddings.
- These embeddings are stored in your configured vector store.
- Updates are processed incrementally when code is pushed to the default branch.

Initial indexing can take time for large repositories.
