---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Git URLを介して移行する
description: "Git URLを使用して、GitLabにリポジトリをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Git URLを使用して、既存のリポジトリをインポートします。この方法で実行されたインポートには、GitLabイシューやマージリクエストは含まれません。

## 前提条件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [リポジトリのURLインポート元](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)が有効になっています。有効になっていない場合は、GitLab管理者に有効にするように依頼してください。URLによるリポジトリインポート元は、GitLab.comでデフォルトで有効になっています。
- インポート先のターゲットグループにおけるメンテナーまたはオーナーロール。
- プライベートリポジトリをインポートする場合、パスワードの代わりに、ソースリポジトリへの認証アクセス用のアクセストークンが必要になる場合があります。

## UIを介してリポジトリをインポートする {#import-a-repository-through-the-ui}

UIを介してリポジトリをインポートするには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択します。
1. **リポジトリのURL**を選択します。
1. **GitリポジトリのURL**を入力します。
1. 残りのフィールドを入力します。プライベートリポジトリからのインポートには、ユーザー名とパスワード（またはアクセストークン）が必要です。
1. **プロジェクトを作成**を選択します。

新しく作成されたプロジェクトが表示されます。

## APIを介してリポジトリをインポートする {#import-a-repository-through-the-api}

[プロジェクトAPI](../../../api/projects.md#create-a-project)を使用してGitリポジトリをインポートできます:

```shell
curl --location "https://gitlab.example.com/api/v4/projects/" \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer <your-token>' \
--data-raw '{
    "description": "New project description",
    "path": "new_project_path",
    "import_url": "https://username:password@example.com/group/project.git"
}'
```

一部のプロバイダではパスワードを許可せず、代わりにアクセストークンを必要とします。

## タイムアウトしたリポジトリをインポートする {#import-a-timed-out-repository}

大規模なリポジトリのインポートは、3時間後にタイムアウトする可能性があります。タイムアウトしたリポジトリをインポートするには:

1. リポジトリをクローンします:

   ```shell
   git clone --mirror https://example.com/group/project.git
   ```

   `--mirror`オプションにより、すべてのブランチ、タグ、およびrefsがコピーされます。

1. 新しいリモートリポジトリを追加します:

   ```shell
   cd repository.git
   git remote add new-origin https://gitlab.com/group/project.git
   ```

1. 新しいリモートリポジトリにすべてをプッシュします:

   ```shell
   git push --mirror new-origin
   ```

## 関連トピック {#related-topics}

- [インポートとエクスポートの設定](../../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../../administration/sidekiq/processing_specific_job_classes.md)。
