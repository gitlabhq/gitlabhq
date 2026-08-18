---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 Markdown 업로드 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 에픽 또는 위키 페이지의 Markdown 텍스트에서 참조할 수 있는 [Markdown 업로드](../security/user_file_uploads.md)를 관리합니다.

## 그룹에 파일 업로드 {#upload-a-file-to-a-group}

{{< history >}}

- GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230537).

{{< /history >}}

지정된 그룹에 파일을 업로드합니다. Markdown 형식의 파일 링크를 반환합니다.

이 엔드포인트를 사용하려면 게스트, 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

```plaintext
POST /groups/:id/uploads
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `file`    | 파일              | 예      | 업로드할 파일입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@/path/to/image.png" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads"
```

응답 예시:

```json
{
  "id": 3,
  "alt": "image",
  "url": "/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png",
  "full_path": "/-/group/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png",
  "markdown": "![image](/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png)"
}
```

## 그룹의 모든 업로드 나열 {#list-all-uploads-for-a-group}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)되었습니다.

{{< /history >}}

지정된 그룹의 모든 업로드를 `created_at`를 기준으로 내림차순으로 정렬하여 나열합니다.

이 엔드포인트를 사용하려면 유지보수자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /groups/:id/uploads
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads"
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

지정된 ID의 업로드된 파일을 다운로드합니다. 이 엔드포인트를 사용하려면 유지보수자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /groups/:id/uploads/:upload_id
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `upload_id` | 정수           | 예      | 업로드의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문에 업로드된 파일을 반환합니다.

## 비밀과 파일명으로 업로드된 파일 다운로드 {#download-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)되었습니다.

{{< /history >}}

지정된 비밀번호 및 파일명의 업로드된 파일을 다운로드합니다. 이 엔드포인트를 사용하려면 게스트, 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /groups/:id/uploads/:secret/:filename
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `secret`    | 문자열            | 예      | 업로드의 32자 비밀번호입니다. |
| `filename`  | 문자열            | 예      | 업로드의 파일명입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문에 업로드된 파일을 반환합니다.

## ID별로 업로드된 파일 삭제 {#delete-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)되었습니다.

{{< /history >}}

지정된 ID의 업로드된 파일을 삭제합니다. 이 엔드포인트를 사용하려면 유지보수자 또는 소유자 역할이 있어야 합니다.

```plaintext
DELETE /groups/:id/uploads/:upload_id
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `upload_id` | 정수           | 예      | 업로드의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

성공하면 응답 본문 없이 [`204`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

## 비밀과 파일명으로 업로드된 파일 삭제 {#delete-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)되었습니다.

{{< /history >}}

지정된 비밀번호 및 파일명의 업로드된 파일을 삭제합니다. 이 엔드포인트를 사용하려면 유지보수자 또는 소유자 역할이 있어야 합니다.

```plaintext
DELETE /groups/:id/uploads/:secret/:filename
```

지원되는 속성:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `secret`    | 문자열            | 예      | 업로드의 32자 비밀번호입니다. |
| `filename`  | 문자열            | 예      | 업로드의 파일명입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

성공하면 응답 본문 없이 [`204`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.
