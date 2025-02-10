---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD job token
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When a CI/CD pipeline job is about to run, GitLab generates a unique token and makes it available
to the job as the [`CI_JOB_TOKEN` predefined variable](../variables/predefined_variables.md).
The token is valid only while the job is running. After the job finishes, the token access
is revoked and you cannot use the token anymore.

Use a CI/CD job token to authenticate with certain GitLab features from running jobs.
The token receives the same access level as the user that triggered the pipeline,
but has [access to fewer resources](#job-token-feature-access) than a personal access token. A user can cause a job to run
with an action like pushing a commit, triggering a manual job, or being the owner of a scheduled pipeline.
This user must have a [role that has the required privileges](../../user/permissions.md#cicd)
to access the resources.

You can use a job token to authenticate with GitLab to access another group or project's resources (the target project).
By default, the job token's group or project must be [added to the target project's allowlist](#add-a-group-or-project-to-the-job-token-allowlist).

If a project is public or internal, you can access some features without being on the allowlist.
For example, you can fetch artifacts from the project's public pipelines.
This access can also [be restricted](#limit-job-token-scope-for-public-or-internal-projects).

## Job token feature access

The CI/CD job token can only access the following features and API endpoints:

| Feature                                                                                               | Additional details |
|-------------------------------------------------------------------------------------------------------|--------------------|
| [Container registry API](../../api/container_registry.md)                                             | The token is scoped to the container registry of the job's project only. |
| [Container registry](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd) | The `$CI_REGISTRY_PASSWORD` [predefined variable](../variables/predefined_variables.md) is the CI/CD job token. Both are scoped to the container registry of the job's project only. |
| [Deployments API](../../api/deployments.md)                                                           | `GET` requests are public by default. |
| [Environments API](../../api/environments.md)                                                         | `GET` requests are public by default. |
| [Job artifacts API](../../api/job_artifacts.md#get-job-artifacts)                                     | `GET` requests are public by default. |
| [API endpoint to get the job of a job token](../../api/jobs.md#get-job-tokens-job)                    | To get the job token's job. |
| [Package registry](../../user/packages/package_registry/_index.md#to-build-packages)                   |         |
| [Packages API](../../api/packages.md)                                                                 | `GET` requests are public by default. |
| [Pipeline triggers](../../api/pipeline_triggers.md)                                                   | Used with the `token=` parameter to [trigger a multi-project pipeline](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api). |
| [Update pipeline metadata API endpoint](../../api/pipelines.md#update-pipeline-metadata)              | To update pipeline metadata. |
| [Release links API](../../api/releases/links.md)                                                      |         |
| [Releases API](../../api/releases/_index.md)                                                           | `GET` requests are public by default. |
| [Repositories API](../../api/repositories.md#generate-changelog-data)                                 | Generates changelog data based on commits in a repository. |
| [Secure files](../secure_files/_index.md#use-secure-files-in-cicd-jobs)                                | The `download-secure-files` tool authenticates with a CI/CD job token by default. |
| [Terraform plan](../../user/infrastructure/_index.md)                                                  |         |

Other API endpoints are not accessible using a job token. There is [a proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559)
to redesign the feature for more granular control of access permissions.

## GitLab CI/CD job token security

If a job token is leaked, it could potentially be used to access private data accessible
to the user that triggered the CI/CD job. To help prevent leaking or misuse of this token,
GitLab:

- Masks the job token in job logs.
- Grants permissions to the job token only when the job is running.

You should also configure your [runners](../runners/_index.md) to be secure:

- Avoid using Docker `privileged` mode if the machines are re-used.
- Avoid using the [`shell` executor](https://docs.gitlab.com/runner/executors/shell.html) when jobs
  run on the same machine.

An insecure GitLab Runner configuration increases the risk that someone can steal tokens from other
jobs.

## Control job token access to your project

You can control which groups or projects can use a job token to authenticate and access some of your project's resources.

By default, job token access is restricted to only CI/CD jobs that run in pipelines in
your project. To allow another group or project to authenticate with a job token from the other
project's pipeline:

- You must [add the group or project to the job token allowlist](#add-a-group-or-project-to-the-job-token-allowlist).
- The user that triggers the job must be a member of your project.
- The user must have the [permissions](../../user/permissions.md) to perform the action.

If your project is public or internal, some publicly accessible resources can be accessed
with a job token from any project. These resources can also be [limited to only projects on the allowlist](#limit-job-token-scope-for-public-or-internal-projects).

GitLab Self-Managed administrators can [override and enforce this setting](../../administration/settings/continuous_integration.md#job-token-permissions).
When the setting is enforced, the CI/CD job token is always restricted to the project's allowlist.

### Add a group or project to the job token allowlist

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) in GitLab 15.9. [Deployed behind the `:inbound_ci_scoped_job_token` feature flag](../../user/feature_flags.md), enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) in GitLab 15.10.
> - **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.
> - Adding groups to the job token allowlist [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.0.
> - **Token Access** section renamed to **Job token permissions**, and [**Limit access _to_ this project** setting renamed to **Authorized groups and projects**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.
> - **Add project** option [renamed to **Add**](https://gitlab.com/gitlab-org/gitlab/-/issues/470880/) in GitLab 17.6.

You can add groups or projects to your job token allowlist to allow access to your project's resources
with a job token for authentication. By default, the allowlist of any project only includes itself.
Add groups or projects to the allowlist only when cross-project access is needed.

Adding a project to the allowlist does not give additional [permissions](../../user/permissions.md)
to the members of the allowlisted project. They must already have permissions to access the resources
in your project to use a job token from the allowlisted project to access your project.

For example, project A can add project B to project A's allowlist. CI/CD jobs
in project B (the "allowed project") can now use CI/CD job tokens to
authenticate API calls to access project A.

Prerequisites:

- You must have at least the Maintainer role for the current project. If the allowed project
  is internal or private, you must have at least the Guest role in that project.
- You must not have more than 200 groups and projects added to the allowlist.

To add a group or project to the allowlist:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**.
1. Ensure the **Authorized groups and projects** toggle is enabled. Enabled by default in new projects.
   It is a [security risk to disable this feature](#allow-any-project-to-access-your-project),
   so project maintainers or owners should keep this setting enabled at all times.
1. Select **Add group or project**.
1. Input the path to the group or project to add to the allowlist, and select **Add**.

You can also add a group or project to the allowlist [with the API](../../api/graphql/reference/_index.md#mutationcijobtokenscopeaddgrouporproject).

### Limit job token scope for public or internal projects

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/405369) in GitLab 16.6.

Projects not in the allowlist can use a job token to authenticate with public or internal projects to:

- Fetch artifacts.
- Access the container registry.
- Access the package registry.
- Access releases, deployments, and environments.

You can limit access to these actions to only the projects on the allowlist by setting
each feature to be only visible to project members.

Prerequisites:

- You must have the Maintainer role for the project.

To set a feature to be only visible to project members:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Set the visibility to **Only project members** for the features you want to restrict access to.
   - The ability to fetch artifacts is controlled by the CI/CD visibility setting.
1. Select **Save changes**.

### Allow any project to access your project

> - **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.
> - **Token Access** section renamed to **Job token permissions**, and [**Limit access _to_ this project** setting renamed to **Authorized groups and projects**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.

WARNING:
It is a security risk to disable the token access limit and allowlist. A malicious user could try to compromise
a pipeline created in an unauthorized project. If the pipeline was created by one of
your maintainers, the job token could be used in an attempt to access your project.

If you disable the **Limit access _to_ this project** setting, the allowlist is ignored.
Jobs from any project could access your project with a job token if the user that
triggers the pipeline has permission to access your project.

You should only disable this setting for testing or a similar reason,
and you should enable it again as soon as possible.

Prerequisites:

- You must have at least the Maintainer role for the project.

To disable the job token scope allowlist:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**.
1. Toggle **Authorized groups and projects** to disabled.
   Enabled by default in new projects.

You can also enable and disable the setting with the [GraphQL](../../api/graphql/reference/_index.md#mutationprojectcicdsettingsupdate) (`inboundJobTokenScopeEnabled`) and [REST](../../api/project_job_token_scopes.md#patch-a-projects-cicd-job-token-access-settings) API.

### Allow Git push requests to your project repository

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) in GitLab 17.2. [with a flag](../../administration/feature_flags.md) named `allow_push_repository_for_job_token`. Disabled by default.
> - **Token Access** section renamed to **Job token permissions**, and [**Limit access _to_ this project** setting renamed to **Authorized groups and projects**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

WARNING:
Pushing to the project repository by authenticating with a CI/CD job token is still in development
and not yet optimized for performance. If you enable this feature for testing, you must
thoroughly test and implement validation measures to prevent infinite loops of "push" pipelines
triggering more pipelines.

You can allow Git push requests to your project repository that are authenticated
with a CI/CD job token. When enabled, access is allowed only for the tokens generated
in CI/CD jobs that run in pipelines in your project. This permission is disabled by default.

Prerequisites:

- You must have at least the Maintainer role for the project.

To grant permission to job tokens generated in your project to push to the project's repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**.
1. In the **Permissions** section, select **Allow Git push requests to the repository**.

The job token has the same access permissions as the user that started the job.
Job tokens from other [projects or groups in the allowlist](#add-a-group-or-project-to-the-job-token-allowlist)
cannot push to the repository in your project.

You can also control this setting with the [`ci_push_repository_for_job_token_allowed`](../../api/projects.md#edit-a-project)
parameter in the `projects` REST API endpoint.

## Use a job token

### To `git clone` a private project's repository

You can use the job token to authenticate and clone a repository from a private project
in a CI/CD job. Use `gitlab-ci-token` as the user, and the value of the job token as the password. For example:

```shell
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/<namespace>/<project>
```

You can use this job token to clone a repository even if the HTTPS protocol is [disabled by group, project, or instance settings](../../administration/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols). You cannot use a job token to push to a repository, but [issue 389060](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)
proposes to change this behavior.

### To authenticate a REST API request

You can use a job token to authenticate requests for allowed REST API endpoints. For example:

```shell
curl --verbose --request POST --form "token=$CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"
```

Additionally, there are multiple valid methods for passing the job token in the request:

- `--form "token=$CI_JOB_TOKEN"`
- `--header "JOB-TOKEN: $CI_JOB_TOKEN"`
- `--data "job_token=$CI_JOB_TOKEN"`

## Limit your project's job token access (deprecated)

NOTE:
The [**Limit access _from_ this project**](#configure-the-job-token-scope-deprecated)
setting is disabled by default for all new projects and is [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/383084)
in GitLab 17.0. Project maintainers or owners should configure the [**Limit access _to_ this project**](#add-a-group-or-project-to-the-job-token-allowlist)
setting instead.

Control your project's job token scope by creating an allowlist of projects which
can be accessed by your project's job token.

By default, the allowlist includes your current project.
Other projects can be added and removed by maintainers with access to both projects.

With the setting disabled, all projects are considered in the allowlist and the job token is
limited only by the user's access permissions.

For example, when the setting is enabled, jobs in a pipeline in project `A` have
a `CI_JOB_TOKEN` scope limited to project `A`. If the job needs to use the token
to make an API request to project `B`, then `B` must be added to the allowlist for `A`.

### Configure the job token scope (deprecated)

> - **Limit CI_JOB_TOKEN access** setting [renamed to **Limit access _from_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.
> - **Token Access** setting [renamed to **Job token permissions**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.

Prerequisites:

- You must not have more than 200 projects added to the token's scope.

To configure the job token scope:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**.
1. Toggle **Limit access _from_ this project** to enabled.
1. Optional. Add existing projects to the token's access scope. The user adding a
   project must have the Maintainer role in both projects.

## Job token authentication log

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/467292/) in GitLab 17.6.

You can track which other projects use a CI/CD job token to authenticate with your project
in an authentication log. To check the log:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**. The **Authentication log** section displays the
   list of other projects that accessed your project by authenticating with a job token.
1. Optional. Select **Download CSV** to download the full authentication log in CSV format.

The authentication log displays a maximum of 100 authentication events. If the number of events
is more than 100, download the CSV file to view the log.

New authentications to a project can take up to 5 minutes to appear in the authentication log.

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
