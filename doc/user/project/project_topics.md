---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project topics
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Topics are labels that you can assign to projects to help you organize and find them.
A topic is typically a short name that describes the content or purpose of a project.
You can assign a topic to several projects.

For example, you can create and assign the topics `python` and `hackathon` to all projects that use Python and are intended for Hackathon contributions.

Topics assigned to a project are displayed in the **Project overview** and [**Projects**](working_with_projects.md#view-all-projects-for-the-instance) lists, below the project information description.

NOTE:
Only users with access to the project can see the topics assigned to that project,
but everyone (including unauthenticated users) can see the topics available on the GitLab instance.
Do not include sensitive information in the name of a topic.

## Explore topics

To explore project topics:

1. On the left sidebar, select **Search or go to**.
1. Select **Explore**.
1. On the left sidebar, select **Topics**. The **Explore topics** page displays a list of all project topics.
1. Optional. To filter topics by name, in the search box, enter your search criteria.
1. To view the projects associated with a topic, select a topic.
   You can also access a topic page with the URL `https://gitlab.com/explore/projects/topics/<topic-name>`.

## Filter and sort topics

On the project topic page, you can filter the list of projects that have that topic by:

- Name
- Language
- Visibility
- Owner
- Archived projects

You can also sort the projects by:

- Date
- Name
- Number of stars

- To filter projects by name, in the search box, enter your search criteria.
- To sort projects by other criteria, from the dropdown lists, select an option.

## Subscribe to a topic

If you want to know when new projects are added to a topic, you can use its RSS feed.

You can do this either from the **Explore topics** page or a project with topics.

To subscribe to a topic:

- From the **Explore topics** page:

  1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
  1. Select **Explore**.
  1. Select **Topics**.
  1. Select the topic you want to subscribe to.
  1. In the upper-right corner, select **Subscribe to the new projects feed** (**{rss}**).

- From a project:

  1. On the left sidebar, select **Search or go to** and find your project.
  1. In the **Project overview** page, from the **Topics** list select the topic you want to subscribe to.
  1. In the upper-right corner, select **Subscribe to the new projects feed** (**{rss}**).

The results are displayed as an RSS feed in Atom format.
The URL of the result contains a feed token and the list of projects that have the topic. You can add this URL to your feed reader.

## Assign topics to a project

To assign topics to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. In the **Topics** text box, enter the project topics. Popular topics are suggested as you type.
1. Select **Save changes**.

## Administer topics

Instance administrators can administer all project topics from the
[**Admin** area's Topics page](../../administration/admin_area.md#administering-topics).
