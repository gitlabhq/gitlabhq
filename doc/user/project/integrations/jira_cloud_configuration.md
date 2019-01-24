# Creating an API token in JIRA cloud

An API token is needed when integrating with JIRA Cloud, follow the steps
below to create one:

1. Log in to <https://id.atlassian.com> with your email.
1. **Click API tokens**, then **Create API token**.

![JIRA API token](img/jira_api_token_menu.png)

![JIRA API token](img/jira_api_token.png)

1. Make sure to write down your new API token as you will need it in the next [steps](jira.md#configuring-gitlab).

NOTE: **Note**
It is important that the user associated with this email has 'write' access to projects in JIRA.

The JIRA configuration is complete. You are going to need this new created token and the email you used to log in when [configuring GitLab in the next section](jira.md#configuring-gitlab).
