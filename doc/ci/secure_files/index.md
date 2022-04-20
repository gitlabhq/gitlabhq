---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Project-level Secure Files **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78227) in GitLab 14.8. [Deployed behind the `ci_secure_files` flag](../../administration/feature_flags.md), disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../../administration/feature_flags.md)
named `ci_secure_files`. Limited to 100 secure files per project. Files must be smaller
than 5 MB. The feature is not ready for production use.

You can securely store files for use in CI/CD pipelines as "secure files". These files
are stored securely outside of your project's repository, and are not version controlled.
It is safe to store sensitive information in these files. Secure files support both
plain text and binary file types.

Secure files can be [downloaded and used by CI/CD jobs](#use-secure-files-in-cicd-jobs)
by using the [load-secure-files](https://gitlab.com/gitlab-org/incubation-engineering/devops-for-mobile-apps/load-secure-files)
tool.

NOTE:
This feature is in active development and is likely to change, potentially in a breaking way.
Additional features and capabilities are planned.

## Add a secure file to a project

To add a secure file to a project, use the [Secure Files API](../../api/secure_files.md#create-secure-file).

Send a POST request to the secure files endpoint for your project:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/:project_id/secure_files" --form "name=myfile.jks" --form "file=@/path/to/file/myfile.jks"
```

The response returns all of the metadata for the file you just uploaded. For example:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "permissions": "read_only",
    "created_at": "2022-02-22T22:22:22.222Z"
}
```

## List all secure files in a project

To list all secure files in a project, use the [Secure Files API](../../api/secure_files.md#list-project-secure-files).

Send a GET request to the secure files endpoint for your project:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/:project_id/secure_files"
```

The response returns an array of all of the secure files in the project. For example:

```json
[{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "permissions": "read_only",
    "created_at": "2022-02-22T22:22:22.222Z"
}]
```

## Use secure files in CI/CD jobs

To use your secure files in a CI/CD job, you must use the [`load-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/devops-for-mobile-apps/load-secure-files)
tool to download the files in the job. After they are downloaded, you can use them
with your other script commands.

Add a command in the `script` section of your job to download the `load-secure-files` tool
and execute it. The files download into a `.secure_files` directory in the root of the project.
To change the download location for the secure files, set the path in the `SECURE_FILES_DOWNLOAD_PATH`
[CI/CD variable](../variables/index.md).

For example:

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/devops-for-mobile-apps/load-secure-files/-/raw/main/installer" | bash
```
