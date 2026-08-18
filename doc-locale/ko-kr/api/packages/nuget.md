---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NuGet API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [NuGet 패키지 관리자 클라이언트](../../user/packages/nuget_repository/_index.md)와 상호작용합니다.

> [!warning]
> 이 API는 [NuGet 패키지 관리자 클라이언트](https://www.nuget.org/)에서 사용되며 일반적으로 수동 사용을 위한 것이 아닙니다.

이러한 끝점은 표준 API 인증 방법을 준수하지 않습니다. [NuGet 패키지 레지스트리 설명서](../../user/packages/nuget_repository/_index.md)를 참조하여 지원되는 헤더 및 토큰 유형에 대한 세부 정보를 확인하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 패키지 인덱스 검색 {#retrieve-a-package-index}

지정된 패키지의 인덱스를 검색합니다. 사용 가능한 버전 목록이 포함됩니다.

```plaintext
GET projects/:id/packages/nuget/download/:package_name/index
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/index"
```

응답 예:

```json
{
  "versions": [
    "1.3.0.17"
  ]
}
```

## 패키지 파일 다운로드 {#download-a-package-file}

프로젝트의 지정된 NuGet 패키지 파일을 다운로드합니다. [메타데이터 서비스](#retrieve-package-metadata)에서 이 URL을 제공합니다.

```plaintext
GET projects/:id/packages/nuget/download/:package_name/:package_version/:package_filename
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name`    | 문자열 | 예      | 패키지의 이름입니다. |
| `package_version` | 문자열 | 예      | 패키지의 버전입니다. |
| `package_filename`| 문자열 | 예      | 파일의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg"
```

파일에 출력을 작성합니다:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg" > MyNuGetPkg.1.3.0.17.nupkg
```

다운로드된 파일을 `MyNuGetPkg.1.3.0.17.nupkg`에 현재 디렉터리로 작성합니다.

> [!note]
> 이 API는 [그룹 끝점](#group-level)을 사용할 때 `404` 상태를 반환합니다. NuGet 패키지 관리자 CLI를 사용하여 [패키지를 설치](../../user/packages/nuget_repository/_index.md#install-a-package)하고 이 오류를 피하기 위해 그룹 끝점과 함께 사용합니다.

## 패키지 파일 업로드 {#upload-a-package-file}

{{< history >}}

- [GitLab 16.2의 NuGet v2 피드에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/416404).

{{< /history >}}

지정된 프로젝트의 NuGet 패키지 파일을 업로드합니다.

- NuGet v3 피드의 경우:

  ```plaintext
  PUT projects/:id/packages/nuget
  ```

- NuGet V2 피드의 경우:

  ```plaintext
  PUT projects/:id/packages/nuget/v2
  ```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name`    | 문자열 | 예      | 패키지의 이름입니다. |
| `package_version` | 문자열 | 예      | 패키지의 버전입니다. |
| `package_filename`| 문자열 | 예      | 파일의 이름입니다. |

- NuGet v3 피드의 경우:

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/"
  ```

- NuGet v2 피드의 경우:

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
  ```

## 기호 패키지 파일 업로드 {#upload-a-symbol-package-file}

프로젝트의 지정된 NuGet 기호 패키지 파일(`.snupkg`)을 업로드합니다.

```plaintext
PUT projects/:id/packages/nuget/symbolpackage
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name`    | 문자열 | 예      | 패키지의 이름입니다. |
| `package_version` | 문자열 | 예      | 패키지의 버전입니다. |
| `package_filename`| 문자열 | 예      | 파일의 이름입니다. |

```shell
curl --request PUT \
     --form 'package=@path/to/mynugetpkg.1.3.0.17.snupkg' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage"
```

## 경로 접두사 {#route-prefix}

나머지 경로의 경우 서로 다른 범위에서 요청을 만드는 두 세트의 동일한 경로가 있습니다:

- 그룹 수준 접두사를 사용하여 그룹의 범위에서 요청을 만듭니다.
- 프로젝트 수준 접두사를 사용하여 단일 프로젝트의 범위에서 요청을 만듭니다.

이 문서의 예제는 모두 프로젝트 수준 접두사를 사용합니다.

### 그룹 수준 {#group-level}

```plaintext
/groups/:id/-/packages/nuget
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 그룹 ID 또는 전체 그룹 경로입니다. |

### 프로젝트 수준 {#project-level}

```plaintext
/projects/:id/packages/nuget
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 프로젝트 ID 또는 전체 프로젝트 경로입니다. |

## 서비스 인덱스 {#service-index}

### V2 소스 피드/프로토콜 {#v2-source-feedprotocol}

v2 NuGet 소스 피드의 서비스 인덱스를 나타내는 XML 문서를 검색합니다. 인증이 필요하지 않습니다.

```plaintext
GET <route-prefix>/v2
```

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
```

응답 예:

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

### V3 소스 피드/프로토콜 {#v3-source-feedprotocol}

{{< history >}}

- [GitLab 16.1에서 공개되도록 변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/214674).

{{< /history >}}

사용 가능한 API 리소스 목록을 검색합니다. 인증이 필요하지 않습니다.

```plaintext
GET <route-prefix>/index
```

요청 예시:

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/index"
```

응답 예:

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

응답의 URL은 요청에 사용된 경로 접두사와 동일합니다. 그룹-수준 경로를 사용하여 요청하면 반환된 URL에 `/groups/:id/-`이 포함됩니다.

## 패키지 메타데이터 검색 {#retrieve-package-metadata}

지정된 패키지의 메타데이터를 검색합니다.

```plaintext
GET <route-prefix>/metadata/:package_name/index
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/index"
```

응답 예:

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

## 버전 메타데이터 검색 {#retrieve-version-metadata}

지정된 패키지 버전의 메타데이터를 검색합니다.

```plaintext
GET <route-prefix>/metadata/:package_name/:package_version
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `package_name`    | 문자열 | 예      | 패키지의 이름입니다.    |
| `package_version` | 문자열 | 예      | 패키지의 버전입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17"
```

응답 예:

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

## 패키지 검색 {#search-for-packages}

지정된 쿼리를 기반으로 리포지토리에서 NuGet 패키지를 검색합니다.

```plaintext
GET <route-prefix>/query
```

| 속성    | 유형    | 필수 | 설명 |
| ------------ | ------- | -------- | ----------- |
| `q`          | 문자열  | 예      | 검색 쿼리입니다. |
| `skip`       | 정수 | 아니오       | 건너뛸 결과 수입니다. |
| `take`       | 정수 | 아니오       | 반환할 결과 수입니다. |
| `prerelease` | 부울 | 아니오       | 사전 릴리스 버전을 포함합니다. 값이 제공되지 않으면 `true`이 기본값입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query?q=MyNuGet"
```

응답 예:

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

## 패키지 삭제 {#delete-a-package}

{{< history >}}

- [GitLab 16.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/38275).

{{< /history >}}

지정된 NuGet 패키지를 삭제합니다.

```plaintext
DELETE projects/:id/packages/nuget/:package_name/:package_version
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name`    | 문자열 | 예      | 패키지의 이름입니다. |
| `package_version` | 문자열 | 예      | 패키지의 버전입니다. |

```shell
curl --request DELETE \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/MyNuGetPkg/1.3.0.17"
```

가능한 요청 응답:

| 상태 | 설명 |
| ------ | ----------- |
| `204`  | 패키지 삭제됨 |
| `401`  | 권한 없음 |
| `403`  | 금지됨 |
| `404`  | 찾을 수 없음 |

## 디버깅 기호 파일 `.pdb`다운로드 {#download-a-debugging-symbol-file-pdb}

{{< history >}}

- [GitLab 16.7에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/416178).

{{< /history >}}

지정된 디버깅 기호 파일(`.pdb`)을 다운로드합니다.

```plaintext
GET <route-prefix>/symbolfiles/:file_name/:signature/:file_name
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `file_name`       | 문자열 | 예      | 파일의 이름입니다. |
| `signature`       | 문자열 | 예      | 파일의 서명입니다. |
| `Symbolchecksum` | 문자열 | 예      | 필수 헤더입니다. 파일의 체크섬입니다. |

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/:file_name/:signature/:file_name"
```

파일에 출력을 작성합니다:

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/mynugetpkg.pdb/k813f89485474661234z7109cve5709eFFFFFFFF/mynugetpkg.pdb" > mynugetpkg.pdb
```

가능한 요청 응답:

| 상태 | 설명 |
| ------ | ----------- |
| `200`  | 파일 다운로드됨 |
| `400`  | 잘못된 요청 |
| `403`  | 금지됨 |
| `404`  | 찾을 수 없음 |

## V2 피드 메타데이터 끝점 {#v2-feed-metadata-endpoints}

{{< history >}}

- GitLab 16.3에서 도입됨.

{{< /history >}}

### $metadata 끝점 {#metadata-endpoint}

인증이 필요하지 않습니다. V2 피드의 사용 가능한 끝점에 대한 메타데이터를 반환합니다:

```plaintext
GET <route-prefix>/v2/$metadata
```

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/$metadata"
```

응답 예:

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

### OData 패키지 항목 끝점 {#odata-package-entry-endpoints}

{{< history >}}

- [GitLab 16.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127667).

{{< /history >}}

| 끝점 | 설명 |
| -------- | ----------- |
| `GET projects/:id/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq '<package_name>')` | 주어진 이름을 가진 패키지에 대한 정보를 포함하는 OData XML 문서를 반환합니다. |
| `GET projects/:id/packages/nuget/v2/FindPackagesById()?id='<package_name>'` | 주어진 이름을 가진 패키지에 대한 정보를 포함하는 OData XML 문서를 반환합니다. |
| `GET projects/:id/packages/nuget/v2/Packages(Id='<package_name>',Version='<package_version>')` | 주어진 이름과 버전을 가진 패키지에 대한 정보를 포함하는 OData XML 문서를 반환합니다. |

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')"
```

응답 예:

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

> [!note]
> GitLab은 `Packages()` 및 `FindPackagesByID()` 끝점에 대한 인증 토큰을 받지 않으므로 패키지의 최신 버전을 반환할 수 없습니다. NuGet v2 피드를 사용하여 패키지를 설치하거나 업그레이드할 때 버전을 제공해야 합니다.

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq 'mynugetpkg')"
```

응답 예:

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
