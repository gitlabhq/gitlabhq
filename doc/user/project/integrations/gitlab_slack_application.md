# Slack application (only available on GitLab.com)

Since GitLab 9.4 you can install GitLab.com Slack application to get [slash commands](https://docs.gitlab.com/ce/integration/slash_commands.html) working.
The only difference is that all the commands should be prefixed with `/gitlab` keyword:

```
# Show the issue #1001
/gitlab gitlab-org/gitlab-ce issue show 1001
```

To install GitLab application to your Slack team you need to go to
`Project Settings > Integration > Slack application` page and press "Add to Slack" button.
Keep in mind that you have to have appropriate permissions for that team to be able to
install a new application, see details in [Add an app to your team](https://get.slack.help/hc/en-us/articles/202035138-Adding-apps-to-your-team).
After confirming installation you, and everyone else in your Slack team, can use all the commands.
When you perform your first slash command you will be asked to authorize your Slack user
inside GitLab.com.
