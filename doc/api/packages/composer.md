---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Composer API

This is the API documentation for [Composer Packages](../../user/packages/composer_repository/index.md).

WARNING:
This API is used by the [Composer package manager client](https://getcomposer.org/)
and is generally not meant for manual consumption.

For instructions on how to upload and install Composer packages from the GitLab
package registry, see the [Composer package registry documentation](../../user/packages/composer_repository/index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [Composer package registry documentation](../../user/packages/composer_repository/index.md)
for details on which headers and token types are supported.

## Base repository request

Returns the repository URL templates for requesting individual packages:

```plaintext
GET group/:id/-/packages/composer/packages
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The ID or full path of the group. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

Example response:

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json",
  "provider-includes": {
    "p/%hash%.json": {
      "sha256": "082df4a5035f8725a12i4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
    }
  },
  "providers-url": "/api/v4/group/1/-/packages/composer/%package%$%hash%.json"
}
```

This endpoint is used by Composer V1 and V2. To see the V2-specific response, include the Composer
`User-Agent` header. Using Composer V2 is recommended over V1.

```shell
curl --user <username>:<personal_access_token> \
     --header "User-Agent: Composer/2" \
     "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

Example response:

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json"
}
```

## V1 packages list

Given the V1 provider SHA, returns a list of packages in the repository. Using Composer V2 is
recommended over V1.

```plaintext
GET group/:id/-/packages/composer/p/:sha
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The ID or full path of the group. |
| `sha`     | string | yes | The provider SHA, provided by the Composer [base request](#base-repository-request). |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p/082df4a5035f8725a12i4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
```

Example response:

```json
{
  "providers": {
    "my-org/my-composer-package": {
      "sha256": "5c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
    }
  }
}
```

## V1 Package Metadata

Returns the list of versions and metadata for a given package. Using Composer V2 is recommended over
V1.

```plaintext
GET group/:id/-/packages/composer/:package_name$:sha
```

Note the `$` symbol in the URL. When making requests, you may need to use the URL-encoded version of
the symbol `%24` (see example below).

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the group. |
| `package_name` | string | yes      | The name of the package. |
| `sha`          | string | yes      | The SHA digest of the package, provided by the [V1 packages list](#v1-packages-list). |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/group/1/-/packages/composer/my-org/my-composer-package%245c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
```

Example response:

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## V2 Package Metadata

Returns the list of versions and metadata for a given package:

```plaintext
GET group/:id/-/packages/composer/p2/:package_name
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the group. |
| `package_name` | string | yes      | The name of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p2/my-org/my-composer-package"
```

Example response:

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## Create a package

Create a Composer package from a Git tag or branch:

```plaintext
POST projects/:id/packages/composer
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The ID or full path of the group. |
| `tag`     | string | no       | The name of the tag to target for the package. |
| `branch`  | string | no       | The name of the branch to target for the package. |

```shell
curl --request POST --user <username>:<personal_access_token> \
     --data tag=v1.0.0 "https://gitlab.example.com/api/v4/projects/1/packages/composer"
```

Example response:

```json
{
  "message": "201 Created"
}
```

## Download a package archive

Download a Composer package. This URL is provided in the [v1](#v1-package-metadata)
or [v2 package metadata](#v2-package-metadata)
response. A `.zip` file extension must be in the request.

```plaintext
GET projects/:id/packages/composer/archives/:package_name
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the group. |
| `package_name` | string | yes      | The name of the package. |
| `sha`          | string | yes      | The target SHA of the requested package version. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
```

Write the output to file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab" >> package.tar.gz
```

This writes the downloaded file to `package.tar.gz` in the current directory.
