---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, concepts, howto
---

# GitLab ChatOps **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4466) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24780) to [GitLab Free](https://about.gitlab.com/pricing/) in 11.9.

GitLab ChatOps provides a method to interact with CI/CD jobs through chat services
like Slack. Many organizations' discussion, collaboration, and troubleshooting takes
place in chat services. Having a method to run CI/CD jobs with output
posted back to the channel can significantly augment your team's workflow.

## How GitLab ChatOps works

GitLab ChatOps is built upon [GitLab CI/CD](../README.md) and
[Slack Slash Commands](../../user/project/integrations/slack_slash_commands.md).
ChatOps provides a `run` action for [slash commands](../../integration/slash_commands.md)
with the following arguments:

- A `<job name>` to execute.
- The `<job arguments>`.

ChatOps passes the following [CI/CD variables](../variables/index.md#predefined-cicd-variables)
to the job:

- `CHAT_INPUT` contains any additional arguments.
- `CHAT_CHANNEL` is set to the name of channel the action was triggered in.

When executed, ChatOps looks up the specified job name and attempts to match it
to a corresponding job in [`.gitlab-ci.yml`](../yaml/index.md). If a matching job
is found on the default branch, a pipeline containing only that job is scheduled. After the
job completes:

- If the job completes in *less than 30 minutes*, the ChatOps sends the job's output to Slack.
- If the job completes in *more than 30 minutes*, the job must use the
  [Slack API](https://api.slack.com/) to send data to the channel.

To use the `run` command, you must have at least the
[Developer role](../../user/permissions.md#project-members-permissions).
If a job shouldn't be able to be triggered from chat, you can set the job to `except: [chat]`.

## Best practices for ChatOps CI jobs

Since ChatOps is built upon GitLab CI/CD, the job has all the same features and
functions available. Consider these best practices when creating ChatOps jobs:

- GitLab strongly recommends you set `only: [chat]` so the job does not run as part
  of the standard CI pipeline.
- If the job is set to `when: manual`, ChatOps creates the pipeline, but the job waits to be started.
- ChatOps provides limited support for access control. If the user triggering the
  slash command has at least the [Developer role](../../user/permissions.md#project-members-permissions)
  in the project, the job runs. The job itself can use existing
  [CI/CD variables](../variables/index.md#predefined-cicd-variables) like
  `GITLAB_USER_ID` to perform additional rights validation, but
  these variables can be [overridden](../variables/index.md#cicd-variable-precedence).

### Controlling the ChatOps reply

The output for jobs with a single command is sent to the channel as a reply. For
example, the chat reply of the following job is `Hello World` in the channel:

```yaml
hello-world:
  stage: chatops
  only: [chat]
  script:
    - echo "Hello World"
```

Jobs that contain multiple commands (or `before_script`) return additional
content in the chat reply. In these cases, both the commands and their output are
included, with the commands wrapped in ANSI color codes.

To selectively reply with the output of one command, its output must be bounded by
the `chat_reply` section. For example, the following job lists the files in the
current directory:

```yaml
ls:
  stage: chatops
  only: [chat]
  script:
    - echo "This command will not be shown."
    - echo -e "section_start:$( date +%s ):chat_reply\r\033[0K\n$( ls -la )\nsection_end:$( date +%s ):chat_reply\r\033[0K"
```

## GitLab ChatOps examples

The GitLab.com team created a repository of [common ChatOps scripts](https://gitlab.com/gitlab-com/chatops)
they use to interact with our Production instance of GitLab. Administrators of
other GitLab instances may find them useful. They can serve as inspiration for ChatOps
scripts you can write to interact with your own applications.

## GitLab ChatOps icon

The [official GitLab ChatOps icon](img/gitlab-chatops-icon.png) is available for download.
You can find and download the official GitLab ChatOps icon here.

![GitLab ChatOps bot icon](img/gitlab-chatops-icon-small.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
