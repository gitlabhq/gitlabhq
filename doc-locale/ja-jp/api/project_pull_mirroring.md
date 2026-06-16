---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プルミラーリングAPI
description: プロジェクトのプルミラーリングを管理します。ミラーの詳細表示、ミラーリングの設定、ミラーの更新を開始します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトの[プルミラーリング](../user/project/repository/mirror/pull.md)を管理します。

## プロジェクトのプルミラーの詳細を取得します {#retrieve-project-pull-mirror-details}

{{< history >}}

- GitLab 17.5では、ミラー設定情報を含む[拡張されたレスポンス](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168377)が追加されました。以下の設定設定が含まれます: `enabled`、`mirror_trigger_builds`、`only_mirror_protected_branches`、`mirror_overwrites_diverged_branches`、および`mirror_branch_regex`。

{{< /history >}}

指定されたプロジェクトのプルミラーの詳細を取得します。

```plaintext
GET /projects/:id/mirror/pull
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                             | 型            | 説明 |
|---------------------------------------|-----------------|-------------|
| `enabled`                             | ブール値         | `true`の場合、ミラーがアクティブになります。 |
| `id`                                  | 整数         | ミラー設定の一意の識別子。 |
| `last_error`                          | 文字列またはnull  | 発生した最新のエラーメッセージ（もしあれば）。エラーが発生しなかった場合は`null`。 |
| `last_successful_update_at`           | 文字列          | 最後のミラー更新が正常に完了したタイムスタンプ。 |
| `last_update_at`                      | 文字列          | 最新のミラー更新試行のタイムスタンプ。 |
| `last_update_started_at`              | 文字列          | 最後のミラー更新プロセスが開始されたタイムスタンプ。 |
| `mirror_branch_regex`                 | 文字列またはnull  | どのブランチをミラーするかをフィルタリングするための正規表現パターン。`null`が未設定の場合。 |
| `mirror_overwrites_diverged_branches` | ブール値         | `true`の場合、ミラーリング中に分岐したブランチを上書きします。 |
| `mirror_trigger_builds`               | ブール値         | `true`の場合、ミラー更新のビルドをトリガーします。 |
| `only_mirror_protected_branches`      | ブール値またはnull | `true`の場合、保護ブランチのみがミラーされます。設定されていない場合、値は`null`です。 |
| `update_status`                       | 文字列          | ミラー更新プロセスのステータス。使用可能な値: `none`、`scheduled`、`started`、`finished`、`failed`、または`canceled`。 |
| `url`                                 | 文字列          | ミラーされたリポジトリのURL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

レスポンス例: 

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "enabled": true,
  "mirror_trigger_builds": true,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## プロジェクトのプルミラーリング設定の更新 {#update-project-pull-mirroring-settings}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/494294)されました。

{{< /history >}}

プロジェクトのプルミラーリング設定を更新します。

```plaintext
PUT /projects/:id/mirror/pull
```

サポートされている属性は以下のとおりです: 

| 属性                             | 型              | 必須 | 説明 |
|:--------------------------------------|:------------------|:---------|:------------|
| `id`                                  | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `auth_password`                       | 文字列            | いいえ       | プルミラーするプロジェクトの認証に使用されるパスワード。 |
| `auth_user`                           | 文字列            | いいえ       | プルミラーするプロジェクトの認証に使用されるユーザー名。 |
| `enabled`                             | ブール値           | いいえ       | `true`の場合、`true`に設定すると、プロジェクトでプルミラーリングが有効になります。 |
| `mirror_branch_regex`                 | 文字列            | いいえ       | 正規表現を含みます。正規表現に一致する名前のブランチのみがミラーされます。`only_mirror_protected_branches`を無効にする必要があります。 |
| `mirror_overwrites_diverged_branches` | ブール値           | いいえ       | `true`の場合、分岐したブランチを上書きします。 |
| `mirror_trigger_builds`               | ブール値           | いいえ       | `true`の場合、ミラー更新のパイプラインをトリガーします。 |
| `only_mirror_protected_branches`      | ブール値           | いいえ       | `true`の場合、保護ブランチのみにミラーリングを制限します。 |
| `url`                                 | 文字列            | いいえ       | ミラーされるリモートリポジトリのURL。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と更新されたプルミラー設定を返します。

プルミラーリングを追加するリクエストの例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "enabled": true,
    "url": "https://gitlab.example.com/group/project.git",
    "auth_user": "user",
    "auth_password": "password"
  }' \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

プルミラーリングを削除するリクエストの例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

レスポンス例: 

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://gitlab.example.com/group/project.git",
  "enabled": true,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## プロジェクトのプルミラーリングを更新する（非推奨） {#update-pull-mirroring-for-a-project-deprecated}

{{< history >}}

- 機能フラグ`mirror_only_branches_match_regex`はGitLab 16.0で[デフォルト](https://gitlab.com/gitlab-org/gitlab/-/issues/381667)で有効になりました。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/410354)になりました。機能フラグ`mirror_only_branches_match_regex`は削除されました。
- GitLab 17.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/494294)になりました。

{{< /history >}}

> [!warning]
> この設定オプションはGitLab 17.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/494294)になり、APIのv5で削除が予定されています。代わりに[新しい設定とエンドポイント](project_pull_mirroring.md#update-project-pull-mirroring-settings)を使用してください。これは破壊的な変更です。

リモートリポジトリが公開されているか、`username:token`認証を使用している場合、プロジェクトの[作成](projects.md#create-a-project)または[更新](projects.md#update-a-project)時にAPIを使用してプルミラーリングを設定します。

HTTPリポジトリが公開されていない場合、認証情報をURLに追加できます。例えば、`https://username:token@gitlab.company.com/group/project.git`（ここで`token`は`api`スコープが有効になっている[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)です）。

サポートされている属性は以下のとおりです: 

| 属性                        | 型    | 必須 | 説明 |
|:---------------------------------|:--------|:---------|:------------|
| `import_url`                     | 文字列  | はい      | ミラーされるリモートリポジトリのURL（必要に応じて`user:token`を使用）。 |
| `mirror`                         | ブール値 | はい      | `true`の場合、プルミラーリングを有効にします。 |
| `mirror_branch_regex`            | 文字列  | いいえ       | 正規表現を含みます。正規表現に一致する名前のブランチのみがミラーされます。`only_mirror_protected_branches`を無効にする必要があります。 |
| `mirror_trigger_builds`          | ブール値 | いいえ       | `true`の場合、ミラー更新のパイプラインをトリガーします。 |
| `only_mirror_protected_branches` | ブール値 | いいえ       | `true`の場合、保護ブランチのみにミラーリングを制限します。 |

プルミラーリングを使用してプロジェクトを作成する例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "new_project",
    "namespace_id": "1",
    "mirror": true,
    "import_url": "https://username:token@gitlab.example.com/group/project.git"
  }' \
  --url "https://gitlab.example.com/api/v4/projects/"
```

プルミラーリングを追加する例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

プルミラーリングを削除する例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

## プロジェクトのプルミラーリングプロセスを開始します {#start-the-pull-mirroring-process-for-a-project}

プロジェクトのプルミラーリングプロセスを開始します。

```plaintext
POST /projects/:id/mirror/pull
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`202 Accepted`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```
