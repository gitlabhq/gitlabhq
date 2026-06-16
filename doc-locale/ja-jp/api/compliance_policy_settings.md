---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コンプライアンスおよびセキュリティポリシー設定API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2で`security_policies_csp`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17392)されました。デフォルトでは無効になっています。
- GitLab Self-ManagedのGitLab 18.3で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/550318)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/17392)になりました。機能フラグ`security_policies_csp`は削除されました。

{{< /history >}}

このAPIを使用して、お使いのGitLabインスタンスのセキュリティポリシー設定を操作します。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。
- お使いのインスタンスは、セキュリティポリシーを使用するためにUltimateティアが必要です。

## セキュリティポリシー設定を取得する {#retrieve-security-policy-settings}

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

CSPネームスペースが設定されていない場合:

```json
{
  "csp_namespace_id": null
}
```

## セキュリティポリシー設定を更新する {#update-security-policy-settings}

このGitLabインスタンスのセキュリティポリシー設定を更新します。

```plaintext
PUT /admin/security/compliance_policy_settings
```

| 属性         | 型    | 必須 | 説明 |
|:------------------|:--------|:---------|:------------|
| `csp_namespace_id` | 整数 | はい     | セキュリティポリシーを中央で管理するために指定されたグループのID。トップレベルグループである必要があります。設定をクリアするには`null`に設定します。 |

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
