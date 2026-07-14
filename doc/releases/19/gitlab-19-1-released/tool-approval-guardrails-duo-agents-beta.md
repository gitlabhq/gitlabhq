---
title: "Tool approval guardrails for GitLab Duo agents (beta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/agents/tool-governance/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22381
categories: [ AI Governance ]
level: primary
---

Administrators can now configure tool-level approval policies for GitLab Duo agents, gating sensitive actions with human approval at the moment of execution.

Previously, after an AI agent was approved for a project, it could invoke any of its tools without further review, including write and destructive operations.
Now, you can define rules for groups and projects that map each tool to one of three modes:

- Allow (execute silently).
- Ask (require human approval).
- Deny (block entirely).

When an AI agent calls a tool in "ask" mode, the user is prompted with an inline approval card before execution proceeds.

This beta release includes Agentic Chat, IDE, and flows, and emits audit events for every approval decision.
