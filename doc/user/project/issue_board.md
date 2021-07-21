---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Issue Boards **(FREE)**

The GitLab Issue Board is a software project management tool used to plan,
organize, and visualize a workflow for a feature or product release.
It can be used as a [Kanban](https://en.wikipedia.org/wiki/Kanban_(development)) or a
[Scrum](https://en.wikipedia.org/wiki/Scrum_(software_development)) board.

It pairs issue tracking and project management, keeping everything together,
so that you don't need to jump between different platforms to organize your workflow.

Issue boards build on the existing [issue tracking functionality](issues/index.md) and
[labels](labels.md). Your issues appear as cards in vertical lists, organized by their assigned
labels, [milestones](#milestone-lists), or [assignees](#assignee-lists).

Issue boards help you to visualize and manage your entire process in GitLab.
You add your labels, and then create the corresponding list for your existing issues.
When you're ready, you can drag your issue cards from one step to another one.

An issue board can show you the issues your team is working on, who is assigned to each,
and where the issues are in the workflow.

To let your team members organize their own workflows, use
[multiple issue boards](#use-cases-for-multiple-issue-boards). This allows creating multiple issue
boards in the same project.

![GitLab issue board - Core](img/issue_boards_core_v14_1.png)

Different issue board features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Tier     | Number of project issue boards | Number of [group issue boards](#group-issue-boards) | [Configurable issue boards](#configurable-issue-boards) | [Assignee lists](#assignee-lists) |
| -------- | ------------------------------ | --------------------------------------------------- | ------------------------------------------------------- | --------------------------------- |
| Free     | Multiple                       | 1                                                   | No                                                      | No                                |
| Premium  | Multiple                       | Multiple                                            | Yes                                                     | Yes                               |
| Ultimate | Multiple                       | Multiple                                            | Yes                                                     | Yes                               |

To learn more, visit [GitLab Enterprise features for issue boards](#gitlab-enterprise-features-for-issue-boards) below.

![GitLab issue board - Premium](img/issue_boards_premium_v14_1.png)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch a [video presentation](https://youtu.be/vjccjHI7aGI) of
the Issue Board feature.

## Multiple issue boards

> - Multiple issue boards per project [moved](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53811) to GitLab Free in 12.1.
> - Multiple issue boards per group are available in GitLab Premium.

Multiple issue boards allow for more than one issue board for a given project **(FREE)** or group **(PREMIUM)**.
This is great for large projects with more than one team or when a repository hosts the code of multiple products.

Using the search box at the top of the menu, you can filter the listed boards.

When you have ten or more boards available, a **Recent** section is also shown in the menu, with
shortcuts to your last four visited boards.

![Multiple issue boards](img/issue_boards_multiple_v13_6.png)

When you're revisiting an issue board in a project or group with multiple boards,
GitLab automatically loads the last board you visited.

### Create an issue board

To create a new issue board:

1. Click the dropdown with the current board name in the upper left corner of the Issue Boards page.
1. Click **Create new board**.
1. Enter the new board's name and select its scope: milestone, labels, assignee, or weight.

### Delete an issue board

To delete the currently active issue board:

1. Click the dropdown with the current board name in the upper left corner of the Issue Boards page.
1. Click **Delete board**.
1. Click **Delete** to confirm.

## Issue boards use cases

You can tailor GitLab issue boards to your own preferred workflow.
Here are some common use cases for issue boards.

For examples of using issue boards along with [epics](../group/epics/index.md),
[issue health status](issues/managing_issues.md#health-status), and
[scoped labels](labels.md#scoped-labels) for various Agile frameworks, check:

- The [How to use GitLab for Agile portfolio planning and project management](https://about.gitlab.com/blog/2020/11/11/gitlab-for-agile-portfolio-planning-project-management/) blog post (November 2020)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[Cross-project Agile work management with GitLab](https://www.youtube.com/watch?v=5J0bonGoECs) (15 min, July 2020)

### Use cases for a single issue board

With the [GitLab Flow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/) you can
discuss proposals in issues, label them, and organize and prioritize them with issue boards.

For example, let's consider this simplified development workflow:

1. You have a repository that hosts your application's codebase, and your team actively contributes code.
1. Your **backend** team starts working on a new implementation, gathers feedback and approval, and
   passes it over to the **frontend** team.
1. When frontend is complete, the new feature is deployed to a **staging** environment to be tested.
1. When successful, it's deployed to **production**.

If you have the labels **Backend**, **Frontend**, **Staging**, and
**Production**, and an issue board with a list for each, you can:

- Visualize the entire flow of implementations since the beginning of the development life cycle
  until deployed to production.
- Prioritize the issues in a list by moving them vertically.
- Move issues between lists to organize them according to the labels you've set.
- Add multiple issues to lists in the board by selecting one or more existing issues.

![issue card moving](img/issue_board_move_issue_card_list_v13_6.png)

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

NOTE:
For a broader use case, please see the blog post
[What is GitLab Flow?](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/).
For a real use case example, you can read why
[Codepen decided to adopt issue boards](https://about.gitlab.com/blog/2017/01/27/codepen-welcome-to-gitlab/#project-management-everything-in-one-place)
to improve their workflow with multiple boards.

#### Quick assignments

To quickly assign issues to your team members:

1. Create [assignee lists](#assignee-lists) for each team member.
1. Drag an issue onto the team member's list.

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
- [**Assignee list**](#assignee-lists): all open issues assigned to a user.
- [**Milestone list**](#milestone-lists): all open issues for a milestone.

A **Card** is a box on a list, and it represents an issue. You can drag cards from one list to
another to change their label, assignee, or milestone. The information you can see on a
card includes:

- Issue title
- Associated labels
- Issue number
- Assignee

## Permissions

Users with the [Reporter and higher roles](../permissions.md) can use all the functionality of the
Issue Board feature to create or delete lists. They can also drag issues from one list to another.

## How GitLab orders issues in a list

When visiting a board, issues appear ordered in any list. You're able to change
that order by dragging the issues. The changed order is saved, so that anybody who visits the same
board later sees the reordering, with some exceptions.

The first time an issue appears in any board (that is, the first time a user
loads a board containing that issue), it is ordered in relation to other issues in that list.
The order is done according to [label priority](labels.md#label-priority).

At this point, that issue is assigned a relative order value by the system,
with respect to the other issues in the list. Any time
you drag and reorder the issue, its relative order value changes accordingly.

Also, any time that issue appears in any board, the ordering is done according to
the updated relative order value. It's only the first
time an issue appears that it takes from the priority order mentioned above. If a user in your GitLab instance
drags issue `A` above issue `B`, the ordering is maintained when these two issues are subsequently
loaded in any board in the same instance. This could be a different project board or a different group
board, for example.

This ordering also affects [issue lists](issues/sorting_issue_lists.md).
Changing the order in an issue board changes the ordering in an issue list,
and vice versa.

### GraphQL-based issue boards

<!-- This anchor is linked from #blocked-issues as well. -->

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285074) in GitLab 13.9.
> - [Deployed behind a feature flag](../feature_flags.md), enabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/248908) in GitLab 14.1
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-graphql-based-issue-boards). **(FREE SELF)**

There can be
[risks when disabling released features](../feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

Using GraphQL-based boards gives you these
additional features:

- [Edit more issue attributes](#edit-an-issue)
- [View blocked issues](#blocked-issues)

Learn more about the known issues in [epic 5596](https://gitlab.com/groups/gitlab-org/-/epics/5596).

## GitLab Enterprise features for issue boards

GitLab issue boards are available on the GitLab Free tier, but some
advanced functionality is present in [higher tiers only](https://about.gitlab.com/pricing/).

### Configurable issue boards **(PREMIUM)**

> - Setting current iteration as scope [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196804) in GitLab 13.8.
> - Moved to GitLab Premium in 13.9.

An issue board can be associated with a [milestone](milestones/index.md#milestones),
[labels](labels.md), assignee, weight, and current [iteration](../group/iterations/index.md),
which automatically filter the board issues accordingly.
This allows you to create unique boards according to your team's need.

![Create scoped board](img/issue_board_creation_v13_6.png)

You can define the scope of your board when creating it or by clicking the **Edit board** button.
After a milestone, iteration, assignee, or weight is assigned to an issue board, you can no longer
filter through these in the search bar. In order to do that, you need to remove the desired scope
(for example, milestone, assignee, or weight) from the issue board.

If you don't have editing permission in a board, you're still able to see the configuration by
clicking **View scope**.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch a [video presentation](https://youtu.be/m5UTNCSqaDk) of
the Configurable Issue Board feature.

### Focus mode

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28597) to GitLab Free SaaS in 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212331) to GitLab Free self-managed in 13.0.

To enable or disable focus mode, select the **Toggle focus mode** button (**{maximize}**) at the top
right. In focus mode, the navigation UI is hidden, allowing you to focus on issues in the board.

### Sum of issue weights **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

The top of each list indicates the sum of issue weights for the issues that
belong to that list. This is useful when using boards for capacity allocation,
especially in combination with [assignee lists](#assignee-lists).

![issue board summed weights](img/issue_board_summed_weights_v13_6.png)

### Group issue boards

Accessible at the group navigation level, a group issue board offers the same features as a project-level board.
It can display issues from all projects that fall under the group and its descendant subgroups.

Users on GitLab Free can use a single group issue board.

### Assignee lists **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5784) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.0.

As in a regular list showing all issues with a chosen label, you can add
an assignee list that shows all issues assigned to a user.
You can have a board with both label lists and assignee lists. To add an
assignee list:

1. Select **Create list**.
1. Select **Assignee**.
1. In the dropdown, select a user.
1. Select **Add to board**.

Now that the assignee list is added, you can assign or unassign issues to that user
by [moving issues](#move-issues-and-lists) to and from an assignee list.
To remove an assignee list, just as with a label list, click the trash icon.

![Assignee lists](img/issue_board_assignee_lists_v14_1.png)

### Milestone lists **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6469) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2.

You're also able to create lists of a milestone. These are lists that filter issues by the assigned
milestone, giving you more freedom and visibility on the issue board. To add a milestone list:

1. Select **Create list**.
1. Select **Milestone**.
1. In the dropdown, select a milestone.
1. Select **Add to board**.

Like the assignee lists, you're able to [drag issues](#move-issues-and-lists)
to and from a milestone list to manipulate the milestone of the dragged issues.
As in other list types, click the trash icon to remove a list.

![Milestone lists](img/issue_board_milestone_lists_v14_1.png)

### Iteration lists **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250479) in GitLab 13.11.
> - [Deployed behind the `board_new_list` and `iteration_board_lists` feature flags](../feature_flags.md), enabled by default.
> - Enabled on GitLab.com.
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to disable the feature flags: [`board_new_list`](#enable-or-disable-new-add-list-form) and [`iteration_board_lists`](#enable-or-disable-iteration-lists-in-boards). **(PREMIUM SELF)**

There can be
[risks when disabling released features](../feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

You're also able to create lists of an iteration.
These are lists that filter issues by the assigned
iteration. To add an iteration list:

1. Select **Create list**.
1. Select **Iteration**.
1. In the dropdown, select an iteration.
1. Select **Add to board**.

Like the milestone lists, you're able to [drag issues](#move-issues-and-lists)
to and from a iteration list to manipulate the iteration of the dragged issues.

![Iteration lists](img/issue_board_iteration_lists_v13_10.png)

### Group issues in swimlanes **(PREMIUM)**

> - Grouping by epic [introduced](https://gitlab.com/groups/gitlab-org/-/epics/3352) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.6.
> - Editing issue titles in the issue sidebar [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232745) in GitLab 13.8.
> - Editing iteration in the issue sidebar [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/290232) in GitLab 13.9.

With swimlanes you can visualize issues grouped by epic.
Your issue board keeps all the other features, but with a different visual organization of issues.
This feature is available both at the project and group level.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video overview, see [Epics Swimlanes Walkthrough - 13.6](https://www.youtube.com/watch?v=nHC7-kz5P2g) (November 2020).

To group issues by epic in an issue board:

1. Select the **Group by** dropdown button.
1. Select **Epic**.

![Epics Swimlanes](img/epics_swimlanes_v14_1.png)

To edit an issue without leaving this view, select the issue card (not its title), and a sidebar
appears on the right. There you can see and edit the issue's: 

- Title
- Assignees
- Epic **PREMIUM**
- Milestone
- Time tracking value (view only)
- Due date
- Labels
- Weight
- Notifications setting

You can also [drag issues](#move-issues-and-lists) to change their position and epic assignment:

- To reorder an issue, drag it to the new position within a list.
- To assign an issue to another epic, drag it to the epic's horizontal lane.
- To unassign an issue from an epic, drag it to the **Issues with no epic assigned** lane.
- To move an issue to another epic _and_ another list, at the same time, drag the issue diagonally.

![Drag issues between swimlanes](img/epics_swimlanes_drag_and_drop.png)

## Work In Progress limits **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11403) in GitLab 12.7
> - Moved to GitLab Premium in 13.9.

You can set a Work In Progress (WIP) limit for each issue list on an issue board. When a limit is
set, the list's header shows the number of issues in the list and the soft limit of issues.
You cannot set a WIP limit on the default lists (**Open** and **Closed**).

Examples:

- When you have a list with four issues and a limit of five, the header shows **4/5**.
  If you exceed the limit, the current number of issues is shown in red.
- You have a list with five issues with a limit of five. When you move another issue to that list,
  the list's header displays **6/5**, with the six shown in red.

To set a WIP limit for a list:

1. Navigate to a Project or Group board of which you're a member.
1. Click the settings icon in a list's header.
1. Next to **Work In Progress Limit**, click **Edit**.
1. Enter the maximum number of issues.
1. Press <kbd>Enter</kbd> to save.

## Blocked issues **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34723) in GitLab 12.8.
> - [View blocking issues when hovering over blocked icon](https://gitlab.com/gitlab-org/gitlab/-/issues/210452) in GitLab 13.10.

If an issue is blocked by another issue, an icon appears next to its title to indicate its blocked
status.

When you hover over the blocked icon (**{issue-block}**), a detailed information popover is displayed.

This feature is only supported when using the [GraphQL-based boards](#graphql-based-issue-boards). The feature is enabled by default regardless when you use group issue boards in epic swimlanes mode.

![Blocked issues](img/issue_boards_blocked_icon_v13_10.png)

## Actions you can take on an issue board

- [Edit an issue](#edit-an-issue).
- [Create a new list](#create-a-new-list).
- [Remove an existing list](#remove-a-list).
- [Remove an issue from a list](#remove-an-issue-from-a-list).
- [Filter issues](#filter-issues) that appear across your issue board.
- [Create workflows](#create-workflows).
- [Move issues and lists](#move-issues-and-lists).
- [Multi-select issue cards](#multi-select-issue-cards).
- Drag and reorder the lists.
- Change issue labels (by dragging an issue between lists).
- Close an issue (by dragging it to the **Closed** list).

If you're not able to do some of the things above, make sure you have the right
[permissions](#permissions).

### Edit an issue

You can edit an issue without leaving the board view.
To open the right sidebar, select an issue card (not its title).

You can edit the following issue attributes in the right sidebar:

- Assignees
- [Epic](../group/epics/index.md)
- Milestone
- Time tracking value (view only)
- Due date
- Labels
- [Weight](issues/issue_weight.md)
- Notifications setting

When you use [GraphQL-based boards](#graphql-based-issue-boards), you can also edit the following issue attributes:

- Title
- [Iteration](../group/iterations/index.md)
- Confidentiality

### Create a new list

Create a new list by clicking the **Create** button in the upper right corner of the issue board.

![creating a new list in an issue board](img/issue_board_add_list_v14_1.png)

Then, choose the label, user or milestone to base the new list on. The new list is inserted
at the end of the lists, before **Closed**. To move and reorder lists, drag them around.

### Remove a list

Removing a list doesn't have any effect on issues and labels, as it's just the
list view that's removed. You can always create it again later if you need.

To remove a list from an issue board:

1. On the top of the list you want to remove, select the **List settings** icon (**{settings}**).
   The list settings sidebar opens on the right.
1. Select **Remove list**. A confirmation dialog appears.
1. Select **OK**.

### Add issues to a list

> The **Add issues** button was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57329) in GitLab 13.11.

If your board is scoped to one or more attributes, go to the issues you want to add and apply the
same attributes as your board scope.

For example, to add an issue to a list scoped to the `Doing` label, in a group issue board:

1. Go to an issue in the group or one of the subgroups or projects.
1. Add the `Doing` label.

The issue should now show in the `Doing` list on your issue board.

### Remove an issue from a list

> The **Remove from board** button was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/229507) in GitLab 13.10.

When an issue should no longer belong to a list, you can remove it.
The steps depend on the scope of the list:

1. To open the right sidebar, select the issue card.
1. Remove what's keeping the issue in the list.
   If it's a label list, remove the label. If it's an [assignee list](#assignee-lists), unassign the user.

### Filter issues

You can use the filters on top of your issue board to show only
the results you want. It's similar to the filtering used in the [issue tracker](issues/index.md).

You can filter by the following:

- Assignee
- Author
- Epic
- Iteration ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6)
- Label
- Milestone
- My Reaction
- Release
- Weight

#### Filtering issues in a group board

When [filtering issues](#filter-issues) in a **group** board, keep this behavior in mind:

- Milestones: you can filter by the milestones belonging to the group and its descendant groups.
- Labels: you can only filter by the labels belonging to the group but not its descendant groups.

When you edit issues individually using the right sidebar, you can additionally select the
milestones and labels from the **project** that the issue is from.

### Create workflows

By reordering your lists, you can create workflows. As lists in issue boards are
based on labels, it works out of the box with your existing issues.

So if you've already labeled things with **Backend** and **Frontend**, the issue appears in
the lists as you create them. In addition, this means you can move something between lists by
changing a label.

A typical workflow of using an issue board would be:

1. You have [created](labels.md#label-management) and [prioritized](labels.md#label-priority)
   labels to categorize your issues.
1. You have a bunch of issues (ideally labeled).
1. You visit the issue board and start [creating lists](#create-a-new-list) to
   create a workflow.
1. You move issues around in lists so that your team knows who should be working
   on what issue.
1. When the work by one team is done, the issue can be dragged to the next list
   so someone else can pick it up.
1. When the issue is finally resolved, the issue is moved to the **Done** list
   and gets automatically closed.

For example, you can create a list based on the label of **Frontend** and one for
**Backend**. A designer can start working on an issue by adding it to the
**Frontend** list. That way, everyone knows that this issue is now being
worked on by the designers.

Then, when they're done, all they have to do is
drag it to the next list, **Backend**. Then, a backend developer can
eventually pick it up. When they're done, they move it to **Done**, to close the
issue.

This process can be seen clearly when visiting an issue. With every move
to another list, the label changes and a system note is recorded.

![issue board system notes](img/issue_board_system_notes_v13_6.png)

### Move issues and lists

You can move issues and lists by dragging them.

Prerequisites:

- A minimum of [Reporter](../permissions.md#project-members-permissions) access to a project in GitLab.

To move an issue, select the issue card and drag it to another position in its current list or
into a different list. Learn about possible effects in [Dragging issues between lists](#dragging-issues-between-lists).

To move a list, select its top bar, and drag it horizontally.
You can't move the **Open** and **Closed** lists, but you can hide them when editing an issue board.

#### Dragging issues between lists

To move an issue to another list, select the issue card and drag it onto that list.

When you drag issues between lists, the result is different depending on the source list
and the target list.

|                              | To Open        | To Closed   | To label B list                | To assignee Bob list          |
| ---------------------------- | -------------- | ----------- | ------------------------------ | ----------------------------- |
| **From Open**                | -              | Close issue | Add label B                    | Assign Bob                    |
| **From Closed**              | Reopen issue   | -           | Reopen issue and add label B   | Reopen issue and assign Bob   |
| **From label A list**        | Remove label A | Close issue | Remove label A and add label B | Assign Bob                    |
| **From assignee Alice list** | Unassign Alice | Close issue | Add label B                    | Unassign Alice and assign Bob |

### Multi-select issue cards

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18954) in GitLab 12.4.
> - [Placed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61955) behind a [feature flag](../feature_flags.md), disabled by default in GitLab 14.0.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-multi-selecting-issue-cards). **(FREE SELF)**

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

You can select multiple issue cards, then drag the group to another position within the list, or to
another list. This makes it faster to reorder many issues at once.

To select and move multiple cards:

1. Select each card with <kbd>Control</kbd>+`Click` on Windows or Linux, or <kbd>Command</kbd>+`Click` on MacOS.
1. Drag one of the selected cards to another position or list and all selected cards are moved.

![Multi-select Issue Cards](img/issue_boards_multi_select_v12_4.png)

### First time using an issue board

> - The automatic creation of the **To Do** and **Doing** lists [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202144) in GitLab 13.5.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/270583) in GitLab 13.7. In GitLab 13.7 and later, the **To Do** and **Doing** columns are not automatically created.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/270583) in GitLab 13.7.
The **To Do** and **Doing** columns are no longer automatically created.

In GitLab 13.5 and 13.6, the first time you open an issue board, you are presented with the default lists
(**Open**, **To Do**, **Doing**, and **Closed**).

If the **To Do** and **Doing** labels don't exist in the project or group, they are created, and
their lists appear as empty. If any of them already exists, the list is filled with the issues that
have that label.

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
  20 appear.

### Enable or disable GraphQL-based issue boards **(FREE SELF)**

NOTE:
When enabling GraphQL-based issue boards, you must also enable the
[new add list form](#enable-or-disable-new-add-list-form).

It is deployed behind a feature flag that is **enabled by default** as of GitLab 14.1.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can disable it.

To enable it:

```ruby
Feature.enable(:graphql_board_lists)
```

To disable it:

```ruby
Feature.disable(:graphql_board_lists)
```

### Enable or disable new add list form **(FREE SELF)**

The new form for adding lists is under development but ready for production use. It is
deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can disable it.

To enable it:

```ruby
Feature.enable(:board_new_list)
```

To disable it:

```ruby
Feature.disable(:board_new_list)
```

### Enable or disable iteration lists in boards **(PREMIUM SELF)**

NOTE:
When disabling iteration lists in boards, you also need to disable the [new add list form](#enable-or-disable-new-add-list-form).

The iteration list is under development but ready for production use. It is
deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can disable it.

To enable it:

```ruby
Feature.enable(:iteration_board_lists)
```

To disable it:

```ruby
Feature.disable(:iteration_board_lists)
```

### Enable or disable multi-selecting issue cards **(FREE SELF)**

Multi-selecting issue cards is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:board_multi_select)
```

To disable it:

```ruby
Feature.disable(:board_multi_select)
```
