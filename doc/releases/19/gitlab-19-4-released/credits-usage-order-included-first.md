---
title: Included credits are used before evaluation credits
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits/#usage-order"
work_item: https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/18961
categories: [ Consumables Cost Management ]
level: secondary
---

When a subscription had temporary evaluation credits, all usage drew from that
shared pool first. Every user's included monthly credits sat idle until the
evaluation pool ran out, and then reset at the end of the month.

GitLab now consumes each user's included credits first, and draws from the
shared pool of temporary evaluation credits only after a user has used their
included amount. The Monthly Commitment Pool, One-Time Charge credits, and
On-Demand credits are consumed in the same order as before, so your bill is
unaffected.
