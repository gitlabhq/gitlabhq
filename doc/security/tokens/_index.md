---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab token overview
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This document lists tokens used in GitLab, their purpose and, where
applicable, security guidance.

## Security considerations

To keep your tokens secure:

- Treat tokens like passwords and keep them secure.
- When creating a scoped token, use the most limited scope possible to reduce the impact of an accidentally leaked token.
  - If separate processes require different scopes (for example, `read` and `write`), consider using separate tokens, one for each scope. If one token leaks, it gives reduced access than a single token with a wide scope like full API access.
- When creating a token, consider setting a token that expires when your task is complete. For example, if you need to perform a one-time import, set the token to expire after a few hours.
- If you set up a demo environment to showcase a project you have been working on, and you record a video or write a blog post describing that project, make sure you don't accidentally leak a secret.
  After the demo is finished, revoke all the secrets created during the demo.
- Adding tokens to URLs can be a security risk. Instead, pass the token with a header like [`Private-Token`](../../api/rest/authentication.md#personalprojectgroup-access-tokens).
  - When cloning or adding a remote with a token in the URL, Git writes the URL to its `.git/config` file in plaintext.
  - URLs are often logged by proxies and application servers, which could leak those credentials to system administrators.
- You can store tokens using [Git credential storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
- Review all active access tokens of all types on a regular basis and revoke any you don't need.

Do not:

- Store tokens in plaintext in your projects. If the token is an external secret for GitLab CI/CD,
  review how to [use external secrets in CI/CD](../../ci/secrets/_index.md) recommendations.
- Include tokens when pasting code, console commands, or log outputs into an issue, MR description, comment, or any other free text inputs.
- Log credentials in the console logs or artifacts. Consider [protecting](../../ci/variables/_index.md#protect-a-cicd-variable) and
  [masking](../../ci/variables/_index.md#mask-a-cicd-variable) your credentials.

### Tokens in CI/CD

Avoid using personal access tokens as CI/CD variables wherever possible due to their wide scope.
If access to other resources is required from a CI/CD job, use one of the following, ordered by least to most access scope:

1. Job tokens (lowest access scope)
1. Project tokens
1. Group tokens

Additional recommendations for [CI/CD variable security](../../ci/variables/_index.md#cicd-variable-security) include:

- Use [secrets storage](../../ci/pipelines/pipeline_security.md#secrets-storage) for any credentials.
- CI/CD variable containing sensitive information should be [protected](../../ci/variables/_index.md#protect-a-cicd-variable),
  [masked](../../ci/variables/_index.md#mask-a-cicd-variable), and [hidden](../../ci/variables/_index.md#hide-a-cicd-variable).

## Personal access tokens

You can create [personal access tokens](../../user/profile/personal_access_tokens.md)
to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of your personal access tokens.
By default, they inherit permissions from the user who created them.

You can use the personal access tokens API to programmatically take action,
such as [rotating a personal access token](../../api/personal_access_tokens.md#rotate-a-personal-access-token).

You
[receive an email](../../user/profile/personal_access_tokens.md#personal-access-token-expiry-emails)
when your personal access tokens are expiring soon.

When considering a CI/CD job that requires tokens for permissions, avoid using personal access tokens, especially if stored as a CI/CD variable.
CI/CD job tokens and project access tokens can often achieve the same result with much less risk.

## OAuth 2.0 tokens

GitLab can serve as an [OAuth 2.0 provider](../../api/oauth2.md) to
allow other services to access the GitLab API on a user's behalf.

You can limit the scope and lifetime of your OAuth 2.0 tokens.

## Impersonation tokens

An [impersonation token](../../api/rest/authentication.md#impersonation-tokens)
is a special type of personal access token. It can be created only by
an administrator for a specific user. Impersonation tokens can help
you build applications or scripts that authenticate with the GitLab
API, repositories, and the GitLab registry as a specific user.

You can limit the scope and set an expiration date for an
impersonation token.

## Project access tokens

[Project access tokens](../../user/project/settings/project_access_tokens.md)
are scoped to a project. Like personal access tokens, you can use
them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of project access tokens.
When you create a project access token, GitLab creates a
[bot user for projects](../../user/project/settings/project_access_tokens.md#bot-users-for-projects).
Bot users for projects are service accounts and do not count as
licensed seats.

You can use the [project access tokens API](../../api/project_access_tokens.md) to programmatically take
action, such as [rotating a project access token](../../api/project_access_tokens.md#rotate-a-project-access-token).

Members of a project with at least the Maintainer role
[receive an email](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails)
when project access tokens are nearly expired.

## Group access tokens

[Group access tokens](../../user/group/settings/group_access_tokens.md)
are scoped to a group. Like personal access tokens, you can use
them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of group access tokens.
When you create a group access token, GitLab creates a
[bot user for groups](../../user/group/settings/group_access_tokens.md#bot-users-for-groups).
Bot users for groups are service accounts and do not count as licensed seats.

You can use the [group access tokens API](../../api/group_access_tokens.md) to programmatically take
action, such as [rotating a group access token](../../api/group_access_tokens.md#rotate-a-group-access-token).

Members of a group with the Owner role
[receive an email](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails)
when group access tokens are nearly expired.

## Deploy tokens

[Deploy tokens](../../user/project/deploy_tokens/_index.md) allow you
to clone, push, and pull packages and container registry images of a
project without a user and a password. Deploy tokens cannot be used
with the GitLab API.

To manage deploy tokens, you must be a member of a project with at least
the Maintainer role.

## Deploy keys

[Deploy keys](../../user/project/deploy_keys/_index.md) allow read-only
or read-write access to your repositories by importing an SSH public key
into your GitLab instance. Deploy keys cannot be used with the
GitLab API or the registry.

You can use deploy keys to clone repositories to your continuous integration
server without setting up a fake user account.

To add or enable a deploy key for a project, you must have at least
the Maintainer role.

## Runner authentication tokens

In GitLab 16.0 and later, to register a runner, you can use a runner authentication token
instead of a runner registration token. Runner registration tokens are
[deprecated](../../ci/runners/new_creation_workflow.md).

After you create a runner and its configuration, you receive a runner authentication token
that you use to register the runner. The runner authentication token is stored locally in
the [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) file,
which you use to configure the runner.

The runner uses the runner authentication token to authenticate with GitLab when it
picks up jobs from the job queue. After the runner authenticates with GitLab, the runner receives
a [job token](../../ci/jobs/ci_job_token.md), which it uses to execute the job.

The runner authentication token stays on the runner machine. The execution environments
for the following executors have access to only the job token and not the runner authentication token:

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

Malicious access to a runner's file system might expose the
`config.toml` file and the runner authentication token. The attacker
could use the runner authentication token to
[clone the runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

You can use the runners API to [rotate or revoke a runner authentication token](../../api/runners.md#reset-runners-authentication-token-by-using-the-current-token).

## Runner registration tokens (deprecated)

WARNING:
The ability to pass a runner registration token has been [deprecated](../../ci/runners/new_creation_workflow.md) and is
planned for removal in GitLab 18.0, along with support for certain configuration arguments. This change is a breaking change. GitLab has implemented a new
[GitLab Runner token architecture](../../ci/runners/new_creation_workflow.md), which introduces
a new method for registering runners and eliminates the
runner registration token.

Runner registration tokens are used to
[register](https://docs.gitlab.com/runner/register/) a
[runner](https://docs.gitlab.com/runner/) with GitLab. Group or
project owners or instance administrators can obtain them through the
GitLab user interface. The registration token is limited to runner
registration and has no further scope.

You can use the runner registration token to add runners that execute
jobs in a project or group. The runner has access to the project's
code, so be careful when assigning permissions to projects or groups.

## CI/CD job tokens

The [CI/CD](../../ci/jobs/ci_job_token.md) job token is a short-lived token valid only for
the duration of a job. It gives a CI/CD job access to a limited number of API endpoints.
API authentication uses the job token by using the authorization of the user triggering the job.

The job token is secured by its short lifetime and limited scope. This token could be leaked if
multiple jobs run on the same machine (for example, with the [shell runner](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)). You can use the [project allow list](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) to further limit what the job token can access.
On Docker Machine runners, you should configure
[`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section)
to ensure runner machines run only one build
and are destroyed afterwards. Provisioning takes time,
so this configuration can affect performance.

## GitLab cluster agent tokens

When you [register a GitLab agent for Kubernetes](../../user/clusters/agent/install/_index.md#register-the-agent-with-gitlab), GitLab generates an access token to authenticate the cluster agent with GitLab.

To revoke this cluster agent token, you can either:

- Revoke the token with the [agents API](../../api/cluster_agents.md#revoke-an-agent-token).
- [Reset the token](../../user/clusters/agent/work_with_agent.md#reset-the-agent-token).

For both methods, you must know the token, agent, and project IDs. To
find this information, use the [Rails console](../../administration/operations/rails_console.md):

```ruby
# Find token ID
Clusters::AgentToken.find_by_token('glagent-xxx').id

# Find agent ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.id
=> 1234

# Find project ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.project_id
=> 12345
```

You can also revoke a token directly in the Rails console:

```ruby
# Revoke token with RevokeService, including generating an audit event
Clusters::AgentTokens::RevokeService.new(token: Clusters::AgentToken.find_by_token('glagent-xxx'), current_user: User.find_by_username('admin-user')).execute

# Revoke token manually, which does not generate an audit event
Clusters::AgentToken.find_by_token('glagent-xxx').revoke!
```

## Other tokens

### Feed token

Each user has a long-lived feed token that does not expire.
Use this token to authenticate with:

- RSS readers, to load a personalized RSS feed.
- Calendar applications, to load a personalized calendar.

You cannot use this token to access any other data.

You can use the user-scoped feed token for all feeds. However, feed
and calendar URLs are generated with a different token valid for only
one feed.

Anyone who has your token can view your feed activity, including
confidential issues, as if they were you. If you think your token
has leaked, [reset the token](../../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token)
immediately.

#### Disable a feed token

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Under **Feed token**, select the **Disable feed token** checkbox, then select **Save changes**.

### Incoming email token

Each user has an incoming email token that does not expire. The token
is included in email addresses associated with a personal project.
You use this token to [create a new issue by email](../../user/project/issues/create_issues.md#by-sending-an-email).

You cannot use this token to access any other data. Anyone who has
your token can create issues and merge requests as if they were
you. If you think your token has leaked, reset the token immediately.

## Available scopes

This table shows default scopes per token. For some tokens, you can limit scopes further when you create the token.

| Token name                  | API access                         | Registry access                    | Repository access |
|-----------------------------|------------------------------------|------------------------------------|-------------------|
| Personal access token       | **{check-circle}** Yes             | **{check-circle}** Yes             | **{check-circle}** Yes |
| OAuth 2.0 token             | **{check-circle}** Yes             | **{dotted-circle}** No             | **{check-circle}** Yes |
| Impersonation token         | **{check-circle}** Yes             | **{check-circle}** Yes             | **{check-circle}** Yes |
| Project access token        | **{check-circle}** Yes<sup>1</sup> | **{check-circle}** Yes<sup>1</sup> | **{check-circle}** Yes<sup>1</sup> |
| Group access token          | **{check-circle}** Yes<sup>2</sup> | **{check-circle}** Yes<sup>2</sup> | **{check-circle}** Yes<sup>2</sup> |
| Deploy token                | **{dotted-circle}** No             | **{check-circle}** Yes             | **{check-circle}** Yes |
| Deploy key                  | **{dotted-circle}** No             | **{dotted-circle}** No             | **{check-circle}** Yes |
| Runner registration token   | **{dotted-circle}** No             | **{dotted-circle}** No             | **{check-circle-dashed}** Limited<sup>3</sup> |
| Runner authentication token | **{dotted-circle}** No             | **{dotted-circle}** No             | **{check-circle-dashed}** Limited<sup>3</sup> |
| Job token                   | **{check-circle-dashed}** Limited<sup>4</sup> | **{dotted-circle}** No  | **{check-circle}** Yes |

**Footnotes:**

1. Limited to the one project.
1. Limited to the one group.
1. Runner registration and authentication tokens don't provide direct access
   to repositories, but can be used to register and authenticate new runners
   that can execute jobs which do have access to repositories.
1. Only [certain endpoints](../../ci/jobs/ci_job_token.md).

## Token prefixes

The following table shows the prefixes for each type of token.

|            Token name             |      Prefix        |
|-----------------------------------|--------------------|
| Personal access token             | `glpat-`           |
| OAuth Application Secret          | `gloas-`           |
| Impersonation token               | `glpat-`           |
| Project access token              | `glpat-`           |
| Group access token                | `glpat-`           |
| Deploy token                      | `gldt-` ([Added in GitLab 16.7](https://gitlab.com/gitlab-org/gitlab/-/issues/376752)) |
| Runner authentication token       | `glrt-`            |
| CI/CD Job token                   | `glcbt-` <br /> &bull; ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426137) in GitLab 16.8 behind a feature flag named `prefix_ci_build_tokens`. Disabled by default.) <br /> &bull; ([Generally available](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17299) in GitLab 16.9. Feature flag `prefix_ci_build_tokens` removed.) |
| Trigger token                     | `glptt-`           |
| Feed token                        | `glft-`            |
| Incoming mail token               | `glimt-`           |
| GitLab agent for Kubernetes token | `glagent-`         |
| GitLab session cookies            | `_gitlab_session=` |
| SCIM Tokens                       | `glsoat-` <br /> &bull; ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435096) in GitLab 16.8 behind a feature flag named `prefix_scim_tokens`. Disabled by default.) <br > &bull; ([Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435423) in GitLab 16.9. Feature flag `prefix_scim_tokens` removed.) |
| Feature Flags Client token        | `glffct-`          |
