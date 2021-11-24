---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Report abuse **(FREE)**

You can report abuse from other GitLab users to GitLab administrators.

A GitLab administrator [can then choose](admin_area/review_abuse_reports.md) to:

- Remove the user, which deletes them from the instance.
- Block the user, which denies them access to the instance.
- Or remove the report, which retains the user's access to the instance.

You can report a user through their:

- [Profile](#report-abuse-from-the-users-profile-page)
- [Comments](#report-abuse-from-a-users-comment)
- [Issues and Merge requests](#report-abuse-through-a-users-issue-or-merge-request)
- [Snippets](snippets.md#mark-snippet-as-spam)

## Report abuse from the user's profile page

To report abuse from a user's profile page:

1. In the top right corner of the user's profile, select the exclamation point report abuse button.
1. Complete an abuse report.
1. Select **Send report**.

## Report abuse from a user's comment

To report abuse from a user's comment:

1. In the comment, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Report abuse to admin**.
1. Complete an abuse report.
1. Select **Send report**.

NOTE:
A URL to the reported user's comment is pre-filled in the abuse report's
**Message** field.

## Report abuse through a user's issue or merge request

The **Report abuse** button is displayed at the top right of the issue or merge request. For users
with permission to close the issue or merge request, the button is available when you select
**Close issue** or **Close merge request**. For all other users, it is available when viewing the
issue or
merge request.

With the **Report abuse** button displayed, to submit an abuse report:

1. Select **Report abuse**.
1. Submit an abuse report.
1. Select **Send report**.

NOTE:
A URL to the reported user's issue or merge request is pre-filled
in the abuse report's **Message** field.

## Related topics

- Administrators can view and resolve abuse reports.
  For more information, see [abuse reports administration documentation](admin_area/review_abuse_reports.md).
