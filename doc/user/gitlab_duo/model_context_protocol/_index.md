---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Describes Model Context Protocol and how to use it
title: Model Context Protocol
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The Model Context Protocol (MCP) is an open standard that connects AI assistants to existing tools and data sources.
MCP works as a universal adapter. Instead of creating separate custom connections for each software platform,
you can use a single standardized protocol for system communication.

For example, an AI assistant can pull customer data from your CRM, check project status in GitLab,
and refer to documentation from your wiki through the same protocol. This approach
reduces configuration for developers and creates more powerful AI assistants with
access to the context they need.

GitLab supports MCP in two ways:

- [MCP clients](mcp_clients.md): Connect GitLab Duo features like GitLab Duo Chat (Agentic)
  to external MCP servers for access to data and tools from other systems to
  provide more comprehensive assistance.

- [MCP server](mcp_server.md): Connect external AI tools to your GitLab instance.
  Connected tools have secure access to your projects, issues, merge requests,
  and other GitLab data.
