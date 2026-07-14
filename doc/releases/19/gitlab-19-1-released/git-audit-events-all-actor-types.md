---
title: Git operation audit events for all actor types
stage: create
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../administration/compliance/audit_event_reports/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20506"
categories: [ Source Code Management ]
---

In GitLab 18.10, audit logs began capturing the specific Git operation performed
(clone, pull, fetch, or push) for human users.

In GitLab 19.1, this extended to all actor types, including runners using deploy tokens
and SSH certificate users.
Audit logs now reflect a complete picture of all Git activity across your repositories,
regardless of who or what initiated it.
