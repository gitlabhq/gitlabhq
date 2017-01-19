# Chat Commands

Chat commands allow user to perform common operations on GitLab right from there chat client.
Right now both Mattermost and Slack are supported.

## Available commands

The trigger is configurable, but for the sake of this example, we'll use `/trigger`

* `/trigger help` - Displays all available commands for this user
* `/trigger issue new <title> <shift+return> <description>` - creates a new issue on the project
* `/trigger issue show <id>` - Shows the issue with the given ID, if you've got access
* `/trigger issue search <query>` - Shows a maximum of 5 items matching the query
* `/trigger deploy <from> to <to>` - Deploy from an environment to another
