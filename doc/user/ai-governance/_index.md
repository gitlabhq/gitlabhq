---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Monitor, audit, and control AI agent activity across your organization.
title: AI Governance
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The AI Governance features help security and compliance teams
monitor, audit, and control AI agent activity across an organization.

These features apply to both GitLab Duo Agent Platform agents and external agents
such as Claude Code and Cursor that connect through the GitLab MCP server.

## Features

| Feature | Description |
|:--------|:------------|
| [AI Governance Dashboard](governance-dashboard.md) | Monitor AI agent sessions, audit logs, and developer exposure across a group. |
| [AI audit events](ai-audit-events.md) | Browse and filter a unified record of agent activity for compliance and governance purposes. |
| [Tool governance](tool-governance.md) | Configure Allow, Ask, and Deny policies for agent tools, enforced at execution time for all connecting clients. |

Each feature has different tier and availability requirements. Check the individual feature page for details.

## Related topics

- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [Compliance features](../compliance/_index.md)
- [Audit events](../compliance/audit_events.md)
