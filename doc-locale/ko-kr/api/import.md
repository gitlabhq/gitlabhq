---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Import API
description: "GitHub 또는 Bitbucket Server에서 REST API를 사용하여 리포지토리를 가져옵니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 개인 네임스페이스로 가져올 때 기여도를 개인 네임스페이스 소유자에게 재할당하는 기능이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) 되었으며 [플래그](../administration/feature_flags/_index.md) `user_mapping_to_personal_namespace_owner`를 사용하여 적용됩니다. 기본적으로 비활성화됨.
- 개인 네임스페이스로 가져올 때 기여도를 개인 네임스페이스 소유자에게 재할당하는 기능이 GitLab 18.6에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626)합니다. 기능 플래그 `user_mapping_to_personal_namespace_owner` 제거됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

이 API를 사용하여 [외부 소스에서 리포지토리를 가져옵니다](../user/import/_index.md).

> [!note]
> [네임스페이스](../user/namespace/_index.md#types-of-namespaces)로 프로젝트를 가져올 때는 사용자 기여도 매핑이 지원되지 않습니다. 개인 네임스페이스로 가져오면 모든 기여도가 개인 네임스페이스 소유자에게 할당되며 재할당할 수 없습니다.

## GitHub에서 리포지토리 가져오기 {#import-repository-from-github}

{{< history >}}

- GitLab 16.0에서 개발자 역할 대신 유지보수자 역할 요구사항이 도입되었으며 GitLab 15.11.1 및 GitLab 15.10.5로 백포트되었습니다.
- `collaborators_import` 키가 `optional_stages`에 GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)되었습니다.
- 기능 플래그 `github_import_extended_events`이 GitLab 16.8에서 도입되었습니다. 기본적으로 비활성화됨. 이 플래그는 가져오기 성능을 개선하지만 `single_endpoint_issue_events_import` 선택적 스테이지를 비활성화합니다.
- 기능 플래그 `github_import_extended_events`이 GitLab 16.9에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)되었습니다.
- 향상된 가져오기 성능이 GitLab 16.11에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)합니다. 기능 플래그 `github_import_extended_events` 제거됨.

{{< /history >}}

GitHub에서 GitLab으로 리포지토리를 가져옵니다.

전제 조건:

- [GitHub 가져오기 사전 요구사항](../user/project/import/github.md#prerequisites).
- `target_namespace`에 설정된 네임스페이스는 반드시 존재해야 합니다.
- 네임스페이스는 사용자 네임스페이스이거나 유지보수자 또는 소유자 역할을 가진 기존 그룹일 수 있습니다.

```plaintext
POST /import/github
```

| 속성               | 유형    | 필수 | 설명 |
|-------------------------|---------|----------|-------------|
| `personal_access_token` | 문자열  | 예      | GitHub 개인 액세스 토큰입니다. |
| `repo_id`               | 정수 | 예      | GitHub 리포지토리 ID입니다. |
| `target_namespace`      | 문자열  | 예      | 리포지토리를 가져올 네임스페이스입니다. `/namespace/subgroup`와 같은 하위 그룹을 지원합니다. 비워 둘 수 없습니다. |
| `github_hostname`       | 문자열  | 아니요       | 사용자 정의 GitHub Enterprise 호스트 이름입니다. GitHub.com에서는 설정하지 마세요. GitLab 16.5에서 GitLab 17.1까지는 경로 `/api/v3`을 포함해야 합니다. |
| `new_name`              | 문자열  | 아니요       | 새 프로젝트의 이름입니다. 새 경로로도 사용되므로 특수 문자로 시작하거나 끝나면 안 되며 연속된 특수 문자를 포함하면 안 됩니다. |
| `optional_stages`       | 객체  | 아니요       | [가져올 추가 항목](../user/project/import/github.md#select-additional-items-to-import)입니다. |
| `pagination_limit`      | 정수 | 아니요       | GitHub에 대한 API 요청당 검색되는 항목 수입니다. 기본값은 페이지당 100개 항목입니다. 대용량 리포지토리에서 프로젝트를 가져올 때 더 낮은 숫자는 GitHub API 엔드포인트가 `500` 또는 `502` 오류를 반환할 위험을 줄일 수 있습니다. 그러나 더 작은 페이지 크기는 마이그레이션 시간을 증가시킵니다. |
| `timeout_strategy`      | 문자열  | 아니요       | 가져오기 타임아웃을 처리하기 위한 전략입니다. 유효한 값은 `optimistic` (가져오기의 다음 스테이지로 계속) 또는 `pessimistic` (즉시 실패)입니다. `pessimistic`로 기본값이 설정됩니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/422979). |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github" \
  --header "content-type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{
    "personal_access_token": "aBc123abC12aBc123abC12abC123+_A/c123",
    "repo_id": "12345",
    "target_namespace": "group/subgroup",
    "new_name": "NEW-NAME",
    "github_hostname": "https://github.example.com",
    "optional_stages": {
      "single_endpoint_notes_import": true,
      "attachments_import": true,
      "collaborators_import": true
    }
}'
```

`optional_stages`에 사용할 수 있는 키는 다음과 같습니다:

- `attachments_import` (Markdown 첨부 파일 가져오기용).
- `collaborators_import` (외부 협력자가 아닌 직접 리포지토리 협력자를 가져오기용).
- `single_endpoint_issue_events_import` (이슈 및 끌어오기 요청 이벤트 가져오기용). 이 선택적 스테이지는 GitLab 16.9에서 제거되었습니다.
- `single_endpoint_notes_import` (대체 및 더 철저한 의견 가져오기용).

자세한 내용은 [가져올 추가 항목 선택](../user/project/import/github.md#select-additional-items-to-import)을 참조하세요.

응답 예시:

```json
{
    "id": 27,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "refs_url": "/root/my-repo/refs",
    "import_source": "my-github/repo",
    "import_status": "scheduled",
    "human_import_status_name": "scheduled",
    "provider_link": "/my-github/repo",
    "relation_type": null,
    "import_warning": null
}
```

### 그룹 액세스 토큰을 사용하여 API를 통해 공개 프로젝트 가져오기 {#import-a-public-project-through-the-api-using-a-group-access-token}

그룹 액세스 토큰을 사용하여 GitHub에서 GitLab으로 프로젝트를 API를 통해 가져올 때:

- GitLab 프로젝트는 원본 프로젝트의 가시성 설정을 상속합니다. 따라서 원본 프로젝트가 공개이면 프로젝트는 공개적으로 액세스 가능합니다.
- `path` 또는 `target_namespace`가 존재하지 않으면 프로젝트 가져오기가 실패합니다.

### GitHub 프로젝트 가져오기 취소 {#cancel-github-project-import}

진행 중인 GitHub 프로젝트 가져오기를 취소합니다.

```plaintext
POST /import/github/cancel
```

| 속성    | 유형    | 필수 | 설명 |
|--------------|---------|----------|-------------|
| `project_id` | 정수 | 예      | GitLab 프로젝트 ID입니다. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/cancel" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "project_id": 12345
}'
```

응답 예시:

```json
{
    "id": 160,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "import_source": "source/source-repo",
    "import_status": "canceled",
    "human_import_status_name": "canceled",
    "provider_link": "/source/source-repo"
}
```

다음 상태 코드를 반환합니다:

- `200 OK`: 프로젝트 가져오기가 취소 중입니다.
- `400 Bad Request`: 프로젝트 가져오기를 취소할 수 없습니다.
- `404 Not Found`: `project_id`와 연결된 프로젝트가 존재하지 않습니다.

### GitHub gist를 GitLab 스니펫으로 가져오기 {#import-github-gists-into-gitlab-snippets}

GitHub 개인 gist를 GitLab 스니펫으로 가져옵니다. 최대 10개의 파일이 있는 gist를 가져올 수 있습니다. 10개 이상의 파일이 있는 GitHub gist는 건너뜁니다. 이러한 GitHub gist는 수동으로 마이그레이션해야 합니다.

gist를 가져올 수 없는 경우 가져오지 못한 gist 목록이 포함된 이메일이 전송됩니다.

```plaintext
POST /import/github/gists
```

| 속성               | 유형   | 필수 | 설명 |
|-------------------------|--------|----------|-------------|
| `personal_access_token` | 문자열 | 예      | GitHub 개인 액세스 토큰입니다. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/gists" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_gitlab_access_token>" \
  --data '{
    "personal_access_token": "<your_github_personal_access_token>"
}'
```

다음 상태 코드를 반환합니다:

- `202 Accepted`: gist 가져오기가 시작 중입니다.
- `401 Unauthorized`: 사용자의 GitHub 개인 액세스 토큰이 유효하지 않습니다.
- `422 Unprocessable Entity`: gist 가져오기가 이미 진행 중입니다.
- `429 Too Many Requests`: 사용자가 GitHub의 속도 제한을 초과했습니다.

## Bitbucket Server에서 리포지토리 가져오기 {#import-repository-from-bitbucket-server}

{{< history >}}

- `bitbucket_server_project` 및 `bitbucket_server_repo` 검증이 GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/429234)되었습니다.

{{< /history >}}

Bitbucket Server에서 GitLab으로 리포지토리를 가져옵니다.

Bitbucket 프로젝트 키는 Bitbucket에서 리포지토리를 찾기 위해서만 사용됩니다. 리포지토리를 GitLab 그룹으로 가져오려면 `target_namespace`을 지정해야 합니다. `target_namespace`을 지정하지 않으면 프로젝트가 개인 사용자 네임스페이스로 가져와집니다.

전제 조건:

- 자세한 내용은 [Bitbucket Server 가져오기 사전 요구사항](../user/import/bitbucket_server.md)을 참조하세요.

```plaintext
POST /import/bitbucket_server
```

| 속성                   | 유형   | 필수 | 설명 |
|-----------------------------|--------|----------|-------------|
| `bitbucket_server_project`  | 문자열 | 예      | Bitbucket 프로젝트 키입니다. 문자, 숫자, 하이픈, 언더스코어, 마침표 또는 공백 문자만 포함해야 합니다. 개인 프로젝트 키는 `~`로 시작합니다. |
| `bitbucket_server_repo`     | 문자열 | 예      | Bitbucket 리포지토리 이름입니다. 문자, 숫자, 하이픈, 언더스코어, 마침표 또는 공백 문자만 포함해야 합니다. |
| `bitbucket_server_url`      | 문자열 | 예      | Bitbucket Server URL입니다. |
| `bitbucket_server_username` | 문자열 | 예      | Bitbucket Server 사용자 이름입니다. |
| `personal_access_token`     | 문자열 | 예      | Bitbucket Server 개인 액세스 토큰 또는 암호입니다. |
| `new_name`                  | 문자열 | 아니요       | 새 프로젝트의 이름입니다. 새 경로로도 사용되므로 특수 문자로 시작하거나 끝나면 안 되며 연속된 특수 문자를 포함하면 안 됩니다. GitLab 16.9 및 이전 버전에서 프로젝트 경로는 대신 Bitbucket에서 [복사](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88845)되었습니다. GitLab 16.10에서 동작이 원래 동작으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145793)되었습니다. |
| `target_namespace`          | 문자열 | 아니요       | 리포지토리를 가져올 네임스페이스입니다. `/namespace/subgroup`와 같은 하위 그룹을 지원합니다. |
| `timeout_strategy`          | 문자열 | 아니요       | 가져오기 타임아웃을 처리하기 위한 전략입니다. 유효한 값은 `optimistic` (가져오기의 다음 스테이지로 계속) 또는 `pessimistic` (즉시 실패)입니다. `pessimistic`로 기본값이 설정됩니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/422979). |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket_server" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_server_url": "http://bitbucket.example.com",
    "bitbucket_server_username": "root",
    "personal_access_token": "Nzk4MDcxODY4MDAyOiP8y410zF3tGAyLnHRv/E0+3xYs",
    "bitbucket_server_project": "NEW",
    "bitbucket_server_repo": "my-repo",
    "new_name": "NEW-NAME"
}'
```

## Bitbucket Cloud에서 리포지토리 가져오기 {#import-repository-from-bitbucket-cloud}

{{< history >}}

- [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/215036).
- Bitbucket Cloud API 토큰 지원이 GitLab 18.9에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/work_items/575583)되었습니다.
- Bitbucket Cloud 앱 암호 지원이 GitLab 19.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/work_items/588961)되었습니다.

{{< /history >}}

Bitbucket Cloud에서 GitLab으로 리포지토리를 가져옵니다.

전제 조건:

- [Bitbucket Cloud 가져오기 사전 요구사항](../user/import/bitbucket_cloud.md).
- 필요한 범위를 가진 [Bitbucket Cloud API 토큰](#bitbucket-cloud-api-token-scopes)입니다.

```plaintext
POST /import/bitbucket
```

| 속성             | 유형   | 필수 | 설명 |
|:----------------------|:-------|:---------|:------------|
| `bitbucket_api_token` | 문자열 | 예      | Bitbucket Cloud API 토큰입니다. |
| `bitbucket_email`     | 문자열 | 예      | Bitbucket Cloud 이메일입니다. |
| `repo_path`           | 문자열 | 예      | 리포지토리 경로입니다. |
| `target_namespace`    | 문자열 | 예      | 리포지토리를 가져올 네임스페이스입니다. `/namespace/subgroup`와 같은 하위 그룹을 지원합니다. |
| `new_name`            | 문자열 | 아니요       | 새 프로젝트의 이름입니다. 새 경로로도 사용되므로 특수 문자로 시작하거나 끝나면 안 되며 연속된 특수 문자를 포함하면 안 됩니다. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_email": "email@example.com",
    "bitbucket_api_token": "your_bitbucket_api_token",
    "repo_path": "username/my_project",
    "target_namespace": "my_group/my_subgroup",
    "new_name": "new_project_name"
}'
```

### Bitbucket Cloud API 토큰 범위 {#bitbucket-cloud-api-token-scopes}

인증을 위해 Bitbucket Cloud API 토큰을 사용하는 경우 토큰은 다음 범위를 가져야 합니다:

- `read:repository:bitbucket`
- `read:pullrequest:bitbucket`
- `read:issue:bitbucket`
- `read:wiki:bitbucket`

## 관련 항목 {#related-topics}

- [직접 전송으로 그룹 마이그레이션 API](bulk_imports.md).
- [그룹 가져오기 및 내보내기 API](group_import_export.md).
- [프로젝트 가져오기 및 내보내기 API](project_import_export.md).
