---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab generic packages repository
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the generic packages repository to publish and manage generic files, such as release binaries, in your project's package registry. This feature is particularly useful for storing and distributing artifacts that don't fit into specific package formats like npm or Maven.

The generic packages repository provides:

- A place to store any file type as a package.
- Version control for your packages.
- Integration with GitLab CI/CD.
- API access for automation.

## Authenticate to the package registry

To interact with the package registry, you must authenticate with one of the following methods:

- A [personal access token](../../profile/personal_access_tokens.md) with the scope set to `api`.
- A [project access token](../../project/settings/project_access_tokens.md) with the scope set to `api` and at least the Developer role.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).
- A [deploy token](../../project/deploy_tokens/_index.md) with the scope set to `read_package_registry`, `write_package_registry`, or both.

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

When you authenticate with the package registry, you should follow these best practices:

- To access permissions associated with the Developer role, use a personal access token.
- Use CI/CD job tokens for automated pipelines.
- Use deploy tokens for external system integration.
- Always send authentication information over HTTPS.

### HTTP Basic authentication

If you use a tool that doesn't support the standard authentication methods, you can use HTTP Basic authentication:

```shell
curl --user "<username>:<token>" <other options> <GitLab API endpoint>
```

Although it is ignored, you must provide a username. The token is your personal access token, CI/CD job token, or deploy token.

## Publish a package

You can publish packages with the API.

### Publish a single file

To publish a single file, use the following API endpoint:

```shell
PUT /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

Replace the placeholders in the URL with your specific values:

- `:id`: Your project ID or URL-encoded path
- `:package_name`: Name of your package
- `:package_version`: Version of your package
- `:file_name`: Name of the file you're uploading

For example:

::Tabs

:::TabTitle Personal access token

With HTTP headers:

```shell
curl --location --header "PRIVATE-TOKEN: <personal_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

With HTTP Basic authentication:

```shell
curl --location --user "<username>:<personal_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

:::TabTitle Project access token

With HTTP headers:

```shell
curl --location --header  "PRIVATE-TOKEN: <project_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

With HTTP Basic authentication:

```shell
curl --location --user "<project_access_token_username>:project_access_token" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

:::TabTitle Deploy token

With HTTP headers:

```shell
curl --location --header  "DEPLOY-TOKEN: <deploy_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

With HTTP Basic authentication:

```shell
curl --location --user "<deploy_token_username>:<deploy_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

Replace `<deploy_token_username>` with the username of your deploy token and `<deploy_token>` with your actual deploy token.

:::TabTitle CI/CD job token

These examples are for a `.gitlab-ci.yml` file. GitLab CI/CD automatically provides the `CI_JOB_TOKEN`.

With HTTP headers:

```yaml
publish:
  stage: deploy
  script:
    - |
      curl --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
           --upload-file path/to/file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

With HTTP Basic authentication:

```yaml
publish:
  stage: deploy
  script:
    - |
      curl --location --user "gitlab-ci-token:${CI_JOB_TOKEN}" \
           --upload-file path/to/file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

::EndTabs

Each request returns a response indicating success or failure. If your upload is successful, the response status is `201 Created`.

### Publish multiple files

To publish multiple files or an entire directory, you must make one API call for each file.

You should follow these best practices when you publish multiple files to the repository:

- **Versioning**: Use a consistent versioning scheme for your package. This could be based on your project's version, build number, or date.
- **File organization**: Consider how you want to structure your files within the package. You might want to include a manifest file that lists all the included files and their purposes.
- **Automation**: Whenever possible, automate the publishing process through CI/CD pipelines. This ensures consistency and reduces manual errors.
- **Error handling**: Implement error checking in your scripts. For example, check the HTTP response code from cURL to ensure each file was uploaded successfully.
- **Logging**: Maintain logs of what files were uploaded, when, and by whom. This can be crucial for troubleshooting and auditing.
- **Compression**: For large directories, consider compressing the contents into a single file before uploading. This can simplify the upload process and reduce the number of API calls.
- **Checksums**: Generate and store checksums (MD5, SHA256) for your files. This allows users to verify the integrity of downloaded files.

For example:

::Tabs

:::TabTitle With a Bash script

Create a Bash script to iterate through files and upload them:

```shell
#!/bin/bash

TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
DIRECTORY_PATH="./files_to_upload"

for file in "$DIRECTORY_PATH"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
             --upload-file "$file" \
             "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$filename"
        echo "Uploaded: $filename"
    fi
done
```

:::TabTitle With GitLab CI/CD

For automated uploads in your CI/CD pipeline, you can iterate through your files and upload them:

```yaml
upload_package:
  stage: publish
  script:
    - |
      for file in ./build/*; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")
          curl --header "JOB-TOKEN: $CI_JOB_TOKEN" \
               --upload-file "$file" \
               "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/$filename"
          echo "Uploaded: $filename"
        fi
      done
```

::EndTabs

### Maintain directory structure

To preserve the structure of a published directory, include the relative path in the file name:

```shell
#!/bin/bash

TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
DIRECTORY_PATH="./files_to_upload"

find "$DIRECTORY_PATH" -type f | while read -r file; do
    relative_path=${file#"$DIRECTORY_PATH/"}
    curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
         --upload-file "$file" \
         "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$relative_path"
    echo "Uploaded: $relative_path"
done
```

## Download a package

You can download packages with the API.

### Download a single file

To download a single package file, use the following API endpoint:

```shell
GET /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

Replace the placeholders in the URL with your specific values:

- `:id`: Your project ID or URL-encoded path
- `:package_name`: Name of your package
- `:package_version`: Version of your package
- `:file_name`: Name of the file you're uploading

For example:

::Tabs

:::TabTitle Personal access token

With HTTP headers:

```shell
curl --header "PRIVATE-TOKEN: <access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

With HTTP Basic authentication:

```shell
curl --user "<username>:<access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

:::TabTitle Project access token

With HTTP headers:

```shell
curl --header "PRIVATE-TOKEN: <project_access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

With HTTP Basic authentication:

```shell
curl --user "<project_access_token_username>:<project_access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

:::TabTitle Deploy token

With HTTP headers:

```shell
curl --header "DEPLOY-TOKEN: <deploy_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

With HTTP Basic authentication:

```shell
curl --user "<deploy_token_username>:<deploy_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

:::TabTitle CI/CD job token

These examples are for a `.gitlab-ci.yml` file. GitLab CI/CD automatically provides the `CI_JOB_TOKEN`.

With HTTP headers:

```yaml
download:
  stage: test
  script:
    - |
      curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
           --location \
           --output file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

With HTTP Basic authentication:

```yaml
download:
  stage: test
  script:
    - |
      curl --user "gitlab-ci-token:${CI_JOB_TOKEN}" \
           --location \
           --output file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

Each request returns a response indicating success or failure. If your upload is successful, the response status is `201 Created`.

::EndTabs

### Download multiple files

To download multiple files or an entire directory, you must make one API call for each file, or use additional tools.

You should follow these best practices when you download multiple files from the repository:

- **Versioning**: Always specify the exact version of the package you want to download to ensure consistency.
- **Directory structure**: When downloading, maintain the original directory structure of the package to preserve file organization.
- **Automation**: Integrate package downloads into your CI/CD pipelines or build scripts for automated workflows.
- **Error handling**: Implement checks to ensure all files are downloaded successfully. You can verify the HTTP status code or check file existence after download.
- **Caching**: For frequently used packages, consider implementing a caching mechanism to reduce network usage and improve build times.
- **Parallel downloads**: For large packages with many files, you might want to implement parallel downloads to speed up the process.
- **Checksums**: If available, verify the integrity of downloaded files using checksums provided by the package publisher.
- **Incremental downloads**: For large packages that change frequently, consider implementing a mechanism to download only the files that have changed since the last download.

For example:

::Tabs

:::TabTitle With a Bash script

Create a bash script to download multiple files:

```shell
#!/bin/bash

TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
OUTPUT_DIR="./downloaded_files"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Array of files to download
files=("file1.txt" "file2.txt" "subdirectory/file3.txt")

for file in "${files[@]}"; do
    curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
         --output "$OUTPUT_DIR/$file" \
         --create-dirs \
         "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$file"
    echo "Downloaded: $file"
done
```

:::TabTitle With GitLab CI/CD

For automated downloads in your CI/CD pipeline:

```yaml
download_package:
  stage: build
  script:
    - |
      FILES=("file1.txt" "file2.txt" "subdirectory/file3.txt")
      for file in "${FILES[@]}"; do
        curl --location --header  "JOB-TOKEN: $CI_JOB_TOKEN" \
             --output "$file" \
             --create-dirs \
             "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/$file"
        echo "Downloaded: $file"
      done
```

::EndTabs

### Download an entire package

To download all files in a package, list the package contents using the GitLab API, then download each file:

```shell
TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
OUTPUT_DIR="./downloaded_package"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get list of files in the package
files=$(curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
     "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/files" \
     | jq -r '.[].file_name')

# Download each file
for file in $files; do
    curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
         --output "$OUTPUT_DIR/$file" \
         --create-dirs \
         "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$file"
    echo "Downloaded: $file"
done
```

## Disable publishing duplicate package names

> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) from Developer to Maintainer in GitLab 15.0.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

By default, when you publish a package with the same name and version as an existing package, the new files are added to the existing package. You can disable publishing duplicate file names in the settings.

Prerequisites:

- You must have the Owner role.

To disable publishing duplicate file names:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Packages and registries**.
1. In the **Generic** row of the **Duplicate packages** table, turn off the **Allow duplicates** toggle.
1. Optional. In the **Exceptions** text box, enter a regular expression that matches the names and versions of packages to allow.

NOTE:
If **Allow duplicates** is turned on, you can specify package names and versions that should not have duplicates in the **Exceptions** text box.

## Add a package retention policy

Implement a package retention policy to manage storage and maintain relevant versions.

To do so:

- Use the built-in GitLab [cleanup policies](../package_registry/reduce_package_registry_storage.md#cleanup-policy).

You can also use the API to implement custom cleanup scripts.

## Generic package sample project

The [Write CI-CD Variables in Pipeline](https://gitlab.com/guided-explorations/cfg-data/write-ci-cd-variables-in-pipeline) project contains a working example you can use to create, upload, and download generic packages in GitLab CI/CD.

It also demonstrates how to manage a semantic version for the generic package: storing it in a CI/CD variable, retrieving it, incrementing it, and writing it back to the CI/CD variable when tests for the download work correctly.

## Troubleshooting

### HTTP 403 errors

You might get a `HTTP 403 Forbidden` error. This error happens when either:

- You don't have access to a resource.
- The package registry is not enabled for the project.

To resolve the issue, ensure the package registry is enabled, and you have permission to access it.

### Internal Server error on large file uploads to S3

S3-compatible object storage [limits the size of a single PUT request to 5 GB](https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html). If the `aws_signature_version` is set to `2` in the [object storage connection settings](../../../administration/object_storage.md), attempting to publish a package file larger than the 5 GB limit can result in a `HTTP 500: Internal Server Error` response.

If you are receiving `HTTP 500: Internal Server Error` responses when publishing large files to S3, set the `aws_signature_version` to `4`:

```ruby
# Consolidated Object Storage settings
gitlab_rails['object_store']['connection'] = {
  # Other connection settings
  'aws_signature_version' => '4'
}
# OR
# Storage-specific form settings
gitlab_rails['packages_object_store_connection'] = {
  # Other connection settings
  'aws_signature_version' => '4'
}
```
