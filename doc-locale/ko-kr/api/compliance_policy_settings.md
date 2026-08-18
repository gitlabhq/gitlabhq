---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 규정 준수 및 정책 설정 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17392) 되었으며 [플래그](../administration/feature_flags/_index.md) `security_policies_csp`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.3에서 GitLab Self-Managed의 경우 [기본값으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/550318)되었습니다.
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/groups/gitlab-org/-/epics/17392). 기능 플래그 `security_policies_csp` 제거됨.

{{< /history >}}

이 API를 사용하여 GitLab 인스턴스의 보안 정책 설정과 상호 작용합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.
- 보안 정책을 사용하려면 인스턴스에 Ultimate 티어가 있어야 합니다.

## 보안 정책 설정 검색 {#retrieve-security-policy-settings}

이 GitLab 인스턴스의 현재 보안 정책 설정을 검색합니다.

```plaintext
GET /admin/security/compliance_policy_settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

응답 예시:

```json
{
  "csp_namespace_id": 42
}
```

CSP 네임스페이스가 구성되지 않은 경우:

```json
{
  "csp_namespace_id": null
}
```

## 보안 정책 설정 업데이트 {#update-security-policy-settings}

이 GitLab 인스턴스의 보안 정책 설정을 업데이트합니다.

```plaintext
PUT /admin/security/compliance_policy_settings
```

| 속성         | 유형    | 필수 | 설명 |
|:------------------|:--------|:---------|:------------|
| `csp_namespace_id` | 정수 | 예     | 보안 정책을 중앙에서 관리하도록 지정된 그룹의 ID입니다. 최상위 그룹이어야 합니다. 설정을 지우려면 `null`로 설정합니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 42}' \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

응답 예시:

```json
{
  "csp_namespace_id": 42
}
```
