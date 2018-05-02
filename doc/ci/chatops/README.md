# GitLab ChatOps **[ULTIMATE]**
> **Notes:**

> * [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4466) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.6.

> * ChatOps is currently in alpha, with some important features missing like access control.

GitLab ChatOps provides a method to interact with CI/CD jobs through chat services like Slack. Many organizations' discussion, collaboration, and troubleshooting is taking place in chat services these days, and having a method to run CI/CD jobs with output posted back to the channel can significantly augment a team's workflow.

## How it works

GitLab ChatOps is built upon two existing features, [GitLab CI/CD](../README.md) and [Slack Slash Commmands](../../user/project/integrations/slack_slash_commands.md). 

A new `run` action has been added to the [slash commands](../../integration/slash_commands.md), which takes two arguments: a `<job name>` to execute and the `<job arguments>`. When executed, ChatOps will look up the specified job name and attempt to match it to a corresponding job in [.gitlab-ci.yml](../yaml/README.md). If a matching job is found on `master`, a pipeline containing just that job is scheduled. Two additional [CI/CD variables](../variables/README.html#predefined-variables-environment-variables) are passed to the job: `CHAT_INPUT` contains any additional arguments, and `CHAT_CHANNEL` is set to the name of channel the action was triggered in.

After the job has finished, its output is sent back to Slack provided it has completed within 30 minutes. If a job takes more than 30 minutes to run it must use the Slack API to manually send data back to a channel.

[Developer access and above](../../user/permissions.html#project-members-permissions) is required to use the `run` command. If a job should not be able to be triggered from chat, it can be set to `except: [chat]`.

## Creating a ChatOps CI job

Since ChatOps is built upon GitLab CI/CD, the job has all the same features and functions available. There a few best practices to consider however when creating ChatOps jobs:

* It is strongly recommended to set `only: [chat]` so the job does not run as part of the standard CI pipeline. 
* If the job is set to `when: manual`, the pipeline will be created however the job will wait to be started. 
* It is important to keep in mind that there is very limited support for access control. If the user who triggered the slash command is a developer in the project, the job will run. The job itself can utilize existing [CI/CD variables](../variables/README.html#predefined-variables-environment-variables) like `GITLAB_USER_ID` to perform additional rights validation, however these variables can be [overridden](https://docs.gitlab.com/ce/ci/variables/README.html#priority-of-variables).

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

