---
title: "Resolve merge conflicts with GitLab Duo is generally available"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/conflicts/#resolve-conflicts-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20688
categories: [ DAP Code Review ]
level: secondary
weight: 20
---

In previous versions of GitLab, you had to resolve merge conflicts manually in
the GitLab UI or from the command line, even for straightforward cases.

Now you can ask GitLab Duo to resolve conflicts for you. 

Start conflict resolution from the merge widget or the **Resolve conflicts** page. 
GitLab Duo analyzes the conflicts, edits the files and commits the resolution to the source branch, and then posts a summary comment on the merge request describing what changed.
