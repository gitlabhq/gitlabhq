---
title: Webhooks for merge request reviews and deployment approvals
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: create
co_create: true
documentation_link: "../../../user/project/integrations/webhook_events/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246562
categories: [ Code Review Workflow, Deployment Management ]
level: secondary
---

You can use webhooks for merge request reviews and deployment approvals. When you submit a
merge request review as **Request changes** or **Reviewed**, GitLab fires a `merge_request`
webhook carrying a `changes.reviewers` entry, so external tools can react to review activity
instead of just approvals.

The deployment webhook gains `blocked`, `approved`, and `rejected` statuses with top-level
`approver` and `approval` fields, letting you follow a deployment through its full approval
lifecycle. The `blocked` status is available in all tiers. The `approved` and `rejected`
statuses are available in Premium and Ultimate only, and `approver.email` is redacted.

Thank you to [Messias Tayllan](https://gitlab.com/tayllanr) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246562))
and [Anvita Gupta](https://gitlab.com/arcesium-guptaanv) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239337))
for these contributions!
