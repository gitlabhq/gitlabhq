---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabのパッケージ保護ルール用REST APIに関するドキュメント。
title: 保護されたパッケージAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`packages_protected_packages`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151741)されました。デフォルトでは無効になっています。
- GitLab.comで[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)になりました。GitLab 17.5。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)になりました。機能フラグ`packages_protected_packages`は削除されました。
- [追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180063): GitLab 17.11で`minimum_access_level_for_delete`属性が`packages_protected_packages_delete`という名前の[機能フラグ](../administration/feature_flags/_index.md)とともに。デフォルトでは無効になっています。

{{< /history >}}

このAPIを使用して、[パッケージの保護ルール](../user/packages/package_registry/package_protection_rules.md)を管理します。

## すべてのパッケージ保護ルールを一覧表示 {#list-all-package-protection-rules}

指定したプロジェクトのすべてのパッケージ保護ルールを一覧表示します。

```plaintext
GET /api/v4/projects/:id/packages/protection/rules
```

サポートされている属性は以下のとおりです: 

| 属性                     | 型            | 必須 | 説明                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)とパッケージ保護ルールの一覧を返します。

次のステータスコードを返すことができます。

- `200 OK`: パッケージ保護ルールの一覧。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、このプロジェクトのパッケージ保護ルールを一覧表示する権限がありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules"
```

レスポンス例: 

```json
[
 {
  "id": 1,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-0",
  "package_type": "npm",
  "minimum_access_level_for_delete": "owner",
  "minimum_access_level_for_push": "maintainer"
 },
 {
  "id": 2,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-1",
  "package_type": "npm",
  "minimum_access_level_for_delete": "owner",
  "minimum_access_level_for_push": "maintainer"
 }
]
```

## パッケージ保護ルールを作成する {#create-a-package-protection-rule}

指定したプロジェクトのパッケージ保護ルールを作成します。

```plaintext
POST /api/v4/projects/:id/packages/protection/rules
```

サポートされている属性は以下のとおりです: 

| 属性                             | 型            | 必須 | 説明                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `package_name_pattern`                | 文字列          | はい      | 保護ルールによって保護されるパッケージ名。例: `@my-scope/my-package-*`。ワイルドカード文字`*`を使用できます。 |
| `package_type`                        | 文字列          | はい      | 保護ルールによって保護されるパッケージのタイプ。例: `npm`。 |
| `minimum_access_level_for_delete`     | 文字列          | はい      | パッケージを削除するために必要な最小GitLabアクセスレベル。有効な値は`null`、`owner`または`admin`です。値が`null`の場合のデフォルトの最小アクセスレベルは`maintainer`です。`minimum_access_level_for_push`が設定されていない場合は、指定する必要があります。`packages_protected_packages_delete`という名前の機能フラグの背後。デフォルトでは無効になっています。 |
| `minimum_access_level_for_push`       | 文字列          | はい      | パッケージをプッシュするために必要な最小GitLabアクセスレベル。有効な値は`null`、`maintainer`、`owner`または`admin`です。値が`null`の場合のデフォルトの最小アクセスレベルは`developer`です。`minimum_access_level_for_delete`が設定されていない場合は、指定する必要があります。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と作成されたパッケージ保護ルールを返します。

次のステータスコードを返すことができます。

- `201 Created`: パッケージ保護ルールが正常に作成されました。
- `400 Bad Request`: パッケージ保護ルールが無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、パッケージ保護ルールを作成する権限がありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。
- `422 Unprocessable Entity`: パッケージ保護ルールを作成できませんでした。たとえば、`package_name_pattern`がすでに使用されているためです。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules" \
  --data '{
       "package_name_pattern": "package-name-pattern-*",
       "package_type": "npm",
       "minimum_access_level_for_delete": "owner",
       "minimum_access_level_for_push": "maintainer"
    }'
```

## パッケージ保護ルールを更新する {#update-a-package-protection-rule}

指定したプロジェクトのパッケージ保護ルールを更新します。

```plaintext
PATCH /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

サポートされている属性は以下のとおりです: 

| 属性                             | 型            | 必須 | 説明                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `package_protection_rule_id`          | 整数         | はい      | 更新するパッケージ保護ルールのID。 |
| `package_name_pattern`                | 文字列          | いいえ       | 保護ルールによって保護されるパッケージ名。例: `@my-scope/my-package-*`。ワイルドカード文字`*`を使用できます。 |
| `package_type`                        | 文字列          | いいえ       | 保護ルールによって保護されるパッケージのタイプ。例: `npm`。 |
| `minimum_access_level_for_delete`     | 文字列          | いいえ       | パッケージを削除するために必要な最小GitLabアクセスレベル。有効な値は`null`、`owner`または`admin`です。値が`null`の場合のデフォルトの最小アクセスレベルは`maintainer`です。`minimum_access_level_for_push`が設定されていない場合は、指定する必要があります。`packages_protected_packages_delete`という名前の機能フラグの背後。デフォルトでは無効になっています。 |
| `minimum_access_level_for_push`       | 文字列          | いいえ       | パッケージをプッシュするために必要な最小GitLabアクセスレベル。有効な値は`null`、`maintainer`、`owner`または`admin`です。値が`null`の場合のデフォルトの最小アクセスレベルは`developer`です。`minimum_access_level_for_delete`が設定されていない場合は、指定する必要があります。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と更新されたパッケージ保護ルールを返します。

次のステータスコードを返すことができます。

- `200 OK`: パッケージ保護ルールが正常にパッチされました。
- `400 Bad Request`: パッチが無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、パッケージ保護ルールをパッチする権限がありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。
- `422 Unprocessable Entity`: パッケージ保護ルールをパッチできませんでした。たとえば、`package_name_pattern`がすでに使用されているためです。

リクエスト例: 

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32" \
  --data '{
       "package_name_pattern": "new-package-name-pattern-*"
    }'
```

## パッケージ保護ルールを削除する {#delete-a-package-protection-rule}

指定したプロジェクトからパッケージ保護ルールを削除します。

```plaintext
DELETE /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

サポートされている属性は以下のとおりです: 

| 属性                     | 型            | 必須 | 説明                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `package_protection_rule_id`  | 整数         | はい      | 削除するパッケージ保護ルールのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

次のステータスコードを返すことができます。

- `204 No Content`: パッケージ保護ルールが正常に削除されました。
- `400 Bad Request`: `id`または`package_protection_rule_id`が見つからないか、無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、パッケージ保護ルールを削除する権限がありません。
- `404 Not Found`: プロジェクトまたはパッケージ保護ルールが見つかりませんでした。

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32"
```
