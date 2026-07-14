---
title: "Resolve review discussions with GitLab Duo (Beta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#resolve-a-discussion-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22117
categories: [ DAP Code Review ]
---


In previous versions of GitLab, to resolve a code review comment, you had to switch to your editor, implement the fix, commit and push the change, and then manually close the thread.
You had to repeat the cycle for every unresolved discussion, and the context-switch overhead would add up across a busy review.

You can now select **Resolve with GitLab Duo** on any review discussion.
GitLab Duo reads the review comment and the code around it, implements the change the reviewer described, and commits it to your branch. GitLab Duo then replies to the discussion with a short summary of what changed and why, and resolves the thread for you. You can review the changes and reopen the thread if the fix doesn't address the comment correctly.
