---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/user/project/pipelines/job_artifacts.html'
type: reference, howto
---

# Job artifacts

> Introduced in [GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16675), artifacts in internal and private projects can be previewed when [GitLab Pages access control](../../administration/pages/index.md#access-control) is enabled.

Jobs can output an archive of files and directories. This output is known as a job artifact.

You can download job artifacts by using the GitLab UI or the [API](../../api/job_artifacts.md#get-job-artifacts).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, watch the video [GitLab CI Pipeline, Artifacts, and Environments](https://www.youtube.com/watch?v=PCKDICEe10s).
Watch also [GitLab CI pipeline tutorial for beginners](https://www.youtube.com/watch?v=Jav4vbUrqII).

Administrators should review our [job artifacts administration](../../administration/job_artifacts.md) documentation.

## Define artifacts in the `.gitlab-ci.yml` file

This example shows how to configure your `.gitlab-ci.yml` file to create job artifacts:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

A job named `pdf` calls the `xelatex` command to build a PDF file from the
LaTeX source file, `mycv.tex`.

The `paths` keyword determines which files to add to the job artifacts.
All paths to files and directories are relative to the repository where the job was created.

The `expire_in` keyword determines how long GitLab keeps the job artifacts.
You can also [use the UI to keep job artifacts from expiring](#download-job-artifacts).
If `expire_in` is not defined, the
[instance-wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration)
is used.

For more examples, view the [keyword reference for the `.gitlab-ci.yml` file](../yaml/README.md#artifacts).

## Download job artifacts

You can download job artifacts or view the job archive:

- On the **Pipelines** page, to the right of the pipeline:

  ![Job artifacts in Pipelines page](img/job_artifacts_pipelines_page.png)

- On the **Jobs** page, to the right of the job:

  ![Job artifacts in Builds page](img/job_artifacts_builds_page.png)

- On a job's detail page. The **Keep** button indicates an `expire_in` value was set:

  ![Job artifacts browser button](img/job_artifacts_browser_button.png)

- On a merge request, by the pipeline details:

  ![Job artifacts in Merge Request](img/job_artifacts_merge_request.png)

- When browsing an archive:

  ![Job artifacts browser](img/job_artifacts_browser.png)

  If [GitLab Pages](../../administration/pages/index.md) is enabled in the project, you can preview
  HTML files in the artifacts directly in your browser. If the project is internal or private, you must
  enable [GitLab Pages access control](../../administration/pages/index.md#access-control) to preview
  HTML files.

## View failed job artifacts

If the latest job has failed to upload the artifacts, you can see that
information in the UI.

![Latest artifacts button](img/job_latest_artifacts_browser.png)

## Erase job artifacts

WARNING:
This is a destructive action that leads to data loss. Use with caution.

You can erase a single job, which also removes the job's
artifacts and log. You must be:

- The owner of the job.
- A [Maintainer](../../user/permissions.md#gitlab-cicd-permissions) of the project.

To erase a job:

1. Go to a job's detail page.
1. At the top right of the job's log, select the trash icon.
1. Confirm the deletion.

## Use GitLab CI/CD to retrieve job artifacts for private projects

To retrieve a job artifact from a different project, you might need to use a
private token to [authenticate and download](../../api/job_artifacts.md#get-job-artifacts)
the artifact.

## The latest job artifacts

Job artifacts created in the most recent successful pipeline for a specific ref
are considered the latest artifacts. If you run two types of pipelines for the same ref,
timing determines which artifacts are the latest.

For example, if a merge request creates a branch pipeline at the same time as
a scheduled pipeline, the pipeline that finished most recently creates the latest job artifact.

In [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/201784) and later, artifacts
for [parent and child pipelines](../parent_child_pipelines.md) are searched in hierarchical
order from parent to child. For example, if both parent and child pipelines have a
job with the same name, the job artifact from the parent pipeline is returned.

## Access the latest job artifacts by URL

You can download the latest job artifacts by using a URL.

To download the whole artifacts archive:

```plaintext
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/download?job=<job_name>
```

To download a single file from the artifacts:

```plaintext
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/raw/<path_to_file>?job=<job_name>
```

For example, to download the latest artifacts of the job named `coverage` of
the `master` branch of the `gitlab` project that belongs to the `gitlab-org`
namespace:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/jobs/artifacts/master/download?job=coverage
```

To download the file `coverage/index.html` from the same artifacts:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/jobs/artifacts/master/raw/coverage/index.html?job=coverage
```

To browse the latest job artifacts:

```plaintext
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/browse?job=<job_name>
```

For example:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/jobs/artifacts/master/browse?job=coverage
```

There is also a URL for specific files, including HTML files that
are shown in [GitLab Pages](../../administration/pages/index.md):

```plaintext
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/file/<path>?job=<job_name>
```

For example, when a job `coverage` creates the artifact `htmlcov/index.html`:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/jobs/artifacts/master/file/htmlcov/index.html?job=coverage
```

### Keep artifacts from most recent successful jobs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16267) in GitLab 13.0.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/229936) in GitLab 13.4.
> - [Made optional with a CI/CD setting](https://gitlab.com/gitlab-org/gitlab/-/issues/241026) in GitLab 13.8.

By default, the latest job artifacts from the most recent successful jobs are never deleted.
If a job is configured with [`expire_in`](../yaml/README.md#artifactsexpire_in),
its artifacts only expire if a more recent artifact exists.

Keeping the latest artifacts can use a large amount of storage space in projects
with a lot of jobs or large artifacts. If the latest artifacts are not needed in
a project, you can disable this behavior to save space:

1. Go to the project's **Settings > CI/CD > Artifacts**.
1. Clear the **Keep artifacts from most recent successful jobs** checkbox.

You can disable this behavior for all projects on a self-managed instance in the
[instance's CI/CD settings](../../user/admin_area/settings/continuous_integration.md#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines).

When you disable the feature, the latest artifacts do not immediately expire.
A new pipeline must run before the latest artifacts can expire and be deleted.

### `artifacts:reports`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20390) in GitLab 11.2.
> - Requires GitLab Runner 11.2 and above.

The `artifacts:reports` keyword is used for collecting test reports, code quality
reports, and security reports from jobs. It also exposes these reports in the GitLab
UI (merge requests, pipeline views, and security dashboards).

The test reports are collected regardless of the job results (success or failure).
You can use [`artifacts:expire_in`](../yaml/README.md#artifactsexpire_in) to set up an expiration
date for their artifacts.

If you also want the ability to browse the report output files, include the
[`artifacts:paths`](../yaml/README.md#artifactspaths) keyword.

#### `artifacts:reports:junit`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20390) in GitLab 11.2.
> - Requires GitLab Runner 11.2 and above.

The `junit` report collects [JUnit report format XML files](https://www.ibm.com/support/knowledgecenter/en/SSQ2R2_14.1.0/com.ibm.rsar.analysis.codereview.cobol.doc/topics/cac_useresults_junit.html)
as artifacts. Although JUnit was originally developed in Java, there are many
third party ports for other
languages like JavaScript, Python, Ruby, and so on.

See [Unit test reports](../unit_test_reports.md) for more details and examples.
Below is an example of collecting a JUnit report format XML file from Ruby's RSpec test tool:

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

The collected Unit test reports upload to GitLab as an artifact and display in merge requests.

If the JUnit tool you use exports to multiple XML files, specify
multiple test report paths within a single job to
concatenate them into a single file. Use a filename pattern (`junit: rspec-*.xml`),
an array of filenames (`junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`), or a
combination thereof (`junit: [rspec.xml, test-results/TEST-*.xml]`).

#### `artifacts:reports:dotenv`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17066) in GitLab 12.9.
> - Requires GitLab Runner 11.5 and later.

The `dotenv` report collects a set of environment variables as artifacts.

The collected variables are registered as runtime-created variables of the job,
which is useful to [set dynamic environment URLs after a job finishes](../environments/index.md#set-dynamic-environment-urls-after-a-job-finishes).

There are a couple of exceptions to the [original dotenv rules](https://github.com/motdotla/dotenv#rules):

- The variable key can contain only letters, digits, and underscores (`_`).
- The maximum size of the `.env` file is 5 KB.
- In GitLab 13.5 and older, the maximum number of inherited variables is 10.
- In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/247913),
  the maximum number of inherited variables is 20.
- Variable substitution in the `.env` file is not supported.
- The `.env` file can't have empty lines or comments (starting with `#`).
- Key values in the `env` file cannot have spaces or newline characters (`\n`), including when using single or double quotes.
- Quote escaping during parsing (`key = 'value'` -> `{key: "value"}`) is not supported.

#### `artifacts:reports:cobertura`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3708) in GitLab 12.9.
> - Requires [GitLab Runner](https://docs.gitlab.com/runner/) 11.5 and above.

The `cobertura` report collects [Cobertura coverage XML files](../../user/project/merge_requests/test_coverage_visualization.md).
The collected Cobertura coverage reports upload to GitLab as an artifact
and display in merge requests.

Cobertura was originally developed for Java, but there are many
third party ports for other languages like JavaScript, Python, Ruby, and so on.

#### `artifacts:reports:terraform`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207528) in GitLab 13.0.
> - Requires [GitLab Runner](https://docs.gitlab.com/runner/) 11.5 and above.

The `terraform` report obtains a Terraform `tfplan.json` file. [JQ processing required to remove credentials](../../user/infrastructure/mr_integration.md#setup). The collected Terraform
plan report uploads to GitLab as an artifact and displays
in merge requests. For more information, see
[Output `terraform plan` information into a merge request](../../user/infrastructure/mr_integration.md).

#### `artifacts:reports:codequality`

> - Introduced in [GitLab Starter](https://about.gitlab.com/pricing/) 11.5.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/212499) in GitLab 13.2.
> - Requires GitLab Runner 11.5 and above.

The `codequality` report collects [Code Quality issues](../../user/project/merge_requests/code_quality.md)
as artifacts.

The collected Code Quality report uploads to GitLab as an artifact and is summarized in merge requests.

#### `artifacts:reports:sast`

> - Introduced in GitLab 11.5.
> - Made [available in all tiers](https://gitlab.com/groups/gitlab-org/-/epics/2098) in GitLab 13.3.
> - Requires GitLab Runner 11.5 and above.

The `sast` report collects [SAST vulnerabilities](../../user/application_security/sast/index.md)
as artifacts.

The collected SAST report uploads to GitLab as an artifact and is summarized
in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

#### `artifacts:reports:secret_detection`

> - Introduced in GitLab 13.1.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/222788) in GitLab
    13.3.
> - Requires GitLab Runner 11.5 and above.

The `secret-detection` report collects [detected secrets](../../user/application_security/secret_detection/index.md)
as artifacts.

The collected Secret Detection report is uploaded to GitLab as an artifact and summarized
in the merge requests and pipeline view. It's also used to provide data for security
dashboards.

#### `artifacts:reports:dependency_scanning` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `dependency_scanning` report collects [Dependency Scanning vulnerabilities](../../user/application_security/dependency_scanning/index.md)
as artifacts.

The collected Dependency Scanning report uploads to GitLab as an artifact and is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

#### `artifacts:reports:container_scanning` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `container_scanning` report collects [Container Scanning vulnerabilities](../../user/application_security/container_scanning/index.md)
as artifacts.

The collected Container Scanning report uploads to GitLab as an artifact and
is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

#### `artifacts:reports:dast` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `dast` report collects [DAST vulnerabilities](../../user/application_security/dast/index.md)
as artifacts.

The collected DAST report uploads to GitLab as an artifact and is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

#### `artifacts:reports:api_fuzzing` **(ULTIMATE)**

> - Introduced in GitLab 13.4.
> - Requires GitLab Runner 13.4 or later.

The `api_fuzzing` report collects [API Fuzzing bugs](../../user/application_security/api_fuzzing/index.md)
as artifacts.

The collected API Fuzzing report uploads to GitLab as an artifact and is summarized in merge
requests and the pipeline view. It's also used to provide data for security dashboards.

#### `artifacts:reports:coverage_fuzzing` **(ULTIMATE)**

> - Introduced in GitLab 13.4.
> - Requires GitLab Runner 13.4 or later.

The `coverage_fuzzing` report collects [coverage fuzzing bugs](../../user/application_security/coverage_fuzzing/index.md)
as artifacts.

The collected coverage fuzzing report uploads to GitLab as an artifact and is summarized in merge
requests and the pipeline view. It's also used to provide data for security dashboards.

#### `artifacts:reports:license_management` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

WARNING:
This artifact is still valid but is **deprecated** in favor of the
[artifacts:reports:license_scanning](../pipelines/job_artifacts.md#artifactsreportslicense_scanning)
introduced in GitLab 12.8.

The `license_management` report collects [Licenses](../../user/compliance/license_compliance/index.md)
as artifacts.

The collected License Compliance report uploads to GitLab as an artifact and is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

#### `artifacts:reports:license_scanning` **(ULTIMATE)**

> - Introduced in GitLab 12.8.
> - Requires GitLab Runner 11.5 and above.

The `license_scanning` report collects [Licenses](../../user/compliance/license_compliance/index.md)
as artifacts.

The License Compliance report uploads to GitLab as an artifact and displays automatically in merge requests and the pipeline view, and provide data for security
dashboards.

#### `artifacts:reports:performance` **(PREMIUM)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `performance` report collects [Browser Performance Testing metrics](../../user/project/merge_requests/browser_performance_testing.md)
as artifacts.

The collected Browser Performance report uploads to GitLab as an artifact and displays in merge requests.

#### `artifacts:reports:load_performance` **(PREMIUM)**

> - Introduced in [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35260) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.
> - Requires GitLab Runner 11.5 and above.

The `load_performance` report collects [Load Performance Testing metrics](../../user/project/merge_requests/load_performance_testing.md)
as artifacts.

The report is uploaded to GitLab as an artifact and is
shown in merge requests automatically.

#### `artifacts:reports:metrics` **(PREMIUM)**

> Introduced in GitLab 11.10.

The `metrics` report collects [Metrics](../metrics_reports.md)
as artifacts.

The collected Metrics report uploads to GitLab as an artifact and displays in merge requests.

#### `artifacts:reports:requirements` **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2859) in GitLab 13.1.
> - Requires GitLab Runner 11.5 and above.

The `requirements` report collects `requirements.json` files as artifacts.

The collected Requirements report uploads to GitLab as an artifact and
existing [requirements](../../user/project/requirements/index.md) are
marked as Satisfied.

## Troubleshooting job artifacts

### Error message `No files to upload`

This is often preceded by other errors or warnings that specify the filename and why it wasn't
generated in the first place. Please check the entire job log for such messages.

If you find no helpful messages, please retry the failed job after activating
[CI/CD debug logging](../variables/README.md#debug-logging).
This provides useful information to investigate further.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
