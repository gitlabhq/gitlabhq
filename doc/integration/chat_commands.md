# Chat Commands

Chat commands in Mattermost and Slack (also called Slack slash commands) allow you to control GitLab and view GitLab content right inside your chat client, without having to leave it. For Slack, this requires a [project service configuration](../user/project/integrations/slack_slash_commands.md). Simply type the command as a message in your chat client to activate it. 

Commands are scoped to a project, with a trigger term that is specified during configuration. (We suggest you use the project name as the trigger term for simplicty and clarity.) Taking the trigger term as `project-name`, the commands are:


| Command | Effect |
| ------- | ------ |
| `/project-name help` | Shows all available chat commands |
| `/project-name issue new <title> <shift+return> <description>` | Creates a new issue with title `<title>` and description `<description>` |
| `/project-name issue show <id>` | Shows the issue with id `<id>` |
| `/project-name issue search <query>` | Shows up to 5 issues matching `<query>` |
| `/project-name deploy <from> to <to>` | Deploy from the `<from>` environment to the `<to>` environment |