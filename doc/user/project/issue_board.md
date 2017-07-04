# Issue Board

>**Note:**
[Introduced][ce-5554] in [GitLab 8.11](https://about.gitlab.com/2016/08/22/gitlab-8-11-released/#issue-board).

The GitLab Issue Board is a software project management tool used to plan,
organize, and visualize a workflow for a feature or product release.
It can be seen like a light version of a [Kanban] or a [Scrum] board.

Other interesting links:

- [GitLab Issue Board landing page on about.gitlab.com][landing]
- [YouTube video introduction to Issue Boards][youtube]

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

With [Multiple Issue Boards](#multiple-issue-boards), available
only in [GitLab Enterprise Edition](https://about.gitlab.com/gitlab-ee/),
you go even further, as you can not only keep yourself and your project
organized from a broader perspective with one Issue Board per project,
but also allow your team members to organize their own workflow by creating
multiple Issue Boards within the same project.

## Use cases

You can see below a few different use cases for GitLab's Issue Boards.

### Use cases for a single Issue Board

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

### Use cases for Multiple Issue Boards

With [Multiple Issue Boards](#multiple-issue-boards), available only in
[GitLab Enterprise Edition](https://about.gitlab.com/gitlab-ee/),
each team can have their own board to organize their workflow individually.

#### Scrum team

With multiple Issue Boards, each team has one board. For each sprint, you can
[associate a milestone](#board-with-a-milestone). Now you can move issues through each
part of the process. For instance: **To Do**, **Doing**, and **Done**.

#### Organization of topics

Create lists to order things by topic and quickly change them between topics or groups,
such as between **UX**, **Frontend**, and **Backend**. The changes will be reflected across boards,
as changing lists will update the label accordingly.

#### Advanced team handover

For example, suppose we have a UX team with an Issue Board that contains:

- **To Do**
- **Doing**
- **Frontend**

When done with something, they move the card to **Frontend**. The Frontend team's board looks like:

- **Frontend**
- **Doing**
- **Done**

Cards finished by the UX team will automatically appear in the **Frontend** column when they're ready for them.

> **Notes:**
>
>- For a broader use case, please check the blog post
[GitLab Workflow, an Overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/#gitlab-workflow-use-case-scenario).
>
>- For a real use case, please check why
[Codepen decided to adopt Issue Boards](https://about.gitlab.com/2017/01/27/codepen-welcome-to-gitlab/#project-management-everything-in-one-place)
to improve their workflow with multiple boards.

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

![GitLab Issue Board](img/issue_board.png)

---

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

## Re-ordering an issue in a list

> Introduced in GitLab 9.0.

Issues can be re-ordered inside of lists. This is as simple as dragging and dropping
an issue into the order you want.

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

## Multiple Issue Boards

> Introduced in [GitLab Enterprise Edition 8.13](https://about.gitlab.com/2016/10/22/gitlab-8-13-released/#multiple-issue-boards-ee).

Multiple Issue Boards, as the name suggests, allow for more than one Issue Board
for a given project. This is great for large projects with more than one team
or in situations where a repository is used to host the code of multiple
products.

Clicking on the current board name in the upper left corner will reveal a
menu from where you can create another Issue Board and rename or delete the
existing one.

![Multiple Issue Boards](img/issue_boards_multiple.png)

### Board with a milestone

> Introduced in [GitLab Enterprise Edition 9.0](https://about.gitlab.com/2017/03/22/gitlab-9-0-released/#boards-with-milestones-ees-eep).

An Issue Board can be associated with a GitLab [Milestone](milestones/index.md#milestones)
which will automatically filter the issue to that milestone. This allows you to
create unique boards for individual milestones.

You can assign a milestone to a board when creating a new Issue Board or you
can update current Issue Boards to also have a milestone. Once a specific
milestone is assigned to an Issue Board, you will no longer be able to filter
through any other milestone. In order to do that, you need to remove the
defined milestone from the Issue Board.

There are also two pre-defined milestones, **Any milestone** which will filter
the issues with any milestone, and **Upcoming** which will filter issues to the
milestone with the due date that is next.

![Update boards milestone](img/issue_board_multiple_milestone.png)

## Focus mode

> Introduced in [GitLab Enterprise Edition 9.1](https://about.gitlab.com/2017/04/22/gitlab-9-1-released/#issue-boards-focus-mode-ees-eep).

Click the button at the top right to toggle focus mode on and off. In focus mode, the navigation UI is hidden, allowing you to focus on issues in the board.

![Board focus mode](img/issue_board_focus_mode.gif)

## Permissions

[Developers and up](../permissions.md) can use all the functionality of the
Issue Board, that is create/delete lists and drag issues around.

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
[ee]: https://about.gitlab.com/gitlab-ee/
[labels]: ./labels.md
[scrum]: https://en.wikipedia.org/wiki/Scrum_(software_development)
[kanban]: https://en.wikipedia.org/wiki/Kanban_(development)
[create-labels]: ./labels.md#create-new-labels
[label-priority]: ./labels.md#prioritize-labels
[landing]: https://about.gitlab.com/features/issueboard/
[youtube]: https://www.youtube.com/watch?v=UWsJ8tkHAa8
