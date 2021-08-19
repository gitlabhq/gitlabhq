---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Confidential issues **(FREE)**

Confidential issues are [issues](index.md) visible only to members of a project with
[sufficient permissions](#permissions-and-access-to-confidential-issues).
Confidential issues can be used by open source projects and companies alike to
keep security vulnerabilities private or prevent surprises from leaking out.

## Making an issue confidential

You can make an issue confidential during issue creation or by editing
an existing one.

When you create a new issue, a checkbox right below the text area is available
to mark the issue as confidential. Check that box and hit the **Create issue**
button to create the issue. For existing issues, edit them, check the
confidential checkbox and hit **Save changes**.

![Creating a new confidential issue](img/confidential_issues_create.png)

## Modifying issue confidentiality

There are two ways to change an issue's confidentiality.

The first way is to edit the issue and toggle the confidentiality checkbox.
After you save the issue, the confidentiality of the issue is updated.

The second way is to locate the Confidentiality section in the sidebar and click
**Edit**. A popup should appear and give you the option to turn on or turn off confidentiality.

| Turn off confidentiality | Turn on confidentiality |
| :-----------: | :----------: |
| ![Turn off confidentiality](img/turn_off_confidentiality.png) | ![Turn on confidentiality](img/turn_on_confidentiality.png) |

Every change from regular to confidential and vice versa, is indicated by a
system note in the issue's comments.

![Confidential issues system notes](img/confidential_issues_system_notes.png)

## Indications of a confidential issue

There are a few things that visually separate a confidential issue from a
regular one. In the issues index page view, you can see the eye-slash (**(eye-slash)**) icon
next to the issues that are marked as confidential:

![Confidential issues index page](img/confidential_issues_index_page.png)

If you don't have [enough permissions](#permissions-and-access-to-confidential-issues),
you cannot see confidential issues at all.

---

Likewise, while inside the issue, you can see the eye-slash icon right next to
the issue number. There is also an indicator in the comment area that the
issue you are commenting on is confidential.

![Confidential issue page](img/confidential_issues_issue_page.png)

There is also an indicator on the sidebar denoting confidentiality.

| Confidential issue | Not confidential issue |
| :-----------: | :----------: |
| ![Sidebar confidential issue](img/sidebar_confidential_issue.png) | ![Sidebar not confidential issue](img/sidebar_not_confidential_issue.png) |

## Merge requests for confidential issues

Although you can make issues be confidential in public projects, you cannot make
confidential merge requests. Learn how to create [merge requests for confidential issues](../merge_requests/confidential.md)
that prevent leaks of private data.

## Permissions and access to confidential issues

There are two kinds of level access for confidential issues. The general rule
is that confidential issues are visible only to members of a project with at
least [Reporter access](../../permissions.md#project-members-permissions). However, a guest user can also create
confidential issues, but can only view the ones that they created themselves.

Confidential issues are also hidden in search results for unprivileged users.
For example, here's what a user with the [Maintainer role](../../permissions.md) and Guest access
sees in the project's search results respectively.

| Maintainer role                                                                        | Guest access                                                                     |
|:---------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------|
| ![Confidential issues search by maintainer](img/confidential_issues_search_master.png) | ![Confidential issues search by guest](img/confidential_issues_search_guest.png) |

## Related links

- [Merge requests for confidential issues](../merge_requests/confidential.md)
- [Make an epic confidential](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [Mark a comment as confidential](../../discussions/index.md#mark-a-comment-as-confidential)
- [Security practices for confidential merge requests](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer) at GitLab
