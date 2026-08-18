---
title: Pre-register MCP OAuth applications
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server#reuse-a-pre-registered-oauth-application"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/601437
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Previously, the `mcp` scope was hidden from the OAuth applications form in the **Admin** area, so you couldn't
pre-register an OAuth application for your MCP clients without using Dynamic Client Registration (DCR).
Now you can create a shared OAuth application with the `mcp` scope directly
from the **Admin** area, giving your users a stable client ID to reuse and
helping you avoid DCR rate limits on shared networks.
