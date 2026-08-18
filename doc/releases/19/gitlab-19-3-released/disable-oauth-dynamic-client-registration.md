---
title: Disable OAuth Dynamic Client Registration for MCP
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../administration/settings/account_and_limit_settings/#oauth-dynamic-client-registration"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/601438
categories: [ System Access ]
level: secondary
weight: 50
---

Previously, MCP clients and AI tools could automatically register OAuth applications on your
instance through Dynamic Client Registration (DCR), which you couldn't turn off. This made it
difficult for administrators on GitLab Self-Managed and GitLab Dedicated instances to control which OAuth
clients could connect.

Now you can disable DCR entirely using the application settings API, giving you full control
over which OAuth clients can access your instance. When DCR is disabled, clients must use a
pre-registered OAuth application instead of registering automatically.
