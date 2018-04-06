# Slash Commands

> The `run` command was [introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4466) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.6.

Slash commands in Mattermost and Slack allow you to control GitLab and view GitLab content right inside your chat client, without having to leave it. For Slack, this requires a [project service configuration](../user/project/integrations/slack_slash_commands.md). Simply type the command as a message in your chat client to activate it.

Commands are scoped to a project, with a trigger term that is specified during configuration.

We suggest you use the project name as the trigger term for simplicity and clarity.

Taking the trigger term as `project-name`, the commands are:


| Command | Effect |
| ------- | ------ |
| `/project-name help` | Shows all available slash commands |
| `/project-name issue new <title> <shift+return> <description>` | Creates a new issue with title `<title>` and description `<description>` |
| `/project-name issue show <id>` | Shows the issue with id `<id>` |
| `/project-name issue search <query>` | Shows up to 5 issues matching `<query>` |
| `/project-name issue move <id> to <project>` | Moves issue ID `<id>` to `<project>` |
| `/project-name deploy <from> to <to>` | Deploy from the `<from>` environment to the `<to>` environment |
| `/project-name run <job name> <arguments>` | Execute [ChatOps](../ci/chatops/README.md) job `<job name>` on `master` (available in GitLab Ultimate only) |

Note that if you are using the [GitLab Slack application](https://docs.gitlab.com/ee/user/project/integrations/gitlab_slack_application.html) for
your GitLab.com projects, you need to [add the `gitlab` keyword at the beginning of the command](https://docs.gitlab.com/ee/user/project/integrations/gitlab_slack_application.html#usage).

## Issue commands

It is possible to create new issue, display issue details and search up to 5 issues.

## Deploy command

In order to deploy to an environment, GitLab will try to find a deployment
manual action in the pipeline.

If there is only one action for a given environment, it is going to be triggered.
If there is more than one action defined, GitLab will try to find an action
which name equals the environment name we want to deploy to.

Command will return an error when no matching action has been found.
