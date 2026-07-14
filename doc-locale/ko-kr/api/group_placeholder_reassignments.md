---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 플레이스홀더 재할당 API
description: "를 사용하여 플레이스홀더 사용자를 대량으로 재할당합니다."
---

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/513794) 되었으며 [플래그](../administration/feature_flags/_index.md) `importer_user_mapping_reassignment_csv`로 제공됩니다. 기본적으로 활성화됨.
- GitLab 18.0에서 [정식 출시](https://gitlab.com/gitlab-org/gitlab/-/issues/478022)되었습니다. 기능 플래그 `importer_user_mapping_reassignment_csv` 제거됨.
- 개인 네임스페이스로 가져올 때 개인 네임스페이스 소유자에게 기여도를 재할당하는 기능이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) 되었으며 [플래그](../administration/feature_flags/_index.md) `user_mapping_to_personal_namespace_owner`로 제공됩니다. 기본적으로 비활성화됨.
- 개인 네임스페이스로 가져올 때 개인 네임스페이스 소유자에게 기여도를 재할당하는 기능이 GitLab 18.6에서 [정식 출시](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626)되었습니다. 기능 플래그 `user_mapping_to_personal_namespace_owner` 제거됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

이 API를 사용하여 [플레이스홀더 사용자를 대량으로 재할당](../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file)합니다.

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

> [!note]
> 프로젝트를 [개인 네임스페이스](../user/namespace/_index.md#types-of-namespaces)로 가져올 때 사용자 기여도 매핑은 지원되지 않습니다. 개인 네임스페이스로 가져오면 모든 기여도가 개인 네임스페이스 소유자에게 할당되며 재할당할 수 없습니다.

## 보류 중인 재할당 검색 {#retrieve-pending-reassignments}

보류 중인 재할당 목록이 포함된 CSV 파일을 검색합니다.

```plaintext
GET /groups/:id/placeholder_reassignments
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/placeholder_reassignments"
```

응답 예시:

```csv
Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
http://gitlab.example,gitlab_migration,11,Bob,bob,"",""
http://gitlab.example,gitlab_migration,9,Alice,alice,"",""
```

## 플레이스홀더 재할당 {#reassign-placeholders}

업로드된 CSV 파일로 플레이스홀더 사용자를 재할당합니다.

```plaintext
POST /groups/:id/placeholder_reassignments
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@placeholder_reassignments_for_group_2_1741253695.csv" \
  --url "http://gdk.test:3000/api/v4/groups/2/placeholder_reassignments"
```

응답 예시:

```json
{"message":"The file is being processed and you will receive an email when completed."}
```
