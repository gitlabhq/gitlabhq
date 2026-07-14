---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 Git 리포지토리에 대한 REST API 설명서입니다.
title: 리포지토리 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Git 리포지토리](../user/project/repository/_index.md)를 관리합니다.

## 프로젝트의 모든 리포지토리 트리 나열 {#list-all-repository-trees-in-a-project}

지정된 프로젝트의 모든 리포지토리 파일 및 디렉터리를 나열합니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

이 명령은 기본적으로 `git ls-tree` 명령과 동일한 기능을 제공합니다. 자세한 내용은 Git 내부 설명서에서 [트리 객체](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html#_tree_objects)를 참조하세요.

> [!warning]
> GitLab 버전 17.7에서는 요청된 경로를 찾을 수 없을 때 오류 처리 동작을 변경합니다. 엔드포인트는 이제 상태 코드 `404 Not Found`를 반환합니다. 이전에는 상태 코드가 `200 OK`였습니다.
>
> 구현이 누락된 경로에 대한 빈 배열과 함께 `200` 상태 코드를 받는 것에 의존하는 경우 오류 처리를 업데이트하여 새로운 `404` 응답을 처리해야 합니다.

```plaintext
GET /projects/:id/repository/tree
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `page_token` | 문자열            | 아니요       | 다음 페이지를 가져올 트리 레코드 ID입니다. 키셋 페이지 매김에서만 사용됩니다. |
| `pagination` | 문자열            | 아니요       | `keyset`이면 [키셋 기반 페이지 매김 방법](rest/_index.md#keyset-based-pagination)을 사용합니다. |
| `path`       | 문자열            | 아니요       | 리포지토리 내부의 경로입니다. 하위 디렉터리의 콘텐츠를 가져오는 데 사용됩니다. |
| `per_page`   | 정수           | 아니요       | 페이지당 표시할 결과의 수입니다. 지정하지 않으면 `20`로 기본값이 설정됩니다. 자세한 내용은 [페이지 매김](rest/_index.md#pagination)을 참조하세요. |
| `recursive`  | 부울           | 아니요       | `true`이면 재귀 트리를 가져옵니다. 기본값은 `false`입니다. |
| `ref`        | 문자열            | 아니요       | 리포지토리 브랜치 또는 태그의 이름입니다. 지정하지 않으면 기본 브랜치를 사용합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 트리 객체의 배열을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/tree"
```

응답 예시:

```json
[
  {
    "id": "a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba",
    "name": "html",
    "type": "tree",
    "path": "files/html",
    "mode": "040000"
  },
  {
    "id": "4535904260b1082e14f867f7a24fd8c21495bde3",
    "name": "images",
    "type": "tree",
    "path": "files/images",
    "mode": "040000"
  },
  {
    "id": "31405c5ddef582c5a9b7a85230413ff90e2fe720",
    "name": "js",
    "type": "tree",
    "path": "files/js",
    "mode": "040000"
  },
  {
    "id": "cc71111cfad871212dc99572599a568bfe1e7e00",
    "name": "lfs",
    "type": "tree",
    "path": "files/lfs",
    "mode": "040000"
  },
  {
    "id": "fd581c619bf59cfdfa9c8282377bb09c2f897520",
    "name": "markdown",
    "type": "tree",
    "path": "files/markdown",
    "mode": "040000"
  },
  {
    "id": "23ea4d11a4bdd960ee5320c5cb65b5b3fdbc60db",
    "name": "ruby",
    "type": "tree",
    "path": "files/ruby",
    "mode": "040000"
  },
  {
    "id": "7d70e02340bac451f281cecf0a980907974bd8be",
    "name": "whitespace",
    "type": "blob",
    "path": "files/whitespace",
    "mode": "100644"
  }
]
```

## 리포지토리에서 blob 검색 {#retrieve-a-blob-from-a-repository}

리포지토리의 blob에 대한 크기 및 콘텐츠와 같은 정보를 검색합니다. Blob 콘텐츠는 Base64로 인코딩됩니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

10MB보다 큰 blob의 경우 이 엔드포인트는 분당 5개 요청의 속도 제한이 있습니다.

```plaintext
GET /projects/:id/repository/blobs/:sha
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `sha`     | 문자열            | 예      | Blob SHA입니다.   |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성  | 유형    | 설명 |
|------------|---------|-------------|
| `content`  | 문자열  | Base64로 인코딩된 blob 콘텐츠입니다. |
| `encoding` | 문자열  | blob 콘텐츠에 사용된 인코딩입니다. |
| `sha`      | 문자열  | Blob SHA입니다.   |
| `size`     | 정수 | 바이트 단위의 blob 크기입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83"
```

응답 예시:

```json
{
  "size": 1476,
  "encoding": "base64",
  "content": "VGhpcyBpcyBhIGJpbmFyeSBmaWxl",
  "sha": "79f7bbd25901e8334750839545a9bd021f0e4c83"
}
```

## 원본 blob 콘텐츠 검색 {#retrieve-raw-blob-content}

blob SHA별로 blob에 대한 원본 파일 콘텐츠를 검색합니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `sha`     | 문자열            | 예      | Blob SHA입니다.   |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83/raw"
```

## 리포지토리에서 파일 아카이브 검색 {#retrieve-file-archive-from-a-repository}

지정된 리포지토리의 파일 아카이브를 검색합니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

GitLab.com 사용자의 경우 이 엔드포인트는 분당 5개 요청의 속도 제한 임계값이 있습니다.

```plaintext
GET /projects/:id/repository/archive[.format]
```

`format`은(는) 아카이브 형식에 대한 선택적 접미사이며 `tar.gz`로 기본값이 설정됩니다. 예를 들어 `archive.zip`을(를) 지정하면 ZIP 형식의 아카이브를 전송합니다. 사용 가능한 옵션은:

- `bz2`
- `tar`
- `tar.bz2`
- `tar.gz`
- `tb2`
- `tbz`
- `tbz2`
- `zip`

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `exclude_paths`     | 문자열            | 아니요       | 아카이브에서 제외할 경로의 쉼표로 구분된 목록입니다. |
| `include_lfs_blobs` | 부울           | 아니요       | `true`이면 LFS 객체가 아카이브에 포함됩니다. `false`로 설정하면 LFS 객체가 제외됩니다. 기본값은 `true`입니다. |
| `path`              | 문자열            | 아니요       | 다운로드할 리포지토리의 하위 경로입니다. 빈 문자열이면 전체 리포지토리로 기본값이 설정됩니다. |
| `sha`               | 문자열            | 아니요       | 다운로드할 커밋 SHA입니다. 태그, 브랜치 참조 또는 SHA를 허용합니다. 지정하지 않으면 기본 브랜치의 끝으로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>&path=<path>&exclude_paths=<path1,path2>"
```

## 브랜치, 태그 또는 커밋 비교 {#compare-branches-tags-or-commits}

{{< history >}}

- `collapsed` 및 `too_large` 응답 속성 [GitLab 18.4에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633).

{{< /history >}}

지정된 프로젝트에서 두 브랜치, 태그 또는 커밋 간의 차이를 검색합니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

`compare_timeout`이(가) `true`일 때 비교가 크기 제한을 초과하거나 시간이 초과되었습니다:

- `commits` 배열은 항상 완전합니다.
- `diffs` 배열은 불완전할 수 있습니다.
- 개별 diff 객체의 `diff` 문자열이 비어 있을 수 있으며, 해당 콘텐츠가 제한을 초과한 경우입니다.

```plaintext
GET /projects/:id/repository/compare
```

지원되는 속성:

| 속성         | 유형              | 필수 | 설명 |
|-------------------|-------------------|----------|-------------|
| `from`            | 문자열            | 예      | 커밋 SHA 또는 브랜치 이름입니다. |
| `id`              | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `to`              | 문자열            | 예      | 커밋 SHA 또는 브랜치 이름입니다. |
| `from_project_id` | 정수           | 아니요       | 비교할 ID입니다. |
| `straight`        | 부울           | 아니요       | `true`이면 비교 방법은 `from`와 `to` 간의 직접 비교입니다(`from`..`to`). `false`이면 병합 베이스를 사용하여 비교합니다(`from`...`to`). 기본값은 `false`입니다. |
| `unidiff`         | 부울           | 아니요       | `true`이면 [통합 diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) 형식으로 diff를 표시합니다. 기본값은 `false`입니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                | 유형         | 설명 |
|--------------------------|--------------|-------------|
| `commit`                 | 객체       | 비교의 최신 커밋의 세부 사항입니다. |
| `commits`                | 객체 배열 | 두 참조 간의 커밋. `compare_timeout`이(가) `true`일 때도 항상 완전합니다. |
| `commits[].author_email` | 문자열       | 커밋 작성자의 이메일 주소입니다. |
| `commits[].author_name`  | 문자열       | 커밋 작성자의 이름입니다. |
| `commits[].created_at`   | 날짜/시간     | 커밋 생성 타임스탬프입니다. |
| `commits[].id`           | 문자열       | 전체 커밋 SHA입니다. |
| `commits[].short_id`     | 문자열       | 짧은 커밋 SHA입니다. |
| `commits[].title`        | 문자열       | 커밋 제목입니다. |
| `compare_same_ref`       | 부울      | `true`이면 비교는 from과 to 모두에 대해 동일한 참조를 사용합니다. |
| `compare_timeout`        | 부울      | `true`이면 비교가 크기 제한을 초과하거나 시간이 초과되었습니다. `diffs` 배열은 불완전할 수 있습니다. |
| `diffs`                  | 객체 배열 | 파일 차이의 목록입니다. |
| `diffs[].a_mode`         | 문자열       | 이전 파일 모드입니다. |
| `diffs[].b_mode`         | 문자열       | 새 파일 모드입니다. |
| `diffs[].collapsed`      | 부울      | `true`이면 파일 diff가 제외되지만 요청 시 가져올 수 있습니다. |
| `diffs[].deleted_file`   | 부울      | `true`이면 파일이 제거되었습니다. |
| `diffs[].diff`           | 문자열       | 파일의 변경 사항을 표시하는 Diff 콘텐츠입니다. |
| `diffs[].new_file`       | 부울      | `true`이면 파일이 추가되었습니다. |
| `diffs[].new_path`       | 문자열       | 파일의 새 경로입니다. |
| `diffs[].old_path`       | 문자열       | 파일의 이전 경로입니다. |
| `diffs[].renamed_file`   | 부울      | `true`이면 파일의 이름이 변경되었습니다. |
| `diffs[].too_large`      | 부울      | `true`이면 파일 diff가 제외되고 검색할 수 없습니다. |
| `web_url`                | 문자열       | 비교를 보기 위한 웹 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/compare?from=main&to=feature"
```

응답 예시:

```json
{
  "commit": {
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  },
  "commits": [{
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  }],
  "diffs": [{
    "old_path": "files/js/application.js",
    "new_path": "files/js/application.js",
    "a_mode": null,
    "b_mode": "100644",
    "diff": "@@ -24,8 +24,10 @@\n //= require g.raphael-min\n //= require g.bar-min\n //= require branch-graph\n-//= require highlightjs.min\n-//= require ace/ace\n //= require_tree .\n //= require d3\n //= require underscore\n+\n+function fix() { \n+  alert(\"Fixed\")\n+}",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/compare/ae73cb07c9eeaf35924a10f713b364d32b2dd34f...0b4bc9a49b562e85de7cc9e834518ea6828729b9"
}
```

## 기여자 목록 가져오기 {#get-contributor-list}

{{< history >}}

- `ref` [GitLab 17.4에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156852).

{{< /history >}}

리포지토리 기여자 목록을 가져옵니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

반환된 커밋 개수에는 병합 커밋이 포함되지 않습니다.

```plaintext
GET /projects/:id/repository/contributors
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `order_by` | 문자열            | 아니요       | 기여자를 `name`, `email` 또는 `commits`(커밋 수)로 정렬합니다. 지정하지 않으면 기여자가 커밋 날짜 순서로 정렬됩니다. |
| `ref`      | 문자열            | 아니요       | 리포지토리 브랜치 또는 태그의 이름입니다. 지정하지 않으면 기본 브랜치. |
| `sort`     | 문자열            | 아니요       | 기여자를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `asc`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성   | 유형    | 설명 |
|-------------|---------|-------------|
| `additions` | 정수 | 기여자의 줄 추가 수입니다. |
| `commits`   | 정수 | 기여자의 커밋 수입니다. |
| `deletions` | 정수 | 기여자의 줄 삭제 수입니다. |
| `email`     | 문자열  | 기여자의 이메일 주소입니다. |
| `name`      | 문자열  | 기여자의 이름입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/repository/contributors"
```

응답 예시:

```json
[{
  "name": "Example User",
  "email": "example@example.com",
  "commits": 117,
  "additions": 0,
  "deletions": 0
}, {
  "name": "Sample User",
  "email": "sample@example.com",
  "commits": 33,
  "additions": 0,
  "deletions": 0
}]
```

## 병합 베이스 가져오기 {#get-merge-base}

커밋 SHA, 브랜치 이름 또는 태그와 같은 2개 이상의 참조에 대한 공통 조상을 가져옵니다.

```plaintext
GET /projects/:id/repository/merge_base
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `refs`    | 배열             | 예      | 공통 조상을 찾을 참조입니다. 여러 참조를 허용합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형     | 설명 |
|---------------------|----------|-------------|
| `author_email`      | 문자열   | 작성자의 이메일 주소입니다. |
| `author_name`       | 문자열   | 작성자의 이름입니다. |
| `authored_date`     | 날짜/시간 | 커밋이 작성된 날짜입니다. |
| `committed_date`    | 날짜/시간 | 커밋이 커밋된 날짜입니다. |
| `committer_email`   | 문자열   | 커미터의 이메일 주소입니다. |
| `committer_name`    | 문자열   | 커미터의 이름입니다. |
| `created_at`        | 날짜/시간 | 커밋 생성 타임스탬프입니다. |
| `extended_trailers` | 객체   | Git 트레일러에 대한 확장 정보입니다. |
| `id`                | 문자열   | 전체 커밋 SHA입니다. |
| `message`           | 문자열   | 전체 커밋 메시지입니다. |
| `parent_ids`        | 배열    | 부모 커밋 SHA의 목록입니다. |
| `short_id`          | 문자열   | 짧은 커밋 SHA입니다. |
| `title`             | 문자열   | 커밋 제목입니다. |
| `trailers`          | 객체   | 커밋 메시지에서 구문 분석된 Git 트레일러입니다. |
| `web_url`           | 문자열   | GitLab 웹 인터페이스에서 커밋을 보기 위한 URL입니다. |

참조가 읽기 쉽도록 생략된 예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merge_base?refs[]=304d257d&refs[]=0031876f"
```

응답 예시:

```json
{
  "id": "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863",
  "short_id": "1a0b36b3",
  "title": "Initial commit",
  "created_at": "2014-02-27T08:03:18.000Z",
  "parent_ids": [],
  "message": "Initial commit\n",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2014-02-27T08:03:18.000Z",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "committed_date": "2014-02-27T08:03:18.000Z",
  "trailers": {},
  "extended_trailers": {},
  "web_url": "https://gitlab.example.com/example-group/example-project/-/commit/1a0b36b3cdad1d2ee32457c102a8c0b7056fa863"
}
```

## 변경 로그 데이터 생성 {#generate-changelog-data}

{{< history >}}

- [GitLab 17.7에서 인증 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172842) 이 [CI/CD 작업 토큰](../ci/jobs/ci_job_token.md)을 통해 이루어졌습니다.
- `config_file_ref` 속성 [GitLab 18.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/426108).
- 일반 텍스트 형식(`.txt`) [GitLab 19.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237585).

{{< /history >}}

리포지토리의 커밋에 기반하여 변경 로그 데이터를 생성합니다. 변경 로그 파일에 커밋하지 않습니다.

`POST /projects/:id/repository/changelog`과(와) 정확히 동일하게 작동하지만 변경 로그 데이터는 변경 로그 파일에 커밋되지 않습니다.

```plaintext
GET /projects/:id/repository/changelog
```

선택사항. 변경 로그를 JSON 대신 일반 텍스트 Markdown으로 반환하는 `.txt` 접미사를 추가할 수 있습니다:

```plaintext
GET /projects/:id/repository/changelog.txt
```

지원되는 속성:

| 속성         | 유형     | 필수 | 설명 |
|-------------------|----------|----------|-------------|
| `version`         | 문자열   | 예      | 변경 로그를 생성할 버전입니다. 형식은 [시멘틱 버전 관리](https://semver.org/)를 따라야 합니다. |
| `config_file`     | 문자열   | 아니요       | 프로젝트의 Git 리포지토리의 변경 로그 구성 파일 경로입니다. `.gitlab/changelog_config.yml`로 기본값이 설정됩니다. |
| `config_file_ref` | 문자열   | 아니요       | 변경 로그 구성 파일이 정의된 Git 참조(예: 브랜치)입니다. 기본 리포지토리 브랜치로 기본값이 설정됩니다. |
| `date`            | 날짜/시간 | 아니요       | 릴리스의 날짜 및 시간입니다. ISO 8601 형식을 사용합니다. 예: `2016-03-11T03:45:40Z`. 현재 시간으로 기본값이 설정됩니다. |
| `from`            | 문자열   | 아니요       | 변경 로그를 생성하는 데 사용할 커밋 범위(SHA)의 시작입니다. 이 커밋 자체는 목록에 포함되지 않습니다. |
| `to`              | 문자열   | 아니요       | 변경 로그에 사용할 커밋 범위(SHA)의 끝입니다. 이 커밋은 목록에 포함됩니다. 기본 프로젝트 브랜치의 HEAD로 기본값이 설정됩니다. |
| `trailer`         | 문자열   | 아니요       | 커밋을 포함하는 데 사용할 Git 트레일러입니다. `Changelog`로 기본값이 설정됩니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형   | 설명 |
|-----------|--------|-------------|
| `notes`   | 문자열 | Markdown 형식으로 생성된 변경 로그 데이터입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0"
```

읽기 쉽도록 줄 바꿈이 추가된 예제 응답:

```json
{
  "notes": "## 1.0.0 (2021-11-17)\n\n### feature (2 changes)\n\n-
    [Title 2](namespace13/project13@ad608eb642124f5b3944ac0ac772fecaf570a6bf)
    ([merge request](namespace13/project13!2))\n-
    [Title 1](namespace13/project13@3c6b80ff7034fa0d585314e1571cc780596ce3c8)
    ([merge request](namespace13/project13!1))\n"
}
```

`.txt` 형식의 예제 요청:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog.txt?version=1.0.0"
```

응답 예시:

```plaintext
## 1.0.0 (2021-11-17)

### feature (2 changes)

- [Title 2](namespace13/project13@ad608eb642124f5b3944ac0ac772fecaf570a6bf)
  ([merge request](namespace13/project13!2))
- [Title 1](namespace13/project13@3c6b80ff7034fa0d585314e1571cc780596ce3c8)
  ([merge request](namespace13/project13!1))
```

## 파일에 변경 로그 데이터 추가 {#add-changelog-data-to-file}

{{< history >}}

- GitLab 17.3에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/issues/364101). 기능 플래그 `changelog_commits_limitation` 제거됨.
- `config_file_ref` [GitLab 18.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/426108).

{{< /history >}}

리포지토리의 커밋에 기반하여 변경 로그 데이터를 생성하고 변경 로그 파일에 커밋합니다.

[시멘틱 버전](https://semver.org/) 및 커밋 범위가 주어지면 GitLab은 특정 [Git 트레일러](https://git-scm.com/docs/git-interpret-trailers)를 사용하는 모든 커밋에 대한 변경 로그를 생성합니다. GitLab은 프로젝트의 Git 리포지토리의 변경 로그 파일에 새로운 Markdown 형식의 섹션을 추가합니다. 출력 형식을 사용자 지정할 수 있습니다.

성능 및 보안상의 이유로 변경 로그 구성 구문 분석은 2초로 제한됩니다. 이 제한은 잘못된 변경 로그 템플릿으로 인한 잠재적 DoS 공격을 방지하는 데 도움이 됩니다. 요청 시간이 초과되면 `changelog_config.yml` 파일의 크기를 줄이는 것이 좋습니다.

사용자 대면 설명서는 [변경 로그](../user/project/changelogs.md)를 참조하세요.

```plaintext
POST /projects/:id/repository/changelog
```

변경 로그는 다음 속성을 지원합니다:

| 속성              | 유형     | 필수 | 설명 |
|------------------------|----------|----------|-------------|
| `version` <sup>1</sup> | 문자열   | 예      | 변경 로그를 생성할 버전입니다. 형식은 [시멘틱 버전 관리](https://semver.org/)를 따라야 합니다. |
| `branch`               | 문자열   | 아니요       | 변경 로그 변경 사항을 커밋할 브랜치입니다. 프로젝트의 기본 브랜치로 기본값이 설정됩니다. |
| `config_file`          | 문자열   | 아니요       | 프로젝트의 Git 리포지토리에 있는 변경 로그 구성 파일의 경로입니다. `.gitlab/changelog_config.yml`로 기본값이 설정됩니다. |
| `config_file_ref`      | 문자열   | 아니요       | 변경 로그 구성 파일이 정의된 Git 참조(예: 브랜치)입니다. 기본 리포지토리 브랜치로 기본값이 설정됩니다. |
| `date`                 | 날짜/시간 | 아니요       | 릴리스의 날짜 및 시간입니다. 현재 시간으로 기본값이 설정됩니다. |
| `file`                 | 문자열   | 아니요       | 변경 사항을 커밋할 파일입니다. `CHANGELOG.md`로 기본값이 설정됩니다. |
| `from` <sup>2</sup>    | 문자열   | 아니요       | 변경 로그에 포함할 커밋 범위의 시작을 나타내는 커밋의 SHA입니다. 이 커밋은 변경 로그에 포함되지 않습니다. |
| `message`              | 문자열   | 아니요       | 변경 사항을 커밋할 때 사용할 커밋 메시지입니다. `Add changelog for version X`로 기본값이 설정되며, 여기서 `X`는 `version` 인수의 값입니다. |
| `to`                   | 문자열   | 아니요       | 변경 로그에 포함할 커밋 범위의 끝을 나타내는 커밋의 SHA입니다. 이 커밋은 변경 로그에 포함됩니다. `branch` 속성에 지정된 브랜치로 기본값이 설정됩니다. 15000개 커밋으로 제한됩니다. |
| `trailer`              | 문자열   | 아니요       | 커밋을 포함하는 데 사용할 Git 트레일러입니다. `Changelog`로 기본값이 설정됩니다. 대소문자 구분: `Example`는 `example` 또는 `eXaMpLE`와 일치하지 않습니다. |

**각주**:

1. `version` 속성은 `v` 접두사를 포함하거나 생략할 수 있습니다. `1.0.0` 및 `v1.0.0` 모두 동일한 결과를 생성합니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/437616).

1. `from`이 지정되지 않으면 GitLab은 지정된 버전보다 앞에 있는 마지막 안정적인 버전 태그를 자동으로 찾습니다. GitLab은 시멘틱 버저닝을 따르는 `X.Y.Z` 또는 `vX.Y.Z` 형식의 태그를 인식합니다.

   예를 들어 `version`이(가) `2.1.0`이면 GitLab은 태그 `v2.0.0`을(를) 사용합니다. `version`이(가) `1.1.1` 또는 `1.2.0`이면 GitLab은 태그 `v1.1.0`을(를) 사용합니다. `v1.0.0-pre1`와 같은 사전 릴리스 태그는 무시됩니다.

   적절한 태그를 찾을 수 없으면 API에서 오류를 반환하고 `from` 속성을 명시적으로 지정해야 합니다.

### 예제 {#examples}

이 예제에서는 [cURL](https://curl.se/)을(를) 사용하여 HTTP 요청을 수행합니다. 예제 명령은 다음 값을 사용합니다:

- 프로젝트 ID:  42
- 위치: GitLab.com에서 호스팅됨
- 예제 API 토큰: `token`

이 명령은 버전 `1.0.0`에 대한 변경 로그를 생성합니다.

커밋 범위:

- 마지막 릴리스의 태그로 시작합니다.
- 대상 브랜치의 마지막 커밋으로 끝납니다. 기본 대상 브랜치는 프로젝트의 기본 브랜치입니다.

마지막 태그가 `v0.9.0`이고 기본 브랜치가 `main`이면 이 예제에 포함된 커밋 범위는 `v0.9.0..main`입니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

`branch` 매개변수를 지정하여 다른 브랜치에서 데이터를 생성합니다. 이 명령은 `foo` 브랜치에서 데이터를 생성합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&branch=foo" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

다른 트레일러를 사용하려면 `trailer` 매개변수를 사용합니다:

```shell
curl --request POST --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&trailer=Type" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

결과를 다른 파일에 저장하려면 `file` 매개변수를 사용합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&file=NEWS" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

브랜치를 매개변수로 지정하려면 `to` 속성을 사용합니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0&to=release/x.x.x"
```

## 수동 변경 로그 파일에서 마이그레이션 {#migrate-from-manual-changelog-files}

기존의 수동으로 관리되는 변경 로그 파일에서 Git 트레일러를 사용하는 파일로 마이그레이션할 때 변경 로그 파일이 [예상 형식](../user/project/changelogs.md)과(와) 일치하는지 확인하세요. 그렇지 않으면 API에서 추가한 새 변경 로그 항목이 예상치 못한 위치에 삽입될 수 있습니다. 예를 들어 수동으로 관리되는 변경 로그 파일의 버전 값이 `vX.Y.Z` 대신 `X.Y.Z`으로 지정되면 Git 트레일러를 사용하여 추가된 새 변경 로그 항목이 변경 로그 파일의 끝에 추가됩니다.

[이슈 444183](https://gitlab.com/gitlab-org/gitlab/-/issues/444183)은(는) 변경 로그 파일의 버전 헤더 형식을 사용자 지정하는 것을 제안합니다. 그러나 해당 이슈가 완료될 때까지 변경 로그 파일의 예상 버전 헤더 형식은 `X.Y.Z`입니다.

## 상태 {#health}

{{< history >}}

- [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182220). [`project_repositories_health`](https://gitlab.com/gitlab-org/gitlab/-/issues/521115) 기능 플래그로 보호됩니다.
- 새로운 필드는 [GitLab 18.1에 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191263).

{{< /history >}}

프로젝트 리포지토리의 상태와 관련된 통계를 가져옵니다.

이 엔드포인트는 `generate`이(가) `true`일 때 프로젝트당 시간당 5개 요청으로 속도 제한됩니다. 이 엔드포인트는 리포지토리에 대한 푸시 액세스 권한이 있는 사용자만 사용할 수 있습니다.

```plaintext
GET /projects/:id/repository/health
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명                                                                            |
|------------|---------|----------|----------------------------------------------------------------------------------------|
| `generate` | 부울 | 아니요       | `true`이면 새 상태 보고서를 생성해야 합니다. 엔드포인트가 `404`를 반환하면 이 설정을 사용하세요. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)과(와) 리포지토리 상태 통계를 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/health"
```

응답 예시:

```json
{
  "size": 2619748827,
  "references": {
    "loose_count": 13,
    "packed_size": 333978,
    "reference_backend": "REFERENCE_BACKEND_FILES"
  },
  "objects": {
    "size": 2180475409,
    "recent_size": 2180453999,
    "stale_size": 21410,
    "keep_size": 0,
    "packfile_count": 1,
    "reverse_index_count": 1,
    "cruft_count": 0,
    "keep_count": 0,
    "loose_objects_count": 36,
    "stale_loose_objects_count": 36,
    "loose_objects_garbage_count": 0
  },
  "commit_graph": {
    "commit_graph_chain_length": 1,
    "has_bloom_filters": true,
    "has_generation_data": true,
    "has_generation_data_overflow": false
  },
  "bitmap": null,
  "multi_pack_index": {
    "packfile_count": 1,
    "version": 1
  },
  "multi_pack_index_bitmap": {
    "has_hash_cache": true,
    "has_lookup_table": true,
    "version": 1
  },
  "alternates": null,
  "is_object_pool": false,
  "last_full_repack": {
    "seconds": 1745892013,
    "nanos": 0
  },
  "updated_at": "2025-05-14T02:31:08.022Z"
}
```

응답의 각 필드에 대한 설명은 [`RepositoryInfoResponse`](https://gitlab.com/gitlab-org/gitaly/blob/fcb986a6482f82b088488db3ed7ca35adfa42fdc/proto/repository.proto#L444) protobuf 메시지를 참조하세요.

## 관련 항목 {#related-topics}

- [변경 로그](../user/project/changelogs.md)에 대한 사용자 설명서
