---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이모지 반응 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/409884)됨: GitLab 16.0에서 "어워드 이모지"에서 "이모지 반응"으로 변경되었습니다.

{{< /history >}}

이 API를 사용하여 [이모지 반응](../user/emoji_reactions.md)을 관리합니다.

이모지 반응을 허용하는 GitLab 객체를 어워더블이라고 합니다. 다음 리소스에서 이모지로 반응할 수 있습니다:

- [에픽](../user/group/epics/_index.md) ([API](epics.md)).
- [이슈](../user/project/issues/_index.md) ([API](issues.md)).
- [머지 리퀘스트](../user/project/merge_requests/_index.md) ([API](merge_requests.md)).
- [스니펫](../user/snippets.md) ([API](snippets.md)).
- [댓글](../user/emoji_reactions.md#emoji-reactions-for-comments) ([API](notes.md)).

## 이슈, 머지 리퀘스트 및 스니펫 {#issues-merge-requests-and-snippets}

댓글과 함께 이 엔드포인트를 사용하는 방법에 대한 정보는 [댓글에 반응 추가](#add-reactions-to-comments)를 참조하세요.

### 리소스에 대한 모든 이모지 반응 나열 {#list-all-emoji-reactions-for-a-resource}

{{< history >}}

- GitLab 15.1에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)됨 - 공개 어워더블에 대한 인증 없는 액세스를 허용합니다.

{{< /history >}}

지정된 이슈, 스니펫 또는 머지 리퀘스트에 대한 모든 이모지 반응을 나열합니다. 어워더블이 공개적으로 액세스 가능한 경우 이 엔드포인트는 인증 없이 액세스할 수 있습니다.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji
GET /projects/:id/snippets/:snippet_id/award_emoji
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 정수        | 예      | 어워더블의 ID (`iid` 머지 리퀘스트/이슈용, `id` 스니펫용).     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji"
```

응답 예시:

```json
[
  {
    "id": 4,
    "name": "1234",
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2016-06-15T10:09:34.206Z",
    "updated_at": "2016-06-15T10:09:34.206Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  },
  {
    "id": 1,
    "name": "microphone",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.177Z",
    "updated_at": "2016-06-15T10:09:34.177Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  }
]
```

### 리소스에서 이모지 반응 검색 {#retrieve-an-emoji-reaction-from-a-resource}

{{< history >}}

- GitLab 15.1에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)됨 - 공개 어워더블에 대한 인증 없는 액세스를 허용합니다.

{{< /history >}}

이슈, 스니펫 또는 머지 리퀘스트에서 지정된 이모지 반응을 검색합니다. 어워더블이 공개적으로 액세스 가능한 경우 이 엔드포인트는 인증 없이 액세스할 수 있습니다.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
GET /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 정수        | 예      | 어워더블의 ID (`iid` 머지 리퀘스트/이슈용, `id` 스니펫용).     |
| `award_id`     | 정수        | 예      | 이모지 반응의 ID.                                                       |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "microphone",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.177Z",
  "updated_at": "2016-06-15T10:09:34.177Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### 리소스에 이모지 반응 추가 {#add-an-emoji-reaction-to-a-resource}

이슈, 스니펫 또는 머지 리퀘스트에 이모지 반응을 추가합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/award_emoji
POST /projects/:id/merge_requests/:merge_request_iid/award_emoji
POST /projects/:id/snippets/:snippet_id/award_emoji
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 정수        | 예      | 어워더블의 ID (`iid` 머지 리퀘스트/이슈용, `id` 스니펫용).     |
| `name`         | 문자열         | 예      | 콜론 없는 이모지의 이름.                                            |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji?name=blowfish"
```

응답 예시:

```json
{
  "id": 344,
  "name": "blowfish",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T17:47:29.266Z",
  "updated_at": "2016-06-17T17:47:29.266Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### 리소스에서 이모지 반응 삭제 {#delete-an-emoji-reaction-from-a-resource}

이슈, 스니펫 또는 머지 리퀘스트에서 지정된 이모지 반응을 삭제합니다.

관리자 또는 반응 작성자만 이모지 반응을 삭제할 수 있습니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid/award_emoji/:award_id
DELETE /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
DELETE /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

매개 변수:

| 속성      | 유형           | 필수 | 설명                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 정수        | 예      | 어워더블의 ID (`iid` 머지 리퀘스트/이슈용, `id` 스니펫용).     |
| `award_id`     | 정수        | 예      | 이모지 반응의 ID.                                                        |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/344"
```

## 댓글에 반응 추가 {#add-reactions-to-comments}

댓글(노트라고도 함)은 이슈, 머지 리퀘스트 및 스니펫의 하위 리소스입니다.

> [!note]
> 아래 예시에서는 이슈의 댓글에 대한 이모지 반응 작업을 설명하지만 머지 리퀘스트 및 스니펫의 댓글에 맞게 조정할 수 있습니다. 따라서 `issue_iid`를 `merge_request_iid` 또는 `snippet_id`로 바꿔야 합니다.

### 댓글에 대한 모든 이모지 반응 나열 {#list-all-emoji-reactions-for-a-comment}

{{< history >}}

- GitLab 15.1에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)됨 - 공개 댓글에 대한 인증 없는 액세스를 허용합니다.

{{< /history >}}

지정된 댓글에 대한 모든 이모지 반응을 나열합니다. 댓글이 공개적으로 액세스 가능한 경우 이 엔드포인트는 인증 없이 액세스할 수 있습니다.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

매개 변수:

| 속성   | 유형           | 필수 | 설명                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid` | 정수        | 예      | 이슈의 내부 ID.                                                     |
| `note_id`   | 정수        | 예      | 댓글(노트)의 ID.                                                      |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji"
```

응답 예시:

```json
[
  {
    "id": 2,
    "name": "mood_bubble_lightning",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.197Z",
    "updated_at": "2016-06-15T10:09:34.197Z",
    "awardable_id": 1,
    "awardable_type": "Note"
  }
]
```

### 댓글에서 이모지 반응 검색 {#retrieve-an-emoji-reaction-from-a-comment}

{{< history >}}

- GitLab 15.1에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)됨 - 공개 댓글에 대한 인증 없는 액세스를 허용합니다.

{{< /history >}}

지정된 댓글에서 이모지 반응을 검색합니다. 댓글이 공개적으로 액세스 가능한 경우 이 엔드포인트는 인증 없이 액세스할 수 있습니다.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

매개 변수:

| 속성   | 유형           | 필수 | 설명                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid` | 정수        | 예      | 이슈의 내부 ID.                                                     |
| `note_id`   | 정수        | 예      | 댓글(노트)의 ID.                                                      |
| `award_id`  | 정수        | 예      | 이모지 반응의 ID.                                                       |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji/2"
```

응답 예시:

```json
{
  "id": 2,
  "name": "mood_bubble_lightning",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.197Z",
  "updated_at": "2016-06-15T10:09:34.197Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### 댓글에 이모지 반응 추가 {#add-an-emoji-reaction-to-a-comment}

지정된 댓글에 이모지 반응을 추가합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

매개 변수:

| 속성   | 유형           | 필수 | 설명                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid` | 정수        | 예      | 이슈의 내부 ID.                                                     |
| `note_id`   | 정수        | 예      | 댓글(노트)의 ID.                                                      |
| `name`      | 문자열         | 예      | 콜론 없는 이모지의 이름.                                            |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji?name=rocket"
```

응답 예시:

```json
{
  "id": 345,
  "name": "rocket",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T19:59:55.888Z",
  "updated_at": "2016-06-17T19:59:55.888Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### 댓글에서 이모지 반응 삭제 {#delete-an-emoji-reaction-from-a-comment}

지정된 댓글에서 이모지 반응을 삭제합니다.

관리자 또는 반응 작성자만 이모지 반응을 삭제할 수 있습니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

매개 변수:

| 속성   | 유형           | 필수 | 설명                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `issue_iid` | 정수        | 예      | 이슈의 내부 ID.                                                     |
| `note_id`   | 정수        | 예      | 댓글(노트)의 ID.                                                      |
| `award_id`  | 정수        | 예      | 이모지 반응의 ID.                                                        |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/345"
```
