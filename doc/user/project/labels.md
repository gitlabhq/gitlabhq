# Labels

## Overview

Labels allow you to categorize issues or merge requests using descriptive titles like `bug`, `feature request`, or `docs`. Each label also has a customizable color. They allow you to quickly and dynamically filter and manage issues or merge requests you care about, and are visible throughout GitLab in most places where issues and merge requests are located.

## Project labels and group labels

In GitLab, you can create project and group labels:

- **Project labels** can be assigned to issues or merge requests in that project only. 
- **Group labels** can be assigned to any issue or merge request of any project in that group or any subgroups of the group.

## Creating labels

>**Note:**
A permission level of `Developer` or higher is required to create labels.

### New project label

To create a **project label**, navigate to **Issues > Labels** in the project.

Click the **New label** button. Enter the title, an optional description, and the background color. Click **Create label** to create the label.

If a project has no labels, you can generate a default set of project labels from its empty label list page:

![Labels generate default](img/labels_generate_default.png)

GitLab will add the following default labels to the project:

![Labels default](img/labels_default.png)

### New group label

To create a **group label**, follow similar steps from above to project labels. Navigate to **Issues > Labels** in the group and create it from there.
Alternatively, you can create group labels also from Epic sidebar. Please note that the created label will belong to the immediate group to which epic belongs.

![Create Labels from Epic](img/labels_epic_sidebar.png) 

Group labels appear in every label list page of the group's child projects.

![Labels list](img/labels_list.png)

### New project label from sidebar

From the sidebar of an issue or a merge request, you can create a create a new **project label** inline immediately, instead of navigating to the project label list page.

![Labels inline](img/new_label_from_sidebar.gif)

## Editing labels

NOTE: **Note:**
A permission level of `Developer` or higher is required to edit labels.

You can update a label by navigating to **Issues > Labels** in the project or group and clicking the pencil icon.

You can delete a label by clicking the trash icon.

### Promoting project labels to group labels

If you are expanding from a few projects to a larger number of projects within the same group, you may want to share the same label among multiple projects in the same group. If you previously created a project label and now want to make it available for other projects, you can promote it to a group label.

From the project label list page, you can promote a project label to a group label. This will merge all project labels across all projects in this group with the same name into a single group label. All issues and merge requests that previously were assigned one of these project labels will now be assigned the new group label. This action cannot be reversed and the changes are permanent.

![Labels promotion](img/labels_promotion.png)

## Assigning labels from the sidebar

Every issue and merge request can be assigned any number of labels. The labels are visible on every issue and merge request page, in the sidebar. They are also visible in the issue board. From the sidebar, you can assign or unassign a label to the object (i.e. label or unlabel it). You can also perform this as a [quick action](quick_actions.md) in a comment.

| View labels in sidebar | Assign labels from sidebar |
|:---:|:---:|
| ![Labels sidebar](img/labels_sidebar.png) | ![Labels sidebar assign](img/labels_sidebar_assign.png) |

## Filtering issues, merge requests and epics by label

### Filtering in list pages

From the project issue list page and the project merge request list page, you can [filter](../search/index.md#issues-and-merge-requests) by both group (including subgroup ancestors) labels and project labels.

From the group issue list page and the group merge request list page, you can [filter](../search/index.md#issues-and-merge-requests) by both group labels (including subgroup ancestors and subgroup descendants) and project labels.

From the group epic list page, you can [filter](../search/index.md#issues-and-merge-requests) by both current group labels as well as decendent group labels.

![Labels group issues](img/labels_group_issues.png)

### Filtering in issue boards

- From [project boards](issue_board.md), you can filter by both group labels and project labels in the [search and filter bar](../search/index.md#issue-boards).
- From [group issue boards](issue_board.md#group-issue-boards), you can filter by only group labels in the [search and filter bar](../search/index.md#issue-boards). **[PREMIUM]**
- From [project boards](issue_board.md), you can filter by both group labels and project labels in the [issue board configuration](issue_board.md#board-with-configuration). **[PREMIUM]**
- From [group issue boards](issue_board.md#group-issue-boards), you can filter by only group labels in the [issue board configuration](issue_board.md#board-with-configuration). **[PREMIUM]**

## Subscribing to labels

From the project label list page and the group label list page, you can subscribe to [notifications](../../workflow/notifications.md) of a given label, to alert you that that label has been assigned to an issue or merge request.

![Labels subscriptions](img/labels_subscriptions.png)

## Label priority

>**Notes:**
>
> - Introduced in GitLab 8.9.
> - Priority sorting is based on the highest priority label only. [This discussion](https://gitlab.com/gitlab-org/gitlab-ce/issues/18554) considers changing this.

Labels can have relative priorities, which are used in the "Label priority" and "Priority" sort orders of the issue and merge request list pages.

From the project label list page, star a label to indicate that it has a priority. Drag starred labels up and down to change their priority. Higher means higher priority. Prioritization happens at the project level, only on the project label list page, and not on the group label list page. However, both project and group labels can be prioritized on the project label list page since both types are displayed on the project label list page.

![Labels prioritized](img/labels_prioritized.png)

On the project and group issue and merge request list pages, you can sort by `Label priority` and `Priority`, which account for objects (issues and merge requests) that have prioritized labels assigned to them.

If you sort by `Label priority`, GitLab considers this sort comparison order:

- Object with a higher priority prioritized label.
- Object without a prioritized label.

Ties are broken arbitrarily. (Note that we _only_ consider the highest prioritized label in an object, and not any of the lower prioritized labels. [This discussion](https://gitlab.com/gitlab-org/gitlab-ce/issues/18554) considers changing this.)

![Labels sort label priority](img/labels_sort_label_priority.png)

If you sort by `Priority`, GitLab considers this sort comparison order:

- Object's assigned [milestone](milestones/index.md)'s due date is sooner, provided the object has a milestone and the milestone has a due date. If this isn't the case, consider the object having a due date in the infinite future.
- Object with a higher priority prioritized label.
- Object without a prioritized label.

Ties are broken arbitrarily.

![Labels sort priority](img/labels_sort_priority.png)
