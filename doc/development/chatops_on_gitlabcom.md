# Chatops on GitLab.com

ChatOps on GitLab.com allows GitLab team members to run various automation tasks on GitLab.com using Slack.

## Requesting access

GitLab team-members may need access to Chatops on GitLab.com for administration
tasks such as:

- Configuring feature flags.
- Running `EXPLAIN` queries against the GitLab.com production replica.
- Get deployment status of all of our environments or for a specific commit: `/chatops run auto_deploy status [commit_sha]`

To request access to Chatops on GitLab.com:

1. Log into <https://ops.gitlab.net/users/sign_in> **using the same username** as for GitLab.com (you may have to rename it).
1. Ask in the [#production](https://gitlab.slack.com/messages/production) channel to add you by running `/chatops run member add <username> gitlab-com/chatops --ops`.

## See also

- [Chatops Usage](../ci/chatops/README.md)
- [Understanding EXPLAIN plans](understanding_explain_plans.md)
- [Feature Groups](feature_flags/development.md#feature-groups)
