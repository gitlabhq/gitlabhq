---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, concepts, howto
---

# GitLab ChatOps **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4466) in GitLab Ultimate 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24780) to GitLab Free in 11.9.
> - `CHAT_USER_ID` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341798) in GitLab 14.4.

Use GitLab ChatOps to interact with CI/CD jobs through chat services
like Slack.

Many organizations use chat services to collaborate, troubleshoot, and plan work. With ChatOps,
you can discuss work with your team, run CI/CD jobs, and view job output, all from the same
application.

## ChatOps workflow and CI/CD configuration

ChatOps looks for the specified job in the
[`.gitlab-ci.yml`](../yaml/index.md) on the project's default
branch. If the job is found, ChatOps creates a pipeline that contains
only the specified job. If you set `when: manual`, ChatOps creates the
pipeline, but the job doesn't start automatically.

A job run with ChatOps has the same functionality as a job run from
GitLab. The job can use existing [CI/CD variables](../variables/index.md#predefined-cicd-variables) like
`GITLAB_USER_ID` to perform additional rights validation, but these
variables can be [overridden](../variables/index.md#cicd-variable-precedence).

You should set [`rules`](../yaml/index.md#rules) so the job does not
run as part of the standard CI/CD pipeline.

ChatOps passes the following [CI/CD variables](../variables/index.md#predefined-cicd-variables)
to the job:

- `CHAT_INPUT` - The arguments passed to `/project-name run`.
- `CHAT_CHANNEL` - The name of the chat channel the job is run from.
- `CHAT_USER_ID` - The chat service ID of the user who runs the job.

When the job runs:

- If the job completes in less than 30 minutes, ChatOps sends the job output to the chat channel.
- If the job completes in more than 30 minutes, you must use a method like the
  [Slack API](https://api.slack.com/) to send data to the channel.

## Run a CI/CD job

You can run a CI/CD job from chat with the `/project-name run`
[slash command](../../integration/slash_commands.md).

Prerequisites:

- You must have at least the Developer role for the project.

To run a CI/CD job:

- In the chat client, enter `/project-name run <job name> <arguments>`.

ChatOps schedules a pipeline that contains only the specified job.

### Exclude a job from ChatOps

To prevent a job from being run from chat:

- In `.gitlab-ci.yml`, set the job to `except: [chat]`.

## Customize the ChatOps reply

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

## Related topics

- [The official GitLab ChatOps icon](img/gitlab-chatops-icon.png)
- [A repository of common ChatOps scripts](https://gitlab.com/gitlab-com/chatops)
  that GitLab uses to interact with GitLab.com
