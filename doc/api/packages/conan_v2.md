---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan v2 API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519741) in GitLab 17.11 [with a flag](../../administration/feature_flags/_index.md) named `conan_package_revisions_support`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14896) in GitLab 18.3. Feature flag `conan_package_revisions_support` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

{{< alert type="note" >}}

For Conan v1 operations, see [Conan v1 API](conan_v1.md).

{{< /alert >}}

Use this API to interact with the [Conan v2 package manager](../../user/packages/conan_2_repository/_index.md).

Generally, these endpoints are used by the [Conan 2 package manager client](https://docs.conan.io/2/index.html)
and are not meant for manual consumption.

{{< alert type="note" >}}

- These endpoints do not adhere to the standard API authentication methods.
See each route for details on how credentials are expected to be passed. Undocumented authentication methods might be removed in the future.

- The Conan registry is not FIPS compliant and is disabled when FIPS mode is enabled.
These endpoints all return `404 Not Found`.
{{< /alert >}}

## Create an authentication token

Creates a JSON Web Token (JWT) for use as a Bearer header in other requests.

```shell
"Authorization: Bearer <authenticate_token>
```

The Conan 2 package manager client automatically uses this token.

```plaintext
GET /projects/:id/packages/conan/v2/users/authenticate
```

| Attribute | Type   | Required      | Description                                                                  |
| --------- | ------ | ------------- | ---------------------------------------------------------------------------- |
| `id`      | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |

Generate a base64-encoded Basic Auth token:

```shell
echo -n "<username>:<your_access_token>"|base64
```

Use the base64-encoded Basic Auth token to get a JWT token:

```shell
curl --request GET \
     --header 'Authorization: Basic <base64_encoded_token>' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v2/users/authenticate"
```

Example response:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Verify authentication credentials

Verifies the validity of Basic Auth credentials or a Conan JWT generated from the Conan v1 [`/authenticate`](conan_v1.md#create-an-authentication-token) endpoint.

```plaintext
GET /projects/:id/packages/conan/v2/users/check_credentials
```

| Attribute | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `id`      | string | yes      | The project ID or full project path. |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan/v2/users/check_credentials"
```

Example response:

```plaintext
ok
```

## Search for a Conan package

Searches the project for a Conan package with a specified name.

```plaintext
GET /projects/:id/packages/conan/v2/conans/search?q=:query
```

| Attribute | Type   | Required | Description                                  |
| --------- | ------ | -------- | -------------------------------------------- |
| `id`      | string | yes      | The project ID or full project path.         |
| `query`   | string | yes      | Search query. You can use `*` as a wildcard. |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/search?q=Hello*"
```

Example response:

```json
{
  "results": [
    "Hello/0.1@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan_test_prod/stable",
    "Hello/0.2@foo+conan_test_prod/beta",
    "Hello/0.3@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan-reference-test/stable",
    "HelloWorld/0.1@baz+conan-reference-test/beta"
    "hello-world/0.4@buz+conan-test/alpha"
  ]
}
```

## Get latest recipe revision

Gets the revision hash and creation date of the latest package recipe.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/latest
```

| Attribute          | Type   | Required | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | yes      | The project ID or full project path.                                                        |
| `package_name`     | string | yes      | Name of a package.                                                                          |
| `package_version`  | string | yes      | Version of a package.                                                                       |
| `package_username` | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`  | string | yes      | Channel of a package.                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/latest"
```

Example response:

```json
{
  "revision" : "75151329520e7685dcf5da49ded2fec0",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## List all recipe revisions

Lists all revisions for a package recipe.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions
```

| Attribute          | Type   | Required | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | yes      | The project ID or full project path.                                                        |
| `package_name`     | string | yes      | Name of a package.                                                                          |
| `package_version`  | string | yes      | Version of a package.                                                                       |
| `package_username` | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`  | string | yes      | Channel of a package.                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions"
```

Example response:

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable",
  "revisions": [
    {
      "revision": "75151329520e7685dcf5da49ded2fec0",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "df28fd816be3a119de5ce4d374436b25",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## Delete a recipe revision

Delete the recipe revision from the registry. If the package has only one recipe revision, the package is deleted as well.

```plaintext
DELETE /projects/:id/packages/conan/conans/:package_name/package_version/:package_username/:package_channel/revisions/:recipe_revision
```

| Attribute          | Type   | Required | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | yes      | The project ID or full project path.                                                        |
| `package_name`     | string | yes      | Name of a package.                                                                          |
| `package_version`  | string | yes      | Version of a package.                                                                       |
| `package_username` | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`  | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`  | string | yes      | Revision hash of the recipe revision to delete.                                                |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/2be19f5a69b2cb02ab576755252319b9"
```

## List all recipe files

Lists all recipe files from the package registry.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files
```

| Attribute          | Type   | Required | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | yes      | The project ID or full project path.                                                        |
| `package_name`     | string | yes      | Name of a package.                                                                          |
| `package_version`  | string | yes      | Version of a package.                                                                       |
| `package_username` | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`  | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`  | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files"
```

Example response:

```json
{
  "files": {
    "conan_sources.tgz": {},
    "conanfile.py": {},
    "conanmanifest.txt": {}
  }
}
```

## Get a recipe file

Gets a recipe file from the package registry.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| Attribute          | Type   | Required | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | yes      | The project ID or full project path.                                                        |
| `package_name`     | string | yes      | Name of a package.                                                                          |
| `package_version`  | string | yes      | Version of a package.                                                                       |
| `package_username` | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`  | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`  | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |
| `file_name`        | string | yes      | The name and file extension of the requested file.                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py"
```

You can also write the output to a file by using:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py" \
     >> conanfile.py
```

This example writes to `conanfile.py` in the current directory.

## Upload a recipe file

Uploads a recipe file to the package registry.

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| Attribute          | Type   | Required | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | yes      | The project ID or full project path.                                                        |
| `package_name`     | string | yes      | Name of a package.                                                                          |
| `package_version`  | string | yes      | Version of a package.                                                                       |
| `package_username` | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`  | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`  | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |
| `file_name`        | string | yes      | The name and file extension of the requested file.                                          |

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/upload-v2-package/1.0.0/user/stable/revisions/123456789012345678901234567890ab/files/conanfile.py"
```

Example response:

```json
{
  "id": 38,
  "package_id": 28,
  "created_at": "2025-04-07T12:35:40.841Z",
  "updated_at": "2025-04-07T12:35:40.841Z",
  "size": 24,
  "file_store": 1,
  "file_md5": "131f806af123b497209a516f46d12ffd",
  "file_sha1": "01b992b2b1976a3f4c1e5294d0cab549cd438502",
  "file_name": "conanfile.py",
  "file": {
    "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/28/files/38/conanfile.py"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## List all package revisions

Lists all package revisions for a specific recipe revision and package reference.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions
```

| Attribute                 | Type   | Required | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | yes      | The project ID or full project path.                                                        |
| `package_name`            | string | yes      | Name of a package.                                                                          |
| `package_version`         | string | yes      | Version of a package.                                                                       |
| `package_username`        | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`         | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`         | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |
| `conan_package_reference` | string | yes      | Reference hash of a Conan package. Conan generates this value.                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions"
```

Example response:

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable#75151329520e7685dcf5da49ded2fec0:103f6067a947f366ef91fc1b7da351c588d1827f",
  "revisions": [
    {
      "revision": "2bfb52659449d84ed11356c353bfbe86",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "3bdd2d8c8e76c876ebd1ac0469a4e72c",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## Get latest package revision

Gets the revision hash and creation date of the latest package revision for a specific recipe revision and package reference.

```plaintext
GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/latest
```

| Attribute                 | Type   | Required | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | yes      | The project ID or full project path.                                                        |
| `package_name`            | string | yes      | Name of a package.                                                                          |
| `package_version`         | string | yes      | Version of a package.                                                                       |
| `package_username`        | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`         | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`         | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |
| `conan_package_reference` | string | yes      | Reference hash of a Conan package. Conan generates this value.                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/latest"
```

Example response:

```json
{
  "revision" : "3bdd2d8c8e76c876ebd1ac0469a4e72c",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## Delete a package revision

Deletes the package revision from the registry. If the package reference has only one package revision, the package reference is deleted as well.

```plaintext
DELETE /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision
```

| Attribute                 | Type   | Required | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | yes      | The project ID or full project path.                                                        |
| `package_name`            | string | yes      | Name of a package.                                                                          |
| `package_version`         | string | yes      | Version of a package.                                                                       |
| `package_username`        | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`         | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`         | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                             |
| `conan_package_reference` | string | yes      | Reference hash of a Conan package. Conan generates this value.                              |
| `package_revision`        | string | yes      | Revision of the package. Does not accept a value of `0`.                                    |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c"
```

## Get a package file

Gets a package file from the package registry.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| Attribute                 | Type   | Required | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | yes      | The project ID or full project path.                                                        |
| `package_name`            | string | yes      | Name of a package.                                                                          |
| `package_version`         | string | yes      | Version of a package.                                                                       |
| `package_username`        | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`         | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`         | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |
| `conan_package_reference` | string | yes      | Reference hash of a Conan package. Conan generates this value.                              |
| `package_revision`        | string | yes      | Revision of the package. Does not accept a value of `0`.                                    |
| `file_name`               | string | yes      | The name and file extension of the requested file.                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

You can also write the output to a file by using:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt" \
     >> conaninfo.txt
```

This example writes to `conaninfo.txt` in the current directory.

## Upload a package file

Uploads a package file to the package registry.

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| Attribute                 | Type   | Required | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | yes      | The project ID or full project path.                                                        |
| `package_name`            | string | yes      | Name of a package.                                                                          |
| `package_version`         | string | yes      | Version of a package.                                                                       |
| `package_username`        | string | yes      | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`         | string | yes      | Channel of a package.                                                                       |
| `recipe_revision`         | string | yes      | Revision of the recipe. Does not accept a value of `0`.                                     |
| `conan_package_reference` | string | yes      | Reference hash of a Conan package. Conan generates this value.                              |
| `package_revision`        | string | yes      | Revision of the package. Does not accept a value of `0`.                                    |
| `file_name`               | string | yes      | The name and file extension of the requested file.                                          |

Provide the file context in the request body:

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

Example response:

```json
{
  "id": 202,
  "package_id": 48,
  "created_at": "2025-03-19T10:06:53.626Z",
  "updated_at": "2025-03-19T10:06:53.626Z",
  "size": 208,
  "file_store": 1,
  "file_md5": "bf996313bbdd75944b58f8c673661d99",
  "file_sha1": "02c8adf14c94135fb95d472f96525063efe09ee8",
  "file_name": "conaninfo.txt",
  "file": {
      "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/48/files/202/conaninfo.txt"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## Get package references metadata

Gets the metadata for all package references of a package.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | yes | The project ID or full project path. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/search"
```

Example response:

```json
{
  "103f6067a947f366ef91fc1b7da351c588d1827f": {
    "settings": {
      "arch": "x86_64",
      "build_type": "Release",
      "compiler": "gcc",
      "compiler.libcxx": "libstdc++",
      "compiler.version": "9",
      "os": "Linux"
    },
    "options": {
      "shared": "False"
    },
    "requires": {
      "zlib/1.2.11": null
    },
    "recipe_hash": "75151329520e7685dcf5da49ded2fec0"
  }
}
```

The response includes the following metadata for each package reference:

- `settings`: The build settings used for the package.
- `options`: The package options.
- `requires`: The required dependencies for the package.
- `recipe_hash`: The hash of the recipe.

## Get package references metadata by recipe revision

Gets the metadata for all package references associated with a specific recipe revision.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/search
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | yes | The project ID or full project path. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `recipe_revision`   | string | yes | Revision of the recipe. Does not accept a value of `0`. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/search"
```

Example response:

```json
{
  "103f6067a947f366ef91fc1b7da351c588d1827f": {
    "settings": {
      "arch": "x86_64",
      "build_type": "Release",
      "compiler": "gcc",
      "compiler.libcxx": "libstdc++",
      "compiler.version": "9",
      "os": "Linux"
    },
    "options": {
      "shared": "False"
    },
    "requires": {
      "zlib/1.2.11": null
    },
    "recipe_hash": "75151329520e7685dcf5da49ded2fec0"
  }
}
```

The response includes the following metadata for each package reference:

- `settings`: The build settings used for the package.
- `options`: The package options.
- `requires`: The required dependencies for the package.
- `recipe_hash`: The hash of the recipe.
