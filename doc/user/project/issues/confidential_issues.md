---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Confidential issues

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3282) in GitLab 8.6.

Confidential issues are issues visible only to members of a project with
[sufficient permissions](#permissions-and-access-to-confidential-issues).
Confidential issues can be used by open source projects and companies alike to
keep security vulnerabilities private or prevent surprises from leaking out.

## Making an issue confidential

You can make an issue confidential during issue creation or by editing
an existing one.

When you create a new issue, a checkbox right below the text area is available
to mark the issue as confidential. Check that box and hit the **Submit issue**
button to create the issue. For existing issues, edit them, check the
confidential checkbox and hit **Save changes**.

![Creating a new confidential issue](img/confidential_issues_create.png)

## Modifying issue confidentiality

There are two ways to change an issue's confidentiality.

The first way is to edit the issue and mark/unmark the confidential checkbox.
Once you save the issue, it will change the confidentiality of the issue.

The second way is to locate the Confidentiality section in the sidebar and click
**Edit**. A popup should appear and give you the option to turn on or turn off confidentiality.

| Turn off confidentiality | Turn on confidentiality |
| :-----------: | :----------: |
| ![Turn off confidentiality](img/turn_off_confidentiality.png) | ![Turn on confidentiality](img/turn_on_confidentiality.png) |

Every change from regular to confidential and vice versa, is indicated by a
system note in the issue's comments.

![Confidential issues system notes](img/confidential_issues_system_notes.png)

## Indications of a confidential issue

NOTE: **Note:**
If you don't have [enough permissions](#permissions-and-access-to-confidential-issues),
you won't be able to see the confidential issues at all.

There are a few things that visually separate a confidential issue from a
regular one. In the issues index page view, you can see the eye-slash icon
next to the issues that are marked as confidential.

![Confidential issues index page](img/confidential_issues_index_page.png)

---

Likewise, while inside the issue, you can see the eye-slash icon right next to
the issue number, but there is also an indicator in the comment area that the
issue you are commenting on is confidential.

![Confidential issue page](img/confidential_issues_issue_page.png)

There is also an indicator on the sidebar denoting confidentiality.

| Confidential issue | Not confidential issue |
| :-----------: | :----------: |
| ![Sidebar confidential issue](img/sidebar_confidential_issue.png) | ![Sidebar not confidential issue](img/sidebar_not_confidential_issue.png) |

## Permissions and access to confidential issues

There are two kinds of level access for confidential issues. The general rule
is that confidential issues are visible only to members of a project with at
least [Reporter access](../../permissions.md#project-members-permissions). However, a guest user can also create
confidential issues, but can only view the ones that they created themselves.

Confidential issues are also hidden in search results for unprivileged users.
For example, here's what a user with Maintainer and Guest access sees in the
project's search results respectively.

| Maintainer access | Guest access |
| :-----------: | :----------: |
| ![Confidential issues search master](img/confidential_issues_search_master.png) | ![Confidential issues search guest](img/confidential_issues_search_guest.png) |

## Merge Requests for Confidential Issues

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/58583) in GitLab 12.1.

To help prevent confidential information being leaked from a public project
in the process of resolving a confidential issue, confidential issues can be
resolved by creating a merge request from a private fork.

The merge request created will target the default branch of the private fork,
not the default branch of the public upstream project. This prevents the merge
request, branch, and commits entering the public repository, and revealing
confidential information prematurely. When the confidential commits are ready
to be made public, this can be done by opening a merge request from the private
fork to the public upstream project.

TIP: **Best practice:**
If you create a long-lived private fork in the same group or in a sub-group of
the original upstream, all the users with Developer membership to the public
project will also have the same permissions in the private project. This way,
all the Developers, who have access to view confidential issues, will have a
streamlined workflow for fixing them.

### How it works

On a confidential issue, a **Create confidential merge request** button is
available. Clicking on it will open a dropdown where you can choose to
**Create confidential merge request and branch** or **Create branch**:

| Create confidential merge request | Create branch |
| :-------------------------------: | :-----------: |
| ![Create Confidential Merge Request Dropdown](img/confidential_mr_dropdown_v12_1.png) | ![Create Confidential Branch Dropdown](img/confidential_mr_branch_dropdown_v12_1.png) |

The **Project** dropdown includes the list of private forks the user is a member
of as at least a Developer and merge requests are enabled.

Whenever the **Branch name** and **Source (branch or tag)** fields change, the
availability of the target or source branch will be checked. Both branches should
be available in the private fork selected.

By clicking the **Create confidential merge request** button, GitLab will create
the branch and merge request in the private fork. When you choose
**Create branch**, GitLab will only create the branch.

Once the branch is created in the private fork, developers can now push code to
that branch to fix the confidential issue.
