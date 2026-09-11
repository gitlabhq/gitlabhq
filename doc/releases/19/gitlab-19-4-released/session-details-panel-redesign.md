---
title: Redesigned session details panel for the GitLab Duo Agent Platform
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/duo_agent_platform/sessions/#view-sessions-for-your-project"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22662
categories: [ Agent Observability ]
level: secondary
weight: 50
---

Finding the details that matter about an agent session used to mean hunting through a cluttered panel.
Now, the session details panel surfaces what you need at a glance: status, timestamps, and the triggering
user appear in an overview bar, while the right rail organizes identity, execution, and supplemental
details into clearly labeled groups.

A new **Linked items** section separates what started the session from what it produced, including
merge requests, work items, jobs, and comments. In the GitLab Duo side panel, session details now
live in a collapsible bar pinned to the bottom, so they stay accessible without getting in your way.
