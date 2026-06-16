---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループのインポート/エクスポートAPI
description: "REST APIを使用してグループをインポートおよびエクスポートする。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[グループの構造を移行](../user/group/import/_index.md)できます。このAPIを[プロジェクトインポートおよびエクスポートAPI](project_import_export.md)と組み合わせて使用すると、プロジェクトイシューとグループエピック間の関連性など、グループレベルの関連性を保持できます。

グループエクスポートには以下が含まれます:

- グループマイルストーン
- グループボード
- グループラベル
- グループバッジ
- グループメンバー
- グループイベント
- グループWiki（PremiumおよびUltimateのみ）
- サブグループ。各サブグループには、リスト内の以前のデータがすべて含まれます。

インポートされたプロジェクトからグループレベルの関連性を維持するには、まずグループエクスポートとインポートを実行する必要があります。この方法で、プロジェクトエクスポートを目的のグループ構造にインポートできます。

[イシュー405168](https://gitlab.com/gitlab-org/gitlab/-/issues/405168)のため、インポートされたグループは、親グループにインポートしない限り、`private`表示レベルになります。デフォルトでは、グループを親グループにインポートすると、サブグループは親と同じ表示レベルを継承します。

インポートされたグループのメンバーリストとそれぞれの権限を保持するには、これらのグループのユーザーをレビューしてください。目的のグループをインポートする前に、これらのユーザーが存在することを確認してください。

## グループエクスポートを作成する {#create-a-group-export}

指定したグループのグループエクスポートを作成します。

```plaintext
POST /groups/:id/export
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export"
```

```json
{
  "message": "202 Accepted"
}
```

## グループエクスポートのダウンロードを取得 {#retrieve-a-group-export-download}

指定したグループのエクスポートされたアーカイブを取得する。

```plaintext
GET /groups/:id/export/download
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのID。 |

```shell
group=1
token=secret

curl --request GET \
  --header "PRIVATE-TOKEN: ${token}" \
  --output download_group_${group}.tar.gz \
  --url "https://gitlab.example.com/api/v4/groups/${group}/export/download"
```

```shell
ls *export.tar.gz
2020-12-05_22-11-148_namespace_export.tar.gz
```

グループのエクスポートにかかる時間は、グループのサイズによって異なる場合があります。このエンドポイントは以下を返します:

- エクスポートされたアーカイブ（利用可能な場合）
- 404メッセージ

## グループインポートを作成する {#create-a-group-import}

ファイルをアップロードしてグループインポートを作成します。

最大インポートファイルサイズは、GitLab Self-Managedの管理者によって設定できます（デフォルトは`0`（無制限）です）。管理者は、最大インポートファイルサイズを次のいずれかの方法で変更できます:

- [**管理者**エリア](../administration/settings/import_and_export_settings.md)で。
- [アプリケーション設定API](settings.md#update-application-settings)の`max_import_size`オプションを使用します。

GitLab.comでの最大インポートファイルサイズについては、[アカウントと制限設定](../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

```plaintext
POST /groups/import
```

| 属性   | 型           | 必須 | 説明 |
| ----------- | -------------- | -------- | ----------- |
| `file`      | 文字列         | はい      | アップロードするファイル。 |
| `name`      | 文字列         | はい      | インポートするグループの名前。 |
| `path`      | 文字列         | はい      | 新しいグループの名前とパス。 |
| `parent_id` | 整数        | いいえ       | グループをインポートする親グループのID。指定しない場合、現在のユーザーのネームスペースにデフォルト設定されます。 |

ファイルシステムからファイルをアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "name=imported-group" \
  --form "path=imported-group" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/groups/import"
```

## 関連トピック {#related-topics}

- [プロジェクトのインポート/エクスポートAPI](project_import_export.md)
