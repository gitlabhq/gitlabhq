---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループのセキュリティ設定API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/502827)されました。

{{< /history >}}

グループのセキュリティ設定に対するすべてのAPIコールは、[認証](rest/authentication.md)される必要があります。

ユーザーがプライベートグループのメンバーでない場合、プライベートグループに対するリクエストは、`404 Not Found`ステータスコードを返します。

## `secret_push_protection_enabled`設定を更新 {#update-secret_push_protection_enabled-setting}

グループ内のすべてのプロジェクトについて、`secret_push_protection_enabled`設定を、指定された値に更新します。

`true`に設定して、グループ内のすべてのプロジェクトに対して[シークレットプッシュ保護](../user/application_security/secret_detection/secret_push_protection/_index.md)を有効にします。

前提要件: 

- グループのメンテナーロール以上を持っている必要があります。

| 属性           | 型              | 必須   | 説明                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | 整数または文字列 | はい        | 認証済みユーザーがメンバーであるグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)  |
| `secret_push_protection_enabled`        | ブール値 | はい        | シークレットプッシュ保護がグループに対して有効になっているかどうか。 |
| `projects_to_exclude`        | 整数の配列 | いいえ        | この機能から除外するプロジェクトのID。  |

```shell
curl --request PUT \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/groups/7/security_settings?secret_push_protection_enabled=true&projects_to_exclude[]=1&projects_to_exclude[]=2"
```

レスポンス例:

```json
{
  "secret_push_protection_enabled": true,
  "errors": []
}
```
