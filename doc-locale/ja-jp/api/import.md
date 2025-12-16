---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インポートAPI
description: "GitHubまたはBitbucket ServerからREST APIを使用してリポジトリをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- パーソナルネームスペースへのインポート時に、パーソナルネームスペースのオーナーにコントリビュートを再割り当てすることは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525342)されました（`user_mapping_to_personal_namespace_owner`という名前の[フラグ付き](../administration/feature_flags/_index.md)）。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

このAPIを使用して、[外部ソースからリポジトリをインポートする](../user/project/import/_index.md)ことができます。

{{< alert type="note" >}}

プロジェクトを[個人ネームスペース](../user/namespace/_index.md#types-of-namespaces)にインポートする場合、ユーザーコントリビュートマッピングはサポートされていません。パーソナルネームスペースにインポートし、`user_mapping_to_personal_namespace_owner`機能フラグが有効になっている場合、すべてのコントリビュートはパーソナルネームスペースのオーナーに割り当てられ、再割り当てできません。`user_mapping_to_personal_namespace_owner`機能フラグが無効になっている場合、すべてのコントリビュートは`Import User`という単一の非機能ユーザー名に割り当てられ、再割り当てできません。

{{< /alert >}}

## GitHubからリポジトリをインポート {#import-repository-from-github}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。
- `optional_stages`の`collaborators_import`キーは、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)されました。
- 機能フラグ`github_import_extended_events`はGitLab 16.8で導入されました。デフォルトでは無効になっています。このフラグを使用すると、インポートのパフォーマンスが向上しますが、`single_endpoint_issue_events_import`オプションのステージングは無効になります。
- GitLab 16.9で、機能フラグ`github_import_extended_events`が[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)になりました。
- 改善されたインポートパフォーマンスは、GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)されました。機能フラグ`github_import_extended_events`は削除されました。

{{< /history >}}

APIを使用して、GitHubからGitLabへプロジェクトをインポートします。

前提要件: 

- [GitHubインポーターの前提条件](../user/project/import/github.md#prerequisites)。
- `target_namespace`で設定されたネームスペースが存在する必要があります。
- ネームスペースは、ユーザー名のネームスペースまたは、少なくともメンテナーロールを持つ既存のグループにすることができます。

```plaintext
POST /import/github
```

| 属性               | 型    | 必須 | 説明 |
|-------------------------|---------|----------|-------------|
| `personal_access_token` | 文字列  | はい      | GitHubのパーソナルアクセストークン。 |
| `repo_id`               | 整数 | はい      | GitHubリポジトリID。 |
| `target_namespace`      | 文字列  | はい      | リポジトリのインポート先のネームスペース。`/namespace/subgroup`のようなサブグループをサポートします。空白にすることはできません。 |
| `github_hostname`       | 文字列  | いいえ       | カスタムGitHub Enterpriseホスト名。GitHub.comには設定しないでください。GitLab 16.5からGitLab 17.1までは、パス`/api/v3`を含める必要があります。 |
| `new_name`              | 文字列  | いいえ       | 新しいプロジェクトの名前。新しいパスとしても使用されるため、特殊文字で始めたり終わったりすることはできず、連続した特殊文字を含めることもできません。 |
| `optional_stages`       | オブジェクト  | いいえ       | インポートする[追加アイテム](../user/project/import/github.md#select-additional-items-to-import)。 |
| `pagination_limit`      | 整数 | いいえ       | GitHubへのAPIリクエストごとに取得されるアイテム数。デフォルト値は、ページあたり100アイテムです。大規模なリポジトリからのプロジェクトインポートの場合、数値を小さくすると、GitHub APIエンドポイントから`500`または`502`エラーが返されるリスクを軽減できます。ただし、ページサイズを小さくすると、移行時間が増加します。 |
| `timeout_strategy`      | 文字列  | いいえ       | インポートのタイムアウトを処理するためのストラテジー。有効な値は、`optimistic`（インポートの次のステージングに進む）または`pessimistic`（すぐに失敗する）です。`pessimistic`がデフォルトです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422979)されました。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github" \
  --header "content-type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{
    "personal_access_token": "aBc123abC12aBc123abC12abC123+_A/c123",
    "repo_id": "12345",
    "target_namespace": "group/subgroup",
    "new_name": "NEW-NAME",
    "github_hostname": "https://github.example.com",
    "optional_stages": {
      "single_endpoint_notes_import": true,
      "attachments_import": true,
      "collaborators_import": true
    }
}'
```

次のキーは、`optional_stages`で使用できます:

- `attachments_import`、Markdownの添付ファイルをインポートします。
- `collaborators_import`、外部コラボレーターではない直接リポジトリコラボレーターをインポートします。
- `single_endpoint_issue_events_import`、イシューとプルリクエストイベントをインポートします。このオプションのステージングは、GitLab 16.9で削除されました。
- `single_endpoint_notes_import`、代替的でより徹底的なコメントをインポートします。

詳細については、[追加のアイテムのインポートの選択](../user/project/import/github.md#select-additional-items-to-import)を参照してください。

レスポンス例:

```json
{
    "id": 27,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "refs_url": "/root/my-repo/refs",
    "import_source": "my-github/repo",
    "import_status": "scheduled",
    "human_import_status_name": "scheduled",
    "provider_link": "/my-github/repo",
    "relation_type": null,
    "import_warning": null
}
```

### グループアクセストークンを使用してAPI経由でパブリックプロジェクトをインポート {#import-a-public-project-through-the-api-using-a-group-access-token}

グループアクセストークンを使用してGitHubからGitLabにプロジェクトをAPI経由でインポートすると、次のようになります:

- GitLabプロジェクトは、元のプロジェクトの表示レベル設定を継承します。その結果、元のプロジェクトがパブリックの場合、プロジェクトはパブリックにアクセスできます。
- `path`または`target_namespace`が存在しない場合、プロジェクトのインポートは失敗します。

### GitHubプロジェクトのインポートのキャンセル {#cancel-github-project-import}

APIを使用して、進行中のGitHubプロジェクトのインポートをキャンセルします。

```plaintext
POST /import/github/cancel
```

| 属性    | 型    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `project_id` | 整数 | はい      | GitLabのプロジェクトID。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/cancel" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "project_id": 12345
}'
```

レスポンス例:

```json
{
    "id": 160,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "import_source": "source/source-repo",
    "import_status": "canceled",
    "human_import_status_name": "canceled",
    "provider_link": "/source/source-repo"
}
```

次のステータスコードを返します:

- `200 OK`: プロジェクトのインポートがキャンセルされます。
- `400 Bad Request`: プロジェクトのインポートをキャンセルできません。
- `404 Not Found`: `project_id`に関連付けられたプロジェクトが存在しません。

### GitHubジストをGitLabスニペットにインポート {#import-github-gists-into-gitlab-snippets}

GitLab APIを使用して、（最大10個のファイルを含む）個人用GitHubジストを個人用GitLabスニペットにインポートできます。ファイル数が10を超えるGitHubジストはスキップされます。これらのGitHubジストは手動で移行する必要があります。

ジストをインポートできなかった場合、インポートされなかったジストのリストが記載されたメールが送信されます。

```plaintext
POST /import/github/gists
```

| 属性               | 型   | 必須 | 説明 |
|-------------------------|--------|----------|-------------|
| `personal_access_token` | 文字列 | はい      | GitHubのパーソナルアクセストークン。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/gists" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_gitlab_access_token>" \
  --data '{
    "personal_access_token": "<your_github_personal_access_token>"
}'
```

次のステータスコードを返します:

- `202 Accepted`: ジストのインポートが開始されています。
- `401 Unauthorized`: ユーザー名のGitHubパーソナルアクセストークンが無効です。
- `422 Unprocessable Entity`: ジストのインポートはすでに進行中です。
- `429 Too Many Requests`: ユーザー名がGitHubのレート制限を超過しました。

## Bitbucket Serverからリポジトリをインポート {#import-repository-from-bitbucket-server}

APIを使用して、Bitbucket ServerからGitLabへプロジェクトをインポートします。

Bitbucketプロジェクトキーは、Bitbucketでリポジトリを検索するためだけに使用されます。リポジトリをGitLabグループにインポートする場合は、`target_namespace`を指定する必要があります。`target_namespace`を指定しない場合、プロジェクトは個人のユーザー名のネームスペースにインポートされます。

前提要件: 

- 詳細については、[Bitbucket Serverインポーターの前提条件](../user/project/import/bitbucket_server.md)を参照してください。

```plaintext
POST /import/bitbucket_server
```

| 属性                   | 型   | 必須 | 説明 |
|-----------------------------|--------|----------|-------------|
| `bitbucket_server_project`  | 文字列 | はい      | Bitbucketプロジェクトキー。 |
| `bitbucket_server_repo`     | 文字列 | はい      | Bitbucketリポジトリ名。 |
| `bitbucket_server_url`      | 文字列 | はい      | Bitbucket ServerのURL。 |
| `bitbucket_server_username` | 文字列 | はい      | Bitbucket Serverのユーザー名。 |
| `personal_access_token`     | 文字列 | はい      | Bitbucket Serverのパーソナルアクセストークンまたはパスワード。 |
| `new_name`                  | 文字列 | いいえ       | 新しいプロジェクトの名前。新しいパスとしても使用されるため、特殊文字で始めたり終わったりすることはできず、連続した特殊文字を含めることもできません。GitLab 16.9以前は、プロジェクトパスは代わりにBitbucketから[コピーされました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88845)。GitLab 16.10では、動作が元の動作に[戻されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145793)。 |
| `target_namespace`          | 文字列 | いいえ       | リポジトリのインポート先のネームスペース。`/namespace/subgroup`のようなサブグループをサポートします。 |
| `timeout_strategy`          | 文字列 | いいえ       | インポートのタイムアウトを処理するためのストラテジー。有効な値は、`optimistic`（インポートの次のステージングに進む）または`pessimistic`（すぐに失敗する）です。`pessimistic`がデフォルトです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422979)されました。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket_server" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_server_url": "http://bitbucket.example.com",
    "bitbucket_server_username": "root",
    "personal_access_token": "Nzk4MDcxODY4MDAyOiP8y410zF3tGAyLnHRv/E0+3xYs",
    "bitbucket_server_project": "NEW",
    "bitbucket_server_repo": "my-repo",
    "new_name": "NEW-NAME"
}'
```

## Bitbucket Cloudからリポジトリをインポート {#import-repository-from-bitbucket-cloud}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/215036)されました。

{{< /history >}}

APIを使用して、Bitbucket CloudからGitLabへプロジェクトをインポートします。

前提要件: 

- [Bitbucket Cloudインポーターの前提条件](../user/project/import/bitbucket.md)。
- [Bitbucket Cloudアプリのパスワード](../user/project/import/bitbucket.md#generate-a-bitbucket-cloud-app-password)。

```plaintext
POST /import/bitbucket
```

| 属性                | 型   | 必須 | 説明 |
|:-------------------------|:-------|:---------|:------------|
| `bitbucket_username`     | 文字列 | はい      | Bitbucket Cloudのユーザー名。 |
| `bitbucket_app_password` | 文字列 | はい      | Bitbucket Cloudアプリのパスワード。 |
| `repo_path`              | 文字列 | はい      | リポジトリへのパス。 |
| `target_namespace`       | 文字列 | はい      | リポジトリのインポート先のネームスペース。`/namespace/subgroup`のようなサブグループをサポートします。 |
| `new_name`               | 文字列 | いいえ       | 新しいプロジェクトの名前。新しいパスとしても使用されるため、特殊文字で始めたり終わったりすることはできず、連続した特殊文字を含めることもできません。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_username": "bitbucket_username",
    "bitbucket_app_password": "bitbucket_app_password",
    "repo_path": "username/my_project",
    "target_namespace": "my_group/my_subgroup",
    "new_name": "new_project_name"
}'
```

## 関連トピック {#related-topics}

- [ダイレクト転送APIによるグループ移行](bulk_imports.md)。
- [グループのインポート/エクスポートAPI](group_import_export.md)。
- [プロジェクトのインポート/エクスポートAPI](project_import_export.md)。
