---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Automatically assign Code Owners as reviewers when a merge request is ready.
title: Automatic reviewer assignment
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175) in GitLab 18.10 [with a flag](../../../../administration/feature_flags/_index.md) named `auto_assign_code_owner_reviewers`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239965) in GitLab 19.1. Feature flag `auto_assign_code_owner_reviewers` removed.

{{< /history >}}

When you enable automatic reviewer assignment, GitLab assigns the
[Code Owners](../../codeowners/_index.md) of changed files as reviewers on a merge request.
You don't have to select reviewers from the `CODEOWNERS` file by hand.

## Prerequisites

- The project must have a [`CODEOWNERS` file](../../codeowners/_index.md).
- The Maintainer or Owner role for the project.

## Enable automatic reviewer assignment

To turn on automatic reviewer assignment for a project:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **Merge requests**.
1. Go to the **Automatic reviewer assignment** section.
1. Select **Automatically assign all code owners as reviewers**.
1. Select **Save changes**.

## When GitLab assigns reviewers

After you turn on the setting, GitLab assigns Code Owners as reviewers when:

- A merge request is created in a ready state.
- A draft merge request is marked as ready.

GitLab assigns every Code Owner that matches the files changed in the merge request.

GitLab skips auto-assignment when:

- The merge request is a draft.
- The merge request already has a reviewer. [`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code) is excluded from this check.
- No code owner matches the files changed in the merge request.
- The merge request author does not have permission to set merge request metadata.

## Reviewer assignment strategy

In projects where [GitLab Duo Agent Platform](../../../../user/duo_agent_platform/_index.md)
recommends reviewers, the **Automatic reviewer assignment** section shows a
**Reviewer assignment strategy** with these options:

- **Do not assign reviewers automatically**: GitLab does not change the reviewers.
- **Assign all code owners as reviewers**: GitLab assigns every Code Owner from the
  `CODEOWNERS` file that matches the changed files.
- **Assign reviewers with GitLab Duo Agent Platform**: GitLab Duo Agent Platform recommends
  the minimum number of reviewers required to satisfy each approval rule.

## Related topics

- [Code Owners](../../codeowners/_index.md)
- [Merge request reviews](_index.md)
- [Merge request approval rules](../approvals/rules.md)
