---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのコンテナリポジトリ保護ルールに関するREST APIのドキュメント。
title: コンテナリポジトリ保護ルールAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.2で`container_registry_protected_containers`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155798)されました。デフォルトでは無効になっています。
- GitLab 17.8の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/429074)で有効になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)になりました。機能フラグ`container_registry_protected_containers`は削除されました。

{{< /history >}}

このAPIを使用して、[container repository protection rules](../user/packages/container_registry/protected_container_tags.md)を管理します。

## コンテナリポジトリ保護ルールの一覧 {#list-container-repository-protection-rules}

プロジェクトのコンテナリポジトリからコンテナリポジトリ保護ルールの一覧を取得します。

```plaintext
GET /api/v4/projects/:id/registry/protection/repository/rules
```

サポートされている属性は以下のとおりです:

| 属性                     | 型            | 必須 | 説明                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)とコンテナリポジトリ保護ルールの一覧を返します。

次のステータスコードを返すことができます:

- `200 OK`: 保護ルールの一覧。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: このプロジェクトの保護ルールを一覧表示する権限がユーザーにありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight0",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight1",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
]
```

## コンテナリポジトリ保護ルールを作成する {#create-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/457518)。

{{< /history >}}

プロジェクトのコンテナリポジトリのコンテナリポジトリ保護ルールを作成します。

```plaintext
POST /api/v4/projects/:id/registry/protection/repository/rules
```

サポートされている属性は以下のとおりです:

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_path_pattern`         | 文字列         | はい      | 保護ルールによって保護されるコンテナリポジトリパスパターン。例: `flight/flight-*`。ワイルドカード文字`*`を使用できます。 |
| `minimum_access_level_for_delete` | 文字列         | いいえ       | コンテナリポジトリ内のコンテナイメージを削除するために必要な最小GitLabアクセスレベル。例: `maintainer`、`owner`、`admin`。`minimum_access_level_for_push`が設定されていない場合は、指定する必要があります。 |
| `minimum_access_level_for_push`   | 文字列         | いいえ       | コンテナイメージをコンテナリポジトリにプッシュするために必要な最小GitLabアクセスレベル。例: `maintainer`、`owner`、`admin`。`minimum_access_level_for_delete`が設定されていない場合は、指定する必要があります。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と、作成されたコンテナリポジトリ保護ルールを返します。

次のステータスコードを返すことができます:

- `201 Created`: 保護ルールが正常に作成されました。
- `400 Bad Request`: 保護ルールが無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: 保護ルールを作成する権限がユーザーにありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。
- `422 Unprocessable Entity`: 保護ルールを作成できませんでした。たとえば、`repository_path_pattern`がすでに使用されているためです。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules" \
  --data '{
        "repository_path_pattern": "flightjs/flight-needs-to-be-a-unique-path",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

## コンテナリポジトリ保護ルールを更新する {#update-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/457518)。

{{< /history >}}

プロジェクトのコンテナリポジトリのコンテナリポジトリ保護ルールを更新します。

```plaintext
PATCH /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

サポートされている属性は以下のとおりです:

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `protection_rule_id`              | 整数        | はい      | 更新する保護ルールのID。 |
| `minimum_access_level_for_delete` | 文字列         | いいえ       | コンテナリポジトリ内のコンテナイメージを削除するために必要な最小GitLabアクセスレベル。例: `maintainer`、`owner`、`admin`。`minimum_access_level_for_push`が設定されていない場合は、指定する必要があります。値を設定解除するには、空の文字列`""`を使用します。 |
| `minimum_access_level_for_push`   | 文字列         | いいえ       | コンテナイメージをコンテナリポジトリにプッシュするために必要な最小GitLabアクセスレベル。例: `maintainer`、`owner`、`admin`。`minimum_access_level_for_delete`が設定されていない場合は、指定する必要があります。値を設定解除するには、空の文字列`""`を使用します。 |
| `repository_path_pattern`         | 文字列         | いいえ       | 保護ルールによって保護されるコンテナリポジトリパスパターン。例: `flight/flight-*`。ワイルドカード文字`*`を使用できます。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と、更新された保護ルールを返します。

次のステータスコードを返すことができます:

- `200 OK`: 保護ルールが正常に更新されました。
- `400 Bad Request`: 保護ルールが無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: 保護ルールを更新する権限がユーザーにありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。
- `422 Unprocessable Entity`: 保護ルールを更新できませんでした。たとえば、`repository_path_pattern`がすでに使用されているためです。

リクエスト例:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/32" \
  --data '{
       "repository_path_pattern": "flight/flight-*"
    }'
```

## コンテナリポジトリ保護ルールを削除する {#delete-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/457518)されました。

{{< /history >}}

プロジェクトのコンテナリポジトリからコンテナリポジトリ保護ルールを削除します。

```plaintext
DELETE /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

サポートされている属性は以下のとおりです:

| 属性            | 型           | 必須 | 説明 |
|----------------------|----------------|----------|-------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `protection_rule_id` | 整数        | はい      | 削除するコンテナリポジトリ保護ルールのID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

次のステータスコードを返すことができます:

- `204 No Content`: 保護ルールは正常に削除されました。
- `400 Bad Request`: `id`または`protection_rule_id`がないか、無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: 保護ルールを削除する権限がユーザーにありません。
- `404 Not Found`: プロジェクトまたは保護ルールが見つかりませんでした。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/1"
```
