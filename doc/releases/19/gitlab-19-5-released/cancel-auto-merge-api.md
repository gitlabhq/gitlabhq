---
title: Cancel auto-merge from the REST API
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../api/merge_requests/#cancel-auto-merge"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255702
categories: [ Code Review Workflow ]
level: secondary
weight: 20
---

You can now cancel an active auto-merge with the `cancel_auto_merge` API endpoint.
If the merge request is on a merge train, the call also removes it from the train.
The older `cancel_merge_when_pipeline_succeeds` endpoint is now deprecated.

Separately, `git push -o merge_request.auto_merge` is now rejected with a remote message when
you cannot merge to the target branch. In previous versions of GitLab, the auto-merge was recorded
and left the merge request unmergeable until canceled.

Thank you to the following users for these contributions!

- [José M. Requena Plens](https://gitlab.com/jmrp) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255702) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255704))
- [Bobby Nandigam](https://gitlab.com/bobby-nandigam) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251960))
