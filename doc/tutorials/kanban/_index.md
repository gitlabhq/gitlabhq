---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Use GitLab to facilitate Kanban'
---

<!-- vale gitlab_base.FutureTense = NO -->

This tutorial guides you through the steps on using GitLab issue boards to manage your tasks in a Kanban workflow.
By setting up groups, projects, boards, and organizing issues, you can enhance transparency, collaboration, and delivery.

To use GitLab issue boards to manage your tasks in a Kanban workflow:

- [Set up groups and projects](#set-up-groups-and-projects)
- [Create labels](#create-labels)
- [Set up Kanban board](#set-up-kanban-board)
- [Visualize flow and distribution](#visualize-flow-and-distribution)

For other information, see [Advanced tips and tricks](#advanced-tips-and-tricks) at the bottom of this page.

## Set up groups and projects

Follow the corresponding steps to [create your groups](../../user/group/_index.md#create-a-group) and [projects](../../user/project/_index.md)

If your team is working across multiple repositories, create a project for each repository in your group.

Issues will canonically be in their respective projects, but your kanban board will be in your
group so you can maintain visibility across all of your projects.
If you are working in a single repository, you can skip this step.

## Create labels

Next, let's create some labels to represent each step in your Kanban lifecycle:

- If you are working in a single project, create the labels in that project.
- If you are working across multiple projects, create the labels in your group.
  This lets you use a single set of labels across all of your projects.

In both scenarios, the process for creating labels is the same. [Create](../../user/project/labels.md#create-a-label) [scoped labels](../../user/project/labels.md#scoped-labels) for **status::to do**, **status::doing**, and **status::done**.

## Set up Kanban board

After you've created your labels, the next step is to create a Kanban board:

1. On the left sidebar, select **Search or go to** and find your group or project.
1. Select **Plan > Issue Boards**.
1. In the upper-left corner of the issue board, select the dropdown list with the current board name.
1. Select **Create new board**.
1. Enter the new board's name and then select **Create board**.
1. Create a new label list by selecting **+ New list**.
1. Set the list scope to **Label** and the value to **status::to do**.
1. Repeat the same label list creation flow to create two more label lists: **status::doing** and **status::done**.

Congrats, you now have a Kanban board. You can now create new issues in each list, drag and drop issues from one workflow step to another, and assign issues to team members.

Optionally, you can enable [work in progress (WIP) limits](../../user/project/issue_board.md#work-in-progress-limits) for each label list on your board.
To do so:

1. Select the **Edit list settings** gear icon in the top right of a label list.
1. Select **Work in progress limit > Edit**.
1. Enter the maximum number of issues allowed in the corresponding list, the press the **Enter** key.

Your list background will now automatically turn red when the limit is reached.
A "work in progress limit" cut line will also be visible in the list to visually display all issues that are over the limit below the line.

## Visualize flow and distribution

Kanban traditionally uses Cumulative Flow Diagrams to visualize load and help identify bottlenecks.
In GitLab, this can be accomplished with [Value Stream Analytics (VSA)](../../user/group/value_stream_analytics/_index.md).
Next, we'll create a custom VSA report that matches your Kanban workflow.

### Visualize flow

To visualize flow:

1. On the left sidebar, select **Search or go to** and find your group or project.
1. In the side navigation, select **Analyze > Value stream analytics**.
1. Select the **Value stream** drop down in the top-left of the page, then select **New Value Stream**.
1. Enter the desired name for the VSA report, then select the **Create from a template** option.
1. Enter **To do** for the stage name.
1. For the start event, select **Issue label was added**, then select the **status::to do** label.
1. For the end event, select **Issue label was removed**, then select the **status::to do** label.
1. Next, select **Add a stage**.
1. Repeat this same process to create stages for **status::in progress** and **status::done**.
1. When all three stages have been added, select **New value stream**.

With your custom VSA report that matches the same workflow as your Kanban board, GitLab
automatically calculates the time each issue spends in each stage and aggregates the data
across all stages.
As a result, you get the lead time and cycle time.
You can dig into each stage to see the specific timings for individual issues.

### Visualize distribution

To visualize distribution:

1. In the VSA report you've created, scroll down to the **Tasks by type** chart.
1. Select the gear icon drop down in the upper right, then search for, and select, the labels that represent the type of issue.
1. If you haven't created **type::...** scope labels or something similar, now would be a good time to start incorporating work item types into your workflow (for example, **feature**, **bug**, and **maintenance**).
1. Select **Show issues**, then select anywhere outside of the dropdown list to apply the changes.
1. The **Tasks by type** chart now shows the distribution of issues matching the selected labels over time.

## Advanced tips and tricks

- To create policies that automatically update issues based on the specified conditions, set up [`gitlab-triage`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage). For example, you can create a policy to automatically close issues when the **status::done** label is applied, or automatically add the **status::to do** label when an issue is created. The open source `gitlab-triage` gem is designed to work seamlessly with GitLab pipelines.
- To make creating different types of issues more efficient and standardized, create [description templates](../../user/project/description_templates.md).
- To visualize the load on each team member in your group or project, create an additional issue board with **assignee lists**.
- Create a scoped label set for T-shirt sizing issues. For example, **size::small**, **size::medium**, and **size::large**.
