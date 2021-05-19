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

- [Profile](#reporting-abuse-through-a-users-profile)
- [Comments](#reporting-abuse-through-a-users-comment)
- [Issues and Merge requests](#reporting-abuse-through-a-users-issue-or-merge-request)

## Reporting abuse through a user's profile

To report abuse from a user's profile page:

1. Click on the exclamation point report abuse button at the top right of the
   user's profile.
1. Complete an abuse report.
1. Click the **Send report** button.

## Reporting abuse through a user's comment

To report abuse from a user's comment:

1. Click on the vertical ellipsis (⋮) more actions button to open the dropdown.
1. Select **Report as abuse**.
1. Complete an abuse report.
1. Click the **Send report** button.

NOTE:
A URL to the reported user's comment is pre-filled in the abuse report's
**Message** field.

## Reporting abuse through a user's issue or merge request

The **Report abuse** button is displayed at the top right of the issue or merge request:

- When **Report abuse** is selected from the menu that appears when the
  **Close issue** or **Close merge request** button is clicked, for users that
  have permission to close the issue or merge request.
- When viewing the issue or merge request, for users that don't have permission
  to close the issue or merge request.

With the **Report abuse** button displayed, to submit an abuse report:

1. Click the **Report abuse** button.
1. Submit an abuse report.
1. Click the **Send report** button.

NOTE:
A URL to the reported user's issue or merge request is pre-filled
in the abuse report's **Message** field.

## Managing abuse reports

Admins are able to view and resolve abuse reports.
For more information, see [abuse reports administration documentation](admin_area/review_abuse_reports.md).
