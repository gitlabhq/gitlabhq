---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# System notes

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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
For all item types except merge requests, the filtering options are:

- **Show all activity** displays both comments and history.
- **Show comments only** hides system notes.
- **Show history only** hides user comments.

Merge requests provide more granular filtering options.

### On an epic

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Epics**.
1. Identify your desired epic, and select its title.
1. Go to the **Activity** section.
1. For **Sort or filter**, select **Show all activity**.

### On an issue

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues** and find your issue.
1. Go to **Activity**.
1. For **Sort or filter**, select **Show all activity**.

### On a merge request

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Go to **Activity**.
1. For **Sort or filter**, select **Show all activity** to see all system notes.
   To narrow the types of system notes returned, select one or more of:

   - **Approvals**
   - **Assignees &amp; Reviewers**
   - **Comments**
   - **Commits &amp; branches**
   - **Edits**
   - **Labels**
   - **Lock status**
   - **Mentions**
   - **Merge request status**
   - **Tracking**

## Privacy considerations

You can see only the system notes linked to objects you can access.

For example, if someone mentions your issue 111 in an issue in their private project:

- The project members see the following note in issue 111: `Alex Garcia mentioned in agarcia/private-project#222`.
- Non-members of the project can't see the note at all.

## Related topics

- [Notes API](../../api/notes.md)
