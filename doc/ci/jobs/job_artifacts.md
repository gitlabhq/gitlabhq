---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Job artifacts **(FREE)**

Jobs can output an archive of files and directories. This output is known as a job artifact.

You can download job artifacts by using the GitLab UI or the [API](../../api/job_artifacts.md#get-job-artifacts).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of job artifacts, watch the video [GitLab CI pipelines, artifacts, and environments](https://www.youtube.com/watch?v=PCKDICEe10s).
Or, for an introduction, watch [GitLab CI pipeline tutorial for beginners](https://www.youtube.com/watch?v=Jav4vbUrqII).

For administrator information about job artifact storage, see [administering job artifacts](../../administration/job_artifacts.md).

## Create job artifacts

To create job artifacts, use the [`artifacts`](../yaml/index.md#artifacts) keyword in your `.gitlab-ci.yml` file:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
```

In this example, a job named `pdf` calls the `xelatex` command to build a PDF file from the
LaTeX source file, `mycv.tex`.

The [`paths`](../yaml/index.md#artifactspaths) keyword determines which files to add to the job artifacts.
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

The [`expire_in`](../yaml/index.md#artifactsexpire_in) keyword determines how long
GitLab keeps the job artifacts. For example:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

If `expire_in` is not defined, the [instance-wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration)
is used.

To prevent artifacts from expiring, you can select **Keep** from the job details page.
The option is not available when an artifact has no expiry set.

### With a dynamically defined name

You can use [CI/CD variables](../variables/index.md) to dynamically define the
artifacts file's name.

For example, to create an archive with a name of the current job:

```yaml
job:
  artifacts:
    name: "$CI_JOB_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current branch or tag including only
the binaries directory:

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

If your branch-name contains forward slashes
(for example `feature/my-feature`) use `$CI_COMMIT_REF_SLUG`
instead of `$CI_COMMIT_REF_NAME` for proper naming of the artifact.

### With a Windows runner or shell executor

If you use Windows Batch to run your shell scripts you must replace `$` with `%`:

```yaml
job:
  artifacts:
    name: "%CI_JOB_STAGE%-%CI_COMMIT_REF_NAME%"
    paths:
      - binaries/
```

If you use Windows PowerShell to run your shell scripts you must replace `$` with `$env:`:

```yaml
job:
  artifacts:
    name: "$env:CI_JOB_STAGE-$env:CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

### Without excluded files

Use [`artifacts:exclude`](../yaml/index.md#artifactsexclude) to prevent files from
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

Unlike [`artifacts:paths`](../yaml/index.md#artifactspaths), `exclude` paths are not recursive.
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

Use [`artifacts:untracked`](../yaml/index.md#artifactsuntracked) to add all Git untracked
files as artifacts (along with the paths defined in [`artifacts:paths`](../yaml/index.md#artifactspaths)). Untracked
files are those that haven't been added to the repository but exist in the repository checkout.

For example, to save all Git untracked files and files in `binaries`:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

For example, to save all untracked files but [exclude](../yaml/index.md#artifactsexclude) `*.txt` files:

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

## Prevent a job from fetching artifacts

Jobs downloads all artifacts from the completed jobs in previous stages by default.
To prevent a job from downloading any artifacts, set [`dependencies`](../yaml/index.md#dependencies)
to an empty array (`[]`):

```yaml
job:
  stage: test
  script: make build
  dependencies: []
```

## View all job artifacts in a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31271) in GitLab 12.4 [with a flag](../../administration/feature_flags.md) named `artifacts_management_page`. Disabled by default.
> - [Improved look](https://gitlab.com/gitlab-org/gitlab/-/issues/33418) in GitLab 15.6.
> - [Improved performance](https://gitlab.com/gitlab-org/gitlab/-/issues/387765) in GitLab 15.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/407475) in GitLab 16.0. Feature flag `artifacts_management_page` removed.

You can view all artifacts stored in a project from the **CI/CD > Artifacts** page.
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

For example, to download the latest artifacts of a job named `build` in the `main` branch of a project on GitLab.com:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/download?job=build
```

For example, to download the file `review/index.html` from the latest job named `build` in the `main` branch of a project on GitLab.com:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/raw/review/index.html?job=build
```

In both examples, replace `<project-id>` with a valid project ID, found at the top of the project details page.

Artifacts for [parent and child pipelines](../pipelines/downstream_pipelines.md#parent-child-pipelines)
are searched in hierarchical order from parent to child. For example, if both parent and
child pipelines have a job with the same name, the job artifacts from the parent pipeline are returned.

## Browse the contents of the artifacts archive

You can browse the contents of the artifacts from the UI without downloading the artifact locally,
from:

- Any **Jobs** list. On the right of the job, select **Browse** (**{folder-open}**).
- A job's detail page. On the right of the page, select **Browse**.
- The **Artifacts** page. On the right of the job, select **Browse** (**{folder-open}**).

If [GitLab Pages](../../administration/pages/index.md) is enabled in the project, you can preview
HTML files in the artifacts directly in your browser. If the project is internal or private, you must
enable [GitLab Pages access control](../../administration/pages/index.md#access-control) to preview
HTML files.

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

You can delete a job's artifacts and log.

Prerequisites:

- You must be the owner of the job or a user with at least the Maintainer role for the project.

To delete a job:

1. Go to a job's detail page.
1. In the upper-right corner of the job's log, select **Erase job log and artifacts** (**{remove}**).

## Link to job artifacts in the merge request UI

Use the [`artifacts:expose_as`](../yaml/index.md#artifactsexpose_as) keyword to display
a link to job artifacts in the [merge request](../../user/project/merge_requests/index.md) UI.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16267) in GitLab 13.0.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/229936) in GitLab 13.4.
> - [Made optional with a CI/CD setting](https://gitlab.com/gitlab-org/gitlab/-/issues/241026) in GitLab 13.8.

By default artifacts are always kept for successful pipelines for the most recent commit on
each ref. This means that the latest artifacts do not immediately expire according
to the `expire_in` specification.

If a pipeline for a new commit on the same ref completes successfully, the previous pipeline's
artifacts are deleted according to the `expire_in` configuration. The artifacts
of the new pipeline are kept automatically. If multiple pipelines run for the most
recent commit on the ref, all artifacts are kept.

Keeping the latest artifacts can use a large amount of storage space in projects
with a lot of jobs or large artifacts. If the latest artifacts are not needed in
a project, you can disable this behavior to save space:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Artifacts**.
1. Clear the **Keep artifacts from most recent successful jobs** checkbox.

You can disable this behavior for all projects on a self-managed instance in the
[instance's CI/CD settings](../../user/admin_area/settings/continuous_integration.md#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines).

When **Keep artifacts from most recent successful jobs** is enabled, artifacts are always kept for [blocked](job_control.md#types-of-manual-jobs)
pipelines. These artifacts expire only after the blocking job is triggered and the pipeline completes.
[Issue 387087](https://gitlab.com/gitlab-org/gitlab/-/issues/387087) proposes to change this behavior.
