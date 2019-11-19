---
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/notifications.html'
---

# GitLab Notification Emails

GitLab Notifications allow you to stay informed about what's happening in GitLab. With notifications enabled, you can receive updates about activity in issues, merge requests, and epics. Notifications are sent via email.

## Receiving notifications

You will receive notifications for one of the following reasons:

- You participate in an issue, merge request, or epic. In this context, _participate_ means comment, or edit.
- You enable notifications in an issue, merge request, or epic. To enable notifications, click the **Notifications** toggle in the sidebar to _on_.

While notifications are enabled, you will receive notification of actions occurring in that issue, merge request, or epic.

NOTE: **Note:**
Notifications can be blocked by an admin, preventing them from being sent.

## Tuning your notifications

The quantity of notifications can be overwhelming. GitLab allows you to tune the notifications you receive. For example, you may want to be notified about all activity in a specific project, but for others, only be notified when you are mentioned by name.

You can tune the notifications you receive by combining your notification settings:

- [Global notification settings](#global-notification-settings)
- [Notification scope](#notification-scope)
- [Notification levels](#notification-levels)

### Editing notification settings

To edit your notification settings:

1. Click on your profile picture and select **Settings**.
1. Click **Notifications** in the left sidebar.
1. Edit the desired notification settings. Edited settings are automatically saved and enabled.

These notification settings apply only to you. They do not affect the notifications received by anyone else in the same project or group.

![notification settings](img/notification_global_settings.png)

## Global notification settings

Your **Global notification settings** are the default settings unless you select different values for a project or a group.

- Notification email
  - This is the email address your notifications will be sent to.
- Global notification level
  - This is the default [notification level](#notification-levels) which applies to all your notifications.
- Receive notifications about your own activity.
  - Check this checkbox if you want to receive notification about your own activity. Default: Not checked.

### Notification scope

You can tune the scope of your notifications by selecting different notification levels for each project and group.

Notification scope is applied in order of precedence (highest to lowest):

- Project
  - For each project, you can select a notification level. Your project setting overrides the group setting.
- Group
  - For each group, you can select a notification level. Your group setting overrides your default setting.
- Global (default)
  - Your global, or _default_, notification level applies if you have not selected a notification level for the project or group in which the activity occurred.

#### Project notifications

You can select a notification level for each project. This can be useful if you need to closely monitor activity in select projects.

![notification settings](img/notification_project_settings.png)

To select a notification level for a project, use either of these methods:

1. Click on your profile picture and select **Settings**.
1. Click **Notifications** in the left sidebar.
1. Locate the project in the **Projects** section.
1. Select the desired [notification level](#notification-levels).

Or:

1. Navigate to the project's page.
1. Click the notification dropdown, marked with a bell icon.
1. Select the desired [notification level](#notification-levels).

#### Group notifications

You can select a notification level and email address for each group.

![notification settings](img/notification_group_settings.png)

##### Group notification level

To select a notification level for a group, use either of these methods:

1. Click on your profile picture and select **Settings**.
1. Click **Notifications** in the left sidebar.
1. Locate the project in the **Groups** section.
1. Select the desired [notification level](#notification-levels).

---

1. Navigate to the group's page.
1. Click the notification dropdown, marked with a bell icon.
1. Select the desired [notification level](#notification-levels).

##### Group notification email address

> Introduced in GitLab 12.0

You can select an email address to receive notifications for each group you belong to. This could be useful, for example, if you work freelance, and want to keep email about clients' projects separate.

1. Click on your profile picture and select **Settings**.
1. Click **Notifications** in the left sidebar.
1. Locate the project in the **Groups** section.
1. Select the desired email address.

### Notification levels

For each project and group you can select one of the following levels:

| Level       | Description |
|:------------|:------------|
| Global      | Your global settings apply. |
| Watch       | Receive notifications for any activity. |
| On mention  | Receive notifications when `@mentioned` in comments. |
| Participate | Receive notifications for threads you have participated in. |
| Disabled    | Turns off notifications. |
| Custom      | Receive notifications for custom selected events. |

## Notification events

Users will be notified of the following events:

| Event                        | Sent to             | Settings level               |
|------------------------------|---------------------|------------------------------|
| New SSH key added            | User                | Security email, always sent. |
| New email added              | User                | Security email, always sent. |
| Email changed                | User                | Security email, always sent. |
| Password changed             | User                | Security email, always sent. |
| New user created             | User                | Sent on user creation, except for OmniAuth (LDAP)|
| User added to project        | User                | Sent when user is added to project |
| Project access level changed | User                | Sent when user project access level is changed |
| User added to group          | User                | Sent when user is added to group |
| Group access level changed   | User                | Sent when user group access level is changed |
| Project moved                | Project members (1) | (1) not disabled             |
| New release                  | Project members     | Custom notification          |

## Issue / Epics / Merge request events

In most of the below cases, the notification will be sent to:

- Participants:
  - the author and assignee of the issue/merge request
  - authors of comments on the issue/merge request
  - anyone mentioned by `@username` in the title or description of the issue, merge request or epic **(ULTIMATE)**
  - anyone with notification level "Participating" or higher that is mentioned by `@username` in any of the comments on the issue, merge request, or epic **(ULTIMATE)**
- Watchers: users with notification level "Watch"
- Subscribers: anyone who manually subscribed to the issue, merge request, or epic **(ULTIMATE)**
- Custom: Users with notification level "custom" who turned on notifications for any of the events present in the table below

| Event                  | Sent to |
|------------------------|---------|
| New issue              |         |
| Close issue            |         |
| Reassign issue         | The above, plus the old assignee |
| Reopen issue           |         |
| Due issue              | Participants and Custom notification level with this event selected |
| Change milestone issue | Subscribers, participants mentioned, and Custom notification level with this event selected |
| Remove milestone issue | Subscribers, participants mentioned, and Custom notification level with this event selected |
| New merge request      |         |
| Push to merge request  | Participants and Custom notification level with this event selected |
| Reassign merge request | The above, plus the old assignee |
| Close merge request    |         |
| Reopen merge request   |         |
| Merge merge request    |         |
| Change milestone merge request | Subscribers, participants mentioned, and Custom notification level with this event selected |
| Remove milestone merge request | Subscribers, participants mentioned, and Custom notification level with this event selected |
| New comment            | The above, plus anyone mentioned by `@username` in the comment, with notification level "Mention" or higher |
| Failed pipeline        | The author of the pipeline |
| Successful pipeline    | The author of the pipeline, if they have the custom notification setting for successful pipelines set |
| New epic **(ULTIMATE)** |        |
| Close epic **(ULTIMATE)** |      |
| Reopen epic **(ULTIMATE)** |     |

In addition, if the title or description of an Issue or Merge Request is
changed, notifications will be sent to any **new** mentions by `@username` as
if they had been mentioned in the original text.

You won't receive notifications for Issues, Merge Requests or Milestones created
by yourself (except when an issue is due). You will only receive automatic
notifications when somebody else comments or adds changes to the ones that
you've created or mentions you.

If an open merge request becomes unmergeable due to conflict, its author will be notified about the cause.
If a user has also set the merge request to automatically merge once pipeline succeeds,
then that user will also be notified.

## Email Headers

Notification emails include headers that provide extra content about the notification received:

| Header                      | Description                                                             |
|-----------------------------|-------------------------------------------------------------------------|
| X-GitLab-Project            | The name of the project the notification belongs to                     |
| X-GitLab-Project-Id         | The ID of the project                                                   |
| X-GitLab-Project-Path       | The path of the project                                                 |
| X-GitLab-(Resource)-ID      | The ID of the resource the notification is for, where resource is `Issue`, `MergeRequest`, `Commit`, etc|
| X-GitLab-Discussion-ID      | Only in comment emails, the ID of the thread the comment is from    |
| X-GitLab-Pipeline-Id        | Only in pipeline emails, the ID of the pipeline the notification is for |
| X-GitLab-Reply-Key          | A unique token to support reply by email                                |
| X-GitLab-NotificationReason | The reason for being notified. "mentioned", "assigned", etc             |
| List-Id                     | The path of the project in a RFC 2919 mailing list identifier useful for email organization, for example, with Gmail filters |

### X-GitLab-NotificationReason

This header holds the reason for the notification to have been sent out,
where reason can be `mentioned`, `assigned`, `own_activity`, etc.
Only one reason is sent out according to its priority:

- `own_activity`
- `assigned`
- `mentioned`

The reason in this header will also be shown in the footer of the notification email. For example an email with the
reason `assigned` will have this sentence in the footer:
`"You are receiving this email because you have been assigned an item on {configured GitLab hostname}"`

NOTE: **Note:**
Only reasons listed above have been implemented so far.
Further implementation is [being discussed](https://gitlab.com/gitlab-org/gitlab/issues/20689).
