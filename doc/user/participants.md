---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Users who interacted with GitLab work items and merge requests including authors, assignees, and users who commented, added reactions, or were mentioned."
title: Participants
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Participants are users who interacted with work items and merge requests.
They include authors, assignees, reviewers (for merge requests), and users who commented,
added emoji reactions, or were mentioned in comments or descriptions.

Participants are available for work items (such as issues, tasks, epics) and merge requests.

## View participants

### For work items

To view participants of a work item:

1. In the top bar, select **Search or go to** and find your project or group.
1. Go to your work item:
   - For issues and tasks: Select **Plan** > **Issues**, then select your work item.
   - For epics: Select **Plan** > **Epics**, then select your epic.
1. In the right sidebar, in the **Participants** section, view all users who
   participated in the work item.

### For merge requests

To view participants in a merge request:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. In the right sidebar, in the **Participants** section, view all users who
   participated in the merge request.

## Participant visibility and permissions

The participant list shows only users who have the necessary permissions
to access the work item or merge request:

- **Base requirement** - Users need read permissions to the work item or
  merge request to appear as participants.
- **Internal notes** - Users mentioned in internal notes only appear as participants
  if they have permission to read internal notes.
- **Mentions add participants** - Users mentioned with `@username` or group mentions
  like `@team-name` are added as participants if they have work item or
  merge request access.

> [!warning]
> Group mentions (like `@team-name`) add all direct group members as participants.
> Be careful when using `@` with common words, as this may unintentionally mention
> existing groups.

## Participants and email notifications

Being a participant in a work item or merge request affects your email notification settings.
Understanding this relationship helps you manage your notification preferences effectively.

How participant status relates to notifications:

- Automatic participation: When you comment, edit, or are mentioned in a work item or merge request,
  you automatically become a participant.
  This can trigger email notifications based on your notification level settings.
- Notification levels: Your [notification level](profile/notifications.md#notification-levels)
  determines which activities generate email notifications.
- Subscribed participants: You can manually
  [subscribe to notifications](profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
  for a work item or merge request even if you haven't participated yet.
  This adds you to the participant list and turns on notifications based on your default notification level.
- Mention notifications: When someone mentions you with `@username` in a comment or description, you receive a notification and become a participant, regardless of your notification level setting.
- Confidential content: For confidential work items, only users with appropriate permissions appear as participants and receive notifications.
  For more information, see [participant visibility and permissions](#participant-visibility-and-permissions).

For more information about managing your notification preferences, see [notification emails](profile/notifications.md)
