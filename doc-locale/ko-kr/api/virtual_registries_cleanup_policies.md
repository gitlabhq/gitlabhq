---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 가상 레지스트리 정리 정책 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) 됨 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry` 이름. 기본적으로 활성화됨.

{{< /history >}}

> [!flag]
> 이 엔드포인트의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 이력을 참조하세요. 사용하기 전에 설명서를 신중하게 검토하세요.

이 API를 사용하여:

- 가상 레지스트리 정리 정책을 생성하고 관리합니다.
- 정리 일정 및 보존 설정을 구성합니다.
- 사용되지 않는 캐시 항목을 자동으로 정리합니다.

## 정리 정책 관리 {#manage-cleanup-policies}

다음 엔드포인트를 사용하여 가상 레지스트리 정리 정책을 생성하고 관리합니다. 각 그룹은 정리 정책을 하나만 가질 수 있습니다.

### 그룹의 정리 정책 검색 {#retrieve-the-cleanup-policy-for-a-group}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) 됨 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry` 이름. 기본적으로 활성화됨.

{{< /history >}}

지정된 그룹의 정리 정책을 검색합니다. 각 그룹은 정리 정책을 하나만 가질 수 있습니다.

```plaintext
GET /groups/:id/-/virtual_registries/cleanup/policy
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|:----------|:-----|:---------|:------------|
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

응답 예시:

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": "2024-05-30T12:28:27.855Z",
  "last_run_deleted_size": 1048576,
  "last_run_deleted_entries_count": 25,
  "keep_n_days_after_download": 30,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {
    "maven": {
      "deleted_entries_count": 25,
      "deleted_size": 1048576
    }
  },
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 정리 정책 생성 {#create-a-cleanup-policy}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) 됨 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry` 이름. 기본적으로 활성화됨.

{{< /history >}}

지정된 그룹에 대한 정리 정책을 생성합니다. 각 그룹은 정리 정책을 하나만 가질 수 있습니다.

```plaintext
POST /groups/:id/-/virtual_registries/cleanup/policy
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `cadence` | 정수 | 아니요 | 정리 정책이 실행되는 빈도입니다. 다음 중 하나여야 합니다: `1` (일일), `7` (주간), `14` (격주), `30` (월간), `90` (분기별). |
| `enabled` | 부울 | 아니요 | 정리 정책을 사용하거나 비활성화합니다. |
| `keep_n_days_after_download` | 정수 | 아니요 | 사용되지 않는 캐시 항목을 정리해야 하는 일 수입니다. 1에서 365 사이여야 합니다. |
| `notify_on_success` | 부울 | 아니요 | 성공한 정리 실행에 대해 그룹 소유자에게 알립니다. |
| `notify_on_failure` | 부울 | 아니요 | 실패한 정리 실행에 대해 그룹 소유자에게 알립니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"enabled": true, "keep_n_days_after_download": 30, "cadence": 7}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

응답 예시:

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": null,
  "last_run_deleted_size": 0,
  "last_run_deleted_entries_count": 0,
  "keep_n_days_after_download": 30,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {},
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 정리 정책 업데이트 {#update-a-cleanup-policy}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) 됨 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry` 이름. 기본적으로 활성화됨.

{{< /history >}}

지정된 그룹의 정리 정책을 업데이트합니다.

```plaintext
PATCH /groups/:id/-/virtual_registries/cleanup/policy
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |
| `cadence` | 정수 | 아니요 | 정리 정책이 실행되는 빈도입니다. 다음 중 하나여야 합니다: `1` (일일), `7` (주간), `14` (격주), `30` (월간), `90` (분기별). |
| `enabled` | 부울 | 아니요 | 정책을 사용하거나 비활성화할 부울입니다. |
| `keep_n_days_after_download` | 정수 | 아니요 | 사용되지 않는 캐시 항목을 정리해야 하는 일 수입니다. 1에서 365 사이여야 합니다. |
| `notify_on_success` | 부울 | 아니요 | 성공한 정리 실행에 대해 그룹 소유자에게 알립니다. |
| `notify_on_failure` | 부울 | 아니요 | 실패한 정리 실행에 대해 그룹 소유자에게 알립니다. |

> [!note]
> 요청에서 선택적 매개변수 중 하나 이상을 제공해야 합니다.

요청 예시:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"keep_n_days_after_download": 60}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

응답 예시:

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": "2024-05-30T12:28:27.855Z",
  "last_run_deleted_size": 1048576,
  "last_run_deleted_entries_count": 25,
  "keep_n_days_after_download": 60,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {
    "maven": {
      "deleted_entries_count": 25,
      "deleted_size": 1048576
    }
  },
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 정리 정책 삭제 {#delete-a-cleanup-policy}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) 됨 [플래그](../administration/feature_flags/_index.md) `maven_virtual_registry` 이름. 기본적으로 활성화됨.

{{< /history >}}

지정된 그룹의 정리 정책을 삭제합니다.

```plaintext
DELETE /groups/:id/-/virtual_registries/cleanup/policy
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 또는 정수 | 예 | 그룹 ID 또는 전체 그룹 경로입니다. 최상위 그룹이어야 합니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.
