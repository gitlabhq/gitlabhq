---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab CI/CD job token **(FREE ALL)**

When a pipeline job is about to run, GitLab generates a unique token and injects it as the
[`CI_JOB_TOKEN` predefined variable](../variables/predefined_variables.md).

You can use a GitLab CI/CD job token to authenticate with specific API endpoints:

- Packages:
  - [Package registry](../../user/packages/package_registry/index.md#to-build-packages).
  - [Packages API](../../api/packages.md) (project-level).
  - [Container registry](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd)
    (the `$CI_REGISTRY_PASSWORD` is `$CI_JOB_TOKEN`).
  - [Container registry API](../../api/container_registry.md)
    (scoped to the job's project).
- [Get job artifacts](../../api/job_artifacts.md#get-job-artifacts).
- [Get job token's job](../../api/jobs.md#get-job-tokens-job).
- [Pipeline triggers](../../api/pipeline_triggers.md), using the `token=` parameter
  to [trigger a multi-project pipeline](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api).
- [Update pipeline metadata](../../api/pipelines.md#update-pipeline-metadata)
- [Releases](../../api/releases/index.md) and [Release links](../../api/releases/links.md).
- [Terraform plan](../../user/infrastructure/index.md).
- [Deployments](../../api/deployments.md).
- [Environments](../../api/environments.md).

The token has the same permissions to access the API as the user that caused the
job to run. A user can cause a job to run by taking action like pushing a commit,
triggering a manual job, or being the owner of a scheduled pipeline. Therefore, this user must be assigned to
[a role that has the required privileges](../../user/permissions.md#gitlab-cicd-permissions).

The token is valid only while the pipeline job runs. After the job finishes, you cannot
use the token anymore.

A job token can access a project's resources without any configuration, but it might
give extra permissions that aren't necessary. There is [a proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559)
to redesign the feature for more strategic control of the access permissions.

You can also use the job token to authenticate and clone a repository from a private project
in a CI/CD job:

```shell
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/<namespace>/<project>
```

You can't use a job token to push to a repository, but [issue 389060](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) proposes to change this behavior.

## GitLab CI/CD job token security

To make sure that this token doesn't leak, GitLab:

- Masks the job token in job logs.
- Grants permissions to the job token only when the job is running.

To make sure that this token doesn't leak, you should also configure
your [runners](../runners/index.md) to be secure. Avoid:

- Using Docker `privileged` mode if the machines are re-used.
- Using the [`shell` executor](https://docs.gitlab.com/runner/executors/shell.html) when jobs
  run on the same machine.

If you have an insecure GitLab Runner configuration, you increase the risk that someone
tries to steal tokens from other jobs.

## Configure CI/CD job token access

You can control what projects a CI/CD job token can access to increase the
job token's security. A job token might give extra permissions that aren't necessary
to access specific private resources.

When enabled, and the job token is being used to access a different project:

- The user that executes the job must be a member of the project that is being accessed.
- The user must have the [permissions](../../user/permissions.md) to perform the action.
- The accessed project must have the project attempting to access it [added to the allowlist](#add-a-project-to-the-job-token-scope-allowlist).

If a job token is leaked, it could potentially be used to access private data
to the job token's user. By limiting the job token access scope, project data cannot
be accessed unless projects are explicitly authorized.

There is a proposal to add more strategic control of the access permissions,
see [epic 3559](https://gitlab.com/groups/gitlab-org/-/epics/3559).

NOTE:
Because `CI_REGISTRY_TOKEN` uses `CI_JOB_TOKEN` to authenticate, the access configuration
also applies to `CI_REGISTRY_TOKEN`.

### Allow access to your project with a job token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) in GitLab 15.9. [Deployed behind the `:inbound_ci_scoped_job_token` feature flag](../../user/feature_flags.md), enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) in GitLab 15.10.

Create an allowlist of projects which can access your project through
their `CI_JOB_TOKEN`.

For example, project `A` can add project `B` to the allowlist. CI/CD jobs
in project `B` (the "allowed project") can now use their CI/CD job token to
authenticate API calls to access project `A`.

By default, the allowlist of any project only includes itself.

It is a security risk to disable this feature, so project maintainers or owners should
keep this setting enabled at all times. Add projects to the allowlist only when cross-project
access is needed.

### Limit job token scope for public or internal projects

Projects can use a job token to authenticate with public or internal projects for
the following actions without being added to the allowlist:

- Fetch artifacts
- Access the container registry
- Access the package registry
- Access releases, deployments, and environments

To limit access to these actions to only the projects on the allowlist, set the visibility
of each feature to be only accessible to project members:

Prerequisites:

- You must have the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Set the visibility to **Only project members** for the features you want to restrict access to.
   - The ability to fetch artifacts is controlled by the CI/CD visibility setting.
1. Select **Save changes**.

Triggering pipelines and fetching Terraform plans is not affected by feature visibility.

### Disable the job token scope allowlist

> **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.

WARNING:
It is a security risk to disable the allowlist. A malicious user could try to compromise
a pipeline created in an unauthorized project. If the pipeline was created by one of
your maintainers, the job token could be used in an attempt to access your project.

You can disable the job token scope allowlist for testing or a similar reason,
but you should enable it again as soon as possible.

Prerequisites:

- You must have at least the Maintainer role for the project.

To disable the job token scope allowlist:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Token Access**.
1. Toggle **Limit access _to_ this project** to disabled.
   Enabled by default in new projects.

You can also disable the allowlist [with the API](../../api/graphql/reference/index.md#mutationprojectcicdsettingsupdate).

### Add a project to the job token scope allowlist

> **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.

You can add projects to the allowlist for a project. Projects added to the allowlist
can make API calls from running pipelines by using the CI/CD job token.

Prerequisites:

- You must have at least the Maintainer role in the current project. If the allowed project
  is internal or private, you must have at least the Guest role in that project.
- You must not have more than 200 projects added to the allowlist.

To add a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Token Access**.
1. Verify **Limit access _to_ this project** is enabled.
1. Under **Allow CI job tokens from the following projects to access this project**,
   add projects to the allowlist.

You can also add a target project to the allowlist [with the API](../../api/graphql/reference/index.md#mutationcijobtokenscopeaddproject).

### Limit your project's job token access

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328553) in GitLab 14.1. [Deployed behind the `:ci_scoped_job_token` feature flag](../../user/feature_flags.md), disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/332272) in GitLab 14.4.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/332272) in GitLab 14.6.

NOTE:
This feature is disabled by default for all new projects and is [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/383084)
in GitLab 17.0. Project maintainers or owners should enable the access control instead.

Control your project's job token scope by creating an allowlist of projects which
can be accessed by your project's job token.

By default, the allowlist includes your current project.
Other projects can be added and removed by maintainers with access to both projects.

With the setting disabled, all projects are considered in the allowlist and the job token is
limited only by the user's access permissions.

For example, when the setting is enabled, jobs in a pipeline in project `A` have
a `CI_JOB_TOKEN` scope limited to project `A`. If the job needs to use the token
to make an API request to project `B`, then `B` must be added to the allowlist for `A`.

### Configure the job token scope

> **Limit CI_JOB_TOKEN access** setting [renamed to **Limit access _from_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.

Prerequisites:

- You must not have more than 200 projects added to the token's scope.

To configure the job token scope:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Token Access**.
1. Toggle **Limit access _from_ this project** to enabled.
1. Optional. Add existing projects to the token's access scope. The user adding a
   project must have the Maintainer role in both projects.

## Download an artifact from a different pipeline **(PREMIUM ALL)**

You can use the CI/CD job token to authenticate with the [jobs artifacts API endpoint](../../api/job_artifacts.md)
and fetch artifacts from a different pipeline. You must specify which job to retrieve artifacts from:

```yaml
build_submodule:
  stage: test
  script:
    - apt update && apt install -y unzip
    - curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"
    - unzip artifacts.zip
```

## Troubleshooting

CI job token failures are usually shown as responses like `404 Not Found` or similar:

- Unauthorized Git clone:

  ```plaintext
  $ git clone https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.com/fabiopitino/test2.git

  Cloning into 'test2'...
  remote: The project you were looking for could not be found or you don't have permission to view it.
  fatal: repository 'https://gitlab-ci-token:[MASKED]@gitlab.com/<namespace>/<project>.git/' not found
  ```

- Unauthorized package download:

  ```plaintext
  $ wget --header="JOB-TOKEN: $CI_JOB_TOKEN" ${CI_API_V4_URL}/projects/1234/packages/generic/my_package/0.0.1/file.txt

  --2021-09-23 11:00:13--  https://gitlab.com/api/v4/projects/1234/packages/generic/my_package/0.0.1/file.txt
  Resolving gitlab.com (gitlab.com)... 172.65.251.78, 2606:4700:90:0:f22e:fbec:5bed:a9b9
  Connecting to gitlab.com (gitlab.com)|172.65.251.78|:443... connected.
  HTTP request sent, awaiting response... 404 Not Found
  2021-09-23 11:00:13 ERROR 404: Not Found.
  ```

- Unauthorized API request:

  ```plaintext
  $ curl --verbose --request POST --form "token=$CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"

  < HTTP/2 404
  < date: Thu, 23 Sep 2021 11:00:12 GMT
  {"message":"404 Not Found"}
  < content-type: application/json
  ```

While troubleshooting CI/CD job token authentication issues, be aware that:

- A [GraphQL example mutation](../../api/graphql/getting_started.md#update-project-settings)
  is available to toggle the scope settings per project.
- [This comment](https://gitlab.com/gitlab-org/gitlab/-/issues/351740#note_1335673157)
  demonstrates how to use GraphQL with Bash and cURL to:
  - Enable the inbound token access scope.
  - Give access to project B from project A, or add B to A's allowlist.
  - To remove project access.
- The CI job token becomes invalid if the job is no longer running, has been erased,
  or if the project is in the process of being deleted.
