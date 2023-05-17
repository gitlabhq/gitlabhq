---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Slash commands in Mattermost and Slack **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24780) from GitLab Ultimate to GitLab Free in 11.9.

If you want to control and view GitLab content while you're
working in Slack and Mattermost, you can use slash commands.
Type the command as a message in your chat client to activate it.
For Slack, this requires an [integration configuration](../user/project/integrations/slack_slash_commands.md).

Slash commands are scoped to a project and require
a specified trigger command during configuration.
You should use the project name as the trigger command.

If you're using the [GitLab for Slack app](../user/project/integrations/gitlab_slack_application.md) for
your GitLab.com projects, [add the `gitlab` keyword at the beginning of the command](../user/project/integrations/gitlab_slack_application.md#slash-commands)
(for example, `/gitlab <project-name> issue show <id>`).

Assuming `project-name` is the trigger command, the slash commands are:

| Command | Effect |
| ------- | ------ |
| `/project-name help` | Shows all available slash commands. |
| `/project-name issue new <title> <shift+return> <description>` | Creates a new issue with title `<title>` and description `<description>`. |
| `/project-name issue show <id>` | Shows the issue with ID `<id>`. |
| `/project-name issue close <id>` | Closes the issue with ID `<id>`. |
| `/project-name issue search <query>` | Shows up to 5 issues matching `<query>`. |
| `/project-name issue move <id> to <project>` | Moves the issue with ID `<id>` to `<project>`. |
| `/project-name issue comment <id> <shift+return> <comment>` | Adds a new comment with comment body `<comment>` to the issue with ID `<id>`. |
| `/project-name deploy <from> to <to>` | [Deploys](#deploy-command) from the `<from>` environment to the `<to>` environment. |
| `/project-name run <job name> <arguments>` | Executes the [ChatOps](../ci/chatops/index.md) job `<job name>` on the default branch. |

## Issue commands

You can create a new issue, display issue details, and search up to 5 issues.

## Deploy command

To deploy to an environment, GitLab tries to find a deployment
manual action in the pipeline.

If there's only one action for a given environment, it is triggered.
If more than one action is defined, GitLab finds an action
name that equals the environment name to deploy to.

The command returns an error if no matching action is found.
