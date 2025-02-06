---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Report abuse
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can report abuse from other GitLab users to GitLab administrators.

A GitLab administrator [can then choose](../administration/review_abuse_reports.md) to:

- Remove the user, which deletes them from the instance.
- Block the user, which denies them access to the instance.
- Or remove the report, which retains the user's access to the instance.

You can report a user through their:

- [Profile](#report-abuse-from-the-users-profile-page)
- [Comments](#report-abuse-from-a-users-comment)
- [Issues](#report-abuse-from-an-issue)
- [Tasks](#report-abuse-from-a-task)
- [Objective](#report-abuse-from-an-objective)
- [Key result](#report-abuse-from-a-key-result)
- [Merge requests](#report-abuse-from-a-merge-request)
- [Snippets](snippets.md#mark-snippet-as-spam)

## Report abuse from the user's profile page

> - Report abuse from overflow menu [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414773) in GitLab 16.4 [with a flag](../administration/feature_flags.md) named `user_profile_overflow_menu_vue`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/414773) in GitLab 16.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/414773) in GitLab 16.6. Feature flag `user_profile_overflow_menu_vue` removed.

To report abuse from a user's profile page:

1. Anywhere in GitLab, select the name of the user.
1. In the upper-right corner of the user's profile select the vertical ellipsis (**{ellipsis_v}**), then **Report abuse**.
1. Select a reason for reporting the user.
1. Complete an abuse report.
1. Select **Send report**.

## Report abuse from a user's comment

> - Reporting abuse from comments in epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389992) in GitLab 15.10.

To report abuse from a user's comment:

1. In the comment, in the upper-right corner, select **More actions** (**{ellipsis_v}**).
1. Select **Report abuse**.
1. Select a reason for reporting the user.
1. Complete an abuse report.
1. Select **Send report**.

NOTE:
A URL to the reported user's comment is pre-filled in the abuse report's
**Message** field.

## Report abuse from an issue

1. On the issue, in the upper-right corner, select **Issue actions** (**{ellipsis_v}**).
1. Select **Report abuse**.
1. Select a reason for reporting the user.
1. Complete an abuse report.
1. Select **Send report**.

## Report abuse from a task

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461848) in GitLab 17.3.

1. On the task, in the upper-right corner, select  **More actions** (**{ellipsis_v}**).
1. Select **Report abuse**.
1. Select a reason for reporting the user.
1. Complete an abuse report.
1. Select **Send report**.

## Report abuse from an objective

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461848) in GitLab 17.3.

1. On the objective, in the upper-right corner, select  **More actions** (**{ellipsis_v}**).
1. Select **Report abuse**.
1. Select a reason for reporting the user.
1. Complete an abuse report.
1. Select **Send report**.

## Report abuse from a key result

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461848) in GitLab 17.3.

1. On the key result, in the upper-right corner, select  **More actions** (**{ellipsis_v}**).
1. Select **Report abuse**.
1. Select a reason for reporting the user.
1. Complete an abuse report.
1. Select **Send report**.

## Report abuse from a merge request

1. On the merge request, in the upper-right corner, select **Merge request actions** (**{ellipsis_v}**).
1. Select **Report abuse**.
1. Select a reason for reporting this user.
1. Complete an abuse report.
1. Select **Send report**.

## Related topics

- [Abuse reports administration documentation](../administration/review_abuse_reports.md)
