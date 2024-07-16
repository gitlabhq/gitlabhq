---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Predefined CI/CD variables reference

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Predefined [CI/CD variables](index.md) are available in every GitLab CI/CD pipeline.

Predefined variables become available at two different phases of pipeline execution.
Some variables are available when GitLab creates the pipeline, and can be used to configure
the pipeline or in job scripts. The other variables become available when a runner runs the job,
and can only be used in job scripts.

Predefined variables made available by the runner cannot be used with [trigger jobs](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)
or these keywords:

- [`workflow`](../yaml/index.md#workflow)
- [`include`](../yaml/index.md#include)
- [`rules`](../yaml/index.md#rules)

NOTE:
Avoid [overriding](index.md#override-a-defined-cicd-variable) predefined variables,
as it can cause the pipeline to behave unexpectedly.

| Variable                          | Defined for | GitLab | Runner | Description |
|-----------------------------------|-------------|--------|--------|-------------|
| `CHAT_CHANNEL`                    | Pipeline    | 10.6   | all    | The Source chat channel that triggered the [ChatOps](../chatops/index.md) command. |
| `CHAT_INPUT`                      | Pipeline    | 10.6   | all    | The additional arguments passed with the [ChatOps](../chatops/index.md) command. |
| `CHAT_USER_ID`                    | Pipeline    | 14.4   | all    | The chat service's user ID of the user who triggered the [ChatOps](../chatops/index.md) command. |
| `CI`                              | Pipeline    | all    | 0.4    | Available for all jobs executed in CI/CD. `true` when available. |
| `CI_API_V4_URL`                   | Pipeline    | 11.7   | all    | The GitLab API v4 root URL. |
| `CI_API_GRAPHQL_URL`              | Pipeline    | 15.11  | all    | The GitLab API GraphQL root URL. |
| `CI_BUILDS_DIR`                   | Jobs only   | all    | 11.10  | The top-level directory where builds are executed. |
| `CI_COMMIT_AUTHOR`                | Pipeline    | 13.11  | all    | The author of the commit in `Name <email>` format. |
| `CI_COMMIT_BEFORE_SHA`            | Pipeline    | 11.2   | all    | The previous latest commit present on a branch or tag. Is always `0000000000000000000000000000000000000000` for merge request pipelines, the first commit in pipelines for branches or tags, or when manually running a pipeline. |
| `CI_COMMIT_BRANCH`                | Pipeline    | 12.6   | 0.5    | The commit branch name. Available in branch pipelines, including pipelines for the default branch. Not available in merge request pipelines or tag pipelines. |
| `CI_COMMIT_DESCRIPTION`           | Pipeline    | 10.8   | all    | The description of the commit. If the title is shorter than 100 characters, the message without the first line. |
| `CI_COMMIT_MESSAGE`               | Pipeline    | 10.8   | all    | The full commit message. |
| `CI_COMMIT_REF_NAME`              | Pipeline    | 9.0    | all    | The branch or tag name for which project is built. |
| `CI_COMMIT_REF_PROTECTED`         | Pipeline    | 11.11  | all    | `true` if the job is running for a protected reference, `false` otherwise. |
| `CI_COMMIT_REF_SLUG`              | Pipeline    | 9.0    | all    | `CI_COMMIT_REF_NAME` in lowercase, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. No leading / trailing `-`. Use in URLs, host names and domain names. |
| `CI_COMMIT_SHA`                   | Pipeline    | 9.0    | all    | The commit revision the project is built for. |
| `CI_COMMIT_SHORT_SHA`             | Pipeline    | 11.7   | all    | The first eight characters of `CI_COMMIT_SHA`. |
| `CI_COMMIT_TAG`                   | Pipeline    | 9.0    | 0.5    | The commit tag name. Available only in pipelines for tags. |
| `CI_COMMIT_TAG_MESSAGE`           | Pipeline    | 15.5   | all    | The commit tag message. Available only in pipelines for tags. |
| `CI_COMMIT_TIMESTAMP`             | Pipeline    | 13.4   | all    | The timestamp of the commit in the [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) format. For example, `2022-01-31T16:47:55Z`. [UTC by default](../../administration/timezone.md). |
| `CI_COMMIT_TITLE`                 | Pipeline    | 10.8   | all    | The title of the commit. The full first line of the message. |
| `CI_CONCURRENT_ID`                | Jobs only   | all    | 11.10  | The unique ID of build execution in a single executor. |
| `CI_CONCURRENT_PROJECT_ID`        | Jobs only   | all    | 11.10  | The unique ID of build execution in a single executor and project. |
| `CI_CONFIG_PATH`                  | Pipeline    | 9.4    | 0.5    | The path to the CI/CD configuration file. Defaults to `.gitlab-ci.yml`. |
| `CI_DEBUG_TRACE`                  | Pipeline    | all    | 1.7    | `true` if [debug logging (tracing)](index.md#enable-debug-logging) is enabled. |
| `CI_DEBUG_SERVICES`               | Pipeline    | 15.7   | 15.7   | `true` if [service container logging](../services/index.md#capturing-service-container-logs) is enabled. |
| `CI_DEFAULT_BRANCH`               | Pipeline    | 12.4   | all    | The name of the project's default branch. |
| `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX`| Pipeline | 14.3 | all  | The direct group image prefix for pulling images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`       | Pipeline | 13.7 | all  | The top-level group image prefix for pulling images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_PASSWORD`    | Pipeline    | 13.7   | all    | The password to pull images through the Dependency Proxy. |
| `CI_DEPENDENCY_PROXY_SERVER`      | Pipeline    | 13.7   | all    | The server for logging in to the Dependency Proxy. This is equivalent to `$CI_SERVER_HOST:$CI_SERVER_PORT`. |
| `CI_DEPENDENCY_PROXY_USER`        | Pipeline    | 13.7   | all    | The username to pull images through the Dependency Proxy. |
| `CI_DEPLOY_FREEZE`                | Pipeline    | 13.2   | all    | Only available if the pipeline runs during a [deploy freeze window](../../user/project/releases/index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze). `true` when available. |
| `CI_DEPLOY_PASSWORD`              | Jobs only   | 10.8   | all    | The authentication password of the [GitLab Deploy Token](../../user/project/deploy_tokens/index.md#gitlab-deploy-token), if the project has one. |
| `CI_DEPLOY_USER`                  | Jobs only   | 10.8   | all    | The authentication username of the [GitLab Deploy Token](../../user/project/deploy_tokens/index.md#gitlab-deploy-token), if the project has one. |
| `CI_DISPOSABLE_ENVIRONMENT`       | Pipeline    | all    | 10.1   | Only available if the job is executed in a disposable environment (something that is created only for this job and disposed of/destroyed after the execution - all executors except `shell` and `ssh`). `true` when available. |
| `CI_ENVIRONMENT_NAME`             | Pipeline    | 8.15   | all    | The name of the environment for this job. Available if [`environment:name`](../yaml/index.md#environmentname) is set. |
| `CI_ENVIRONMENT_SLUG`             | Pipeline    | 8.15   | all    | The simplified version of the environment name, suitable for inclusion in DNS, URLs, Kubernetes labels, and so on. Available if [`environment:name`](../yaml/index.md#environmentname) is set. The slug is [truncated to 24 characters](https://gitlab.com/gitlab-org/gitlab/-/issues/20941). A random suffix is automatically added to [uppercase environment names](https://gitlab.com/gitlab-org/gitlab/-/issues/415526). |
| `CI_ENVIRONMENT_URL`              | Pipeline    | 9.3    | all    | The URL of the environment for this job. Available if [`environment:url`](../yaml/index.md#environmenturl) is set. |
| `CI_ENVIRONMENT_ACTION`           | Pipeline    | 13.11  | all    | The action annotation specified for this job's environment. Available if [`environment:action`](../yaml/index.md#environmentaction) is set. Can be `start`, `prepare`, or `stop`. |
| `CI_ENVIRONMENT_TIER`             | Pipeline    | 14.0   | all    | The [deployment tier of the environment](../environments/index.md#deployment-tier-of-environments) for this job. |
| `CI_GITLAB_FIPS_MODE`             | Pipeline    | 14.10  | all    | Only available if [FIPS mode](../../development/fips_compliance.md) is enabled in the GitLab instance. `true` when available. |
| `CI_HAS_OPEN_REQUIREMENTS`        | Pipeline    | 13.1   | all    | Only available if the pipeline's project has an open [requirement](../../user/project/requirements/index.md). `true` when available. |
| `CI_JOB_ID`                       | Jobs only   | 9.0    | all    | The internal ID of the job, unique across all jobs in the GitLab instance. |
| `CI_JOB_IMAGE`                    | Pipeline    | 12.9   | 12.9   | The name of the Docker image running the job. |
| `CI_JOB_JWT` (Deprecated)         | Pipeline    | 12.10  | all    | A RS256 JSON web token to authenticate with third party systems that support JWT authentication, for example [HashiCorp's Vault](../secrets/index.md). [Deprecated in GitLab 15.9](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) and scheduled to be removed in GitLab 17.0. Use [ID tokens](../yaml/index.md#id_tokens) instead. |
| `CI_JOB_JWT_V1` (Deprecated)      | Pipeline    | 14.6   | all    | The same value as `CI_JOB_JWT`. [Deprecated in GitLab 15.9](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) and scheduled to be removed in GitLab 17.0. Use [ID tokens](../yaml/index.md#id_tokens) instead. |
| `CI_JOB_JWT_V2` (Deprecated)      | Pipeline    | 14.6   | all    | A newly formatted RS256 JSON web token to increase compatibility. Similar to `CI_JOB_JWT`, except the issuer (`iss`) claim is changed from `gitlab.com` to `https://gitlab.com`, `sub` has changed from `job_id` to a string that contains the project path, and an `aud` claim is added. The `aud` field is a constant value. Trusting JWTs in multiple relying parties can lead to [one RP sending a JWT to another one and acting maliciously as a job](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72555#note_769112331). [Deprecated in GitLab 15.9](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) and scheduled to be removed in GitLab 17.0. Use [ID tokens](../yaml/index.md#id_tokens) instead. |
| `CI_JOB_MANUAL`                   | Pipeline    | 8.12   | all    | Only available if the job was started manually. `true` when available. |
| `CI_JOB_NAME`                     | Pipeline    | 9.0    | 0.5    | The name of the job. |
| `CI_JOB_NAME_SLUG`                | Pipeline    | 15.4   | all    | `CI_JOB_NAME` in lowercase, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. No leading / trailing `-`. Use in paths. |
| `CI_JOB_STAGE`                    | Pipeline    | 9.0    | 0.5    | The name of the job's stage. |
| `CI_JOB_STATUS`                   | Jobs only   | all    | 13.5   | The status of the job as each runner stage is executed. Use with [`after_script`](../yaml/index.md#after_script). Can be `success`, `failed`, or `canceled`. |
| `CI_JOB_TIMEOUT`                  | Jobs only   | 15.7   | 15.7   | The job timeout, in seconds. |
| `CI_JOB_TOKEN`                    | Jobs only   | 9.0    | 1.2    | A token to authenticate with [certain API endpoints](../jobs/ci_job_token.md). The token is valid as long as the job is running. |
| `CI_JOB_URL`                      | Jobs only   | 11.1   | 0.5    | The job details URL. |
| `CI_JOB_STARTED_AT`               | Jobs only   | 13.10  | all    | The date and time when a job started, in [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) format. For example, `2022-01-31T16:47:55Z`. [UTC by default](../../administration/timezone.md). |
| `CI_KUBERNETES_ACTIVE`            | Pipeline    | 13.0   | all    | Only available if the pipeline has a Kubernetes cluster available for deployments. `true` when available. |
| `CI_NODE_INDEX`                   | Pipeline    | 11.5   | all    | The index of the job in the job set. Only available if the job uses [`parallel`](../yaml/index.md#parallel). |
| `CI_NODE_TOTAL`                   | Pipeline    | 11.5   | all    | The total number of instances of this job running in parallel. Set to `1` if the job does not use [`parallel`](../yaml/index.md#parallel). |
| `CI_OPEN_MERGE_REQUESTS`          | Pipeline    | 13.8   | all    | A comma-separated list of up to four merge requests that use the current branch and project as the merge request source. Only available in branch and merge request pipelines if the branch has an associated merge request. For example, `gitlab-org/gitlab!333,gitlab-org/gitlab-foss!11`. |
| `CI_PAGES_DOMAIN`                 | Pipeline    | 11.8   | all    | The configured domain that hosts GitLab Pages. |
| `CI_PAGES_URL`                    | Pipeline    | 11.8   | all    | The URL for a GitLab Pages site. Always a subdomain of `CI_PAGES_DOMAIN`. |
| `CI_PIPELINE_ID`                  | Jobs only   | 8.10   | all    | The instance-level ID of the current pipeline. This ID is unique across all projects on the GitLab instance. |
| `CI_PIPELINE_IID`                 | Pipeline    | 11.0   | all    | The project-level IID (internal ID) of the current pipeline. This ID is unique only within the current project. |
| `CI_PIPELINE_SOURCE`              | Pipeline    | 10.0   | all    | How the pipeline was triggered. The value can be one of the [pipeline sources](../jobs/job_rules.md#ci_pipeline_source-predefined-variable). |
| `CI_PIPELINE_TRIGGERED`           | Pipeline    | all    | all    | `true` if the job was [triggered](../triggers/index.md). |
| `CI_PIPELINE_URL`                 | Jobs only   | 11.1   | 0.5    | The URL for the pipeline details. |
| `CI_PIPELINE_CREATED_AT`          | Pipeline    | 13.10  | all    | The date and time when the pipeline was created, in [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) format. For example, `2022-01-31T16:47:55Z`. [UTC by default](../../administration/timezone.md). |
| `CI_PIPELINE_NAME`                | Pipeline    | 16.3   | all    | The pipeline name defined in [`workflow:name`](../yaml/index.md#workflowname) |
| `CI_PROJECT_DIR`                  | Jobs only   | all    | all    | The full path the repository is cloned to, and where the job runs from. If the GitLab Runner `builds_dir` parameter is set, this variable is set relative to the value of `builds_dir`. For more information, see the [Advanced GitLab Runner configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_PROJECT_ID`                   | Pipeline    | all    | all    | The ID of the current project. This ID is unique across all projects on the GitLab instance. |
| `CI_PROJECT_NAME`                 | Pipeline    | 8.10   | 0.5    | The name of the directory for the project. For example if the project URL is `gitlab.example.com/group-name/project-1`, `CI_PROJECT_NAME` is `project-1`. |
| `CI_PROJECT_NAMESPACE`            | Pipeline    | 8.10   | 0.5    | The project namespace (username or group name) of the job. |
| `CI_PROJECT_NAMESPACE_ID`         | Pipeline    | 15.7   | 0.5    | The project namespace ID of the job. |
| `CI_PROJECT_PATH_SLUG`            | Pipeline    | 9.3    | all    | `$CI_PROJECT_PATH` in lowercase with characters that are not `a-z` or `0-9` replaced with `-` and shortened to 63 bytes. Use in URLs and domain names. |
| `CI_PROJECT_PATH`                 | Pipeline    | 8.10   | 0.5    | The project namespace with the project name included. |
| `CI_PROJECT_REPOSITORY_LANGUAGES` | Pipeline    | 12.3   | all    | A comma-separated, lowercase list of the languages used in the repository. For example `ruby,javascript,html,css`. The maximum number of languages is limited to 5. An issue [proposes to increase the limit](https://gitlab.com/gitlab-org/gitlab/-/issues/368925). |
| `CI_PROJECT_ROOT_NAMESPACE`       | Pipeline    | 13.2   | 0.5    | The root project namespace (username or group name) of the job. For example, if `CI_PROJECT_NAMESPACE` is `root-group/child-group/grandchild-group`, `CI_PROJECT_ROOT_NAMESPACE` is `root-group`. |
| `CI_PROJECT_TITLE`                | Pipeline    | 12.4   | all    | The human-readable project name as displayed in the GitLab web interface. |
| `CI_PROJECT_DESCRIPTION`          | Pipeline    | 15.1   | all    | The project description as displayed in the GitLab web interface. |
| `CI_PROJECT_URL`                  | Pipeline    | 8.10   | 0.5    | The HTTP(S) address of the project. |
| `CI_PROJECT_VISIBILITY`           | Pipeline    | 10.3   | all    | The project visibility. Can be `internal`, `private`, or `public`. |
| `CI_PROJECT_CLASSIFICATION_LABEL` | Pipeline    | 14.2   | all    | The project [external authorization classification label](../../administration/settings/external_authorization.md). |
| `CI_REGISTRY`                     | Pipeline    | 8.10   | 0.5    | Address of the [container registry](../../user/packages/container_registry/index.md) server, formatted as `<host>[:<port>]`. For example: `registry.gitlab.example.com`. Only available if the container registry is enabled for the GitLab instance. |
| `CI_REGISTRY_IMAGE`               | Pipeline    | 8.10   | 0.5    | Base address for the container registry to push, pull, or tag project's images, formatted as `<host>[:<port>]/<project_full_path>`. For example: `registry.gitlab.example.com/my_group/my_project`. Image names must follow the [container registry naming convention](../../user/packages/container_registry/index.md#naming-convention-for-your-container-images). Only available if the container registry is enabled for the project. |
| `CI_REGISTRY_PASSWORD`            | Jobs only   | 9.0    | all    | The password to push containers to the GitLab project's container registry. Only available if the container registry is enabled for the project. This password value is the same as the `CI_JOB_TOKEN` and is valid only as long as the job is running. Use the `CI_DEPLOY_PASSWORD` for long-lived access to the registry |
| `CI_REGISTRY_USER`                | Jobs only   | 9.0    | all    | The username to push containers to the project's GitLab container registry. Only available if the container registry is enabled for the project. |
| `CI_RELEASE_DESCRIPTION`          | Pipeline    | 15.5   | all    | The description of the release. Available only on pipelines for tags. Description length is limited to first 1024 characters. |
| `CI_REPOSITORY_URL`               | Jobs only   | 9.0    | all    | The full path to Git clone (HTTP) the repository with a [CI/CD job token](../jobs/ci_job_token.md), in the format `https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.example.com/my-group/my-project.git`. |
| `CI_RUNNER_DESCRIPTION`           | Jobs only   | 8.10   | 0.5    | The description of the runner. |
| `CI_RUNNER_EXECUTABLE_ARCH`       | Jobs only   | all    | 10.6   | The OS/architecture of the GitLab Runner executable. Might not be the same as the environment of the executor. |
| `CI_RUNNER_ID`                    | Jobs only   | 8.10   | 0.5    | The unique ID of the runner being used. |
| `CI_RUNNER_REVISION`              | Jobs only   | all    | 10.6   | The revision of the runner running the job. |
| `CI_RUNNER_SHORT_TOKEN`           | Jobs only   | all    | 12.3   | The runner's unique ID, used to authenticate new job requests. The token contains a prefix, and the first 17 characters are used. |
| `CI_RUNNER_TAGS`                  | Jobs only   | 8.10   | 0.5    | A comma-separated list of the runner tags. |
| `CI_RUNNER_VERSION`               | Jobs only   | all    | 10.6   | The version of the GitLab Runner running the job. |
| `CI_SERVER_FQDN`                  | Pipeline    | 16.10  | all    | The fully qualified domain name (FQDN) of the instance. For example `gitlab.example.com:8080`. |
| `CI_SERVER_HOST`                  | Pipeline    | 12.1   | all    | The host of the GitLab instance URL, without protocol or port. For example `gitlab.example.com`. |
| `CI_SERVER_NAME`                  | Pipeline    | all    | all    | The name of CI/CD server that coordinates jobs. |
| `CI_SERVER_PORT`                  | Pipeline    | 12.8   | all    | The port of the GitLab instance URL, without host or protocol. For example `8080`. |
| `CI_SERVER_PROTOCOL`              | Pipeline    | 12.8   | all    | The protocol of the GitLab instance URL, without host or port. For example `https`. |
| `CI_SERVER_SHELL_SSH_HOST`        | Pipeline    | 15.11  | all    | The SSH host of the GitLab instance, used for access to Git repositories via SSH. For example `gitlab.com`. |
| `CI_SERVER_SHELL_SSH_PORT`        | Pipeline    | 15.11  | all    | The SSH port of the GitLab instance, used for access to Git repositories via SSH. For example `22`. |
| `CI_SERVER_REVISION`              | Pipeline    | all    | all    | GitLab revision that schedules jobs. |
| `CI_SERVER_TLS_CA_FILE`           | Pipeline    | all    | all    | File containing the TLS CA certificate to verify the GitLab server when `tls-ca-file` set in [runner settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_SERVER_TLS_CERT_FILE`         | Pipeline    | all    | all    | File containing the TLS certificate to verify the GitLab server when `tls-cert-file` set in [runner settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_SERVER_TLS_KEY_FILE`          | Pipeline    | all    | all    | File containing the TLS key to verify the GitLab server when `tls-key-file` set in [runner settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section). |
| `CI_SERVER_URL`                   | Pipeline    | 12.7   | all    | The base URL of the GitLab instance, including protocol and port. For example `https://gitlab.example.com:8080`. |
| `CI_SERVER_VERSION_MAJOR`         | Pipeline    | 11.4   | all    | The major version of the GitLab instance. For example, if the GitLab version is `13.6.1`, the `CI_SERVER_VERSION_MAJOR` is `13`. |
| `CI_SERVER_VERSION_MINOR`         | Pipeline    | 11.4   | all    | The minor version of the GitLab instance. For example, if the GitLab version is `13.6.1`, the `CI_SERVER_VERSION_MINOR` is `6`. |
| `CI_SERVER_VERSION_PATCH`         | Pipeline    | 11.4   | all    | The patch version of the GitLab instance. For example, if the GitLab version is `13.6.1`, the `CI_SERVER_VERSION_PATCH` is `1`. |
| `CI_SERVER_VERSION`               | Pipeline    | all    | all    | The full version of the GitLab instance. |
| `CI_SERVER`                       | Jobs only   | all    | all    | Available for all jobs executed in CI/CD. `yes` when available. |
| `CI_SHARED_ENVIRONMENT`           | Pipeline    | all    | 10.1   | Only available if the job is executed in a shared environment (something that is persisted across CI/CD invocations, like the `shell` or `ssh` executor). `true` when available. |
| `CI_TEMPLATE_REGISTRY_HOST`       | Pipeline    | 15.3   | all    | The host of the registry used by CI/CD templates. Defaults to `registry.gitlab.com`. |
| `CI_TRIGGER_SHORT_TOKEN`          | Jobs only   | 17.0   | all    | First 4 characters of the [trigger token](../triggers/index.md#create-a-pipeline-trigger-token) of the current job. Only available if the pipeline was [triggered with a trigger token](../triggers/index.md). For example, for a trigger token of `glptt-dbf556605bcad4d9db3ec5fcef84f78f9b4fec28`, `CI_TRIGGER_SHORT_TOKEN` would be `dbf5`. |
| `GITLAB_CI`                       | Pipeline    | all    | all    | Available for all jobs executed in CI/CD. `true` when available. |
| `GITLAB_FEATURES`                 | Pipeline    | 10.6   | all    | The comma-separated list of licensed features available for the GitLab instance and license. |
| `GITLAB_USER_EMAIL`               | Pipeline    | 8.12   | all    | The email of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the email of the user who started the job. |
| `GITLAB_USER_ID`                  | Pipeline    | 8.12   | all    | The numeric ID of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the ID of the user who started the job. |
| `GITLAB_USER_LOGIN`               | Pipeline    | 10.0   | all    | The unique username of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the username of the user who started the job. |
| `GITLAB_USER_NAME`                | Pipeline    | 10.0   | all    | The display name (user-defined **Full name** in the profile settings) of the user who started the pipeline, unless the job is a manual job. In manual jobs, the value is the name of the user who started the job. |
| `KUBECONFIG`                      | Pipeline    | 14.2   | all    | The path to the `kubeconfig` file with contexts for every shared agent connection. Only available when a [GitLab agent is authorized to access the project](../../user/clusters/agent/ci_cd_workflow.md#authorize-the-agent). |
| `TRIGGER_PAYLOAD`                 | Pipeline    | 13.9   | all    | The webhook payload. Only available when a pipeline is [triggered with a webhook](../triggers/index.md#access-webhook-payload). |

## Predefined variables for merge request pipelines

These variables are available when:

- The pipelines [are merge request pipelines](../pipelines/merge_request_pipelines.md).
- The merge request is open.

| Variable                                    | GitLab | Runner | Description |
|---------------------------------------------|--------|--------|-------------|
| `CI_MERGE_REQUEST_APPROVED`                 | 14.1   | all    | Approval status of the merge request. `true` when [merge request approvals](../../user/project/merge_requests/approvals/index.md) is available and the merge request has been approved. |
| `CI_MERGE_REQUEST_ASSIGNEES`                | 11.9   | all    | Comma-separated list of usernames of assignees for the merge request. |
| `CI_MERGE_REQUEST_DIFF_BASE_SHA`            | 13.7   | all    | The base SHA of the merge request diff. |
| `CI_MERGE_REQUEST_DIFF_ID`                  | 13.7   | all    | The version of the merge request diff. |
| `CI_MERGE_REQUEST_EVENT_TYPE`               | 12.3   | all    | The event type of the merge request. Can be `detached`, `merged_result` or `merge_train`. |
| `CI_MERGE_REQUEST_DESCRIPTION`              | 16.7   | all    | The description of the merge request. If the description is more than 2700 characters long, only the first 2700 characters are stored in the variable. |
| `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` | 16.8   | all    | `true` if `CI_MERGE_REQUEST_DESCRIPTION` is truncated down to 2700 characters because the description of the merge request is too long. |
| `CI_MERGE_REQUEST_ID`                       | 11.6   | all    | The instance-level ID of the merge request. This is a unique ID across all projects on the GitLab instance. |
| `CI_MERGE_REQUEST_IID`                      | 11.6   | all    | The project-level IID (internal ID) of the merge request. This ID is unique for the current project, and is the number used in the merge request URL, page title, and other visible locations. |
| `CI_MERGE_REQUEST_LABELS`                   | 11.9   | all    | Comma-separated label names of the merge request. |
| `CI_MERGE_REQUEST_MILESTONE`                | 11.9   | all    | The milestone title of the merge request. |
| `CI_MERGE_REQUEST_PROJECT_ID`               | 11.6   | all    | The ID of the project of the merge request. |
| `CI_MERGE_REQUEST_PROJECT_PATH`             | 11.6   | all    | The path of the project of the merge request. For example `namespace/awesome-project`. |
| `CI_MERGE_REQUEST_PROJECT_URL`              | 11.6   | all    | The URL of the project of the merge request. For example, `http://192.168.10.15:3000/namespace/awesome-project`. |
| `CI_MERGE_REQUEST_REF_PATH`                 | 11.6   | all    | The ref path of the merge request. For example, `refs/merge-requests/1/head`. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`       | 11.6   | all    | The source branch name of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED`  | 16.4   | all    | `true` when the source branch of the merge request is [protected](../../user/project/protected_branches.md). |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`        | 11.9   | all    | The HEAD SHA of the source branch of the merge request. The variable is empty in merge request pipelines. The SHA is present only in [merged results pipelines](../pipelines/merged_results_pipelines.md). |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_ID`        | 11.6   | all    | The ID of the source project of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`      | 11.6   | all    | The path of the source project of the merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_URL`       | 11.6   | all    | The URL of the source project of the merge request. |
| `CI_MERGE_REQUEST_SQUASH_ON_MERGE`          | 16.4   | all    | `true` when the [squash on merge](../../user/project/merge_requests/squash_and_merge.md) option is set. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`       | 11.6   | all    | The target branch name of the merge request. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED`  | 15.2   | all    | `true` when the target branch of the merge request is [protected](../../user/project/protected_branches.md). |
| `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`        | 11.9   | all    | The HEAD SHA of the target branch of the merge request. The variable is empty in merge request pipelines. The SHA is present only in [merged results pipelines](../pipelines/merged_results_pipelines.md). |
| `CI_MERGE_REQUEST_TITLE`                    | 11.9   | all    | The title of the merge request. |

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

## Deployment variables

Integrations that are responsible for deployment configuration can define their own
predefined variables that are set in the build environment. These variables are only defined
for [deployment jobs](../environments/index.md).

For example, the [Kubernetes integration](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)
defines deployment variables that you can use with the integration.

The [documentation for each integration](../../user/project/integrations/index.md)
explains if the integration has any deployment variables available.

## Troubleshooting

You can [output the values of all variables available for a job](index.md#list-all-variables)
with a `script` command.
