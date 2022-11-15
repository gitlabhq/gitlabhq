---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Incident management for Slack **(FREE SAAS)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8545) in GitLab 15.6.

Many teams receive alerts and collaborate in real time during incidents in Slack.
With the GitLab for Slack app:

- Create GitLab incidents from Slack.
- Receive incident notifications.
- Send important updates between Slack and GitLab incidents.

Incident management for Slack is initially only available for GitLab.com. Some of the functionality
described might be available for
[the self-managed Slack app](../../user/project/integrations/slack_slash_commands.md).
To stay up to date, follow [epic 1211](https://gitlab.com/groups/gitlab-org/-/epics/1211).

## Setup and configuration

To be able to manage incidents from Slack:

1. Install the [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md).
   Installing this application allows you to use slash commands in Slack to create and update GitLab incidents.

1. Enable [Slack notifications](../../user/project/integrations/slack.md). Be sure to enable
   notifications for `Issue` events, and to define a Slack channel to receive the relevant notifications.

## Manage an incident from Slack

Use the following slash commands in Slack to manage incidents

| Command                            | Description                                |
| ---------------------------------- | ------------------------------------------ |
| `/gitlab incident declare`         | Creates an incident in GitLab.              |
| `/gitlab incident comment <text>`  | Adds a comment on a GitLab incident.        |
| `/gitlab incident timeline <text>` | Adds a timeline event to a GitLab incident. |

After the Slack app for GitLab is configured, you can also use any of the [existing slash commands for Slack](../../user/project/integrations/gitlab_slack_application.md).

### Declare an incident

After you've configured the GitLab for Slack app, create incidents in GitLab from Slack
with the `/gitlab incident declare` slash command.

To declare an incident:

1. In Slack, in any channel or DM, enter the `/gitlab incident declare` slash command.
1. From the modal, select the relevant incident details, including:

   - The incident title and description.
   - The project where the incident should be created.
   - The severity of the incident.

   If there is an existing [incident template](incidents.md#create-incidents-automatically) for your
   project, that template is automatically applied to the description field. The template is applied
   only if the description field is empty.

   You can also include GitLab [quick actions](../../user/project/quick_actions.md) in the description field.
   For example, typing `/link https://example.slack.com/archives/123456789 Dedicated Slack channel`
   adds a dedicated Slack channel to the incident you create. For a more complete list of applicable
   quick actions for incidents, see [Use GitLab quick actions](#use-gitlab-quick-actions).
1. Optional. Add a link to an existing Zoom meeting.
1. Select **Create**.

If the incident is successfully created, Slack shows a confirmation notification.

#### Use GitLab quick actions

Use [quick actions](../../user/project/quick_actions.md) in the description field when creating
an incident from Slack to take additional actions in GitLab. The following quick actions might be the most relevant to you:

| Command                  | Description                               |
| ------------------------ | ----------------------------------------- |
| `/assign @user1 @user2`  | Adds an assignee to the GitLab incident.  |
| `/label ~label1 ~label2` | Adds labels to the GitLab incident.       |
| `/link <URL> <text>`     | Adds a link to a dedicated Slack channel, a runbook, or to any relevant resource to the `Related resources` section of an incident. |
| `/zoom <URL>`            | Adds a Zoom meeting link to the incident. |

### Comment on GitLab incidents

Comment on GitLab incidents from Slack with the `/gitlab incident comment <text>` slash command.

After you enter this slash command, Slack shows a prompt asking you to confirm which incident you'd
like to post your comment to.

### Add a timeline event

Add a [timeline event](incident_timeline_events.md) to a GitLab incident from Slack with the
`/gitlab incident timeline <text>` slash command.

After you enter this slash command, Slack shows a prompt asking you to confirm which incident you'd
like to add your timeline event to.

### Close an incident

When your incident is fully resolved, close your incident from Slack using the `/gitlab incident close`
slash command.

After you enter this slash command, Slack shows a prompt asking you to confirm which incident you'd
like to close.

## Send GitLab incident notifications to Slack

If you have [enabled notifications](#setup-and-configuration) for issues, you should receive
notifications to the selected Slack channel every time an incident is opened, closed, or updated.

## Troubleshooting

### No projects in the incident project dropdown list

If this happens, you might have not authorized GitLab to take actions on behalf of your Slack user.

Try executing a non-incident [Slack slash command](../../integration/slash_commands.md) to start the
authorization flow. For more context, visit [issue 377548](https://gitlab.com/gitlab-org/gitlab/-/issues/377548).
