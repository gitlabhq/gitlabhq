---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトリモートミラーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのリポジトリ設定で定義された[プッシュミラー](../user/project/repository/mirror/push.md)は、リモートミラーと呼ばれます。これらのミラーの状態は、リモートミラーAPIでクエリを実行して変更できます。

セキュリティ上の理由から、APIレスポンスの`url`属性から、ユーザー名とパスワードの情報が常に削除されます。

{{< alert type="note" >}}

[プルミラー](../user/project/repository/mirror/pull.md)は、表示と更新に[別のAPIエンドポイント](project_pull_mirroring.md#configure-pull-mirroring-for-a-project)を使用します。

{{< /alert >}}

## プロジェクトのリモートミラーの一覧表示 {#list-a-projects-remote-mirrors}

{{< history >}}

- `host_keys`属性は、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)されました。

{{< /history >}}

プロジェクトのリモートミラーとそのステータスの配列を取得します。

```plaintext
GET /projects/:id/remote_mirrors
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                   | 型    | 説明 |
|-----------------------------|---------|-------------|
| `auth_method`               | 文字列  | ミラーに使用される認証方法。 |
| `enabled`                   | ブール値 | `true`の場合、ミラーが有効になります。 |
| `host_keys`                 | 配列   | リモートミラーのSSHホストキーフィンガープリントの配列。 |
| `id`                        | 整数 | リモートミラーのID。 |
| `keep_divergent_refs`       | ブール値 | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `last_error`                | 文字列  | 前回のミラー試行からのエラーメッセージ。`null`の場合は成功。 |
| `last_successful_update_at` | 文字列  | 最後に成功したミラー更新のタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーリングされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。使用可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーのURL。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

レスポンス例:

```json
[
  {
    "enabled": true,
    "id": 101486,
    "auth_method": "ssh_public_key",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
  }
]
```

## 単一プロジェクトのリモートミラーを取得 {#get-a-single-projects-remote-mirror}

{{< history >}}

- `host_keys`属性は、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)されました。

{{< /history >}}

プロジェクトの単一のリモートミラーとそのステータスを取得します。

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id
```

サポートされている属性は以下のとおりです:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id` | 整数           | はい      | リモートミラーのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                   | 型    | 説明 |
|-----------------------------|---------|-------------|
| `enabled`                   | ブール値 | `true`の場合、ミラーが有効になります。 |
| `id`                        | 整数 | リモートミラーのID。 |
| `host_keys`                 | 配列   | リモートミラーのSSHホストキーフィンガープリントの配列。 |
| `keep_divergent_refs`       | ブール値 | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `last_error`                | 文字列  | 前回のミラー試行からのエラーメッセージ。`null`の場合は成功。 |
| `last_successful_update_at` | 文字列  | 最後に成功したミラー更新のタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーリングされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。使用可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーのURL。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

レスポンス例:

```json
{
  "enabled": true,
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "only_protected_branches": true,
  "keep_divergent_refs": true,
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "host_keys": [
    {
      "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
    }
  ]
}
```

## 単一プロジェクトのリモートミラー公開キーを取得 {#get-a-single-projects-remote-mirror-public-key}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180291)されました。

{{< /history >}}

SSH認証を使用するリモートミラーの公開キーを取得します。

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id/public_key
```

サポートされている属性は以下のとおりです:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id` | 整数           | はい      | リモートミラーのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性   | 型   | 説明                        |
|-------------|--------|------------------------------------|
| `public_key`| 文字列 | リモートミラーの公開キー。  |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/public_key"
```

レスポンス例:

```json
{
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EA..."
}
```

## プルミラーを作成 {#create-a-pull-mirror}

プロジェクトプルミラーリングAPIを使用して[プルミラーを設定する方法](project_pull_mirroring.md#configure-pull-mirroring-for-a-project)を説明します。

## プッシュミラーを作成 {#create-a-push-mirror}

{{< history >}}

- GitLab 16.0では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/381667)。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/410354)になりました。機能フラグ`mirror_only_branches_match_regex`は削除されました。
- `auth_method`は、GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155)されました。
- `host_keys`属性は、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)されました。

{{< /history >}}

プロジェクトのプッシュミラーを作成します。プッシュミラーリングはデフォルトで無効になっています。有効にするには、ミラーの作成時にオプションのパラメータ`enabled`を含めます。

```plaintext
POST /projects/:id/remote_mirrors
```

サポートされている属性は以下のとおりです:

| 属性                 | 型              | 必須 | 説明 |
|---------------------------|-------------------|----------|-------------|
| `id`                      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `url`                     | 文字列            | はい      | リポジトリがミラーリングされるターゲットURL。 |
| `auth_method`             | 文字列            | いいえ       | ミラーの認証方法: 指定できる値: `ssh_public_key`、`password`。 |
| `enabled`                 | ブール値           | いいえ       | `true`の場合、ミラーが有効になります。 |
| `keep_divergent_refs`     | ブール値           | いいえ       | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `mirror_branch_regex`     | 文字列            | いいえ       | ミラーするブランチ名の正規表現。正規表現に一致する名前のブランチのみがミラーリングされます。`only_protected_branches`を無効にする必要があります。PremiumおよびUltimateのみです。 |
| `only_protected_branches` | ブール値           | いいえ       | `true`の場合、保護ブランチのみがミラーリングされます。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                   | 型    | 説明 |
|-----------------------------|---------|-------------|
| `auth_method`               | 文字列  | ミラーに使用される認証方法。 |
| `enabled`                   | ブール値 | `true`の場合、ミラーが有効になります。 |
| `host_keys`                 | 配列   | リモートミラーのSSHホストキーフィンガープリントの配列。 |
| `id`                        | 整数 | リモートミラーのID。 |
| `keep_divergent_refs`       | ブール値 | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `last_error`                | 文字列  | 前回のミラー試行からのエラーメッセージ。`null`の場合は成功。 |
| `last_successful_update_at` | 文字列  | 最後に成功したミラー更新のタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーリングされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。使用可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーのURL。 |

リクエスト例:

```shell
curl --request POST \
  --data "url=https://username:token@example.com/gitlab/example.git" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

レスポンス例:

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": null,
    "last_update_at": null,
    "last_update_started_at": null,
    "only_protected_branches": false,
    "keep_divergent_refs": false,
    "update_status": "none",
    "url": "https://*****:*****@example.com/gitlab/example.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## リモートミラーの属性を更新 {#update-a-remote-mirrors-attributes}

{{< history >}}

- `auth_method`は、GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155)されました。
- `host_keys`属性は、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)されました。

{{< /history >}}

リモートミラーの設定を更新します。リモートミラーの切替をオンまたはオフにするか、ミラーリングされるブランチのタイプを変更します。

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

サポートされている属性は以下のとおりです:

| 属性                 | 型              | 必須 | 説明 |
|---------------------------|-------------------|----------|-------------|
| `id`                      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id`               | 整数           | はい      | リモートミラーのID。 |
| `auth_method`             | 文字列            | いいえ       | ミラーの認証方法: 指定できる値: `ssh_public_key`、`password`。 |
| `enabled`                 | ブール値           | いいえ       | `true`の場合、ミラーが有効になります。 |
| `keep_divergent_refs`     | ブール値           | いいえ       | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `mirror_branch_regex`     | 文字列            | いいえ       | ミラーするブランチ名の正規表現。正規表現に一致する名前のブランチのみがミラーリングされます。`only_protected_branches`が有効になっている場合は機能しません。PremiumおよびUltimateのみです。 |
| `only_protected_branches` | ブール値           | いいえ       | `true`の場合、保護ブランチのみがミラーリングされます。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                   | 型    | 説明 |
|-----------------------------|---------|-------------|
| `auth_method`               | 文字列  | ミラーに使用される認証方法。 |
| `enabled`                   | ブール値 | `true`の場合、ミラーが有効になります。 |
| `host_keys`                 | 配列   | リモートミラーのSSHホストキーフィンガープリントの配列。 |
| `id`                        | 整数 | リモートミラーのID。 |
| `keep_divergent_refs`       | ブール値 | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `last_error`                | 文字列  | 前回のミラー試行からのエラーメッセージ。`null`の場合は成功。 |
| `last_successful_update_at` | 文字列  | 最後に成功したミラー更新のタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーリングされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。使用可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーのURL。 |

リクエスト例:

```shell
curl --request PUT \
  --data "enabled=false" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

レスポンス例:

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## 強制プッシュミラー更新 {#force-push-mirror-update}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388907)されました。

{{< /history >}}

プッシュミラーへの[更新を強制する](../user/project/repository/mirror/_index.md#force-an-update)。

```plaintext
POST /projects/:id/remote_mirrors/:mirror_id/sync
```

サポートされている属性は以下のとおりです:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id` | 整数           | はい      | リモートミラーのID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/sync"
```

## リモートミラーを削除 {#delete-a-remote-mirror}

リモートミラーを削除します。

```plaintext
DELETE /projects/:id/remote_mirrors/:mirror_id
```

サポートされている属性は以下のとおりです:

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id` | 整数           | はい      | リモートミラーのID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```
