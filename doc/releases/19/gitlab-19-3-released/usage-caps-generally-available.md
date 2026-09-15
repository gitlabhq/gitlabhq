---
title: GitLab Credits usage caps are generally available
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#usage-caps"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607551
categories: [ Consumables Cost Management ]
level: secondary
---

On-demand usage can run up overage charges you didn't plan for. Usage caps for GitLab Credits are now generally available: set a subscription-level cap on on-demand credits in Customers Portal, and set a default per-user cap or per-user overrides with the GraphQL API. When consumption reaches a cap, features that consume GitLab Credits, like GitLab Duo Agent Platform, are suspended until the next billing period begins or an administrator adjusts the cap. Usage caps were introduced in GitLab 18.11 behind the `budget_caps_graphql_api` feature flag. In GitLab 19.3, the feature flag is removed.
