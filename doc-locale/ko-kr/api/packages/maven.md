---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Maven API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 [Maven 패키지 관리자 클라이언트](../../user/packages/maven_repository/_index.md)와 상호 작용하는 데 사용합니다.

> [!warning]
> 이 API는 [Maven 패키지 관리자 클라이언트](https://maven.apache.org/)에서 사용하며 일반적으로 수동 사용을 위해 고안되지 않았습니다.

이 엔드포인트는 표준 API 인증 방법을 따르지 않습니다. 지원되는 헤더 및 토큰 유형에 대한 세부 정보는 [Maven 패키지 레지스트리](../../user/packages/maven_repository/_index.md) 설명서를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 인스턴스용 패키지 파일 다운로드 {#download-a-package-file-for-an-instance}

인스턴스용 지정된 Maven 패키지 파일을 다운로드합니다.

```plaintext
GET packages/maven/*path/:file_name
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `path`       | 문자열 | 예 | Maven 패키지 레지스트리 경로는 `<groupId>/<artifactId>/<version>` 형식입니다. `.`의 `groupId` 항목을 모두 `/`로 바꿉니다. |
| `file_name`  | 문자열 | 예 | Maven 패키지 파일의 이름입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

출력을 파일로 쓰려면:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

다운로드한 파일이 `mypkg-1.0-SNAPSHOT.jar`로 현재 디렉터리에 기록됩니다.

## 그룹 수준용 패키지 파일 다운로드 {#download-a-package-file-for-a-group-level}

그룹용 지정된 Maven 패키지 파일을 다운로드합니다.

```plaintext
GET groups/:id/-/packages/maven/*path/:file_name
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `path`       | 문자열 | 예 | Maven 패키지 레지스트리 경로는 `<groupId>/<artifactId>/<version>` 형식입니다. `.`의 `groupId` 항목을 모두 `/`로 바꿉니다. |
| `file_name`  | 문자열 | 예 | Maven 패키지 파일의 이름입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

출력을 파일로 쓰려면:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

다운로드한 파일이 `mypkg-1.0-SNAPSHOT.jar`로 현재 디렉터리에 기록됩니다.

## 프로젝트용 패키지 파일 다운로드 {#download-a-package-file-for-a-project}

프로젝트용 지정된 Maven 패키지 파일을 다운로드합니다.

```plaintext
GET projects/:id/packages/maven/*path/:file_name
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `path`       | 문자열 | 예 | Maven 패키지 레지스트리 경로는 `<groupId>/<artifactId>/<version>` 형식입니다. `.`의 `groupId` 항목을 모두 `/`로 바꿉니다. |
| `file_name`  | 문자열 | 예 | Maven 패키지 파일의 이름입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

출력을 파일로 쓰려면:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

다운로드한 파일이 `mypkg-1.0-SNAPSHOT.jar`로 현재 디렉터리에 기록됩니다.

## 패키지 파일 업로드 {#upload-a-package-file}

프로젝트용 지정된 Maven 패키지 파일을 업로드합니다.

```plaintext
PUT projects/:id/packages/maven/*path/:file_name
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `path`       | 문자열 | 예 | Maven 패키지 레지스트리 경로는 `<groupId>/<artifactId>/<version>` 형식입니다. `.`의 `groupId` 항목을 모두 `/`로 바꿉니다. |
| `file_name`  | 문자열 | 예 | Maven 패키지 파일의 이름입니다. |

```shell
curl --request PUT \
     --upload-file path/to/mypkg-1.0-SNAPSHOT.pom \
     --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.pom"
```
