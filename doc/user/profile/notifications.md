---
stage: Foundations
group: Personal Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Notification emails
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Enhanced email styling [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78604) in GitLab 14.9 [with a feature flag](../../administration/feature_flags.md) named `enhanced_notify_css`. Disabled by default.
> - Enhanced email styling [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/355907) in GitLab 14.9.
> - Enhanced email styling [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/355907) in GitLab 15.0.
> - Product marketing emails [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/418137) in GitLab 16.6.

Stay informed about what's happening in GitLab with email notifications.
You can receive updates about activity in issues, merge requests, epics, and designs.

For the tool that GitLab administrators can use to send messages to users, read
[Email from GitLab](../../administration/email_from_gitlab.md).

In GitLab 17.2 and later, [notifications are rate limited](../../security/rate_limits.md#notification-emails)
per 24 hours per project or group per user.

## Who receives notifications

When notifications are enabled for an issue, merge request, or epic, GitLab notifies you of actions
that happen there.

You might receive notifications for one of the following reasons:

- You participate in an issue, merge request, epic, or design. You become a participant when you comment
  or edit, or someone mentions <sup>1</sup> you.
- You've [enabled notifications in an issue, merge request, or epic](#notifications-on-issues-merge-requests-and-epics).
- You've configured notifications for the [project](#change-level-of-project-notifications) or [group](#group-notifications).
- You're subscribed to group or project pipeline notifications through the pipeline emails [integration](../project/integrations/_index.md).

> GitLab does not send a notification when:
>
> - The account is a project bot.
> - The account is a service account with default email address.
> - The account is blocked (banned) or deactivated.
> - [A comment is edited to include a user mention](../discussions/_index.md#edit-a-comment-to-add-a-mention).
> - An administrator has blocked notifications.

## Edit notification settings

Getting many notifications can be overwhelming. You can tune the notifications you receive.
For example, you might want to be notified about all activity in a specific project.
For other projects, you only want to be notified when you are mentioned by name.

These notification settings apply only to you. They do not affect the notifications received by
anyone else.

To edit your notification settings:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. On the left sidebar, select **Notifications**.
1. Edit the desired global, group, or project notification settings.
   Edited settings are automatically saved.

### Notification scope

You can tune the scope of your notifications by selecting different notification levels for each
project and group.

Notification scope is applied from the broadest to most specific levels:

- Your **global**, or _default_, notification level applies if you
  have not selected a notification level for the project or group in which the activity occurred.
- Your **group** setting overrides your default setting.
- Your **project** setting overrides the group setting.

### Notification levels

For each project and group you can select one of the following levels:

| Level       | Description                                                 |
| ----------- | ----------------------------------------------------------- |
| Global      | Your global settings apply.                                 |
| Watch       | Receive notifications for any activity.                     |
| Participate | Receive notifications for threads you have participated in. |
| On mention  | Receive notifications when you are [mentioned](../discussions/_index.md#mentions) in a comment. |
| Disabled    | Receive no notifications.                                   |
| Custom      | Receive notifications for selected events and threads you have participated in.                  |

### Global notification settings

Your **Global notification settings** are the default settings unless you select
different values for a project or a group.

- **Notification email**: the email address your notifications are sent to.
  Defaults to your primary email address.
- **Global notification level**: the default [notification level](#notification-levels)
  which applies to all your notifications.
- **Receive notifications about your own activity**: select this checkbox to receive
  notifications about your own activity. Not selected by default.

### Group notifications

You can select a notification level and email address for each group.

#### Change level of group notifications

To select a notification level for a group, use either of these methods:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. On the left sidebar, select **Notifications**.
1. Locate the group in the **Groups** section.
1. Select the desired [notification level](#notification-levels).

Or:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select the notification dropdown list, next to the bell icon (**{notifications}**).
1. Select the desired [notification level](#notification-levels).

#### Change email address used for group notifications

You can select an email address to receive notifications for each group you belong to.
You can use group notifications, for example, if you work freelance, and want to keep email about clients' projects separate.

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. On the left sidebar, select **Notifications**.
1. Locate the group in the **Groups** section.
1. Select the desired email address.

### Change level of project notifications

To help you stay up to date, you can select a notification level for each project.

To select a notification level for a project, use either of these methods:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. On the left sidebar, select **Notifications**.
1. Locate the project in the **Projects** section.
1. Select the desired [notification level](#notification-levels).

Or:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select the notification dropdown list, next to the bell icon (**{notifications}**).
1. Select the desired [notification level](#notification-levels).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
To learn how to be notified when a new release is available, watch [Notification for releases](https://www.youtube.com/watch?v=qyeNkGgqmH4).

## Notification events

Users are notified of the following events:

<!-- The table is sorted first by recipient, then alphabetically. -->

| Event                                    | Sent to         | Settings level                                                                                                                          |
|------------------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| New release                              | Project members | Custom notification.                                                                                                                    |
| Project moved                            | Project members | Any other than disabled.                                                                                                                |
| Email changed                            | User            | Security email, always sent.                                                                                                            |
| Group access level changed               | User            | Sent when user group access level is changed.                                                                                           |
| New email address added                  | User            | Security email, sent to primary email address.                                                                                          |
| New email address added                  | User            | Security email, sent to newly-added email address.                                                                                      |
| New SAML/SCIM user provisioned           | User            | Sent when a user is provisioned through SAML/SCIM.                                                                                      |
| New SSH key added                        | User            | Security email, always sent.                                                                                                            |
| New user created                         | User            | Sent on user creation, except for OmniAuth (LDAP).                                                                                      |
| Password changed                         | User            | Security email, always sent when user changes their own password.                                                                       |
| Password changed by administrator        | User            | Security email, always sent when an administrator changes the password of another user.                                                 |
| Personal access tokens expiring soon     | User            | Security email, always sent.                                                                                                            |
| Personal access tokens have been created | User            | Security email, always sent.                                                                                                            |
| Personal access tokens have expired      | User            | Security email, always sent.                                                                                                            |
| Personal access token has been revoked   | User            | Security email, always sent.  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98911) in GitLab 15.5.                 |
| Group access tokens expiring soon        | Direct Group Owners | Security email, always sent.  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367705) in GitLab 16.4.                 |
| Project access tokens expiring soon      | Direct Project Owners and Maintainers | Security email, always sent.  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367706) in GitLab 16.4.                 |
| Project access level changed             | User            | Sent when user project access level is changed.                                                                                         |
| SSH key has expired                      | User            | Security email, always sent.                                                                                                            |
| Two-factor authentication disabled       | User            | Security email, always sent.                                                                                                            |
| User added to group                      | User            | Sent when user is added to group.                                                                                                       |
| User added to project                    | User            | Sent when user is added to project.                                                                                                     |
| Group access expired                     | Group members   | Sent when user's access to a group expires in seven days. _[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12704) in GitLab 16.3._                                                                                 |
| Project access expired                   | Project members | Sent when user's access to a project expires in seven days. _[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12704) in GitLab 16.3._                                                                                                   |

## Notifications on issues, merge requests, and epics

You also receive notifications for events happening on
issues, merge requests, and epics.

### Who receives notifications on issues, merge requests, and epics

In issues, merge requests, and epics, for most events, the notification is sent to:

- Participants:
  - The author and assignee.
  - Authors of comments.
  - Anyone [mentioned](../discussions/_index.md#mentions) by username in the title
    or description.
  - Anyone mentioned by username in a comment if their notification level is "Participating" or higher.
- Watchers: users with notification level "Watch".
- Subscribers: anyone who manually subscribed to notifications.
- Custom: users with notification level "Custom" who turned on notifications for a fitting type of events.

To minimize the number of notifications that do not require any action, eligible
approvers are not notified for all the activities in their projects. To turn on such notifications, they have
to change their user notification settings to **Watch** instead.

### Edit notification settings for issues, merge requests, and epics

To toggle notifications on an issue, merge request, or epic: on the right sidebar,
select the vertical ellipsis (**{ellipsis_v}**), then turn on or off the **Notifications** toggle.

#### Moved notifications

DETAILS:
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132678) in GitLab 16.5 [with a flag](../../administration/feature_flags.md) named `notifications_todos_buttons`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag. For more information, see the history. Enabling this feature flag moves the notifications and to-do item buttons to the upper-right corner of the page.

When you **turn on** notifications, you start receiving notifications on each update, even if you
haven't participated in the discussion.
When you turn notifications on in an epic, you aren't automatically subscribed to the issues linked
to the epic.

When you **turn off** notifications, you stop receiving notifications for updates.
Turning this toggle off only unsubscribes you from updates related to this issue, merge request, or epic.
Learn how to [opt out of all emails from GitLab](#opt-out-of-all-gitlab-emails).

### Notification events on issues, merge requests, and epics

The following table presents the events that generate notifications for issues, merge requests, and
epics:

| Type | Event | Sent to |
|------|-------|---------|
| Epic | Closed | Subscribers and participants. |
| Epic | New | Anyone mentioned by username in the description, with notification level "Mention" or higher. |
| Epic | New note | Participants, Watchers, Subscribers, and Custom notification level with this event selected. Also anyone mentioned by username in the comment, with notification level "Mention" or higher. |
| Epic | Reopened | Subscribers and participants. |
| Issue | Closed | Subscribers and participants. |
| Issue | Due | Participants and Custom notification level with this event selected. |
| Issue | Milestone changed | Subscribers and participants. |
| Issue | Milestone removed | Subscribers and participants. |
| Issue | New | Anyone mentioned by username in the description, with notification level "Mention" or higher. |
| Issue | New note | Participants, Watchers, Subscribers, and Custom notification level with this event selected. Also anyone mentioned by username in the comment, with notification level "Mention" or higher. |
| Issue | Title or description changed | Any new mentions by username. |
| Issue | Reassigned | Participants, Watchers, Subscribers, Custom notification level with this event selected, and the old assignee. |
| Issue | Reopened | Subscribers and participants. |
| Merge Request | Closed | Subscribers and participants. |
| Merge Request | Conflict | Author and any user that has set the merge request to auto-merge. |
| Merge Request | [Marked as ready](../project/merge_requests/drafts.md) | Watchers and participants. |
| Merge Request | Merged | Subscribers and participants. |
| Merge Request | Merged when pipeline succeeds | Author, Participants, Watchers, Subscribers, and Custom notification level with this event selected. Custom notification level is ignored for Author, Watchers and Subscribers. |
| Merge Request | Milestone changed | Subscribers and participants. |
| Merge Request | Milestone removed | Subscribers and participants. |
| Merge Request | New | Anyone mentioned by username in the description, with notification level "Mention" or higher. |
| Merge Request | New note | Participants, Watchers, Subscribers, and Custom notification level with this event selected. Also anyone mentioned by username in the comment, with notification level "Mention" or higher. |
| Merge Request | Pushed | Participants and Custom notification level with this event selected. |
| Merge Request | Reassigned | Participants, Watchers, Subscribers, Custom notification level with this event selected, and the old assignee. |
| Merge Request | Review requested | Participants, Watchers, Subscribers, Custom notification level with this event selected, and the old reviewer. |
| Merge Request | Reopened | Subscribers and participants. |
| Merge Request | Title or description changed | Any new mentions by username. |
| Merge Request | Added as approver | Custom notification level with this event selected. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12855) in GitLab 16.7. |
| Pipeline | Failed | The author of the pipeline. |
| Pipeline | Fixed | The author of the pipeline. Enabled by default. |
| Pipeline | Successful | The author of the pipeline, with Custom notification level for successful pipelines. If the pipeline failed previously, a "Fixed pipeline" message is sent for the first successful pipeline after the failure, and then a "Successful pipeline" message for any further successful pipelines. |

By default, you don't receive notifications for issues, merge requests, or epics created by yourself.
To always receive notifications on your own issues, merge requests, and so on, turn on
[notifications about your own activity](#global-notification-settings).

## Notifications for unknown sign-ins

> - Listing the full name and username of the signed-in user [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225183) in GitLab 15.10.
> - Geographic location [added](https://gitlab.com/gitlab-org/gitlab/-/issues/296128) in GitLab 17.5.

NOTE:
This feature is enabled by default for self-managed instances. Administrators may disable this feature
through the [Sign-in restrictions](../../administration/settings/sign_in_restrictions.md#email-notification-for-unknown-sign-ins) section of the UI.
The feature is always enabled on GitLab.com.

When a user successfully signs in from a previously unknown IP address or device,
GitLab notifies the user by email. In this way, GitLab proactively alerts users of potentially
malicious or unauthorized sign-ins. This notification email includes the:

- Hostname.
- User's name and username.
- IP address.
- Geographic location.
- Date and time of sign-in.

GitLab uses several methods to identify a known sign-in. All methods must fail for a notification email to be sent.

- Last sign-in IP: The current sign-in IP address is checked against the last sign-in
  IP address.
- Current active sessions: If the user has an existing active session from the
  same IP address. See [Active Sessions](active_sessions.md).
- Cookie: After successful sign in, an encrypted cookie is stored in the browser.
  This cookie is set to expire 14 days after the last successful sign in.

## Notifications for attempted sign-ins using incorrect verification codes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374740) in GitLab 15.5.

GitLab sends you an email notification if it detects an attempt to sign in to your account using a wrong two-factor
authentication (2FA) code. This can help you detect that a bad actor gained access to your username and password, and is trying
to brute force 2FA.

## Notifications on designs

Email notifications are sent to the participants when someone comments on a design.

The participants are:

- Authors of the design (can be multiple people if different authors have uploaded different versions of the design).
- Authors of comments on the design.
- Anyone that is [mentioned](../discussions/_index.md#mentions) in a comment on the design.

## Notifications on group or project access expiration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12704) in GitLab 16.3.

GitLab sends an email notification if a user's access to a group or project expires in seven days.
This reminds group or project members to extend their access duration if they want to.

## Opt out of all GitLab emails

If you no longer wish to receive any email notifications:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. On the left sidebar, select **Notifications**.
1. Set your **Global notification level** to **Disabled**.
1. Clear the **Receive notifications about your own activity** checkbox.
1. If you belong to any groups or projects, set their notification setting to **Global** or
   **Disabled**.

On GitLab Self-Managed instances, even after doing this, your instance administrator
[can still email you](../../administration/email_from_gitlab.md).

## Unsubscribe from notification emails

You can unsubscribe from notification emails from GitLab on a per-resource basis (for example a specific issue).

### Using the unsubscribe link

Every notification email from GitLab contains an unsubscribe link at the bottom.

To unsubscribe:

1. Select the unsubscribe link in the email.
1. If you are signed in to GitLab in your browser, you are unsubscribed immediately.
1. If you are not signed in, you need to confirm the action.

### Using an email client or other software

Your email client might show an **Unsubscribe** button when you view an email from GitLab.
To unsubscribe, select this button.

Notification emails from GitLab contain special headers.
These headers allow supported email clients and other software
to unsubscribe users automatically. Here's an example:

```plaintext
List-Unsubscribe: <https://gitlab.com/-/sent_notifications/[REDACTED]/unsubscribe>,<mailto:incoming+[REDACTED]-unsubscribe@incoming.gitlab.com>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

The `List-Unsubscribe` header has two entries:

- A link for software to send a `POST` request.
  This action directly unsubscribes the user from the resource.
  Sending a `GET` request to this link shows a confirmation dialog instead of unsubscribing.
- An email address for software to send an unsubscribe email.
  The content of the email is ignored.

## Email headers you can use to filter email

Notification email messages include GitLab-specific headers. To better manage your notifications,
you can filter the notification emails based on the content of these headers.

For example, you could filter all emails from a specific project where you are being assigned a
merge request or an issue.

The following table lists all GitLab-specific email headers:

| Header                        | Description |
|-------------------------------|-------------|
| `List-Id`                     | The path of the project in an RFC 2919 mailing list identifier. You can use it for email organization with filters. |
| `X-GitLab-(Resource)-ID`      | The ID of the resource the notification is for. The resource, for example, can be `Issue`, `MergeRequest`, `Commit`, or another such resource. |
| `X-GitLab-(Resource)-State`   | The state of the resource the notification is for. The resource can be, for example, `Issue` or `MergeRequest`. The value can be `opened`, `closed`, `merged`, or `locked`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130967) in GitLab 16.4. |
| `X-GitLab-ConfidentialIssue`  | The boolean value indicating issue confidentiality for notifications. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222908) in GitLab 16.0. |
| `X-GitLab-Discussion-ID`      | The ID of the thread the comment belongs to, in notification emails for comments. |
| `X-GitLab-Group-Id`           | The group's ID. Only present on notification emails for [epics](../group/epics/_index.md). |
| `X-GitLab-Group-Path`         | The group's path. Only present on notification emails for [epics](../group/epics/_index.md) |
| `X-GitLab-NotificationReason` | The reason for the notification. [See possible values.](#x-gitlab-notificationreason). |
| `X-GitLab-Pipeline-Id`        | The ID of the pipeline the notification is for, in notification emails for pipelines. |
| `X-GitLab-Project-Id`         | The project's ID. |
| `X-GitLab-Project-Path`       | The project's path. |
| `X-GitLab-Project`            | The name of the project the notification belongs to. |
| `X-GitLab-Reply-Key`          | A unique token to support reply by email. |

### X-GitLab-NotificationReason

The `X-GitLab-NotificationReason` header contains the reason for the notification.
The value is one of the following, in order of priority:

- `own_activity`
- `assigned`
- `review_requested`
- `mentioned`
- `subscribed`

The reason for the notification is also included in the footer of the notification email.
For example, an email with the reason `assigned` has this sentence in the footer:

> You are receiving this email because you have been assigned an item on \<configured GitLab hostname>.

#### On-call alerts notifications

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

An [on-call alert](../../operations/incident_management/oncall_schedules.md)
notification email can have one of [the alert's](../../operations/incident_management/alerts.md) statuses:

- `alert_triggered`
- `alert_acknowledged`
- `alert_resolved`
- `alert_ignored`

#### Incident escalation notifications

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

An [incident escalation](../../operations/incident_management/escalation_policies.md)
notification email can have one of [the incident's](../../operations/incident_management/incidents.md) status:

- `incident_triggered`
- `incident_acknowledged`
- `incident_resolved`
- `incident_ignored`

Expanding the list of events included in the `X-GitLab-NotificationReason` header is tracked in
[issue 20689](https://gitlab.com/gitlab-org/gitlab/-/issues/20689).

## Troubleshooting

### Pull a list of recipients for notifications

If you want to pull a list of recipients to receive notifications from a project
(mainly used for troubleshooting custom notifications),
in a Rails console, run `sudo gitlab-rails c` and be sure to update the project name:

```plaintext
project = Project.find_by_full_path '<project_name>'
merge_request = project.merge_requests.find_by(iid: 1)
current_user = User.first
recipients = NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: "push_to"); recipients.count
recipients.each { |notify| puts notify.user.username }
```

### Notifications about failed pipeline that doesn't exist

If you receive notifications (through email or Slack) regarding a failed pipeline that no longer
exists, double-check to see if you have any duplicate GitLab instances that could have triggered the
message.

### Email notifications are enabled, but not received

If you've enabled email notifications in GitLab, but users aren't receiving notifications as expected, ensure that
your email provider isn't blocking emails from your GitLab instance. Many email providers (like Outlook) block emails
coming from lesser-known self-managed mail server IP addresses. To verify, attempt to send an email
directly from the SMTP server for your instance. For example, a test email from Sendmail might look something like:

```plaintext
# (echo subject: test; echo) | $(which sendmail) -v -Am -i <valid email address>
```

If your email provider is blocking the message, you might get output like the following (depending on your email provider and SMTP server):

```plaintext
Diagnostic-Code: smtp; 550 5.7.1 Unfortunately, messages from [xx.xx.xx.xx]
weren't sent. For more information, please go to
http://go.microsoft.com/fwlink/?LinkID=526655 (http://go.microsoft.com/fwlink/?LinkID=526655) AS(900)
```

Usually this issue can be resolved by adding the IP address of your SMTP server to your
mail provider's allowlist. Check your mail provider's documentation for instructions.
