---
title: Early warnings for GitLab Flex spend caps
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_flex/#adjust-your-reservation"
work_item: https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/18962
categories: [ Consumables Cost Management ]
level: secondary
---

GitLab 19.3 introduced email notifications for reservation thresholds and for the moment a
capped capability is cut off. The spend cap itself had no early warning, so
the first email about a cap arrived when usage had already stopped.

GitLab now emails billing account managers when a capability's on-demand usage
reaches 50% or 80% of its monthly spend cap, naming the capability and the cap
in credits. Only the highest threshold crossed is sent, at most once per
capability per billing period. Caps of less than $10 are skipped, so a
small cap does not generate noise.
