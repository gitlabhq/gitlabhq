---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# PyPI API

This is the API documentation for [PyPI Packages](../../user/packages/pypi_repository/index.md).

WARNING:
This API is used by the [PyPI package manager client](https://pypi.org/)
and is generally not meant for manual consumption.

For instructions on how to upload and install PyPI packages from the GitLab
package registry, see the [PyPI package registry documentation](../../user/packages/pypi_repository/index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [PyPI package registry documentation](../../user/packages/pypi_repository/index.md)
for details on which headers and token types are supported.

## Download a package file from a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225545) in GitLab 13.12.

Download a PyPI package file. The [simple API](#group-level-simple-api-entry-point)
normally supplies this URL.

```plaintext
GET groups/:id/packages/pypi/files/:sha256/:file_identifier
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | yes      | The ID or full path of the group. |
| `sha256`          | string | yes      | The PyPI package file's sha256 checksum. |
| `file_identifier` | string | yes      | The PyPI package file's name. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

This writes the downloaded file to `my.pypi.package-0.0.1.tar.gz` in the current directory.

## Group level simple API entry point

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225545) in GitLab 13.12.

Returns the package descriptor as an HTML file:

```plaintext
GET groups/:id/packages/pypi/simple/:package_name
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the group. |
| `package_name` | string | yes      | The name of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/packages/pypi/simple/my.pypi.package"
```

Example response:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/groups/1/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/packages/pypi/simple/my.pypi.package" >> simple.html
```

This writes the downloaded file to `simple.html` in the current directory.

## Download a package file from a project

> Introduced in GitLab 12.10.

Download a PyPI package file. The [simple API](#project-level-simple-api-entry-point)
normally supplies this URL.

```plaintext
GET projects/:id/packages/pypi/files/:sha256/:file_identifier
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`              | string | yes | The ID or full path of the project. |
| `sha256`          | string | yes | PyPI package file sha256 check sum. |
| `file_identifier` | string | yes | The PyPI package file name. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

This writes the downloaded file to `my.pypi.package-0.0.1.tar.gz` in the current directory.

## Project-level simple API entry point

> Introduced in GitLab 12.10.

Returns the package descriptor as an HTML file:

```plaintext
GET projects/:id/packages/pypi/simple/:package_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`           | string | yes | The ID or full path of the project. |
| `package_name` | string | yes | The name of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package"
```

Example response:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package" >> simple.html
```

This writes the downloaded file to `simple.html` in the current directory.

## Upload a package

> Introduced in GitLab 11.3.

Upload a PyPI package:

```plaintext
PUT projects/:id/packages/pypi
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The ID or full path of the project. |

```shell
curl --request PUT \
     --upload-file path/to/my.pypi.package-0.0.1.tar.gz \
     --user <username>:<personal_access_token> \
     "https://gitlab.example.com/api/v4/projects/1/packages/pypi"
```
