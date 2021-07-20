---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Predefined variables reference **(FREE)**

Predefined [CI/CD variables](index.md) are available in every GitLab CI/CD pipeline.

Some variables are only available with more recent versions of [GitLab Runner](https://docs.gitlab.com/runner/).

You can [output the values of all variables available for a job](index.md#list-all-environment-variables)
with a `script` command.

There are also [Kubernetes-specific deployment variables](../../user/project/clusters/deploy_to_cluster.md#deployment-variables).

| Variable                                 | GitLab | Runner | Description |
|------------------------------------------|--------|--------|-------------|
| `CHAT_CHANNEL`                           | 10.6   | all    | The Source chat channel that triggered the [ChatOps](../chatops/index.md) command. |
| `CHAT_INPUT`                             | 10.6   | all    | The additional arguments passed with the [ChatOps](../chatops/index.md) command. |
| `CI`                                     | all    | 0.4    | Available for all jobs executed in CI/CD. `true` when available. |
| `CI_API_V4_URL`                          | 11.7   | all    | The GitLab API v4 root URL. |
| `CI_BUILDS_DIR`                          | all    | 11.10  | The top-level directory where builds are executed. |
| `CI_COMMIT_AUTHOR`                       | 13.11  | all    | The author of the commit in `Name <email>` format. |
| `CI_COMMIT_BEFORE_SHA`                   | 11.2   | all    | The previous latest commit present on a branch. Is always `0000000000000000000000000000000000000000` in pipelines for merge requests. |
| `CI_COMMIT_BRANCH`                       | 12.6   | 0.5    | The commit branch name. Available in branch pipelines, including pipelines for the default branch. Not available in merge request pipelines or tag pipelines. |
| `CI_COMMIT_DESCRIPTION`                  | 10.8   | all    | The description of the commit. If the title is shorter than 100 characters, the message without the first line. |
| `CI_COMMIT_MESSAGE`                      | 10.8   | all    | The full commit message. |
| `CI_COMMIT_REF_NAME`                     | 9.0    | all    | The branch or tag name for which project is built. |
| `CI_COMMIT_REF_PROTECTED`                | 11.11  | all    | `true` if the job is running for a protected reference. |
| `CI_COMMIT_REF_SLUG`                     | 9.0    | all    | `CI_COMMIT_REF_NAME` in lowercase, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. No leading / trailing `-`. Use in URLs, host names and domain names. |
| `CI_COMMIT_SHA`                          | 9.0    | all    | The commit revision the project is built for. |
| `CI_COMMIT_SHORT_SHA`                    | 11.7   | all    | The first eight characters of `CI_COMMIT_SHA`. |
| `CI_COMMIT_TAG`                          | 9.0    | 0.5    | The commit tag name. Available only in pipelines for tags. |
| `CI_COMMIT_TIMESTAMP`                    | 13.4   | all    | The timestamp of the commit in the ISO 8601 format. |
| `CI_COMMIT_TITLE`                        | 10.8   | all    | The title of the commit. The full first line of the message. |
| `CI_CONCURRENT_ID`                       | all    | 11.10  | The unique ID of build execution in a single executor. |
| `CI_CONCURRENT_PROJECT_ID`               | all    | 11.10  | The unique ID of build execution in a single executor and project. |
| `CI_CONFIG_PATH`                         | 9.4    | 0.5    | The path to the CI/CD configuration file. Defaults to `.gitlab-ci.yml`. |
| `CI_DEBUG_TRACE`                         | all    | 1.7    | `true` if [debug logging (tracing)](index.md#debug-logging) is enabled. |
| `CI_DEFAULT_BRANCH`                      | 12.4   | all    | The name of the project's default branch. |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX` | 13.7   | all    | The image prefix for pulling images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_PASSWORD`           | 13.7   | all    | The password to pull images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_SERVER`             | 13.7   | all    | The server for logging in to the Dependency Proxy. This is equivalent to `$CI_SERVER_HOST:$CI_SERVER_PORT`. |
| `CI_DEPENDENCY_PROXY_USER`               | 13.7   | all    | The username to pull images through the Dependency Proxy. |
| `CI_DEPLOY_FREEZE`                       | 13.2   | all    | Only available if the pipeline runs during a [deploy freeze window](../../user/project/releases/index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze). `true` when available. |
| `CI_DEPLOY_PASSWORD`                     | 10.8   | all    | The authentication password of the [GitLab Deploy Token](../../user/project/deploy_tokens/index.md#gitlab-deploy-token), if the project has one. |
| `CI_DEPLOY_USER`                         | 10.8   | all    | The authentication username of the [GitLab Deploy Token](../../user/project/deploy_tokens/index.md#gitlab-deploy-token), if the project has one. |
| `CI_DISPOSABLE_ENVIRONMENT`              | all    | 10.1   | Only available if the job is executed in a disposable environment (something that is created only for this job and disposed of/destroyed after the execution - all executors except `shell` and `ssh`). `true` when available. |
| `CI_ENVIRONMENT_NAME`                    | 8.15   | all    | The name of the environment for this job. Available if [`environment:name`](../yaml/index.md#environmentname) is set. |
| `CI_ENVIRONMENT_SLUG`                    | 8.15   | all    | The simplified version of the environment name, suitable for inclusion in DNS, URLs, Kubernetes labels, and so on. Available if [`environment:name`](../yaml/index.md#environmentname) is set. The slug is [truncated to 24 characters](https://gitlab.com/gitlab-org/gitlab/-/issues/20941). |
| `CI_ENVIRONMENT_URL`                     | 9.3    | all    | The URL of the environment for this job. Available if [`environment:url`](../yaml/index.md#environmenturl) is set. |
| `CI_ENVIRONMENT_ACTION`                  | 13.11  | all    | The action annotation specified for this job's environment. Available if [`environment:action`](../yaml/index.md#environmentaction) is set. Can be `start`, `prepare`, or `stop`. |
| `CI_ENVIRONMENT_TIER`                    | 14.0   | all    | The [deployment tier of the environment](../environments/index.md#deployment-tier-of-environments) for this job. |
| `CI_HAS_OPEN_REQUIREMENTS`               | 13.1   | all    | Only available if the pipeline's project has an open [requirement](../../user/project/requirements/index.md). `true` when available. |
| `CI_JOB_ID`                              | 9.0    | all    | The internal ID of the job, unique across all jobs in the GitLab instance. |
| `CI_JOB_IMAGE`                           | 12.9   | 12.9   | The name of the Docker image running the job. |
| `CI_JOB_JWT`                             | 12.10  | all    | A RS256 JSON web token to authenticate with third party systems that support JWT authentication, for example [HashiCorp's Vault](../secrets/index.md). |
| `CI_JOB_MANUAL`                          | 8.12   | all    | `true` if a job was started manually. |
| `CI_JOB_NAME`                            | 9.0    | 0.5    | The name of the job. |
| `CI_JOB_STAGE`                           | 9.0    | 0.5    | The name of the job's stage. |
| `CI_JOB_STATUS`                          | all    | 13.5   | The status of the job as each runner stage is executed. Use with [`after_script`](../yaml/index.md#after_script). Can be `success`, `failed`, or `canceled`. |
| `CI_JOB_TOKEN`                           | 9.0    | 1.2    | A token to authenticate with [certain API endpoints](../../api/index.md#gitlab-cicd-job-token). The token is valid as long as the job is running. |
| `CI_JOB_URL`                             | 11.1   | 0.5    | The job details URL. |
| `CI_JOB_STARTED_AT`                      | 13.10  | all    | The UTC datetime when a job started, in [ISO 8601](https://tools.ietf.org/html/rfc3339#appendix-A) format. |
| `CI_KUBERNETES_ACTIVE`                   | 13.0   | all    | Only available if the pipeline has a Kubernetes cluster available for deployments. `true` when available. |
| `CI_NODE_INDEX`                          | 11.5   | all    | The index of the job in the job set. Only available if the job uses [`parallel`](../yaml/index.md#parallel). |
| `CI_NODE_TOTAL`                          | 11.5   | all    | The total number of instances of this job running in parallel. Set to `1` if the job does not use [`parallel`](../yaml/index.md#parallel). |
| `CI_OPEN_MERGE_REQUESTS`                 | 13.8   | all    | A comma-separated list of up to four merge requests that use the current branch and project as the merge request source. Only available in branch and merge request pipelines if the branch has an associated merge request. For example, `gitlab-org/gitlab!333,gitlab-org/gitlab-foss!11`. |
| `CI_PAGES_DOMAIN`                        | 11.8   | all    | The configured domain that hosts GitLab Pages. |
| `CI_PAGES_URL`                           | 11.8   | all    | The URL for a GitLab Pages site. Always a subdomain of `CI_PAGES_DOMAIN`. |
| `CI_PIPELINE_ID`                         | 8.10   | all    | The instance-level ID of the current pipeline. This ID is unique across all projects on the GitLab instance. |
| `CI_PIPELINE_IID`                        | 11.0   | all    | The project-level IID (internal ID) of the current pipeline. This ID is unique only within the current project. |
| `CI_PIPELINE_SOURCE`                     | 10.0   | all    | How the pipeline was triggered. Can be `push`, `web`, `schedule`, `api`, `external`, `chat`, `webide`, `merge_request_event`, `external_pull_request_event`, `parent_pipeline`, [`trigger`, or `pipeline`](../triggers/index.md#authentication-tokens). |
| `CI_PIPELINE_TRIGGERED`                  | all    | all    | `true` if the job was [triggered](../triggers/index.md). |
| `CI_PIPELINE_URL`                        | 11.1   | 0.5    | The URL for the pipeline details. |
| `CI_PIPELINE_CREATED_AT`                 | 13.10  | all    | The UTC datetime when the pipeline was created, in [ISO 8601](https://tools.ietf.org/html/rfc3339#appendix-A) format. |
| `CI_PROJECT_CONFIG_PATH`                 | 13.8 to 13.12 | all    | [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/322807) in GitLab 14.0. Use `CI_CONFIG_PATH`. |
| `CI_PROJECT_DIR`                         | all    | all    | The full path the repository is cloned to, and where the job runs from. If the GitLab Runner `builds_dir` parameter is set, this variable is set relative to the value of `builds_dir`. For more information, see the [Advanced GitLab Runner configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_PROJECT_ID`                          | all    | all    | The ID of the current project. This ID is unique across all projects on the GitLab instance. |
| `CI_PROJECT_NAME`                        | 8.10   | 0.5    | The name of the directory for the project. For example if the project URL is `gitlab.example.com/group-name/project-1`, `CI_PROJECT_NAME` is `project-1`. |
| `CI_PROJECT_NAMESPACE`                   | 8.10   | 0.5    | The project namespace (username or group name) of the job. |
| `CI_PROJECT_PATH_SLUG`                   | 9.3    | all    | `$CI_PROJECT_PATH` in lowercase with characters that are not `a-z` or `0-9` replaced with `-`. Use in URLs and domain names. |
| `CI_PROJECT_PATH`                        | 8.10   | 0.5    | The project namespace with the project name included. |
| `CI_PROJECT_REPOSITORY_LANGUAGES`        | 12.3   | all    | A comma-separated, lowercase list of the languages used in the repository. For example `ruby,javascript,html,css`. |
| `CI_PROJECT_ROOT_NAMESPACE`              | 13.2   | 0.5    | The root project namespace (username or group name) of the job. For example, if `CI_PROJECT_NAMESPACE` is `root-group/child-group/grandchild-group`, `CI_PROJECT_ROOT_NAMESPACE` is `root-group`. |
| `CI_PROJECT_TITLE`                       | 12.4   | all    | The human-readable project name as displayed in the GitLab web interface. |
| `CI_PROJECT_URL`                         | 8.10   | 0.5    | The HTTP(S) address of the project. |
| `CI_PROJECT_VISIBILITY`                  | 10.3   | all    | The project visibility. Can be `internal`, `private`, or `public`. |
| `CI_REGISTRY_IMAGE`                      | 8.10   | 0.5    | The address of the project's Container Registry. Only available if the Container Registry is enabled for the project. |
| `CI_REGISTRY_PASSWORD`                   | 9.0    | all    | The password to push containers to the project's GitLab Container Registry. Only available if the Container Registry is enabled for the project. |
| `CI_REGISTRY_USER`                       | 9.0    | all    | The username to push containers to the project's GitLab Container Registry. Only available if the Container Registry is enabled for the project. |
| `CI_REGISTRY`                            | 8.10   | 0.5    | The address of the GitLab Container Registry. Only available if the Container Registry is enabled for the project. This variable includes a `:port` value if one is specified in the registry configuration. |
| `CI_REPOSITORY_URL`                      | 9.0    | all    | The URL to clone the Git repository. |
| `CI_RUNNER_DESCRIPTION`                  | 8.10   | 0.5    | The description of the runner. |
| `CI_RUNNER_EXECUTABLE_ARCH`              | all    | 10.6   | The OS/architecture of the GitLab Runner executable. Might not be the same as the environment of the executor. |
| `CI_RUNNER_ID`                           | 8.10   | 0.5    | The unique ID of the runner being used. |
| `CI_RUNNER_REVISION`                     | all    | 10.6   | The revision of the runner running the job. |
| `CI_RUNNER_SHORT_TOKEN`                  | all    | 12.3   | First eight characters of the runner's token used to authenticate new job requests. Used as the runner's unique ID. |
| `CI_RUNNER_TAGS`                         | 8.10   | 0.5    | A comma-separated list of the runner tags. |
| `CI_RUNNER_VERSION`                      | all    | 10.6   | The version of the GitLab Runner running the job. |
| `CI_SERVER_HOST`                         | 12.1   | all    | The host of the GitLab instance URL, without protocol or port. For example `gitlab.example.com`. |
| `CI_SERVER_NAME`                         | all    | all    | The name of CI/CD server that coordinates jobs. |
| `CI_SERVER_PORT`                         | 12.8   | all    | The port of the GitLab instance URL, without host or protocol. For example `8080`. |
| `CI_SERVER_PROTOCOL`                     | 12.8   | all    | The protocol of the GitLab instance URL, without host or port. For example `https`. |
| `CI_SERVER_REVISION`                     | all    | all    | GitLab revision that schedules jobs. |
| `CI_SERVER_URL`                          | 12.7   | all    | The base URL of the GitLab instance, including protocol and port. For example `https://gitlab.example.com:8080`. |
| `CI_SERVER_VERSION_MAJOR`                | 11.4   | all    | The major version of the GitLab instance. For example, if the GitLab version is `13.6.1`, the `CI_SERVER_VERSION_MAJOR` is `13`. |
| `CI_SERVER_VERSION_MINOR`                | 11.4   | all    | The minor version of the GitLab instance. For example, if the GitLab version is `13.6.1`, the `CI_SERVER_VERSION_MINOR` is `6`. |
| `CI_SERVER_VERSION_PATCH`                | 11.4   | all    | The patch version of the GitLab instance. For example, if the GitLab version is `13.6.1`, the `CI_SERVER_VERSION_PATCH` is `1`. |
| `CI_SERVER_VERSION`                      | all    | all    | The full version of the GitLab instance. |
| `CI_SERVER`                              | all    | all    | Available for all jobs executed in CI/CD. `yes` when available. |
| `CI_SHARED_ENVIRONMENT`                  | all    | 10.1   | Only available if the job is executed in a shared environment (something that is persisted across CI/CD invocations, like the `shell` or `ssh` executor). `true` when available. |
| `GITLAB_CI`                              | all    | all    | Available for all jobs executed in CI/CD. `true` when available. |
| `GITLAB_FEATURES`                        | 10.6   | all    | The comma-separated list of licensed features available for the GitLab instance and license. |
| `GITLAB_USER_EMAIL`                      | 8.12   | all    | The email of the user who started the job. |
| `GITLAB_USER_ID`                         | 8.12   | all    | The ID of the user who started the job. |
| `GITLAB_USER_LOGIN`                      | 10.0   | all    | The username of the user who started the job. |
| `GITLAB_USER_NAME`                       | 10.0   | all    | The name of the user who started the job. |
| `TRIGGER_PAYLOAD`                        | 13.9   | all    | The webhook payload. Only available when a pipeline is [triggered with a webhook](../triggers/index.md#using-webhook-payload-in-the-triggered-pipeline). |

## Predefined variables for merge request pipelines

These variables are available when:

- The pipelines [are merge request pipelines](../pipelines/merge_request_pipelines.md).
- The merge request is open.

| Variable                               | GitLab | Runner | Description |
|----------------------------------------|--------|--------|-------------|
| `CI_MERGE_REQUEST_APPROVED`            | 14.1   | all    | Approval status of the merge request. `true` when [merge request approvals](../../user/project/merge_requests/approvals/index.md) is available and the merge request has been approved. |
| `CI_MERGE_REQUEST_ASSIGNEES`           | 11.9   | all    | Comma-separated list of usernames of assignees for the merge request. |
| `CI_MERGE_REQUEST_ID`                  | 11.6   | all    | The instance-level ID of the merge request. This is a unique ID across all projects on GitLab. |
| `CI_MERGE_REQUEST_IID`                 | 11.6   | all    | The project-level IID (internal ID) of the merge request. This ID is unique for the current project. |
| `CI_MERGE_REQUEST_LABELS`              | 11.9   | all    | Comma-separated label names of the merge request. |
| `CI_MERGE_REQUEST_MILESTONE`           | 11.9   | all    | The milestone title of the merge request. |
| `CI_MERGE_REQUEST_PROJECT_ID`          | 11.6   | all    | The ID of the project of the merge request. |
| `CI_MERGE_REQUEST_PROJECT_PATH`        | 11.6   | all    | The path of the project of the merge request. For example `namespace/awesome-project`. |
| `CI_MERGE_REQUEST_PROJECT_URL`         | 11.6   | all    | The URL of the project of the merge request. For example, `http://192.168.10.15:3000/namespace/awesome-project`. |
| `CI_MERGE_REQUEST_REF_PATH`            | 11.6   | all    | The ref path of the merge request. For example, `refs/merge-requests/1/head`. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`  | 11.6   | all    | The source branch name of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`   | 11.9   | all    | The HEAD SHA of the source branch of the merge request. The variable is empty in merge request pipelines. The SHA is present only in [merged results pipelines](../pipelines/pipelines_for_merged_results.md). **(PREMIUM)** |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_ID`   | 11.6   | all    | The ID of the source project of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_PATH` | 11.6   | all    | The path of the source project of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_URL`  | 11.6   | all    | The URL of the source project of the merge request. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`  | 11.6   | all    | The target branch name of the merge request. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`   | 11.9   | all    | The HEAD SHA of the target branch of the merge request. The variable is empty in merge request pipelines. The SHA is present only in [merged results pipelines](../pipelines/pipelines_for_merged_results.md). **(PREMIUM)** |
| `CI_MERGE_REQUEST_TITLE`               | 11.9   | all    | The title of the merge request. |
| `CI_MERGE_REQUEST_EVENT_TYPE`          | 12.3   | all    | The event type of the merge request. Can be `detached`, `merged_result` or `merge_train`. |
| `CI_MERGE_REQUEST_DIFF_ID`             | 13.7   | all    | The version of the merge request diff. |
| `CI_MERGE_REQUEST_DIFF_BASE_SHA`       | 13.7   | all    | The base SHA of the merge request diff. |

## Predefined variables for external pull request pipelines

These variables are only available when:

- The pipelines are [external pull requests pipelines](../ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests)
- The pull request is open.

| Variable                                      | GitLab | Runner | Description |
|-----------------------------------------------|--------|--------|-------------|
| `CI_EXTERNAL_PULL_REQUEST_IID`                | 12.3   | all    | Pull request ID from GitHub. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY`  | 13.3   | all    | The source repository name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY`  | 13.3   | all    | The target repository name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME` | 12.3   | all    | The source branch name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA`  | 12.3   | all    | The HEAD SHA of the source branch of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME` | 12.3   | all    | The target branch name of the pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA`  | 12.3   | all    | The HEAD SHA of the target branch of the pull request. |
