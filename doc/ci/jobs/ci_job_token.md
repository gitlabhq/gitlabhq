---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab CI/CD job token

When a pipeline job is about to run, GitLab generates a unique token and injects it as the
[`CI_JOB_TOKEN` predefined variable](../variables/predefined_variables.md).

You can use a GitLab CI/CD job token to authenticate with specific API endpoints:

- Packages:
  - [Package Registry](../../user/packages/package_registry/index.md). To push to the
    Package Registry, you can use [deploy tokens](../../user/project/deploy_tokens/index.md).
  - [Container Registry](../../user/packages/container_registry/index.md)
    (the `$CI_REGISTRY_PASSWORD` is `$CI_JOB_TOKEN`).
  - [Container Registry API](../../api/container_registry.md)
    (scoped to the job's project, when the `ci_job_token_scope` feature flag is enabled).
- [Get job artifacts](../../api/job_artifacts.md#get-job-artifacts).
- [Get job token's job](../../api/jobs.md#get-job-tokens-job).
- [Pipeline triggers](../../api/pipeline_triggers.md), using the `token=` parameter.
- [Release creation](../../api/releases/index.md#create-a-release).
- [Terraform plan](../../user/infrastructure/index.md).

The token has the same permissions to access the API as the user that triggers the
pipeline. Therefore, this user must be assigned to [a role that has the required privileges](../../user/permissions.md#gitlab-cicd-permissions).

The token is valid only while the pipeline job runs. After the job finishes, you can't
use the token anymore.

A job token can access a project's resources without any configuration, but it might
give extra permissions that aren't necessary. There is [a proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559)
to redesign the feature for more strategic control of the access permissions.

You can also use the job token to authenticate and clone a repository from a private project
in a CI/CD job:

```shell
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/<namespace>/<project>
```

## GitLab CI/CD job token security

To make sure that this token doesn't leak, GitLab:

- Masks the job token in job logs.
- Grants permissions to the job token only when the job is running.

To make sure that this token doesn't leak, you should also configure
your [runners](../runners/index.md) to be secure. Avoid:

- Using Docker's `privileged` mode if the machines are re-used.
- Using the [`shell` executor](https://docs.gitlab.com/runner/executors/shell.html) when jobs
  run on the same machine.

If you have an insecure GitLab Runner configuration, you increase the risk that someone
tries to steal tokens from other jobs.

## Limit GitLab CI/CD job token access

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328553) in GitLab 14.1.
> - [Deployed behind a feature flag](../../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-ci-job-token-scope-limit). **(FREE SELF)**

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../../administration/feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

You can limit the access scope of a project's CI/CD job token to increase the
job token's security. A job token might give extra permissions that aren't necessary
to access specific private resources. Limiting the job token access scope reduces the risk of a leaked
token being used to access private data that the user associated to the job can access.

Control the job token access scope with an allowlist of other projects authorized
to be accessed by authenticating with the current project's job token. By default
the token scope only allows access to the same project where the token comes from.
Other projects can be added and removed by maintainers with access to both projects.

This setting is enabled by default for all new projects, and disabled by default in projects
created before GitLab 14.1. It is strongly recommended that project maintainers enable this
setting at all times, and configure the allowlist for cross-project access if needed.

For example, when the setting is enabled, jobs in a pipeline in project `A` have
a `CI_JOB_TOKEN` scope limited to project `A`. If the job needs to use the token
to make an API request to a private project `B`, then `B` must be added to the allowlist for `A`.
If project `B` is public or internal, it doesn't need to be added to the allowlist.
The job token scope is only for controlling access to private projects.

To enable and configure the job token scope limit:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Token Access**.
1. Toggle **Limit CI_JOB_TOKEN access** to enabled.
1. (Optional) Add existing projects to the token's access scope. The user adding a
   project must have the [maintainer role](../../user/permissions.md) in both projects.

If the job token scope limit is disabled, the token can potentially be used to authenticate
API requests to all projects accessible to the user that triggered the job.

There is [a proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559) to improve
the feature with more strategic control of the access permissions.

### Enable or disable CI job token scope limit **(FREE SELF)**

The GitLab CI/CD job token access scope limit is under development and not ready for production
use. It is deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:ci_scoped_job_token)
```

To disable it:

```ruby
Feature.disable(:ci_scoped_job_token)
```

## Trigger a multi-project pipeline by using a CI job token

> `CI_JOB_TOKEN` for multi-project pipelines was [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/31573) from GitLab Premium to GitLab Free in 12.4.

You can use the `CI_JOB_TOKEN` to trigger [multi-project pipelines](../pipelines/multi_project_pipelines.md)
from a CI/CD job. A pipeline triggered this way creates a dependent pipeline relation
that is visible on the [pipeline graph](../pipelines/multi_project_pipelines.md#multi-project-pipeline-visualization).

For example:

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - curl --request POST --form "token=$CI_JOB_TOKEN" --form ref=main "https://gitlab.example.com/api/v4/projects/9/trigger/pipeline"
  rules:
    - if: $CI_COMMIT_TAG
```

If you use the `CI_PIPELINE_SOURCE` [predefined CI/CD variable](../variables/predefined_variables.md)
in a pipeline triggered this way, [the value is `pipeline` (not `triggered`)](../triggers/index.md#authentication-tokens).

## Download an artifact from a different pipeline **(PREMIUM)**

> `CI_JOB_TOKEN` for artifacts download with the API was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2346) in GitLab 9.5.

You can use the `CI_JOB_TOKEN` to access artifacts from a job created by a previous
pipeline. You must specify which job you want to retrieve the artifacts from:

```yaml
build_submodule:
  stage: test
  script:
    - apt update && apt install -y unzip
    - curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"
    - unzip artifacts.zip
```

Read more about the [jobs artifacts API](../../api/job_artifacts.md#download-the-artifacts-archive).
