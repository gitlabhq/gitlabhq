---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dockerfiles API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 전체 인스턴스에서 사용 가능한 Dockerfile 템플릿을 위한 API 엔드포인트를 제공합니다. 기본 템플릿은 GitLab 리포지토리의 [`vendor/Dockerfile`](https://gitlab.com/gitlab-org/gitlab-foss/-/tree/master/vendor/Dockerfile)에 정의됩니다.

게스트 역할을 가진 사용자는 Dockerfiles 템플릿에 액세스할 수 없습니다. 자세한 정보는 [프로젝트 및 그룹 가시성](../../user/public_access.md)을 참조하세요.

## Dockerfile API 템플릿 재정의 {#override-dockerfile-api-templates}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GitLab Premium 및 Ultimate](https://about.gitlab.com/pricing/) 계층에서 GitLab 인스턴스 관리자는 [**운영자** 영역](../../administration/settings/instance_template_repository.md)의 템플릿을 재정의할 수 있습니다.

## 모든 Dockerfile 템플릿 나열 {#list-all-dockerfile-templates}

모든 Dockerfile 템플릿을 나열합니다.

```plaintext
GET /templates/dockerfiles
```

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles"
```

응답 예:

```json
[
  {
    "key": "Binary",
    "name": "Binary"
  },
  {
    "key": "Binary-alpine",
    "name": "Binary-alpine"
  },
  {
    "key": "Binary-scratch",
    "name": "Binary-scratch"
  },
  {
    "key": "Golang",
    "name": "Golang"
  },
  {
    "key": "Golang-alpine",
    "name": "Golang-alpine"
  },
  {
    "key": "Golang-scratch",
    "name": "Golang-scratch"
  },
  {
    "key": "HTTPd",
    "name": "HTTPd"
  },
  {
    "key": "Node",
    "name": "Node"
  },
  {
    "key": "Node-alpine",
    "name": "Node-alpine"
  },
  {
    "key": "OpenJDK",
    "name": "OpenJDK"
  },
  {
    "key": "PHP",
    "name": "PHP"
  },
  {
    "key": "Python",
    "name": "Python"
  },
  {
    "key": "Python-alpine",
    "name": "Python-alpine"
  },
  {
    "key": "Python2",
    "name": "Python2"
  },
  {
    "key": "Ruby",
    "name": "Ruby"
  },
  {
    "key": "Ruby-alpine",
    "name": "Ruby-alpine"
  },
  {
    "key": "Rust",
    "name": "Rust"
  },
  {
    "key": "Swift",
    "name": "Swift"
  }
]
```

## 단일 Dockerfile 템플릿 검색 {#retrieve-a-single-dockerfile-template}

단일 Dockerfile 템플릿을 검색합니다.

```plaintext
GET /templates/dockerfiles/:key
```

| 속성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `key`     | 문자열 | 예      | Dockerfile 템플릿의 키 |

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles/Binary"
```

응답 예:

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```
