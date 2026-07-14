---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 라이선스 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab에는 다양한 오픈소스 라이선스 템플릿으로 작업하기 위한 API 엔드포인트가 있습니다. 다양한 라이선스 조건에 대한 자세한 정보는 [이 사이트](https://choosealicense.com/) 또는 온라인에서 이용할 수 있는 다른 많은 리소스를 참조하세요.

게스트 역할이 있는 사용자는 라이선스 템플릿에 액세스할 수 없습니다. 자세한 정보는 [프로젝트 및 그룹 가시성](../../user/public_access.md)을 참조하세요.

## 모든 라이선스 템플릿 나열 {#list-all-license-templates}

모든 라이선스 템플릿을 나열합니다.

```plaintext
GET /templates/licenses
```

| 속성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `popular` | 부울 | 아니오       | 이를 전달하면 인기 있는 라이선스만 반환합니다 |

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/licenses?popular=1"
```

응답 예:

```json
[
  {
    "key":"apache-2.0",
    "name":"Apache License 2.0",
    "nickname":null,
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/apache-2.0/",
    "source_url":"http://www.apache.org/licenses/LICENSE-2.0.html",
    "description":"A permissive license that also provides an express grant of patent rights from contributors to users.",
    "conditions":[
      "include-copyright",
      "document-changes"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "patent-use",
      "private-use"
    ],
    "limitations":[
      "trademark-use",
      "no-liability"
    ],
    "content":"                                 Apache License\n                           Version 2.0, January 2004\n [...]"
  },
  {
    "key":"gpl-3.0",
    "name":"GNU General Public License v3.0",
    "nickname":"GNU GPLv3",
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/gpl-3.0/",
    "source_url":"http://www.gnu.org/licenses/gpl-3.0.txt",
    "description":"The GNU GPL is the most widely used free software license and has a strong copyleft requirement. When distributing derived works, the source code of the work must be made available under the same license.",
    "conditions":[
      "include-copyright",
      "document-changes",
      "disclose-source",
      "same-license"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "patent-use",
      "private-use"
    ],
    "limitations":[
      "no-liability"
    ],
    "content":"                    GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007\n [...]"
  },
  {
    "key":"mit",
    "name":"MIT License",
    "nickname":null,
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/mit/",
    "source_url":"http://opensource.org/licenses/MIT",
    "description":"A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
    "conditions":[
      "include-copyright"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "private-use"
    ],
    "limitations":[
      "no-liability"
    ],
    "content":"The MIT License (MIT)\n\nCopyright (c) [year] [fullname]\n [...]"
  }
]
```

## 단일 라이선스 템플릿 검색 {#retrieve-a-single-license-template}

단일 라이선스 템플릿을 검색합니다. 라이선스 자리 표시자를 바꾸기 위해 매개변수를 전달할 수 있습니다.

```plaintext
GET /templates/licenses/:key
```

| 속성  | 유형   | 필수 | 설명 |
|------------|--------|----------|-------------|
| `key`      | 문자열 | 예      | 라이선스 템플릿의 키 |
| `project`  | 문자열 | 아니오       | 저작권이 있는 프로젝트 이름 |
| `fullname` | 문자열 | 아니오       | 저작권 보유자의 전체 이름 |

> [!note]
> `fullname` 매개변수를 생략하지만 요청을 인증하면 인증된 사용자의 이름이 저작권 보유자 자리 표시자를 대체합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/templates/licenses/mit?project=My+Cool+Project"
```

응답 예:

```json
{
  "key":"mit",
  "name":"MIT License",
  "nickname":null,
  "featured":true,
  "html_url":"http://choosealicense.com/licenses/mit/",
  "source_url":"http://opensource.org/licenses/MIT",
  "description":"A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
  "conditions":[
    "include-copyright"
  ],
  "permissions":[
    "commercial-use",
    "modifications",
    "distribution",
    "private-use"
  ],
  "limitations":[
    "no-liability"
  ],
  "content":"The MIT License (MIT)\n\nCopyright (c) 2016 John Doe\n [...]"
}
```
