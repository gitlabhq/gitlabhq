---
title: Stacked merge requests in the UI
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/stacked_merge_requests"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22211
categories: [ Code Review Workflow ]
level: secondary
ignore_in_report: true
---

<!-- categories: Code Review Workflow -->

Previously, when you split a large change into smaller merge requests that
build on each other, the UI gave no signal that they were related. Authors and reviewers had to
track the sequence manually.

GitLab now detects stacked merge requests automatically and shows them in the merge request
header. A merge request joins a stack when it targets another open merge request's source branch,
or when another open merge request targets its source branch. The stack control next to the source
branch shows the current position (for example, **1 of 2**) and lets you jump to any other merge
request in the stack.

To create stacked merge requests from the command line, use stacked diffs in the GitLab CLI.
