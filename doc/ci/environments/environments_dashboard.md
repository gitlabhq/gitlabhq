---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Environments Dashboard
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The Environments Dashboard provides a cross-project
environment-based view that lets you see the big picture
of what is going on in each environment. From a single
location, you can track the progress as changes flow
from development to staging, and then to production (or
through any series of custom environment flows you can set up).
With an at-a-glance view of multiple projects, you can instantly
see which pipelines are green and which are red allowing you to
diagnose if there is a block at a particular point, or if there's
a more systemic problem you need to investigate.

1. On the left sidebar, select **Search or go to**.
1. Select **Your work**.
1. Select **Environments**.

![Environments Dashboard with projects.](img/environments_dashboard_v12_5.png)

The Environments dashboard displays a paginated list of projects that includes
up to three environments per project.

The listed environments for each project are unique, such as
"production" and "staging". Review apps and other grouped
environments are not displayed.

## Adding a project to the dashboard

To add a project to the dashboard:

1. Select **Add projects** in the home screen of the dashboard.
1. Search and add one or more projects using the **Search your projects** field.
1. Select **Add projects**.

Once added, you can see a summary of each project's environment operational
health, including the latest commit, pipeline status, and deployment time.

The Environments and [Operations](../../user/operations_dashboard/_index.md)
dashboards share the same list of projects. When you add or remove a
project from one, GitLab adds or removes the project from the other.

You can add up to 150 projects for GitLab to display on this dashboard.

## Environment dashboards on GitLab.com

GitLab.com users can add public projects to the Environments
Dashboard for free. If your project is private, the group it belongs
to must have a [GitLab Premium](https://about.gitlab.com/pricing/) plan.
