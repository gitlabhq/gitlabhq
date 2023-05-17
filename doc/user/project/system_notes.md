---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# System notes **(FREE)**

System notes are short descriptions that help you understand the history of events
that occur during the life cycle of a GitLab object, such as:

- [Alerts](../../operations/incident_management/alerts.md).
- [Designs](issues/design_management.md).
- [Issues](issues/index.md).
- [Merge requests](merge_requests/index.md).
- [Objectives and key results](../okrs.md) (OKRs).
- [Tasks](../tasks.md).

GitLab logs information about events triggered by Git or the GitLab application
in system notes. System notes use the format `<Author> <action> <time ago>`.

## Show or filter system notes

By default, system notes do not display. When displayed, they are shown oldest first.
If you change the filter or sort options, your selection is remembered across sections.
The filtering options are:

- **Show all activity** displays both comments and history.
- **Show comments only** hides system notes.
- **Show history only** hides user comments.

### On an epic

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Epics** (**{epic}**).
1. Identify your desired epic, and select its title.
1. Go to the **Activity** section.
1. For **Sort or filter**, select **Show all activity**.

### On an issue

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Issues** and find your issue.
1. Go to **Activity**.
1. For **Sort or filter**, select **Show all activity**.

### On a merge request

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Merge requests** and find your merge request.
1. Go to **Activity**.
1. For **Sort or filter**, select **Show all activity**.

## Related topics

- [Notes API](../../api/notes.md)
