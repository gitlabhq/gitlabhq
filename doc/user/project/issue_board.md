# Issue Board

>**Note:**
[Introduced][ce-5554] in [GitLab 8.11](https://about.gitlab.com/2016/08/22/gitlab-8-11-released/#issue-board).

The GitLab Issue Board is a software project management tool used to plan,
organize, and visualize a workflow for a feature or product release.
It can be seen like a light version of a [Kanban] or a [Scrum] board.

Other interesting links:

- [GitLab Issue Board landing page on about.gitlab.com][landing]
- [YouTube video introduction to Issue Boards][youtube]

![GitLab Issue Board](img/issue_board.png)

## Overview

The Issue Board builds on GitLab's existing
[issue tracking functionality](issues/index.md#issue-tracker) and
leverages the power of [labels] by utilizing them as lists of the scrum board.

With the Issue Board you can have a different view of your issues while
maintaining the same filtering and sorting abilities you see across the
issue tracker. An Issue Board is based on its project's label structure, therefore, it
applies the same descriptive labels to indicate placement on the board, keeping
consistency throughout the entire development lifecycle.

An Issue Board shows you what issues your team is working on, who is assigned to each,
and where in the workflow those issues are.

You create issues, host code, perform reviews, build, test,
and deploy from one single platform. Issue Boards help you to visualize
and manage the entire process _in_ GitLab.

With [Multiple Issue Boards](https://docs.gitlab.com/ee/user/project/issue_board.html#multiple-issue-boards), available
only in [GitLab Ultimate](https://about.gitlab.com/products/),
you go even further, as you can not only keep yourself and your project
organized from a broader perspective with one Issue Board per project,
but also allow your team members to organize their own workflow by creating
multiple Issue Boards within the same project.

## Use cases

GitLab Workflow allows you to discuss proposals in issues, categorize them
with labels, and from there organize and prioritize them with Issue Boards.

For example, let's consider this simplified development workflow:

1. You have a repository hosting your app's codebase
and your team actively contributing to code
1. Your **backend** team starts working a new
implementation, gathers feedback and approval, and pass it over to **frontend**
1. When frontend is complete, the new feature is deployed to **staging** to be tested
1. When successful, it is deployed to **production**

If we have the labels "**backend**", "**frontend**", "**staging**", and
"**production**", and an Issue Board with a list for each, we can:

- Visualize the entire flow of implementations since the
beginning of the development lifecycle until deployed to production
- Prioritize the issues in a list by moving them vertically
- Move issues between lists to organize them according to the labels you've set
- Add multiple issues to lists in the board by selecting one or more existing issues

![issue card moving](img/issue_board_move_issue_card_list.png)

> **Notes:**
>
>- For a broader use case, please check the blog post
[GitLab Workflow, an Overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/#gitlab-workflow-use-case-scenario).
>
>- For a real use case, please check why
[Codepen decided to adopt Issue Boards](https://about.gitlab.com/2017/01/27/codepen-welcome-to-gitlab/#project-management-everything-in-one-place)
to improve their workflow with [multiple boards](https://docs.gitlab.com/ee/user/project/issue_board.html#multiple-issue-boards).

## Issue Board terminology

Below is a table of the definitions used for GitLab's Issue Board.

| What we call it  | What it means |
| --------------  | ------------- |
| **Issue Board** | It represents a different view for your issues. It can have multiple lists with each list consisting of issues represented by cards. |
| **List**        | Each label that exists in the issue tracker can have its own dedicated list. Every list is named after the label it is based on and is represented by a column which contains all the issues associated with that label. You can think of a list like the results you get when you filter the issues by a label in your issue tracker. |
| **Card**        | Every card represents an issue and it is shown under the list for which it has a label. The information you can see on a card consists of the issue number, the issue title, the assignee and the labels associated with it. You can drag cards around from one list to another. You can re-order cards within a list. |

There are two types of lists, the ones you create based on your labels, and
two defaults:

- Label list: a list based on a label. It shows all opened issues with that label.
- **Backlog** (default): shows all open issues that does not belong to one of lists. Always appears on the very left.
- **Closed** (default): shows all closed issues. Always appears on the very right.

In short, here's a list of actions you can take in an Issue Board:

- [Create a new list](#creating-a-new-list).
- [Delete an existing list](#deleting-a-list).
- Drag issues between lists.
- Re-order issues in lists.
- Drag and reorder the lists themselves.
- Change issue labels on-the-fly while dragging issues between lists.
- Close an issue if you drag it to the **Done** list.
- Create a new list from a non-existing label by [creating the label on-the-fly](#creating-a-new-list)
  within the Issue Board.
- [Filter issues](#filtering-issues) that appear across your Issue Board.

If you are not able to perform one or more of the things above, make sure you
have the right [permissions](#permissions).

## First time using the Issue Board

The first time you navigate to your Issue Board, you will be presented with
a default list (**Done**) and a welcoming message that gives
you two options. You can either create a predefined set of labels and create
their corresponding lists to the Issue Board or opt-out and use your own lists.

![Issue Board welcome message](img/issue_board_welcome_message.png)

If you choose to use and create the predefined lists, they will appear as empty
because the labels associated to them will not exist up until that moment,
which means the system has no way of populating them automatically. That's of
course if the predefined labels don't already exist. If any of them does exist,
the list will be created and filled with the issues that have that label.

## Creating a new list

Create a new list by clicking on the **Add list** button at the upper
right corner of the Issue Board.

![Issue Board welcome message](img/issue_board_add_list.png)

Simply choose the label to create the list from. The new list will be inserted
at the end of the lists, before **Done**. Moving and reordering lists is as
easy as dragging them around.

To create a list for a label that doesn't yet exist, simply create the label by
choosing **Create new label**. The label will be created on-the-fly and it will
be immediately added to the dropdown. You can now choose it to create a list.

## Deleting a list

To delete a list from the Issue Board use the small trash icon that is present
in the list's heading. A confirmation dialog will appear for you to confirm.

Deleting a list doesn't have any effect in issues and labels, it's just the
list view that is removed. You can always add it back later if you need.

## Adding issues to a list

You can add issues to a list by clicking the **Add issues** button that is
present in the upper right corner of the Issue Board. This will open up a modal
window where you can see all the issues that do not belong to any list.

Select one or more issues by clicking on the cards and then click **Add issues**
to add them to the selected list. You can limit the issues you want to add to
the list by filtering by author, assignee, milestone and label.

![Bulk adding issues to lists](img/issue_boards_add_issues_modal.png)

## Removing an issue from a list

Removing an issue from a list can be done by clicking on the issue card and then
clicking the **Remove from board** button in the sidebar. Under the hood, the
respective label is removed, and as such it's also removed from the list and the
board itself.

![Remove issue from list](img/issue_boards_remove_issue.png)

## Issue ordering in a list

When visiting a board, issues appear ordered in any list. You are able to change
that order simply by dragging and dropping the issues. The changed order will be saved
to the system so that anybody who visits the same board later will see the reordering,
with some exceptions.

The first time a given issue appears in any board (i.e. the first time a user
loads a board containing that issue), it will be ordered with 
respect to other issues in that list according to [Priority order][label-priority].
At that point, that issue will be assigned a relative order value by the system
representing its relative order with respect to the other issues in the list. Any time
you drag-and-drop reorder that issue, its relative order value will change accordingly.
Also, any time that issue appears in any board when it is loaded by a user,
the updated relative order value will be used for the ordering. (It's only the first
time an issue appears that it takes from the Priority order mentioned above.) This means that
if issue `A` is drag-and-drop reordered to be above issue `B` by any user in
a given board inside your GitLab instance, any time those two issues are subsequently
loaded in any board in the same instance (could be a different project board or a different group board, for example), 
that ordering will be maintained.

## Filtering issues

You should be able to use the filters on top of your Issue Board to show only
the results you want. This is similar to the filtering used in the issue tracker
since the metadata from the issues and labels are re-used in the Issue Board.

You can filter by author, assignee, milestone and label.

## Creating workflows

By reordering your lists, you can create workflows. As lists in Issue Boards are
based on labels, it works out of the box with your existing issues. So if you've
already labeled things with 'Backend' and 'Frontend', the issue will appear in
the lists as you create them. In addition, this means you can easily move
something between lists by changing a label.

A typical workflow of using the Issue Board would be:

1. You have [created][create-labels] and [prioritized][label-priority] labels
   so that you can easily categorize your issues.
1. You have a bunch of issues (ideally labeled).
1. You visit the Issue Board and start [creating lists](#creating-a-new-list) to
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

![Issue Board system notes](img/issue_board_system_notes.png)

## Permissions

[Developers and up](../permissions.md) can use all the functionality of the
Issue Board, that is create/delete lists and drag issues around.

##  Group Issue Board

>Introduced in GitLab 10.6

Group issue board is analogous to project-level issue board and it is accessible at the group
navigation level. A group-level issue board allows you to view all issues from all projects in that group
(currently, it does not see issues from projects in subgroups). Similarly, you can only filter by group labels for these
boards. When updating milestones and labels for an issue through the sidebar update mechanism, again only
group-level objects are available.

## Features per tier

Different issue board features are available in different [GitLab tiers](https://about.gitlab.com/pricing/), as shown in the following table:

| Tier | Number of project issue boards | Board with configuration in project issue boards | Number of group issue boards | Board with configuration in group issue boards |
| --- | --- | --- | --- | --- |
| Libre    | 1        | No  | 1        | No  |
| Starter  | Multiple | Yes | 1        | No  |
| Premium  | Multiple | Yes | Multiple | Yes |
| Ultimate | Multiple | Yes | Multiple | Yes |

## Tips

A few things to remember:

- The label that corresponds to a list is hidden for issues under that list.
- Moving an issue between lists removes the label from the list it came from
  and adds the label from the list it goes to.
- When moving a card to **Done**, the label of the list it came from is removed
  and the issue gets closed.
- An issue can exist in multiple lists if it has more than one label.
- Lists are populated with issues automatically if the issues are labeled.
- Clicking on the issue title inside a card will take you to that issue.
- Clicking on a label inside a card will quickly filter the entire Issue Board
  and show only the issues from all lists that have that label.
- For performance and visibility reasons, each list shows the first 20 issues
  by default. If you have more than 20 issues start scrolling down and the next
  20 will appear.

[ce-5554]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5554
[labels]: ./labels.md
[scrum]: https://en.wikipedia.org/wiki/Scrum_(software_development)
[kanban]: https://en.wikipedia.org/wiki/Kanban_(development)
[create-labels]: ./labels.md#create-new-labels
[label-priority]: ./labels.md#prioritize-labels
[landing]: https://about.gitlab.com/solutions/issueboard
[youtube]: https://www.youtube.com/watch?v=UWsJ8tkHAa8
