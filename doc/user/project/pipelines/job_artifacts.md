# Introduction to job artifacts

>**Notes:**
>- Since GitLab 8.2 and GitLab Runner 0.7.0, job artifacts that are created by
   GitLab Runner are uploaded to GitLab and are downloadable as a single archive
   (`tar.gz`) using the GitLab UI.
>- Starting with GitLab 8.4 and GitLab Runner 1.0, the artifacts archive format
   changed to `ZIP`, and it is now possible to browse its contents, with the added
   ability of downloading the files separately.
>- Starting with GitLab 8.17, builds are renamed to jobs.
>- The artifacts browser will be available only for new artifacts that are sent
   to GitLab using GitLab Runner version 1.0 and up. It will not be possible to
   browse old artifacts already uploaded to GitLab.
>- This is the user documentation. For the administration guide see
   [administration/job_artifacts](../../../administration/job_artifacts.md).

Artifacts is a list of files and directories which are attached to a job
after it completes successfully. This feature is enabled by default in all
GitLab installations.

## Defining artifacts in `.gitlab-ci.yml`

A simple example of using the artifacts definition in `.gitlab-ci.yml` would be
the following:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
    - mycv.pdf
    expire_in: 1 week
```

A job named `pdf` calls the `xelatex` command in order to build a pdf file from
the latex source file `mycv.tex`. We then define the `artifacts` paths which in
turn are defined with the `paths` keyword. All paths to files and directories
are relative to the repository that was cloned during the build. These uploaded
artifacts will be kept in GitLab for 1 week as defined by the `expire_in`
definition. You have the option to keep the artifacts from expiring via the
[web interface](#browsing-job-artifacts). If you don't define an expiry date,
the artifacts will be kept forever.

For more examples on artifacts, follow the [artifacts reference in
`.gitlab-ci.yml`](../../../ci/yaml/README.md#artifacts).

## Browsing artifacts

>**Note:**
With GitLab 9.2, PDFs, images, videos and other formats can be previewed
directly in the job artifacts browser without the need to download them.

>**Note:**
With [GitLab 10.1][ce-14399], HTML files in a public project can be previewed
directly in a new tab without the need to download them when
[GitLab Pages](../../../administration/pages/index.md) is enabled

After a job finishes, if you visit the job's specific page, there are three
buttons. You can download the artifacts archive or browse its contents, whereas
the **Keep** button appears only if you have set an [expiry date] to the
artifacts in case you changed your mind and want to keep them.

![Job artifacts browser button](img/job_artifacts_browser_button.png)

---

The archive browser shows the name and the actual file size of each file in the
archive. If your artifacts contained directories, then you are also able to
browse inside them.

Below you can see how browsing looks like. In this case we have browsed inside
the archive and at this point there is one directory, a couple files, and
one HTML file that you can view directly online when
[GitLab Pages](../../../administration/pages/index.md) is enabled (opens in a new tab).

![Job artifacts browser](img/job_artifacts_browser.png)

---

## Downloading artifacts

If you need to download the whole archive, there are buttons in various places
inside GitLab that make that possible.

1. While on the pipelines page, you can see the download icon for each job's
   artifacts archive in the right corner:

    ![Job artifacts in Pipelines page](img/job_artifacts_pipelines_page.png)

1. While on the **Jobs** page, you can see the download icon for each job's
   artifacts archive in the right corner:

    ![Job artifacts in Builds page](img/job_artifacts_builds_page.png)

1. While inside a specific job, you are presented with a download button
   along with the one that browses the archive:

    ![Job artifacts browser button](img/job_artifacts_browser_button.png)

1. And finally, when browsing an archive you can see the download button at
   the top right corner:

    ![Job artifacts browser](img/job_artifacts_browser.png)

## Downloading the latest artifacts

It is possible to download the latest artifacts of a job via a well known URL
so you can use it for scripting purposes.

>**Note:**
The latest artifacts are considered as the artifacts created by jobs in the
latest pipeline that succeeded for the specific ref.
Artifacts for other pipelines can be accessed with direct access to them.

The structure of the URL to download the whole artifacts archive is the following:

```
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/download?job=<job_name>
```

To download a single file from the artifacts use the following URL:

```
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/raw/<path_to_file>?job=<job_name>
```

For example, to download the latest artifacts of the job named `coverage` of
the `master` branch of the `gitlab-ce` project that belongs to the `gitlab-org`
namespace, the URL would be:

```
https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/artifacts/master/download?job=coverage
```

To download the file `coverage/index.html` from the same
artifacts use the following URL:

```
https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/artifacts/master/raw/coverage/index.html?job=coverage
```

There is also a URL to browse the latest job artifacts:

```
https://example.com/<namespace>/<project>/-/jobs/artifacts/<ref>/browse?job=<job_name>
```

For example:

```
https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/artifacts/master/browse?job=coverage
```

The latest builds are also exposed in the UI in various places. Specifically,
look for the download button in:

- the main project's page
- the branches page
- the tags page

If the latest job has failed to upload the artifacts, you can see that
information in the UI.

![Latest artifacts button](img/job_latest_artifacts_browser.png)

## Erasing artifacts

DANGER: **Warning:**
This is a destructive action that leads to data loss. Use with caution.

If you have at least Developer [permissions](../../permissions.md#gitlab-ci-cd-permissions)
on the project, you can erase a single job via the UI which will also remove the
artifacts and the job's trace.

1. Navigate to a job's page.
1. Click the trash icon at the top right of the job's trace.
1. Confirm the deletion.

[expiry date]: ../../../ci/yaml/README.md#artifacts-expire_in
[ce-14399]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14399
