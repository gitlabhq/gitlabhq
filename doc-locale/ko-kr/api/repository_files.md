---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에서 Git 리포지토리 파일을 관리하기 위한 REST API 문서입니다.
title: 리포지토리 파일 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [리포지토리 파일](../user/project/repository/_index.md)을 관리합니다. 이 API에 대해 [속도 제한을 구성](../administration/settings/files_api_rate_limits.md)할 수도 있습니다.

## 개인 액세스 토큰에 사용 가능한 범위 {#available-scopes-for-personal-access-tokens}

[개인 액세스 토큰](../user/profile/personal_access_tokens.md)은 이러한 범위를 지원합니다:

| 범위             | 설명 |
|-------------------|-------------|
| `api`             | 리포지토리 파일에 대한 읽기-쓰기 액세스를 허용합니다. |
| `read_api`        | 리포지토리 파일에 대한 읽기 액세스를 허용합니다. |
| `read_repository` | 리포지토리 파일에 대한 읽기 액세스를 허용합니다. |

## 리포지토리에서 파일 검색 {#retrieve-a-file-from-a-repository}

리포지토리의 지정된 파일에 대한 정보를 검색합니다. 이름, 크기, 파일 내용 등의 정보를 포함합니다. 파일 내용은 Base64로 인코딩됩니다. 리포지토리가 공개적으로 액세스 가능한 경우 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

10MB보다 큰 blob의 경우 이 엔드포인트는 분당 5개 요청의 속도 제한을 갖습니다.

```plaintext
GET /projects/:id/repository/files/:file_path
```

지원되는 속성:

| 특성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `file_path` | 문자열            | 예      | `lib%2Fclass%2Erb`과 같은 URL 인코딩된 전체 파일 경로입니다. |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `ref`       | 문자열            | 예      | 브랜치, 태그 또는 커밋의 이름입니다. 기본 브랜치를 자동으로 사용하려면 `HEAD`을 사용합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성          | 유형    | 설명 |
|--------------------|---------|-------------|
| `blob_id`          | 문자열  | Blob SHA입니다.   |
| `commit_id`        | 문자열  | 파일의 커밋 SHA입니다. |
| `content`          | 문자열  | Base64 인코딩된 파일 내용입니다. |
| `content_sha256`   | 문자열  | 파일 내용의 SHA256 해시입니다. |
| `encoding`         | 문자열  | 파일 내용에 사용된 인코딩입니다. |
| `execute_filemode` | 부울 | `true`인 경우 파일에 실행 플래그가 설정됩니다. |
| `file_name`        | 문자열  | 파일의 이름입니다. |
| `file_path`        | 문자열  | 파일의 전체 경로입니다. |
| `last_commit_id`   | 문자열  | 이 파일을 수정한 마지막 커밋의 SHA입니다. |
| `ref`              | 문자열  | 사용된 브랜치, 태그 또는 커밋의 이름입니다. |
| `size`             | 정수 | 파일의 크기(바이트)입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

브랜치 이름을 모르거나 기본 브랜치를 사용하려는 경우 `HEAD`을 `ref` 값으로 사용할 수 있습니다. 예를 들어:

```shell
curl --header "PRIVATE-TOKEN: " \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=HEAD"
```

예제 응답:

```json
{
  "file_name": "key.rb",
  "file_path": "app/models/key.rb",
  "size": 1476,
  "encoding": "base64",
  "content": "IyA9PSBTY2hlbWEgSW5mb3...",
  "content_sha256": "4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481",
  "ref": "main",
  "blob_id": "79f7bbd25901e8334750839545a9bd021f0e4c83",
  "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50",
  "last_commit_id": "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
  "execute_filemode": false
}
```

### 파일 메타데이터만 가져오기 {#get-file-metadata-only}

`HEAD`을 사용하여 파일 메타데이터만 가져올 수도 있습니다.

```plaintext
HEAD /projects/:id/repository/files/:file_path
```

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

예제 응답:

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: key.rb
X-Gitlab-File-Path: app/models/key.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

## 리포지토리에서 파일 blame 이력 검색 {#retrieve-file-blame-history-from-a-repository}

리포지토리의 지정된 파일에 대한 blame 이력을 검색합니다. 각 blame 범위에는 줄과 해당하는 커밋 정보가 포함됩니다.

```plaintext
GET /projects/:id/repository/files/:file_path/blame
```

지원되는 속성:

| 특성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `file_path`    | 문자열            | 예      | `lib%2Fclass%2Erb`과 같은 URL 인코딩된 전체 파일 경로입니다. |
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `ref`          | 문자열            | 예      | 브랜치, 태그 또는 커밋의 이름입니다. 기본 브랜치를 자동으로 사용하려면 `HEAD`을 사용합니다. |
| `range`        | 해시              | 아니요       | Blame 범위입니다. |
| `range[end]`   | 정수           | 아니요       | blame할 범위의 마지막 줄입니다. |
| `range[start]` | 정수           | 아니요       | blame할 범위의 첫 번째 줄입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성 | 유형   | 설명 |
|-----------|--------|-------------|
| `commit`  | 객체 | blame 범위에 대한 커밋 정보입니다. |
| `lines`   | 배열  | 이 blame 범위에 대한 줄 배열입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

예제 응답:

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'",
      ""
    ]
  }
]
```

### 파일 blame 메타데이터만 가져오기 {#get-file-blame-metadata-only}

`HEAD` 메서드를 사용하여 파일 blame 메타데이터만 반환합니다.

```plaintext
HEAD /projects/:id/repository/files/:file_path/blame
```

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

예제 응답:

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: file.rb
X-Gitlab-File-Path: path/to/file.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

### Blame 범위 요청 {#request-a-blame-range}

Blame 범위를 요청하려면 `range[start]` 및 `range[end]` 매개변수를 지정하고 파일의 시작 및 끝 줄 번호를 입력합니다.

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main&range[start]=1&range[end]=2"
```

예제 응답:

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'"
    ]
  }
]
```

## 리포지토리에서 원본 파일 검색 {#retrieve-a-raw-file-from-a-repository}

리포지토리의 지정된 파일에 대한 원본 파일 내용을 검색합니다.

```plaintext
GET /projects/:id/repository/files/:file_path/raw
```

지원되는 속성:

| 특성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `file_path` | 문자열            | 예      | `lib%2Fclass%2Erb`과 같은 URL 인코딩된 전체 파일 경로입니다. |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `lfs`       | 부울           | 아니요       | `true`인 경우 응답이 포인터가 아닌 Git LFS 파일 내용이어야 하는지 결정합니다. 파일이 Git LFS에서 추적하지 않는 경우 무시됩니다. `false`로 기본값이 설정됩니다. |
| `ref`       | 문자열            | 아니요       | 브랜치, 태그 또는 커밋의 이름입니다. 기본값은 프로젝트의 `HEAD`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb/raw?ref=main"
```

> [!note]
> [리포지토리에서 파일 검색](repository_files.md#retrieve-a-file-from-a-repository)과 유사하게 `HEAD`을 사용하여 파일 메타데이터만 가져올 수 있습니다.

## 리포지토리에서 파일 생성 {#create-a-file-in-a-repository}

{{< history >}}

- 요청 크기 및 속도 제한은 GitLab 18.7에서 도입되었습니다.

{{< /history >}}

지정된 리포지토리에서 파일을 생성합니다. 단일 요청으로 여러 파일을 생성하려면 [커밋 API](commits.md#create-a-commit)을 참조하세요.

```plaintext
POST /projects/:id/repository/files/:file_path
```

> [!note]
> 이 엔드포인트는 [요청 크기 및 속도 제한](../administration/instance_limits.md#commits-and-files-api-limits)에 따릅니다. 기본 300MB 제한보다 큰 요청은 거부됩니다. 20MB보다 큰 요청은 30초마다 3개 요청으로 속도 제한됩니다.

지원되는 속성:

| 특성          | 유형              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `branch`           | 문자열            | 예      | 생성할 브랜치의 이름입니다. 커밋이 이 브랜치에 추가됩니다. |
| `commit_message`   | 문자열            | 예      | 커밋 메시지. |
| `content`          | 문자열            | 예      | 파일의 내용입니다. |
| `file_path`        | 문자열            | 예      | URL 인코딩된 전체 파일 경로입니다. 예: `lib%2Fclass%2Erb`. |
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `author_email`     | 문자열            | 아니요       | 커밋 작성자의 이메일 주소입니다. |
| `author_name`      | 문자열            | 아니요       | 커밋 작성자의 이름입니다. |
| `encoding`         | 문자열            | 아니요       | 인코딩을 `base64`로 변경합니다. 기본값은 `text`입니다. |
| `execute_filemode` | 부울           | 아니요       | `true`인 경우 파일의 `execute` 플래그를 활성화합니다. `false`인 경우 파일의 `execute` 플래그를 비활성화합니다. |
| `start_branch`     | 문자열            | 아니요       | 브랜치를 생성할 기본 브랜치의 이름입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성   | 유형   | 설명 |
|-------------|--------|-------------|
| `branch`    | 문자열 | 파일이 생성된 브랜치의 이름입니다. |
| `file_path` | 문자열 | 생성된 파일의 경로입니다. |

```shell
curl --request POST \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
            "content": "some content", "commit_message": "create a new file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

예제 응답:

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

## 리포지토리에서 파일 업데이트 {#update-a-file-in-a-repository}

{{< history >}}

- 요청 크기 및 속도 제한은 GitLab 18.7에서 도입되었습니다.

{{< /history >}}

리포지토리의 지정된 파일을 업데이트합니다. 단일 요청으로 여러 파일을 업데이트하려면 [커밋 API](commits.md#create-a-commit)을 참조하세요.

```plaintext
PUT /projects/:id/repository/files/:file_path
```

> [!note]
> 이 엔드포인트는 [요청 크기 및 속도 제한](../administration/instance_limits.md#commits-and-files-api-limits)에 따릅니다. 기본 300MB 제한보다 큰 요청은 거부됩니다. 20MB보다 큰 요청은 30초마다 3개 요청으로 속도 제한됩니다.

지원되는 속성:

| 특성        | 유형              | 필수 | 설명 |
| ---------------- | ----------------- | -------- | ----------- |
| `branch`         | 문자열            | 예      | 생성할 브랜치의 이름입니다. 커밋이 이 브랜치에 추가됩니다. |
| `commit_message` | 문자열            | 예      | 커밋 메시지. |
| `content`        | 문자열            | 예      | 파일의 내용입니다. |
| `file_path`      | 문자열            | 예      | URL 인코딩된 전체 파일 경로입니다. 예: `lib%2Fclass%2Erb`. |
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)  |
| `author_email`   | 문자열            | 아니요       | 커밋 작성자의 이메일 주소입니다. |
| `author_name`    | 문자열            | 아니요       | 커밋 작성자의 이름입니다. |
| `encoding`       | 문자열            | 아니요       | 인코딩을 `base64`로 변경합니다. 기본값은 `text`입니다. |
| `execute_filemode` | 부울         | 아니요       | `true`인 경우 파일의 `execute` 플래그를 활성화합니다. `false`인 경우 파일의 `execute` 플래그를 비활성화합니다. |
| `last_commit_id` | 문자열            | 아니요       | 마지막으로 알려진 파일 커밋 ID입니다. |
| `start_branch`   | 문자열            | 아니요       | 브랜치를 생성할 기본 브랜치의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성   | 유형   | 설명 |
|-------------|--------|-------------|
| `branch`    | 문자열 | 파일이 업데이트된 브랜치의 이름입니다. |
| `file_path` | 문자열 | 업데이트된 파일의 경로입니다. |

```shell
curl --request PUT \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "content": "some content", "commit_message": "update file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

예제 응답:

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

어떤 이유로든 커밋이 실패하면 API는 `400 Bad Request` 오류를 비특정 오류 메시지와 함께 반환합니다. 실패한 커밋의 가능한 원인:

- `file_path`에 `/../`(시도된 디렉터리 순회)가 포함되어 있습니다.
- 커밋이 비어 있었습니다: 새 파일 내용이 현재 파일 내용과 동일합니다.
- 파일 편집이 진행 중인 동안 누군가 `git push`을 사용하여 브랜치를 업데이트했습니다.

[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell/)은 Boolean 반환 코드를 가지고 있어 GitLab이 오류를 지정하지 못합니다.

## 리포지토리에서 파일 삭제 {#delete-a-file-in-a-repository}

리포지토리의 지정된 파일을 삭제합니다. 단일 요청으로 여러 파일을 삭제하려면 [커밋 API](commits.md#create-a-commit)을 참조하세요.

```plaintext
DELETE /projects/:id/repository/files/:file_path
```

지원되는 속성:

| 특성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `branch`         | 문자열            | 예      | 생성할 브랜치의 이름입니다. 커밋이 이 브랜치에 추가됩니다. |
| `commit_message` | 문자열            | 예      | 커밋 메시지. |
| `file_path`      | 문자열            | 예      | URL 인코딩된 전체 파일 경로입니다. 예: `lib%2Fclass%2Erb`. |
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `author_email`   | 문자열            | 아니요       | 커밋 작성자의 이메일 주소입니다. |
| `author_name`    | 문자열            | 아니요       | 커밋 작성자의 이름입니다. |
| `last_commit_id` | 문자열            | 아니요       | 마지막으로 알려진 파일 커밋 ID입니다. |
| `start_branch`   | 문자열            | 아니요       | 브랜치를 생성할 기본 브랜치의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환합니다.

```shell
curl --request DELETE \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "commit_message": "delete file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```
