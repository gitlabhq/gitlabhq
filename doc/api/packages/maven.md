---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Maven API

This is the API documentation for [Maven Packages](../../user/packages/maven_repository/index.md).

WARNING:
This API is used by the [Maven package manager client](https://maven.apache.org/)
and is generally not meant for manual consumption.

For instructions on how to upload and install Maven packages from the GitLab
package registry, see the [Maven package registry documentation](../../user/packages/maven_repository/index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See [Maven package registry documentation](../../user/packages/maven_repository/index.md)
for details on which headers and token types are supported.

## Download a package file at the instance-level

> Introduced in GitLab 11.6.

Download a Maven package file:

```plaintext
GET packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.jar"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Download a package file at the group-level

> Introduced in GitLab 11.7.

Download a Maven package file:

```plaintext
GET groups/:id/-/packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.jar"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Download a package file at the project-level

> Introduced in GitLab 11.3.

Download a Maven package file:

```plaintext
GET projects/:id/packages/maven/*path/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | yes | The Maven package path, in the format `<groupId>/<artifactId>/<version>`. Replace any `.` in the `groupId` with `/`. |
| `file_name`  | string | yes | The name of the Maven package file. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.jar"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

This writes the downloaded file to `mypkg-1.0-SNAPSHOT.jar` in the current directory.

## Upload a package file

> Introduced in GitLab 11.3.

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
     "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/baz/mypkg-1.0-SNAPSHOT.pom"
```
