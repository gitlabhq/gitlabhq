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
   [administration/job_artifacts.md](../../../administration/job_artifacts.md).

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
```

A job named `pdf` calls the `xelatex` command in order to build a pdf file from
the latex source file `mycv.tex`. We then define the `artifacts` paths which in
turn are defined with the `paths` keyword. All paths to files and directories
are relative to the repository that was cloned during the build.

For more examples on artifacts, follow the artifacts reference in
[`.gitlab-ci.yml` documentation](../../../ci/yaml/README.md#artifacts).

## Browsing job artifacts

After a job finishes, if you visit the job's specific page, you can see
that there are two buttons. One is for downloading the artifacts archive and
the other for browsing its contents.

![Job artifacts browser button](img/job_artifacts_browser_button.png)

---

The archive browser shows the name and the actual file size of each file in the
archive. If your artifacts contained directories, then you are also able to
browse inside them.

Below you can see how browsing looks like. In this case we have browsed inside
the archive and at this point there is one directory and one HTML file.

![Job artifacts browser](img/job_artifacts_browser.png)

---

## Downloading job artifacts

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

## Downloading the latest job artifacts

It is possible to download the latest artifacts of a job via a well known URL
so you can use it for scripting purposes.

The structure of the URL to download the whole artifacts archive is the following:

```
https://example.com/<namespace>/<project>/builds/artifacts/<ref>/download?job=<job_name>
```

To download a single file from the artifacts use the following URL:

```
https://example.com/<namespace>/<project>/builds/artifacts/<ref>/file/<path_to_file>?job=<job_name>
```

For example, to download the latest artifacts of the job named `coverage` of
the `master` branch of the `gitlab-ce` project that belongs to the `gitlab-org`
namespace, the URL would be:

```
https://gitlab.com/gitlab-org/gitlab-ce/builds/artifacts/master/download?job=coverage
```

To download the file `coverage/index.html` from the same
artifacts use the following URL:

```
https://gitlab.com/gitlab-org/gitlab-ce/builds/artifacts/master/file/coverage/index.html?job=coverage
```

There is also a URL to browse the latest job artifacts:

```
https://example.com/<namespace>/<project>/builds/artifacts/<ref>/browse?job=<job_name>
```

For example:

```
https://gitlab.com/gitlab-org/gitlab-ce/builds/artifacts/master/browse?job=coverage
```

The latest builds are also exposed in the UI in various places. Specifically,
look for the download button in:

- the main project's page
- the branches page
- the tags page

If the latest job has failed to upload the artifacts, you can see that
information in the UI.

![Latest artifacts button](img/job_latest_artifacts_browser.png)

