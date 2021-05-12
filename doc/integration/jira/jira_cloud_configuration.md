---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Create an API token in Jira on Atlassian cloud **(FREE)**

You need an API token to [integrate with Jira](index.md)
on Atlassian cloud. To create the API token:

1. Sign in to [`id.atlassian.com`](https://id.atlassian.com/manage-profile/security/api-tokens)
   with your email address. Use an account with *write* access to Jira projects.
1. Go to **Settings > API tokens**.
1. Select **Create API token** to display a modal window with an API token.
1. To copy the API token, select **Copy to clipboard**, or select **View** and write
   down the new API token. You need this value when you
   [configure GitLab](development_panel.md#configure-gitlab).

You need the newly created token, and the email
address you used when you created it, when you
[configure GitLab](development_panel.md#configure-gitlab).
