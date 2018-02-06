# Confidential issues

> [Introduced][ce-3282] in GitLab 8.6.

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

>**Note:** If you don't have [enough permissions](#permissions-and-access-to-confidential-issues),
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
least [Reporter access][permissions]. However, a guest user can also create
confidential issues, but can only view the ones that they created themselves.

Confidential issues are also hidden in search results for unprivileged users.
For example, here's what a user with Master and Guest access sees in the
project's search results respectively.

| Master access | Guest access |
| :-----------: | :----------: |
| ![Confidential issues search master](img/confidential_issues_search_master.png) | ![Confidential issues search guest](img/confidential_issues_search_guest.png) |

[permissions]: ../../permissions.md#project
[ce-3282]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3282
