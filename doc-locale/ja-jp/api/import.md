---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: インポートAPI
description: "REST APIを使用して、GitHubまたはBitbucket Serverからリポジトリをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で、パーソナルネームスペースにインポートする際にパーソナルネームスペースオーナーにコントリビュートを再割り当てする機能が`user_mapping_to_personal_namespace_owner`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525342)されました。デフォルトでは無効になっています。
- GitLab 18.6で、パーソナルネームスペースにインポートする際にパーソナルネームスペースオーナーにコントリビュートを再割り当てする機能が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626)になりました。機能フラグ`user_mapping_to_personal_namespace_owner`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

このAPIを使用して、[外部ソースからリポジトリをインポートします](../user/import/_index.md)。

> [!note]
> ユーザーのコントリビュートマッピングは、プロジェクトを[個人ネームスペース](../user/namespace/_index.md#types-of-namespaces)にインポートする場合、サポートされていません。個人ネームスペースにインポートする場合、すべてのコントリビュートは個人ネームスペースのオーナーに割り当てられ、再割り当てすることはできません。

## GitHubからリポジトリをインポートする {#import-repository-from-github}

{{< history >}}

- GitLab 16.0でデベロッパーロールではなくメンテナーロールが必要になる要件が導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされました。
- `collaborators_import`の`optional_stages`のキーは、GitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)。
- 機能フラグ`github_import_extended_events`はGitLab 16.8で導入されました。デフォルトでは無効になっています。このフラグは、インポートのパフォーマンスを向上させますが、`single_endpoint_issue_events_import`オプションのステージを無効にします。
- GitLab 16.9で、機能フラグ`github_import_extended_events`が[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)になりました。
- 改善されたインポートパフォーマンスは、GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)されました。機能フラグ`github_import_extended_events`は削除されました。

{{< /history >}}

GitHubからGitLabにリポジトリをインポートします。

前提条件: 

- [GitHubインポーターの前提条件](../user/project/import/github.md#prerequisites)。
- `target_namespace`で設定されたネームスペースが存在する必要があります。
- そのネームスペースは、ユーザーのネームスペース、またはメンテナーまたはオーナーのロールを持つ既存のグループにすることができます。

```plaintext
POST /import/github
```

| 属性               | 型    | 必須 | 説明 |
|-------------------------|---------|----------|-------------|
| `personal_access_token` | 文字列  | はい      | GitHubパーソナルアクセストークン。 |
| `repo_id`               | 整数 | はい      | GitHubリポジトリID。 |
| `target_namespace`      | 文字列  | はい      | リポジトリのインポート先のネームスペース。`/namespace/subgroup`のようなサブグループをサポートします。空白にしないでください。 |
| `github_hostname`       | 文字列  | いいえ       | カスタムGitHub Enterpriseホスト名。GitHub.comには設定しないでください。GitLab 16.5からGitLab 17.1までは、パス`/api/v3`を含める必要があります。 |
| `new_name`              | 文字列  | いいえ       | 新しいプロジェクトの名前。新しいパスとしても使用されるため、特殊文字で開始または終了したり、連続した特殊文字を含めたりすることはできません。 |
| `optional_stages`       | オブジェクト  | いいえ       | [追加のインポート項目](../user/project/import/github.md#select-additional-items-to-import)。 |
| `pagination_limit`      | 整数 | いいえ       | GitHubへのAPIリクエストごとに取得される項目の数。デフォルト値は、ページあたり100項目です。大規模なリポジトリからのプロジェクトのインポートの場合、数値を小さくすると、GitHub APIエンドポイントが`500`または`502`エラーを返すリスクを軽減できます。ただし、ページサイズを小さくすると、移行時間が長くなります。 |
| `timeout_strategy`      | 文字列  | いいえ       | インポートのタイムアウトを処理するためのストラテジー。有効な値は、`optimistic`（インポートの次のステージに進む）または`pessimistic`（すぐに失敗する）です。`pessimistic`がデフォルトです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422979)されました。 |

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

- `attachments_import`。Markdown添付ファイルをインポートします。
- `collaborators_import`。外部のコラボレーターではない直接のリポジトリのコラボレーターをインポートします。
- `single_endpoint_issue_events_import`。イシューとプルリクエストのイベントをインポートします。このオプションのステージは、GitLab 16.9で削除されました。
- `single_endpoint_notes_import`。別の方法として、より徹底的にコメントをインポートします。

詳細については、[追加の項目をインポートする](../user/project/import/github.md#select-additional-items-to-import)を参照してください。

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

### グループアクセストークンを使用して、API経由でパブリックプロジェクトをインポート {#import-a-public-project-through-the-api-using-a-group-access-token}

グループアクセストークンを使用して、API経由でGitHubからGitLabにプロジェクトをインポートする場合:

- そのGitLabプロジェクトは、元のプロジェクトの表示レベル設定を継承します。その結果、元のプロジェクトがパブリックの場合、そのプロジェクトは公開されます。
- `path`または`target_namespace`が存在しない場合、プロジェクトのインポートは失敗します。

### GitHubプロジェクトのインポートをキャンセル {#cancel-github-project-import}

進行中のGitHubプロジェクトのインポートをキャンセルします。

```plaintext
POST /import/github/cancel
```

| 属性    | 型    | 必須 | 説明 |
|--------------|---------|----------|-------------|
| `project_id` | 整数 | はい      | GitLabプロジェクトID。 |

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

次のステータスコードが返されます:

- `200 OK`: プロジェクトのインポートがキャンセルされています。
- `400 Bad Request`: プロジェクトのインポートをキャンセルできません。
- `404 Not Found`: `project_id`に関連付けられたプロジェクトが存在しません。

### GitHub GistをGitLabスニペットにインポートする {#import-github-gists-into-gitlab-snippets}

個人のGitHub GistをGitLabスニペットにインポートします。最大10個のファイルでGistをインポートできます。10個を超えるファイルを含むGitHub Gistはスキップされます。これらのGitHub Gistは手動で移行する必要があります。

Gistをインポートできなかった場合、インポートされなかったGistのリストが記載されたメールが送信されます。

```plaintext
POST /import/github/gists
```

| 属性               | 型   | 必須 | 説明 |
|-------------------------|--------|----------|-------------|
| `personal_access_token` | 文字列 | はい      | GitHubパーソナルアクセストークン。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/gists" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_gitlab_access_token>" \
  --data '{
    "personal_access_token": "<your_github_personal_access_token>"
}'
```

次のステータスコードが返されます:

- `202 Accepted`: Gistのインポートが開始されています。
- `401 Unauthorized`: ユーザーのGitHubのパーソナルアクセストークンが無効です。
- `422 Unprocessable Entity`: Gistのインポートはすでに進行中です。
- `429 Too Many Requests`: ユーザーがGitHubのレート制限を超えました。

## Bitbucket Serverからリポジトリをインポートする {#import-repository-from-bitbucket-server}

{{< history >}}

- `bitbucket_server_project`と`bitbucket_server_repo`の検証がGitLab 19.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/429234)。

{{< /history >}}

Bitbucket ServerからGitLabにリポジトリをインポートします。

Bitbucketプロジェクトキーは、Bitbucket内のリポジトリを検索するためにのみ使用されます。リポジトリをGitLabグループにインポートする場合は、`target_namespace`を指定する必要があります。`target_namespace`を指定しない場合、プロジェクトは個人のユーザーネームスペースにインポートされます。

前提条件: 

- 詳細については、[Bitbucket Serverインポーターの前提条件](../user/import/bitbucket_server.md)を参照してください。

```plaintext
POST /import/bitbucket_server
```

| 属性                   | 型   | 必須 | 説明 |
|-----------------------------|--------|----------|-------------|
| `bitbucket_server_project`  | 文字列 | はい      | Bitbucketプロジェクトのキー。文字、数字、ハイフン、アンダースコア、ピリオド、または空白文字のみを含める必要があります。個人プロジェクトキーは`~`で始まります。 |
| `bitbucket_server_repo`     | 文字列 | はい      | Bitbucketリポジトリ名。文字、数字、ハイフン、アンダースコア、ピリオド、または空白文字のみを含める必要があります。 |
| `bitbucket_server_url`      | 文字列 | はい      | Bitbucket ServerのURL。 |
| `bitbucket_server_username` | 文字列 | はい      | Bitbucket Serverのユーザー名。 |
| `personal_access_token`     | 文字列 | はい      | Bitbucket Serverのパーソナルアクセストークンまたはパスワード。 |
| `new_name`                  | 文字列 | いいえ       | 新しいプロジェクトの名前。新しいパスとしても使用されるため、特殊文字で開始または終了したり、連続した特殊文字を含めたりすることはできません。GitLab 16.9以前では、プロジェクトのパスは代わりにBitbucketから[コピーされました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88845)。GitLab 16.10では、動作が元の動作に[戻されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145793)。 |
| `target_namespace`          | 文字列 | いいえ       | リポジトリのインポート先のネームスペース。`/namespace/subgroup`のようなサブグループをサポートします。 |
| `timeout_strategy`          | 文字列 | いいえ       | インポートのタイムアウトを処理するためのストラテジー。有効な値は、`optimistic`（インポートの次のステージに進む）または`pessimistic`（すぐに失敗する）です。`pessimistic`がデフォルトです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422979)されました。 |

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

## Bitbucket Cloudからリポジトリをインポートする {#import-repository-from-bitbucket-cloud}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/215036)されました。
- Bitbucket Cloud APIトークンのサポートがGitLab 18.9で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/575583)。
- Bitbucket Cloudアプリパスワードのサポートは、GitLab 19.0で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/588961)。

{{< /history >}}

Bitbucket CloudからGitLabにリポジトリをインポートします。

前提条件: 

- [Bitbucket Cloudインポーターの前提条件](../user/import/bitbucket_cloud.md)。
- 必要なスコープを持つ[Bitbucket Cloud APIトークン](#bitbucket-cloud-api-token-scopes)。

```plaintext
POST /import/bitbucket
```

| 属性             | 型   | 必須 | 説明 |
|:----------------------|:-------|:---------|:------------|
| `bitbucket_api_token` | 文字列 | はい      | Bitbucket Cloud APIトークン。 |
| `bitbucket_email`     | 文字列 | はい      | Bitbucket Cloudのメール。 |
| `repo_path`           | 文字列 | はい      | リポジトリへのパス。 |
| `target_namespace`    | 文字列 | はい      | リポジトリのインポート先のネームスペース。`/namespace/subgroup`のようなサブグループをサポートします。 |
| `new_name`            | 文字列 | いいえ       | 新しいプロジェクトの名前。新しいパスとしても使用されるため、特殊文字で開始または終了したり、連続した特殊文字を含めたりすることはできません。 |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_email": "email@example.com",
    "bitbucket_api_token": "your_bitbucket_api_token",
    "repo_path": "username/my_project",
    "target_namespace": "my_group/my_subgroup",
    "new_name": "new_project_name"
}'
```

### Bitbucket Cloud APIトークンのスコープ {#bitbucket-cloud-api-token-scopes}

認証にBitbucket Cloud APIトークンを使用している場合、そのトークンには次のスコープが必要です:

- `read:repository:bitbucket`
- `read:pullrequest:bitbucket`
- `read:issue:bitbucket`
- `read:wiki:bitbucket`

## 関連トピック {#related-topics}

- [ダイレクト転送APIによるグループの移行](bulk_imports.md)。
- [グループのインポート/エクスポートAPI](group_import_export.md)。
- [プロジェクトのインポート/エクスポートAPI](project_import_export.md)。
