---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Go 프록시 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Go 패키지 관리자 클라이언트](../../user/packages/go_proxy/_index.md)와 상호작용합니다. 이 API는 기본적으로 비활성화된 기능 플래그 뒤에 있습니다. GitLab Rails 콘솔에 액세스할 수 있는 GitLab 관리자는 GitLab 인스턴스에 대해 이 API를 [활성화](../../administration/feature_flags/_index.md)할 수 있습니다.

> [!warning]
> 이 API는 [`go` 명령](https://go.dev/ref/mod#go-get)으로 사용되며 일반적으로 수동 사용을 위한 것이 아닙니다.

이러한 끝점은 표준 API 인증 방법을 준수하지 않습니다. 지원되는 헤더 및 토큰 유형에 대한 세부 정보는 [Go 프록시 패키지 설명서](../../user/packages/go_proxy/_index.md)를 참고하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 목록 {#list}

주어진 Go 모듈의 모든 태그된 버전을 가져옵니다:

```plaintext
GET projects/:id/packages/go/:module_name/@v/list
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 문자열 | 예      | 프로젝트의 프로젝트 ID 또는 전체 경로입니다. |
| `module_name`  | 문자열 | 예      | Go 모듈의 이름입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/list"
```

출력 예:

```shell
"v1.0.0\nv1.0.1\nv1.3.8\n2.0.0\n2.1.0\n3.0.0"
```

## 버전 메타데이터 {#version-metadata}

주어진 Go 모듈의 모든 태그된 버전을 가져옵니다:

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.info
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 프로젝트 ID 또는 전체 경로입니다. |
| `module_name`     | 문자열 | 예      | Go 모듈의 이름입니다. |
| `module_version`  | 문자열 | 예      | Go 모듈의 버전입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.info"
```

출력 예:

```json
{
  "Version": "v1.0.0",
  "Time": "1617822312 -0600"
}
```

## 모듈 파일 다운로드 {#download-module-file}

`.mod` 모듈 파일을 가져옵니다:

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.mod
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 프로젝트 ID 또는 전체 경로입니다. |
| `module_name`     | 문자열 | 예      | Go 모듈의 이름입니다. |
| `module_version`  | 문자열 | 예      | Go 모듈의 버전입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.mod"
```

파일에 쓰기:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.mod" >> foo.mod
```

현재 디렉터리의 `foo.mod`에 쓰입니다.

## 모듈 소스 다운로드 {#download-module-source}

모듈 소스의 `.zip`을 가져옵니다:

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.zip
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 프로젝트의 프로젝트 ID 또는 전체 경로입니다. |
| `module_name`     | 문자열 | 예      | Go 모듈의 이름입니다. |
| `module_version`  | 문자열 | 예      | Go 모듈의 버전입니다. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.zip"
```

파일에 쓰기:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.zip" >> foo.zip
```

현재 디렉터리의 `foo.zip`에 쓰입니다.
