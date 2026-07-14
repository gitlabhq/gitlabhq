---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: LDAP 그룹 링크
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 API를 사용하여 LDAP 그룹 링크를 관리합니다. 자세한 내용은 [LDAP를 사용한 그룹 멤버십 관리](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)를 참조하세요.

## 모든 LDAP 그룹 링크 나열 {#list-all-ldap-group-links}

모든 LDAP 그룹 링크를 나열합니다.

```plaintext
GET /groups/:id/ldap_group_links
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

응답 예시:

```json
[
  {
    "cn": "group1",
    "group_access": 40,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  },
  {
    "cn": "group2",
    "group_access": 10,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  }
]
```

## CN 또는 필터를 사용하여 LDAP 그룹 링크 추가 {#add-an-ldap-group-link-with-cn-or-filter}

CN 또는 필터를 사용하여 LDAP 그룹 링크를 추가합니다.

```plaintext
POST /groups/:id/ldap_group_links
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `group_access` | 정수   | 예      | LDAP 그룹 멤버의 기본 액세스 수준입니다. 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자), `50` (소유자). |
| `provider` | 문자열        | 예      | LDAP 그룹 링크의 LDAP 제공자 ID입니다. |
| `cn`      | 문자열         | 예/아니오   | LDAP 그룹의 CN입니다. `cn` 또는 `filter` 중 하나를 제공하되, 둘 다 제공할 수는 없습니다. |
| `filter`  | 문자열         | 예/아니오   | 그룹의 LDAP 필터입니다. `cn` 또는 `filter` 중 하나를 제공하되, 둘 다 제공할 수는 없습니다. |
| `member_role_id` | 정수 | 아니요       | [멤버 역할](member_roles.md)의 ID입니다. Ultimate만 해당. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"group_access": 40, "provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

응답 예시:

```json
{
  "cn": "group2",
  "group_access": 40,
  "provider": "main",
  "filter": null,
  "member_role_id": null
}
```

## CN 또는 필터를 사용하여 LDAP 그룹 링크 삭제 {#delete-an-ldap-group-link-with-cn-or-filter}

CN 또는 필터를 사용하여 LDAP 그룹 링크를 삭제합니다.

```plaintext
DELETE /groups/:id/ldap_group_links
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `provider` | 문자열        | 예      | LDAP 그룹 링크의 LDAP 제공자 ID입니다. |
| `cn`      | 문자열         | 예/아니오   | LDAP 그룹의 CN입니다. `cn` 또는 `filter` 중 하나를 제공하되, 둘 다 제공할 수는 없습니다. |
| `filter`  | 문자열         | 예/아니오   | 그룹의 LDAP 필터입니다. `cn` 또는 `filter` 중 하나를 제공하되, 둘 다 제공할 수는 없습니다. |

요청 예시:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

성공한 경우 응답이 반환되지 않습니다.

## LDAP 그룹 링크 삭제(더 이상 사용되지 않음) {#delete-an-ldap-group-link-deprecated}

LDAP 그룹 링크를 삭제합니다. 지원 중단됨. 향후 릴리스에서 제거될 예정입니다. 대신 [CN 또는 필터를 사용하여 LDAP 그룹 링크 삭제](#delete-an-ldap-group-link-with-cn-or-filter)를 사용하세요.

CN을 사용하여 LDAP 그룹 링크 삭제:

```plaintext
DELETE /groups/:id/ldap_group_links/:cn
```

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `cn`      | 문자열         | 예      | LDAP 그룹의 CN |

특정 LDAP 제공자에 대한 LDAP 그룹 링크 삭제:

```plaintext
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `cn`      | 문자열         | 예      | LDAP 그룹의 CN |
| `provider` | 문자열        | 예      | LDAP 그룹 링크의 LDAP 제공자 |
