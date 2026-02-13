---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Flow execution variables
---

Not all variables are available in the jobs that execute flows.

- Some predefined and Agent Platform-specific variables are available.
- Predefined filtered variables, custom CI/CD variables, and user identity variables are not available.

## Available variables

The following variables are available to use in the jobs that execute your flows.

### Predefined variables

The following predefined CI/CD variables are available:

| Variable | Description |
|----------|-------------|
| `CI_PROJECT_ID` | Project ID. |
| `CI_PROJECT_NAME` | Project name. |
| `CI_PROJECT_PATH` | Project path with namespace. |
| `CI_PROJECT_URL` | Project HTTP URL. |
| `CI_PROJECT_NAMESPACE` | Project namespace. |
| `CI_PROJECT_VISIBILITY` | Project visibility (`public`, `internal`, or `private`). |
| `CI_DEFAULT_BRANCH` | Default branch name. |
| `CI_JOB_ID` | Job ID. |
| `CI_JOB_URL` | Job URL. |
| `CI_JOB_TOKEN` | Job authentication token. |
| `CI_JOB_IMAGE` | Docker image used for the job. |
| `CI_JOB_STATUS` | Job status. |
| `CI_JOB_TIMEOUT` | Job timeout in seconds. |
| `CI_JOB_STARTED_AT` | Job start timestamp in ISO 8601 format. |
| `CI_PIPELINE_ID` | Pipeline ID. |
| `CI_PIPELINE_URL` | Pipeline URL. |
| `CI_REGISTRY_USER` | Container registry username (`gitlab-ci-token`). |
| `CI_REGISTRY_PASSWORD` | Container registry password (job token). |
| `CI_DEPENDENCY_PROXY_USER` | Dependency proxy username. |
| `CI_DEPENDENCY_PROXY_PASSWORD` | Dependency proxy password. |
| `CI_REPOSITORY_URL` | Git clone URL with embedded credentials. |
| `CI_RUNNER_VERSION` | Runner version. |
| `CI_RUNNER_EXECUTABLE_ARCH` | Runner architecture (for example, `linux/amd64`). |
| `CI_SERVER` | Always `yes` in CI/CD environments. |
| `CI_WORKLOAD_REF` | Workload reference for the flow execution (for example, `refs/workloads/c727f70ba7f`). This is not a Git branch and cannot be used for Git operations. |

### Environment variables

The following environment variables are specific to the Agent Platform.
These variables are available in both `setup_script` and the main agent runtime.

This table documents the key variables. Additional internal variables
(for example, debug flags and telemetry identifiers) may also be present
in the execution container but are not intended for use in flow configuration.

| Variable | Description | Example |
|----------|-------------|---------|
| `DUO_WORKFLOW_GIT_HTTP_BASE_URL` | GitLab instance base URL. Use this instead of `CI_SERVER_URL`. | `https://gitlab.com` |
| `DUO_WORKFLOW_PROJECT_ID` | Project ID. Same value as `CI_PROJECT_ID`. | `77056053` |
| `DUO_WORKFLOW_NAMESPACE_ID` | Namespace ID. | `91555435` |
| `DUO_WORKFLOW_GOAL` | URL of the issue that triggered the flow. | `https://gitlab.com/group/project/-/issues/10` |
| `DUO_WORKFLOW_DEFINITION` | Flow definition identifier. | `developer/v1` |
| `DUO_WORKFLOW_SERVICE_REALM` | Deployment type. | `saas` or `self-managed` |
| `DUO_WORKFLOW_GIT_HTTP_USER` | Git HTTP username for cloning. | `oauth` |
| `DUO_WORKFLOW_GIT_HTTP_PASSWORD` | Git HTTP password for cloning. | *(OAuth token)* |
| `DUO_WORKFLOW_GIT_USER_NAME` | Name of the user who triggered the flow. Used as the Git committer. | `Jane Developer` |
| `DUO_WORKFLOW_GIT_USER_EMAIL` | Email of the user who triggered the flow. Used as the Git committer email. | `jdeveloper@example.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_EMAIL` | Email of the service account. Used as the Git author email. | `service_account_group_<ID>@noreply.gitlab.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME` | Name of the service account. Used as the Git author name. | `Duo Developer` |
| `GITLAB_BASE_URL` | GitLab instance base URL. Same value as `DUO_WORKFLOW_GIT_HTTP_BASE_URL`. | `https://gitlab.com` |
| `GITLAB_PROJECT_PATH` | Project full path with namespace. Same value as `CI_PROJECT_PATH`. | `my-group/my-project` |
| `GITLAB_TOKEN` | OAuth token for GitLab API access. Same value as `DUO_WORKFLOW_GIT_HTTP_PASSWORD`. | *(OAuth token)* |
| `AGENT_PLATFORM_GITLAB_VERSION` | GitLab version running the flow. | `18.9.0` |

## Not available

The following variables are not available in the jobs that execute your flows.

### Filtered predefined variables

The following predefined CI/CD variables are not available:

| Variable | Reason |
|----------|--------|
| `CI_REGISTRY` | Filtered by the workload variable gate. Use a hardcoded registry hostname instead. |
| `CI_REGISTRY_IMAGE` | Filtered by the workload variable gate. Use a hardcoded image path instead. |
| `CI_SERVER_URL`, `CI_SERVER_HOST`, `CI_API_V4_URL` | Filtered. Use `GITLAB_BASE_URL` or `DUO_WORKFLOW_GIT_HTTP_BASE_URL` instead. |
| `CI_COMMIT_SHA`, `CI_COMMIT_BRANCH`, `CI_COMMIT_REF_NAME` | The job has no commit context. The source branch is managed by the GitLab Duo agent. |
| `GITLAB_USER_LOGIN`, `GITLAB_USER_EMAIL`, `GITLAB_USER_NAME` | The job runs as a service account, not as the triggering user. |
| `CI_PIPELINE_SOURCE`, `CI_PIPELINE_IID` | Filtered by the workload variable gate. |

### User identity

The CI job token used during flow execution is a
[composite identity](../composite_identity.md)
token that represents both the triggering user and the service account.

Git commits created during flow execution are committed by the user
who triggered the flow but marked as authored by the service account.

Because a service account is executing the flow, not a user, the
`GITLAB_USER_LOGIN` and `GITLAB_USER_EMAIL` variables are not available.

However, the identity of the user who triggered the flow is available in
`DUO_WORKFLOW_GIT_USER_EMAIL` and `DUO_WORKFLOW_GIT_USER_NAME`,
and the service account identity is available in
`DUO_WORKFLOW_GIT_AUTHOR_EMAIL` and `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME`.

### Custom CI/CD variables

Custom CI/CD variables defined in **Settings > CI/CD > Variables**
for projects, groups, or the instance are not available.

Custom CI/CD variables include protected variables, unprotected variables, masked variables, and file variables.

All flow configuration must be provided in `agent-config.yml` or through the
[available environment variables](#environment-variables).

## Accessing the GitLab instance URL

The standard `CI_SERVER_URL` variable is not available. Use
`GITLAB_BASE_URL` or `DUO_WORKFLOW_GIT_HTTP_BASE_URL` instead.

For example, to make an API call in `setup_script`:

```yaml
setup_script:
  - "curl --silent --header 'JOB-TOKEN: ${CI_JOB_TOKEN}' ${GITLAB_BASE_URL}/api/v4/projects/${CI_PROJECT_ID}"
```
