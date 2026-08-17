---
title: "Resolve review discussions with GitLab Duo is generally available"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#resolve-a-discussion-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22058
categories: [ DAP Code Review ]
level: secondary
weight: 20
---

In previous versions of GitLab, to resolve a code review comment, you had to switch to your editor, implement the fix, commit and push the change, and then manually close the thread. 

Now you can select **Resolve with GitLab Duo** and GitLab Duo will address the review discussion for you.

GitLab Duo reads the comment and the surrounding code, makes the requested change on the source branch, replies to the discussion with a summary of what changed, and then resolves the thread. 
If the change does not address the comment correctly, you or the reviewer can reopen the thread.
