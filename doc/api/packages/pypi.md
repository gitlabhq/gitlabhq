---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PyPI API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This is the API documentation for [PyPI Packages](../../user/packages/pypi_repository/_index.md).

WARNING:
This API is used by the [PyPI package manager client](https://pypi.org/)
and is generally not meant for manual consumption.

For instructions on how to upload and install PyPI packages from the GitLab
Package Registry, see the [PyPI package registry documentation](../../user/packages/pypi_repository/_index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [PyPI package registry documentation](../../user/packages/pypi_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.

NOTE:
[Twine 3.4.2](https://twine.readthedocs.io/en/stable/changelog.html?highlight=FIPS#id28) or greater
is recommended when [FIPS mode](../../development/fips_gitlab.md) is enabled.

## Download a package file from a group

Download a PyPI package file. The [simple API](#group-level-simple-api-entry-point)
usually supplies this URL.

```plaintext
GET groups/:id/-/packages/pypi/files/:sha256/:file_identifier
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | yes      | The ID or full path of the group. |
| `sha256`          | string | yes      | The PyPI package file's sha256 checksum. |
| `file_identifier` | string | yes      | The PyPI package file's name. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

This writes the downloaded file to `my.pypi.package-0.0.1.tar.gz` in the current
directory.

## Group-level simple API index

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327595) in GitLab 15.1.

Returns a list of packages in the group as an HTML file:

```plaintext
GET groups/:id/-/packages/pypi/simple
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | yes | The ID or full path of the group. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple"
```

Example response:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Group</title>
  </head>
  <body>
    <h1>Links for Group</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple" >> simple_index.html
```

This writes the downloaded file to `simple_index.html` in the current directory.

## Group level simple API entry point

Returns the package descriptor as an HTML file:

```plaintext
GET groups/:id/-/packages/pypi/simple/:package_name
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the group. |
| `package_name` | string | yes      | The name of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package"
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
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package" >> simple.html
```

This writes the downloaded file to `simple.html` in the current directory.

## Download a package file from a project

Download a PyPI package file. The [simple API](#project-level-simple-api-entry-point)
usually supplies this URL.

```plaintext
GET projects/:id/packages/pypi/files/:sha256/:file_identifier
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`              | string | yes | The ID or full path of the project. |
| `sha256`          | string | yes | PyPI package file sha256 check sum. |
| `file_identifier` | string | yes | The PyPI package filename. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

This writes the downloaded file to `my.pypi.package-0.0.1.tar.gz` in the current
directory.

## Project-level simple API index

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327595) in GitLab 15.1.

Returns a list of packages in the project as an HTML file:

```plaintext
GET projects/:id/packages/pypi/simple
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | yes | The ID or full path of the project. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple"
```

Example response:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Project</title>
  </head>
  <body>
    <h1>Links for Project</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

To write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple" >> simple_index.html
```

This writes the downloaded file to `simple_index.html` in the current directory.

## Project-level simple API entry point

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

Upload a PyPI package:

```plaintext
POST projects/:id/packages/pypi
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The ID or full path of the project. |
| `requires_python` | string | no | The PyPI required version. |

```shell
curl --request POST \
     --form 'content=@path/to/my.pypi.package-0.0.1.tar.gz' \
     --form 'name=my.pypi.package' \
     --form 'version=1.3.7' \
     --user <username>:<personal_access_token> \
     "https://gitlab.example.com/api/v4/projects/1/packages/pypi"
```
