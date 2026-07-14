---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 에이전트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 에이전트 토큰 API [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) (GitLab 15.0)

{{< /history >}}

이 API를 사용하여 [Kubernetes용 GitLab 에이전트](../user/clusters/agent/_index.md)와 상호 작용합니다.

## 모든 에이전트 나열 {#list-all-agents}

프로젝트에 등록된 모든 에이전트를 나열합니다.

이 엔드포인트를 사용하려면 개발자, 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /projects/:id/cluster_agents
```

매개변수:

| 속성 | 유형              | 필수  | 설명                                                                                                     |
|-----------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예       | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |

응답:

응답은 다음 필드를 포함하는 에이전트 목록입니다:

| 속성                            | 유형     | 설명                                          |
|--------------------------------------|----------|------------------------------------------------------|
| `id`                                 | 정수  | 에이전트의 ID                                      |
| `name`                               | 문자열   | 에이전트의 이름                                    |
| `config_project`                     | 객체   | 에이전트가 속한 프로젝트를 나타내는 객체 |
| `config_project.id`                  | 정수  | 프로젝트의 ID                                    |
| `config_project.description`         | 문자열   | 프로젝트의 설명                           |
| `config_project.name`                | 문자열   | 프로젝트의 이름                                  |
| `config_project.name_with_namespace` | 문자열   | 프로젝트의 네임스페이스를 포함한 전체 이름              |
| `config_project.path`                | 문자열   | 프로젝트의 경로                                  |
| `config_project.path_with_namespace` | 문자열   | 프로젝트의 네임스페이스를 포함한 전체 경로              |
| `config_project.created_at`          | 문자열   | 프로젝트가 생성된 ISO8601 날짜/시간        |
| `created_at`                         | 문자열   | 에이전트가 생성된 ISO8601 날짜/시간          |
| `created_by_user_id`                 | 정수  | 에이전트를 생성한 사용자의 ID                 |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  {
    "id": 2,
    "name": "agent-2",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  }
]
```

## 에이전트 검색 {#retrieve-an-agent}

단일 에이전트의 세부 정보를 검색합니다.

이 엔드포인트를 사용하려면 개발자, 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /projects/:id/cluster_agents/:agent_id
```

매개변수:

| 속성  | 유형              | 필수 | 설명                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id` | 정수           | 예      | 에이전트의 ID                                                                                                 |

응답:

응답은 다음 필드를 포함하는 단일 에이전트입니다:

| 속성                            | 유형    | 설명                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | 정수 | 에이전트의 ID                                      |
| `name`                               | 문자열  | 에이전트의 이름                                    |
| `config_project`                     | 객체  | 에이전트가 속한 프로젝트를 나타내는 객체 |
| `config_project.id`                  | 정수 | 프로젝트의 ID                                    |
| `config_project.description`         | 문자열  | 프로젝트의 설명                           |
| `config_project.name`                | 문자열  | 프로젝트의 이름                                  |
| `config_project.name_with_namespace` | 문자열  | 프로젝트의 네임스페이스를 포함한 전체 이름              |
| `config_project.path`                | 문자열  | 프로젝트의 경로                                  |
| `config_project.path_with_namespace` | 문자열  | 프로젝트의 네임스페이스를 포함한 전체 경로              |
| `config_project.created_at`          | 문자열  | 프로젝트가 생성된 ISO8601 날짜/시간        |
| `created_at`                         | 문자열  | 에이전트가 생성된 ISO8601 날짜/시간          |
| `created_by_user_id`                 | 정수 | 에이전트를 생성한 사용자의 ID                 |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## 에이전트 생성 {#create-an-agent}

프로젝트에 대한 새로운 에이전트를 생성합니다.

이 엔드포인트를 사용하려면 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
POST /projects/:id/cluster_agents
```

매개변수:

| 속성 | 유형              | 필수 | 설명                                                                                                     |
|-----------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `name`    | 문자열            | 예      | 에이전트의 이름                                                                                              |

응답:

응답은 다음 필드를 포함하는 새로운 에이전트입니다:

| 속성                            | 유형    | 설명                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | 정수 | 에이전트의 ID                                      |
| `name`                               | 문자열  | 에이전트의 이름                                    |
| `config_project`                     | 객체  | 에이전트가 속한 프로젝트를 나타내는 객체 |
| `config_project.id`                  | 정수 | 프로젝트의 ID                                    |
| `config_project.description`         | 문자열  | 프로젝트의 설명                           |
| `config_project.name`                | 문자열  | 프로젝트의 이름                                  |
| `config_project.name_with_namespace` | 문자열  | 프로젝트의 네임스페이스를 포함한 전체 이름              |
| `config_project.path`                | 문자열  | 프로젝트의 경로                                  |
| `config_project.path_with_namespace` | 문자열  | 프로젝트의 네임스페이스를 포함한 전체 경로              |
| `config_project.created_at`          | 문자열  | 프로젝트가 생성된 ISO8601 날짜/시간        |
| `created_at`                         | 문자열  | 에이전트가 생성된 ISO8601 날짜/시간          |
| `created_by_user_id`                 | 정수 | 에이전트를 생성한 사용자의 ID                 |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents" \
  --data '{"name":"some-agent"}'
```

응답 예시:

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## 에이전트 삭제 {#delete-an-agent}

기존 에이전트 등록을 삭제합니다.

이 엔드포인트를 사용하려면 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id
```

매개변수:

| 속성  | 유형              | 필수 | 설명                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id` | 정수           | 예      | 에이전트의 ID                                                                                                 |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

## 모든 에이전트 토큰 나열 {#list-all-agent-tokens}

{{< history >}}

- [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) (GitLab 15.0)

{{< /history >}}

에이전트에 대한 모든 활성 토큰을 나열합니다.

이 엔드포인트를 사용하려면 개발자, 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens
```

지원하는 속성:

| 속성  | 유형              | 필수  | 설명                                                                                                      |
|------------|-------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| `id`       | 정수 또는 문자열 | 예       | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id` | 정수 또는 문자열 | 예       | 에이전트의 ID입니다.                                                                                                 |

응답:

응답은 다음 필드를 포함하는 토큰 목록입니다:

| 속성            | 유형           | 설명                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 정수        | 토큰의 ID입니다.                                                  |
| `name`               | 문자열         | 토큰의 이름입니다.                                                |
| `description`        | 문자열 또는 null | 토큰의 설명입니다.                                         |
| `agent_id`           | 정수        | 토큰이 속한 에이전트의 ID입니다.                             |
| `status`             | 문자열         | 토큰의 상태입니다. 유효한 값은 `active` 및 `revoked`입니다. |
| `created_at`         | 문자열         | 토큰이 생성된 ISO8601 날짜/시간입니다.                      |
| `created_by_user_id` | 문자열         | 토큰을 생성한 사용자의 사용자 ID입니다.                        |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "abcd",
    "description": "Some token",
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  },
  {
    "id": 2,
    "name": "foobar",
    "description": null,
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  }
]
```

> [!note]
> `last_used_at` 필드는 단일 에이전트 토큰을 얻을 때만 반환됩니다.

## 에이전트 토큰 검색 {#retrieve-an-agent-token}

{{< history >}}

- [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) (GitLab 15.0)

{{< /history >}}

단일 에이전트 토큰을 검색합니다.

이 엔드포인트를 사용하려면 개발자, 유지관리자 또는 소유자 역할이 있어야 합니다.

에이전트 토큰이 취소된 경우 `404`을 반환합니다.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

지원하는 속성:

| 속성  | 유형              | 필수 | 설명                                                                                                       |
|------------|-------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함)  |
| `agent_id` | 정수           | 예      | 에이전트의 ID입니다.                                                                                                  |
| `token_id` | 정수           | 예      | 토큰의 ID입니다.                                                                                                  |

응답:

응답은 다음 필드를 포함하는 단일 토큰입니다:

| 속성            | 유형           | 설명                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 정수        | 토큰의 ID입니다.                                                  |
| `name`               | 문자열         | 토큰의 이름입니다.                                                |
| `description`        | 문자열 또는 null | 토큰의 설명입니다.                                         |
| `agent_id`           | 정수        | 토큰이 속한 에이전트의 ID입니다.                             |
| `status`             | 문자열         | 토큰의 상태입니다. 유효한 값은 `active` 및 `revoked`입니다. |
| `created_at`         | 문자열         | 토큰이 생성된 ISO8601 날짜/시간입니다.                      |
| `created_by_user_id` | 문자열         | 토큰을 생성한 사용자의 사용자 ID입니다.                        |
| `last_used_at`       | 문자열 또는 null | 토큰이 마지막으로 사용된 ISO8601 날짜/시간입니다.                    |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/token/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null
}
```

## 에이전트 토큰 생성 {#create-an-agent-token}

{{< history >}}

- [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) (GitLab 15.0)
- 2토큰 제한이 [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/361030/) (GitLab 16.1) [플래그](../administration/feature_flags/_index.md) `cluster_agents_limit_tokens_created` 이름으로.
- 2토큰 제한이 [일반적으로 이용 가능함](https://gitlab.com/gitlab-org/gitlab/-/issues/412399) (GitLab 16.2) 기능 플래그 `cluster_agents_limit_tokens_created` 제거됨.

{{< /history >}}

에이전트에 대한 새로운 토큰을 생성합니다.

이 엔드포인트를 사용하려면 유지관리자 또는 소유자 역할이 있어야 합니다.

에이전트는 한 번에 2개의 활성 토큰만 가질 수 있습니다.

```plaintext
POST /projects/:id/cluster_agents/:agent_id/tokens
```

지원하는 속성:

| 속성     | 유형              | 필수 | 설명                                                                                                      |
|---------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id`    | 정수           | 예      | 에이전트의 ID입니다.                                                                                                 |
| `name`        | 문자열            | 예      | 토큰의 이름입니다.                                                                                              |
| `description` | 문자열            | 아니오       | 토큰의 설명입니다.                                                                                       |

응답:

응답은 다음 필드를 포함하는 새로운 토큰입니다:

| 속성            | 유형           | 설명                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 정수        | 토큰의 ID입니다.                                                  |
| `name`               | 문자열         | 토큰의 이름입니다.                                                |
| `description`        | 문자열 또는 null | 토큰의 설명입니다.                                         |
| `agent_id`           | 정수        | 토큰이 속한 에이전트의 ID입니다.                             |
| `status`             | 문자열         | 토큰의 상태입니다. 유효한 값은 `active` 및 `revoked`입니다. |
| `created_at`         | 문자열         | 토큰이 생성된 ISO8601 날짜/시간입니다.                      |
| `created_by_user_id` | 문자열         | 토큰을 생성한 사용자의 사용자 ID입니다.                        |
| `last_used_at`       | 문자열 또는 null | 토큰이 마지막으로 사용된 ISO8601 날짜/시간입니다.                    |
| `token`              | 문자열         | 비밀 토큰 값입니다.                                           |

> [!note]
> `token`은 `POST` 엔드포인트의 응답에서만 반환되며 나중에 검색할 수 없습니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens" \
  --data '{"name":"some-token"}'
```

응답 예시:

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null,
  "token": "qeY8UVRisx9y3Loxo1scLxFuRxYcgeX3sxsdrpP_fR3Loq4xyg"
}
```

## 에이전트 토큰 취소 {#revoke-an-agent-token}

{{< history >}}

- [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) (GitLab 15.0)

{{< /history >}}

에이전트 토큰을 취소합니다.

이 엔드포인트를 사용하려면 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

지원하는 속성:

| 속성 | 유형 | 필수 | 설명 | |------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------- -| | `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) | | `agent_id` | 정수 | 예 | 에이전트의 ID입니다. | | `token_id` | 정수 | 예 | 토큰의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens/1"
```

## 반응형 에이전트 {#receptive-agents}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [소개됨](https://gitlab.com/groups/gitlab-org/-/epics/12180) (GitLab 17.4)

{{< /history >}}

[반응형 에이전트](../user/clusters/agent/_index.md#receptive-agents)를 사용하면 GitLab이 GitLab 인스턴스에 네트워크 연결을 설정할 수 없지만 GitLab에 의해 연결될 수 있는 Kubernetes 클러스터와 통합할 수 있습니다.

### 모든 URL 구성 나열 {#list-all-url-configurations}

지정된 에이전트의 모든 URL 구성을 나열합니다.

이 엔드포인트를 사용하려면 개발자, 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations
```

지원하는 속성:

| 속성  | 유형              | 필수  | 설명                                                                                                           |
|------------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`       | 정수 또는 문자열 | 예       | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id` | 정수 또는 문자열 | 예       | 에이전트의 ID입니다.                                                                                                      |

응답:

응답은 다음 필드를 포함하는 URL 구성 목록입니다:

| 속성            | 유형           | 설명                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 정수        | URL 구성의 ID입니다.                                                |
| `agent_id`           | 정수        | URL 구성이 속한 에이전트의 ID입니다.                           |
| `url`                | 문자열         | 이 URL 구성의 URL입니다.                                             |
| `public_key`         | 문자열         | (선택사항) JWT 인증을 사용하는 경우 Base64 인코딩된 공개 키입니다.         |
| `client_cert`        | 문자열         | (선택사항) mTLS 인증을 사용하는 경우 PEM 형식의 클라이언트 인증서입니다. |
| `ca_cert`            | 문자열         | (선택사항) 에이전트 엔드포인트를 확인하기 위한 PEM 형식의 CA 인증서입니다.       |
| `tls_host`           | 문자열         | (선택사항) 에이전트 엔드포인트에서 서버 이름을 확인하기 위한 TLS 호스트 이름입니다.       |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations"
```

응답 예시:

```json
[
  {
    "id": 1,
    "agent_id": 5,
    "url": "grpcs://agent.example.com:4242",
    "public_key": "..."
  }
]
```

> [!note]
> `public_key` 또는 `client_cert`이 설정되어 있지만 둘 다 설정될 수는 없습니다.

### URL 구성 검색 {#retrieve-a-url-configuration}

단일 에이전트 URL 구성을 검색합니다.

이 엔드포인트를 사용하려면 개발자, 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

지원하는 속성:

| 속성              | 유형              | 필수 | 설명                                                                                                            |
|------------------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------------|
| `id`                   | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함)  |
| `agent_id`             | 정수           | 예      | 에이전트의 ID입니다.                                                                                                       |
| `url_configuration_id` | 정수           | 예      | URL 구성의 ID입니다.                                                                                           |

응답:

응답은 다음 필드를 포함하는 단일 URL 구성입니다:

| 속성            | 유형           | 설명                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 정수        | URL 구성의 ID입니다.                                                |
| `agent_id`           | 정수        | URL 구성이 속한 에이전트의 ID입니다.                           |
| `url`                | 문자열         | 이 URL 구성의 에이전트 URL입니다.                                             |
| `public_key`         | 문자열         | (선택사항) JWT 인증을 사용하는 경우 Base64 인코딩된 공개 키입니다.         |
| `client_cert`        | 문자열         | (선택사항) mTLS 인증을 사용하는 경우 PEM 형식의 클라이언트 인증서입니다. |
| `ca_cert`            | 문자열         | (선택사항) 에이전트 엔드포인트를 확인하기 위한 PEM 형식의 CA 인증서입니다.       |
| `tls_host`           | 문자열         | (선택사항) 에이전트 엔드포인트에서 서버 이름을 확인하기 위한 TLS 호스트 이름입니다.       |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1"
```

응답 예시:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

> [!note]
> `public_key` 또는 `client_cert`이 설정되어 있지만 둘 다 설정될 수는 없습니다.

### URL 구성 생성 {#create-a-url-configuration}

에이전트에 대한 새로운 URL 구성을 생성합니다.

이 엔드포인트를 사용하려면 유지관리자 또는 소유자 역할이 있어야 합니다.

에이전트는 한 번에 1개의 URL 구성만 가질 수 있습니다.

```plaintext
POST /projects/:id/cluster_agents/:agent_id/url_configurations
```

지원하는 속성:

| 속성     | 유형              | 필수 | 설명                                                                                                           |
|---------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id`    | 정수           | 예      | 에이전트의 ID입니다.                                                                                                      |
| `url`         | 문자열            | 예      | 이 URL 구성의 에이전트 URL입니다.                                                                                 |
| `client_cert` | 문자열            | 아니오       | mTLS 인증을 사용해야 하는 경우 PEM 형식의 클라이언트 인증서입니다. `client_key`과 함께 제공되어야 합니다.           |
| `client_key`  | 문자열            | 아니오       | mTLS 인증을 사용해야 하는 경우 PEM 형식의 클라이언트 키입니다. `client_cert`과 함께 제공되어야 합니다.                  |
| `ca_cert`     | 문자열            | 아니오       | 에이전트 엔드포인트를 확인하기 위한 PEM 형식의 CA 인증서입니다.                                                            |
| `tls_host`    | 문자열            | 아니오       | 에이전트 엔드포인트에서 서버 이름을 확인하기 위한 TLS 호스트 이름입니다.                                                            |

응답:

응답은 다음 필드를 포함하는 새로운 URL 구성입니다:

| 속성            | 유형           | 설명                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 정수        | URL 구성의 ID입니다.                                                |
| `agent_id`           | 정수        | URL 구성이 속한 에이전트의 ID입니다.                           |
| `url`                | 문자열         | 이 URL 구성의 에이전트 URL입니다.                                             |
| `public_key`         | 문자열         | (선택사항) JWT 인증을 사용하는 경우 Base64 인코딩된 공개 키입니다.         |
| `client_cert`        | 문자열         | (선택사항) mTLS 인증을 사용하는 경우 PEM 형식의 클라이언트 인증서입니다. |
| `ca_cert`            | 문자열         | (선택사항) 에이전트 엔드포인트를 확인하기 위한 PEM 형식의 CA 인증서입니다.       |
| `tls_host`           | 문자열         | (선택사항) 에이전트 엔드포인트에서 서버 이름을 확인하기 위한 TLS 호스트 이름입니다.       |

JWT 토큰으로 URL 구성을 생성하는 요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242"}'
```

JWT 인증에 대한 응답 예시:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

`client.pem` 및 `client-key.pem` 파일에서 클라이언트 인증서 및 키를 사용하여 mTLS로 URL 구성을 생성하는 요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242", \
           "client_cert":"'"$(awk -v ORS='\\n' '1' client.pem)"'", \
           "client_key":"'"$(awk -v ORS='\\n' '1' client-key.pem)"'"}'
```

mTLS에 대한 응답 예시:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "client_cert": "..."
}
```

> [!note]
> `client_cert` 및 `client_key`이 제공되지 않으면 개인-공개 키 쌍이 생성되고 mTLS 대신 JWT 인증이 사용됩니다.

### URL 구성 삭제 {#delete-a-url-configuration}

에이전트 URL 구성을 삭제합니다.

이 엔드포인트를 사용하려면 유지관리자 또는 소유자 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

지원하는 속성:

| 속성              | 유형              | 필수 | 설명                                                                                                           |
|------------------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`                   | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) (인증된 사용자가 유지 관리함) |
| `agent_id`             | 정수           | 예      | 에이전트의 ID입니다.                                                                                                      |
| `url_configuration_id` | 정수           | 예      | URL 구성의 ID입니다.                                                                                          |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1
```
