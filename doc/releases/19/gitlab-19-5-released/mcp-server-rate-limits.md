---
title: "New rate limits for GitLab MCP server"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/#rate-limits"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22800
categories: [ Agent Tools ]
level: secondary
weight: 50
---

If you connect an agent to GitLab over MCP today, nothing stops it from reconnecting or retrying faster than your workflow actually needs, and on GitLab.com that carries a cost. 

Starting October 15, the GitLab MCP server on GitLab.com limits each user to 60 requests a minute on the Free tier and 600 on Premium and Ultimate. Every reconnect and retry counts toward your limit. If your agent starts getting rate-limited (HTTP 429) errors, check its reconnect and retry settings before upgrading to a higher tier.
