---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Debian project distributions API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5835) in GitLab 14.0.

See the [Debian package registry documentation](../../user/packages/debian_repository/index.md)
for more information about working with Debian packages.

## Enable Debian repository feature

Debian repository support is gated behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to enable it.

To enable it:

```ruby
Feature.enable(:debian_packages)
```

To disable it:

```ruby
Feature.disable(:debian_packages)
```

## List all Debian distributions in a project

Lists Debian distributions in the given project.

```plaintext
GET /projects/:id/debian_distributions
```

| Attribute  | Type           | Required | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding). |
| `codename` | string         | no       | Filter with a specific `codename`. |
| `suite`    | string         | no       | Filter with a specific `suite`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/debian_distributions"
```

Example response:

```json
[
  {
    "id": 1,
    "codename": "unstable",
    "suite": null,
    "origin": null,
    "label": null,
    "version": null,
    "description": null,
    "valid_time_duration_seconds": null,
    "components": [
      "main"
    ],
    "architectures": [
      "all",
      "amd64"
    ]
  }
]
```

## Single Debian project distribution

Gets a single Debian project distribution.

```plaintext
GET /projects/:id/debian_distributions/:codename
```

| Attribute  | Type           | Required | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding) owned by the authenticated user. |
| `codename` | integer        | yes      | The `codename` of a distribution. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable"
```

Example response:

```json
{
  "id": 1,
  "codename": "unstable",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Create a Debian project distribution

Creates a Debian project distribution.

```plaintext
POST /projects/:id/debian_distributions
```

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding) owned by the authenticated user. |
| `codename`                    | string         | yes      | The Debian distribution's codename.  |
| `suite`                       | string         | no       | The new Debian distribution's suite. |
| `origin`                      | string         | no       | The new Debian distribution's origin. |
| `label`                       | string         | no       | The new Debian distribution's label. |
| `version`                     | string         | no       | The new Debian distribution's version. |
| `description`                 | string         | no       | The new Debian distribution's description. |
| `valid_time_duration_seconds` | integer        | no       | The new Debian distribution's valid time duration (in seconds). |
| `components`                  | architectures  | no       | The new Debian distribution's list of components. |
| `architectures`               | architectures  | no       | The new Debian distribution's list of architectures. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/debian_distributions?codename=unstable"
```

Example response:

```json
{
  "id": 1,
  "codename": "unstable",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Update a Debian project distribution

Updates a Debian project distribution.

```plaintext
PUT /projects/:id/debian_distributions/:codename
```

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding) owned by the authenticated user. |
| `codename`                    | string         | yes      | The Debian distribution's codename. |
| `suite`                       | string         | no       | The Debian distribution's new suite. |
| `origin`                      | string         | no       | The Debian distribution's new origin. |
| `label`                       | string         | no       | The Debian distribution's new label. |
| `version`                     | string         | no       | The Debian distribution's new version. |
| `description`                 | string         | no       | The Debian distribution's new description. |
| `valid_time_duration_seconds` | integer        | no       | The Debian distribution's new valid time duration (in seconds). |
| `components`                  | architectures  | no       | The Debian distribution's new list of components. |
| `architectures`               | architectures  | no       | The Debian distribution's new list of architectures. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable?suite=new-suite&valid_time_duration_seconds=604800"
```

Example response:

```json
{
  "id": 1,
  "codename": "unstable",
  "suite": "new-suite",
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": 604800,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Delete a Debian project distribution

Deletes a Debian project distribution.

```plaintext
DELETE /projects/:id/debian_distributions/:codename
```

| Attribute  | Type           | Required | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding) owned by the authenticated user. |
| `codename` | integer        | yes      | The Debian distribution's codename. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/debian_distributions/unstable"
```
