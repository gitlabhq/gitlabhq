---
stage: Plan
group: Optimize
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Set up an analytics-powered website project'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you work on a complex project (for example, a website), you likely collaborate with other people to build and maintain it.
The way you collaborate and communicate in your team can make or break the project, so you want processes in place that help team members follow and achieve the common goal.
Analytics metrics help you understand how the team is doing, and if you need to adjust processes so you can work better together.
GitLab provides different types of [analytics](../../user/analytics/_index.md) insights at the instance, group, and project level.
If this list seems long and you're not sure where to start, then this tutorial is for you.

Follow along to learn how to set up an example website project, collaborate with other GitLab users,
and use project-level analytics reports to evaluate the development of your project.

Here's an overview of what we're going to do:

1. Create a project from a template.
1. Invite users to the project.
1. Create project labels.
1. Create a value stream with a custom stage.
1. Create an Insights report.
1. View merge request and issue analytics.

## Before you begin

- You must have the Owner role for the group in which you create the project.

## Create a project from a template

First of all, you need to create a project in your group.

GitLab provides project templates,
which make it easier to set up a project with all the necessary files for various use cases.
Here, you'll create a project for a Hugo website.

To create a project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Pages/Hugo** template.
1. In the **Project name** text box, enter a name (for example `My website`).
1. From the **Project URL** dropdown list, select the group you want to create the project in.
1. In the **Project slug** text box, enter a slug for your project (for example, `my-website`).
1. Optional. In the **Project description** text box, enter a description of your project.
   For example, "Analytics-powered project for a website built with Hugo". You can add or edit this description at any time.
1. Under **Visibility Level**, select the desired level for the project.
   If you create the project in a group, the visibility setting for a project must be at least as restrictive as the visibility of its parent group.
1. Select **Create project**.

Now you have a project with all the files you need for a Hugo website.

## Invite users to the project

When working on a large project such as a website, you'll likely need to collaborate with other people,
such as developers and designers.
You have to invite them to your project, so that they get access to all the files, issues, and reports.

To invite a user to the `My website` project:

1. In the project, select **Manage > Members**.
1. Select **Invite members**.
1. Enter the user's **username**.
1. From the **Role** dropdown list, select the **Developer** role or higher.
   Users must have at least the Developer role to view analytics and contribute to issues and merge requests.
1. Optional. In the **Access expiration date** picker, select a date.
   This step is recommended if the invited member is expected to contribute to the project only for a limited time.
1. Select **Invite**.

The invited user should now be a member of the project.
You can [view, filter, and search for members](../../user/project/members/_index.md#filter-and-sort-project-members) of your project.

## Create project labels

[Labels](../../user/project/labels.md) help you organize and track issues, merge requests, and epics.
You can create as many labels as you need for your projects and groups.
For example, for a website project like this one, the labels `feature request` and `bug` might be useful.

To create a project label, in the `My website` project:

1. Select **Manage > Labels**.
1. Select **New label**.
1. In the **Title** field, enter `feature request`.
1. Optional. In the **Description** field, enter additional information about how and when to use this label.
1. Optional. Select a color by selecting from the available colors, or enter a hex color value for a specific color in the **Background color** field.
1. Select **Create label**.

The label should now appear in the [label list](../../user/project/labels.md#view-project-labels),
and you can use it to create a value stream with a custom stage.

## Create a value stream with a custom stage

Now that you have a project with collaborators, you can start tracking and visualizing the activity.
[Value Stream Analytics](../../user/group/value_stream_analytics/_index.md) helps you measure the time it takes
to go from an idea to production, and identify inefficiencies in the development process.
For a click-through demo of analytics features, see [the Value Stream Management product tour](https://gitlab.navattic.com/vsm).

To get started, create a value stream in the `My website` project:

1. Select **Analyze > Value Stream Analytics**.
1. Select **New Value Stream**.
1. Enter a name for the value stream, for example `My website value stream`.
1. Select **Create from default template**.
1. To add a custom stage, select **Add a stage**.
   - Enter a name for the stage, for example `Labeled MRs merged`.
   - From the **Start event** dropdown list, select **Merge request label was added**, then the `feature request` label.
   - From the **Stop event** dropdown list, select **Merge request merged**.
1. Select **Create value stream**.

After you create the value stream, data starts collecting and loading.
This process might take a while. When it's ready, the dashboard is displayed in **Analyze > Value Stream Analytics**.

In the meantime, you can start creating an Insights report for your project.

## Create an Insights report

While Value Stream Analytics give an overview of the entire development process,
[Insights](../../user/project/insights/_index.md) provide a more granular view of a project's
issues created and closed, and average merge time of merge requests.
This data visualization can help you triage issues at a glance.

You can create as many Insights reports with different charts as you need.
For example, a stacked bar chart for bugs by severity or a line chart for issues opened over the month.

To create an Insights report, in the `My website` project:

1. Above the file list, select the plus icon, then select **New file**.
1. In the **File name** text box, enter `.gitlab/insights.yml`.
1. In the large text box, enter the following code:

   ```yaml
   bugsCharts:
      title: "Charts for bugs"
      charts:
         - title: "Monthly bugs created"
            description: "Open bugs created per month"
            type: bar
            query:
            data_source: issuables
            params:
               issuable_type: issue
               issuable_state: opened
               filter_labels:
                  - bug
               group_by: month
               period_limit: 12
   ```

1. Select **Commit changes**.

Now you have an Insights bar chart that displays the number of issues with the label `~bug` created per month, for the past 12 months.
You and project members with at least the Developer role can view the Insights report in **Analyze > Insights**.

## View merge request and issue analytics

In addition to the Insights reports, you can get detailed analytics on the merge requests and issues of your project.
[Merge request analytics](../../user/analytics/merge_request_analytics.md) and [Issue analytics](../../user/group/issues_analytics/_index.md) display charts and tables with metrics such as assignees, merge request throughput, and issue status.

To view merge request and issue analytics, in the `My website` project, select **Analyze > Merge request analytics** or **Analyze > Issue analytics**.

That was it! Now you have an analytics-powered website project on which you can collaborate efficiently with your team.
