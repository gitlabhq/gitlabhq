# Issue board

> [Introduced][ce-5554] in GitLab 8.11.

The GitLab Issue Board is a software project management tool used to plan,
organize, and visualize a workflow for a feature or product release.
It can be seen like a light version of a [Kanban] or a [Scrum] board.

## Overview

The Issue Board builds on GitLab's existing issue tracking functionality and
leverages the power of [labels] by utilizing them as lists of the scrum board.

With the Issue Board you can have a different view of your issues while also
maintaining the same filtering and sorting abilities you see across the
issue tracker.

There are three types of lists, of which two are default:

- **Backlog** (default): shows all issues that do not fall in one of the other
  lists. Always appears on the very left.
- **Done** (default): shows all closed issues. Always appears on the very right.
- Label list: a list based on a label. It shows all issues with that label.

![GitLab Issue Board](img/issue_board.png)

---

Below is a table of the definitions used for GitLab's Issue Board.

| Term | Definition |
| ---- | ----------- |
| **Issue Board** | It can have up to 10 lists with each list consisting of issues represented by cards. |
| **List** | Each label that exists in the issue tracker can have its own dedicated list. Every list is named after the label it is based on and is represented by a column which contains all the issues associated with that label. You can think of a list like the results you get when you filter the issues by a label in your issue tracker. You can create up to 10 lists per Issue Board. |
| **Card** | Every card represents an issue. The information you can see on a card consists of the issue number, the issue title and the labels associated with it. You can drag cards around from one lists to another. Issues are [ordered by priority](labels.md#prioritize-labels). |

## Functionality

The Issue Board consists of lists appearing as columns. Each list you add is
named after and based on the labels that already exist in your issue tracker.
Issues can be seen as cards and they can easily be moved between the lists, as
to create workflows. The issues inside each list are sorted by priority.

The first time you navigate to your Issue Board, you will be presented with the
two special lists (**Backlog** and **Done**) and a welcoming message that
The starting point is two lists: **Backlog** and **Done**. The **Backlog**
list shows all issues that do not fall in one of the other lists. Drag a card
to the **Done** list and the relevant issue will be closed.

Here's a list of actions you can take in an Issue Board:

1. Add a new issue list
1. Delete an issue list
1. Drag issues between lists
1. Drag and reorder the lists themselves
1. Change issue labels on-the-fly while dragging issues between lists
1. Close an issue if you drag it to the **Done** list
1. Add a new list from a non-existing label by creating the label on-the-fly
1. Populate lists with issues automatically

Moving an issue between lists removes the label from the list it came from
and adds the label of the list it goes to.

When moving to Done, remove the label of the list it came from and close the issue.

An issue can exist in multiple lists if it has more than one labels.

## First time using the Issue Board

When default lists are created, they are empty because the labels associated to
them did not exist up until that moment, which means the system has no way of
populating them automatically. It'll be the users' job to add individual issues to them.

## Adding a new list

Add a new list by clicking on the button. In a modal you will find a label
dropdown, where you can also create new labels (like in the sidebar).

The new list should be inserted at the end of the lists, before Done.

## Moving lists

You should be able to drag the label lists around by dragging them on the top.

## Creating workflows

By adding new lists, you can create workflows. For instance you can create a
list based on the label of 'Frontend' and one for 'Backend'. A designer can start
working on an issue by dragging it from **Backlog** to 'Frontend'. That way, everyone
knows, this issue is now being worked on by the designers. Then, once they’re
done, all they have to do is drag it over to the next list, 'Backend', where a
backend developer can eventually pick it up. Once they’re done, they move it to
**Done**, to close the issue.

As lists in Issue Boards are based on labels, it works out of the box with your
existing issues. So if you've already labeled things with 'Backend' and 'Frontend',
the issue will appear in the lists as you create them. In addition, this means
you can easily move something between lists by changing a label.

If you move an issue from one list to the next, it removes the label from the
list it comes from and adds the label from the list it moves towards.

## Filtering issues

You should be able to use the filters on top, as seen in the mockup and similar to the issue list.
Every issue contains metadata.

[ce-5554]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5554
[labels]: ./labels.md
[scrum]: https://en.wikipedia.org/wiki/Scrum_(software_development)
[kanban]: https://en.wikipedia.org/wiki/Kanban_(development)
