---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabでグループの設定を更新します。グループ内のすべてのプロジェクトに対し、シークレットプッシュ保護やその他のセキュリティポリシーを設定します。
title: グループセキュリティ設定API
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

## グループセキュリティ設定を更新 {#update-group-security-settings}

指定されたグループのグループ設定を更新します。

前提条件: 

- グループのセキュリティマネージャー、メンテナー、またはオーナーのロールが必要です。

```plaintext
PUT /groups/:id/security_settings
```

| 属性                        | 型              | 必須 | 説明 |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | 整数または文字列 | はい      | グループのID、またはURLエンコードされた[パス](rest/_index.md#namespaced-paths)。 |
| `secret_push_protection_enabled` | ブール値           | はい      | グループ内のプロジェクトでシークレットプッシュ保護を有効にします。 |
| `projects_to_exclude`            | 整数の配列 | いいえ       | シークレットプッシュ保護から除外するプロジェクトのID。 |

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
