---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトフォーク 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabプロジェクトのフォークを管理します。詳細については、[forks](../user/project/repository/forking_workflow.md)（../user/project/repository/forking_workflow.md）を参照してください。

## プロジェクトをフォークする {#fork-a-project}

個人のネームスペースまたは指定されたネームスペースにプロジェクトをフォークします。

前提要件: 

- 認証済みである必要があります。

プロジェクトのフォーク操作は非同期で、バックグラウンドジョブで完了します。リクエストはすぐに返されます。プロジェクトのフォークが完了したかどうかを判断するには、新しいプロジェクトの`import_status`をクエリします。

```plaintext
POST /projects/:id/fork
```

| 属性                | 型              | 必須 | 説明 |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branches`               | 文字列            | いいえ       | ブランチをフォークします（すべてのブランチの場合は空）。 |
| `description`            | 文字列            | いいえ       | フォーク後に結果として得られるプロジェクトに割り当てられた説明。 |
| `mr_default_target_self` | ブール値           | いいえ       | フォークされたプロジェクトの場合、マージリクエストのターゲットをこのプロジェクトに設定します。`false`の場合、ターゲットはアップストリームプロジェクトになります。 |
| `name`                   | 文字列            | いいえ       | フォーク後に結果として得られるプロジェクトに割り当てられた名前。 |
| `namespace_id`           | 整数           | いいえ       | プロジェクトのフォーク先のネームスペースのID。 |
| `namespace_path`         | 文字列            | いいえ       | プロジェクトのフォーク先のネームスペースのパス。 |
| `namespace`              | 整数または文字列 | いいえ       | _（非推奨）_プロジェクトのフォーク先のネームスペースのIDまたはパス。 |
| `path`                   | 文字列            | いいえ       | フォーク後に結果として得られるプロジェクトに割り当てられたパス。 |
| `visibility`             | 文字列            | いいえ       | フォーク後に結果として得られるプロジェクトに割り当てられた[表示レベル](projects.md#project-visibility-level)。 |

## プロジェクトのフォークの一覧 {#list-forks-of-a-project}

指定されたプロジェクトとの間に確立されたフォークした関係を持つ、アクセス可能なプロジェクトを一覧表示します。

```plaintext
GET /projects/:id/forks
```

サポートされている属性は以下のとおりです:

| 属性                     | 型              | 必須 | 説明 |
|:------------------------------|:------------------|:---------|:------------|
| `id`                          | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `archived`                    | ブール値           | いいえ       | アーカイブ状態で制限します。 |
| `membership`                  | ブール値           | いいえ       | 現在のユーザーがメンバーであるプロジェクトで制限します。 |
| `min_access_level`            | 整数           | いいえ       | 現在のユーザーの最小[ロール（`access_level`）](members.md#roles)で制限します。 |
| `order_by`                    | 文字列            | いいえ       | `id`、`name`、`path`、`created_at`、`updated_at`、`star_count`、または`last_activity_at`のフィールドで並べ替えられたプロジェクトを返します。デフォルトは`created_at`です。 |
| `owned`                       | ブール値           | いいえ       | 現在のユーザーが明示的に所有するプロジェクトで制限します。 |
| `search`                      | 文字列            | いいえ       | 検索条件に一致するプロジェクトのリストを返します。 |
| `simple`                      | ブール値           | いいえ       | プロジェクトごとに制限されたフィールドのみを返します。認証がない場合、このオペレーションは何も行いません。単純なフィールドのみが返されます。 |
| `sort`                        | 文字列            | いいえ       | `asc`または`desc`の順にソートされたプロジェクトを返します。デフォルトは`desc`です。 |
| `starred`                     | ブール値           | いいえ       | 現在のユーザーがお気に入りに登録したプロジェクトで制限します。 |
| `statistics`                  | ブール値           | いいえ       | プロジェクトの統計を含めます。レポーター以上のロールを持つユーザーのみが利用できます。 |
| `updated_after`               | 日時          | いいえ       | 指定された時刻以降に最終更新が行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）。GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393979)されました。 |
| `updated_before`              | 日時          | いいえ       | 指定された時刻以前に最終更新が行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）。GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393979)されました。 |
| `visibility`                  | 文字列            | いいえ       | 表示レベル（`public`、`internal`、`private`）で制限します。 |
| `with_custom_attributes`      | ブール値           | いいえ       | 応答に[カスタム属性](custom_attributes.md)を含めます。_（管理者のみ）_ |
| `with_issues_enabled`         | ブール値           | いいえ       | 有効になっているイシュー機能で制限します。 |
| `with_merge_requests_enabled` | ブール値           | いいえ       | 有効になっているマージリクエスト機能で制限します。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/forks"
```

レスポンス例:

```json
[
  {
    "id": 3,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "internal",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
    "web_url": "http://example.com/diaspora/diaspora-project-site",
    "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora project"
    ],
    "topics": [
      "example",
      "disapora project"
    ],
    "name": "Diaspora Project Site",
    "name_with_namespace": "Diaspora / Diaspora Project Site",
    "path": "diaspora-project-site",
    "path_with_namespace": "diaspora/diaspora-project-site",
    "repository_object_format": "sha1",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": true,
    "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 1,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## プロジェクト間のフォーク関係の作成 {#create-a-fork-relationship-between-projects}

プロジェクト間のフォーク関係を作成します。

前提要件: 

- 管理者であるか、プロジェクトのオーナーロールが割り当てられている必要があります。

```plaintext
POST /projects/:id/fork/:forked_from_id
```

サポートされている属性は以下のとおりです:

| 属性        | 型              | 必須 | 説明 |
|:-----------------|:------------------|:---------|:------------|
| `forked_from_id` | ID                | はい      | フォーク元のプロジェクトのID。 |
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

## プロジェクト間のフォーク関係の削除 {#delete-a-fork-relationship-between-projects}

プロジェクト間のフォーク関係を削除します。

前提要件: 

- 管理者であるか、プロジェクトのオーナーロールが割り当てられている必要があります。

```plaintext
DELETE /projects/:id/fork
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
