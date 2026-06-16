---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトのセキュリティ設定API
description: プロジェクトのセキュリティオプション（シークレットプッシュ保護など）を一覧表示および更新するためのAPIエンドポイント。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトセキュリティ設定に対するすべてのAPIコールは、[認証される](rest/authentication.md)必要があります。

プロジェクトがプライベートで、かつユーザーがセキュリティ設定が属するプロジェクトのメンバーでない場合、そのプロジェクトへのリクエストは`404 Not Found`ステータスコードを返します。

## すべてのプロジェクトセキュリティ設定を一覧表示する {#list-all-project-security-settings}

プロジェクトのすべてのセキュリティ設定を一覧表示します。

前提条件: 

- プロジェクトのセキュリティマネージャー、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/security_settings
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                            |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

レスポンス例: 

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": true
}
```

## `secret_push_protection_enabled`設定を更新する {#update-the-secret_push_protection_enabled-setting}

{{< history >}}

- GitLab 17.11で`pre_receive_secret_detection_enabled`から[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185310)。

{{< /history >}}

指定されたプロジェクトの`secret_push_protection_enabled`設定を更新します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

```plaintext
PUT /projects/:id/security_settings
```

| 属性                        | 型              | 必須 | 説明 |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `secret_push_protection_enabled` | ブール値           | はい      | プロジェクトのシークレットプッシュ保護を有効にします。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "secret_push_protection_enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

レスポンス例: 

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": false
}
```
