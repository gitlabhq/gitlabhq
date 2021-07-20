---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Debian API

This is the API documentation for [Debian](../../user/packages/debian_repository/index.md).

WARNING:
This API is used by the Debian related package clients such as [dput](https://manpages.debian.org/stable/dput-ng/dput.1.en.html)
and [apt-get](https://manpages.debian.org/stable/apt/apt-get.8.en.html),
and is generally not meant for manual consumption. This API is under development and is not ready
for production use due to limited functionality.

For instructions on how to upload and install Debian packages from the GitLab
package registry, see the [Debian registry documentation](../../user/packages/debian_repository/index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [Debian registry documentation](../../user/packages/debian_repository/index.md)
for details on which headers and token types are supported.

## Enable the Debian API

The Debian API for GitLab is behind a feature flag that is disabled by default. GitLab
administrators with access to the GitLab Rails console can enable this API for your instance.

To enable it:

```ruby
Feature.enable(:debian_packages)
```

To disable it:

```ruby
Feature.disable(:debian_packages)
```

## Upload a package file

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62028) in GitLab 14.0.

Upload a Debian package file:

```plaintext
PUT projects/:id/packages/debian/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`        | string | yes | The ID or full path of the project.  |
| `file_name` | string | yes | The name of the Debian package file. |

```shell
curl --request PUT \
     --upload-file path/to/mypkg.deb \
     --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/mypkg.deb"
```

## Route prefix

The remaining endpoints described are two sets of identical routes that each make requests in
different scopes:

- Use the project-level prefix to make requests in a single project's scope.
- Use the group-level prefix to make requests in a single group's scope.

The examples in this document all use the project-level prefix.

### Project-level

```plaintext
 /projects/:id/packages/debian`
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The project ID or full project path. |

### Group-level

```plaintext
 /groups/:id/-/packages/debian`
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The project ID or full group path. |

## Download a distribution Release file

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64067) in GitLab 14.1.

Download a Debian package file.

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

This writes the downloaded file to `Release` in the current directory.

## Download a signed distribution Release file

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64067) in GitLab 14.1.

Download a Debian package file.

Signed releases are [not supported](https://gitlab.com/groups/gitlab-org/-/epics/6057#note_582697034).
Therefore, this endpoint downloads the unsigned release file.

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

This writes the downloaded file to `InRelease` in the current directory.
