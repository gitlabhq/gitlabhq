---
title: Automatic rebase before merge
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/methods/#automatic-rebase-before-merge"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16803
categories: [ Code Review Workflow ]
---


In previous versions of GitLab, if your project used the semi-linear or fast-forward merge method, you had to complete an additional step when the source branch fell behind the target branch.
To merge, you had to select **Rebase**, wait for it to complete, then return to the merge request to select **Merge**.
That two-step handoff added friction to every merge.

You can now select **Enable automatic rebase prior to merge** in your project's merge request settings.
When the setting is on, GitLab rebases the source branch onto the target branch at merge time and you can merge with a single action. 
If it's important to preserve GPG signatures on individual commits, you can leave the setting off.
