---
stage: Deploy
group: Environments
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: ChatOps on GitLab.com
---

ChatOps on GitLab.com allows GitLab team members to run various automation tasks on GitLab.com using Slack.

## Requesting access

GitLab team-members may need access to ChatOps on GitLab.com for administration
tasks such as:

- Configuring feature flags.
- Running `EXPLAIN` queries against the GitLab.com production replica.
- Get deployment status of all of our environments or for a specific commit: `/chatops run auto_deploy status [commit_sha]`

To request access to ChatOps on GitLab.com:

1. Sign in to [Internal GitLab for Operations](https://ops.gitlab.net/users/sign_in)
   with one of the following methods (Okta is not supported):

   - The same username you use on GitLab.com.
   - Selecting the **Sign in with Google** button to sign in with your GitLab.com email address.

1. Confirm that your username in [Internal GitLab for Operations](https://ops.gitlab.net/)
   is the same as your username in [GitLab.com](https://gitlab.com). If the usernames
   don't match, update the username in [User Settings/Account for the Ops instance](https://ops.gitlab.net/-/profile/account). Matching usernames are required to reduce the administrative effort of running multiple platforms. Matching usernames also help with tasks like managing access requests and offboarding.

1. Comment in your onboarding issue, and tag your onboarding buddy and your manager.
   Request they add you to the `ops` ChatOps project by running this command
   in the `#chat-ops-test` Slack channel, replacing `<username>` with your GitLab.com username:
   `/chatops run member add <username> gitlab-com/chatops --ops`

   ```plaintext
   Hi <__BUDDY_HANDLE__> and <__MANAGER_HANDLE__>, could you please add me to
   the ChatOps project in Ops by running this command:
   `/chatops run member add <username> gitlab-com/chatops --ops` in the
   `#chat-ops-test` Slack channel? Thanks in advance.
   ```

1. Ensure you've set up two-factor authentication.
1. After you're added to the ChatOps project, run this command to check your user
   status and ensure you can execute commands in the `#chat-ops-test` Slack channel:

   ```plaintext
   /chatops run user find <username>
   ```

   The bot guides you through the process of allowing your user to execute
   commands in the `#chat-ops-test` Slack channel.

1. If you had to change your username for GitLab.com on the first step, make sure
   [to reflect this information](https://gitlab.com/gitlab-com/www-gitlab-com#adding-yourself-to-the-team-page)
   on [the team page](https://about.gitlab.com/company/team/).

## See also

- [ChatOps Usage](../ci/chatops/_index.md)
- [Feature Flag Controls](feature_flags/controls.md)
- [Understanding EXPLAIN plans](database/understanding_explain_plans.md)
- [Feature Groups](feature_flags/_index.md#feature-groups)
