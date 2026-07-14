---
title: GitLab Flavored Markdown references in personal snippets
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: plan
documentation_link: "../../../user/markdown/#gitlab-specific-references"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/4185
categories: [ Markdown ]
level: secondary
weight: 50
ignore_in_report: true
---

<!-- categories: Markdown -->

You can now use GitLab Flavored Markdown (GFM) references with personal snippets in two ways:

- GitLab processes GFM references inside personal snippet descriptions and comments,
  just like in project snippets and other areas of GitLab.
- You can reference a personal snippet from anywhere GFM is supported, such as comments and issue or merge request descriptions,
  using the `$<id>` syntax that already works for project snippets.

Because snippet IDs are unique across personal and project snippets, each ID resolves to a single snippet.
