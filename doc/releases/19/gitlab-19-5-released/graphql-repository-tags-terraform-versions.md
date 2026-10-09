---
title: Repository tags and Terraform states in GraphQL
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../api/graphql/reference/#repositorytags"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255229
categories: [ Source Code Management ]
level: secondary
weight: 40
---

GraphQL now exposes `Repository.tags`, with forward pagination, search, and a `TagSort` enum
for name, updated, and version order, at up to 100 tags per page. `Repository.tags` is an
experiment in GitLab 19.5. `TerraformState.versions` lists a state's versions, newest first.
The merge requests REST API now returns `author.bot` on single and list responses, so a client
can tell bot and service account authors apart without a second call to the Users API.

Thank you to the following users for these contributions!

- [Jeston Singh](https://gitlab.com/sjestonsingh) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255229) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255230))
- [Ivane Gkomarteli](https://gitlab.com/ivane_gkomarteli) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256381))
