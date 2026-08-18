---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 위키 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [프로젝트 위키](../user/project/wiki/_index.md)를 관리합니다. [그룹 위키](group_wikis.md)용 API도 사용할 수 있습니다.

위키 페이지의 댓글을 `notes`이라고 합니다. 이들과 상호 작용하려면 [노트 API](notes.md#project-wikis)를 사용합니다.

## 모든 위키 페이지 나열 {#list-all-wiki-pages}

지정된 프로젝트의 모든 위키 페이지를 나열합니다.

```plaintext
GET /projects/:id/wikis
```

| 속성      | 유형           | 필수 | 설명 |
| -------------- | -------------- | -------- | ----------- |
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `with_content` | 부울        | 아니요       | 페이지 내용을 포함합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis?with_content=1"
```

응답 예시:

```json
[
  {
    "content" : "Here is an instruction how to deploy this project.",
    "format" : "markdown",
    "slug" : "deploy",
    "title" : "deploy",
    "encoding": "UTF-8"
  },
  {
    "content" : "Our development process is described here.",
    "format" : "markdown",
    "slug" : "development",
    "title" : "development",
    "encoding": "UTF-8"
  },
  {
    "content" : "*  [Deploy](deploy)\n*  [Development](development)",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home",
    "encoding": "UTF-8"
  }
]
```

## 위키 페이지 검색 {#retrieve-a-wiki-page}

프로젝트의 지정된 위키 페이지를 검색합니다.

```plaintext
GET /projects/:id/wikis/:slug
```

| 속성     | 유형           | 필수 | 설명 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `slug`        | 문자열         | 예      | `dir%2Fpage_name`과 같은 위키 페이지의 URL 인코딩 슬러그(고유 문자열)입니다. |
| `render_html` | 부울        | 아니요       | 위키 페이지의 렌더링된 HTML을 반환합니다. |
| `version`     | 문자열         | 아니요       | 위키 페이지 버전 SHA입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/home"
```

응답 예시:

```json
{
  "content" : "home page",
  "format" : "markdown",
  "slug" : "home",
  "title" : "home",
  "encoding": "UTF-8"
}
```

## 위키 페이지 생성 {#create-a-wiki-page}

지정된 프로젝트에 대해 제목, 슬러그 및 내용이 포함된 위키 페이지를 생성합니다.

```plaintext
POST /projects/:id/wikis
```

| 속성 | 유형           | 필수 | 설명 |
| ----------| -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `content` | 문자열         | 예      | 위키 페이지의 내용입니다. |
| `title`   | 문자열         | 예      | 위키 페이지의 제목입니다. |
| `format`  | 문자열         | 아니요       | 위키 페이지의 형식입니다. 사용 가능한 형식은 `markdown`(기본값), `rdoc`, `asciidoc` 및 `org`입니다. |

```shell
curl --data "format=rdoc&title=Hello&content=Hello world" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis"
```

응답 예시:

```json
{
  "content" : "Hello world",
  "format" : "markdown",
  "slug" : "Hello",
  "title" : "Hello",
  "encoding": "UTF-8"
}
```

특수 문자와 다이어그램이 있는 마크다운 콘텐츠의 경우 `--data-urlencode`을 파일 참조와 함께 사용하여 인코딩을 자동으로 처리합니다.

예를 들어 `content.md`라는 파일을 위키 콘텐츠로 생성한 다음 실행합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "title=Page with Complex Content" \
  --data-urlencode "content@content.md" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis"
```

`--data-urlencode "content@content.md"` 옵션은 마크다운 파일의 내용을 URL 인코딩하고 `content` 속성에 할당합니다. 이 인코딩은 특수 문자, 줄 바꿈 및 그렇지 않으면 오류를 유발할 수 있는 복잡한 마크다운 구문을 처리합니다.

응답 예시:

```json
{
"content": "<contents of content.md>",
"format": "markdown",
"slug": "Page-with-Complex-Content",
"title": "Page with Complex Content",
"encoding": "UTF-8"
}
```

## 위키 페이지 업데이트 {#update-a-wiki-page}

지정된 위키 페이지를 업데이트합니다. 위키 페이지를 업데이트하려면 최소한 하나의 매개변수가 필요합니다.

```plaintext
PUT /projects/:id/wikis/:slug
```

| 속성 | 유형           | 필수                          | 설명 |
| --------- | -------        | --------------------------------- | ----------- |
| `id`      | 정수 또는 문자열 | 예                               | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `content` | 문자열         | `title`이 제공되지 않은 경우 예   | 위키 페이지의 내용입니다. |
| `title`   | 문자열         | `content`이 제공되지 않은 경우 예 | 위키 페이지의 제목입니다. |
| `format`  | 문자열         | 아니요                                | 위키 페이지의 형식입니다. 사용 가능한 형식은 `markdown`(기본값), `rdoc`, `asciidoc` 및 `org`입니다. |
| `slug`    | 문자열         | 예                               | `dir%2Fpage_name`과 같은 위키 페이지의 URL 인코딩 슬러그(고유 문자열)입니다. |

```shell
curl --request PUT \
  --data "format=rdoc&content=documentation&title=Docs" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

응답 예시:

```json
{
  "content" : "documentation",
  "format" : "markdown",
  "slug" : "Docs",
  "title" : "Docs",
  "encoding": "UTF-8"
}
```

## 위키 페이지 삭제 {#delete-a-wiki-page}

지정된 위키 페이지를 삭제합니다.

```plaintext
DELETE /projects/:id/wikis/:slug
```

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `slug`    | 문자열         | 예      | `dir%2Fpage_name`과 같은 위키 페이지의 URL 인코딩 슬러그(고유 문자열)입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

성공한 경우, `204 No Content` HTTP 응답과 빈 본문이 예상됩니다.

## 위키 리포지토리에 첨부파일 업로드 {#upload-an-attachment-to-the-wiki-repository}

위키의 리포지토리 내부 첨부파일 폴더에 파일을 업로드합니다. 첨부파일 폴더는 `uploads` 폴더입니다.

```plaintext
POST /projects/:id/wikis/attachments
```

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `file`    | 문자열         | 예      | 업로드할 첨부파일입니다. |
| `branch`  | 문자열         | 아니요       | 브랜치의 이름입니다. 위키 리포지토리 기본 브랜치로 기본값이 설정됩니다. |

파일 시스템에서 파일을 업로드하려면 `--form` 인수를 사용하세요. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`가 앞에 와야 합니다. 예를 들어:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@dk.png" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/attachments"
```

응답 예시:

```json
{
  "file_name" : "dk.png",
  "file_path" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
  "branch" : "main",
  "link" : {
    "url" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
    "markdown" : "![A description of the attachment](uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png)"
  }
}
```
