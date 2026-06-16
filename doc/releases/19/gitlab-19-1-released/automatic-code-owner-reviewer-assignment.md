---
title: Automatically assign Code Owners as reviewers
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/automatic_reviewer_assignment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20708
categories: [ Code Review Workflow ]
level: primary
ignore_in_report: true
---

<!-- categories: Code Review Workflow -->

Previously, you needed to select reviewers for each merge request manually,
even when a `CODEOWNERS` file already defined who should review each file.

You can now configure a project to assign Code Owners as reviewers automatically.
GitLab assigns every Code Owner that matches the changed files. This happens when a
merge request is created in a ready state, or when a draft is marked ready. If you
already assigned a reviewer, GitLab skips automatic assignment and keeps your choice.

To turn on automatic reviewer assignment, go to **Settings** > **Merge requests** >
**Automatic reviewer assignment** and select **Automatically assign all code owners as
reviewers**.
