---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NuGet API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This is the API documentation for [NuGet Packages](../../user/packages/nuget_repository/_index.md).

WARNING:
This API is used by the [NuGet package manager client](https://www.nuget.org/)
and is generally not meant for manual consumption.

For instructions on how to upload and install NuGet packages from the GitLab
Package Registry, see the [NuGet package registry documentation](../../user/packages/nuget_repository/_index.md).

NOTE:
These endpoints do not adhere to the standard API authentication methods.
See the [NuGet package registry documentation](../../user/packages/nuget_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.

## Package index

Returns the index for a given package, which includes a list of available versions:

```plaintext
GET projects/:id/packages/nuget/download/:package_name/index
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | yes      | The ID or full path of the project. |
| `package_name` | string | yes      | The name of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/index"
```

Example response:

```json
{
  "versions": [
    "1.3.0.17"
  ]
}
```

## Download a package file

Download a NuGet package file. The [metadata service](#metadata-service) provides this URL.

```plaintext
GET projects/:id/packages/nuget/download/:package_name/:package_version/:package_filename
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | yes      | The ID or full path of the project. |
| `package_name`    | string | yes      | The name of the package. |
| `package_version` | string | yes      | The version of the package. |
| `package_filename`| string | yes      | The name of the file. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg"
```

Write the output to a file:

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg" > MyNuGetPkg.1.3.0.17.nupkg
```

This writes the downloaded file to `MyNuGetPkg.1.3.0.17.nupkg` in the current directory.

## Upload a package file

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) in GitLab 16.2 for NuGet v2 feed.

Upload a NuGet package file:

- For NuGet v3 feed:

  ```plaintext
  PUT projects/:id/packages/nuget
  ```

- For NuGet V2 feed:

  ```plaintext
  PUT projects/:id/packages/nuget/v2
  ```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | yes      | The ID or full path of the project. |
| `package_name`    | string | yes      | The name of the package. |
| `package_version` | string | yes      | The version of the package. |
| `package_filename`| string | yes      | The name of the file. |

- For NuGet v3 feed:

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      "https://gitlab.example.com/api/v4/projects/1/packages/nuget/"
  ```

- For NuGet v2 feed:

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
  ```

## Upload a symbol package file

Upload a NuGet symbol package file (`.snupkg`):

```plaintext
PUT projects/:id/packages/nuget/symbolpackage
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | yes      | The ID or full path of the project. |
| `package_name`    | string | yes      | The name of the package. |
| `package_version` | string | yes      | The version of the package. |
| `package_filename`| string | yes      | The name of the file. |

```shell
curl --request PUT \
     --form 'package=@path/to/mynugetpkg.1.3.0.17.snupkg' \
     --user <username>:<personal_access_token> \
     "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage"
```

## Route prefix

For the remaining routes, there are two sets of identical routes that each make requests in
different scopes:

- Use the group-level prefix to make requests in a group's scope.
- Use the project-level prefix to make requests in a single project's scope.

The examples in this document all use the project-level prefix.

### Group-level

```plaintext
/groups/:id/-/packages/nuget
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The group ID or full group path. |

### Project-level

```plaintext
/projects/:id/packages/nuget
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | yes      | The project ID or full project path. |

## Service Index

### V2 source feed/protocol

Returns an XML document that represents the service index of the v2 NuGet source feed.
Authentication is not required:

```plaintext
GET <route-prefix>/v2
```

Example Request:

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
```

Example response:

```xml
<?xml version="1.0" encoding="utf-8"?>
<service xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
  <workspace>
    <atom:title type="text">Default</atom:title>
    <collection href="Packages">
      <atom:title type="text">Packages</atom:title>
    </collection>
  </workspace>
</service>
```

### V3 source feed/protocol

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/214674) to be public in GitLab 16.1.

Returns a list of available API resources.
Authentication is not required:

```plaintext
GET <route-prefix>/index
```

Example Request:

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/index"
```

Example response:

```json
{
  "version": "3.0.0",
  "resources": [
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService/3.0.0-beta",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService/3.0.0-rc",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl/3.0.0-beta",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl/3.0.0-rc",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download",
      "@type": "PackageBaseAddress/3.0.0",
      "comment": "Get package content (.nupkg)."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget",
      "@type": "PackagePublish/2.0.0",
      "comment": "Push and delete (or unlist) packages."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage",
      "@type": "SymbolPackagePublish/4.9.0",
      "comment": "Push symbol packages."
    }
  ]
}
```

The URLs in the response have the same route prefix used to request them. If you request them with
the group-level route, the returned URLs contain `/groups/:id/-`.

## Metadata Service

Returns metadata for a package:

```plaintext
GET <route-prefix>/metadata/:package_name/index
```

| Attribute      | Type   | Required | Description |
| -------------- | ------ | -------- | ----------- |
| `package_name` | string | yes      | The name of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/index"
```

Example response:

```json
{
  "count": 1,
  "items": [
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
      "lower": "1.3.0.17",
      "upper": "1.3.0.17",
      "count": 1,
      "items": [
        {
          "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
          "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
          "catalogEntry": {
            "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
            "authors": "Author1, Author2",
            "dependencyGroups": [],
            "id": "MyNuGetPkg",
            "version": "1.3.0.17",
            "tags": "",
            "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
            "description": "Description of the package",
            "summary": "Description of the package",
            "published": "2023-05-08T17:23:25Z",
          }
        }
      ]
    }
  ]
}
```

## Version Metadata Service

Returns metadata for a specific package version:

```plaintext
GET <route-prefix>/metadata/:package_name/:package_version
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `package_name`    | string | yes      | The name of the package.    |
| `package_version` | string | yes      | The version of the package. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17"
```

Example response:

```json
{
  "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
  "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
  "catalogEntry": {
    "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
    "authors": "Author1, Author2",
    "dependencyGroups": [],
    "id": "MyNuGetPkg",
    "version": "1.3.0.17",
    "tags": "",
    "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
    "description": "Description of the package",
    "summary": "Description of the package",
    "published": "2023-05-08T17:23:25Z",
  }
}
```

## Search Service

Given a query, search for NuGet packages in the repository:

```plaintext
GET <route-prefix>/query
```

| Attribute    | Type    | Required | Description |
| ------------ | ------- | -------- | ----------- |
| `q`          | string  | yes      | The search query. |
| `skip`       | integer | no       | The number of results to skip. |
| `take`       | integer | no       | The number of results to return. |
| `prerelease` | boolean | no       | Include prerelease versions. Defaults to `true` if no value is supplied. |

```shell
curl --user <username>:<personal_access_token> "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query?q=MyNuGet"
```

Example response:

```json
{
  "totalHits": 1,
  "data": [
    {
      "@type": "Package",
      "authors": "Author1, Author2",
      "id": "MyNuGetPkg",
      "title": "MyNuGetPkg",
      "description": "Description of the package",
      "summary": "Description of the package",
      "totalDownloads": 0,
      "verified": true,
      "version": "1.3.0.17",
      "versions": [
        {
          "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
          "version": "1.3.0.17",
          "downloads": 0
        }
      ],
      "tags": ""
    }
  ]
}
```

## Delete service

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) in GitLab 16.5.

Delete a NuGet package:

```plaintext
DELETE projects/:id/packages/nuget/:package_name/:package_version
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | yes      | The ID or full path of the project. |
| `package_name`    | string | yes      | The name of the package. |
| `package_version` | string | yes      | The version of the package. |

```shell
curl --request DELETE \
     --user <username>:<personal_access_token> \
     "https://gitlab.example.com/api/v4/projects/1/packages/nuget/MyNuGetPkg/1.3.0.17"
```

Possible request responses:

| Status | Description |
| ------ | ----------- |
| `204`  | Package deleted |
| `401`  | Unauthorized |
| `403`  | Forbidden |
| `404`  | Not found |

## Download a debugging symbol file `.pdb`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416178) in GitLab 16.7.

Download a debugging symbol file (`.pdb`):

```plaintext
GET <route-prefix>/symbolfiles/:file_name/:signature/:file_name
```

| Attribute         | Type   | Required | Description |
| ----------------- | ------ | -------- | ----------- |
| `file_name`       | string | yes      | The name of the file. |
| `signature`       | string | yes      | The signature of the file. |
| `Symbolchecksum` | string | yes      | Required header. The checksum of the file. |

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/:file_name/:signature/:file_name"
```

Write the output to a file:

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/mynugetpkg.pdb/k813f89485474661234z7109cve5709eFFFFFFFF/mynugetpkg.pdb" > mynugetpkg.pdb
```

Possible request responses:

| Status | Description |
| ------ | ----------- |
| `200`  | File downloaded |
| `400`  | Bad request |
| `403`  | Forbidden |
| `404`  | Not found |

## V2 Feed Metadata Endpoints

> - Introduced in GitLab 16.3.

### $metadata endpoint

Authentication is not required. Returns metadata for a V2 feed available endpoints:

```plaintext
GET <route-prefix>/v2/$metadata
```

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/$metadata"
```

Example response:

```xml
<edmx:Edmx xmlns:edmx="http://schemas.microsoft.com/ado/2007/06/edmx" Version="1.0">
  <edmx:DataServices xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" m:DataServiceVersion="2.0" m:MaxDataServiceVersion="2.0">
    <Schema xmlns="http://schemas.microsoft.com/ado/2006/04/edm" Namespace="NuGetGallery.OData">
      <EntityType Name="V2FeedPackage" m:HasStream="true">
        <Key>
          <PropertyRef Name="Id"/>
          <PropertyRef Name="Version"/>
        </Key>
        <Property Name="Id" Type="Edm.String" Nullable="false"/>
        <Property Name="Version" Type="Edm.String" Nullable="false"/>
        <Property Name="Authors" Type="Edm.String"/>
        <Property Name="Dependencies" Type="Edm.String"/>
        <Property Name="Description" Type="Edm.String"/>
        <Property Name="DownloadCount" Type="Edm.Int64" Nullable="false"/>
        <Property Name="IconUrl" Type="Edm.String"/>
        <Property Name="Published" Type="Edm.DateTime" Nullable="false"/>
        <Property Name="ProjectUrl" Type="Edm.String"/>
        <Property Name="Tags" Type="Edm.String"/>
        <Property Name="Title" Type="Edm.String"/>
        <Property Name="LicenseUrl" Type="Edm.String"/>
      </EntityType>
    </Schema>
    <Schema xmlns="http://schemas.microsoft.com/ado/2006/04/edm" Namespace="NuGetGallery">
      <EntityContainer Name="V2FeedContext" m:IsDefaultEntityContainer="true">
        <EntitySet Name="Packages" EntityType="NuGetGallery.OData.V2FeedPackage"/>
        <FunctionImport Name="FindPackagesById" ReturnType="Collection(NuGetGallery.OData.V2FeedPackage)" EntitySet="Packages">
          <Parameter Name="id" Type="Edm.String" FixedLength="false" Unicode="false"/>
        </FunctionImport>
      </EntityContainer>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>
```

### OData package entry endpoints

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127667) in GitLab 16.4.

| Endpoint | Description |
| -------- | ----------- |
| `GET projects/:id/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq '<package_name>')` | Returns an OData XML document containing information about the package with the given name. |
| `GET projects/:id/packages/nuget/v2/FindPackagesById()?id='<package_name>'` | Returns an OData XML document containing information about the package with the given name. |
| `GET projects/:id/packages/nuget/v2/Packages(Id='<package_name>',Version='<package_version>')` | Returns an OData XML document containing information about the package with the given name and version. |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')"
```

Example response:

```xml
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
    <id>https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')</id>
    <category term="V2FeedPackage" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme"/>
    <title type="text">mynugetpkg</title>
    <content type="application/zip" src="https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/mynugetpkg/1.0.0/mynugetpkg.1.0.0.nupkg"/>
    <m:properties>
      <d:Version>1.0.0</d:Version>
    </m:properties>
 </entry>
```

NOTE:
GitLab doesn't receive an authentication token for the `Packages()` and
`FindPackagesByID()` endpoints, so the latest version of the package
cannot be returned. You must provide the version when you install
or upgrade a package with the NuGet v2 feed.

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq 'mynugetpkg')"
```

Example response:

```xml
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
    <id>https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='')</id>
    <category term="V2FeedPackage" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme"/>
    <title type="text">mynugetpkg</title>
    <content type="application/zip" src="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"/>
    <m:properties>
      <d:Version></d:Version>
    </m:properties>
 </entry>
```
