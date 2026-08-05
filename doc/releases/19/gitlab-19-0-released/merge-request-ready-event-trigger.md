---
title: Merge request ready event trigger
stage: ai-powered
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../user/duo_agent_platform/triggers/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/592454"
categories: [ Duo Agent Platform ]
weight: 30
---

You can now configure flows and external agents to run on the **Merge request ready** event.

When a draft merge request is marked as ready for review, GitLab Duo automatically runs the flow or external agent.

To configure a trigger, go to **AI** > **Triggers** in your project.

This feature is behind the `merge_request_ready_flow_trigger` feature flag, disabled by default.
