---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project-level secure files
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) and feature flag `ci_secure_files` removed in GitLab 15.7.

{{< /history >}}

This feature is part of [Mobile DevOps](../mobile_devops/_index.md).
The feature is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

You can securely store up to 100 files for use in CI/CD pipelines as secure files. These files are stored securely outside of your project's repository and are not version controlled. It is safe to store sensitive information in these files. Secure files support both plain text and binary file types but must be 5 MB or less.

You can manage secure files in the project settings, or with the [secure files API](../../api/secure_files.md).

Secure files can be [downloaded and used by CI/CD jobs](#use-secure-files-in-cicd-jobs)
by using the [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile) command.

## Add a secure file to a project

To add a secure file to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **CI/CD**.
1. Expand the **Secure Files** section.
1. Select **Upload File**.
1. Find the file to upload, select **Open**, and the file upload begins immediately.
   The file shows up in the list when the upload is complete.

## Use secure files in CI/CD jobs

{{< alert type="warning" >}}

The content of secure files are not [masked](../variables/_index.md#mask-a-cicd-variable)
in the job log output. Make sure to avoid outputting secure file contents in the job log,
especially when logging output that could contain sensitive information.

{{< /alert >}}

### With the `glab` tool

To download one or more secure files with [`glab`](https://gitlab.com/gitlab-org/cli/),
you can use the `cli` Docker image in the CI/CD job.

#### Download all the files in a project

To download all the secure files in a project:

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - export GITLAB_HOST=$CI_SERVER_URL
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download --all --output-dir="where/to/save"
```

In this example, all variables are [predefined variables](../variables/predefined_variables.md)
that are automatically available.

#### Download a single file in a project

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - export GITLAB_HOST=$CI_SERVER_URL
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download $SECURE_FILE_ID --path="where/to/save/file.txt"
```

The `SECURE_FILE_ID` CI/CD variable needs to passed to the job explicitly, for example
in [CI/CD settings](../variables/_index.md#define-a-cicd-variable-in-the-ui) or when
[running a pipeline manually](../pipelines/_index.md#run-a-pipeline-manually).
Every other variable is a [predefined variable](../variables/predefined_variables.md)
that is automatically available.

Alternatively, instead of using the Docker image, you can [download the binary](https://gitlab.com/gitlab-org/cli/-/releases).
and use it in your CI/CD job.

### With the `download-secure-files` tool (deprecated)

{{< history >}}

- [Deprecated](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/issues/45) in GitLab 18.6.

{{< /history >}}

{{< alert type="warning" >}}

This method is deprecated.

{{< /alert >}}

To use your secure files in a CI/CD job, you can use the [`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)
tool to download the files in the job. After they are downloaded, you can use them
with your other script commands.

Add a command in the `script` section of your job to download the `download-secure-files` tool
and execute it. The files download into a `.secure_files` directory in the root of the project.
To change the download location for the secure files, set the path in the `SECURE_FILES_DOWNLOAD_PATH`
[CI/CD variable](../variables/_index.md).

For example:

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
```

## Security details

Project-level Secure Files are encrypted on upload using the [Lockbox](https://github.com/ankane/lockbox)
Ruby gem by using the [`Ci::SecureFileUploader`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/uploaders/ci/secure_file_uploader.rb)
interface. This interface generates a SHA256 checksum of the source file during upload
that is persisted with the record in the database so it can be used to verify the contents
of the file when downloaded.

A [unique encryption key](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb#L27)
is generated for each file when it is created and persisted in the database. The encrypted uploaded files
are stored in either local storage or object storage depending on the [GitLab instance configuration](../../administration/cicd/secure_files.md).

Individual files can be retrieved with the [secure files download API](../../api/secure_files.md#download-secure-file).
Metadata can be retrieved with the [list](../../api/secure_files.md#list-project-secure-files)
or [show](../../api/secure_files.md#show-secure-file-details) API endpoints. Files can also be retrieved
with the [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile)
command. This command automatically verifies the checksum of each file as it is downloaded.

Any project member with at least the Developer role can access Project-level secure files.
Interactions with Project-level secure files are not included in audit events, but
[issue 117](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/117)
proposes adding this functionality.
