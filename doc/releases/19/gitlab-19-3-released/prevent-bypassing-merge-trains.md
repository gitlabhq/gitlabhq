---
title: Enforce merge trains
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "../../../ci/pipelines/merge_trains/#enforce-merge-trains"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/597962
categories: [ Merge Trains ]
level: secondary
weight: 10
---

In previous versions of GitLab, you couldn't stop merges from bypassing the train. Both
the option to merge immediately and the REST API could skip merge train protections
without restriction. For teams running high-velocity monorepos, a single merge that
skips the train can cancel and restart every in-progress pipeline, multiplying CI costs
and straining infrastructure.

Now you can enforce merge train usage across the UI and API with a single project-level
setting, preventing bypasses that cancel and restart in-progress pipelines. Owners and
Administrators can still override the setting when needed.
