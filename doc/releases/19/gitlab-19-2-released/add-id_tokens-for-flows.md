---
title: Configure ID tokens in flows
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/flows/execution/#configure-id-tokens"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/591140
categories: [ Runner Execution, System Access ]
level: secondary
weight: 50
---

Use ID tokens to authenticate with third-party OpenID Connect (OIDC) services
without storing long-lived credentials. For example, use ID tokens for keyless
signing of binaries and commits, or to retrieve secrets from a secrets manager.

To use this feature, update your agent configuration to include the `id_tokens`
keyword, then configure the service to trust tokens issued by GitLab Duo Agent
Platform.
