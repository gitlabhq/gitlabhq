---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Set up a complex group with subgroups for issue triage'
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

Issue triage is the process of categorization according to type and severity.
As your project grows and people create more issues, it's worth creating a workflow for how you'll
triage incoming issues.

In this tutorial, you'll learn how to set up a GitLab group with subgroups for this scenario.

To set up GitLab for a complex group with subgroups for issue triage:

1. [Create a group](#create-a-group)
1. [Create subgroups inside a group](#create-subgroups-inside-a-group)
1. [Create projects inside subgroups](#create-projects-inside-subgroups)
1. [Decide on the criteria for types, severity, and priority](#decide-on-the-criteria-for-types-severity-and-priority)
1. [Document your criteria](#document-your-criteria)
1. [Create scoped labels](#create-scoped-labels)
1. [Prioritize the new labels](#prioritize-the-new-labels)
1. [Create a parent group issue triage board](#create-a-parent-group-issue-triage-board)
1. [Create issues for features](#create-issues-for-features)

## Before you begin

- If you're using an existing project for this tutorial, make sure you have at least the Reporter role
  for the project.
  - If your existing project does not have a parent group, create a group and [promote the project labels to group labels](../../user/project/labels.md#promote-a-project-label-to-a-group-label).

## Create a group

A [group](../../user/group/_index.md) is, in essence, a container for multiple projects.
It allows users to manage multiple projects and communicate with group members all at once.

To create a new group:

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and select **New group**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Create group**.
1. Enter the group details:
   - For **Group name**, enter `Web App Dev` or another value.
1. At the bottom of the page, select **Create group**.

## Create subgroups inside a group

A [subgroup](../../user/group/subgroups/_index.md) is a group in a group.
Subgroups help organize large projects and manage permissions.

To create a new subgroup:

1. On the left sidebar, select **Search or go to** and find your **Web App Dev** group. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Create new** ({{< icon name="plus" >}}) and **New subgroup**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Enter the subgroup details:
   - For **Subgroup name**, enter `Frontend` or another value.
1. Select **Create subgroup**.
1. Repeat this process to create a second subgroup named `Backend` or another value.

## Create projects inside subgroups

To manage issue-tracking across multiple projects, you need to create projects in your subgroups.

To create a new project:

1. On the left sidebar, select **Search or go to** and find your `Frontend` subgroup. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and select **New project/repository**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Create blank project**.
1. Enter the project details:
   - For **Project name**, enter `Web UI`. For more information, see project
     [naming rules](../../user/reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs).
1. At the bottom of the page, select **Create project**.
1. Repeat this process to create a second project named `Accessibility Audit` in the `Frontend`
   subgroup and a third project named `API` in the `Backend` subgroup.

## Decide on the criteria for types, severity, and priority

Next, you'll need to determine:

- **Types** of issues you want to recognize. If you need a more granular approach, you
  can also create subtypes for each type. Types help categorize work to understand the
  kind of work that is requested of your team.
- Levels of **priorities** and **severities** to define the impact that incoming work has on end
  users and to assist in prioritization.

For this tutorial, suppose you've decided on the following:

- Type: `Bug`, `Feature`, and `Maintenance`
- Priority: `1`, `2`, `3`, and `4`
- Severity: `1`, `2`, `3`, and `4`

For inspiration, see how we define these at GitLab:

- [Types and subtypes](https://handbook.gitlab.com/handbook/engineering/metrics/#work-type-classification)
- [Priority](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#priority)
- [Severity](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity)

## Document your criteria

After you agree on all the criteria, write it all down somewhere your teammates can always access.

For example, add it to a [wiki](../../user/project/wiki/_index.md) in your project, or your company
handbook published with [GitLab Pages](../../user/project/pages/_index.md).

<!-- Idea for expanding this tutorial:
     Add steps for [creating a wiki page](../../user/project/wiki/_index.md#create-a-new-wiki-page). -->

## Create scoped labels

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Next, you'll create labels to add to issues to categorize them.

The best tool for this is [scoped labels](../../user/project/labels.md#scoped-labels), which you
can use to set mutually exclusive attributes.

Checking with the list of types, severities, and priorities you've assembled
[previously](#decide-on-the-criteria-for-types-severity-and-priority), you'll want to create matching
scoped labels.

The double colon (`::`) in the name of a scoped label prevents two labels of the same scope being
used together.
For example, if you add the `type::feature` label to an issue that already has `type::bug`, the
previous one is removed.

{{< alert type="note" >}}

Scoped labels are available in the Premium and Ultimate tier.
If you're on the Free tier, you can use regular labels instead.
However, they aren't mutually exclusive.

{{< /alert >}}

To make labels available to all projects across every subgroup, first go to the parent group that
contains your subgroups. If you want labels to be available to only projects in a certain subgroup,
then follow these steps from inside a subgroup.

To create each label:

1. On the left sidebar, select **Search or go to** and find your **Web App Dev** group. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Manage** > **Labels**.
1. Select **New label**.
1. In the **Title** field, enter the name of the label. Start with `type::bug`.
1. Optional. Select a color from the available colors, or enter a hex color value for
   a specific color in the **Background color** field.
1. Select **Create label**.

Repeat steps 3-6 to create all the labels you need.
Here are some examples:

- `type::bug`
- `type::feature`
- `type::maintenance`
- `priority::1`
- `priority::2`
- `priority::3`
- `priority::4`
- `severity::1`
- `severity::2`
- `severity::3`
- `severity::4`

## Prioritize the new labels

Now, set the new labels as priority labels.
Doing this ensures that the most important issues show on top
of the issue list if you sort by priority or label priority.

To learn what happens when you sort by priority or label priority, see
[Sorting and ordering issue lists](../../user/project/issues/sorting_issue_lists.md).

To prioritize labels:

1. On the Labels page, next to a label you want to prioritize, select **Prioritize** ({{< icon name="star-o" >}}).
   This label now appears at the top of the label list, under **Prioritized labels**.
1. To change the relative priority of these labels, drag them up and down the list.
   Labels higher in the list get higher priority.
1. Prioritize all the labels you previously created.
   Make sure that labels of higher priority and severity are higher on the list than those of lower values.

![List of eleven prioritized scoped labels](img/priority_labels_v16_3.png)

## Create a parent group issue triage board

To prepare for the incoming issue backlog, create an [issue board](../../user/project/issue_board.md) that organizes issues by label.
You'll use it to quickly create issues and add labels to them by dragging cards to various lists.

To set up your issue board:

1. Decide on the scope of the board.
   For example, create a [group issue board](../../user/project/issue_board.md#group-issue-boards) to assign
   severity to issues.
1. On the left sidebar, select **Search or go to** and find your **Web App Dev** group. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Issue board**.
1. In the upper-left corner of the issue board page, select the dropdown list with the current board name.
1. Select **Create new board**.
1. In the **Title** field, enter `Issue triage (by severity)`.
1. Keep the **Show the Open list** checkbox selected and clear the **Show the Closed list** one.
1. Select **Create board**. You should see an empty board.
1. Create a list for the `severity::1` label:
   1. In the upper-right corner of the issue board page, select **Create list**.
   1. In the column that appears, from the **Value** dropdown list, select the `severity::1` label.
   1. At the bottom of the list, select **Add to board**.
1. Repeat the previous step for labels `severity::2`, `severity::3`, and `severity::4`.

To create subgroup issue boards, follow steps 3-10 from inside a subgroup.

For now, the lists in your board should be empty. Next, you'll populate them with some issues.

## Create issues for features

To track upcoming features and bugs, you must create some issues.
Issues belong in projects, but you can also create them directly from your group issue board.

Start by creating some issues for planned features.
You can create issues for bugs as you find them (hopefully not too many!).

To create an issue from your **Issue triage (by severity)** board:

1. Go to the **Open** list.
   This list shows issues that don't fit any other board list.
   If you already know which severity label your issue should have, you can create it directly from
   that label's list.
   Keep in mind that each issue created from a label list is given that label.

   For now, we'll proceed with using the **Open** list.
1. On the **Open** list, select the **Create new issue** icon ({{< icon name="plus" >}}).
1. Complete the fields:
   - Under **Title**, enter `Dark mode toggle`.
   - Select the project to which this issue applies. We will select `Frontend / Web UI`.
1. Select **Create issue**.
1. Repeat these steps to create a few more issues.

   For example, if you're building a Web API app, `Frontend` and `Backend` refer to different
   engineering teams. The projects refer to different aspects of stack development.
   Create the following issues, assigning to projects as you see fit:

   - `User registration`
   - `Profile creation`
   - `Search functionality`
   - `Add to favorites`
   - `Push notifications`
   - `Social sharing`
   - `In-app messaging`
   - `Track progress`
   - `Feedback and ratings`
   - `Settings and preferences`

{{< alert type="note" >}}

Issues in one project's issue board can't be seen from other project's issue board.
Similarly, issues in projects in one subgroup can only be seen on that subgroup's
issue board. To view all issues across every project in a parent group, you must be in
the parent group's issue board.

{{< /alert >}}

Your first triage issue board is ready!
Try it out by dragging some issues from the **Open** list to one of the label lists to add one of
the severity labels.

![Issue board with unlabeled issues and prioritized "severity" labels for labeling issues](img/triage_board_v16_3.png)

## Next steps

Next, you can:

- Tweak how you use issue boards. Some options include:
  - Edit your current issue board to also have lists for priority and type labels.
    This way, you'll make the board wider and might require some horizontal scrolling.
  - Create separate issue boards named `Issue triage (by priority)` and `Issue triage (by type)`.
    This way, you'll keep various types of triage work separate, but will require switching between
    boards.
  - [Set up issue boards for team hand-off](../boards_for_teams/_index.md).
- Browse issues by priority or severity in issue lists,
  [filtered by each label](../../user/project/issues/managing_issues.md#filter-the-list-of-issues).
  If it's available to you, make use of
  [the "is one of" filter operator](../../user/project/issues/managing_issues.md#filter-with-the-or-operator).
- Break the issues down into [tasks](../../user/tasks.md).
- Create policies that help automate issue triage in a project with the [`gitlab-triage` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage).
  Generate summary reports with heatmaps like the following:

  ![Diagonal heatmap for issues with "priority" and "severity" labels](img/triage_report_v16_3.png)

To learn more about issue triage at GitLab, see [Issue Triage](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/)
and [Triage Operations](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/).
