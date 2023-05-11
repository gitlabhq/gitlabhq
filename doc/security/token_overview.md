---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# GitLab Token overview **(FREE)**

This document lists tokens used in GitLab, their purpose and, where applicable, security guidance.

## Personal access tokens

You can create [Personal access tokens](../user/profile/personal_access_tokens.md) to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of your personal access tokens. By default,
they inherit permissions from the user who created them.

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

## Group access tokens

[Group access tokens](../user/group/settings/group_access_tokens.md#group-access-tokens)
are scoped to a group. As with [Personal access tokens](#personal-access-tokens), you can use them to authenticate with:

- The GitLab API.
- GitLab repositories.
- The GitLab registry.

You can limit the scope and expiration date of group access tokens. When you
create a group access token, GitLab creates a [bot user for groups](../user/group/settings/group_access_tokens.md#bot-users-for-groups).
Bot users for groups are service accounts and do not count as licensed seats.

## Deploy tokens

[Deploy tokens](../user/project/deploy_tokens/index.md) allow you to download (`git clone`) or push and pull packages and container registry images of a project without having a user and a password. Deploy tokens cannot be used with the GitLab API.

Deploy tokens can be managed by project maintainers and owners.

## Deploy keys

[Deploy keys](../user/project/deploy_keys/index.md) allow read-only or read-write access to your repositories by importing an SSH public key into your GitLab instance. Deploy keys cannot be used with the GitLab API or the registry.

This is useful, for example, for cloning repositories to your Continuous Integration (CI) server. By using deploy keys, you don't have to set up a fake user account.

Project maintainers and owners can add or enable a deploy key for a project repository

## Runner registration tokens (deprecated)

WARNING:
The ability to pass a runner registration token has been [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) and is
planned for removal in 17.0, along with support for certain configuration arguments. This change is a breaking change. GitLab plans to introduce a new
[GitLab Runner token architecture](../architecture/blueprints/runner_tokens/index.md), which introduces
a new method for registering runners and eliminates the
runner registration token.

Runner registration tokens are used to [register](https://docs.gitlab.com/runner/register/) a [runner](https://docs.gitlab.com/runner/) with GitLab. Group or project owners or instance administrators can obtain them through the GitLab user interface. The registration token is limited to runner registration and has no further scope.

You can use the runner registration token to add runners that execute jobs in a project or group. The runner has access to the project's code, so be careful when assigning project and group-level permissions.

## Runner authentication tokens (also called runner tokens)

Once created, the runner receives an authentication token, which it uses to authenticate with GitLab when picking up jobs from the job queue. The authentication token is stored locally in the runner's [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) file.

After authentication with GitLab, the runner receives a [job token](../ci/jobs/ci_job_token.md), which it uses to execute the job.

In case of Docker Machine/Kubernetes/VirtualBox/Parallels/SSH executors, the execution environment has no access to the runner authentication token, because it stays on the runner machine. They have access to the job token only, which is needed to execute the job.

Malicious access to a runner's file system may expose the `config.toml` file and thus the authentication token, allowing an attacker to [clone the runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

In GitLab 16.0 and later, you can use an authentication token to register runners instead of a
registration token. Runner registration tokens have been [deprecated](../update/deprecations.md#registration-tokens-and-server-side-runner-arguments-in-gitlab-runner-register-command).

To generate an authentication token, you create a runner in the GitLab UI and use the authentication token
instead of the registration token.

| Process            | Registration command  |
| ------------------ | --------------------- |
| Registration token (deprecated) | `gitlab-runner register --registration-token $RUNNER_REGISTRATION_TOKEN <runner configuration arguments>` |
| Authentication token | `gitlab-runner register --token $RUNNER_AUTHENTICATION_TOKEN` |

## CI/CD job tokens

The [CI/CD](../ci/jobs/ci_job_token.md) job token
is a short lived token only valid for the duration of a job. It gives a CI/CD job
access to a limited amount of API endpoints.
API authentication uses the job token, by using the authorization of the user
triggering the job.

The job token is secured by its short life-time and limited scope. It could possibly be leaked if multiple jobs run on the same machine ([like with the shell runner](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)). On Docker Machine runners, configuring [`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section) is recommended to make sure runner machines only ever run one build and are destroyed afterwards. This may impact performance, as provisioning machines takes some time.

## Other tokens

### Feed token

Each user has a long-lived feed token that does not expire. This token allows authentication for:

- RSS readers to load a personalized RSS feed.
- Calendar applications to load a personalized calendar.

This token is visible in those feed URLs. You cannot use this token to access any other data.

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

## Security considerations

- Access tokens should be treated like passwords and kept secure.
- Adding access tokens to URLs is a security risk, especially when cloning or adding a remote because Git then writes the URL to its `.git/config` file in plain text. URLs are
  also generally logged by proxies and application servers, which makes those credentials visible to system administrators. Instead, pass API calls an access token using
  headers like [the `Private-Token` header](../api/rest/index.md#personalprojectgroup-access-tokens).
- Tokens can also be stored using a [Git credential storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
- Tokens must not be committed to your source code. Instead, consider an approach such as [using external secrets in CI](../ci/secrets/index.md).
- When creating a scoped token, consider using the most limited scope possible to reduce the impact of accidentally leaking the token.
- When creating a token, consider setting a token that expires when your task is complete. For example, if performing a one-off import, set the
  token to expire after a few hours or a day. This reduces the impact of a token that is accidentally leaked because it is useless when it expires.
- Be careful not to include tokens when pasting code, console commands, or log outputs into an issue or MR description or comment.
- Don’t log credentials in the console logs. Consider [protecting](../ci/variables/index.md#protect-a-cicd-variable) and
  [masking](../ci/variables/index.md#mask-a-cicd-variable) your credentials.
- Review all currently active access tokens of all types on a regular basis and revoke any that are no longer needed.
