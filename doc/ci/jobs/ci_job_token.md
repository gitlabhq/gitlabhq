---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD job token
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When a CI/CD pipeline job is about to run, GitLab generates a unique token and makes it available
to the job as the [`CI_JOB_TOKEN` predefined variable](../variables/predefined_variables.md).
The token is valid only while the job is running. After the job finishes, the token access
is revoked and you cannot use the token anymore.

Use a CI/CD job token to authenticate with certain GitLab features from running jobs.
The token receives the same access level as the user that triggered the pipeline,
but has [access to fewer resources](#job-token-access) than a personal access token. A user can cause a job to run
with an action like pushing a commit, triggering a manual job, or being the owner of a scheduled pipeline.
This user must have a [role that has the required privileges](../../user/permissions.md#cicd)
to access the resources.

You can use a job token to authenticate with GitLab to access another group or project's resources (the target project).
By default, the job token's group or project must be [added to the target project's allowlist](#add-a-group-or-project-to-the-job-token-allowlist).

If a project is public or internal, you can access some features without being on the allowlist.
For example, you can fetch artifacts from the project's public pipelines.
This access can also [be restricted](#limit-job-token-scope-for-public-or-internal-projects).

## Job token access

CI/CD job tokens can access the following resources:

| Resource                                                                                              | Notes |
| ----------------------------------------------------------------------------------------------------- | ----- |
| [Container registry](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd) | Used as the `$CI_REGISTRY_PASSWORD` [predefined variable](../variables/predefined_variables.md) to authenticate with the container registry associated with the job's project. |
| [Package registry](../../user/packages/package_registry/_index.md#to-build-packages)                  | Used to authenticate with the registry. |
| [Terraform module registry](../../user/packages/terraform_module_registry/_index.md)                  | Used to authenticate with the registry. |
| [Secure files](../secure_files/_index.md#use-secure-files-in-cicd-jobs)                               | Used by the [`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files) tool to use secure files in jobs. |
| [Container registry API](../../api/container_registry.md)                                             | Can authenticate only with the container registry associated with the job's project. |
| [Deployments API](../../api/deployments.md)                                                           | Can access all endpoints in this API. |
| [Environments API](../../api/environments.md)                                                         | Can access all endpoints in this API. |
| [Jobs API](../../api/jobs.md#get-job-tokens-job)                                                      | Can access only the `GET /job` endpoint. |
| [Job artifacts API](../../api/job_artifacts.md)                                                       | Can access all endpoints in this API. |
| [Packages API](../../api/packages.md)                                                                 | Can access all endpoints in this API. |
| [Pipeline trigger tokens API](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)         | Can access only the `POST /projects/:id/trigger/pipeline` endpoint. |
| [Pipelines API](../../api/pipelines.md#update-pipeline-metadata)                                      | Can access only the `PUT /projects/:id/pipelines/:pipeline_id/metadata` endpoint. |
| [Release links API](../../api/releases/links.md)                                                      | Can access all endpoints in this API. |
| [Releases API](../../api/releases/_index.md)                                                          | Can access all endpoints in this API. |
| [Repositories API](../../api/repositories.md#generate-changelog-data)                                 | Can access only the `GET /projects/:id/repository/changelog` endpoint. |

An open [proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559) exists to make permissions
more granular.

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) in GitLab 15.9. [Deployed behind the `:inbound_ci_scoped_job_token` feature flag](../../user/feature_flags.md), enabled by default.
- [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) in GitLab 15.10.
- **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.
- Adding groups to the job token allowlist [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.0.
- **Token Access** section renamed to **Job token permissions**, and [**Limit access _to_ this project** setting renamed to **Authorized groups and projects**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.
- **Add project** option [renamed to **Add**](https://gitlab.com/gitlab-org/gitlab/-/issues/470880/) in GitLab 17.6.

{{< /history >}}

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

### Auto-populate a project's allowlist

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/478540) in GitLab 17.10.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

You can populate a project's allowlist using the data from the [job token authentication log](#job-token-authentication-log)
with the UI or a Rake task.

In either case, GitLab uses the authentication log to determine which projects or groups to add to the allowlist
and adds those entries for you.

This process creates at most 200 entries in the project's allowlist. If more than 200 entries exist in the authentication log,
it [compacts the allowlist](#allowlist-compaction) to stay under the 200 entry limit.

#### With the UI

{{< history >}}

- Introduced in [GitLab 17.10](https://gitlab.com/gitlab-org/gitlab/-/issues/498125).

{{< /history >}}

To auto-populate the allowlist through the UI:

1. On the left sidebar, select **Search or go** to and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**.
1. Select **Add** and choose **All projects in authentication log** from the dropdown list.
1. A dialog asks you to confirm the action, select **Add entries**.

After the process completes, the allowlist contains the entries from the authentication log.
If not already set, the **Authorized groups and projects** is set to **Only this project and any groups and projects in the allowlist**.

#### With a Rake task

GitLab administrators with [rails console access](../../administration/operations/rails_console.md)
can run a Rake task to auto-populate the allowlist for all or a subset of projects on an instance.
This task also sets the **Authorized groups and projects** setting to **Only this project and any groups and projects in the allowlist**.

The `ci:job_tokens:allowlist:autopopulate_and_enforce` Rake task has the following configuration options:

- `PREVIEW`: Do a dry run and output the steps that would have been taken, but do not change any data.
- `ONLY_PROJECT_IDS`: Do the migration for only the supplied project IDs (maximum of 1000 IDs).
- `EXCLUDE_PROJECT_IDS`: Do the migration for all projects on the instance, except
  for the supplied project IDs (maximum of 1000 IDs).

`ONLY_PROJECT_IDS` and `EXCLUDE_PROJECT_IDS` cannot be used at the same time.

For example:

- `ci:job_tokens:allowlist:autopopulate_and_enforce PREVIEW=true`
- `ci:job_tokens:allowlist:autopopulate_and_enforce PREVIEW=true ONLY_PROJECT_IDS=2,3`
- `ci:job_tokens:allowlist:autopopulate_and_enforce PREVIEW=true EXCLUDE_PROJECT_IDS=2,3`
- `ci:job_tokens:allowlist:autopopulate_and_enforce`
- `ci:job_tokens:allowlist:autopopulate_and_enforce ONLY_PROJECT_IDS=2,3`
- `ci:job_tokens:allowlist:autopopulate_and_enforce EXCLUDE_PROJECT_IDS=2,3`

To run the Rake task for:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake ci:job_tokens:allowlist:autopopulate_and_enforce
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo -u git -H bundle exec rake ci:job_tokens:allowlist:autopopulate_and_enforce
```

{{< /tab >}}

{{< /tabs >}}

#### Allowlist compaction

The allowlist compaction algorithm:

1. Scans the authorization log to identify the nearest common groups for projects.
1. Consolidates multiple project-level entries into single group-level entries.
1. Updates the allowlist with these consolidated entries.

For example, with an allowlist similar to:

```plaintext
group1/group2/group3/project1
group1/group2/group3/project2
group1/group2/group4/project3
group1/group2/group4/project4
group1/group5/group6/project5
```

The compaction algorithm:

1. Compacts the list to:

   ```plaintext
   group1/group2/group3
   group1/group2/group4
   group1/group2/group6
   ```

1. If the allowlist is over the 200 entry limit, the algorithm compacts again:

   ```plaintext
   group1/group2
   group1/group5
   ```

1. If the allowlist is still over the 200 entry limit, the algorithm continues:

   ```plaintext
   group1
   ```

This process is performed until the number of allowlist entries is 200 or fewer.

### Limit job token scope for public or internal projects

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/405369) in GitLab 16.6.

{{< /history >}}

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

{{< history >}}

- **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.
- **Token Access** section renamed to **Job token permissions**, and [**Limit access _to_ this project** setting renamed to **Authorized groups and projects**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.

{{< /history >}}

{{< alert type="warning" >}}

It is a security risk to disable the token access limit and allowlist. A malicious user could try to compromise
a pipeline created in an unauthorized project. If the pipeline was created by one of
your maintainers, the job token could be used in an attempt to access your project.

{{< /alert >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) in GitLab 17.2. [with a flag](../../administration/feature_flags.md) named `allow_push_repository_for_job_token`. Disabled by default.
- **Token Access** section renamed to **Job token permissions**, and [**Limit access _to_ this project** setting renamed to **Authorized groups and projects**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

{{< alert type="warning" >}}

Pushing to the project repository by authenticating with a CI/CD job token is still in development
and not yet optimized for performance. If you enable this feature for testing, you must
thoroughly test and implement validation measures to prevent infinite loops of "push" pipelines
triggering more pipelines.

{{< /alert >}}

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

## Fine-grained permissions for job tokens

Fine-grained permissions for job tokens are an [experiment](../../policy/development_stages_support.md#experiment). For information on this feature and the available resources, see [Fine-grained permissions for CI/CD job tokens](fine_grained_permissions.md). Feedback is welcome on this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/519575).

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

{{< alert type="note" >}}

The [**Limit access _from_ this project**](#configure-the-job-token-scope-deprecated)
setting is disabled by default for all new projects and is [scheduled for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/383084)
in GitLab 17.0. Project maintainers or owners should configure the [**Limit access _to_ this project**](#add-a-group-or-project-to-the-job-token-allowlist)
setting instead.

{{< /alert >}}

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

{{< history >}}

- **Limit CI_JOB_TOKEN access** setting [renamed to **Limit access _from_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.
- **Token Access** setting [renamed to **Job token permissions**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) in GitLab 17.2.

{{< /history >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/467292/) in GitLab 17.6.

{{< /history >}}

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

## Use legacy format for CI/CD tokens

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/514860) in GitLab 17.10.

{{< /history >}}

Beginning in GitLab 18.0, CI/CD job tokens use the JWT standard by default. All new projects created after February 21, 2025 on GitLab.com or from 17.10 on GitLab Self-Managed use this standard. Existing projects can continue to use the legacy format by configuring the top-level group for their project. This setting is only available until the GitLab 18.3 release.

To use the legacy format for your CI/CD tokens:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Turn off **Enable JWT format for CI/CD job tokens**.

Your CI/CD tokens now use the legacy format. If you want to use the JWT format again later, you can re-enable this setting.

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

### JWT format job token errors

There are some known issues with the JWT format for CI/CD job tokens.

#### `Error when persisting the task ARN.` error with EC2 Fargate Runner custom executor

There is [a bug](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/fargate/-/issues/86)
in version `0.5.0` and earlier of the EC2 Fargate custom executor. This issue causes this error:

- `Error when persisting the task ARN. Will stop the task for cleanup`

To fix this issue, upgrade to version `0.5.1` or later of the Fargate custom executor.

#### `invalid character '\n' in string literal` error with `base64` encoding

If you use `base64` to encode job tokens, you could receive an `invalid character '\n'` error.

The default behavior of the `base64` command wraps strings that are longer than 79 characters.
When `base64` encoding JWT format job tokens during job execution, for example with
`echo $CI_JOB_TOKEN | base64`, the token is rendered invalid.

To fix this issue, use `base64 -w0` to disable automatically wrapping the token.
