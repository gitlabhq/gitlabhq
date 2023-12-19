---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Token overview **(FREE ALL)**

This document lists tokens used in GitLab, their purpose and, where applicable, security guidance.

## Personal access tokens

You can create [Personal access tokens](../user/profile/personal_access_tokens.md) to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of your personal access tokens. By default,
they inherit permissions from the user who created them.

You can use the personal access tokens API to programmatically take action,
such as [rotating a personal access token](../api/personal_access_tokens.md#rotate-a-personal-access-token).

You will receive an email when personal access tokens are 7 days or less from expiration.

## OAuth2 tokens

GitLab can serve as an [OAuth2 provider](../api/oauth2.md) to allow other services to access the GitLab API on a user's behalf.

You can limit the scope and lifetime of your OAuth2 tokens.

## Impersonation tokens

An [Impersonation token](../api/rest/index.md#impersonation-tokens) is a special type of personal access
token. It can be created only by an administrator for a specific user. Impersonation tokens can
help you build applications or scripts that authenticate with the GitLab API, repositories, and the GitLab registry as a specific user.

You can limit the scope and set an expiration date for an impersonation token.

## Project access tokens

[Project access tokens](../user/project/settings/project_access_tokens.md#project-access-tokens)
are scoped to a project. As with [Personal access tokens](#personal-access-tokens), you can use them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of project access tokens. When you
create a project access token, GitLab creates a [bot user for projects](../user/project/settings/project_access_tokens.md#bot-users-for-projects).
Bot users for projects are service accounts and do not count as licensed seats.

You can use the [project access tokens API](../api/project_access_tokens.md) to
programmatically take action, such as
[rotating a project access token](../api/project_access_tokens.md#rotate-a-project-access-token).

All project maintainers receive an email when project access tokens are 7 days or less from expiration.

## Group access tokens

[Group access tokens](../user/group/settings/group_access_tokens.md#group-access-tokens)
are scoped to a group. As with [Personal access tokens](#personal-access-tokens), you can use them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of group access tokens. When you
create a group access token, GitLab creates a [bot user for groups](../user/group/settings/group_access_tokens.md#bot-users-for-groups).
Bot users for groups are service accounts and do not count as licensed seats.

You can use the [group access tokens API](../api/group_access_tokens.md) to
programmatically take action, such as
[rotating a group access token](../api/group_access_tokens.md#rotate-a-group-access-token).

All group owners receive an email when group access tokens are 7 days or less from expiration.

## Deploy tokens

[Deploy tokens](../user/project/deploy_tokens/index.md) allow you to download (`git clone`) or push and pull packages and container registry images of a project without having a user and a password. Deploy tokens cannot be used with the GitLab API.

Deploy tokens can be managed by project maintainers and owners.

## Deploy keys

[Deploy keys](../user/project/deploy_keys/index.md) allow read-only or read-write access to your repositories by importing an SSH public key into your GitLab instance. Deploy keys cannot be used with the GitLab API or the registry.

This is useful, for example, for cloning repositories to your Continuous Integration (CI) server. By using deploy keys, you don't have to set up a fake user account.

Project maintainers and owners can add or enable a deploy key for a project repository

## Runner authentication tokens

In GitLab 16.0 and later, to register a runner, you can use a runner authentication token
instead of a runner registration token. Runner registration tokens have
been [deprecated](../ci/runners/new_creation_workflow.md).

After you create a runner and its configuration, you receive a runner authentication token
that you use to register the runner. The runner authentication token is stored locally in the
[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) file, which
you use to configure the runner.

The runner uses the runner authentication token to authenticate with GitLab when
it picks up jobs from the job queue. After the runner authenticates with GitLab,
the runner receives a [job token](../ci/jobs/ci_job_token.md), which it uses to
execute the job.

The runner authentication token stays on the runner machine. The execution environments
for the following executors only have access to the job token and not the runner authentication token:

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

Malicious access to a runner's file system may expose the `config.toml` file and the
runner authentication token. The attacker could use the runner authentication token
to [clone the runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

You can use the `runners` API to
programmatically [rotate or revoke a runner authentication token](../api/runners.md#reset-runners-authentication-token-by-using-the-current-token).

## Runner registration tokens (deprecated)

WARNING:
The ability to pass a runner registration token has been [deprecated](../ci/runners/new_creation_workflow.md) and is
planned for removal in GitLab 18.0, along with support for certain configuration arguments. This change is a breaking change. GitLab has implemented a new
[GitLab Runner token architecture](../ci/runners/new_creation_workflow.md), which introduces
a new method for registering runners and eliminates the
runner registration token.

Runner registration tokens are used to [register](https://docs.gitlab.com/runner/register/) a [runner](https://docs.gitlab.com/runner/) with GitLab. Group or project owners or instance administrators can obtain them through the GitLab user interface. The registration token is limited to runner registration and has no further scope.

You can use the runner registration token to add runners that execute jobs in a project or group. The runner has access to the project's code, so be careful when assigning project and group-level permissions.

## CI/CD job tokens

The [CI/CD](../ci/jobs/ci_job_token.md) job token
is a short lived token only valid for the duration of a job. It gives a CI/CD job
access to a limited amount of API endpoints.
API authentication uses the job token, by using the authorization of the user
triggering the job.

The job token is secured by its short life-time and limited scope. It could possibly be leaked if multiple jobs run on the same machine ([like with the shell runner](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)). On Docker Machine runners, configuring [`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section) is recommended to make sure runner machines only ever run one build and are destroyed afterwards. This may impact performance, as provisioning machines takes some time.

## GitLab cluster agent tokens

When [registering a GitLab Agent for Kubernetes](../user/clusters/agent/install/index.md#register-the-agent-with-gitlab), GitLab generates an access token to authenticate the cluster agent with GitLab.

To revoke this cluster agent token, you can use either the:

- [Agents API](../api/cluster_agents.md#revoke-an-agent-token) to revoke the token.
- [UI](../user/clusters/agent/work_with_agent.md#reset-the-agent-token) to reset the token.

For both methods, you must know the token, agent, and project IDs. To find this information, use the [Rails console](../administration/operations/rails_console.md)

```irb
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

```irb
# Revoke token with RevokeService, including generating an audit event
Clusters::AgentTokens::RevokeService.new(token: Clusters::AgentToken.find_by_token('glagent-xxx'), current_user: User.find_by_username('admin-user')).execute

# Revoke token manually, which does not generate an audit event
Clusters::AgentToken.find_by_token('glagent-xxx').revoke!
```

## Other tokens

### Feed token

Each user has a long-lived feed token that does not expire. This token allows authentication for:

- RSS readers to load a personalized RSS feed.
- Calendar applications to load a personalized calendar.

You cannot use this token to access any other data.

The user-scoped feed token can be used for all feeds, however feed and calendar URLs are generated
with a different token that is only valid for one feed.

Anyone who has your token can read activity and issue RSS feeds or your calendar feed as if they were you, including confidential issues. If that happens, [reset the token](../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token).

### Incoming email token

Each user has a long-lived incoming email token that does not expire. This token allows a user to [create a new issue by email](../user/project/issues/create_issues.md#by-sending-an-email), and is included in that user's personal project-specific email addresses. You cannot use this token to access any other data. Anyone who has your token can create issues and merge requests as if they were you. If that happens, reset the token.

## Available scopes

This table shows available scopes per token. Scopes can be limited further on token creation.

|                             | API access | Registry access | Repository access |
|-----------------------------|------------|-----------------|-------------------|
| Personal access token       | ✅         | ✅              | ✅                |
| OAuth2 token                | ✅         | 🚫              | ✅                |
| Impersonation token         | ✅         | ✅              | ✅                |
| Project access token        | ✅(1)      | ✅(1)           | ✅(1)             |
| Group access token          | ✅(2)      | ✅(2)           | ✅(2)             |
| Deploy token                | 🚫         | ✅              | ✅                |
| Deploy key                  | 🚫         | 🚫              | ✅                |
| Runner registration token   | 🚫         | 🚫              | ✴️(3)              |
| Runner authentication token | 🚫         | 🚫              | ✴️(3)              |
| Job token                   | ✴️(4)       | 🚫              | ✅                |

1. Limited to the one project.
1. Limited to the one group.
1. Runner registration and authentication token don't provide direct access to repositories, but can be used to register and authenticate a new runner that may execute jobs which do have access to the repository
1. Limited to certain [endpoints](../ci/jobs/ci_job_token.md).

## Token prefixes

The following tables show the prefixes for each type of token where applicable.

### GitLab tokens

|            Token name             |      Prefix        |
|-----------------------------------|--------------------|
| Personal access token             | `glpat-`           |
| OAuth Application Secret          | `gloas-`           |
| Impersonation token               | Not applicable.    |
| Project access token              | Not applicable.    |
| Group access token                | Not applicable.    |
| Deploy token                      | `gldt-` ([Added in GitLab 16.7](https://gitlab.com/gitlab-org/gitlab/-/issues/376752)) |
| Deploy key                        | Not applicable.    |
| Runner registration token         | Not applicable.    |
| Runner authentication token       | `glrt-`            |
| Job token                         | Not applicable.    |
| Trigger token                     | `glptt-`           |
| Legacy runner registration token  | GR1348941          |
| Feed token                        | `glft-`            |
| Incoming mail token               | `glimt-`           |
| GitLab Agent for Kubernetes token | `glagent-`         |
| GitLab session cookies            | `_gitlab_session=` |

### External system tokens

|   Token name    |     Prefix      |
|-----------------|-----------------|
| Omamori tokens  | `omamori_pat_`  |
| AWS credentials | `AKIA`          |
| GCP credentials | Not applicable. |

## Security considerations

1. Treat access tokens like passwords and keep them secure.
1. When creating a scoped token, consider using the most limited scope possible to reduce the impact of accidentally leaking the token.
1. When creating a token, consider setting a token that expires when your task is complete. For example, if performing a one-off import, set the
  token to expire after a few hours or a day. This reduces the impact of a token that is accidentally leaked because it is useless when it expires.
1. If you have set up a demo environment to showcase a project you have been working on and you are recording a video or writing a blog post describing that project, make sure you are not leaking sensitive secrets (for example a personal access token (PAT), feed token or trigger token) during that process. If you have finished the demo, you must revoke all the secrets created during that demo. For more information, see [revoking a PAT](../user/profile/personal_access_tokens.md#revoke-a-personal-access-token).
1. Adding access tokens to URLs is a security risk, especially when cloning or adding a remote because Git then writes the URL to its `.git/config` file in plain text. URLs are
  also generally logged by proxies and application servers, which makes those credentials visible to system administrators. Instead, pass API calls an access token using
  headers like [the `Private-Token` header](../api/rest/index.md#personalprojectgroup-access-tokens).
1. You can also store token using a [Git credential storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
1. Do not:
   - Store tokens in plain text in your projects.
   - Include tokens when pasting code, console commands, or log outputs into an issue, MR description, or comment.
   Consider an approach such as [using external secrets in CI](../ci/secrets/index.md).
1. Do not log credentials in the console logs or artifacts. Consider [protecting](../ci/variables/index.md#protect-a-cicd-variable) and
  [masking](../ci/variables/index.md#mask-a-cicd-variable) your credentials.
1. Review all active access tokens of all types on a regular basis and revoke any that are no longer needed. This includes:
   - Personal, project, and group access tokens.
   - Feed tokens.
   - Trigger tokens.
   - Runner registration tokens.
   - Any other sensitive secrets etc.
