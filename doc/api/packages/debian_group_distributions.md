---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Debian group distributions API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Deployed behind a feature flag](../../user/feature_flags.md), disabled by default.

This is the reference documentation for the Debian group distributions API. This API is behind a
feature flag that is disabled by default. To use this API, you must [enable it](#enable-the-debian-group-api).

WARNING:
This API is under development and is not meant for production use.

For more information about working with Debian packages, see the
[Debian package registry documentation](../../user/packages/debian_repository/_index.md).

## Enable the Debian group API

Debian group repository support is still a work in progress. It's gated behind a feature flag that's
**disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to enable it. To enable it, follow the instructions in
[Enable the Debian group API](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api).

## Authenticate to the Debian distributions APIs

See [Authenticate to the Debian distributions APIs](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-distributions-apis).

## List all Debian distributions in a group

Lists Debian distributions in the given group.

```plaintext
GET /groups/:id/-/debian_distributions
```

| Attribute  | Type            | Required | Description |
| ---------- | --------------- | -------- | ----------- |
| `id`       | integer/string  | yes      | The ID or [URL-encoded path of the group](../rest/_index.md#namespaced-paths). |
| `codename` | string          | no       | Filter with specific `codename`. |
| `suite`    | string          | no       | Filter with specific `suite`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions"
```

Example response:

```json
[
  {
    "id": 1,
    "codename": "sid",
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

## Single Debian group distribution

Gets a single Debian group distribution.

```plaintext
GET /groups/:id/-/debian_distributions/:codename
```

| Attribute  | Type           | Required | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the group](../rest/_index.md#namespaced-paths). |
| `codename` | string         | yes      | The `codename` of a distribution. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable"
```

Example response:

```json
{
  "id": 1,
  "codename": "sid",
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

## Single Debian group distribution key

Gets a single Debian group distribution key.

```plaintext
GET /groups/:id/-/debian_distributions/:codename/key.asc
```

| Attribute  | Type           | Required | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the group](../rest/_index.md#namespaced-paths). |
| `codename` | string         | yes      | The `codename` of a distribution. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable/key.asc"
```

Example response:

```plaintext
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: Alice's OpenPGP certificate
Comment: https://www.ietf.org/id/draft-bre-openpgp-samples-01.html

mDMEXEcE6RYJKwYBBAHaRw8BAQdArjWwk3FAqyiFbFBKT4TzXcVBqPTB3gmzlC/U
b7O1u120JkFsaWNlIExvdmVsYWNlIDxhbGljZUBvcGVucGdwLmV4YW1wbGU+iJAE
ExYIADgCGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQTrhbtfozp14V6UTmPy
MVUMT0fjjgUCXaWfOgAKCRDyMVUMT0fjjukrAPoDnHBSogOmsHOsd9qGsiZpgRnO
dypvbm+QtXZqth9rvwD9HcDC0tC+PHAsO7OTh1S1TC9RiJsvawAfCPaQZoed8gK4
OARcRwTpEgorBgEEAZdVAQUBAQdAQv8GIa2rSTzgqbXCpDDYMiKRVitCsy203x3s
E9+eviIDAQgHiHgEGBYIACAWIQTrhbtfozp14V6UTmPyMVUMT0fjjgUCXEcE6QIb
DAAKCRDyMVUMT0fjjlnQAQDFHUs6TIcxrNTtEZFjUFm1M0PJ1Dng/cDW4xN80fsn
0QEA22Kr7VkCjeAEC08VSTeV+QFsmz55/lntWkwYWhmvOgE=
=iIGO
-----END PGP PUBLIC KEY BLOCK-----
```

## Create a Debian group distribution

Creates a Debian group distribution.

```plaintext
POST /groups/:id/-/debian_distributions
```

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](../rest/_index.md#namespaced-paths). |
| `codename`                    | string         | yes      | The codename of a Debian distribution. |
| `suite`                       | string         | no       | The suite of the new Debian distribution. |
| `origin`                      | string         | no       | The origin of the new Debian distribution. |
| `label`                       | string         | no       | The label of the new Debian distribution. |
| `version`                     | string         | no       | The version of the new Debian distribution. |
| `description`                 | string         | no       | The description of the new Debian distribution. |
| `valid_time_duration_seconds` | integer        | no       | The valid time duration (in seconds) of the new Debian distribution. |
| `components`                  | string array   | no       | The new Debian distribution's list of components. |
| `architectures`               | string array   | no       | The new Debian distribution's list of architectures. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions?codename=sid"
```

Example response:

```json
{
  "id": 1,
  "codename": "sid",
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

## Update a Debian group distribution

Updates a Debian group distribution.

```plaintext
PUT /groups/:id/-/debian_distributions/:codename
```

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](../rest/_index.md#namespaced-paths). |
| `codename`                    | string         | yes      | The Debian distribution's new codename.  |
| `suite`                       | string         | no       | The Debian distribution's new suite. |
| `origin`                      | string         | no       | The Debian distribution's new origin. |
| `label`                       | string         | no       | The Debian distribution's new label. |
| `version`                     | string         | no       | The Debian distribution's new version. |
| `description`                 | string         | no       | The Debian distribution's new description. |
| `valid_time_duration_seconds` | integer        | no       | The Debian distribution's new valid time duration (in seconds). |
| `components`                  | string array   | no       | The Debian distribution's new list of components. |
| `architectures`               | string array   | no       | The Debian distribution's new list of architectures. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable?suite=new-suite&valid_time_duration_seconds=604800"
```

Example response:

```json
{
  "id": 1,
  "codename": "sid",
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

## Delete a Debian group distribution

Deletes a Debian group distribution.

```plaintext
DELETE /groups/:id/-/debian_distributions/:codename
```

| Attribute  | Type           | Required | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the group](../rest/_index.md#namespaced-paths). |
| `codename` | string         | yes      | The codename of the Debian distribution. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable"
```
