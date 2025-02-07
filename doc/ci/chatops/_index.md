---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab ChatOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use GitLab ChatOps to interact with CI/CD jobs through chat services
like Slack.

Many organizations use Slack or Mattermost to collaborate, troubleshoot, and plan work. With ChatOps,
you can discuss work with your team, run CI/CD jobs, and view job output, all from the same
application.

## Slash command integrations

You can trigger ChatOps with the [`run` slash command](../../user/project/integrations/gitlab_slack_application.md#slash-commands).

The following integrations are available:

- [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md) (recommended for Slack)
- [Slack slash commands](../../user/project/integrations/slack_slash_commands.md)
- [Mattermost slash commands](../../user/project/integrations/mattermost_slash_commands.md)

## ChatOps workflow and CI/CD configuration

ChatOps looks for the specified job in the
[`.gitlab-ci.yml`](../yaml/_index.md) on the project's default
branch. If the job is found, ChatOps creates a pipeline that contains
only the specified job. If you set `when: manual`, ChatOps creates the
pipeline, but the job doesn't start automatically.

A job run with ChatOps has the same functionality as a job run from
GitLab. The job can use existing [CI/CD variables](../variables/_index.md#predefined-cicd-variables) like
`GITLAB_USER_ID` to perform additional rights validation, but these
variables can be [overridden](../variables/_index.md#cicd-variable-precedence).

You should set [`rules`](../yaml/_index.md#rules) so the job does not
run as part of the standard CI/CD pipeline.

ChatOps passes the following [CI/CD variables](../variables/_index.md#predefined-cicd-variables)
to the job:

- `CHAT_INPUT` - The arguments passed to the `run` slash command.
- `CHAT_CHANNEL` - The name of the chat channel the job is run from.
- `CHAT_USER_ID` - The chat service ID of the user who runs the job.

When the job runs:

- If the job completes in less than 30 minutes, ChatOps sends the job output to the chat channel.
- If the job completes in more than 30 minutes, you must use a method like the
  [Slack API](https://api.slack.com/) to send data to the channel.

### Exclude a job from ChatOps

To prevent a job from being run from chat:

- In `.gitlab-ci.yml`, set the job to `except: [chat]`.

### Customize the ChatOps reply

ChatOps sends the output for a job with a single command to the
channel as a reply. For example, when the following job runs,
the chat reply is `Hello world`:

```yaml
stages:
- chatops

hello-world:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "Hello World"
```

If the job contains multiple commands, or if `before_script` is set, ChatOps sends the commands
and their output to the channel. The commands are wrapped in ANSI color codes.

To selectively reply with the output of one command, place the output
in a `chat_reply` section. For example, the following job lists the
files in the current directory:

```yaml
stages:
- chatops

ls:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "This command will not be shown."
    - echo -e "section_start:$( date +%s ):chat_reply\r\033[0K\n$( ls -la )\nsection_end:$( date +%s ):chat_reply\r\033[0K"
```

## Trigger a CI/CD job using ChatOps

Prerequisites:

- You must have at least the Developer role for the project.
- The project is configured to use a slash command integration.

You can run a CI/CD job on the default branch from Slack or Mattermost.

The slash command to trigger a CI/CD job depends on which slash command integration
is configured for the project.

- For the GitLab for Slack app, use `/gitlab <project-name> run <job name> <arguments>`.
- For Slack or Mattermost slash commands, use `/<trigger-name> run <job name> <arguments>`.

Where:

- `<job name>` is the name of the CI/CD job to run.
- `<arguments>` are the arguments to pass to the CI/CD job.
- `<trigger-name>` is the trigger name configured for the Slack or Mattermost integration.

ChatOps schedules a pipeline that contains only the specified job.

## Related topics

- [A repository of common ChatOps scripts](https://gitlab.com/gitlab-com/chatops)
  that GitLab uses to interact with GitLab.com
- [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)
- [Slack slash commands](../../user/project/integrations/slack_slash_commands.md)
- [Mattermost slash commands](../../user/project/integrations/mattermost_slash_commands.md)
