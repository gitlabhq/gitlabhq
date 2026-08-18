---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 템플릿 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 다음 엔드포인트의 프로젝트별 버전을 검색합니다:

- [Dockerfile 템플릿](templates/dockerfiles.md)
- [Gitignore 템플릿](templates/gitignores.md)
- [GitLab CI/CD 구성 템플릿](templates/gitlab_ci_ymls.md)
- [오픈 소스 라이선스 템플릿](templates/licenses.md)
- [이슈 및 머지 리퀘스트 템플릿](../user/project/description_templates.md)

이러한 엔드포인트는 더 이상 사용되지 않으며 API 버전 5에서 제거될 예정입니다.

전체 인스턴스에 공통적인 템플릿 외에도 이 API 엔드포인트에서 프로젝트별 템플릿을 사용할 수 있습니다.

[그룹의 파일 템플릿](../user/group/manage.md#group-file-templates)에 대한 지원도 제공됩니다.

## 특정 유형의 모든 템플릿 나열 {#list-all-templates-of-a-particular-type}

프로젝트의 지정된 유형의 모든 템플릿을 나열합니다.

```plaintext
GET /projects/:id/templates/:type
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `type`    | 문자열            | 예      | 템플릿의 유형입니다. 허용되는 값: `dockerfiles`, `gitignores`, `gitlab_ci_ymls`, `licenses`, `issues` 또는 `merge_requests`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형   | 설명 |
|-----------|--------|-------------|
| `key`     | 문자열 | 템플릿의 고유 식별자입니다. |
| `name`    | 문자열 | 템플릿의 사람이 읽을 수 있는 이름입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/licenses"
```

응답 예시(라이선스):

```json
[
  {
    "key": "epl-1.0",
    "name": "Eclipse Public License 1.0"
  },
  {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0"
  },
  {
    "key": "unlicense",
    "name": "The Unlicense"
  },
  {
    "key": "agpl-3.0",
    "name": "GNU Affero General Public License v3.0"
  },
  {
    "key": "gpl-3.0",
    "name": "GNU General Public License v3.0"
  },
  {
    "key": "bsd-3-clause",
    "name": "BSD 3-clause \"New\" or \"Revised\" License"
  },
  {
    "key": "lgpl-2.1",
    "name": "GNU Lesser General Public License v2.1"
  },
  {
    "key": "mit",
    "name": "MIT License"
  },
  {
    "key": "apache-2.0",
    "name": "Apache License 2.0"
  },
  {
    "key": "bsd-2-clause",
    "name": "BSD 2-clause \"Simplified\" License"
  },
  {
    "key": "mpl-2.0",
    "name": "Mozilla Public License 2.0"
  },
  {
    "key": "gpl-2.0",
    "name": "GNU General Public License v2.0"
  }
]
```

## 특정 유형의 템플릿 검색 {#retrieve-a-template-of-a-particular-type}

프로젝트의 지정된 유형의 템플릿을 검색합니다.

```plaintext
GET /projects/:id/templates/:type/:name
```

지원되는 속성:

| 속성                    | 유형              | 필수 | 설명 |
|------------------------------|-------------------|----------|-------------|
| `id`                         | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                       | 문자열            | 예      | 컬렉션 엔드포인트에서 얻은 템플릿의 키입니다. |
| `type`                       | 문자열            | 예      | 템플릿의 유형입니다. 다음 중 하나: `dockerfiles`, `gitignores`, `gitlab_ci_ymls`, `licenses`, `issues` 또는 `merge_requests`입니다. |
| `fullname`                   | 문자열            | 아니요       | 템플릿의 플레이스홀더를 확장할 때 사용할 저작권 소유자의 전체 이름입니다. 라이선스에만 영향을 미칩니다. |
| `project`                    | 문자열            | 아니요       | 템플릿의 플레이스홀더를 확장할 때 사용할 프로젝트 이름입니다. 라이선스에만 영향을 미칩니다. |
| `source_template_project_id` | 정수           | 아니요       | 주어진 템플릿이 저장되는 프로젝트 ID입니다. 다른 프로젝트의 여러 템플릿이 동일한 이름을 가질 때 유용합니다. 여러 템플릿이 동일한 이름을 가진 경우 `source_template_project_id`을(를) 지정하지 않으면 가장 가까운 상위 항목의 일치가 반환됩니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성     | 유형     | 설명                                                   |
|---------------|----------|---------------------------------------------------------------|
| `conditions`  | 배열    | 라이선스 조건의 배열입니다. 라이선스에만 사용 가능합니다.    |
| `content`     | 문자열   | 템플릿 콘텐츠입니다.                                             |
| `description` | 문자열   | 라이선스의 설명입니다. 라이선스에만 사용 가능합니다.     |
| `html_url`    | 문자열   | 라이선스 정보 페이지로의 URL입니다. 라이선스에만 사용 가능합니다. |
| `key`         | 문자열   | 템플릿의 고유 식별자입니다. 라이선스에만 사용 가능합니다. |
| `limitations` | 배열    | 라이선스 제한 사항의 배열입니다. 라이선스에만 사용 가능합니다.   |
| `name`        | 문자열   | 템플릿의 사람이 읽을 수 있는 이름입니다.                          |
| `nickname`    | 문자열   | 라이선스의 일반적인 별칭입니다. 라이선스에만 사용 가능합니다. |
| `permissions` | 배열    | 라이선스 권한의 배열입니다. 라이선스에만 사용 가능합니다.   |
| `popular`     | 부울  | `true`이면 인기 있는 라이선스임을 나타냅니다. 라이선스에만 사용 가능합니다. |
| `source_url`  | 문자열   | 라이선스 소스로의 URL입니다. 라이선스에만 사용 가능합니다.      |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/dockerfiles/Binary"
```

응답 예시(Dockerfile):

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/licenses/mit"
```

응답 예시(라이선스):

```json
{
  "key": "mit",
  "name": "MIT License",
  "nickname": null,
  "popular": true,
  "html_url": "http://choosealicense.com/licenses/mit/",
  "source_url": "https://opensource.org/licenses/MIT",
  "description": "A short and simple permissive license with conditions only requiring preservation of copyright and license notices. Licensed works, modifications, and larger works may be distributed under different terms and without source code.",
  "conditions": [
    "include-copyright"
  ],
  "permissions": [
    "commercial-use",
    "modifications",
    "distribution",
    "private-use"
  ],
  "limitations": [
    "liability",
    "warranty"
  ],
  "content": "MIT License\n\nCopyright (c) 2018 [fullname]\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n"
}
```
