---
title: More ways to filter and manage through the API
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: foundations
co_create: true
documentation_link: "../../../api/rest/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244359
categories: [ System Access ]
level: secondary
---

Six improvements are now available across the REST and GraphQL APIs:

- Groups queries accept `visibilityLevel` and `includeSubgroups`, and can filter for groups
  scheduled for deletion with `aimed_for_deletion`.
- The merge requests REST API accepts `merged_after` and `merged_before`.
- Achievement award messages can be edited after being granted, rather than only set at award time.
- Administrators can reset SCIM tokens through the admin token API.
- `CI_JOB_TOKEN` can now fetch repository archives, which unblocks private Composer package
  downloads that broke when source fallback was deprecated.

Thank you to the following users for these contributions!

- [Colin Jacob Boby](https://gitlab.com/jcb960) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249258))
- [nagraj raikar](https://gitlab.com/nraj0408) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244359) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245378))
- [Niklas van Schrick](https://gitlab.com/Taucher2003) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246614))
- [Nicholas Wittstruck](https://gitlab.com/nwittstruck) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243804))
- [Alessandro Lai](https://gitlab.com/Alessandro.Lai) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246159))
