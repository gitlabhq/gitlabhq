---
title: Resolve merge conflicts with GitLab Duo (Beta)
stage: ai_coding
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/project/merge_requests/conflicts/#resolve-conflicts-with-gitlab-duo"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20688"
categories: [ Duo Agent Platform, Code Review Workflow ]
weight: 80
---

In previous versions of GitLab, you had to resolve merge conflicts manually in
the GitLab UI or from the command line, even for straightforward cases.

Now GitLab Duo can autonomously analyze merge conflicts, edit the conflicting
files, create a commit, and push to the source branch. Trigger conflict
resolution from the **Resolve conflicts** page or directly from the merge
request widget. When complete, GitLab Duo posts a summary comment so reviewers
can see what changed.

GitLab Duo respects branch protection rules and does not force-push to
protected branches.

This feature is in beta and is gated behind the `mr_ai_resolve_conflicts` feature flag,
enabled by default.
