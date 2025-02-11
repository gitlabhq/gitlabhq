---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Confidential issues
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Confidential issues are [issues](_index.md) visible only to members of a project with
[sufficient permissions](#who-can-see-confidential-issues).
Confidential issues can be used by open source projects and companies alike to
keep security vulnerabilities private or prevent surprises from leaking out.

## Make an issue confidential

> - Minimum role to make an issue confidential [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

You can make an issue confidential when you create or edit an issue.

Prerequisites:

- You must have at least the Planner role for the project.
- If the issue you want to make confidential has any child [tasks](../../tasks.md),
  you must first make all the child tasks confidential.
  A confidential issue can have only confidential children.

### In a new issue

When you create a new issue, a checkbox right below the text area is available
to mark the issue as confidential. Check that box and select **Create issue**
to create the issue.

When you create a confidential issue in a project, the project becomes listed in the **Contributed projects** section in your [profile](../../profile/_index.md). **Contributed projects** does not show information about the confidential issue; it only shows the project name.

To create a confidential issue:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, at the top, select **Create new** (**{plus}**).
1. From the dropdown list, select **New issue**.
1. Complete the [fields](create_issues.md#fields-in-the-new-issue-form).
   - Select the **This issue is confidential** checkbox.
1. Select **Create issue**.

### In an existing issue

To change the confidentiality of an existing issue:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues**.
1. Select the title of your issue to view it.
1. In the upper-right corner, select **Issue actions** (**{ellipsis_v}**) and then **Turn on confidentiality** (or **Turn off confidentiality** to make the issue non-confidential).

Alternatively, you can use the `/confidential` [quick action](../quick_actions.md#issues-merge-requests-and-epics).

## Who can see confidential issues

> - Minimum role to see confidential issues [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

When an issue is made confidential, only users with at least the Planner role
for the project have access to the issue.
Users with Guest or [Minimal](../../permissions.md#users-with-minimal-access) roles can't access
the issue even if they were actively participating before the change.

However, a user with the **Guest role** can create confidential issues, but can only view the ones
that they created themselves.

Users with the Guest role or non-members can read the confidential issue if they are assigned to the issue.
When a Guest user or non-member is unassigned from a confidential issue, they can no longer view it.

Confidential issues are hidden in search results for users without the necessary permissions.

## Confidential issue indicators

Confidential issues are visually different from regular issues in a few ways.
In the **Issues** and **Issue boards** pages, you can see the confidential (**{eye-slash}**) icon
next to issues marked as confidential.

If you don't have [enough permissions](#who-can-see-confidential-issues),
you cannot see confidential issues at all.

Likewise, while inside the issue, you can see the confidential (**{eye-slash}**) icon right next to
the issue number. There is also an indicator in the comment area that the
issue you are commenting on is confidential.

There is also an indicator on the sidebar denoting confidentiality.

Every change from regular to confidential and vice versa, is indicated by a
system note in the issue's comments, for example:

> - **{eye-slash}** Jo Garcia made the issue confidential 5 minutes ago
> - **{eye}** Jo Garcia made the issue visible to everyone just now

## Merge requests for confidential issues

Although you can create confidential issues (and make existing issues confidential) in a public project, you cannot make confidential merge requests.
Learn how to create [merge requests for confidential issues](../merge_requests/confidential.md) that prevent leaks of private data.

## Related topics

- [Merge requests for confidential issues](../merge_requests/confidential.md)
- [Make an epic confidential](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [Add an internal note](../../discussions/_index.md#add-an-internal-note)
- [Security practices for confidential merge requests](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md#security-releases-critical-non-critical-as-a-developer) at GitLab
