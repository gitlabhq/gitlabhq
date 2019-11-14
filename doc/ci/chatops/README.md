---
type: index, concepts, howto
---

# GitLab ChatOps

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/4466) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/24780) to [GitLab Core](https://about.gitlab.com/pricing/) in 11.9.

GitLab ChatOps provides a method to interact with CI/CD jobs through chat services like Slack. Many organizations' discussion, collaboration, and troubleshooting is taking place in chat services these days, and having a method to run CI/CD jobs with output posted back to the channel can significantly augment a team's workflow.

NOTE: **Note:**
ChatOps is currently in alpha with some important features missing, like access control.

## How it works

GitLab ChatOps is built upon two existing features:

- [GitLab CI/CD](../README.md).
- [Slack Slash Commands](../../user/project/integrations/slack_slash_commands.md).

A new `run` action has been added to the [slash commands](../../integration/slash_commands.md), which takes two arguments: a `<job name>` to execute and the `<job arguments>`. When executed, ChatOps will look up the specified job name and attempt to match it to a corresponding job in [`.gitlab-ci.yml`](../yaml/README.md). If a matching job is found on `master`, a pipeline containing just that job is scheduled. Two additional [CI/CD variables](../variables/README.md#predefined-environment-variables) are passed to the job: `CHAT_INPUT` contains any additional arguments, and `CHAT_CHANNEL` is set to the name of channel the action was triggered in.

After the job has finished, its output is sent back to Slack provided it has completed within 30 minutes. If a job takes more than 30 minutes to run it must use the Slack API to manually send data back to a channel.

[Developer access and above](../../user/permissions.html#project-members-permissions) is required to use the `run` command. If a job should not be able to be triggered from chat, it can be set to `except: [chat]`.

## Creating a ChatOps CI job

Since ChatOps is built upon GitLab CI/CD, the job has all the same features and functions available. There a few best practices to consider however when creating ChatOps jobs:

- It is strongly recommended to set `only: [chat]` so the job does not run as part of the standard CI pipeline.
- If the job is set to `when: manual`, the pipeline will be created however the job will wait to be started.
- It is important to keep in mind that there is limited support for access control. If the user who triggered the slash command is a developer in the project, the job will run. The job itself can utilize existing [CI/CD variables](../variables/README.html#predefined-environment-variables) like `GITLAB_USER_ID` to perform additional rights validation, however these variables can be [overridden](../variables/README.html#priority-of-environment-variables).

### Controlling the ChatOps reply

For jobs with a single command, its output is automatically sent back to the channel as a reply. For example the chat reply of the following job is simply `Hello World.`

```yaml
hello-world:
  stage: chatops
  only: [chat]
  script:
    - echo "Hello World."
```

Jobs that contain multiple commands, or have a `before_script`, include additional content in the chat reply. In these cases both the commands and their output are included, with the commands wrapped in ANSI colors codes.

To selectively reply with the output of one command, its output must be bounded by the `chat_reply` section. For example, the following job will list the files in the current directory.

```yaml
ls:
  stage: chatops
  only: [chat]
  script:
    - echo "This command will not be shown."
    - echo -e "section_start:$( date +%s ):chat_reply\r\033[0K\n$( ls -la )\nsection_end:$( date +%s ):chat_reply\r\033[0K"
```

## GitLab ChatOps Examples

The GitLab.com team created a repository of [common ChatOps scripts they use to interact with our Production instance of GitLab](https://gitlab.com/gitlab-com/chatops). They are likely useful
to other adminstrators of GitLab instances and can serve as inspiration for ChatOps scripts you can write to interact with your own applications.

## GitLab ChatOps icon

Say Hi to our ChatOps bot.
You can find and download the official GitLab ChatOps icon here.

![GitLab ChatOps bot icon](img/gitlab-chatops-icon-small.png)

[Download bigger image](img/gitlab-chatops-icon.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
