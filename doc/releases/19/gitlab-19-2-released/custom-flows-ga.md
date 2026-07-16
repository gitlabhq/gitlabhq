---
title: GitLab Duo custom flows are now generally available
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/duo_agent_platform/flows/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/602415
categories: [ AI Catalog Creation ]
level: primary
weight: 10
---

Custom flows are AI-powered workflows you create and configure to automate complex, multi-step tasks across your GitLab projects. They let teams define workflow steps, components, and triggers so repetitive development and operational work can run automatically in response to GitLab events. In the GitLab UI, flows run directly in GitLab CI/CD, helping teams automate common tasks without leaving GitLab.

Key features include:

- YAML-defined, reusable workflows for team-specific automation
- Multi-agent orchestration for complex, multi-step tasks
- User-defined human-in-the-loop (HITL) checkpoints for approval or feedback at sensitive steps
- Native GitLab triggers, including mentions, assignments, pipeline events, and merge request lifecycle events
- Flow creation and management from projects or the AI Catalog
- Public and private visibility controls
- Secure execution using service accounts and composite identity
- YAML validation to catch configuration issues before runtime
