---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 仮想レジストリのクリーンアップポリシーAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.6で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572839)されました。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

これらのエンドポイントの可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。使用する前に、ドキュメントを注意深く確認してください。

{{< /alert >}}

このAPIを使用して以下を行います:

- 仮想レジストリのクリーンアップポリシーを作成および管理します。
- クリーンアップポリシーのスケジュールと保持を設定します。
- 未使用のキャッシュエントリを自動的にクリーンアップポリシーします。

## クリーンアップポリシーを管理 {#manage-cleanup-policies}

仮想レジストリのクリーンアップポリシーを作成および管理するには、次のエンドポイントを使用します。各グループが持つことができるクリーンアップポリシーは1つのみです。

### グループのクリーンアップポリシーを取得します {#get-the-cleanup-policy-for-a-group}

{{< history >}}

- GitLab 18.6で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572839)されました。デフォルトでは有効になっています。

{{< /history >}}

グループのクリーンアップポリシーを取得します。各グループが持つことができるクリーンアップポリシーは1つのみです。

```plaintext
GET /groups/:id/-/virtual_registries/cleanup/policy
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列または整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

レスポンス例:

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

### クリーンアップポリシーを作成する {#create-a-cleanup-policy}

{{< history >}}

- GitLab 18.6で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572839)されました。デフォルトでは有効になっています。

{{< /history >}}

グループのクリーンアップポリシーを作成します。各グループが持つことができるクリーンアップポリシーは1つのみです。

```plaintext
POST /groups/:id/-/virtual_registries/cleanup/policy
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列または整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |
| `cadence` | 整数 | いいえ | クリーンアップポリシーの実行頻度。次のいずれかである必要があります: `1`（毎日）、`7`（毎週）、`14`（隔週）、`30`（毎月）、`90`（四半期ごと）。 |
| `enabled` | ブール値 | いいえ | クリーンアップポリシーを有効または無効にします。 |
| `keep_n_days_after_download` | 整数 | いいえ | 未使用のキャッシュエントリをクリーンアップポリシーするまでの日数。1～365の間である必要があります。 |

リクエスト例:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"enabled": true, "keep_n_days_after_download": 30, "cadence": 7}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

レスポンス例:

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
  "failure_message": null,
  "last_run_detailed_metrics": {},
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### クリーンアップポリシーを更新する {#update-a-cleanup-policy}

{{< history >}}

- GitLab 18.6で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572839)されました。デフォルトでは有効になっています。

{{< /history >}}

グループのクリーンアップポリシーを更新します。

```plaintext
PATCH /groups/:id/-/virtual_registries/cleanup/policy
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列または整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |
| `cadence` | 整数 | いいえ | クリーンアップポリシーの実行頻度。次のいずれかである必要があります: `1`（毎日）、`7`（毎週）、`14`（隔週）、`30`（毎月）、`90`（四半期ごと）。 |
| `enabled` | ブール値 | いいえ | ポリシーを有効/無効にするブール値。 |
| `keep_n_days_after_download` | 整数 | いいえ | 未使用のキャッシュエントリをクリーンアップポリシーするまでの日数。1～365の間である必要があります。 |

{{< alert type="note" >}}

少なくとも1つのオプションパラメータをリクエストで指定する必要があります。

{{< /alert >}}

リクエスト例:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"keep_n_days_after_download": 60}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

レスポンス例:

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

### クリーンアップポリシーを削除 {#delete-a-cleanup-policy}

{{< history >}}

- GitLab 18.6で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572839)されました。デフォルトでは有効になっています。

{{< /history >}}

グループのクリーンアップポリシーを削除します。

```plaintext
DELETE /groups/:id/-/virtual_registries/cleanup/policy
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列または整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。
