---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This is the API documentation for [Conan Packages](../../user/packages/conan_repository/_index.md).

WARNING:
This API is used by the [Conan package manager client](https://docs.conan.io/en/latest/)
and is generally not meant for manual consumption.

For instructions on how to upload and install Conan packages from the GitLab
package registry, see the [Conan package registry documentation](../../user/packages/conan_repository/_index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See each route for details on how credentials are expected to be passed. Undocumented authentication methods might be removed in the future.

NOTE:
The Conan registry is not FIPS compliant and is disabled when [FIPS mode](../../development/fips_gitlab.md) is enabled.
These endpoints will all return 404 Not Found.

## Route prefix

There are two sets of identical routes that each make requests in different scopes:

- Use the instance-level prefix to make requests in the entire GitLab instance's scope.
- Use the project-level prefix to make requests in a single project's scope.

The examples in this document all use the instance-level prefix.

### Instance-level

```plaintext
/packages/conan/v1
```

When using the instance-level routes, be aware that there is a
[naming restriction](../../user/packages/conan_repository/_index.md#package-recipe-naming-convention-for-instance-remotes)
for Conan recipes.

### Project-level

```plaintext
/projects/:id/packages/conan/v1
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The project ID or full project path. |

## Ping

Ping the GitLab Conan repository to verify availability:

```plaintext
GET <route-prefix>/ping
```

```shell
curl "https://gitlab.example.com/api/v4/packages/conan/v1/ping"
```

Example response:

```json
""
```

## Search

Search the instance for Conan packages by name:

```plaintext
GET <route-prefix>/conans/search
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Authenticate

Returns a JWT to be used for Conan requests in a Bearer header:

```shell
"Authorization: Bearer <token>
```

The Conan package manager client automatically uses this token.

```plaintext
GET <route-prefix>/users/authenticate
```

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/packages/conan/v1/users/authenticate"
```

Example response:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Check Credentials

Checks the validity of Basic Auth credentials or a Conan JWT generated from [`/authenticate`](#authenticate).

```plaintext
GET <route-prefix>/users/check_credentials
```

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/packages/conan/v1/users/check_credentials
```

Example response:

```shell
ok
```

## Recipe Snapshot

This returns the snapshot of the recipe files for the specified Conan recipe. The snapshot is a list
of filenames with their associated md5 hash.

```plaintext
GET <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Package Snapshot

This returns the snapshot of the package files for the specified Conan recipe with the specified
Conan reference. The snapshot is a list of filenames with their associated md5 hash.

```plaintext
GET <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Recipe Manifest

The manifest is a list of recipe filenames with their associated download URLs.

```plaintext
GET <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/digest
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Package Manifest

The manifest is a list of package filenames with their associated download URLs.

```plaintext
GET <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Recipe Download URLs

Recipe download URLs return a list of recipe filenames with their associated download URLs.
This attribute is the same payload as the [recipe manifest](#recipe-manifest) endpoint.

```plaintext
GET <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Package Download URLs

Package download URLs return a list of package filenames with their associated download URLs.
This URL is the same payload as the [package manifest](#package-manifest) endpoint.

```plaintext
GET <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Recipe Upload URLs

Given a list of recipe filenames and file sizes, a list of URLs to upload each file is returned.

```plaintext
POST <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

Example request JSON payload:

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

## Package Upload URLs

Given a list of package filenames and file sizes, a list of URLs to upload each file is returned.

```plaintext
POST <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |
| `conan_package_reference` | string | yes | Reference hash of a Conan package. Conan generates this value. |

Example request JSON payload:

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

## Download a Recipe file

Download a recipe file to the package registry. You must use a download URL that the
[recipe download URLs endpoint](#recipe-download-urls)
returned.

```plaintext
GET packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Upload a Recipe file

Upload a recipe file to the package registry. You must use an upload URL that the
[recipe upload URLs endpoint](#recipe-upload-urls)
returned.

```plaintext
PUT packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Download a Package file

Download a package file to the package registry. You must use a download URL that the
[package download URLs endpoint](#package-download-urls)
returned.

```plaintext
GET packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Upload a Package file

Upload a package file to the package registry. You must use an upload URL that the
[package upload URLs endpoint](#package-upload-urls)
returned.

```plaintext
PUT packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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

## Delete a Package (delete a Conan recipe)

Delete the Conan recipe and package files from the registry:

```plaintext
DELETE <route-prefix>/conans/:package_name/:package_version/:package_username/:package_channel
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
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
