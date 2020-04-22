# Issue Boards

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5554) in [GitLab 8.11](https://about.gitlab.com/releases/2016/08/22/gitlab-8-11-released/#issue-board).

## Overview

The GitLab Issue Board is a software project management tool used to plan,
organize, and visualize a workflow for a feature or product release.
It can be used as a [Kanban](https://en.wikipedia.org/wiki/Kanban_(development)) or a
[Scrum](https://en.wikipedia.org/wiki/Scrum_(software_development)) board.

It pairs issue tracking and project management,
keeping everything in the same place, so that you don't need to jump
between different platforms to organize your workflow.

With issue boards, you organize your issues in lists that correspond to
their assigned labels, visualizing issues designed as cards throughout those lists.

You define your process, and GitLab organizes it for you. You add your labels
then create the corresponding list to pull in your existing issues. When
you're ready, you can drag and drop your issue cards from one step to the next.

![GitLab issue board - Core](img/issue_boards_core.png)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch a [video presentation](https://youtu.be/UWsJ8tkHAa8) of
the Issue Board feature (introduced in GitLab 8.11 - August 2016).

### Advanced features of issue boards

- Create multiple issue boards per project.
- Create multiple issue boards per group. **(PREMIUM)**
- Add lists for [assignees](#assignee-lists-premium) and [milestones](#milestone-lists-premium). **(PREMIUM)**

Check all the [GitLab Enterprise features for issue boards](#gitlab-enterprise-features-for-issue-boards).

![GitLab issue boards - Premium](img/issue_boards_premium.png)

---

## How it works

The Issue Board feature builds on GitLab's existing
[issue tracking functionality](issues/index.md#issues-list) and
[labels](labels.md) by using them as lists of the Scrum board.

With issue boards you can have a different view of your issues while
maintaining the same filtering and sorting abilities you see across the
issue tracker. An issue board is based on its project's label structure, so it
applies the same descriptive labels to indicate placement on the board, keeping
consistency throughout the entire development lifecycle.

An issue board shows you what issues your team is working on, who is assigned to each,
and where in the workflow those issues are.

You create issues, host code, perform reviews, build, test,
and deploy from one single platform. Issue boards help you to visualize
and manage the entire process in GitLab.

With [multiple issue boards](#use-cases-for-multiple-issue-boards),
you go even further, as you can not only keep yourself and your project
organized from a broader perspective with one issue board per project,
but also allow your team members to organize their own workflow by creating
multiple issue boards within the same project.

## Use cases

There are many ways to use GitLab issue boards tailored to your own preferred workflow.
Here are some common use cases for issue boards.

### Use cases for a single issue board

With the GitLab Workflow you can discuss proposals in issues, categorize them
with labels, and from there, organize and prioritize them with issue boards.

For example, let's consider this simplified development workflow:

1. You have a repository that hosts your application's codebase, and your team actively contributes code.
1. Your **backend** team starts working on a new implementation, gathers feedback and approval, and
   passes it over to the **frontend** team.
1. When frontend is complete, the new feature is deployed to a **staging** environment to be tested.
1. When successful, it's deployed to **production**.

If you have the labels "**backend**", "**frontend**", "**staging**", and
"**production**", and an issue board with a list for each, you can:

- Visualize the entire flow of implementations since the beginning of the development life cycle
  until deployed to production.
- Prioritize the issues in a list by moving them vertically.
- Move issues between lists to organize them according to the labels you've set.
- Add multiple issues to lists in the board by selecting one or more existing issues.

![issue card moving](img/issue_board_move_issue_card_list.png)

---

### Use cases for multiple issue boards

With [multiple issue boards](#multiple-issue-boards),
each team can have their own board to organize their workflow individually.

#### Scrum team

With multiple issue boards, each team has one board. Now you can move issues through each
part of the process. For instance: **To Do**, **Doing**, and **Done**.

#### Organization of topics

Create lists to order issues by topic and quickly change them between topics or groups,
such as between **UX**, **Frontend**, and **Backend**. The changes are reflected across boards,
as changing lists updates the labels on each issue accordingly.

#### Advanced team handover

For example, suppose we have a UX team with an issue board that contains:

- **To Do**
- **Doing**
- **Frontend**

When finished with something, they move the card to **Frontend**. The Frontend team's board looks like:

- **Frontend**
- **Doing**
- **Done**

Cards finished by the UX team automatically appear in the **Frontend** column when they are ready
for them.

NOTE: **Note:**
For a broader use case, please see the blog post
[GitLab Workflow, an Overview](https://about.gitlab.com/blog/2016/10/25/gitlab-workflow-an-overview/#gitlab-workflow-use-case-scenario).
For a real use case example, you can read why
[Codepen decided to adopt issue boards](https://about.gitlab.com/blog/2017/01/27/codepen-welcome-to-gitlab/#project-management-everything-in-one-place)
to improve their workflow with multiple boards.

#### Quick assignments

Create lists for each of your team members and quickly drag and drop issues onto each team member's
list.

## Issue board terminology

An **issue board** represents a unique view of your issues. It can have multiple lists with each
list consisting of issues represented by cards.

A **list** is a column on the issue board that displays issues matching certain attributes.
In addition to the default "Open" and "Closed" lists, each additional list shows issues matching
your chosen label, assignee, or milestone. On the top of each list you can see the number of issues
that belong to it. Types of lists include:

- **Open** (default): all open issues that do not belong to one of the other lists.
  Always appears as the leftmost list.
- **Closed** (default): all closed issues. Always appears as the rightmost list.
- **Label list**: all open issues for a label.
- [**Assignee list**](#assignee-lists-premium): all open issues assigned to a user.
- [**Milestone list**](#milestone-lists-premium): all open issues for a milestone.

A **Card** is a box on a list, and it represents an issue. You can drag cards from one list to
another to change their label, assignee, or milestone. The information you can see on a
card includes:

- Issue title
- Associated labels
- Issue number
- Assignee

## Permissions

Users with the [Reporter and higher roles](../permissions.md) can use all the functionality of the
Issue Board feature to create or delete lists and drag issues from one list to another.

## GitLab Enterprise features for issue boards

GitLab issue boards are available on GitLab Core and GitLab.com Free tiers, but some
advanced functionality is present in [higher tiers only](https://about.gitlab.com/pricing/).

### Summary of features per tier

Different issue board features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Tier             | Number of Project issue boards | Number of Group issue boards | Configurable issue boards | Assignee lists |
|------------------|--------------------------------|------------------------------|---------------------------|----------------|
| Core / Free      | Multiple                       | 1                            | No                        | No             |
| Starter / Bronze | Multiple                       | 1                            | Yes                       | No             |
| Premium / Silver | Multiple                       | Multiple                     | Yes                       | Yes            |
| Ultimate / Gold  | Multiple                       | Multiple                     | Yes                       | Yes            |

### Multiple issue boards

> - [Introduced](https://about.gitlab.com/releases/2016/10/22/gitlab-8-13-released/) in GitLab 8.13.
> - Multiple issue boards per project [moved](https://gitlab.com/gitlab-org/gitlab-foss/issues/53811) to [GitLab Core](https://about.gitlab.com/pricing/) in GitLab 12.1.
> - Multiple issue boards per group are available in [GitLab Premium](https://about.gitlab.com/pricing/).

Multiple issue boards allow for more than one issue board for a given project or group.
This is great for large projects with more than one team or in situations where a repository is used
to host the code of multiple products.

Using the search box at the top of the menu, you can filter the listed boards.

When you have ten or more boards available, a **Recent** section is also shown in the menu, with
shortcuts to your last four visited boards.

![Multiple issue boards](img/issue_boards_multiple.png)

When you're revisiting an issue board in a project or group with multiple boards,
GitLab automatically loads the last board you visited.

#### Create an issue board

To create a new issue board:

1. Click the dropdown with the current board name in the upper left corner of the Issue Boards page.
1. Click **Create new board**.
1. Enter the new board's name and select its scope: milestone, labels, assignee, or weight.

#### Delete an issue board

To delete the currently active issue board:

1. Click the dropdown with the current board name in the upper left corner of the Issue Boards page.
1. Click **Delete board**.
1. Click **Delete** to confirm.

### Configurable issue boards **(STARTER)**

> [Introduced](https://about.gitlab.com/releases/2017/11/22/gitlab-10-2-released/#issue-boards-configuration) in [GitLab Starter](https://about.gitlab.com/pricing/) 10.2.

An issue board can be associated with a GitLab [Milestone](milestones/index.md#milestones),
[Labels](labels.md), Assignee and Weight
which will automatically filter the Board issues according to these fields.
This allows you to create unique boards according to your team's need.

![Create scoped board](img/issue_board_creation.png)

You can define the scope of your board when creating it or by clicking the "Edit board" button.
Once a milestone, assignee or weight is assigned to an issue board, you will no longer be able to
filter through these in the search bar. In order to do that, you need to remove the desired scope
(for example, milestone, assignee, or weight) from the issue board.

![Edit board configuration](img/issue_board_edit_button.png)

If you don't have editing permission in a board, you're still able to see the configuration by
clicking **View scope**.

![Viewing board configuration](img/issue_board_view_scope.png)

---

### Focus mode

> - [Introduced]((https://about.gitlab.com/releases/2017/04/22/gitlab-9-1-released/#issue-boards-focus-mode-ees-eep)) in [GitLab Starter](https://about.gitlab.com/pricing/) 9.1.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212331) to GitLab Core in 12.10.

Click the button at the top right to toggle focus mode on and off. In focus mode, the navigation UI
is hidden, allowing you to focus on issues in the board.

![Board focus mode](img/issue_board_focus_mode.gif)

---

### Sum of issue weights **(STARTER)**

The top of each list indicates the sum of issue weights for the issues that
belong to that list. This is useful when using boards for capacity allocation,
especially in combination with [assignee lists](#assignee-lists-premium).

![issue board summed weights](img/issue_board_summed_weights.png)

---

### Group issue boards **(PREMIUM)**

> [Introduced](https://about.gitlab.com/releases/2017/09/22/gitlab-10-0-released/#group-issue-boards) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.0.

Accessible at the group navigation level, a group issue board offers the same features as a project-level board,
but it can display issues from all projects in that
group and its descendant subgroups. Similarly, you can only filter by group labels for these
boards. When updating milestones and labels for an issue through the sidebar update mechanism, again only
group-level objects are available.

NOTE: **Note:**
Multiple group issue boards were originally [introduced](https://about.gitlab.com/releases/2017/09/22/gitlab-10-0-released/#group-issue-boards) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.0, and one group issue board per group was made available in GitLab Core 10.6.

![Group issue board](img/group_issue_board.png)

---

### Assignee lists **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/5784) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.0.

Like in a regular list that shows all issues with a chosen label, you can add
an assignee list that shows all issues assigned to a user.
You can have a board with both label lists and assignee lists. To add an
assignee list:

1. Click **Add list**.
1. Select the **Assignee list** tab.
1. Search and click the user you want to add as an assignee.

Now that the assignee list is added, you can assign or unassign issues to that user
by [dragging issues](#drag-issues-between-lists) to and from an assignee list.
To remove an assignee list, just as with a label list, click the trash icon.

![Assignee lists](img/issue_board_assignee_lists.png)

---

### Milestone lists **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/6469) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2.

You're also able to create lists of a milestone. These are lists that filter issues by the assigned
milestone, giving you more freedom and visibility on the issue board. To add a milestone list:

1. Click **Add list**.
1. Select the **Milestone** tab.
1. Search and click the milestone.

Similar to the assignee lists, you're now able to [drag issues](#drag-issues-between-lists)
to and from a milestone list to manipulate the milestone of the dragged issues.
As in other list types, click the trash icon to remove a list.

![Milestone lists](img/issue_board_milestone_lists.png)

---

## Work In Progress limits **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/11403) in GitLab 12.7

You can set Work In Progress (WIP) limits per issues list. When a limit is set, the list's header
shows the number of issues in the list and the soft limit of issues.

Examples:

- You have a list with four issues, and a limit of five, the header will show **4/5**.
  If you exceed the limit, the current number of issues is shown in red.
- You have a list with five issues with a limit of five. When you move another issue to that list,
  the list's header displays **6/5**, with the six shown in red.

To set a WIP limit for a list:

1. Navigate to a Project or Group board of which you're a member.
1. Click the Settings icon (**{settings}**) in a list's header.
1. Next to **Work In Progress Limit**, click **Edit**.
1. Enter the maximum number of issues.
1. Press <kbd>Enter</kbd> to save.

## Blocked issues

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/34723) in GitLab 12.8.

If an issue is blocked by another issue, an icon appears next to its title to indicate its blocked
status.

![Blocked issues](img/issue_boards_blocked_icon_v12_8.png)

---

## Actions you can take on an issue board

- [Create a new list](#create-a-new-list).
- [Delete an existing list](#delete-a-list).
- [Add issues to a list](#add-issues-to-a-list).
- [Remove an issue from a list](#remove-an-issue-from-a-list).
- [Filter issues](#filter-issues) that appear across your issue board.
- [Create workflows](#create-workflows).
- [Drag issues between lists](#drag-issues-between-lists).
- [Mulit-select issue cards](#multi-select-issue-cards).
- [Re-order issues in lists](#issue-ordering-in-a-list).
- Drag and reorder the lists.
- Change issue labels (by dragging an issue between lists).
- Close an issue (by dragging it to the **Done** list).

If you're not able to do some of the things above, make sure you have the right
[permissions](#permissions).

### First time using an issue board

The first time you open an issue board, you are presented with
the default lists (**Open** and **Closed**) and a welcome message that gives
you two options. You can either:

- Create a predefined set of labels (by default: **To Do** and **Doing**) and create their
  corresponding lists to the issue board.
- Opt-out and use your own lists.

![issue board welcome message](img/issue_board_welcome_message.png)

If you choose to use and create the predefined lists, they will appear as empty
because the labels associated to them will not exist up until that moment,
which means the system has no way of populating them automatically. That's of
course if the predefined labels don't already exist. If any of them does exist,
the list will be created and filled with the issues that have that label.

### Create a new list

Create a new list by clicking the **Add list** button in the upper right corner of the issue board.

![issue board welcome message](img/issue_board_add_list.png)

Then, choose the label or user to create the list from. The new list will be inserted
at the end of the lists, before **Done**. Moving and reordering lists is as
easy as dragging them around.

To create a list for a label that doesn't yet exist, create the label by
choosing **Create new label**. This creates the label immediately and adds it to the dropdown.
You can now choose it to create a list.

### Delete a list

To delete a list from the issue board, use the small trash icon present
in the list's heading. A confirmation dialog will appear for you to confirm.

Deleting a list doesn't have any effect in issues and labels, it's just the
list view that is removed. You can always add it back later if you need.

### Add issues to a list

You can add issues to a list by clicking the **Add issues** button
present in the upper right corner of the issue board. This will open up a modal
window where you can see all the issues that do not belong to any list.

Select one or more issues by clicking the cards and then click **Add issues**
to add them to the selected list. You can limit the issues you want to add to
the list by filtering by author, assignee, milestone, and label.

![Bulk adding issues to lists](img/issue_boards_add_issues_modal.png)

---

### Remove an issue from a list

Removing an issue from a list can be done by clicking the issue card and then
clicking the **Remove from board** button in the sidebar. The
respective label is removed.

![Remove issue from list](img/issue_boards_remove_issue.png)

---

### Filter issues

You should be able to use the filters on top of your issue board to show only
the results you want. This is similar to the filtering used in the issue tracker
since the metadata from the issues and labels are re-used in the issue board.

You can filter by author, assignee, milestone, and label.

### Create workflows

By reordering your lists, you can create workflows. As lists in issue boards are
based on labels, it works out of the box with your existing issues. So if you've
already labeled things with 'Backend' and 'Frontend', the issue appears in
the lists as you create them. In addition, this means you can easily move
something between lists by changing a label.

A typical workflow of using an issue board would be:

1. You have [created](labels.md#label-management) and [prioritized](labels.md#label-priority)
   labels so that you can easily categorize your issues.
1. You have a bunch of issues (ideally labeled).
1. You visit the issue board and start [creating lists](#create-a-new-list) to
   create a workflow.
1. You move issues around in lists so that your team knows who should be working
   on what issue.
1. When the work by one team is done, the issue can be dragged to the next list
   so someone else can pick up.
1. When the issue is finally resolved, the issue is moved to the **Done** list
   and gets automatically closed.

For instance you can create a list based on the label of 'Frontend' and one for
'Backend'. A designer can start working on an issue by adding it to the
'Frontend' list. That way, everyone knows that this issue is now being
worked on by the designers. Then, once they're done, all they have to do is
drag it over to the next list, 'Backend', where a backend developer can
eventually pick it up. Once they’re done, they move it to **Done**, to close the
issue.

This process can be seen clearly when visiting an issue since with every move
to another list the label changes and a system not is recorded.

![issue board system notes](img/issue_board_system_notes.png)

---

### Drag issues between lists

When dragging issues between lists, different behavior occurs depending on the source list and the target list.

|                            | To Open            | To Closed    | To label `B` list            | To assignee `Bob` list                |
|----------------------------|--------------------|--------------|------------------------------|---------------------------------------|
| From Open                  | -                  | Issue closed | `B` added                    | `Bob` assigned                        |
| From Closed                | Issue reopened     | -            | Issue reopened<br/>`B` added | Issue reopened<br/>`Bob` assigned     |
| From label `A` list        | `A` removed        | Issue closed | `A` removed<br/>`B` added    | `Bob` assigned                        |
| From assignee `Alice` list | `Alice` unassigned | Issue closed | `B` added                    | `Alice` unassigned<br/>`Bob` assigned |

### Multi-select issue cards

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/18954) in GitLab 12.4.

You can select multiple issue cards, then drag the group to another position within the list, or to another list. This makes it faster to reorder many issues at once.

To select and move multiple cards:

1. Select each card with <kbd>Ctrl</kbd>+`Click` on Windows or Linux, or <kbd>Cmd</kbd>+`Click` on MacOS.
1. Drag one of the selected cards to another position or list and all selected cards are moved.

![Multi-select Issue Cards](img/issue_boards_multi_select_v12_4.png)

---

### Issue ordering in a list

When visiting a board, issues appear ordered in any list. You're able to change
that order by dragging and dropping the issues. The changed order will be saved
to the system so that anybody who visits the same board later will see the reordering,
with some exceptions.

The first time a given issue appears in any board (that is, the first time a user
loads a board containing that issue), it is ordered with
respect to other issues in that list according to [Priority order](labels.md#label-priority).

At that point, that issue is assigned a relative order value by the system
representing its relative order with respect to the other issues in the list. Any time
you drag-and-drop reorder that issue, its relative order value changes accordingly.

Also, any time that issue appears in any board when it's loaded by a user,
the updated relative order value is used for the ordering. (It's only the first
time an issue appears that it takes from the Priority order mentioned above.) This means that
if issue `A` is drag-and-drop reordered to be above issue `B` by any user in
a given board inside your GitLab instance, any time those two issues are subsequently
loaded in any board in the same instance (could be a different project board or a different group
board, for example), that ordering is maintained.

This ordering also affects [issue lists](issues/sorting_issue_lists.md).
Changing the order in an issue board changes the ordering in an issue list,
and vice versa.

## Tips

A few things to remember:

- Moving an issue between lists removes the label from the list it came from
  and adds the label from the list it goes to.
- An issue can exist in multiple lists if it has more than one label.
- Lists are populated with issues automatically if the issues are labeled.
- Clicking the issue title inside a card takes you to that issue.
- Clicking a label inside a card quickly filters the entire issue board
  and show only the issues from all lists that have that label.
- For performance and visibility reasons, each list shows the first 20 issues
  by default. If you have more than 20 issues, start scrolling down and the next
  20 appears.
