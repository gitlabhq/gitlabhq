---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Project-level Secure Files **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78227) in GitLab 14.8 [with a flag](../../administration/feature_flags.md) named `ci_secure_files`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) in GitLab 15.7. Feature flag `ci_secure_files` removed.

This feature is part of [Mobile DevOps](../mobile_devops.md) developed by [GitLab Incubation Engineering](https://about.gitlab.com/handbook/engineering/incubation/).
The feature is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

You can securely store up to 100 files for use in CI/CD pipelines as secure files. These files are stored securely outside of your project's repository and are not version controlled. It is safe to store sensitive information in these files. Secure files support both plain text and binary file types but must be 5 MB or less.

You can manage secure files in the project settings, or with the [secure files API](../../api/secure_files.md).

Secure files can be [downloaded and used by CI/CD jobs](#use-secure-files-in-cicd-jobs)
by using the [download-secure-files](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)
tool.

## Add a secure file to a project

To add a secure file to a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. In the **Secure Files** section, select **Expand**.
1. Select **Upload File**.
1. Find the file to upload, select **Open**, and the file upload begins immediately.
   The file shows up in the list when the upload is complete.

## Use secure files in CI/CD jobs

To use your secure files in a CI/CD job, you must use the [`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)
tool to download the files in the job. After they are downloaded, you can use them
with your other script commands.

Add a command in the `script` section of your job to download the `download-secure-files` tool
and execute it. The files download into a `.secure_files` directory in the root of the project.
To change the download location for the secure files, set the path in the `SECURE_FILES_DOWNLOAD_PATH`
[CI/CD variable](../variables/index.md).

For example:

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
```
