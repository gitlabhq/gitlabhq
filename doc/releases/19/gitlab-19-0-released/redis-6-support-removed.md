---
title: Redis 6 support removed
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "../../../install/requirements/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/585839"
categories: [ Omnibus Package ]
weight: 30
---

Support for Redis 6 is removed in GitLab 19.0. If you use an external Redis 6 deployment, migrate
to Redis 7.2 or Valkey 7.2 before upgrading. The bundled Redis included with the Linux package has
used Redis 7 since GitLab 16.2 and is not affected.
