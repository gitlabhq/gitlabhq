---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This is the API documentation for [Maven Packages](../../user/packages/maven_repository/_index.md).

WARNING:
This API is used by the [Maven package manager client](https://maven.apache.org/)
and is generally not meant for manual consumption.

For instructions on how to upload and install Maven packages from the GitLab
package registry, see the [Maven package registry documentation](../../user/packages/maven_repository/_index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See [Maven package registry documentation](../../user/packages/maven_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.

## Download a package file at the instance-level

Download a Maven package file:

```plaintext
GET packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Download a package file at the group-level

Download a Maven package file:

```plaintext
GET groups/:id/-/packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Download a package file at the project-level

Download a Maven package file:

```plaintext
GET projects/:id/packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Upload a package file

Upload a Maven package file:

```plaintext
PUT projects/:id/packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --request PUT \
     --upload-file path/to/mypkg-1.0-SNAPSHOT.pom \
     --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.pom"
```
