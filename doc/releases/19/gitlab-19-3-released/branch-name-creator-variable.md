---
title: Branch names can carry the name of whoever created the branch
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/branches/#configure-default-pattern-for-branch-names-from-issues"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247356
categories: [ Source Code Management ]
level: secondary
---

You can include the creator in branch name templates with a new `%{branch_creator}` variable,
so a branch created from an issue can identify who created it rather than falling back to a
generic name.

Thank you to [Radek Antoniuk](https://gitlab.com/rantoniuk) for this contribution!
