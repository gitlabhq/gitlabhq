# Chatops on GitLab.com

ChatOps on GitLab.com allows GitLab team members to run various automation tasks on GitLab.com using Slack.

## Requesting access

GitLab team-members may need access to Chatops on GitLab.com for administration
tasks such as:

- Configuring feature flags.
- Running `EXPLAIN` queries against the GitLab.com production replica.

To request access to Chatops on GitLab.com:

1. Log into <https://ops.gitlab.net/users/sign_in> using the same username as for GitLab.com.
1. Ask [anyone in the `chatops` project](https://gitlab.com/gitlab-com/chatops/project_members) to add you by running `/chatops run member add <username> gitlab-com/chatops --ops`.

## See also

 - [Chatops Usage](https://docs.gitlab.com/ee/ci/chatops/README.html)
 - [Understanding EXPLAIN plans](understanding_explain_plans.md)
 - [Feature Groups](feature_flags/development.md#feature-groups)
