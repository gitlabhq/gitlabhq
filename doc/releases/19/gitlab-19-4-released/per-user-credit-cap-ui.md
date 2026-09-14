---
title: Set credit caps without the GraphQL API
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#manage-credit-caps"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/628559
categories: [ Consumables Cost Management ]
level: secondary
---

Credit caps limit how many GitLab Credits each user can consume, but until now
you could only configure them through the GraphQL API. Setting a different cap
for a handful of users meant writing mutations by hand.

The new **Credit caps** page lets you set the flat cap that applies to every
user by default, and add per-user overrides for individual users through a
searchable picker.
This page is available in **GitLab Credits** for group Owners on GitLab.com and administrators on GitLab Self-Managed.
The GraphQL mutations still
work if you prefer to script cap changes.
