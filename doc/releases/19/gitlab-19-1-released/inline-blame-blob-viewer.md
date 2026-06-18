---
title: Inline blame in the blob viewer
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/project/repository/files/git_blame/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/11471"
categories: [ Source Code Management ]
---

<!-- categories: Source Code Management -->

Previously, viewing blame information required navigating to a separate page,
breaking your flow when reviewing code.

You can now toggle blame information directly in the file view. Each line
shows who last modified it, and you can hover for a commit popover with
additional details. Select **View blame prior to this change** to trace history
further, or select **Ignore specific revisions** to exclude specific commits from
the blame view.
