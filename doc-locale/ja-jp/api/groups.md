---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabグループを表示および管理します。詳細については、[グループ](../user/group/_index.md)を参照してください。

エンドポイントの応答は、グループ内の[権限](../user/permissions.md)によって異なる場合があります。

## 単一のグループを取得する {#get-a-single-group}

1つのグループのすべての詳細を取得します。グループが公開されている場合、このエンドポイントには認証なしでアクセスできます。グループが公開されている場合、リクエストするユーザーが管理者であれば認証なしでアクセスできます。認証を使用すると、ユーザーが管理者であるか、オーナーのロールを持っている場合、グループの`runners_token`と`enabled_git_access_protocol`も返されます。

```plaintext
GET /groups/:id
```

パラメータは以下のとおりです。

| 属性                | 型           | 必須 | 説明 |
|--------------------------|----------------|----------|-------------|
| `id`                     | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `with_custom_attributes` | ブール値        | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |
| `with_projects`          | ブール値        | いいえ       | 指定されたグループに属するプロジェクトの詳細を含めます（デフォルトは`true`）。（非推奨。[v5で削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/213797)です。グループ内のすべてのプロジェクトの詳細を取得するには、[グループのプロジェクトをリストする](#list-projects)を使用します）。 |

{{< alert type="note" >}}

レスポンス内の`projects`属性と`shared_projects`属性は非推奨であり、[v5で削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/213797)です。グループ内のすべてのプロジェクトの詳細を取得するには、[グループのプロジェクトをリスト](#list-projects)または[グループの共有プロジェクトをリスト](#list-shared-projects)を使用します。

{{< /alert >}}

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4"
```

このエンドポイントは、最大100個のプロジェクトと共有プロジェクトを返します。グループ内のすべてのプロジェクトの詳細を取得するには、代わりに[グループのプロジェクトをリスト](#list-projects)を使用します。

レスポンス例:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "runners_token": "ba324ca7b1c77fc20bb9",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "shared_with_groups": [
    {
      "group_id": 28,
      "group_name": "H5bp",
      "group_full_path": "h5bp",
      "group_access_level": 20,
      "expires_at": null
    }
  ],
  "prevent_sharing_groups_outside_hierarchy": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 7,
      "description": "Voluptas veniam qui et beatae voluptas doloremque explicabo facilis.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "public",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/typeahead-js.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/typeahead-js.git",
      "web_url": "https://gitlab.example.com/twitter/typeahead-js",
      "name": "Typeahead.Js",
      "name_with_namespace": "Twitter / Typeahead.Js",
      "path": "typeahead-js",
      "path_with_namespace": "twitter/typeahead-js",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:25.578Z",
      "last_activity_at": "2016-06-17T07:47:25.881Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    },
    {
      "id": 6,
      "description": "Aspernatur omnis repudiandae qui voluptatibus eaque.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/flight.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/flight.git",
      "web_url": "https://gitlab.example.com/twitter/flight",
      "name": "Flight",
      "name_with_namespace": "Twitter / Flight",
      "path": "flight",
      "path_with_namespace": "twitter/flight",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:24.661Z",
      "last_activity_at": "2016-06-17T07:47:24.838Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 8,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "shared_projects": [ // Deprecated and will be removed in API v5
    {
      "id": 8,
      "description": "Velit eveniet provident fugiat saepe eligendi autem.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "private",
      "ssh_url_to_repo": "git@gitlab.example.com:h5bp/html5-boilerplate.git",
      "http_url_to_repo": "https://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "https://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "H5bp / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:27.089Z",
      "last_activity_at": "2016-06-17T07:47:27.310Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "H5bp",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 4,
      "public_jobs": true,
      "shared_with_groups": [
        {
          "group_id": 4,
          "group_name": "Twitter",
          "group_full_path": "twitter",
          "group_access_level": 30,
          "expires_at": null
        },
        {
          "group_id": 3,
          "group_name": "Gitlab Org",
          "group_full_path": "gitlab-org",
          "group_access_level": 10,
          "expires_at": "2018-08-14"
        }
      ]
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

`prevent_sharing_groups_outside_hierarchy`属性は、トップレベルグループにのみ存在します。

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、次の属性も表示されます。

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `marked_for_deletion_on`
- `membership_lock`
- `wiki_access_level`
- `duo_features_enabled`
- `lock_duo_features_enabled`
- `duo_availability`
- `experiment_features_enabled`

その他のレスポンス属性:

```json
{
  "id": 4,
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "marked_for_deletion_on": "2020-04-03",
  "membership_lock": false,
  "wiki_access_level": "disabled",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "duo_availability": "default_on",
  "experiment_features_enabled": false,
  ...
}
```

パラメータ`with_projects=false`を追加すると、プロジェクトは返されません。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4?with_projects=false"
```

レスポンス例:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "file_template_project_id": 1,
  "parent_id": null
}
```

## グループのリストを取得する {#list-groups}

### すべてのグループのリストを取得する {#list-all-groups}

認証済みユーザーの表示可能なグループのリストを取得します。認証なしでアクセスすると、公開グループのみが返されます。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

認証なしでアクセスする場合、この[キーセットページネーション](rest/_index.md#keyset-based-pagination)もサポートします。

- 連続する結果ページをする場合は、キーセットページネーションを使用する必要があります。
- 特定の制限（[ベースのページネーション用のREST APIで許可される最大オフセット](../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)で指定）を超えると、ページネーションは使用できなくなります。

パラメータは以下のとおりです。

| 属性                | 型              | 必須 | 説明 |
|--------------------------|-------------------|----------|-------------|
| `skip_groups`            | 整数の配列 | いいえ       | 渡されたグループIDをスキップします。 |
| `all_available`          | ブール値           | いいえ       | `true`の場合、アクセス可能なすべてのグループを返します。`false`の場合、ユーザーがメンバーであるグループのみを返します。ユーザーの場合は`false`がデフォルトであり、管理者の場合は`true`がデフォルトです。認証されていないリクエストでは、常にすべての公開グループが返されます。`owned`属性と`min_access_level`属性が優先されます。 |
| `search`                 | 文字列            | いいえ       | 検索条件に一致する認証済みグループのリストを返します。 |
| `order_by`               | 文字列            | いいえ       | グループを`name`、`path`、`id`、または`similarity`で並べ替えます。デフォルトは`name`です。 |
| `sort`                   | 文字列            | いいえ       | グループを`asc`または`desc`の順に並べ替えます。デフォルトは`asc`です。 |
| `statistics`             | ブール値           | いいえ       | グループ統計を含めます（管理者のみ）。<br> トップレベルグループの場合、レスポンスはUIに表示される完全な`root_storage_statistics`データを返します。GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/469254)されました。 |
| `visibility`             | 文字列            | いいえ       | `public`、`internal`、または`private`のグループに制限します。 |
| `with_custom_attributes` | ブール値           | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |
| `owned`                  | ブール値           | いいえ       | 現在の認証済みユーザーが明示的に所有するグループに制限します。 |
| `min_access_level`       | 整数           | いいえ       | 現在のユーザーが、指定されている[ロール（`access_level`）](members.md#roles)以上のロールを持っているグループに制限します。 |
| `top_level_only`         | ブール値           | いいえ       | トップレベルグループに制限します（すべてのサブグループを除外）。 |
| `repository_storage`     | 文字列            | いいえ       | グループが使用しているリポジトリストレージでフィルタリングします（管理者のみ）。GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419643)されました。PremiumおよびUltimateのみです。 |
| `marked_for_deletion_on` | 日付              | いいえ       | グループが削除対象としてマークされた日付でフィルタリングします。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429315)されました。PremiumおよびUltimateのみです。 |
| `active`                 | ブール値           | いいえ       | アーカイブされておらず、削除対象としてマークされていないグループに制限します。 |
| `archived`               | ブール値           | いいえ       | アーカイブされたグループで制限します。[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519587) in GitLab 18.2.このパラメータは実験的機能です。 |

```plaintext
GET /groups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "ip_restriction_ranges": null
  }
]
```

パラメータ`statistics=true`を追加すると、認証済みユーザーが管理者の場合、追加のグループ統計が返されます。トップレベルグループの場合、`root_storage_statistics`も追加されます。

```plaintext
GET /groups?statistics=true
```

パラメータ`statistics=true`を使用すると、認証済みユーザーが管理者の場合、レスポンスにはコンテナレジストリのストレージサイズに関する情報が含まれます。

- `container_registry_size`: グループとそのサブグループ内のすべてのコンテナで使用されるストレージサイズの合計（バイト単位）。グループのプロジェクトとサブグループ内のすべてのリポジトリサイズの合計として計算されます。メタデータデータベースが有効になっている場合にのみ使用できます。

- `container_registry_size_is_estimated`: サイズが、すべてのの実際のデータに基づいた正確な計算であるか（`false`）、パフォーマンスの制約による見積もりであるか（`true`）を示します。

GitLab Self-Managedインスタンスの場合、コンテナレジストリサイズ属性を含めるには、[コンテナレジストリメタデータデータベース](../administration/packages/container_registry_metadata_database.md)を有効にする必要があります。

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "statistics": {
      "storage_size": 363,
      "repository_size": 33,
      "wiki_size": 100,
      "lfs_objects_size": 123,
      "job_artifacts_size": 57,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 50,
      "uploads_size": 0
    },
    "root_storage_statistics": {
      "build_artifacts_size": 0,
      "container_registry_size": 0,
      "container_registry_size_is_estimated": false,
      "dependency_proxy_size": 0,
      "lfs_objects_size": 0,
      "packages_size": 0,
      "pipeline_artifacts_size": 0,
      "repository_size": 0,
      "snippets_size": 0,
      "storage_size": 0,
      "uploads_size": 0,
      "wiki_size": 0
  },
    "wiki_access_level": "private",
    "duo_features_enabled": true,
    "lock_duo_features_enabled": false,
    "duo_availability": "default_on",
    "experiment_features_enabled": false,
  }
]
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`wiki_access_level`、`duo_features_enabled`、`lock_duo_features_enabled`、`duo_availability`、および`experiment_features_enabled`属性も表示されます。

グループは名前またはパスで検索できます。以下を参照してください。

[カスタム属性](custom_attributes.md)でフィルタリングするには、以下を使用します。

```plaintext
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

#### グループのページネーション {#group-pagination}

デフォルトでは、APIの結果はページネーションされるため、一度に20個のグループのみが表示されます。

取得するネームスペースの数を増やすには（最大100個）、以下を引数としてAPIコールに渡します。

```plaintext
/groups?per_page=100
```

ページをスイッチするには、以下を追加します。

```plaintext
/groups?per_page=100&page=2
```

### グループを検索する {#search-for-a-group}

名前またはが文字列と一致するすべてのグループを取得します。

```plaintext
GET /groups?search=foobar
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group"
  }
]
```

## グループの詳細のリストを取得する {#list-group-details}

### プロジェクトのリストを取得する {#list-projects}

このグループ内のプロジェクトのリストを取得します。認証なしでアクセスすると、公開プロジェクトのみが返されます。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

```plaintext
GET /groups/:id/projects
```

パラメータは以下のとおりです。

| 属性                     | 型           | 必須 | 説明 |
|-------------------------------|----------------|----------|-------------|
| `id`                          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `archived`                    | ブール値        | いいえ       | アーカイブステータスで制限します。 |
| `visibility`                  | 文字列         | いいえ       | 表示レベル（`public`、`internal`、`private`）で制限します。 |
| `order_by`                    | 文字列         | いいえ       | `id`、`name`、`path`、`created_at`、`updated_at`、`similarity`<sup>1</sup>、`star_count`または`last_activity_at`フィールドで並べ替えられたプロジェクトを返します。デフォルトは`created_at`です。 |
| `sort`                        | 文字列         | いいえ       | `asc`または`desc`の順にソートされたプロジェクトを返します。デフォルトは`desc`です。 |
| `search`                      | 文字列         | いいえ       | 検索条件に一致する、権限のあるプロジェクトのリストを返します。 |
| `simple`                      | ブール値        | いいえ       | プロジェクトごとに制限されたフィールドのみを返します。認証がない場合、何も行われません。単純なフィールドのみが返されます。 |
| `owned`                       | ブール値        | いいえ       | 現在のユーザーが所有するプロジェクトで制限します。 |
| `starred`                     | ブール値        | いいえ       | 現在のユーザーがStar付きに登録したプロジェクトで制限します。 |
| `topic`                       | 文字列         | いいえ       | トピックに一致するプロジェクトを返します。 |
| `with_issues_enabled`         | ブール値        | いいえ       | イシュー機能が有効になっているプロジェクトで制限します。デフォルトは`false`です。 |
| `with_merge_requests_enabled` | ブール値        | いいえ       | マージリクエスト機能が有効になっているプロジェクトで制限します。デフォルトは`false`です。 |
| `with_shared`                 | ブール値        | いいえ       | このグループに共有されているプロジェクトを含めます。デフォルトは`true`です。 |
| `include_subgroups`           | ブール値        | いいえ       | このグループのサブグループ内のプロジェクトを含めます。デフォルトは`false`です。 |
| `min_access_level`            | 整数        | いいえ       | 現在のユーザーが少なくともこの[ロール（`access_level`）](members.md#roles)を持つプロジェクトに制限します |
| `with_custom_attributes`      | ブール値        | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |
| `with_security_reports`       | ブール値        | いいえ       | ビルドのいずれかにセキュリティレポートアーティファクトが存在するプロジェクトのみを返します。これは、「セキュリティが有効になっているプロジェクト」を意味します。デフォルトは`false`です。Ultimateのみです。 |

**脚注**:

1. `search`パラメータから計算された類似性スコアで結果を並べ替えます。`order_by=similarity`を使用すると、`sort`パラメータは無視されます。`search`パラメータが指定されていない場合、APIは`name`で並べ替えられたプロジェクトを返します。

レスポンス例:

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "main",
    "tag_list": [], //deprecated, use `topics` instead
    "topics": [],
    "archived": false,
    "visibility": "internal",
    "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
    "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
    "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
    "name": "Html5 Boilerplate",
    "name_with_namespace": "Experimental / Html5 Boilerplate",
    "path": "html5-boilerplate",
    "path_with_namespace": "h5bp/html5-boilerplate",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "created_at": "2016-04-05T21:40:50.169Z",
    "last_activity_at": "2016-04-06T16:52:08.432Z",
    "shared_runners_enabled": true,
    "creator_id": 1,
    "namespace": {
      "id": 5,
      "name": "Experimental",
      "path": "h5bp",
      "kind": "group"
    },
    "avatar_url": null,
    "star_count": 1,
    "forks_count": 0,
    "open_issues_count": 3,
    "public_jobs": true,
    "shared_with_groups": [],
    "request_access_enabled": false
  }
]
```

{{< alert type="note" >}}

グループ内のプロジェクトと、グループに共有されているプロジェクトを区別するには、`namespace`を使用できます。プロジェクトがグループに共有されている場合、その`namespace`はリクエストの対象であるグループとは異なります。

{{< /alert >}}

### 共有プロジェクトのリストを取得する {#list-shared-projects}

このグループに共有されているプロジェクトのリストを取得します。認証なしでアクセスすると、公開されている共有プロジェクトのみが返されます。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

```plaintext
GET /groups/:id/projects/shared
```

パラメータは以下のとおりです。

| 属性                     | 型           | 必須 | 説明 |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `archived`                    | ブール値        | いいえ       | アーカイブステータスで制限します。 |
| `visibility`                  | 文字列         | いいえ       | 表示レベル（`public`、`internal`、`private`）で制限します。 |
| `order_by`                    | 文字列         | いいえ       | `id`、`name`、`path`、`created_at`、`updated_at`、`star_count`、または`last_activity_at`フィールドで並べ替えられたプロジェクトを返します。デフォルトは`created_at`です。 |
| `sort`                        | 文字列         | いいえ       | `asc`または`desc`の順にソートされたプロジェクトを返します。デフォルトは`desc`です。 |
| `search`                      | 文字列         | いいえ       | 検索条件に一致する、権限のあるプロジェクトのリストを返します。 |
| `simple`                      | ブール値        | いいえ       | プロジェクトごとに制限されたフィールドのみを返します。認証がない場合、何も行われません。単純なフィールドのみが返されます。 |
| `starred`                     | ブール値        | いいえ       | 現在のユーザーがStar付きに登録したプロジェクトで制限します。 |
| `with_issues_enabled`         | ブール値        | いいえ       | イシュー機能が有効になっているプロジェクトで制限します。デフォルトは`false`です。 |
| `with_merge_requests_enabled` | ブール値        | いいえ       | マージリクエスト機能が有効になっているプロジェクトで制限します。デフォルトは`false`です。 |
| `min_access_level`            | 整数        | いいえ       | 現在のユーザーが少なくともこの[ロール（`access_level`）](members.md#roles)を持つプロジェクトに制限します |
| `with_custom_attributes`      | ブール値        | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |

レスポンス例:

```json
[
   {
      "id":8,
      "description":"Shared project for Html5 Boilerplate",
      "name":"Html5 Boilerplate",
      "name_with_namespace":"H5bp / Html5 Boilerplate",
      "path":"html5-boilerplate",
      "path_with_namespace":"h5bp/html5-boilerplate",
      "created_at":"2020-04-27T06:13:22.642Z",
      "default_branch":"main",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"ssh://git@gitlab.com/h5bp/html5-boilerplate.git",
      "http_url_to_repo":"https://gitlab.com/h5bp/html5-boilerplate.git",
      "web_url":"https://gitlab.com/h5bp/html5-boilerplate",
      "readme_url":"https://gitlab.com/h5bp/html5-boilerplate/-/blob/main/README.md",
      "avatar_url":null,
      "star_count":0,
      "forks_count":4,
      "last_activity_at":"2020-04-27T06:13:22.642Z",
      "namespace":{
         "id":28,
         "name":"H5bp",
         "path":"h5bp",
         "kind":"group",
         "full_path":"h5bp",
         "parent_id":null,
         "avatar_url":null,
         "web_url":"https://gitlab.com/groups/h5bp"
      },
      "_links":{
         "self":"https://gitlab.com/api/v4/projects/8",
         "issues":"https://gitlab.com/api/v4/projects/8/issues",
         "merge_requests":"https://gitlab.com/api/v4/projects/8/merge_requests",
         "repo_branches":"https://gitlab.com/api/v4/projects/8/repository/branches",
         "labels":"https://gitlab.com/api/v4/projects/8/labels",
         "events":"https://gitlab.com/api/v4/projects/8/events",
         "members":"https://gitlab.com/api/v4/projects/8/members"
      },
      "empty_repo":false,
      "archived":false,
      "visibility":"public",
      "resolve_outdated_diff_discussions":false,
      "container_registry_enabled":true,
      "container_expiration_policy":{
         "cadence":"7d",
         "enabled":true,
         "keep_n":null,
         "older_than":null,
         "name_regex":null,
         "name_regex_keep":null,
         "next_run_at":"2020-05-04T06:13:22.654Z"
      },
      "issues_enabled":true,
      "merge_requests_enabled":true,
      "wiki_enabled":true,
      "jobs_enabled":true,
      "snippets_enabled":true,
      "can_create_merge_request_in":true,
      "issues_access_level":"enabled",
      "repository_access_level":"enabled",
      "merge_requests_access_level":"enabled",
      "forking_access_level":"enabled",
      "wiki_access_level":"enabled",
      "builds_access_level":"enabled",
      "snippets_access_level":"enabled",
      "pages_access_level":"enabled",
      "security_and_compliance_access_level":"enabled",
      "emails_disabled":null,
      "emails_enabled": null,
      "shared_runners_enabled":true,
      "lfs_enabled":true,
      "creator_id":1,
      "import_status":"failed",
      "open_issues_count":10,
      "ci_default_git_depth":50,
      "ci_forward_deployment_enabled":true,
      "ci_forward_deployment_rollback_allowed": true,
      "ci_allow_fork_pipelines_to_run_in_parent_project":true,
      "public_jobs":true,
      "build_timeout":3600,
      "auto_cancel_pending_pipelines":"enabled",
      "ci_config_path":null,
      "shared_with_groups":[
         {
            "group_id":24,
            "group_name":"Commit451",
            "group_full_path":"Commit451",
            "group_access_level":30,
            "expires_at":null
         }
      ],
      "only_allow_merge_if_pipeline_succeeds":false,
      "request_access_enabled":true,
      "only_allow_merge_if_all_discussions_are_resolved":false,
      "remove_source_branch_after_merge":true,
      "printing_merge_request_link_enabled":true,
      "merge_method":"merge",
      "suggestion_commit_message":null,
      "auto_devops_enabled":true,
      "auto_devops_deploy_strategy":"continuous",
      "autoclose_referenced_issues":true,
      "repository_storage":"default"
   }
]
```

### すべてのSAMLユーザーのリストを取得する {#list-all-saml-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193748)されました。

{{< /history >}}

指定されたトップレベルグループのすべてのSAMLユーザーをリスト表示します。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

```plaintext
GET /groups/:id/saml_users
```

サポートされている属性は以下のとおりです。

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `username`       | 文字列         | いいえ       | 指定されたユーザー名のユーザーを返します。 |
| `search`         | 文字列         | いいえ       | 一致する名前、メール、またはユーザー名を持つユーザーを返します。部分的な値を使用すると、結果が増えます。 |
| `active`         | ブール値        | いいえ       | アクティブユーザーのみを返します。 |
| `blocked`        | ブール値        | いいえ       | ブロックされたユーザーのみを返します。 |
| `created_after`  | 日時       | いいえ       | 指定された時刻以降に作成されたユーザーを返します。形式は、ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）です。 |
| `created_before` | 日時       | いいえ       | 指定された時刻よりも前に作成されたユーザーを返します。形式は、ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）です。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/saml_users"
```

レスポンス例:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

### プロビジョニングされたユーザーのリストを取得する {#list-provisioned-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特定のグループによってプロビジョニングされたユーザーのリストを取得します。サブグループは含まれません。

少なくともグループに対するメンテナーロールが必要です。

```plaintext
GET /groups/:id/provisioned_users
```

パラメータは以下のとおりです。

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `username`       | 文字列         | いいえ       | 特定のユーザー名を持つ1つのユーザーを返します。 |
| `search`         | 文字列         | いいえ       | 名前、メールアドレス、ユーザー名でユーザーを検索します。 |
| `active`         | ブール値        | いいえ       | アクティブユーザーのみを返します。 |
| `blocked`        | ブール値        | いいえ       | ブロックされたユーザーのみを返します。 |
| `created_after`  | 日時       | いいえ       | 指定された時刻以降に作成されたユーザーを返します。 |
| `created_before` | 日時       | いいえ       | 指定された時刻よりも前に作成されたユーザーを返します。 |

レスポンス例:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "John Doe22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [ ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  ...
]
```

### サブグループのリストを取得する {#list-subgroups}

このグループで表示可能な直接サブグループのリストを取得します。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

このリストを次のいずれかのユーザーとしてリクエストする場合は、次のようになります。

- 認証されていないユーザーの場合、公開グループのみが返されます。
- 認証済みユーザーの場合、メンバーであるグループのみが返され、公開グループは含まれません。

パラメータは以下のとおりです。

| 属性                | 型              | 必須 | 説明 |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | 整数または文字列    | はい      | 直属の親グループのIDまたは[URLエンコードされたグループのパス](rest/_index.md#namespaced-paths)。 |
| `skip_groups`            | 整数の配列 | いいえ       | 渡されたグループIDをスキップします。 |
| `all_available`          | ブール値           | いいえ       | アクセスできるすべてのグループを表示します（認証済みユーザーの場合は`false`がデフォルトで、管理者の場合は`true`がデフォルトです）。属性とが優先されます。`owned`および`min_access_level`属性が優先されます。 |
| `search`                 | 文字列            | いいえ       | 検索条件に一致する認証済みグループのリストを返します。サブグループの（フルパスではなく）短いパスのみが検索されます。 |
| `order_by`               | 文字列            | いいえ       | グループを`name`、`path`、または`id`で並べ替えます。デフォルトは`name`です。 |
| `sort`                   | 文字列            | いいえ       | グループを`asc`または`desc`の順に並べ替えます。デフォルトは`asc`です。 |
| `statistics`             | ブール値           | いいえ       | グループ統計を含めます（管理者のみ）。 |
| `with_custom_attributes` | ブール値           | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |
| `owned`                  | ブール値           | いいえ       | 現在の認証済みユーザーが明示的に所有するグループに制限します。 |
| `min_access_level`       | 整数           | いいえ       | 現在のユーザーが、指定されている[ロール（`access_level`）](members.md#roles)以上のロールを持っているグループに制限します。 |
| `all_available`          | ブール値           | いいえ       | `true`の場合、アクセス可能なすべてのグループを返します。`false`の場合、ユーザーがメンバーであるグループのみを返します。ユーザーの場合は`false`がデフォルトであり、管理者の場合は`true`がデフォルトです。認証されていないリクエストでは、常にすべての公開グループが返されます。`owned`属性と`min_access_level`属性が優先されます。 |
| `active`                 | ブール値           | いいえ       | アーカイブされておらず、削除対象としてマークされていないグループに制限します。 |

```plaintext
GET /groups/:id/subgroups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://gitlab.example.com/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`wiki_access_level`、`duo_features_enabled`、`lock_duo_features_enabled`、`duo_availability`、および`experiment_features_enabled`属性も表示されます。

### 子孫グループのリストを取得する {#list-descendant-groups}

このグループの表示可能な子孫グループのリストを取得します。認証なしでアクセスすると、公開グループのみが返されます。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

パラメータは以下のとおりです。

| 属性                | 型              | 必須 | 説明 |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | 整数または文字列    | はい      | 直属の親グループのIDまたは[URLエンコードされたグループのパス](rest/_index.md#namespaced-paths)。 |
| `skip_groups`            | 整数の配列 | いいえ       | 渡されたグループIDをスキップします。 |
| `all_available`          | ブール値           | いいえ       | `true`の場合、アクセス可能なすべてのグループを返します。`false`の場合、ユーザーがメンバーであるグループのみを返します。ユーザーの場合は`false`がデフォルトであり、管理者の場合は`true`がデフォルトです。認証されていないリクエストでは、常にすべての公開グループが返されます。`owned`属性と`min_access_level`属性が優先されます。 |
| `search`                 | 文字列            | いいえ       | 検索条件に一致する認証済みグループのリストを返します。子孫グループの（フルパスではなく）短いパスのみが検索されます。 |
| `order_by`               | 文字列            | いいえ       | グループを`name`、`path`、または`id`で並べ替えます。デフォルトは`name`です。 |
| `sort`                   | 文字列            | いいえ       | グループを`asc`または`desc`の順に並べ替えます。デフォルトは`asc`です。 |
| `statistics`             | ブール値           | いいえ       | グループ統計を含めます（管理者のみ）。 |
| `with_custom_attributes` | ブール値           | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |
| `owned`                  | ブール値           | いいえ       | 現在の認証済みユーザーが明示的に所有するグループに制限します。 |
| `min_access_level`       | 整数           | いいえ       | 現在のユーザーが、指定されている[ロール（`access_level`）](members.md#roles)以上のロールを持っているグループに制限します。 |
| `active`                 | ブール値           | いいえ       | アーカイブされておらず、削除対象としてマークされていないグループに制限します。 |

```plaintext
GET /groups/:id/descendant_groups
```

```json
[
  {
    "id": 2,
    "name": "Bar Group",
    "path": "bar",
    "description": "A subgroup of Foo Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "request_access_enabled": false,
    "full_name": "Bar Group",
    "full_path": "foo/bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  },
  {
    "id": 3,
    "name": "Baz Group",
    "path": "baz",
    "description": "A subgroup of Bar Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/baz.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar/baz",
    "request_access_enabled": false,
    "full_name": "Baz Group",
    "full_path": "foo/bar/baz",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`wiki_access_level`、`duo_features_enabled`、`lock_duo_features_enabled`、`duo_availability`、および`experiment_features_enabled`属性も表示されます。

### 共有グループのリストを取得する {#list-shared-groups}

特定のグループが招待されているグループのリストを取得します。認証なしでアクセスすると、公開されている共有グループのみが返されます。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

パラメータは以下のとおりです。

| 属性                             | 型              | 必須 | 説明 |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `skip_groups`                         | 整数の配列 | いいえ       | 指定されたグループのIDを除外します。 |
| `search`                              | 文字列            | いいえ       | 検索条件に一致する認証済みグループのリストを返します。 |
| `order_by`                            | 文字列            | いいえ       | グループを`name`、`path`、`id`、または`similarity`で並べ替えます。デフォルトは`name`です。 |
| `sort`                                | 文字列            | いいえ       | グループを`asc`または`desc`の順に並べ替えます。デフォルトは`asc`です。 |
| `visibility`                          | 文字列            | いいえ       | `public`、`internal`、または`private`のグループに制限します。 |
| `min_access_level`                    | 整数           | いいえ       | 現在のユーザーが、指定されている[ロール（`access_level`）](members.md#roles)以上のロールを持っているグループに制限します。 |
| `with_custom_attributes`              | ブール値           | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |

```plaintext
GET /groups/:id/groups/shared
```

レスポンス例:

```json
[
  {
    "id": 101,
    "web_url": "http://gitlab.example.com/groups/some_path",
    "name": "group1",
    "path": "some_path",
    "description": "",
    "visibility": "public",
    "share_with_group_lock": "false",
    "require_two_factor_authentication": "false",
    "two_factor_grace_period": 48,
    "project_creation_level": "maintainer",
    "auto_devops_enabled": "nil",
    "subgroup_creation_level": "maintainer",
    "emails_disabled": "false",
    "emails_enabled": "true",
    "mentions_disabled": "nil",
    "lfs_enabled": "true",
    "math_rendering_limits_enabled": "true",
    "lock_math_rendering_limits_enabled": "false",
    "default_branch": "nil",
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
        "allowed_to_push": [
          {
              "access_level": 30
          }
        ],
        "allow_force_push": "true",
        "allowed_to_merge": [
          {
              "access_level": 30
          }
        ],
        "developer_can_initial_push": "false",
        "code_owner_approval_required": "false"
    },
    "avatar_url": "http://gitlab.example.com/uploads/-/system/group/avatar/101/banana_sample.gif",
    "request_access_enabled": "true",
    "full_name": "group1",
    "full_path": "some_path",
    "created_at": "2024-06-06T09:39:30.056Z",
    "parent_id": "nil",
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": "nil",
    "ldap_access": "nil",
    "wiki_access_level": "enabled"
  }
]
```

### 招待されたグループのリストを取得する {#list-invited-groups}

特定のグループに招待されたグループのリストを取得します。認証なしでアクセスすると、公開されている招待グループのみが返されます。このエンドポイントは、ユーザー（認証済みユーザーの場合）またはIP（認証されていないユーザーの場合）ごとに、1分あたり60リクエストにレート制限されています。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

パラメータは以下のとおりです。

| 属性                             | 型              | 必須 | 説明 |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`                              | 文字列            | いいえ       | 検索条件に一致する認証済みグループのリストを返します。 |
| `min_access_level`                    | 整数           | いいえ       | 現在のユーザーが、指定されている[ロール（`access_level`）](members.md#roles)以上のロールを持っているグループに制限します。 |
| `relation`                            | 文字列の配列  | いいえ       | グループを関係（直接または継承）でフィルタリングします。 |
| `with_custom_attributes`              | ブール値           | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます（管理者のみ）。 |

```plaintext
GET /groups/:id/invited_groups
```

レスポンス例:

```json
[
  {
    "id": 33,
    "web_url": "http://gitlab.example.com/groups/flightjs",
    "name": "Flightjs",
    "path": "flightjs",
    "description": "Illo dolorum tempore eligendi minima ducimus provident.",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "maintainer",
    "emails_disabled": false,
    "emails_enabled": true,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "math_rendering_limits_enabled": true,
    "lock_math_rendering_limits_enabled": false,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
        {
          "access_level": 40
        }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
        {
          "access_level": 40
        }
      ],
      "developer_can_initial_push": false
    },
    "avatar_url": null,
    "request_access_enabled": true,
    "full_name": "Flightjs",
    "full_path": "flightjs",
    "created_at": "2024-07-09T10:31:08.307Z",
    "parent_id": null,
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": null,
    "ldap_access": null,
    "wiki_access_level": "enabled"
  }
]
```

### 監査イベントのリストを取得する {#list-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループ監査イベントには、[グループ監査イベントAPI](audit_events.md#group-audit-events)を介してアクセスできます。

## グループを管理する {#manage-groups}

### グループを作成する {#create-a-group}

{{< alert type="note" >}}

GitLab SaaSで親グループのないグループを作成するには、GitLab UIを使用する必要があります。APIを使用してこの操作を行うことはできません。

{{< /alert >}}

新しいプロジェクトグループを作成します。これは、グループを作成できるユーザーのみが利用できます。

```plaintext
POST /groups
```

パラメータは以下のとおりです。

| 属性                            | 型    | 必須 | 説明 |
|--------------------------------------|---------|----------|-------------|
| `name`                               | 文字列  | はい      | グループの名前。 |
| `path`                               | 文字列  | はい      | グループのパス。 |
| `auto_devops_enabled`                | ブール値 | いいえ       | このグループ内のすべてのプロジェクトでAuto DevOpsパイプラインをデフォルトにします。 |
| `avatar`                             | 混合   | いいえ       | グループのアバターの画像ファイル。 |
| `default_branch`                     | 文字列  | いいえ       | グループのプロジェクトの[デフォルトブランチ](../user/project/repository/branches/default.md)名。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442298)されました。 |
| `default_branch_protection`          | 整数 | いいえ       | GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)になりました。代わりに`default_branch_protection_defaults`を使用してください。 |
| `default_branch_protection_defaults` | ハッシュ    | いいえ       | GitLab 17.0で導入されました。利用可能なオプションについては、[`default_branch_protection_defaults`のオプション](#options-for-default_branch_protection_defaults)を参照してください。 |
| `description`                        | 文字列  | いいえ       | グループの説明。 |
| `enabled_git_access_protocol`        | 文字列  | いいえ       | Gitアクセスで有効になっているプロトコル。使用できる値は`ssh`、`http`、および`all`（両方のプロトコルを許可する場合）です。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436618)されました。 |
| `emails_disabled`                    | ブール値 | いいえ       | （GitLab 16.5で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)になりました。）メール通知を無効にします。代わりに`emails_enabled`を使用してください。 |
| `emails_enabled`                     | ブール値 | いいえ       | メール通知を有効にします。 |
| `lfs_enabled`                        | ブール値 | いいえ       | このグループのプロジェクトに対して、Large File Storage（LFS）を有効または無効にします。 |
| `mentions_disabled`                  | ブール値 | いいえ       | グループがメンションされる機能を無効にします。 |
| `organization_id`                    | 整数 | いいえ       | グループの組織ID。 |
| `parent_id`                          | 整数 | いいえ       | ネストされたグループを作成するための親グループID。 |
| `project_creation_level`             | 文字列  | いいえ       | デベロッパーがグループにプロジェクトを作成できるかどうかを決定します。`administrator`（管理者モードが有効になっているユーザー）、`noone`（なし）、`maintainer`（メンテナーロールを持つユーザー）、または`developer`（デベロッパーまたはメンテナーロールを持つユーザー）を指定できます。 |
| `request_access_enabled`             | ブール値 | いいえ       | ユーザーがメンバーアクセスをリクエストできるようにします。 |
| `require_two_factor_authentication`  | ブール値 | いいえ       | このグループのすべてのユーザーに対して2要素認証のセットアップを必須にします。 |
| `share_with_group_lock`              | ブール値 | いいえ       | このグループ内で別のグループとプロジェクトを共有することを禁止します。 |
| `subgroup_creation_level`            | 文字列  | いいえ       | [サブグループ](../user/group/subgroups/_index.md#create-a-subgroup)の作成を許可します。`owner`（オーナーロールを持つユーザー）または`maintainer`（メンテナーロールを持つユーザー）を指定できます。 |
| `two_factor_grace_period`            | 整数 | いいえ       | 2要素認証が強制的に適用されるまでの時間（時間単位）。 |
| `visibility`                         | 文字列  | いいえ       | グループの表示レベル。`private`、`internal`、または`public`のいずれかです。 |
| `membership_lock`                    | ブール値 | いいえ       | このグループのプロジェクトにユーザーを追加できません。PremiumおよびUltimateのみです。 |
| `extra_shared_runners_minutes_limit` | 整数 | いいえ       | 管理者のみが設定できます。このグループの追加のコンピューティング時間です。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `shared_runners_minutes_limit`       | 整数 | いいえ       | 管理者のみが設定できます。このグループの1か月あたりのコンピューティング時間の最大数。`nil`（デフォルト、システムのデフォルトを継承）、`0`（無制限）、または`> 0`のいずれかです。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `wiki_access_level`                  | 文字列  | いいえ       | Wikiのアクセスレベル。`disabled`、`private`、または`enabled`のいずれかです。PremiumおよびUltimateのみです。 |
| `duo_availability` | 文字列 | いいえ | GitLab Duoの可用性設定。有効な値は`default_on`、`default_off`、または`never_on`です。注: UIでは`never_on`は「常にオフ」として表示されます。 |
| `experiment_features_enabled` | ブール値 | いいえ | このグループに対して実験的機能を有効にします。 |

#### `default_branch_protection`のオプション {#options-for-default_branch_protection}

`default_branch_protection`属性は、[デベロッパー](../user/project/repository/branches/default.md)またはメンテナーのロールを持つユーザーが該当するデフォルトブランチにプッシュできるかどうかを決定します。次のテーブルで詳しく説明します。

| 値 | 説明 |
|-------|-------------|
| `0`   | 保護されません。デベロッパーまたはメンテナーのロールを持つユーザーは、以下の操作を実行できます。<br>\- 新しいコミットをプッシュする<br>\- 変更を強制プッシュする<br>\- ブランチを削除する |
| `1`   | 部分的に保護されます。デベロッパーまたはメンテナーのロールを持つユーザーは、以下の操作を実行できます。<br>\- 新しいコミットをプッシュする |
| `2`   | 完全に保護されます。メンテナーのロールを持つユーザーのみが、以下の操作を実行できます。<br>\- 新しいコミットをプッシュする |
| `3`   | プッシュから保護されています。メンテナーのロールを持つユーザーが以下の操作を実行できます。<br>\- 新しいコミットをプッシュする<br>\- 変更を強制プッシュする<br>\- マージリクエストを承認する<br>デベロッパーのロールを持つユーザーは、以下の操作を実行できます。<br>\- マージリクエストを承認する |
| `4`   | 初回プッシュ後に完全に保護されます。デベロッパーのロールを持つユーザーは、以下の操作を実行できます。<br>\- 空のリポジトリにコミットをプッシュする<br> メンテナーのロールを持つユーザーが以下の操作を実行できます。<br>\- 新しいコミットをプッシュする<br>\- マージリクエストを承認する |

#### `default_branch_protection_defaults`のオプション {#options-for-default_branch_protection_defaults}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)されました。

{{< /history >}}

`default_branch_protection_defaults`属性は、デフォルトブランチ保護のデフォルトを記述します。すべてのパラメータはオプションです。

| キー                          | 型    | 説明 |
|:-----------------------------|:--------|:------------|
| `allowed_to_push`            | 配列   | プッシュが許可されたアクセスレベルの配列。デベロッパー（30）またはメンテナー（40）をサポートしています。 |
| `allow_force_push`           | ブール値 | プッシュアクセスを持つすべてのユーザーに対して強制プッシュを許可します。 |
| `allowed_to_merge`           | 配列   | マージが許可されたアクセスレベルの配列。デベロッパー（30）またはメンテナー（40）をサポートしています。 |
| `developer_can_initial_push` | ブール値 | デベロッパーに対し初回プッシュを許可します。 |

### サブグループを作成する {#create-a-subgroup}

これは、[新しいグループ](#create-a-group)の作成に似ています。[グループのリスト](#list-groups)呼び出しからの`parent_id`が必要です。その後、必要な情報を入力できます。

- `subgroup_path`
- `subgroup_name`

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"path": "<subgroup_path>", "name": "<subgroup_name>", "parent_id": <parent_group_id> }' \
     "https://gitlab.example.com/api/v4/groups/"
```

### グループを削除する {#delete-a-group}

{{< history >}}

- GitLab 18.0のFreeプランで、削除対象のグループのマークが[利用可能](https://gitlab.com/groups/gitlab-org/-/epics/17208)になりました。
- `permanently_remove`は、`disallow_immediate_deletion`という名前の[フラグ](../administration/feature_flags/_index.md)でGitLab 18.4で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201957)になりました。

{{< /history >}}

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループを削除対象としてマークします。グループは、保持期間の終了時に削除されます。

- GitLab.comでは、グループは30日間保持されます。
- GitLab Self-Managedでは、保持期間は[インスタンスの設定](../administration/settings/visibility_and_access_controls.md#deletion-protection)によって制御されます。

このエンドポイントは、以前に削除対象としてマークされたサブグループを即座に削除することもできます。

```plaintext
DELETE /groups/:id
```

パラメータは以下のとおりです。

| `id` | integerまたはstring | yes | グループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)またはID。| | `permanently_remove` | boolean/string | no | GitLab 18.4で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201957)。`true`の場合、既に削除対象としてマークされているサブグループをすぐに削除します。トップレベルグループは削除できません。| | `full_path` | string | no | サブグループへのフルパス。サブグループの削除の確認に使用されます。`permanently_remove`が`true`の場合、この属性は必須です。[グループの詳細](groups.md#get-a-single-group)を確認するには、サブグループのパスを参照してください。

ユーザーに認証がある場合、レスポンスは`202 Accepted`です。

{{< alert type="note" >}}

サブスクリプションにリンクされているGitLab.comグループは削除できません。最初に、別のグループとの[サブスクリプションをリンク](../subscriptions/manage_subscription.md#link-subscription-to-a-group)する必要があります。

{{< /alert >}}

#### 削除対象としてマークされたグループを復元する {#restore-a-group-marked-for-deletion}

以前に削除対象としてマークされたグループを復元します。

```plaintext
POST /groups/:id/restore
```

パラメータは以下のとおりです。

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

### グループをアーカイブする {#archive-a-group}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.0で`archive_group`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481969)されました。デフォルトでは無効になっています。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

グループをアーカイブします。

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループが既にアーカイブされている場合、このエンドポイントは、処理できないエンティティエラー`422`を返します。

```plaintext
POST /groups/:id/archive
```

パラメータは以下のとおりです。

| 属性                             | 型              | 必須 | 説明 |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | 整数または文字列 | はい      | 認証済みユーザーが所有しているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

レスポンス例:

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": true,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

#### グループのアーカイブを解除する {#unarchive-a-group}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.0で`archive_group`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481969)されました。デフォルトでは無効になっています。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

グループのアーカイブを解除します。

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループがアーカイブされていない場合、このエンドポイントは、処理できないエンティティエラー`422`を返します。

```plaintext
POST /groups/:id/unarchive
```

パラメータは以下のとおりです。

| 属性                             | 型              | 必須 | 説明 |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | 整数または文字列 | はい      | 認証済みユーザーが所有しているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

レスポンス例:

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": false,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

### グループを転送する {#transfer-a-group}

グループを新しい親グループに転送するか、サブグループをトップレベルグループに変換します。

前提要件:

- グループのオーナーロールを持っている必要があります。
- グループを転送する場合は、新しい親グループで[サブグループを作成する](../user/group/subgroups/_index.md#create-a-subgroup)権限が必要です。
- サブグループを変換する場合は、[トップレベルグループを作成する権限](../administration/user_settings.md)が必要です。

```plaintext
POST /groups/:id/transfer
```

パラメータは以下のとおりです。

| 属性  | 型    | 必須 | 説明 |
|------------|---------|----------|-------------|
| `id`       | 整数 | はい      | 転送行するグループのID。 |
| `id`       | 整数 | はい      | 転送行するグループのID。 |
| `group_id` | 整数 | いいえ       | 新しい親グループのID。指定しない場合、グループはトップレベルグループに変換されます。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/transfer?group_id=7"
```

#### グループの転送に利用できる場所のリストを取得する {#list-all-locations-available-for-group-transfer}

指定されたグループを転送するために利用可能なすべての親グループを一覧表示します。

```plaintext
GET /groups/:id/transfer_locations
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | 転送するグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | 検索する特定のグループの名前。 |

リクエストの例:

```shell
curl --request GET "https://gitlab.example.com/api/v4/groups/1/transfer_locations"
```

レスポンス例:

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

#### プロジェクトをグループに転送する {#transfer-a-project-to-a-group}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトを別のグループネームスペースに転送します。または、代わりに[プロジェクトを新しいネームスペースに転送する](projects.md#transfer-a-project-to-a-new-namespace)エンドポイントを使用します。

{{< alert type="note" >}}

タグ付きパッケージがプロジェクトのリポジトリに存在する場合、転送プロセスが失敗する可能性があります。

{{< /alert >}}

前提要件:

- インスタンスの管理者である。

```plaintext
POST /groups/:id/projects/:project_id
```

パラメータは以下のとおりです。

| 属性    | 型           | 必須 | 説明 |
| ------------ | -------------- | -------- | ----------- |
| `id`         | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `project_id` | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/projects/56"
```

### グループの招待 {#invite-groups}

これらのエンドポイントは、グループの招待に使用されます。詳しくは、[グループへのグループの招待](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group)をご覧ください。

#### グループ招待の作成 {#create-a-group-invitation}

ターゲットグループを指定されたグループに追加するグループ招待を作成します。

```plaintext
POST /groups/:id/share
```

| `id` | 整数または文字列 | はい | ターゲットグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)またはID。| | `group_id` | 整数 | はい | 招待するグループのID。| | `group_access` | 整数 | はい | 招待されたグループに割り当てるデフォルトロールの[ロール (`access_level`)](members.md#roles)。| | `expires_at` | 日付（ISO 8601）| いいえ | グループ招待の有効期限の日付。| | `member_role_id` | 整数 | いいえ | 招待されたグループに割り当てる[カスタムロール](../user/custom_roles/_index.md#assign-a-custom-role-to-an-invited-group)のID。定義されている場合、`group_access`はカスタムロールの作成に使用されるベースロールと一致する必要があります。|

成功すると、`200`とグループの詳細が返されます。

#### グループ招待の削除 {#delete-a-group-invitation}

グループ招待を削除し、指定されたグループからターゲットグループへのアクセスを削除します。

```plaintext
DELETE /groups/:id/share/:group_id
```

| 属性  | 型           | 必須 | 説明 |
|------------|----------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | ターゲットグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `group_id` | 整数        | はい      | 招待を取り消すグループのID。 |

成功すると`204`が返されますが、コンテンツは返されません。

## グループ属性を更新する {#update-group-attributes}

{{< history >}}

- GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183101)になりました。機能フラグ`limit_unique_project_downloads_per_namespace_user`は削除されました。
- `web_based_commit_signing_enabled`はGitLab 18.2で[フラグ](../administration/feature_flags/_index.md)の`use_web_based_commit_signing_enabled`という名前で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193928)。デフォルトでは無効になっています。{{< /history >}}

{{< alert type="flag" >}}

`web_based_commit_signing_enabled`属性の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

指定されたグループの属性を更新します。

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

```plaintext
PUT /groups/:id
```

| 属性                                            | 型              | 必須 | 説明 |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | 整数           | はい      | グループのID。 |
| `name`                                               | 文字列            | いいえ       | グループの名前。 |
| `path`                                               | 文字列            | いいえ       | グループのパス。 |
| `auto_devops_enabled`                                | ブール値           | いいえ       | このグループ内のすべてのプロジェクトでAuto DevOpsパイプラインをデフォルトにします。 |
| `avatar`                                             | 混合             | いいえ       | グループのアバターの画像ファイル。 |
| `default_branch`                                     | 文字列            | いいえ       | グループのプロジェクトの[デフォルトブランチ](../user/project/repository/branches/default.md)名。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442298)されました。 |
| `default_branch_protection`                          | 整数           | いいえ       | GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)になりました。代わりに`default_branch_protection_defaults`を使用してください。 |
| `default_branch_protection_defaults`                 | ハッシュ              | いいえ       | GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)されました。利用可能なオプションについては、[`default_branch_protection_defaults`のオプション](#options-for-default_branch_protection_defaults)を参照してください。 |
| `description`                                        | 文字列            | いいえ       | グループの説明。 |
| `enabled_git_access_protocol`                        | 文字列            | いいえ       | Gitアクセスで有効になっているプロトコル。使用できる値は`ssh`、`http`、および`all`（両方のプロトコルを許可する場合）です。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436618)されました。 |
| `emails_disabled`                                    | ブール値           | いいえ       | （GitLab 16.5で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)になりました。）メール通知を無効にします。代わりに`emails_enabled`を使用してください。 |
| `emails_enabled`                                     | ブール値           | いいえ       | メール通知を有効にします。 |
| `lfs_enabled`                                        | ブール値           | いいえ       | このグループのプロジェクトに対して、Large File Storage（LFS）を有効または無効にします。 |
| `mentions_disabled`                                  | ブール値           | いいえ       | グループがメンションされる機能を無効にします。 |
| `prevent_sharing_groups_outside_hierarchy`           | ブール値           | いいえ       | [グループ階層外部でのグループ共有を防ぐ](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy)を参照してください。この属性は、トップレベルグループでのみ使用できます。 |
| `project_creation_level`                             | 文字列            | いいえ       | デベロッパーがグループにプロジェクトを作成できるかどうかを決定します。`noone`（なし）、`maintainer`（メンテナーロールを持つユーザー）、または`developer`（デベロッパーロールまたはメンテナーロールを持つユーザー）のいずれかです。 |
| `request_access_enabled`                             | ブール値           | いいえ       | ユーザーがメンバーアクセスをリクエストできるようにします。 |
| `require_two_factor_authentication`                  | ブール値           | いいえ       | このグループのすべてのユーザーに対して2要素認証のセットアップを必須にします。 |
| `shared_runners_setting`                             | 文字列            | いいえ       | [`shared_runners_setting`のオプション](#options-for-shared_runners_setting)を参照してください。グループのサブグループおよびプロジェクトのインスタンスRunnerを有効または無効にします。 |
| `share_with_group_lock`                              | ブール値           | いいえ       | このグループ内で別のグループとプロジェクトを共有することを禁止します。 |
| `subgroup_creation_level`                            | 文字列            | いいえ       | [サブグループ](../user/group/subgroups/_index.md#create-a-subgroup)の作成を許可します。`owner`（オーナーロールを持つユーザー）または`maintainer`（メンテナーロールを持つユーザー）を指定できます。 |
| `two_factor_grace_period`                            | 整数           | いいえ       | 2要素認証が強制的に適用されるまでの時間（時間単位）。 |
| `visibility`                                         | 文字列            | いいえ       | グループの表示レベル。`private`、`internal`、または`public`のいずれかです。 |
| `extra_shared_runners_minutes_limit`                 | 整数           | いいえ       | 管理者のみが設定できます。このグループの追加のコンピューティング時間です。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `file_template_project_id`                           | 整数           | いいえ       | カスタムファイルテンプレートの読み込み元のプロジェクトのID。PremiumおよびUltimateのみです。 |
| `membership_lock`                                    | ブール値           | いいえ       | このグループのプロジェクトにユーザーを追加できません。PremiumおよびUltimateのみです。 |
| `prevent_forking_outside_group`                      | ブール値           | いいえ       | 有効にすると、ユーザーはこのグループから外部ネームスペースへプロジェクトをフォークできません。PremiumおよびUltimateのみです。 |
| `shared_runners_minutes_limit`                       | 整数           | いいえ       | 管理者のみが設定できます。このグループの1か月あたりのコンピューティング時間の最大数。`nil`（デフォルト、システムのデフォルトを継承）、`0`（無制限）、または`> 0`のいずれかです。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `unique_project_download_limit`                      | 整数           | いいえ       | 指定された期間内にユーザーがダウンロードできる一意のプロジェクトの最大数。この数を超えると、ユーザーはBANされます。トップレベルグループでのみ使用できます。デフォルトは、0、最大値は10,000です。Ultimateのみです。 |
| `unique_project_download_limit_interval_in_seconds`  | 整数           | いいえ       | ユーザーが最大量のプロジェクトをダウンロードできる期間。この期間を経過すると、ユーザーはBANされます。トップレベルグループでのみ使用できます。デフォルトは、0、最大値は864,000秒（10日間）です。Ultimateのみです。 |
| `unique_project_download_limit_allowlist`            | 文字列の配列  | いいえ       | 一意のプロジェクトのダウンロード制限から除外されるユーザー名のリスト。トップレベルグループでのみ使用できます。デフォルトは`[]`、最大値は100個のユーザー名です。Ultimateのみです。 |
| `unique_project_download_limit_alertlist`            | 整数の配列 | いいえ       | 一意のプロジェクトのダウンロード制限を超えた場合にメールで通知されるユーザーIDのリスト。トップレベルグループでのみ使用できます。デフォルトは`[]`、最大値は100個のユーザーIDです。Ultimateのみです。 |
| `auto_ban_user_on_excessive_projects_download`       | ブール値           | いいえ       | 有効にすると、ユーザーが`unique_project_download_limit`と`unique_project_download_limit_interval_in_seconds`で指定されている一意のプロジェクトの最大数を超えてダウンロードすると、.ユーザーは自動的にグループからBANされます。Ultimateのみです。 |
| `ip_restriction_ranges`                              | 文字列      | いいえ       | グループアクセスを制限するためのIPアドレスまたはサブネットマスクのカンマ区切りリスト。PremiumおよびUltimateのみです。 |
| `allowed_email_domains_list`                         | 文字列      | いいえ       | グループアクセスを許可するメールアドレスドメインのカンマ区切りリスト。GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/351494)されました。GitLab PremiumおよびUltimateのみです。 |
| `wiki_access_level`                                  | 文字列            | いいえ       | Wikiのアクセスレベル。`disabled`、`private`、または`enabled`のいずれかです。PremiumおよびUltimateのみです。 |
| `duo_availability`                                   | 文字列 | いいえ | GitLab Duoの可用性設定。有効な値は`default_on`、`default_off`、または`never_on`です。注: UIでは`never_on`は「常にオフ」として表示されます。 |
| `experiment_features_enabled`                        | ブール値 | いいえ | このグループに対して実験的機能を有効にします。 |
| `math_rendering_limits_enabled`                      | ブール値           | いいえ       | 数式レンダリングの制限がこのグループに使用されるかどうかを示します。 |
| `lock_math_rendering_limits_enabled`                 | ブール値           | いいえ       | 数式レンダリングの制限がすべての子孫グループに対してロックされているかどうかを示します。 |
| `duo_features_enabled`                               | ブール値           | いいえ       | このグループでGitLab Duo機能が有効になっているかどうかを示します。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `lock_duo_features_enabled`                          | ブール値           | いいえ       | GitLab Duo機能で有効になっている設定がすべてのサブグループに適用されるかどうかを示します。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `max_artifacts_size`                                 | 整数           | いいえ       | 個々のジョブアーティファクトの最大ファイルサイズ（MB単位）。 |
| `web_based_commit_signing_enabled`                  | ブール値           | いいえ       | GitLab UIから作成されたコミットのWebベースのコミット署名を有効にします。GitLab.comのトップレベルグループでのみ利用可能です。グループに対して有効になっている場合、グループ内のすべてのプロジェクトに適用されます。 |

{{< alert type="note" >}}

レスポンス内の`projects`属性と`shared_projects`属性は非推奨であり、[v5で削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/213797)です。グループ内のすべてのプロジェクトの詳細を取得するには、[グループのプロジェクトをリスト](#list-projects)または[グループの共有プロジェクトをリスト](#list-shared-projects)を使用します。

{{< /alert >}}

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/5?name=Experimental"
```

このエンドポイントは、最大100個のプロジェクトと共有プロジェクトを返します。グループ内のすべてのプロジェクトの詳細を取得するには、代わりに[グループのプロジェクトをリストエンドポイント](#list-projects)を使用します。

レスポンス例:

```json
{
  "id": 5,
  "name": "Experimental",
  "path": "h5bp",
  "description": "foo",
  "visibility": "internal",
  "avatar_url": null,
  "web_url": "http://gitlab.example.com/groups/h5bp",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Foobar Group",
  "full_path": "h5bp",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "prevent_sharing_groups_outside_hierarchy": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 9,
      "description": "foo",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "public": false,
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
      "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "Experimental / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": true,
      "created_at": "2016-04-05T21:40:50.169Z",
      "last_activity_at": "2016-04-06T16:52:08.432Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "Experimental",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 1,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

`prevent_sharing_groups_outside_hierarchy`属性は、トップレベルグループのレスポンスにのみ存在します。

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`wiki_access_level`、`duo_features_enabled`、`lock_duo_features_enabled`、`duo_availability`、および`experiment_features_enabled`属性も表示されます。

### `shared_runners_setting`のオプション {#options-for-shared_runners_setting}

`shared_runners_setting`属性は、グループのサブグループとプロジェクトに対してインスタンスRunnerを有効にするかどうかを決定します。

| 値                        | 説明 |
|------------------------------|-------------|
| `enabled`                    | このグループ内のすべてのプロジェクトとサブグループに対して、インスタンスRunnerを有効にします。 |
| `disabled_and_overridable`   | このグループ内のすべてのプロジェクトとサブグループに対してインスタンスRunnerを無効にしますが、サブグループでこの設定を上書きできるようにします。 |
| `disabled_and_unoverridable` | このグループ内のすべてのプロジェクトとサブグループに対してインスタンスRunnerを無効にし、サブグループでこの設定を上書きできないようにします。 |
| `disabled_with_override`     | （非推奨。`disabled_and_overridable`を使用してください。）このグループ内のすべてのプロジェクトとサブグループに対してインスタンスRunnerを無効にしますが、サブグループでこの設定を上書きできるようにします。 |

## グループアバターを更新する {#update-group-avatars}

グループアバターを更新します。

### グループアバターをダウンロードする {#download-a-group-avatar}

グループアバターを取得します。グループが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /groups/:id/avatar
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのID。 |

例: 

```shell
curl --header "PRIVATE-TOKEN: $GITLAB_LOCAL_TOKEN" \
  --remote-header-name \
  --remote-name \
  "https://gitlab.example.com/api/v4/groups/4/avatar"
```

### グループアバターをアップロードする {#upload-a-group-avatar}

ファイルシステムからアバターファイルをアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例は次のとおりです。

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --form "avatar=@/tmp/example.png"
```

### グループアバターを削除する {#remove-a-group-avatar}

グループアバターを削除するには、`avatar`属性に空白値を使用します。

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --data "avatar="
```

## トークンを失効させる {#revoke-a-token}

{{< history >}}

- GitLab 17.2で`group_agnostic_token_revocation`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/371117)されました。デフォルトでは無効になっています。
- ユーザーフィードトークンの失効は、GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468599)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

トークンにグループ、またはそのサブグループとプロジェクトのいずれかへのアクセス権がある場合は、トークンを失効させます。トークンが失効した場合、またはすでに失効している場合は、その詳細がレスポンスで返されます。

次の条件を満たしている必要があります。

- このグループはトップレベルグループである必要があります。
- グループのオーナーロールを持っている必要があります。
- トークンタイプが次のいずれかである必要があります。
  - パーソナルアクセストークン
  - グループアクセストークン
  - プロジェクトアクセストークン
  - グループデプロイトークン
  - ユーザーフィードトークン

追加のトークンタイプが後日サポートされる可能性があります。

```plaintext
POST /groups/:id/tokens/revoke
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `token`   | 文字列            | はい      | プレーンテキストのトークン。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)とトークンのJSON表現を返します。返される属性は、トークンタイプによって異なります。

リクエストの例

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"token":"glpat-EXAMPLE"}' \
  --url "https://gitlab.example.com/api/v4/groups/63/tokens/revoke"
```

レスポンス例:

```json
{
    "id": 9,
    "name": "my-subgroup-deploytoken",
    "username": "gitlab+deploy-token-9",
    "expires_at": null,
    "scopes":
    [
        "read_repository",
        "read_package_registry",
        "write_package_registry"
    ],
    "revoked": true,
    "expired": false
}
```

## グループをLDAPと同期する {#sync-a-group-with-ldap}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

指定されたグループを、リンクされたLDAPグループと同期させます。

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

```plaintext
POST /groups/:id/ldap_sync
```

| 属性 | 型                | 必須 | 説明                            |
| --------- | ------------------- | -------- | -------------------------------------- |
| `id`      | 整数または文字列   | はい      | グループのID、またはURLエンコードされたパス。 |

<!--
### Credentials inventory management

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16343) in GitLab 18.1 [with a flag](../administration/feature_flags/_index.md) named `manage_pat_by_group_owners_ready`. Disabled by default.

{{< /history >}}

View, revoke, and rotate the credentials of enterprise users on GitLab.com.

Prerequisites:

- You must have the Owner role for the group.

#### List all personal access tokens for a group

Lists all personal access tokens associated with enterprise users in a top-level group.

```plaintext
GET /groups/:id/manage/personal_access_tokens
```

| Attribute          | Type                | Required | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | integer or string   | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `created_after`    | datetime (ISO 8601) | No       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | No       | If defined, returns tokens created before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | No       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | No       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | No       | If `true`, only returns revoked tokens. |
| `search`           | string              | No       | If defined, returns tokens that include the specified value in the name. |
| `state`            | string              | No       | If defined, returns tokens with the specified state. Possible values: `active` and `inactive`. |
| `sort`             | string              | No       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" "https://gitlab.example.com/api/v4/groups/1/manage/personal_access_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "Test Token",
    "revoked": false,
    "created_at": "2020-07-23T14:31:47.729Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 3,
    "last_used_at": "2021-10-06T17:58:37.550Z",
    "active": true,
    "expires_at": 2025-11-08
  }
]
```

#### List all group and project access tokens for a group

Lists all group and project access tokens associated with a top-level-group.

```plaintext
GET /groups/:id/manage/resource_access_tokens
```

| Attribute          | Type                | Required | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | integer or string   | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `created_after`    | datetime (ISO 8601) | No       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | No       | If defined, returns tokens created before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | No       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | No       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | No       | If `true`, only returns revoked tokens. |
| `search`           | string              | No       | If defined, returns tokens that include the specified value in the name. |
| `state`            | string              | No       | If defined, returns tokens with the specified state. Possible values: `active` and `inactive`. |
| `sort`             | string              | No       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" "https://gitlab.example.com/api/v4/groups/1/manage/resource_access_tokens"
```

Example response:

```json
[
  {
    "id": 12767703,
    "name": "Test Group Token",
    "revoked": false,
    "created_at": "2025-01-07T00:25:02.128Z",
    "description": "",
    "scopes": [
        "read_registry"
    ],
    "user_id": 25365147,
    "last_used_at": null,
    "active": true,
    "expires_at": "2025-06-19",
    "access_level": 10,
    "resource_type": "group",
    "resource_id": 77449520
  }
]
```

#### List all SSH keys for a group

Lists all SSH public keys associated with enterprise users in a top-level-group.

```plaintext
GET /groups/:id/manage/ssh_keys
```

| Attribute        | Type                | Required | Description |
| ---------------- | ------------------- | -------- | ----------- |
| `id`             | integer or string   | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `created_after`  | datetime (ISO 8601) | No       | If defined, returns SSH keys created after the specified time. |
| `created_before` | datetime (ISO 8601) | No       | If defined, returns SSH keys created before the specified time. |
| `expires_before` | datetime (ISO 8601) | No       | If defined, returns SSH keys that expire before the specified time. |
| `expires_after`  | datetime (ISO 8601) | No       | If defined, returns SSH keys that expire after the specified time. |

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" "https://gitlab.example.com/api/v4/groups/1/manage/ssh_keys"
```

Example response:

```json
[
  {
    "id":3,
    "title":"Sample key 3",
    "created_at":"2024-12-23T05:40:11.891Z",
    "expires_at":null,
    "last_used_at":"2024-13-23T05:40:11.891Z",
    "usage_type":"auth_and_signing",
    "user_id":3
  }
]
```

#### Revoke a personal access token for an enterprise user

Revokes a specified personal access token for an enterprise user.

```plaintext
DELETE groups/:id/manage/personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID of a personal access token or the keyword `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/personal_access_tokens/<personal_access_token_id>"
```

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.
- `403: Forbidden` if the access token does not have the required permissions.

#### Revoke a group or project access token for an enterprise user

Revokes a specified group or project access token for an enterprise user associated with the top-level group.

```plaintext
DELETE groups/:id/manage/resource_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID of a resource access token or the keyword `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/resource_access_tokens/<personal_access_token_id>"
```

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.
- `403: Forbidden` if the access token does not have the required permissions.

#### Delete an SSH key for an enterprise user

Deletes a specified SSH public key for an enterprise user associated with the top-level group.

```plaintext
DELETE /groups/:id/manage/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of existing key.  |

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if SSH Key is not deleted successfully.
- `401: Unauthorized` if the SSH Key is invalid.
- `403: Forbidden` if the user does not have the required permissions.

#### Rotate a personal access token for an enterprise user

Rotates a specified personal access token for an enterprise user associated with the top-level group. This revokes the previous token and creates a new token
that expires after one week.

```plaintext
POST groups/:id/manage/personal_access_tokens/:id/rotate
```

| Attribute | Type      | Required | Description         |
|-----------|-----------|----------|---------------------|
| `id` | integer or string | yes      | ID of a personal access token or the keyword `self`. |
| `expires_at` | date   | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date must be one year or less from the rotation date. If undefined, the token expires after one week. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/managepersonal_access_tokens/<personal_access_token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

If successful, returns `200: OK`.

Other possible responses:

- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if any of the following conditions are true:
  - The token does not exist.
  - The token has expired.
  - The token was revoked.
  - You do not have access to the specified token.
- `403: Forbidden` if the token is not allowed to rotate itself.
- `404: Not Found` if the user has the Owner role, but the token does not exist.
- `405: Method Not Allowed` if the token is not a personal access token.

#### Rotate a group or project access token for an enterprise user

Rotates a specified group or project access token for an enterprise user associated with the top-level group. This revokes the previous token and creates a new token
that expires after one week.

```plaintext
POST groups/:id/manage/resource_access_tokens/:id/rotate
```

| Attribute | Type      | Required | Description         |
|-----------|-----------|----------|---------------------|
| `id` | integer or string | yes      | ID of a personal access token or the keyword `self`. |
| `expires_at` | date   | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date must be one year or less from the rotation date. If undefined, the token expires after one week. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/manage/resource_access_tokens/<resource_access_token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

If successful, returns `200: OK`.

Other possible responses:

- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if any of the following conditions are true:
  - The token does not exist.
  - The token has expired.
  - The token was revoked.
  - You do not have access to the specified token.
- `403: Forbidden` if the token is not allowed to rotate itself or token is not a bot user token.
- `404: Not Found` if the user has the Owner role, but the token does not exist.
-->
