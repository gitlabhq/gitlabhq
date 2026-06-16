---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループプレースホルダーの再割り当てAPI
description: "REST APIを使用して、プレースホルダーユーザーを一括で再割り当てします。"
---

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.10で`importer_user_mapping_reassignment_csv`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513794)されました。デフォルトでは有効になっています。
- GitLab 18.0[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/478022)になりました。機能フラグ`importer_user_mapping_reassignment_csv`は削除されました。
- GitLab 18.3で、パーソナルネームスペースにインポートする際にパーソナルネームスペースオーナーにコントリビュートを再割り当てする機能が`user_mapping_to_personal_namespace_owner`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525342)されました。デフォルトでは無効になっています。
- GitLab 18.6で、パーソナルネームスペースにインポートする際にパーソナルネームスペースオーナーにコントリビュートを再割り当てする機能が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626)になりました。機能フラグ`user_mapping_to_personal_namespace_owner`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

このAPIを使用して、[プレースホルダーユーザーを一括で再割り当て](../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file)します。

前提条件: 

- グループのオーナーのロールを持っている必要があります。

> [!note]
> ユーザーのコントリビュートマッピングは、プロジェクトを[個人ネームスペース](../user/namespace/_index.md#types-of-namespaces)にインポートする場合、サポートされていません。個人ネームスペースにインポートする場合、すべてのコントリビュートは個人ネームスペースのオーナーに割り当てられ、再割り当てすることはできません。

## 保留中の再割り当てを取得する {#retrieve-pending-reassignments}

保留中の再割り当てのリストを含むCSVファイルを取得します。

```plaintext
GET /groups/:id/placeholder_reassignments
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのID、またはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/placeholder_reassignments"
```

レスポンス例: 

```csv
Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
http://gitlab.example,gitlab_migration,11,Bob,bob,"",""
http://gitlab.example,gitlab_migration,9,Alice,alice,"",""
```

## プレースホルダーを再割り当て {#reassign-placeholders}

アップロードされたCSVファイルでプレースホルダーユーザーを再割り当てします。

```plaintext
POST /groups/:id/placeholder_reassignments
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのID、またはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@placeholder_reassignments_for_group_2_1741253695.csv" \
  --url "http://gdk.test:3000/api/v4/groups/2/placeholder_reassignments"
```

レスポンス例: 

```json
{"message":"The file is being processed and you will receive an email when completed."}
```
