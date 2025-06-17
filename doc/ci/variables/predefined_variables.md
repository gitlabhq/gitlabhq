---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Predefined CI/CD variables reference
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Predefined [CI/CD variables](_index.md) are available in every GitLab CI/CD pipeline.

Avoid [overriding](_index.md#use-pipeline-variables) predefined variables,
as it can cause the pipeline to behave unexpectedly.

## Variable availability

Predefined variables become available at three different phases of pipeline execution:

- Pre-pipeline: Pre-pipeline variables are available before the pipeline is created.
  These variables are the only variables that can be used with [`include:rules`](../yaml/_index.md#includerules)
  to control which configuration files to use when creating the pipeline.
- Pipeline: Pipeline variables become available when GitLab is creating the pipeline.
  Along with pre-pipeline variables, pipeline variables can be used to configure
  [`rules`](../yaml/_index.md#rules) defined in jobs, to determine which jobs to add to the pipeline.
- Job-only: These variables are only made available to each job when a runner picks
  up the job and runs it, and:
  - Can be used in job scripts.
  - Cannot be used with [trigger jobs](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
  - Cannot be used with [`workflow`](../yaml/_index.md#workflow), [`include`](../yaml/_index.md#include)
    or [`rules`](../yaml/_index.md#rules).

## Predefined variables

| Variable                                        | Availability | Description |
|-------------------------------------------------|--------------|-------------|
| `CHAT_CHANNEL`                                  | Pipeline     | The Source chat channel that triggered the [ChatOps](../chatops/_index.md) command. |
| `CHAT_INPUT`                                    | Pipeline     | The additional arguments passed with the [ChatOps](../chatops/_index.md) command. |
| `CHAT_USER_ID`                                  | Pipeline     | The chat service's user ID of the user who triggered the [ChatOps](../chatops/_index.md) command. |
| `CI`                                            | Pre-pipeline | Available for all jobs executed in CI/CD. `true` when available. |
| `CI_API_V4_URL`                                 | Pre-pipeline | The GitLab API v4 root URL. |
| `CI_API_GRAPHQL_URL`                            | Pre-pipeline | The GitLab API GraphQL root URL. Introduced in GitLab 15.11. |
| `CI_BUILDS_DIR`                                 | Job-only     | The top-level directory where builds are executed. |
| `CI_COMMIT_AUTHOR`                              | Pre-pipeline | The author of the commit in `Name <email>` format. |
| `CI_COMMIT_BEFORE_SHA`                          | Pre-pipeline | The previous latest commit present on a branch or tag. Is always `0000000000000000000000000000000000000000` for merge request pipelines, scheduled pipelines, the first commit in pipelines for branches or tags, or when manually running a pipeline. |
| `CI_COMMIT_BRANCH`                              | Pre-pipeline | The commit branch name. Available in branch pipelines, including pipelines for the default branch. Not available in merge request pipelines or tag pipelines. |
| `CI_COMMIT_DESCRIPTION`                         | Pre-pipeline | The description of the commit. If the title is shorter than 100 characters, the message without the first line. |
| `CI_COMMIT_MESSAGE`                             | Pre-pipeline | The full commit message. |
| `CI_COMMIT_REF_NAME`                            | Pre-pipeline | The branch or tag name for which project is built. |
| `CI_COMMIT_REF_PROTECTED`                       | Pre-pipeline | `true` if the job is running for a protected reference, `false` otherwise. |
| `CI_COMMIT_REF_SLUG`                            | Pre-pipeline | `CI_COMMIT_REF_NAME` in lowercase, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. No leading / trailing `-`. Use in URLs, host names and domain names. |
| `CI_COMMIT_SHA`                                 | Pre-pipeline | The commit revision the project is built for. |
| `CI_COMMIT_SHORT_SHA`                           | Pre-pipeline | The first eight characters of `CI_COMMIT_SHA`. |
| `CI_COMMIT_TAG`                                 | Pre-pipeline | The commit tag name. Available only in pipelines for tags. |
| `CI_COMMIT_TAG_MESSAGE`                         | Pre-pipeline | The commit tag message. Available only in pipelines for tags. Introduced in GitLab 15.5. |
| `CI_COMMIT_TIMESTAMP`                           | Pre-pipeline | The timestamp of the commit in the [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) format. For example, `2022-01-31T16:47:55Z`. [UTC by default](../../administration/timezone.md). |
| `CI_COMMIT_TITLE`                               | Pre-pipeline | The title of the commit. The full first line of the message. |
| `CI_CONCURRENT_ID`                              | Job-only     | The unique ID of build execution in a single executor. |
| `CI_CONCURRENT_PROJECT_ID`                      | Job-only     | The unique ID of build execution in a single executor and project. |
| `CI_CONFIG_PATH`                                | Pre-pipeline | The path to the CI/CD configuration file. Defaults to `.gitlab-ci.yml`. |
| `CI_DEBUG_TRACE`                                | Pipeline     | `true` if [debug logging (tracing)](variables_troubleshooting.md#enable-debug-logging) is enabled. |
| `CI_DEBUG_SERVICES`                             | Pipeline     | `true` if [service container logging](../services/_index.md#capturing-service-container-logs) is enabled. Introduced in GitLab 15.7. Requires GitLab Runner 15.7. |
| `CI_DEFAULT_BRANCH`                             | Pre-pipeline | The name of the project's default branch. |
| `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX` | Pre-pipeline | The direct group image prefix for pulling images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`        | Pre-pipeline | The top-level group image prefix for pulling images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_PASSWORD`                  | Pipeline     | The password to pull images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_SERVER`                    | Pre-pipeline | The server for logging in to the Dependency Proxy. This variable is equivalent to `$CI_SERVER_HOST:$CI_SERVER_PORT`. |
| `CI_DEPENDENCY_PROXY_USER`                      | Pipeline     | The username to pull images through the Dependency Proxy. |
| `CI_DEPLOY_FREEZE`                              | Pre-pipeline | Only available if the pipeline runs during a [deploy freeze window](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze). `true` when available. |
| `CI_DEPLOY_PASSWORD`                            | Job-only     | The authentication password of the [GitLab Deploy Token](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token), if the project has one. |
| `CI_DEPLOY_USER`                                | Job-only     | The authentication username of the [GitLab Deploy Token](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token), if the project has one. |
| `CI_DISPOSABLE_ENVIRONMENT`                     | Pipeline     | Only available if the job is executed in a disposable environment (something that is created only for this job and disposed of/destroyed after the execution - all executors except `shell` and `ssh`). `true` when available. |
| `CI_ENVIRONMENT_NAME`                           | Pipeline     | The name of the environment for this job. Available if [`environment:name`](../yaml/_index.md#environmentname) is set. |
| `CI_ENVIRONMENT_SLUG`                           | Pipeline     | The simplified version of the environment name, suitable for inclusion in DNS, URLs, Kubernetes labels, and so on. Available if [`environment:name`](../yaml/_index.md#environmentname) is set. The slug is [truncated to 24 characters](https://gitlab.com/gitlab-org/gitlab/-/issues/20941). A random suffix is automatically added to [uppercase environment names](https://gitlab.com/gitlab-org/gitlab/-/issues/415526). |
| `CI_ENVIRONMENT_URL`                            | Pipeline     | The URL of the environment for this job. Available if [`environment:url`](../yaml/_index.md#environmenturl) is set. |
| `CI_ENVIRONMENT_ACTION`                         | Pipeline     | The action annotation specified for this job's environment. Available if [`environment:action`](../yaml/_index.md#environmentaction) is set. Can be `start`, `prepare`, or `stop`. |
| `CI_ENVIRONMENT_TIER`                           | Pipeline     | The [deployment tier of the environment](../environments/_index.md#deployment-tier-of-environments) for this job. |
| `CI_GITLAB_FIPS_MODE`                           | Pre-pipeline | Only available if [FIPS mode](../../development/fips_gitlab.md) is enabled in the GitLab instance. `true` when available. |
| `CI_HAS_OPEN_REQUIREMENTS`                      | Pipeline     | Only available if the pipeline's project has an open [requirement](../../user/project/requirements/_index.md). `true` when available. |
| `CI_JOB_GROUP_NAME`                             | Pipeline     | The shared name of a group of jobs, when using either [`parallel`](../yaml/_index.md#parallel) or [manually grouped jobs](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views). For example, if the job name is `rspec:test: [ruby, ubuntu]`, the `CI_JOB_GROUP_NAME` is `rspec:test`. It is the same as `CI_JOB_NAME` otherwise. Introduced in GitLab 17.10. |
| `CI_JOB_ID`                                     | Job-only     | The internal ID of the job, unique across all jobs in the GitLab instance. |
| `CI_JOB_IMAGE`                                  | Pipeline     | The name of the Docker image running the job. |
| `CI_JOB_MANUAL`                                 | Pipeline     | Only available if the job was started manually. `true` when available. |
| `CI_JOB_NAME`                                   | Pipeline     | The name of the job. |
| `CI_JOB_NAME_SLUG`                              | Pipeline     | `CI_JOB_NAME` in lowercase, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. No leading / trailing `-`. Use in paths. Introduced in GitLab 15.4. |
| `CI_JOB_STAGE`                                  | Pipeline     | The name of the job's stage. |
| `CI_JOB_STATUS`                                 | Job-only     | The status of the job as each runner stage is executed. Use with [`after_script`](../yaml/_index.md#after_script). Can be `success`, `failed`, or `canceled`. |
| `CI_JOB_TIMEOUT`                                | Job-only     | The job timeout, in seconds. Introduced in GitLab 15.7. Requires GitLab Runner 15.7. |
| `CI_JOB_TOKEN`                                  | Job-only     | A token to authenticate with [certain API endpoints](../jobs/ci_job_token.md). The token is valid as long as the job is running. |
| `CI_JOB_URL`                                    | Job-only     | The job details URL. |
| `CI_JOB_STARTED_AT`                             | Job-only     | The date and time when a job started, in [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) format. For example, `2022-01-31T16:47:55Z`. [UTC by default](../../administration/timezone.md). |
| `CI_KUBERNETES_ACTIVE`                          | Pre-pipeline | Only available if the pipeline has a Kubernetes cluster available for deployments. `true` when available. |
| `CI_NODE_INDEX`                                 | Pipeline     | The index of the job in the job set. Only available if the job uses [`parallel`](../yaml/_index.md#parallel). |
| `CI_NODE_TOTAL`                                 | Pipeline     | The total number of instances of this job running in parallel. Set to `1` if the job does not use [`parallel`](../yaml/_index.md#parallel). |
| `CI_OPEN_MERGE_REQUESTS`                        | Pre-pipeline | A comma-separated list of up to four merge requests that use the current branch and project as the merge request source. Only available in branch and merge request pipelines if the branch has an associated merge request. For example, `gitlab-org/gitlab!333,gitlab-org/gitlab-foss!11`. |
| `CI_PAGES_DOMAIN`                               | Pre-pipeline | The instance's domain that hosts GitLab Pages, not including the namespace subdomain. To use the full hostname, use `CI_PAGES_HOSTNAME` instead. |
| `CI_PAGES_HOSTNAME`                             | Job-only     | The full hostname of the Pages deployment. |
| `CI_PAGES_URL`                                  | Job-only     | The URL for a GitLab Pages site. Always a subdomain of `CI_PAGES_DOMAIN`. In GitLab 17.9 and later, the value includes the `path_prefix` when one is specified. |
| `CI_PIPELINE_ID`                                | Job-only     | The instance-level ID of the current pipeline. This ID is unique across all projects on the GitLab instance. |
| `CI_PIPELINE_IID`                               | Pipeline     | The project-level IID (internal ID) of the current pipeline. This ID is unique only in the current project. |
| `CI_PIPELINE_SOURCE`                            | Pre-pipeline | How the pipeline was triggered. The value can be one of the [pipeline sources](../jobs/job_rules.md#ci_pipeline_source-predefined-variable). |
| `CI_PIPELINE_TRIGGERED`                         | Pipeline     | `true` if the job was [triggered](../triggers/_index.md). |
| `CI_PIPELINE_URL`                               | Job-only     | The URL for the pipeline details. |
| `CI_PIPELINE_CREATED_AT`                        | Pre-pipeline | The date and time when the pipeline was created, in [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) format. For example, `2022-01-31T16:47:55Z`. [UTC by default](../../administration/timezone.md). |
| `CI_PIPELINE_NAME`                              | Pre-pipeline | The pipeline name defined in [`workflow:name`](../yaml/_index.md#workflowname). Introduced in GitLab 16.3. |
| `CI_PIPELINE_SCHEDULE_DESCRIPTION`              | Pre-pipeline | The description of the pipeline schedule. Only available in scheduled pipelines. Introduced in GitLab 17.8. |
| `CI_PROJECT_DIR`                                | Job-only     | The full path the repository is cloned to, and where the job runs from. If the GitLab Runner `builds_dir` parameter is set, this variable is set relative to the value of `builds_dir`. For more information, see the [Advanced GitLab Runner configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_PROJECT_ID`                                 | Pre-pipeline | The ID of the current project. This ID is unique across all projects on the GitLab instance. |
| `CI_PROJECT_NAME`                               | Pre-pipeline | The name of the directory for the project. For example if the project URL is `gitlab.example.com/group-name/project-1`, `CI_PROJECT_NAME` is `project-1`. |
| `CI_PROJECT_NAMESPACE`                          | Pre-pipeline | The project namespace (username or group name) of the job. |
| `CI_PROJECT_NAMESPACE_ID`                       | Pre-pipeline | The project namespace ID of the job. Introduced in GitLab 15.7. |
| `CI_PROJECT_NAMESPACE_SLUG`                     | Pre-pipeline | `$CI_PROJECT_NAMESPACE` in lowercase with characters that are not `a-z` or `0-9` replaced with - and shortened to 63 bytes. |
| `CI_PROJECT_PATH_SLUG`                          | Pre-pipeline | `$CI_PROJECT_PATH` in lowercase with characters that are not `a-z` or `0-9` replaced with `-` and shortened to 63 bytes. Use in URLs and domain names. |
| `CI_PROJECT_PATH`                               | Pre-pipeline | The project namespace with the project name included. |
| `CI_PROJECT_REPOSITORY_LANGUAGES`               | Pre-pipeline | A comma-separated, lowercase list of the languages used in the repository. For example `ruby,javascript,html,css`. The maximum number of languages is limited to 5. An issue [proposes to increase the limit](https://gitlab.com/gitlab-org/gitlab/-/issues/368925). |
| `CI_PROJECT_ROOT_NAMESPACE`                     | Pre-pipeline | The root project namespace (username or group name) of the job. For example, if `CI_PROJECT_NAMESPACE` is `root-group/child-group/grandchild-group`, `CI_PROJECT_ROOT_NAMESPACE` is `root-group`. |
| `CI_PROJECT_TITLE`                              | Pre-pipeline | The human-readable project name as displayed in the GitLab web interface. |
| `CI_PROJECT_DESCRIPTION`                        | Pre-pipeline | The project description as displayed in the GitLab web interface. Introduced in GitLab 15.1. |
| `CI_PROJECT_URL`                                | Pre-pipeline | The HTTP(S) address of the project. |
| `CI_PROJECT_VISIBILITY`                         | Pre-pipeline | The project visibility. Can be `internal`, `private`, or `public`. |
| `CI_PROJECT_CLASSIFICATION_LABEL`               | Pre-pipeline | The project [external authorization classification label](../../administration/settings/external_authorization.md). |
| `CI_REGISTRY`                                   | Pre-pipeline | Address of the [container registry](../../user/packages/container_registry/_index.md) server, formatted as `<host>[:<port>]`. For example: `registry.gitlab.example.com`. Only available if the container registry is enabled for the GitLab instance. |
| `CI_REGISTRY_IMAGE`                             | Pre-pipeline | Base address for the container registry to push, pull, or tag project's images, formatted as `<host>[:<port>]/<project_full_path>`. For example: `registry.gitlab.example.com/my_group/my_project`. Image names must follow the [container registry naming convention](../../user/packages/container_registry/_index.md#naming-convention-for-your-container-images). Only available if the container registry is enabled for the project. |
| `CI_REGISTRY_PASSWORD`                          | Job-only     | The password to push containers to the GitLab project's container registry. Only available if the container registry is enabled for the project. This password value is the same as the `CI_JOB_TOKEN` and is valid only as long as the job is running. Use the `CI_DEPLOY_PASSWORD` for long-lived access to the registry |
| `CI_REGISTRY_USER`                              | Job-only     | The username to push containers to the project's GitLab container registry. Only available if the container registry is enabled for the project. |
| `CI_RELEASE_DESCRIPTION`                        | Pipeline     | The description of the release. Available only on pipelines for tags. Description length is limited to first 1024 characters. Introduced in GitLab 15.5. |
| `CI_REPOSITORY_URL`                             | Job-only     | The full path to Git clone (HTTP) the repository with a [CI/CD job token](../jobs/ci_job_token.md), in the format `https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.example.com/my-group/my-project.git`. |
| `CI_RUNNER_DESCRIPTION`                         | Job-only     | The description of the runner. |
| `CI_RUNNER_EXECUTABLE_ARCH`                     | Job-only     | The OS/architecture of the GitLab Runner executable. Might not be the same as the environment of the executor. |
| `CI_RUNNER_ID`                                  | Job-only     | The unique ID of the runner being used. |
| `CI_RUNNER_REVISION`                            | Job-only     | The revision of the runner running the job. |
| `CI_RUNNER_SHORT_TOKEN`                         | Job-only     | The runner's unique ID, used to authenticate new job requests. The token contains a prefix, and the first 17 characters are used. |
| `CI_RUNNER_TAGS`                                | Job-only     | A JSON array of runner tags. For example `["tag_1", "tag_2"]`. |
| `CI_RUNNER_VERSION`                             | Job-only     | The version of the GitLab Runner running the job. |
| `CI_SERVER_FQDN`                                | Pre-pipeline | The fully qualified domain name (FQDN) of the instance. For example `gitlab.example.com:8080`. Introduced in GitLab 16.10. |
| `CI_SERVER_HOST`                                | Pre-pipeline | The host of the GitLab instance URL, without protocol or port. For example `gitlab.example.com`. |
| `CI_SERVER_NAME`                                | Pre-pipeline | The name of CI/CD server that coordinates jobs. |
| `CI_SERVER_PORT`                                | Pre-pipeline | The port of the GitLab instance URL, without host or protocol. For example `8080`. |
| `CI_SERVER_PROTOCOL`                            | Pre-pipeline | The protocol of the GitLab instance URL, without host or port. For example `https`. |
| `CI_SERVER_SHELL_SSH_HOST`                      | Pre-pipeline | The SSH host of the GitLab instance, used for access to Git repositories through SSH. For example `gitlab.com`. Introduced in GitLab 15.11. |
| `CI_SERVER_SHELL_SSH_PORT`                      | Pre-pipeline | The SSH port of the GitLab instance, used for access to Git repositories through SSH. For example `22`. Introduced in GitLab 15.11. |
| `CI_SERVER_REVISION`                            | Pre-pipeline | GitLab revision that schedules jobs. |
| `CI_SERVER_TLS_CA_FILE`                         | Pipeline     | File containing the TLS CA certificate to verify the GitLab server when `tls-ca-file` set in [runner settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_SERVER_TLS_CERT_FILE`                       | Pipeline     | File containing the TLS certificate to verify the GitLab server when `tls-cert-file` set in [runner settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_SERVER_TLS_KEY_FILE`                        | Pipeline     | File containing the TLS key to verify the GitLab server when `tls-key-file` set in [runner settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_SERVER_URL`                                 | Pre-pipeline | The base URL of the GitLab instance, including protocol and port. For example `https://gitlab.example.com:8080`. |
| `CI_SERVER_VERSION_MAJOR`                       | Pre-pipeline | The major version of the GitLab instance. For example, if the GitLab version is `17.2.1`, the `CI_SERVER_VERSION_MAJOR` is `17`. |
| `CI_SERVER_VERSION_MINOR`                       | Pre-pipeline | The minor version of the GitLab instance. For example, if the GitLab version is `17.2.1`, the `CI_SERVER_VERSION_MINOR` is `2`. |
| `CI_SERVER_VERSION_PATCH`                       | Pre-pipeline | The patch version of the GitLab instance. For example, if the GitLab version is `17.2.1`, the `CI_SERVER_VERSION_PATCH` is `1`. |
| `CI_SERVER_VERSION`                             | Pre-pipeline | The full version of the GitLab instance. |
| `CI_SERVER`                                     | Job-only     | Available for all jobs executed in CI/CD. `yes` when available. |
| `CI_SHARED_ENVIRONMENT`                         | Pipeline     | Only available if the job is executed in a shared environment (something that is persisted across CI/CD invocations, like the `shell` or `ssh` executor). `true` when available. |
| `CI_TEMPLATE_REGISTRY_HOST`                     | Pre-pipeline | The host of the registry used by CI/CD templates. Defaults to `registry.gitlab.com`. Introduced in GitLab 15.3. |
| `CI_TRIGGER_SHORT_TOKEN`                        | Job-only     | First 4 characters of the [trigger token](../triggers/_index.md#create-a-pipeline-trigger-token) of the current job. Only available if the pipeline was [triggered with a trigger token](../triggers/_index.md). For example, for a trigger token of `glptt-1234567890abcdefghij`, `CI_TRIGGER_SHORT_TOKEN` would be `1234`. Introduced in GitLab 17.0. <!-- gitleaks:allow --> |
| `GITLAB_CI`                                     | Pre-pipeline | Available for all jobs executed in CI/CD. `true` when available. |
| `GITLAB_FEATURES`                               | Pre-pipeline | The comma-separated list of licensed features available for the GitLab instance and license. |
| `GITLAB_USER_EMAIL`                             | Pipeline     | The email of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the email of the user who started the job. |
| `GITLAB_USER_ID`                                | Pipeline     | The numeric ID of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the ID of the user who started the job. |
| `GITLAB_USER_LOGIN`                             | Pipeline     | The unique username of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the username of the user who started the job. |
| `GITLAB_USER_NAME`                              | Pipeline     | The display name (user-defined **Full name** in the profile settings) of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the name of the user who started the job. |
| `KUBECONFIG`                                    | Pipeline     | The path to the `kubeconfig` file with contexts for every shared agent connection. Only available when a [GitLab agent is authorized to access the project](../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access). |
| `TRIGGER_PAYLOAD`                               | Pipeline     | The webhook payload. Only available when a pipeline is [triggered with a webhook](../triggers/_index.md#access-webhook-payload). |

## Predefined variables for merge request pipelines

These variables are available before GitLab creates the pipeline
(Pre-pipeline). These variables can be used with
[`include:rules`](../yaml/includes.md#use-rules-with-include)
and as environment variables in jobs.

The pipeline must be a [merge request pipeline](../pipelines/merge_request_pipelines.md),
and the merge request must be open.

| Variable                                    | Description |
|---------------------------------------------|-------------|
| `CI_MERGE_REQUEST_APPROVED`                 | Approval status of the merge request. `true` when [merge request approvals](../../user/project/merge_requests/approvals/_index.md) is available and the merge request has been approved. |
| `CI_MERGE_REQUEST_ASSIGNEES`                | Comma-separated list of usernames of assignees for the merge request. Only available if the merge request has at least one assignee. |
| `CI_MERGE_REQUEST_DIFF_BASE_SHA`            | The base SHA of the merge request diff. |
| `CI_MERGE_REQUEST_DIFF_ID`                  | The version of the merge request diff. |
| `CI_MERGE_REQUEST_EVENT_TYPE`               | The event type of the merge request. Can be `detached`, `merged_result` or `merge_train`. |
| `CI_MERGE_REQUEST_DESCRIPTION`              | The description of the merge request. If the description is more than 2700 characters long, only the first 2700 characters are stored in the variable. Introduced in GitLab 16.7. |
| `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` | `true` if `CI_MERGE_REQUEST_DESCRIPTION` is truncated down to 2700 characters because the description of the merge request is too long, otherwise `false`. Introduced in GitLab 16.8. |
| `CI_MERGE_REQUEST_ID`                       | The instance-level ID of the merge request. The ID is unique across all projects on the GitLab instance. |
| `CI_MERGE_REQUEST_IID`                      | The project-level IID (internal ID) of the merge request. This ID is unique for the current project, and is the number used in the merge request URL, page title, and other visible locations. |
| `CI_MERGE_REQUEST_LABELS`                   | Comma-separated label names of the merge request. Only available if the merge request has at least one label. |
| `CI_MERGE_REQUEST_MILESTONE`                | The milestone title of the merge request. Only available if the merge request has a milestone set. |
| `CI_MERGE_REQUEST_PROJECT_ID`               | The ID of the project of the merge request. |
| `CI_MERGE_REQUEST_PROJECT_PATH`             | The path of the project of the merge request. For example `namespace/awesome-project`. |
| `CI_MERGE_REQUEST_PROJECT_URL`              | The URL of the project of the merge request. For example, `http://192.168.10.15:3000/namespace/awesome-project`. |
| `CI_MERGE_REQUEST_REF_PATH`                 | The ref path of the merge request. For example, `refs/merge-requests/1/head`. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`       | The source branch name of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED`  | `true` when the source branch of the merge request is [protected](../../user/project/repository/branches/protected.md). Introduced in GitLab 16.4. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`        | The HEAD SHA of the source branch of the merge request. The variable is empty in merge request pipelines. The SHA is present only in [merged results pipelines](../pipelines/merged_results_pipelines.md). |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_ID`        | The ID of the source project of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`      | The path of the source project of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_URL`       | The URL of the source project of the merge request. |
| `CI_MERGE_REQUEST_SQUASH_ON_MERGE`          | `true` when the [squash on merge](../../user/project/merge_requests/squash_and_merge.md) option is set. Introduced in GitLab 16.4. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`       | The target branch name of the merge request. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED`  | `true` when the target branch of the merge request is [protected](../../user/project/repository/branches/protected.md). Introduced in GitLab 15.2. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`        | The HEAD SHA of the target branch of the merge request. The variable is empty in merge request pipelines. The SHA is present only in [merged results pipelines](../pipelines/merged_results_pipelines.md). |
| `CI_MERGE_REQUEST_TITLE`                    | The title of the merge request. |
| `CI_MERGE_REQUEST_DRAFT`                    | `true` if the merge request is a draft. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/275981) in GitLab 17.10. |

## Predefined variables for external pull request pipelines

These variables are only available when:

- The pipelines are [external pull requests pipelines](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)
- The pull request is open.

| Variable                                      | Description |
|-----------------------------------------------|-------------|
| `CI_EXTERNAL_PULL_REQUEST_IID`                | Pull request ID from GitHub. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY`  | The source repository name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY`  | The target repository name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME` | The source branch name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA`  | The HEAD SHA of the source branch of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME` | The target branch name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA`  | The HEAD SHA of the target branch of the pull request. |

## Deployment variables

Integrations that are responsible for deployment configuration can define their own
predefined variables that are set in the build environment. These variables are only defined
for [deployment jobs](../environments/_index.md).

For example, the [Kubernetes integration](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)
defines deployment variables that you can use with the integration.

The [documentation for each integration](../../user/project/integrations/_index.md)
explains if the integration has any deployment variables available.

## Auto DevOps variables

When [Auto DevOps](../../topics/autodevops/_index.md) is enabled, some additional
[pre-pipeline](#variable-availability) variables are made available:

- `AUTO_DEVOPS_EXPLICITLY_ENABLED`: Has a value of `1` to indicate Auto DevOps is enabled.
- `STAGING_ENABLED`: See [Auto DevOps deployment strategy](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy).
- `INCREMENTAL_ROLLOUT_MODE`: See [Auto DevOps deployment strategy](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy).
- `INCREMENTAL_ROLLOUT_ENABLED`: Deprecated.

## Integration variables

Some integrations make variables available in jobs. These variables are available
as [job-only predefined variables](#variable-availability):

- [Harbor](../../user/project/integrations/harbor.md):
  - `HARBOR_URL`
  - `HARBOR_HOST`
  - `HARBOR_OCI`
  - `HARBOR_PROJECT`
  - `HARBOR_USERNAME`
  - `HARBOR_PASSWORD`
- [Apple App Store Connect](../../user/project/integrations/apple_app_store.md):
  - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY`
  - `APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`
- [Google Play](../../user/project/integrations/google_play.md):
  - `SUPPLY_PACKAGE_NAME`
  - `SUPPLY_JSON_KEY_DATA`
- [Diffblue Cover](../../integration/diffblue_cover.md):
  - `DIFFBLUE_LICENSE_KEY`
  - `DIFFBLUE_ACCESS_TOKEN_NAME`
  - `DIFFBLUE_ACCESS_TOKEN`

## Troubleshooting

You can [output the values of all variables available for a job](variables_troubleshooting.md#list-all-variables)
with a `script` command.
