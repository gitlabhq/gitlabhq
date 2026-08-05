---
title: Admin-defined network access controls for Agent Platform remote flows
stage: ai-powered
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/environment_sandbox/#configure-a-network-policy"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/593149"
categories: [ Duo Agent Platform ]
weight: 110
---

Administrators can now define centralized network policies for GitLab Duo Agent Platform remote flows
directly in Settings. Top-level group administrators on GitLab.com, and instance administrators on
GitLab Self-Managed and Dedicated, can configure organization-wide domain denylists and allowlists
that projects inherit automatically. An additional setting controls whether projects can
extend the approved domain list with custom entries. Policies are enforced at runtime
across all remote flows, giving security and platform teams a consistent governance layer
for agent network egress.
