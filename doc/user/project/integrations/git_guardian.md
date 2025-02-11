---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Integrate GitLab with GitGuardian to get alerts for policy violations and security issues before they can be exploited."
title: GitGuardian
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435706) in GitLab 16.9 [with a flag](../../../administration/feature_flags.md) named `git_guardian_integration`. Enabled by default. Disabled on GitLab.com.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/438695#note_2226917025) in GitLab 17.7.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176391) in GitLab 17.8. Feature flag `git_guardian_integration` removed.

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

## Skip secret detection

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152064) in GitLab 17.0.

You can skip GitGuardian secret detection, if needed. The options to skip
secret detection for all commits in a push are identical to the options for
[Native Secret Detection](../../application_security/secret_detection/secret_push_protection/_index.md#skip-secret-push-protection). Either:

- Add `[skip secret push protection]` to one of the commit messages.
- Use the `secret_push_protection.skip_all` [push option](../../../topics/git/commit.md#push-options-for-gitguardian-integration).

## Known issues

- Pushes can be delayed or can time out. With the GitGuardian integration:
  - Pushes are sent to a third-party.
  - GitLab has no control over the connection with GitGuardian or the GitGuardian process.
- Due to a [GitGuardian API limitation](https://api.gitguardian.com/docs#operation/multiple_scan), the integration ignores files over the size of 1 MB. They are not scanned.
- If a pushed file has a name over 256 characters, the push fails.
- For more information, see [GitGuardian API documentation](https://api.gitguardian.com/docs#operation/multiple_scan).

Troubleshooting steps below show how to mitigate some of these problems.

## Troubleshooting

When working with the GitGuardian integration, you might encounter the following issues.

### `500` HTTP errors

You might get an HTTP `500` error.

This issue occurs for when requests time out for commits with a lot of changed files.

If this issue happens when you change more than 50 files in a commit:

1. Split your changes into smaller commits.
1. Push the smaller commits one by one.

### Error: `Filename: ensure this value has at most 256 characters`

You might get an HTTP `400` error that states `Filename: ensure this value has at most 256 characters`.

This issue occurs when some of the changed files you are pushing in that commit have the filename (not the path) longer then 256 characters.

The workaround is to shorten the filename if possible.
For example, if the filename cannot be shortened because it was automatically
generated by a framework, disable the integration and try to push again.
Don't forget to re-enable the integration afterwards if needed.
