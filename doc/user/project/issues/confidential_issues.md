---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Confidential issues **(FREE)**

Confidential issues are [issues](index.md) visible only to members of a project with
[sufficient permissions](#permissions-and-access-to-confidential-issues).
Confidential issues can be used by open source projects and companies alike to
keep security vulnerabilities private or prevent surprises from leaking out.

## Make an issue confidential

You can make an issue confidential when you create or edit an issue.

### In a new issue

When you create a new issue, a checkbox right below the text area is available
to mark the issue as confidential. Check that box and select **Create issue**
to create the issue.

When you create a confidential issue in a project, the project becomes listed in the **Contributed projects** section in your [profile](../../profile/index.md). **Contributed projects** does not show information about the confidential issue; it only shows the project name.

To create a confidential issue:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. On the left sidebar, at the top, select **Create new** (**{plus}**).
1. From the dropdown list, select **New issue**.
1. Complete the [fields](create_issues.md#fields-in-the-new-issue-form).
   - Select the **This issue is confidential...** checkbox.
1. Select **Create issue**.

### In an existing issue

To change the confidentiality of an existing issue:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Plan > Issues**.
1. Select the title of your issue to view it.
1. On the right sidebar, next to **Confidentiality**, select **Edit**.
1. Select **Turn on** (or **Turn off** to make the issue non-confidential).

Alternatively, you can use the `/confidential` [quick action](../quick_actions.md#issues-merge-requests-and-epics).

## Who can see confidential issues

When an issue is made confidential, only users with at least the Reporter role
for the project have access to the issue.
Users with Guest or [Minimal](../../permissions.md#users-with-minimal-access) roles can't access
the issue even if they were actively participating before the change.

## Confidential issue indicators

Confidential issues are visually different from regular issues in a few ways.
In the issues index page view, you can see the confidential (**{eye-slash}**) icon
next to the issues that are marked as confidential:

![Confidential issues index page](img/confidential_issues_index_page.png)

If you don't have [enough permissions](#permissions-and-access-to-confidential-issues),
you cannot see confidential issues at all.

Likewise, while inside the issue, you can see the confidential (**{eye-slash}**) icon right next to
the issue number. There is also an indicator in the comment area that the
issue you are commenting on is confidential.

![Confidential issue page](img/confidential_issues_issue_page.png)

There is also an indicator on the sidebar denoting confidentiality.

| Confidential issue | Not confidential issue |
| :-----------: | :----------: |
| ![Sidebar confidential issue](img/sidebar_confidential_issue.png) | ![Sidebar not confidential issue](img/sidebar_not_confidential_issue.png) |

Every change from regular to confidential and vice versa, is indicated by a
system note in the issue's comments:

- **{eye-slash}** The issue is made confidential.
- **{eye}** The issue is made public.

![Confidential issues system notes](img/confidential_issues_system_notes_v15_4.png)

## Merge requests for confidential issues

Although you can create confidential issues (and make existing issues confidential) in a public project, you cannot make confidential merge requests.
Learn how to create [merge requests for confidential issues](../merge_requests/confidential.md) that prevent leaks of private data.

## Permissions and access to confidential issues

Access to confidential issues is by one of two routes. The general rule
is that confidential issues are visible only to members of a project with at
least the **Reporter role**.

However, a user with the **Guest role** can create
confidential issues, but can only view the ones that they created themselves.

Users with the Guest role or non-members can read the confidential issue if they are assigned to the issue.
When a Guest user or non-member is unassigned from a confidential issue,
they can no longer view it.

Confidential issues are hidden in search results for unprivileged users.
For example, here's what a user with the Maintainer role and the Guest role
sees in the project's search results:

| Maintainer role | Guest role |
|:----------------|:-----------|
| ![Confidential issues search by maintainer](img/confidential_issues_search_master.png) | ![Confidential issues search by guest](img/confidential_issues_search_guest.png) |

## Related topics

- [Merge requests for confidential issues](../merge_requests/confidential.md)
- [Make an epic confidential](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [Add an internal note](../../discussions/index.md#add-an-internal-note)
- [Security practices for confidential merge requests](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer) at GitLab
