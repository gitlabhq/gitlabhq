---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 마크다운 업로드 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [마크다운 업로드](../security/user_file_uploads.md)를 관리하면 이슈, 머지 리퀘스트, 스니펫 또는 위키 페이지의 마크다운 텍스트에서 참조할 수 있습니다.

## 업로드 생성 {#create-an-upload}

{{< history >}}

- [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112450)한 GitLab 15.10입니다. 기능 플래그 `enforce_max_attachment_size_upload_api` 제거됨.
- `full_path` 응답 속성 패턴이 GitLab 17.1에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150939)되었습니다.
- `id` 속성이 GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161160)되었습니다.

{{< /history >}}

이슈 또는 머지 리퀘스트 설명 또는 댓글에서 사용할 프로젝트에 파일을 업로드합니다.

```plaintext
POST /projects/:id/uploads
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `file`    | 문자열            | 예      | 업로드할 파일입니다. |
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

파일 시스템에서 파일을 업로드하려면 `--form` 인수를 사용하세요. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`가 앞에 와야 합니다.

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

응답 예시:

```json
{
  "id": 5,
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/-/project/1234/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

응답에서:

- `full_path`은 파일의 절대 경로입니다.
- `url`을 마크다운 컨텍스트에서 사용할 수 있습니다. `markdown`의 형식을 사용하면 링크가 확장됩니다.

## 업로드 나열 {#list-uploads}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)되었습니다.

{{< /history >}}

`created_at`에서 내림차순으로 정렬된 프로젝트의 모든 업로드를 나열합니다.

전제 조건:

- 유지 관리자 또는 소유자 역할입니다.

```plaintext
GET /projects/:id/uploads
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|:----------|:------------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

응답 예시:

```json
[
  {
    "id": 1,
    "size": 1024,
    "filename": "image.png",
    "created_at":"2024-06-20T15:53:03.067Z",
    "uploaded_by": {
      "id": 18,
      "name" : "Alexandra Bashirian",
      "username" : "eileen.lowe"
    }
  },
  {
    "id": 2,
    "size": 512,
    "filename": "other-image.png",
    "created_at":"2024-06-19T15:53:03.067Z",
    "uploaded_by": null
  }
]
```

## ID별로 업로드된 파일 다운로드 {#download-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)되었습니다.

{{< /history >}}

ID별로 업로드된 파일을 다운로드합니다.

전제 조건:

- 유지 관리자 또는 소유자 역할입니다.

```plaintext
GET /projects/:id/uploads/:upload_id
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|:------------|:------------------|:---------|:------------|
| `id`        | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `upload_id` | 정수           | 예      | 업로드의 ID입니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문에 업로드된 파일을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## 비밀과 파일명으로 업로드된 파일 다운로드 {#download-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)되었습니다.

{{< /history >}}

비밀과 파일명으로 업로드된 파일을 다운로드합니다.

전제 조건:

- 플래너, 보고자, 개발자, 유지 관리자 또는 소유자 역할입니다.

```plaintext
GET /projects/:id/uploads/:secret/:filename
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|:-----------|:------------------|:---------|:------------|
| `id`       | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `secret`   | 문자열            | 예      | 업로드의 32자 비밀입니다. |
| `filename` | 문자열            | 예      | 업로드의 파일명입니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문에 업로드된 파일을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

## ID별로 업로드된 파일 삭제 {#delete-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)되었습니다.

{{< /history >}}

ID별로 업로드된 파일을 삭제합니다.

전제 조건:

- 유지 관리자 또는 소유자 역할입니다.

```plaintext
DELETE /projects/:id/uploads/:upload_id
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|:------------|:------------------|:---------|:------------|
| `id`        | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `upload_id` | 정수           | 예      | 업로드의 ID입니다. |

성공하면 응답 본문 없이 [`204`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## 비밀과 파일명으로 업로드된 파일 삭제 {#delete-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)되었습니다.

{{< /history >}}

비밀과 파일명으로 업로드된 파일을 삭제합니다.

전제 조건:

- 유지 관리자 또는 소유자 역할입니다.

```plaintext
DELETE /projects/:id/uploads/:secret/:filename
```

지원되는 속성:

| 속성  | 유형              | 필수 | 설명 |
|:-----------|:------------------|:---------|:------------|
| `id`       | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `secret`   | 문자열            | 예      | 업로드의 32자 비밀입니다. |
| `filename` | 문자열            | 예      | 업로드의 파일명입니다. |

성공하면 응답 본문 없이 [`204`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```
