# Labels

## Overview

Labels allow you to categorize epics, issues, and merge requests using descriptive titles like
`bug`, `feature request`, or `docs`. Each label also has a customizable color. They
allow you to quickly and dynamically filter and manage epics, issues and merge requests you
care about, and are visible throughout GitLab in most places where issues and merge
requests are located.

## Project labels and group labels

In GitLab, you can create project and group labels:

- **Project labels** can be assigned to issues and merge requests in that project only.
- **Group labels** can be assigned to any epics, issue and merge request in any project in
  that group, or any subgroups of the group.

## Scoped labels **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9175) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.10.

Scoped labels allow teams to use the simple and familiar label feature to
annotate their epics, issues, merge requests, and epics to achieve custom fields and
custom workflow states by leveraging a special label title syntax.

A scoped label is a kind of label defined by a special double-colon syntax
in the label’s title, using the format `key::value`. For example:

![A sample scoped label](img/labels_key_value_v12_1.png)

An issue, epic, or merge request cannot have two scoped labels with the same key.
For example, if an issue is already labeled `priority::3`, and then you apply the
`priority::2` label to it, `priority::3` is automatically removed.

This functionality is demonstrated in a video titled [Use scoped labels in GitLab 11.10 for custom fields and custom workflows](https://www.youtube.com/watch?v=4BCBby6du3c).

### Labels with multiple colon pairs

If labels have multiple instances of `::`, the longest path from left to right, until
the last `::`, is considered the "key" or the "scope".

For example, `nested::key1::value1` and `nested::key1::value2` cannot both exist on
the same issue. Adding the latter label will automatically remove the former due to
the shared scope of `nested::key1`.

`nested::key1::value1` and `nested::key2::value1` can both exist on the same issue,
as these are considered to use two different label scopes, `nested::key1` and `nested::key2`.

### Workflows with scoped labels

Suppose you wanted a custom field in issues to track the platform operating system
that your features target, where each issue should only target one platform. You
would then create labels `platform::iOS`, `platform::Android`, `platform::Linux`,
etc., as necessary. Applying any one of these labels on a given issue would
automatically remove any other existing label that starts with `platform::`.

The same pattern could be applied to represent the workflow states of your teams.
Suppose you have the labels `workflow::development`, `workflow::review`, and
`workflow::deployed`. If an issue already has the label `workflow::development`
applied, and a developer wanted to advance the issue to `workflow::review`, they
would simply apply that label, and the `workflow::development` label would
automatically be removed. This behavior already exists when you move issues
across label lists in an [issue board](issue_board.md#creating-workflows), but
now, team members who may not be working in an issue board directly would still
be able to advance workflow states consistently in issues themselves.

## Creating labels

NOTE: **Note:**
A permission level of Reporter or higher is required to create labels.

### New project label

To create a **project label**, navigate to **Issues > Labels** in the project.
This page only shows the project labels in this project, and the group labels of the
project's parent group.

Click the **New label** button. Enter the title, an optional description, and the
background color. Click **Create label** to create the label.

If a project has no labels, you can generate a default set of project labels from
its empty label list page:

![Labels generate default](img/labels_generate_default_v12_1.png)

GitLab will add the following default labels to the project:

![Labels default](img/labels_default_v12_1.png)

### New group label

To create a **group label**, navigate to **Issues > Labels** in the **group** and create
it from there. This page only shows group labels in this group.

Alternatively, you can create group labels from the Epic sidebar. **(ULTIMATE)**

Please note that the created label will belong to the immediate group to which the
epic belongs.

![Create Labels from Epic](img/labels_epic_sidebar_v12_1.png)

Group labels appear in every label list page of the group's child projects.

![Labels list](img/labels_list_v12_1.png)

### New project label from sidebar

From the sidebar of an issue or a merge request, you can create a new **project label**
inline immediately, instead of navigating to the project label list page.

![Labels inline](img/labels_new_label_from_sidebar.gif)

## Editing labels

NOTE: **Note:**
A permission level of Reporter or higher is required to edit labels.

To update a label, navigate to **Issues > Labels** in the project or group
and click the pencil icon. The title, description and color can be changed.

To delete a label, click the three dots next to the `Subscribe` button, and select
**Delete**.

![Delete label](img/labels_delete_v12_1.png)

### Promoting project labels to group labels

If you are expanding from a few projects to a larger number of projects within the
same group, you may want to share the same label among multiple projects in the same
group. If you previously created a project label and now want to make it available
for other projects, you can promote it to a group label.

From the project label list page, you can promote a project label to a group label.
This will merge all project labels with the same name into a single group label, across
all projects in this group. All issues and merge requests that were previously
assigned one of these project labels will now be assigned the new group label. This
action cannot be reversed and the changes are permanent.

![Labels promotion](img/labels_promotion_v12_1.png)

## Assigning labels from the sidebar

Every epic, issue, and merge request can be assigned any number of labels. The labels are
visible on every epic, issue and merge request page, in the sidebar and on your issue boards.

From the sidebar, you can assign or unassign a label to the object (i.e. label or
unlabel it). You can also perform this as a [quick action](quick_actions.md),
in a comment.

| View labels in sidebar | Assign labels from sidebar |
|:----------------------:|:--------------------------:|
| ![Labels sidebar](img/labels_sidebar.png) | ![Labels sidebar assign](img/labels_sidebar_assign.png) |

## Searching for project labels

To search for project labels, go to **Issues > Labels** in the left sidebar, and enter
your search query in the **Filter** field.

![Labels project list search](img/labels_project_list_search.png)

GitLab will check both the label titles and descriptions for the search.

## Filtering by label

The following can be filtered by labels:

- Epic lists **(ULTIMATE)**
- Issue lists
- Merge Request lists
- Issue Boards

### Filtering in list pages

- From the project issue list page and the project merge request list page, you can
  [filter](../search/index.md#issues-and-merge-requests) by:
  - Group labels (including subgroup ancestors)
  - Project labels

- From the group epic lists page, issue list page and the group merge request list page, you can
  [filter](../search/index.md#issues-and-merge-requests) by:
  - Group labels (including subgroup ancestors and subgroup descendants)
  - Project labels

- You can [filter](../search/index.md#issues-and-merge-requests) the group epic list
  page by: **(ULTIMATE)**
  - Current group labels
  - Descendant group labels

![Labels group issues](img/labels_group_issues_v12_1.png)

### Filtering in issue boards

- From [project boards](issue_board.md), you can use the [search and filter bar](../search/index.md#issue-boards)
  to filter by:
  - Group labels
  - Project labels

- From [group issue boards](issue_board.md#group-issue-boards-premium), you can use the
  [search and filter bar](../search/index.md#issue-boards) to filter by group labels only. **(PREMIUM)**

- From [project boards](issue_board.md), in the [issue board configuration](issue_board.md#configurable-issue-boards-starter),
  you can filter by: **(STARTER)**
  - Group labels
  - Project labels

- From [group issue boards](issue_board.md#group-issue-boards-premium), in the [issue board configuration](issue_board.md#configurable-issue-boards-starter),
  you can filter by group labels only. **(STARTER)**

## Subscribing to labels

From the project label list page and the group label list page, you can subscribe
to [notifications](../profile/notifications.md) of a given label, to alert you
that the label has been assigned to an epic, issue, or merge request.

![Labels subscriptions](img/labels_subscriptions_v12_1.png)

## Label priority

>**Notes:**
>
> - Introduced in GitLab 8.9.
> - Priority sorting is based on the highest priority label only. [This discussion](https://gitlab.com/gitlab-org/gitlab-foss/issues/18554) considers changing this.

Labels can have relative priorities, which are used in the "Label priority" and
"Priority" sort orders of the epic, issue, and merge request list pages.

From the project label list page, star a label to indicate that it has a priority.

![Labels prioritized](img/labels_prioritized_v12_1.png)

Drag starred labels up and down the list to change their priority. Higher in the list
means higher priority. Prioritization happens at the project level, only on the project
label list page, and not on the group label list page.

However, both project and group
labels can be prioritized on the project label list page since both types are displayed
on the project label list page.

![Drag to change label priority](img/labels_drag_priority_v12_1.gif)

On the epic, merge request and issue pages, for both groups and projects, you can sort by `Label priority`
and `Priority`, which account for objects (epic, issues, and merge requests) that have prioritized
labels assigned to them.

If you sort by `Label priority`, GitLab considers this sort comparison order:

- Object with a higher priority prioritized label.
- Object without a prioritized label.

Ties are broken arbitrarily. Note that we _only_ consider the highest prioritized label
in an object, and not any of the lower prioritized labels. [This discussion](https://gitlab.com/gitlab-org/gitlab-foss/issues/18554)
considers changing this.

![Labels sort label priority](img/labels_sort_label_priority.png)

If you sort by `Priority`, GitLab considers this sort comparison order:

- Due date of the assigned [milestone](milestones/index.md) is sooner, provided
  the object has a milestone and the milestone has a due date. If this isn't the case,
  consider the object having a due date in the infinite future.
- Object with a higher priority prioritized label.
- Object without a prioritized label.

Ties are broken arbitrarily.

![Labels sort priority](img/labels_sort_priority.png)
