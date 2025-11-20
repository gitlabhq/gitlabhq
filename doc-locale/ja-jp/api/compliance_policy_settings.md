---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンプライアンスおよびポリシー設定API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.2で`security_policies_csp`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17392)されました。デフォルトでは無効になっています。
- [デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/550318)。GitLab 18.3のGitLab Self-Managedで利用できます。
- [一般提供](https://gitlab.com/groups/gitlab-org/-/epics/17392)はGitLab 18.5で行われます。機能フラグ`security_policies_csp`は削除されました。

{{< /history >}}

このAPIを使用すると、GitLabインスタンスのセキュリティポリシー設定を操作できます。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。
- セキュリティポリシーを使用するには、インスタンスがUltimateプランである必要があります。

## セキュリティポリシー設定を取得 {#get-security-policy-settings}

このGitLabインスタンスの現在のセキュリティポリシー設定を取得します。

```plaintext
GET /admin/security/compliance_policy_settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

レスポンス例:

```json
{
  "csp_namespace_id": 42
}
```

CSPネームスペースが構成されていない場合:

```json
{
  "csp_namespace_id": null
}
```

## セキュリティポリシー設定を更新 {#update-security-policy-settings}

このGitLabインスタンスのセキュリティポリシー設定を更新します。

```plaintext
PUT /admin/security/compliance_policy_settings
```

| 属性         | 型    | 必須 | 説明 |
|:------------------|:--------|:---------|:------------|
| `csp_namespace_id` | 整数 | はい     | セキュリティポリシーを一元的に管理するために指定されたグループのID。トップレベルグループである必要があります。`null`に設定すると、設定がクリアされます。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 42}' \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

レスポンス例:

```json
{
  "csp_namespace_id": 42
}
```
