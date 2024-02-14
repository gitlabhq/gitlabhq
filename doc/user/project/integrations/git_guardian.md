---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitGuardian

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435706) in GitLab 16.9 [with a flag](../../../administration/feature_flags.md) named `git_guardian_integration`. Enabled by default. Disabled on GitLab.com.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../../../administration/feature_flags.md) named `git_guardian_integration`.
On GitLab.com, this feature is not available.

WARNING:
Pushes can be delayed or can time out. With the GitGuardian integration, pushes are sent to a third-party, and GitLab has no control over the connection with GitGuardian or the GitGuardian process.

[GitGuardian](https://www.gitguardian.com/) is a cybersecurity service that detects sensitive data such as API keys
and passwords in source code repositories.
It scans Git repositories, alerts on policy violations, and helps organizations
fix security issues before hackers can exploit them.

You can configure GitLab to reject commits based on GitGuardian policies.

To set up the GitGuardian integration:

1. [Create a GitGuardian API token](#create-a-gitguardian-api-token).
1. [Set up the GitGuardian integration for your project](#set-up-the-gitguardian-integration-for-your-project).

## Create a GitGuardian API token

Prerequisites:

- You must have a GitGuardian account.

To create an API token:

1. Sign in to your GitGuardian account.
1. Go to the **API** section in the sidebar.
1. In the API section sidebar go to **Personal access tokens** page.
1. Select **Create token**. The token creation dialog opens.
1. Provide your token information:
    - Give your API token a meaningful name to identify its purpose.
      For example, `GitLab integration token`.
    - Select an appropriate expiration.
    - Select the **scan scope** checkbox.
      It is the only one needed for the integration.
1. Select **Create token**.
1. After you've generated a token, copy it to your clipboard.
   This token is sensitive information, so keep it secure.

Now you have successfully created a GitGuardian API token that you can use to for our integration.

## Set up the GitGuardian integration for your project

Prerequisites:

- You must have at least the Maintainer role for the project.

After you have created and copied your API token, configure GitLab to reject commits:

To enable the integration for your project:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Integrations**.
1. Select **GitGuardian**.
1. In **Enable integration**, select the **Active** checkbox.
1. In **API token**, [paste the token value from GitGuardian](#create-a-gitguardian-api-token).
1. Optional. Select **Test settings**.
1. Select **Save changes**.

GitLab is now ready to reject commits based on GitGuardian policies.
