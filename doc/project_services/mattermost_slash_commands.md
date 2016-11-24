# Mattermost slash commands

> Introduced in GitLab 8.14

Mattermost commands give users an extra interface to perform common operations
from the chat environment. This allows one to, for example, create an issue as
soon as the idea was discussed in Mattermost.

## Prerequisites

Mattermost 3.4 and up is required.

If you have the Omnibus GitLab package installed, Mattermost is already bundled
in it. All you have to do is configure it. Read more in the
[Omnibus GitLab Mattermost documentation][omnimmdocs].

## Configuration

The configuration consists of two parts. First you need to enable the slash
commands in Mattermost and then enable the service in GitLab.


### Step 1. Enable custom slash commands in Mattermost

The first thing to do in Mattermost is to enable custom slash commands from
the administrator console.

1. Log in with an account that has admin privileges and navigate to the system
   console.

    ![Mattermost go to console](img/mattermost_goto_console.png)

    ---

1. Click **Custom integrations** and set **Enable Custom Slash Commands** to
   true.

    ![Mattermost console](img/mattermost_console_integrations.png)

    ---

1. Click **Save** at the bottom to save the changes.

### Step 2. Open the Mattermost slash commands service in GitLab

1. Open a new tab for GitLab and go to your project's settings
   **Services ➔ Mattermost command**. A screen will appear with all the values you
   need to copy in Mattermost as described in the next step. Leave the window open.

    >**Note:**
    GitLab will propose some values for the Mattermost settings. The only one
    required to copy-paste as-is is the **Request URL**, all the others are just
    suggestions.

    ![Mattermost setup instructions](img/mattermost_config_help.png)

    ---

1. Proceed to the next step and create a slash command in Mattermost with the
   above values.

### Step 3. Create a new custom slash command in Mattermost

Now that you have enabled the custom slash commands in Mattermost and opened
the Mattermost slash commands service in GitLab, it's time to copy these values
in a new slash command.

1. Back to Mattermost, under your team page settings, you should see the
   **Integrations** option.

    ![Mattermost team integrations](img/mattermost_team_integrations.png)

    ---

1. Go to the **Slash Commands** integration and add a new one by clicking the
   **Add Slash Command** button.

    ![Mattermost add command](img/mattermost_add_slash_command.png)

    ---

1. Fill in the options for the custom command as described in
   [step 2](#step-2-open-the-mattermost-slash-commands-service-in-gitlab).

    >**Note:**
    If you plan on connecting multiple projects, pick a slash command trigger
    word that relates to your projects such as `/gitlab-project-name` or even
    just `/project-name`. Only use `/gitlab` if you will only connect a single
    project to your Mattermost team.

    ![Mattermost add command configuration](img/mattermost_slash_command_configuration.png)

1. After you setup all the values, copy the token (we will use it below) and
   click **Done**.

    ![Mattermost slash command token](img/mattermost_slash_command_token.png)

### Step 4. Copy the Mattermost token into the Mattermost slash command service

1. In GitLab, paste the Mattermost token you copied in the previous step and
   check the **Active** checkbox.

    ![Mattermost copy token to GitLab](img/mattermost_gitlab_token.png)

1. Click **Save changes** for the changes to take effect.

---

You are now set to start using slash commands in Mattermost that talk to the
GitLab project you configured.

## Authorizing Mattermost to interact with GitLab

The first time a user will interact with the newly created slash commands,
Mattermost will trigger an authorization process.

![Mattermost bot authorize](img/mattermost_bot_auth.png)

This will connect your Mattermost user with your GitLab user. You can
see all authorized chat accounts in your profile's page under **Chat**.

When the authorization process is complete, you can start interacting with
GitLab using the Mattermost commands.

## Available slash commands

The available slash commands so far are:

| Command | Description | Example |
| ------- | ----------- | ------- |
| `/<trigger> issue create <title>\n<description>` | Create a new issue in the project that `<trigger>` is tied to. `<description>` is optional. | `/trigger issue create We need to change the homepage` |
| `/<trigger> issue show <issue-number>` | Show the issue with ID `<issue-number>` from the project that `<trigger>` is tied to. | `/trigger issue show 42` |
| `/<trigger> deploy <environment> to <environment>` | Start the CI job that deploys from one environment to another, for example `staging` to `production`. CI/CD must be [properly configured][ciyaml]. | `/trigger deploy staging to production` |

To see a list of available commands that can interact with GitLab, type the
trigger word followed by `help`:

```
/my-project help
```

![Mattermost bot available commands](img/mattermost_bot_available_commands.png)

## Permissions

The permissions to run the [available commands](#available-commands) derive from
the [permissions you have on the project](../user/permissions.md#project).

## Further reading

- [Mattermost slash commands documentation][mmslashdocs]
- [Omnibus GitLab Mattermost][omnimmdocs]


[omnimmdocs]: https://docs.gitlab.com/omnibus/gitlab-mattermost/
[mmslashdocs]: https://docs.mattermost.com/developer/slash-commands.html
[ciyaml]: ../ci/yaml/README.md
