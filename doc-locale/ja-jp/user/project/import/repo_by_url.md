---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: URLでリポジトリからプロジェクトをインポートする
description: "URLでGitLabにリポジトリをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Git URLを指定して、既存のリポジトリをインポートできます。この方法では、GitLabイシューとマージリクエストをインポートできません。他の方法では、より完全なインポート方法が提供されます。

リポジトリが大きすぎる場合、インポートがタイムアウトになる可能性があります。

次の方法でGitリポジトリをインポートできます:

- [UIを使用する](#import-a-project-by-using-the-ui)
- [APIを使用する](#import-a-project-by-using-the-api)

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [リポジトリのURLからのインポート元](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。有効になっていない場合は、GitLab管理者に有効にするように依頼してください。GitLab.comでは、リポジトリのURLからのインポート元はデフォルトで有効になっています。
- インポート先のGitLabグループに対する少なくともメンテナーロールが必要です。
- プライベートリポジトリをインポートする場合は、パスワードの代わりに、ソースリポジトリへの認証されたアクセスのためのアクセストークンが必要になる場合があります。

## UIを使用してプロジェクトをインポートする {#import-a-project-by-using-the-ui}

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **リポジトリのURL**を選択します。
1. **GitリポジトリのURL**を入力します。
1. 残りのフィールドを入力します。プライベートリポジトリからインポートするには、ユーザー名とパスワード（またはアクセストークン）が必要です。
1. **プロジェクトを作成**を選択します。

新しく作成されたプロジェクトが表示されます。

### タイムアウトしたプロジェクトのインポート {#import-a-timed-out-project}

大規模なリポジトリのインポートは、3時間後にタイムアウトする可能性があります。タイムアウトしたプロジェクトをインポートするには、次のようにします:

1. リポジトリのクローンを作成します。

   ```shell
   git clone --mirror https://example.com/group/project.git
   ```

   `--mirror`オプションを指定すると、すべてのブランチ、タグ、およびrefsがコピーされます。

1. 新しいリモートリポジトリを追加します。

   ```shell
   cd repository.git
   git remote add new-origin https://gitlab.com/group/project.git
   ```

1. すべてを新しいリモートリポジトリにプッシュします。

   ```shell
   git push --mirror new-origin
   ```

## APIを使用してプロジェクトをインポートする {#import-a-project-by-using-the-api}

[Projects API](../../../api/projects.md#create-a-project)を使用して、Gitリポジトリをインポートできます:

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

一部のプロバイダーではパスワードが許可されておらず、代わりにアクセストークンが必要です。
