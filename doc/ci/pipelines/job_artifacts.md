---
stage: Verify
group: Pipeline Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/user/project/pipelines/job_artifacts.html'
---

# Job artifacts **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16675) in GitLab 12.4, artifacts in internal and private projects can be previewed when [GitLab Pages access control](../../administration/pages/index.md#access-control) is enabled.

Jobs can output an archive of files and directories. This output is known as a job artifact.

You can download job artifacts by using the GitLab UI or the [API](../../api/job_artifacts.md#get-job-artifacts).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of job artifacts, watch the video [GitLab CI pipelines, artifacts, and environments](https://www.youtube.com/watch?v=PCKDICEe10s).
Or, for an introduction, watch [GitLab CI pipeline tutorial for beginners](https://www.youtube.com/watch?v=Jav4vbUrqII).

For administrator information about job artifact storage, see [administering job artifacts](../../administration/job_artifacts.md).

## Create job artifacts

To create job artifacts, use the `artifacts` keyword in your `.gitlab-ci.yml` file:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

In this example, a job named `pdf` calls the `xelatex` command to build a PDF file from the
LaTeX source file, `mycv.tex`.

The `paths` keyword determines which files to add to the job artifacts.
All paths to files and directories are relative to the repository where the job was created.

The `expire_in` keyword determines how long GitLab keeps the job artifacts.
You can also [use the UI to keep job artifacts from expiring](#download-job-artifacts).
If `expire_in` is not defined, the
[instance-wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration)
is used.

If you run two types of pipelines (like branch and scheduled) for the same ref,
the pipeline that finishes later creates the job artifact.

To disable artifact passing, define the job with empty [dependencies](../yaml/index.md#dependencies):

```yaml
job:
  stage: build
  script: make build
  dependencies: []
```

You may want to create artifacts only for tagged releases to avoid filling the
build server storage with temporary build artifacts. For example, use [`rules`](../yaml/index.md#rules)
to create artifacts only for tags:

```yaml
default-job:
  script:
    - mvn test -U
  rules:
    - if: $CI_COMMIT_BRANCH

release-job:
  script:
    - mvn package -U
  artifacts:
    paths:
      - target/*.war
  rules:
    - if: $CI_COMMIT_TAG
```

You can use wildcards for directories too. For example, if you want to get all the
files inside the directories that end with `xyz`:

```yaml
job:
  artifacts:
    paths:
      - path/*xyz/*
```

### Use CI/CD variables to define the artifacts name

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
(for example `feature/my-feature`) it's advised to use `$CI_COMMIT_REF_SLUG`
instead of `$CI_COMMIT_REF_NAME` for proper naming of the artifact.

To create an archive with a name of the current job and the current branch or
tag including only the binaries directory:

```yaml
job:
  artifacts:
    name: "$CI_JOB_NAME-$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current [stage](../yaml/index.md#stages) and branch name:

```yaml
job:
  artifacts:
    name: "$CI_JOB_STAGE-$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

If you use **Windows Batch** to run your shell scripts you must replace
`$` with `%`:

```yaml
job:
  artifacts:
    name: "%CI_JOB_STAGE%-%CI_COMMIT_REF_NAME%"
    paths:
      - binaries/
```

If you use **Windows PowerShell** to run your shell scripts you must replace
`$` with `$env:`:

```yaml
job:
  artifacts:
    name: "$env:CI_JOB_STAGE-$env:CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

### Exclude files from job artifacts

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

### Add untracked files to artifacts

Use [`artifacts:untracked`](../yaml/index.md#artifactsuntracked) to add all Git untracked
files as artifacts (along with the paths defined in [`artifacts:paths`](../yaml/index.md#artifactspaths)). Untracked
files are those that haven't been added to the repository but exist in the repository checkout.

Save all Git untracked files and files in `binaries`:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

Save all untracked files but [exclude](../yaml/index.md#artifactsexclude) `*.txt`:

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

## Download job artifacts

You can download job artifacts or view the job archive:

- On the **Pipelines** page, to the right of the pipeline:

  ![Job artifacts in Pipelines page](img/job_artifacts_pipelines_page_v13_11.png)

- On the **Jobs** page, to the right of the job:

  ![Job artifacts in Jobs page](img/job_artifacts_jobs_page_v13_11.png)

- On a job's detail page. The **Keep** button indicates an `expire_in` value was set:

  ![Job artifacts browser button](img/job_artifacts_browser_button_v13_11.png)

- On a merge request, by the pipeline details:

  ![Job artifacts in merge request](img/job_artifacts_merge_request_v13_11.png)

- When browsing an archive:

  ![Job artifacts browser](img/job_artifacts_browser_v13_11.png)

  If [GitLab Pages](../../administration/pages/index.md) is enabled in the project, you can preview
  HTML files in the artifacts directly in your browser. If the project is internal or private, you must
  enable [GitLab Pages access control](../../administration/pages/index.md#access-control) to preview
  HTML files.

## View failed job artifacts

If the latest job has failed to upload the artifacts, you can see that
information in the UI.

![Latest artifacts button](img/job_latest_artifacts_browser.png)

## Delete job artifacts

WARNING:
This is a destructive action that leads to data loss. Use with caution.

You can delete a single job, which also removes the job's
artifacts and log. You must be:

- The owner of the job.
- A user with at least the Maintainer role for the project.

To delete a job:

1. Go to a job's detail page.
1. On the top right of the job's log, select **Erase job log** (**{remove}**).
1. On the confirmation dialog, select **OK**.

## Expose job artifacts in the merge request UI

Use the [`artifacts:expose_as`](../yaml/index.md#artifactsexpose_as) keyword to expose
[job artifacts](../pipelines/job_artifacts.md) in the [merge request](../../user/project/merge_requests/index.md) UI.

For example, to match a single file:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

With this configuration, GitLab adds a link **artifact 1** to the relevant merge request
that points to `file.txt`. To access the link, select **View exposed artifact**
below the pipeline graph in the merge request overview.

An example that matches an entire directory:

```yaml
test:
  script: ["mkdir test && echo 'test' > test/file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['test/']
```

## Retrieve job artifacts for other projects

To retrieve a job artifact from a different project, you might need to use a
private token to [authenticate and download](../../api/job_artifacts.md#get-job-artifacts)
the artifact.

## How searching for job artifacts works

In [GitLab 13.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/201784), artifacts
for [parent and child pipelines](downstream_pipelines.md#parent-child-pipelines) are searched in hierarchical
order from parent to child. For example, if both parent and child pipelines have a
job with the same name, the job artifact from the parent pipeline is returned.

## Access the latest job artifacts

You can download job artifacts from the latest successful pipeline by using [the job artifacts API](../../api/job_artifacts.md).
You cannot download [artifact reports](../yaml/artifacts_reports.md) with the job artifacts API,
unless the report is added as a regular artifact with `artifacts:paths`.

### Download the whole artifacts archive for a specific job

You can download the artifacts archive for a specific job with [the job artifacts API](../../api/job_artifacts.md#download-the-artifacts-archive).

For example, to download the latest artifacts of a job named `build` in the `main` branch of a project on GitLab.com:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/download?job=build
```

Replace `<project-id>` with a valid project ID, found at the top of the project details page.

### Download a single file from the artifacts

You can download a specific file from the artifacts archive for a specific job with [the job artifacts API](../../api/job_artifacts.md#download-a-single-artifact-file-by-job-id).

For example, to download the file `review/index.html` from the latest job named `build` in the `main` branch of the `gitlab` project in the `gitlab-org` namespace:

```plaintext
https://gitlab.com/api/v4/projects/27456355/jobs/artifacts/main/raw/review/index.html?job=build
```

### Browse job artifacts

To browse the job artifacts of the latest successful pipeline for a specific job you can use the following URL:

```plaintext
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/browse?job=<job_name>
```

For example, to browse the latest artifacts of a job named `build` in the `main` branch of a project on GitLab.com:

```plaintext
https://gitlab.com/<full-project-path>/-/jobs/artifacts/main/browse?job=build
```

Replace `<full-project-path>` with a valid project path, you can find it in the URL for your project.

## When job artifacts are deleted

See the [`expire_in`](../yaml/index.md#artifactsexpire_in) documentation for information on when
job artifacts are deleted.

### Keep artifacts from most recent successful jobs

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

## Troubleshooting

### Job does not retrieve certain artifacts

By default, jobs fetch all artifacts from previous stages, but jobs using `dependencies`
or `needs` do not fetch artifacts from all jobs by default.

If you use these keywords, artifacts are fetched from only a subset of jobs. Review
the keyword reference for information on how to fetch artifacts with these keywords:

- [`dependencies`](../yaml/index.md#dependencies)
- [`needs`](../yaml/index.md#needs)
- [`needs:artifacts`](../yaml/index.md#needsartifacts)

### Job artifacts using too much disk space

There are a number of potential causes for this.
[Read more in the job artifacts administration documentation](../../administration/job_artifacts.md#job-artifacts-using-too-much-disk-space).

### Error message `No files to upload`

This message is often preceded by other errors or warnings that specify the filename and why it wasn't
generated. Check the job log for these messages.

If you find no helpful messages, retry the failed job after activating
[CI/CD debug logging](../variables/index.md#enable-debug-logging).
This logging should provide information to help you investigate further.

### Error message `Missing /usr/bin/gitlab-runner-helper. Uploading artifacts is disabled.`

There is a [known issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3068) where setting a CI/CD variable named `DEBUG` can cause artifact uploads to fail.

To work around this, either use a different variable name or set it inline with `script`:

```yaml
# This job might fail due to issue gitlab-org/gitlab-runner#3068
failing_test_job:
  variables:
    DEBUG: true
  script: bin/mycommand
  artifacts:
    paths:
      - bin/results

# This job does not define a CI/CD variable named `DEBUG` and is not affected by the issue
successful_test_job:
  script: DEBUG=true bin/mycommand
  artifacts:
    paths:
      - bin/results
```

### Error message `FATAL: invalid argument` when uploading a dotenv artifact on a windows runner

The PowerShell `echo` command writes files with UCS-2 LE BOM (Byte Order Mark) encoding,
but only UTF-8 is supported. If you try create the dotenv artifact with `echo`, it causes a
`FATAL: invalid argument` error.

Use PowerShell `Add-Content` instead, which uses UTF-8:

```yaml
test-job:
  stage: test
  tags:
    - windows
  script:
    - echo "test job"
    - Add-Content -Path build.env -Value "MY_ENV_VAR=true"
  artifacts:
    reports:
      dotenv: build.env
```

### Job artifacts are not expired

If some job artifacts are not expiring as expected, check if the
[**Keep artifacts from most recent successful jobs**](#keep-artifacts-from-most-recent-successful-jobs)
setting is enabled.

When this setting is enabled, job artifacts from the latest successful pipeline
of each ref do not expire and are not deleted.

### Error message `This job could not start because it could not retrieve the needed artifacts.`

A job configured with [`needs:artifacts`](../yaml/index.md#needsartifacts) keyword
fails to start and returns this error message if:

- The job's dependencies cannot be found.
- The job cannot access the relevant resources due to insufficient permissions.

The troubleshooting steps to follow are determined by the syntax used in the job configuration.

#### Job configured with `needs:project`

The `could not retrieve the needed artifacts.` error can happen for a job using
[`needs:project`](../yaml/index.md#needsproject), with a configuration similar to:

```yaml
rspec:
  needs:
    - project: org/another-project
      job: dependency-job
      ref: master
      artifacts: true
```

To troubleshoot this job, verify that:

- Project `org/another-project` is in a group with a Premium subscription plan.
- The user running the job has permissions to access resources in `org/another-project`.
- The `project`, `job`, and `ref` combination exists and results in the desired dependency.
- Any variables in use evaluate to the correct values.

#### Job configured with `needs:pipeline:job`

The `could not retrieve the needed artifacts.` error can happen for a job using
[`needs:pipeline:job`](../yaml/index.md#needspipelinejob), with a configuration similar to:

```yaml
rspec:
  needs:
    - pipeline: $UPSTREAM_PIPELINE_ID
      job: dependency-job
      artifacts: true
```

To troubleshoot this job, verify that:

- The `$UPSTREAM_PIPELINE_ID` CI/CD variable is available in the current pipeline's
   parent-child pipeline hierarchy.
- The `pipeline` and `job` combination exists and resolves to an existing pipeline.
- `dependency-job` has run and finished successfully.
