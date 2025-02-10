---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Debian API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Deployed behind a feature flag](../../user/feature_flags.md), disabled by default.

This is the API documentation for [Debian](../../user/packages/debian_repository/_index.md).

WARNING:
This API is used by the Debian related package clients such as [dput](https://manpages.debian.org/stable/dput-ng/dput.1.en.html)
and [apt-get](https://manpages.debian.org/stable/apt/apt-get.8.en.html),
and is generally not meant for manual consumption. This API is under development and is not ready
for production use due to limited functionality.

For instructions on how to upload and install Debian packages from the GitLab
package registry, see the [Debian registry documentation](../../user/packages/debian_repository/_index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [Debian registry documentation](../../user/packages/debian_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.

## Enable the Debian API

The Debian API is behind a feature flag that is disabled by default.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to enable it. To enable it, follow the instructions in
[Enable the Debian API](../../user/packages/debian_repository/_index.md#enable-the-debian-api).

## Enable the Debian group API

The Debian group API is behind a feature flag that is disabled by default.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to enable it. To enable it, follow the instructions in
[Enable the Debian group API](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api).

### Authenticate to the Debian Package Repositories

See [Authenticate to the Debian Package Repositories](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-package-repositories).

## Upload a package file

> - Upload with explicit distribution and component [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101838) in GitLab 15.9.

Upload a Debian package file:

```plaintext
PUT projects/:id/packages/debian/:file_name
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the project.  |
| `file_name`    | string | yes      | The name of the Debian package file. |
| `distribution` | string | no       | The distribution codename or suite. Used with `component` for upload with explicit distribution and component. |
| `component`    | string | no       | The package file component. Used with `distribution` for upload with explicit distribution and component. |

```shell
curl --request PUT \
     --user "<username>:<personal_access_token>" \
     --upload-file path/to/mypkg.deb \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/mypkg.deb"
```

Upload with explicit distribution and component:

```shell
curl --request PUT \
  --user "<username>:<personal_access_token>" \
  --upload-file  /path/to/myother.deb \
  "https://gitlab.example.com/api/v4/projects/1/packages/debian/myother.deb?distribution=sid&component=main"
```

## Download a package

Download a package file.

```plaintext
GET projects/:id/packages/debian/pool/:distribution/:letter/:package_name/:package_version/:file_name
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `letter`          | string | yes      | The Debian Classification (first-letter or lib-first-letter). |
| `package_name`    | string | yes      | The source package name. |
| `package_version` | string | yes      | The source package version. |
| `file_name`       | string | yes      | The filename. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Route prefix

The remaining endpoints described are two sets of identical routes that each make requests in
different scopes:

- Use the project-level prefix to make requests in a single project's scope.
- Use the group-level prefix to make requests in a single group's scope.

The examples in this document all use the project-level prefix.

### Project-level

```plaintext
/projects/:id/packages/debian
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The project ID or full project path. |

### Group-level

```plaintext
/groups/:id/-/packages/debian
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The project ID or full group path. |

## Download a distribution Release file

Download a Debian distribution file.

```plaintext
GET <route-prefix>/dists/*distribution/Release
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a signed distribution Release file

Download a signed Debian distribution file.

```plaintext
GET <route-prefix>/dists/*distribution/InRelease
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a release file signature

Download a Debian release file signature.

```plaintext
GET <route-prefix>/dists/*distribution/Release.gpg
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a packages index

Download a packages index.

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/Packages
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `component`       | string | yes      | The distribution component name. |
| `architecture`    | string | yes      | The distribution architecture type. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a packages index by hash

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96947) in GitLab 15.4.

Download a packages index by hash.

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256

```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `component`       | string | yes      | The distribution component name. |
| `architecture`    | string | yes      | The distribution architecture type. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a Debian Installer packages index

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71918) in GitLab 15.4.

Download a Debian Installer packages index.

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `component`       | string | yes      | The distribution component name. |
| `architecture`    | string | yes      | The distribution architecture type. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a Debian Installer packages index by hash

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96947) in GitLab 15.4.

Download a Debian Installer packages index by hash.

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `component`       | string | yes      | The distribution component name. |
| `architecture`    | string | yes      | The distribution architecture type. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a source packages index

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71918) in GitLab 15.4.

Download a source packages index.

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/Sources
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `component`       | string | yes      | The distribution component name. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.

## Download a source packages index by hash

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96947) in GitLab 15.4.

Download a source packages index by hash.

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | yes      | The codename or suite of the Debian distribution. |
| `component`       | string | yes      | The distribution component name. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

Write the output to a file:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

This writes the downloaded file using the remote filename in the current directory.
