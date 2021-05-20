---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Slash Commands **(FREE)**

> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24780) to GitLab Free in 11.9.

Slash commands in Mattermost and Slack allow you to control GitLab and view GitLab content right inside your chat client, without having to leave it. For Slack, this requires an [integration configuration](../user/project/integrations/slack_slash_commands.md). Type the command as a message in your chat client to activate it.

Commands are scoped to a project, with a trigger term that is specified during configuration.

We suggest you use the project name as the trigger term for simplicity and clarity.

Taking the trigger term as `project-name`, the commands are:

| Command | Effect |
| ------- | ------ |
| `/project-name help` | Shows all available slash commands |
| `/project-name issue new <title> <shift+return> <description>` | Creates a new issue with title `<title>` and description `<description>` |
| `/project-name issue show <id>` | Shows the issue with ID `<id>` |
| `/project-name issue close <id>` | Closes the issue with ID `<id>` |
| `/project-name issue search <query>` | Shows up to 5 issues matching `<query>` |
| `/project-name issue move <id> to <project>` | Moves issue ID `<id>` to `<project>` |
| `/project-name issue comment <id> <shift+return> <comment>` | Adds a new comment to an issue with ID `<id>` and comment body `<comment>` |
| `/project-name deploy <from> to <to>` | Deploy from the `<from>` environment to the `<to>` environment |
| `/project-name run <job name> <arguments>` | Execute [ChatOps](../ci/chatops/index.md) job `<job name>` on the default branch |

If you are using the [GitLab Slack application](../user/project/integrations/gitlab_slack_application.md) for
your GitLab.com projects, [add the `gitlab` keyword at the beginning of the command](../user/project/integrations/gitlab_slack_application.md#usage).

## Issue commands

It's possible to create new issue, display issue details and search up to 5 issues.

## Deploy command

To deploy to an environment, GitLab tries to find a deployment
manual action in the pipeline.

If there's only one action for a given environment, it is triggered.
If more than one action is defined, GitLab tries to find an action
which name equals the environment name we want to deploy to.

The command returns an error when no matching action has been found.
