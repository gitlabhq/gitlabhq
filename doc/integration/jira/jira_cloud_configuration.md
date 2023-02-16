---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create a Jira Cloud API token **(FREE)**

You need an API token to [integrate with Jira](index.md)
in Atlassian Cloud. To create the API token:

1. Sign in to [Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)
   using an account with *write* access to Jira projects.

   The link opens the API tokens page. Alternatively, to go to this page from your Atlassian
   profile, select **Account Settings > Security > Create and manage API tokens**.
1. Select **Create API token**.
1. In the dialog, enter a label for your token and select **Create**.
1. To copy the API token, select **Copy**, then paste the token somewhere safe.

You need the newly created token, and the email
address you used when you created it, when you
[configure GitLab](configure.md).
