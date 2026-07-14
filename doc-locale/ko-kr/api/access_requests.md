---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 및 프로젝트 액세스 요청 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 그룹 및 프로젝트에 대한 액세스 요청과 상호 작용합니다.

## 그룹 또는 프로젝트에 대한 모든 액세스 요청 나열 {#list-all-access-requests-for-a-group-or-project}

인증된 사용자가 볼 수 있는 지정된 그룹 또는 프로젝트에 대한 모든 액세스 요청을 나열합니다.

```plaintext
GET /groups/:id/access_requests
GET /projects/:id/access_requests
```

| 특성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

예제 응답:

```json
[
 {
   "id": 1,
   "username": "raymond_smith",
   "name": "Raymond Smith",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/1/avatar.png",
   "web_url": "https://gitlab.com/raymond_smith",
   "requested_at": "2024-10-22T14:13:35Z"
 },
 {
   "id": 2,
   "username": "john_doe",
   "name": "John Doe",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/2/avatar.png",
   "web_url": "https://gitlab.com/john_doe",
   "requested_at": "2024-10-22T14:13:35Z"
 }
]
```

## 그룹 또는 프로젝트에 대한 액세스 요청 {#request-access-to-a-group-or-project}

인증된 사용자가 지정된 그룹 또는 프로젝트에 대한 액세스를 요청합니다.

```plaintext
POST /groups/:id/access_requests
POST /projects/:id/access_requests
```

| 특성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [그룹 또는 프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths) |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

예제 응답:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "requested_at": "2012-10-22T14:13:35Z"
}
```

## 액세스 요청 승인 {#approve-an-access-request}

지정된 그룹 또는 프로젝트에서 지정된 사용자의 액세스 요청을 승인합니다.

```plaintext
PUT /groups/:id/access_requests/:user_id/approve
PUT /projects/:id/access_requests/:user_id/approve
```

| 특성      | 유형           | 필수 | 설명 |
|----------------|----------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `user_id`      | 정수        | 예      | 액세스를 요청한 사용자의 사용자 ID |
| `access_level` | 정수        | 아니오       | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자), `50` (소유자). 기본값: `30`. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id/approve?access_level=20"
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id/approve?access_level=20"
```

예제 응답:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "access_level": 20
}
```

## 액세스 요청 거부 {#deny-an-access-request}

지정된 그룹 또는 프로젝트에서 지정된 사용자의 액세스 요청을 거부합니다.

```plaintext
DELETE /groups/:id/access_requests/:user_id
DELETE /projects/:id/access_requests/:user_id
```

| 특성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `user_id` | 정수        | 예      | 액세스를 요청한 사용자의 사용자 ID |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id"
```
