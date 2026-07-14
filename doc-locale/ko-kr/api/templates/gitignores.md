---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: .gitignore API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 .gitignore 템플릿을 검색합니다. 자세한 내용은 [Git documentation for `.gitignore`](https://git-scm.com/docs/gitignore)을 참조하세요.

게스트 역할을 가진 사용자는 `.gitignore` 템플릿에 액세스할 수 없습니다. 자세한 정보는 [프로젝트 및 그룹 가시성](../../user/public_access.md)을 참조하세요.

## 모든 `.gitignore` 템플릿 나열 {#list-all-gitignore-templates}

모든 `.gitignore` 템플릿을 나열합니다.

```plaintext
GET /templates/gitignores
```

성공하면 [`200 OK`](../rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성 | 유형   | 설명 |
|-----------|--------|-------------|
| `key`     | 문자열 | `.gitignore` 템플릿의 키 식별자입니다. |
| `name`    | 문자열 | `.gitignore` 템플릿의 표시 이름입니다. |

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores"
```

응답 예:

```json
[
  {
    "key": "Actionscript",
    "name": "Actionscript"
  },
  {
    "key": "Ada",
    "name": "Ada"
  },
  {
    "key": "Agda",
    "name": "Agda"
  },
  {
    "key": "Android",
    "name": "Android"
  },
  {
    "key": "AppEngine",
    "name": "AppEngine"
  },
  {
    "key": "AppceleratorTitanium",
    "name": "AppceleratorTitanium"
  },
  {
    "key": "ArchLinuxPackages",
    "name": "ArchLinuxPackages"
  },
  {
    "key": "Autotools",
    "name": "Autotools"
  },
  {
    "key": "C",
    "name": "C"
  },
  {
    "key": "C++",
    "name": "C++"
  },
  {
    "key": "CFWheels",
    "name": "CFWheels"
  },
  {
    "key": "CMake",
    "name": "CMake"
  },
  {
    "key": "CUDA",
    "name": "CUDA"
  },
  {
    "key": "CakePHP",
    "name": "CakePHP"
  },
  {
    "key": "ChefCookbook",
    "name": "ChefCookbook"
  },
  {
    "key": "Clojure",
    "name": "Clojure"
  },
  {
    "key": "CodeIgniter",
    "name": "CodeIgniter"
  },
  {
    "key": "CommonLisp",
    "name": "CommonLisp"
  },
  {
    "key": "Composer",
    "name": "Composer"
  },
  {
    "key": "Concrete5",
    "name": "Concrete5"
  }
]
```

## 단일 `.gitignore` 템플릿 검색 {#retrieve-a-single-gitignore-template}

단일 `.gitignore` 템플릿을 검색합니다.

```plaintext
GET /templates/gitignores/:key
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `key`     | 문자열 | 예      | `.gitignore` 템플릿의 키입니다. |

성공하면 [`200 OK`](../rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성 | 유형   | 설명 |
|-----------|--------|-------------|
| `content` | 문자열 | `.gitignore` 템플릿의 내용입니다. |
| `name`    | 문자열 | `.gitignore` 템플릿의 표시 이름입니다. |

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores/Ruby"
```

응답 예:

```json
{
  "name": "Ruby",
  "content": "*.gem\n*.rbc\n/.config\n/coverage/\n/InstalledFiles\n/pkg/\n/spec/reports/\n/spec/examples.txt\n/test/tmp/\n/test/version_tmp/\n/tmp/\n\n# Used by dotenv library to load environment variables.\n# .env\n\n## Specific to RubyMotion:\n.dat*\n.repl_history\nbuild/\n*.bridgesupport\nbuild-iPhoneOS/\nbuild-iPhoneSimulator/\n\n## Specific to RubyMotion (use of CocoaPods):\n#\n# We recommend against adding the Pods directory to your .gitignore. However\n# you should judge for yourself, the pros and cons are mentioned at:\n# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control\n#\n# vendor/Pods/\n\n## Documentation cache and generated files:\n/.yardoc/\n/_yardoc/\n/doc/\n/rdoc/\n\n## Environment normalization:\n/.bundle/\n/vendor/bundle\n/lib/bundler/man/\n\n# for a library or gem, you might want to ignore these files since the code is\n# intended to run in multiple environments; otherwise, check them in:\n# Gemfile.lock\n# .ruby-version\n# .ruby-gemset\n\n# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:\n.rvmrc\n"
}
```
