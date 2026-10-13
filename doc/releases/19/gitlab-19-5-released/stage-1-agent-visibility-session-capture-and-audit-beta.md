---
title: Connect Externally Connected Agents (ECAs) to AI Governance
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/externally-connected-agents"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/633489
categories: [ AI Governance ]
level: primary
weight: 50
---

Previously, the [AI Governance Dashboard](../../../user/ai-governance/governance-dashboard.md) showed
activity only from GitLab Duo Agent Platform agents. This provided you total visibility into all of your
Agent Platform agents, including the sessions they were running, including tool calls, MCPs used, and
the prompt input and output from the user and agent respectively.

With the GitLab 19.5 release, after a one-time `glab govern setup`, you can now extend governance
visibility past just GitLab Duo Agent Platform agents, and connect Externally Connected Agents (ECAs) like
Claude Code, Cursor, and Codex to GitLab AI Governance by using the GitLab CLI (`glab`).

When **Allow external agents** and **Store AI audit events** are enabled, security and compliance teams
get visibility into ECAs that run outside GitLab, alongside your GitLab Duo Agent Platform agents. Every qualifying
agent session is captured, including who ran it, which agent, which project, and when, with sessions and
tool calls appearing in the AI Governance Dashboard and the AI audit events report. Audit events also
flow to your SIEM through audit event streaming.

Tool output is not sent, except for short error messages from failed tool calls.

This feature is in beta. Share your feedback in [issue 633489](https://gitlab.com/gitlab-org/gitlab/-/work_items/633489).
