---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Job artifacts
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Jobs can output an archive of files and directories. This output is known as a job artifact.

You can download job artifacts by using the GitLab UI or the [API](../../api/job_artifacts.md#get-job-artifacts).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of job artifacts, watch the video [GitLab CI pipelines, artifacts, and environments](https://www.youtube.com/watch?v=PCKDICEe10s).
Or, for an introduction, watch [GitLab CI pipeline tutorial for beginners](https://www.youtube.com/watch?v=Jav4vbUrqII).

For administrator information about job artifact storage, see [administering job artifacts](../../administration/cicd/job_artifacts.md).

## Create job artifacts

To create job artifacts, use the [`artifacts`](../yaml/_index.md#artifacts) keyword in your `.gitlab-ci.yml` file:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
```

In this example, a job named `pdf` calls the `xelatex` command to build a PDF file from the
LaTeX source file, `mycv.tex`.

The [`paths`](../yaml/_index.md#artifactspaths) keyword determines which files to add to the job artifacts.
All paths to files and directories are relative to the repository where the job was created.

### With wildcards

You can use wildcards for paths and directories. For example, to create an artifact
with all the files inside the directories that end with `xyz`:

```yaml
job:
  script: echo "build xyz project"
  artifacts:
    paths:
      - path/*xyz/*
```

### With an expiry

The [`expire_in`](../yaml/_index.md#artifactsexpire_in) keyword determines how long
GitLab keeps the artifacts defined in `artifacts:paths`. For example:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

If `expire_in` is not defined, the [instance-wide setting](../../administration/settings/continuous_integration.md#default-artifacts-expiration)
is used.

To prevent artifacts from expiring, you can select **Keep** from the job details page.
The option is not available when an artifact has no expiry set.

By default, the [latest artifacts are always kept](#keep-artifacts-from-most-recent-successful-jobs).

### With an explicitly defined artifact name

You can explicitly customize artifact names using the [`artifacts:name`](../yaml/_index.md#artifactsname) configuration:

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

### Without excluded files

Use [`artifacts:exclude`](../yaml/_index.md#artifactsexclude) to prevent files from
being added to an artifacts archive.

For example, to store all files in `binaries/`, but not `*.o` files located in
subdirectories of `binaries/`.

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

Unlike [`artifacts:paths`](../yaml/_index.md#artifactspaths), `exclude` paths are not recursive.
To exclude all of the contents of a directory, match them explicitly rather
than matching the directory itself.

For example, to store all files in `binaries/` but nothing located in the `temp/` subdirectory:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/temp/**/*
```

### With untracked files

Use [`artifacts:untracked`](../yaml/_index.md#artifactsuntracked) to add all Git untracked
files as artifacts (along with the paths defined in [`artifacts:paths`](../yaml/_index.md#artifactspaths)). Untracked
files are those that haven't been added to the repository but exist in the repository checkout.

For example, to save all Git untracked files and files in `binaries`:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

For example, to save all untracked files but [exclude](../yaml/_index.md#artifactsexclude) `*.txt` files:

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

### With variable expansion

Variable expansion is supported for:

- [`artifacts:name`](../yaml/_index.md#artifactsname)
- [`artifacts:paths`](../yaml/_index.md#artifactspaths)
- [`artifacts:exclude`](../yaml/_index.md#artifactsexclude)

Instead of using shell, GitLab Runner uses its
[internal variable expansion mechanism](../variables/where_variables_can_be_used.md#gitlab-runner-internal-variable-expansion-mechanism).
Only [CI/CD variables](../variables/_index.md) are supported in this context.

For example, to create an archive using the current branch or tag name
including only files from a directory named after the current project:

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/${CI_PROJECT_NAME}/"
```

When your branch name contains forward slashes (for example, `feature/my-feature`),
use `$CI_COMMIT_REF_SLUG` instead of `$CI_COMMIT_REF_NAME` to ensure proper artifact naming.

Variables are expanded before [globs](https://en.wikipedia.org/wiki/Glob_(programming)).

## Fetching artifacts

By default, jobs fetch all artifacts from jobs defined in previous stages. These artifacts are downloaded into the job's working directory.

You can control which artifacts to download by using these keywords:

- [`dependencies`](../yaml/_index.md#dependencies): Specify which jobs to download artifacts from.
- [`needs`](../yaml/_index.md#needs): Define relationships between jobs and specify which artifacts to download.

When you use these keywords, the default behavior changes and artifacts are fetched from only the jobs you specify.

### Prevent a job from fetching artifacts

To prevent a job from downloading any artifacts, set
[`dependencies`](../yaml/_index.md#dependencies) to an empty array
(`[]`):

```yaml
job:
  stage: test
  script: make build
  dependencies: []
```

## View all job artifacts in a project

> - Interface improvements [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33418) in GitLab 15.6.
> - Performance improvements [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387765) in GitLab 15.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/407475) in GitLab 16.0. Feature flag `artifacts_management_page` removed.

You can view all artifacts stored in a project from the **Build > Artifacts** page.
This list displays all jobs and their associated artifacts. Expand an entry to access
all artifacts associated with a job, including:

- Artifacts created with the `artifacts:` keyword.
- [Report artifacts](../yaml/artifacts_reports.md).
- Job logs and metadata, which are stored internally as separate artifacts.

You can download or delete individual artifacts from this list.

## Download job artifacts

You can download job artifacts from:

- Any **Pipelines** list. On the right of the pipeline, select **Download artifacts** (**{download}**).
- Any **Jobs** list. On the right of the job, select **Download artifacts** (**{download}**).
- A job's detail page. On the right of the page, select **Download**.
- A merge request **Overview** page. On the right of the latest pipeline, select **Artifacts** (**{download}**).
- The [**Artifacts**](#view-all-job-artifacts-in-a-project) page. On the right of the job, select **Download** (**{download}**).
- The [artifacts browser](#browse-the-contents-of-the-artifacts-archive). On the top of the page,
  select **Download artifacts archive** (**{download}**).

[Report artifacts](../yaml/artifacts_reports.md) can only be downloaded from the **Pipelines** list
or **Artifacts** page.

You can download job artifacts from the latest successful pipeline by using [the job artifacts API](../../api/job_artifacts.md).
You cannot download [artifact reports](../yaml/artifacts_reports.md) with the job artifacts API,
unless the report is added as a regular artifact with `artifacts:paths`.

### From a URL

You can download the artifacts archive for a specific job with a publicly accessible
URL for the [job artifacts API](../../api/job_artifacts.md#download-the-artifacts-archive).

For example:

- To download the latest artifacts of a job named `build` in the `main` branch of a project on GitLab.com:

  ```plaintext
  https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/download?job=build
  ```

- To download the file `review/index.html` from the latest job named `build` in the `main` branch of a project on GitLab.com:

  ```plaintext
  https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/raw/review/index.html?job=build
  ```

  Files returned by this endpoint always have the `plain/text` content type.

In both examples, replace `<project-id>` with a valid project ID. You can find the project ID on the
[project overview page](../../user/project/working_with_projects.md#access-a-project-by-using-the-project-id).

Artifacts for [parent and child pipelines](../pipelines/downstream_pipelines.md#parent-child-pipelines)
are searched in hierarchical order from parent to child. For example, if both parent and
child pipelines have a job with the same name, the job artifacts from the parent pipeline are returned.

### With a CI/CD job token

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use a [CI/CD job token](ci_job_token.md) to authenticate with the [jobs artifacts API endpoint](../../api/job_artifacts.md)
and fetch artifacts from a different pipeline. You must specify which job to retrieve artifacts from,
for example:

```yaml
build_submodule:
  stage: test
  script:
    - apt update && apt install -y unzip
    - curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"
    - unzip artifacts.zip
```

## Browse the contents of the artifacts archive

You can browse the contents of the artifacts from the UI without downloading the artifact locally,
from:

- Any **Jobs** list. On the right of the job, select **Browse** (**{folder-open}**).
- A job's detail page. On the right of the page, select **Browse**.
- The **Artifacts** page. On the right of the job, select **Browse** (**{folder-open}**).

If [GitLab Pages](../../administration/pages/_index.md) is enabled globally, even if it is disabled in the project settings,
you can preview some artifacts file extensions directly in your browser. If the project is internal or private,
you must enable [GitLab Pages access control](../../administration/pages/_index.md#access-control) to enable the preview.

The following extensions are supported:

| File extension | GitLab.com             | Linux package with built-in NGINX |
|----------------|------------------------|-----------------------------------|
| `.html`        | **{check-circle}** Yes | **{check-circle}** Yes            |
| `.json`        | **{check-circle}** Yes | **{check-circle}** Yes            |
| `.xml`         | **{check-circle}** Yes | **{check-circle}** Yes            |
| `.txt`         | **{dotted-circle}** No | **{check-circle}** Yes            |
| `.log`         | **{dotted-circle}** No | **{check-circle}** Yes            |

### From a URL

You can browse the job artifacts of the latest successful pipeline for a specific job
with a publicly accessible URL.

For example, to browse the latest artifacts of a job named `build` in the `main` branch of a project on GitLab.com:

```plaintext
https://gitlab.com/<full-project-path>/-/jobs/artifacts/main/browse?job=build
```

Replace `<full-project-path>` with a valid project path, you can find it in the URL for your project.

## Delete job log and artifacts

WARNING:
Deleting the job log and artifacts is a destructive action that cannot be reverted. Use with caution.
Deleting certain files, including report artifacts, job logs, and metadata files, affects
GitLab features that use these files as data sources.

You can delete a job's artifacts and log.

Prerequisites:

- You must be the owner of the job or a user with at least the Maintainer role for the project.

To delete a job:

1. Go to a job's detail page.
1. In the upper-right corner of the job's log, select **Erase job log and artifacts** (**{remove}**).

You can also delete individual artifacts from the [**Artifacts** page](#bulk-delete-artifacts).

### Bulk delete artifacts

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33348) in GitLab 15.10 [with a flag](../../administration/feature_flags.md) named `ci_job_artifact_bulk_destroy`. Disabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/398581) in GitLab 16.1.

You can delete multiple artifacts at the same time:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Artifacts**.
1. Select the checkboxes next to the artifacts you want to delete. You can select up to 50 artifacts.
1. Select **Delete selected**.

## Link to job artifacts in the merge request UI

Use the [`artifacts:expose_as`](../yaml/_index.md#artifactsexpose_as) keyword to display
a link to job artifacts in the [merge request](../../user/project/merge_requests/_index.md) UI.

For example, for an artifact with a single file:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

With this configuration, GitLab adds **artifact 1** as a link to `file.txt` to the
**View exposed artifact** section of the relevant merge request.

## Keep artifacts from most recent successful jobs

> - Artifacts for [blocked](https://gitlab.com/gitlab-org/gitlab/-/issues/387087) or [failed](https://gitlab.com/gitlab-org/gitlab/-/issues/266958) pipelines changed to no longer be kept indefinitely in GitLab 16.7.

By default artifacts are always kept for successful pipelines for the most recent commit on each ref.
Any [`expire_in`](#with-an-expiry) configuration does not apply to the most recent artifacts.

A pipeline's artifacts are only deleted according to the `expire_in` configuration
if a new pipeline runs for the same ref and:

- Succeeds.
- Fails.
- Stops running due to being blocked by a manual job.

Additionally, artifacts are kept for the ref's last successful pipeline even if it
is not the latest pipeline. As a result, if a new pipeline run fails, the last successful pipeline's
artifacts are still kept.

Keeping the latest artifacts can use a large amount of storage space in projects
with a lot of jobs or large artifacts. If the latest artifacts are not needed in
a project, you can disable this behavior to save space:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Artifacts**.
1. Clear the **Keep artifacts from most recent successful jobs** checkbox.

After disabling this setting, all new artifacts expire according to the `expire_in` configuration.
Artifacts in old pipelines continue to be kept until a new pipeline runs for the same ref.
Then the artifacts in the earlier pipeline for that ref are allowed to expire too.

You can disable this behavior for all projects on GitLab Self-Managed in the
[instance's CI/CD settings](../../administration/settings/continuous_integration.md#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines).
