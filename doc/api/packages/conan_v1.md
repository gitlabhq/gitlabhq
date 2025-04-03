---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan v1 API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

For Conan v2 operations, see [Conan v2 API](conan_v2.md).

{{< /alert >}}

Use this API to interact with the Conan v1 package manager. These endpoints work for both
projects and instances. For more information,
see [Conan packages in the package registry](../../user/packages/conan_repository/_index.md).

Generally, these endpoints are used by the [Conan 1 package manager client](https://docs.conan.io/en/latest/)
and are not meant for manual consumption.

For instructions on how to upload and install Conan packages from the GitLab
package registry, see the [Conan package registry documentation](../../user/packages/conan_repository/_index.md).

{{< alert type="note" >}}

These endpoints do not adhere to the standard API authentication methods.
See each route for details on how credentials are expected to be passed. Undocumented authentication methods might be removed in the future.

{{< /alert >}}

{{< alert type="note" >}}

The Conan registry is not FIPS compliant and is disabled when [FIPS mode](../../development/fips_gitlab.md) is enabled.
These endpoints will all return 404 Not Found.

{{< /alert >}}

## Verify availability of a Conan repository

Verifies the availability of the GitLab Conan repository.

```plaintext
GET /packages/conan/v1/ping
GET /projects/:id/packages/conan/v1/ping
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |

```shell
curl "https://gitlab.example.com/api/v4/packages/conan/v1/ping"
```

Example response:

```json
""
```

## Search for a Conan package

Searches the instance for a Conan package with a specified name.

```plaintext
GET /packages/conan/v1/conans/search
GET /projects/:id/packages/conan/v1/conans/search
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `q`       | string | yes | Search query. You can use `*` as a wildcard. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/packages/conan/v1/conans/search?q=Hello*"
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

## Create an authentication token

Creates a JSON Web Token (JWT) for use as a Bearer header in other requests.

```shell
"Authorization: Bearer <token>
```

The Conan package manager client automatically uses this token.

```plaintext
GET /packages/conan/v1/users/authenticate
GET /projects/:id/packages/conan/v1/users/authenticate
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/packages/conan/v1/users/authenticate"
```

Example response:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Verify authentication credentials

Verifies the validity of Basic Auth credentials or a Conan JWT generated from the [`/authenticate`](#create-an-authentication-token) endpoint.

```plaintext
GET /packages/conan/v1/users/check_credentials
GET /projects/:id/packages/conan/v1/users/check_credentials
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/users/check_credentials
```

Example response:

```shell
ok
```

## Get a recipe snapshot

Gets a snapshot of the files for a specified Conan recipe. The snapshot is a list of filenames
with their associated MD5 hash.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
GET /projects/:id/packages/conan/v1/conans/:package_version/:package_username/:package_channel
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

Example response:

```json
{
  "conan_sources.tgz": "eadf19b33f4c3c7e113faabf26e76277",
  "conanfile.py": "25e55b96a28f81a14ba8e8a8c99eeace",
  "conanmanifest.txt": "5b6fd77a2ba14303ce4cdb08c87e82ab"
}
```

## Get a package snapshot

Gets a snapshot of the files for a specified Conan package and reference. The snapshot is a list of filenames
with their associated MD5 hash.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f"
```

Example response:

```json
{
  "conan_package.tgz": "749b29bdf72587081ca03ec033ee59dc",
  "conaninfo.txt": "32859d737fe84e6a7ccfa4d64dc0d1f2",
  "conanmanifest.txt": "a86b398e813bd9aa111485a9054a2301"
}
```

## Get a recipe manifest

Gets a manifest that includes a list of files and associated download URLs for a specified recipe.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

Example response:

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the project-level route, the returned URLs contain `/projects/:id`.

## Get a package manifest

Gets a manifest that includes a list of files and associated download URLs for a specified package.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
GET /projects/:id/packages/conan/v1/conans/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/digest"
```

Example response:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the project-level route, the returned URLs contain `/projects/:id`.

## List all recipe download URLs

Lists all files and associated download URLs for a specified recipe.
Returns the same payload as the [recipe manifest](#get-a-recipe-manifest) endpoint.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

Example response:

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the project-level route, the returned URLs contain `/projects/:id`.

## List all package download URLs

Lists all files and associated download URLs for a specified package.
Returns the same payload as the [package manifest](#get-a-package-manifest) endpoint.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/download_urls"
```

Example response:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the project-level route, the returned URLs contain `/projects/:id`.

## List all recipe upload URLs

Lists the upload URLs for a specified collection of recipe files. The request must include a JSON object
with the name and size of the individual files.

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

Example request JSON payload:

The payload must include both the name and size of the file.

```json
{
  "conanfile.py": 410,
  "conanmanifest.txt": 130
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conanfile.py":410,"conanmanifest.txt":130}' \
     "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/upload_urls"
```

Example response:

```json
{
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the project-level route, the returned URLs contain `/projects/:id`.

## List all package upload URLs

Lists the upload URLs for a specified collection of package files. The request must include a JSON object
with the name and size of the individual files.

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |

Example request JSON payload:

The payload must include both the name and size of the file.

```json
{
  "conan_package.tgz": 5412,
  "conanmanifest.txt": 130,
  "conaninfo.txt": 210
  }
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conan_package.tgz":5412,"conanmanifest.txt":130,"conaninfo.txt":210}'
     "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/upload_urls"
```

Example response:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the project-level route, the returned URLs contain `/projects/:id`.

## Get a recipe file

Gets a recipe file from the package registry. You must use the download URL returned from the
[recipe download URLs](#list-all-recipe-download-urls) endpoint.

```plaintext
GET packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
GET projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `recipe_revision`   | string | yes | Revision of the recipe. GitLab does not yet support Conan revisions, so the default value of `0` is always used. |
| `file_name`         | string | yes | The name and file extension of the requested file. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

You can also write the output to a file by using:

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py" >> conanfile.py
```

This example writes to `conanfile.py` in the current directory.

## Upload a recipe file

Uploads a specified recipe file in the package registry. You must use the upload URL returned from the
[recipe upload URLs](#list-all-recipe-upload-urls) endpoint.

```plaintext
PUT packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
PUT projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `recipe_revision`   | string | yes | Revision of the recipe. GitLab does not yet support Conan revisions, so the default value of `0` is always used. |
| `file_name`         | string | yes | The name and file extension of the requested file. |

Provide the file context in the request body:

```shell
curl --request PUT \
     --user <username>:<personal_access_token> \
     --upload-file path/to/conanfile.py \
     "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

## Get a package file

Gets a package file from the package registry. You must use the download URL returned from the
[package download URLs](#list-all-package-download-urls) endpoint.

```plaintext
GET packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
GET projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `recipe_revision`   | string | yes | Revision of the recipe. GitLab does not yet support Conan revisions, so the default value of `0` is always used. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |
| `package_revision`  | string | yes | Revision of the package. GitLab does not yet support Conan revisions, so the default value of `0` is always used. |
| `file_name`         | string | yes | The name and file extension of the requested file. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

You can also write the output to a file by using:

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt" >> conaninfo.txt
```

This example writes to `conaninfo.txt` in the current directory.

## Upload a package file

Uploads a specified package file in the package registry. You must use the upload URL returned from the
[package upload URLs](#list-all-package-upload-urls) endpoint.

```plaintext
PUT packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
PUT projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `recipe_revision`   | string | yes | Revision of the recipe. GitLab does not yet support Conan revisions, so the default value of `0` is always used. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |
| `package_revision`  | string | yes | Revision of the package. GitLab does not yet support Conan revisions, so the default value of `0` is always used. |
| `file_name`         | string | yes | The name and file extension of the requested file. |

Provide the file context in the request body:

```shell
curl --request PUT \
     --user <username>:<personal_access_token> \
     --upload-file path/to/conaninfo.txt \
     "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

## Delete a recipe and package

Deletes a specified Conan recipe and the associated package files from the package registry.

```plaintext
DELETE packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
DELETE projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionally | The project ID or full project path. Required only for the project endpoint. |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

```shell
curl --request DELETE --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

Example response:

```json
{
  "id": 1,
  "project_id": 123,
  "created_at": "2020-08-19T13:17:28.655Z",
  "updated_at": "2020-08-19T13:17:28.655Z",
  "name": "my-package",
  "version": "1.0",
  "package_type": "conan",
  "creator_id": null,
  "status": "default"
}
```
