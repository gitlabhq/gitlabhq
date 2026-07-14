---
title: GitLab Duo CLI is now generally available
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/19717
categories: [ Duo CLI ]
level: primary
weight: 10
---

GitLab Duo CLI brings the GitLab Duo Agent Platform directly to your terminal. 

Use the CLI to ask complex questions about your codebase and to autonomously perform actions on your
behalf.
Unlike external tools, the CLI has context about your GitLab project, pipelines, and agent
configurations.

Key features include:

- Two modes: interactive chat mode and headless mode for CI/CD
- Administrator on/off control for GitLab Self-Managed and GitLab Dedicated
- Model selection and shared sessions
- Tool approvals
- Model Context Protocol (MCP) connections
- Slash commands, including commands for context usage and context compaction
- Support for skills and `AGENTS.md` customization files

Install the GitLab Duo CLI through the GitLab CLI (`glab`) or as a standalone tool.
