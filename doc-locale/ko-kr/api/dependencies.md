---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Dependencies API에 접근하여 리포지토리 내 프로젝트 종속성 정보(패키지 세부 정보, 버전, 취약점, 라이선스 포함)를 검색합니다."
title: Dependencies API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 엔드포인트에 대한 모든 호출에는 인증이 필요합니다. 이 호출을 수행하려면 사용자는 리포지토리를 읽을 권한이 있어야 합니다. 응답에서 취약점을 확인하려면 사용자는 [Project Security Dashboard](../user/application_security/security_dashboard/_index.md)를 읽을 권한이 있어야 합니다.

## 프로젝트 종속성 나열 {#list-project-dependencies}

지정된 프로젝트의 모든 종속성을 나열합니다. 이 작업은 [dependency list](../user/application_security/dependency_list/_index.md) 기능을 부분적으로 반영하며, 이 기능은 Gemnasium에서 지원하는 [languages and package managers](../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#supported-languages-and-files)에만 사용할 수 있습니다.

응답은 [페이지로 나뉘며](rest/_index.md#pagination) 기본적으로 20개의 결과를 반환합니다.

```plaintext
GET /projects/:id/dependencies
GET /projects/:id/dependencies?package_manager=maven
GET /projects/:id/dependencies?package_manager=yarn,bundler
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                                            |
| `package_manager` | 문자열 배열   | 아니요       | 지정된 패키지 관리자에 속하는 종속성을 반환합니다. 유효한 값: `bundler`, `composer`, `conan`, `go`, `gradle`, `maven`, `npm`, `nuget`, `pip`, `pipenv`, `pnpm`, `yarn`, `sbt`, 또는 `setuptools`입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/dependencies"
```

응답 예시:

```json
[
  {
    "name": "rails",
    "version": "5.0.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [
      {
        "name": "DDoS",
        "severity": "unknown",
        "id": 144827,
        "url": "https://gitlab.example.com/group/project/-/security/vulnerabilities/144827"
      }
    ],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  },
  {
    "name": "hanami",
    "version": "1.3.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  }
]
```
