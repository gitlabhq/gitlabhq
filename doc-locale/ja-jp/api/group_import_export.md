---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループのインポート/エクスポートAPI
description: "REST APIを使用して、グループをインポートおよびエクスポートする。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[グループ構造を移行する](../user/group/import/_index.md)。このAPIを[プロジェクトインポート・エクスポートAPI](project_import_export.md)とともに使用すると、プロジェクトのイシューとグループエピック間の接続など、グループレベルの関係を保持できます。

グループのエクスポートには、以下が含まれます:

- グループマイルストーン
- グループボード
- グループラベル
- グループバッジ
- グループメンバー
- グループWiki（PremiumおよびUltimateプランのみ）
- サブグループ。各サブグループには、リスト内の以前のすべてのデータが含まれます。

インポートされたプロジェクトからグループレベルの関係を保持するには、最初にグループのエクスポートとインポートを実行する必要があります。これにより、目的のグループ構造にプロジェクトのエクスポートをインポートできます。

[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/405168)により、グループを親グループにインポートしない限り、インポートされたグループの表示レベルは`private`になります。デフォルトでは、グループを親グループにインポートすると、サブグループは親と同じ表示レベルを継承します。

インポートされたグループのメンバーリストとそれぞれの権限を保持するには、これらのグループのユーザーをレビューしてください。目的のグループをインポートする前に、これらのユーザーが存在することを確認してください。

## 前提要件 {#prerequisites}

- グループインポート・エクスポートAPIの前提条件については、[エクスポートファイルをアップロードしてグループを移行する](../user/project/settings/import_export.md#preparation)ための前提条件を参照してください。

## 新しいエクスポートのスケジュール {#schedule-new-export}

新しいグループエクスポートを開始します。

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

## エクスポートのダウンロード {#export-download}

完了したエクスポートをダウンロードします。

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

グループのエクスポートに費やす時間は、グループのサイズによって異なる場合があります。このエンドポイントは、次のいずれかを返します:

- エクスポートされたアーカイブ（利用可能な場合）
- 404メッセージ

## ファイルをインポート {#import-a-file}

インポートするファイルの最大サイズは、GitLabセルフマネージドの管理者が設定できます（デフォルトは`0`（無制限））。管理者は、インポートするファイルの最大サイズを次のいずれかの方法で変更できます:

- [**管理者**エリア](../administration/settings/import_and_export_settings.md)で操作する。
- [アプリケーション設定API](settings.md#update-application-settings)の`max_import_size`オプションを使用する。

GitLab.comのインポートファイルの最大サイズについては、[アカウントと制限設定](../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

```plaintext
POST /groups/import
```

| 属性   | 型           | 必須 | 説明 |
| ----------- | -------------- | -------- | ----------- |
| `file`      | 文字列         | はい      | アップロードするファイル。 |
| `name`      | 文字列         | はい      | インポートするグループの名前。 |
| `path`      | 文字列         | はい      | 新しいグループの名前とパス。 |
| `parent_id` | 整数        | いいえ       | グループのインポート先の親グループのID。指定されていない場合、現在のユーザーのネームスペースにデフォルト設定されます。 |

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
