---
title: Reliable SCIM user deprovisioning for large groups
stage: tenant_scale
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com ]
documentation_link: "../../../development/internal_api/#group-scim-api"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/521324"
categories: [ User Management ]
weight: 90
---

For organizations managing large numbers of users through SCIM, deprovisioning group members
could time out and return `500` errors. SCIM `DELETE` and `PATCH` requests now return a
success response immediately. Membership removal is handled asynchronously, so identity
providers and SCIM clients receive consistent success responses.
