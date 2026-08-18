---
title: Custom lifetime for OAuth access tokens
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../administration/settings/account_and_limit_settings/#limit-the-lifetime-of-oauth-access-tokens
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595570
categories: [ System Access ]
level: secondary
weight: 50
---

By default, OAuth access tokens in GitLab expire after two hours. In GitLab 19.1, instance administrators on GitLab Self-Managed and GitLab Dedicated can set a custom lifetime for new OAuth access tokens. You can configure any value from 300 to 7200 seconds. This helps you enforce shorter-lived tokens for security-sensitive OAuth integrations, including MCP clients, without changing the behavior of existing tokens.
