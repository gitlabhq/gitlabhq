---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトリモートミラーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[リモートミラー](../user/project/repository/mirror/push.md)を管理できます。このリモートミラーAPIを使用して、これらのミラーの状態をクエリおよび変更できます。

セキュリティ上の理由から、API応答の`url`属性からは、ユーザー名とパスワード情報が常に削除されます。

> [!note]
> [プルミラー](../user/project/repository/mirror/pull.md)は、表示および更新のために[別のAPIエンドポイント](project_pull_mirroring.md#update-project-pull-mirroring-settings)を使用します。

## プロジェクトのすべてのリモートミラーを一覧表示 {#list-all-remote-mirrors-for-a-project}

{{< history >}}

- 属性`host_keys`がGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)。

{{< /history >}}

指定されたプロジェクトのすべてのリモートミラーを一覧表示します。

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
| `last_error`                | 文字列  | 最後のミラー試行からのエラーメッセージ。`null`の場合、成功。 |
| `last_successful_update_at` | 文字列  | 最後のミラー更新が正常に完了したタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。指定可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーURL。 |

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

## プロジェクトのリモートミラーを取得 {#retrieve-a-remote-mirror-for-a-project}

{{< history >}}

- 属性`host_keys`がGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)。

{{< /history >}}

指定されたプロジェクトのリモートミラーを取得します。

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
| `last_error`                | 文字列  | 最後のミラー試行からのエラーメッセージ。`null`の場合、成功。 |
| `last_successful_update_at` | 文字列  | 最後のミラー更新が正常に完了したタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。指定可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーURL。 |

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

## リモートミラーの公開キーを取得 {#retrieve-a-public-key-for-a-remote-mirror}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180291)されました。

{{< /history >}}

SSH認証を使用する、指定されたリモートミラーの公開キーを取得します。

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

プロジェクトのプルミラーリングAPIを使用して、[プルミラーを設定する](project_pull_mirroring.md#update-project-pull-mirroring-settings)方法を学習してください。

## プッシュミラーを作成 {#create-a-push-mirror}

{{< history >}}

- GitLab 16.0では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/381667)。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/410354)になりました。機能フラグ`mirror_only_branches_match_regex`は削除されました。
- フィールド`auth_method`がGitLab 16.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155)。
- 属性`host_keys`がGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)。

{{< /history >}}

> [!note]
> 各プロジェクトには、最大10個の有効なプッシュミラーを設定できます。詳細については、[プロジェクトプッシュミラーの最大数](../administration/instance_limits.md#maximum-number-of-project-push-mirrors)を参照してください。

プロジェクトのプッシュミラーを作成します。プッシュミラーリングはデフォルトで無効になっています。有効にするには、ミラーの作成時にオプションパラメータ`enabled`を含めます。

```plaintext
POST /projects/:id/remote_mirrors
```

サポートされている属性は以下のとおりです: 

| 属性                 | 型              | 必須 | 説明 |
|---------------------------|-------------------|----------|-------------|
| `id`                      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `url`                     | 文字列            | はい      | リポジトリがミラーリングされるターゲットURL。 |
| `auth_method`             | 文字列            | いいえ       | ミラー認証方法。指定可能な値: `ssh_public_key`、`password`。 |
| `enabled`                 | ブール値           | いいえ       | `true`の場合、ミラーが有効になります。 |
| `host_keys`               | 文字列の配列  | いいえ       | ベア形式(`ssh-ed25519 AAAA...`)または完全な`known_hosts`形式(`hostname ssh-ed25519 AAAA...`)のSSHホストキー。ベアキーは、ミラーURLからホスト名を使用します。 |
| `keep_divergent_refs`     | ブール値           | いいえ       | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `mirror_branch_regex`     | 文字列            | いいえ       | ブランチ名をミラーするための正規表現。正規表現に一致する名前のブランチのみがミラーされます。`only_protected_branches`を無効にする必要があります。PremiumおよびUltimateのみです。 |
| `only_protected_branches` | ブール値           | いいえ       | `true`の場合、保護ブランチのみがミラーされます。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                   | 型    | 説明 |
|-----------------------------|---------|-------------|
| `auth_method`               | 文字列  | ミラーに使用される認証方法。 |
| `enabled`                   | ブール値 | `true`の場合、ミラーが有効になります。 |
| `host_keys`                 | 配列   | リモートミラーのSSHホストキーフィンガープリントの配列。 |
| `id`                        | 整数 | リモートミラーのID。 |
| `keep_divergent_refs`       | ブール値 | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `last_error`                | 文字列  | 最後のミラー試行からのエラーメッセージ。`null`の場合、成功。 |
| `last_successful_update_at` | 文字列  | 最後のミラー更新が正常に完了したタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。指定可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーURL。 |

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

## プロジェクト内のリモートミラーを更新 {#update-a-remote-mirror-in-a-project}

{{< history >}}

- フィールド`auth_method`がGitLab 16.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155)。
- 属性`host_keys`がGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435)。

{{< /history >}}

指定されたリモートミラーの設定または稼働状況を更新します。

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

サポートされている属性は以下のとおりです: 

| 属性                 | 型              | 必須 | 説明 |
|---------------------------|-------------------|----------|-------------|
| `id`                      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id`               | 整数           | はい      | リモートミラーのID。 |
| `auth_method`             | 文字列            | いいえ       | ミラー認証方法。指定可能な値: `ssh_public_key`、`password`。 |
| `enabled`                 | ブール値           | いいえ       | `true`の場合、ミラーが有効になります。 |
| `host_keys`               | 文字列の配列  | いいえ       | ベア形式(`ssh-ed25519 AAAA...`)または完全な`known_hosts`形式(`hostname ssh-ed25519 AAAA...`)のSSHホストキー。ベアキーは、ミラーURLからホスト名を使用します。 |
| `keep_divergent_refs`     | ブール値           | いいえ       | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `mirror_branch_regex`     | 文字列            | いいえ       | ブランチ名をミラーするための正規表現。正規表現に一致する名前のブランチのみがミラーされます。`only_protected_branches`が有効な場合は動作しません。PremiumおよびUltimateのみです。 |
| `only_protected_branches` | ブール値           | いいえ       | `true`の場合、保護ブランチのみがミラーされます。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                   | 型    | 説明 |
|-----------------------------|---------|-------------|
| `auth_method`               | 文字列  | ミラーに使用される認証方法。 |
| `enabled`                   | ブール値 | `true`の場合、ミラーが有効になります。 |
| `host_keys`                 | 配列   | リモートミラーのSSHホストキーフィンガープリントの配列。 |
| `id`                        | 整数 | リモートミラーのID。 |
| `keep_divergent_refs`       | ブール値 | `true`の場合、ミラーリング時に分岐したrefsが保持されます。 |
| `last_error`                | 文字列  | 最後のミラー試行からのエラーメッセージ。`null`の場合、成功。 |
| `last_successful_update_at` | 文字列  | 最後のミラー更新が正常に完了したタイムスタンプ。ISO 8601形式。 |
| `last_update_at`            | 文字列  | 最後のミラー試行のタイムスタンプ。ISO 8601形式。 |
| `last_update_started_at`    | 文字列  | 最後のミラー試行が開始されたときのタイムスタンプ。ISO 8601形式。 |
| `only_protected_branches`   | ブール値 | `true`の場合、保護ブランチのみがミラーされます。 |
| `update_status`             | 文字列  | ミラー更新のステータス。指定可能な値: `none`、`scheduled`、`started`、`finished`、`failed`。 |
| `url`                       | 文字列  | セキュリティのために認証情報が削除されたミラーURL。 |

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

## プッシュミラーの強制プッシュ更新 {#force-push-mirror-update}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388907)されました。

{{< /history >}}

プッシュミラーへの[更新を強制します](../user/project/repository/mirror/_index.md#force-an-update)。

```plaintext
POST /projects/:id/remote_mirrors/:mirror_id/sync
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id` | 整数           | はい      | リモートミラーのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/sync"
```

## プロジェクトからリモートミラーを削除 {#delete-a-remote-mirror-from-a-project}

指定されたプロジェクトからリモートミラーを削除します。

```plaintext
DELETE /projects/:id/remote_mirrors/:mirror_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `mirror_id` | 整数           | はい      | リモートミラーのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```
