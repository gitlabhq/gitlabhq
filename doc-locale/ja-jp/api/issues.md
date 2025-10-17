---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabの課題に関するREST APIのドキュメント。
title: イシューAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イシューAPIを使用して、プログラムで[GitLabイシュー](../user/project/issues/_index.md)を読み取り、管理します。イシューAPIは次の処理を行います。

- プロジェクトとグループに関するイシューを作成、更新、削除する。
- 担当者、ラベル、マイルストーン、タイムトラッキングなどのイシューメタデータを管理する。
- イシューとマージリクエスト間の相互参照をサポートする。
- プロジェクトとエピック間のイシューの移動とプロモーションを追跡する。
- 認証チェックによりアクセスと表示レベルを制御する。

ユーザーが非公開プロジェクトのメンバーでない場合、そのプロジェクトに対する`GET`リクエストの結果はステータスコード`404`になります。

## イシューのページネーション {#issues-pagination}

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

{{< alert type="note" >}}

`references.relative`属性は、リクエストされるイシューのグループまたはプロジェクトに対して相対的です。プロジェクトからイシューがフェッチされるときの`relative`形式は、`short`形式と同じです。グループ全体またはプロジェクト全体にわたってリクエストされた場合、`full`形式と同じになると想定されます。

{{< /alert >}}

## イシューをリストする {#list-issues}

認証済みユーザーがアクセスできるすべてのイシューを取得します。デフォルトでは、現在のユーザーが作成したイシューのみが返されます。すべてのイシューを取得するには、パラメータ`scope=all`を使用します。

```plaintext
GET /issues
GET /issues?assignee_id=5
GET /issues?author_id=5
GET /issues?confidential=true
GET /issues?iids[]=42&iids[]=43
GET /issues?labels=foo
GET /issues?labels=foo,bar
GET /issues?labels=foo,bar&state=opened
GET /issues?milestone=1.0.0
GET /issues?milestone=1.0.0&state=opened
GET /issues?my_reaction_emoji=star
GET /issues?search=foo&in=title
GET /issues?state=closed
GET /issues?state=opened
```

サポートされている属性は以下のとおりです。

| 属性                       | 型          | 必須   | 説明                                                                                                                                         |
|---------------------------------|---------------| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `assignee_id`                   | 整数       | いいえ         | 指定されたユーザー`id`に割り当てられているイシューを返します。`assignee_username`と相互に排他的です。`None`は、未割り当てのイシューを返します。`Any`は、担当者がいるイシューを返します。 |
| `assignee_username`             | 文字列配列  | いいえ         | 指定された`username`に割り当てられているイシューを返します。`assignee_id`と類似しており、`assignee_id`と相互に排他的です。GitLab Community Edition（CE）では、`assignee_username`配列には単一値のみが含まれている必要があります。そうでない場合には、無効なパラメータエラーが返されます。 |
| `author_id`                     | 整数       | いいえ         | 指定されたユーザー`id`が作成したイシューを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`               | 文字列        | いいえ         | 指定された`username`が作成したイシューを返します。`author_id`と類似しており、`author_id`と相互に排他的です。 |
| `confidential`                  | ブール値       | いいえ         | 非公開イシューまたは公開イシューをフィルタリングします。                                                                                                               |
| `created_after`                 | 日時      | いいえ         | 指定時刻以降に作成されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `created_before`                | 日時      | いいえ         | 指定時刻以前に作成されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `due_date`                      | 文字列        | いいえ         | 期限がないイシュー、期限切れのイシュー、または期日が今週、今月、または2週間前から来月の間にあるイシューを返します。`0`（期限なし）、`any`、`today`、`tomorrow`、`overdue`、`week`、`month`、`next_month_and_previous_two_weeks`を指定できます。 |
| `epic_id`        | 整数       | いいえ         | 指定されたエピックIDに関連付けられているイシューを返します。`None`は、エピックに関連付けられていないイシューを返します。`Any`は、エピックに関連付けられているイシューを返します。PremiumおよびUltimateのみです。 |
| `health_status`  | 文字列        | いいえ         | 指定された`health_status`のイシューを返します。_（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/370721)されました）。_GitLab 15.5[以降](https://gitlab.com/gitlab-org/gitlab/-/issues/370721)では、`None`はヘルスステータスが割り当てられていないイシューを返し、`Any`はヘルスステータスが割り当てられているイシューを返します。Ultimateのみです。 |
| `iids[]`                        | 整数の配列 | いいえ         | 指定された`iid`を持つイシューのみを返します。                                                                                                       |
| `in`                            | 文字列        | いいえ         | `search`属性のスコープを変更します（`title`、`description`、またはこれらをカンマで結合した文字列）。デフォルトは`title,description`です。             |
| `issue_type`                    | 文字列        | いいえ         | 特定の種類のイシューに絞り込みます。`issue`、`incident`、`test_case`、`task`のいずれかです。 |
| `iteration_id`                  | 整数       | いいえ         | 指定されたイテレーションIDに割り当てられているイシューを返します。`None`は、イテレーションに属していないイシューを返します。`Any`は、イテレーションに属しているイシューを返します。`iteration_title`と相互に排他的です。PremiumおよびUltimateのみです。 |
| `iteration_title`               | 文字列        | いいえ       | 指定されたタイトルのイテレーションに割り当てられているイシューを返します。`iteration_id`と類似しており、`iteration_id`と相互に排他的です。PremiumおよびUltimateのみです。 |
| `labels`                        | 文字列        | いいえ         | ラベル名のカンマ区切りリスト。イシューが返されるようにするには、イシューにすべてのラベルが含まれている必要があります。`None`は、ラベルのないすべてのイシューをリストします。`Any`は、1つ以上のラベルがあるすべてのイシューをリストします。`No+Label`（非推奨）は、ラベルのないすべてのイシューをリストします。定義済みの名前では大文字と小文字が区別されません。 |
| `milestone_id`                  | 文字列        | いいえ         | 指定されたタイムボックス値（`None`、`Any`、`Upcoming`、`Started`）を持つマイルストーンに割り当てられているイシューを返します。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。`Upcoming`は、将来に期日があるマイルストーンに割り当てられているすべてのイシューをリストします。`Started`は、開始されたオープンなマイルストーンに割り当てられているすべてのイシューをリストします。`Upcoming`および`Started`のロジックは、[GraphQL API](../user/project/milestones/_index.md#special-milestone-filters)で使用されているロジックとは異なります。`milestone`と`milestone_id`は相互に排他的です。 |
| `milestone`                     | 文字列        | いいえ         | マイルストーンのタイトル。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。`None`または`Any`の使用は、[今後非推奨になる](https://gitlab.com/gitlab-org/gitlab/-/issues/336044)予定です。代わりに`milestone_id`属性を使用してください。`milestone`と`milestone_id`は相互に排他的です。 |
| `my_reaction_emoji`             | 文字列        | いいえ         | 認証済みユーザーが、指定された`emoji`でリアクションしたイシューを返します。`None`は、リアクションがないイシューを返します。`Any`は、1つ以上のリアクションがあるイシューを返します。 |
| `non_archived`                  | ブール値       | いいえ         | 非アーカイブ済みプロジェクトのイシューのみを返します。`false`の場合、応答ではアーカイブ済みプロジェクトと非アーカイブ済みプロジェクトの両方のイシューが返されます。デフォルトは`true`です。 |
| `not`                           | ハッシュ          | いいえ         | 指定されたパラメータに一致しないイシューを返します。`assignee_id`、`assignee_username`、`author_id`、`author_username`、`iids`、`iteration_id`、`iteration_title`、`labels`、`milestone`、`milestone_id`、および`weight`を指定できます。 |
| `order_by`                      | 文字列        | いいえ         | `created_at`、`due_date`、`label_priority`、`milestone_due`、`popularity`、`priority`、`relative_position`、`title`、`updated_at`、`weight`フィールドで並べ替えられたイシューを返します。デフォルトは`created_at`です。 |
| `scope`                         | 文字列        | いいえ         | 指定されたスコープ（`created_by_me`、`assigned_to_me`、または`all`）のイシューを返します。デフォルトは`created_by_me`です。 |
| `search`                        | 文字列        | いいえ         | `title`と`description`でイシューを検索します。                                                                                               |
| `sort`                          | 文字列        | いいえ         | `asc`または`desc`の順にソートされたイシューを返します。デフォルトは`desc`です。                                                                                    |
| `state`                         | 文字列        | いいえ         | `all`のイシューを返すか、または`opened`か`closed`のイシューのみを返します。                                                                                       |
| `updated_after`                 | 日時      | いいえ         | 指定時刻以降に更新されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `updated_before`                | 日時      | いいえ         | 指定時刻以前に更新されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `weight`                        | 整数       | いいえ         | 指定された`weight`のイシューを返します。`None`は、ウェイトが割り当てられていないイシューを返します。`Any`は、ウェイトが割り当てられているイシューを返します。PremiumおよびUltimateのみです。   |
| `with_labels_details`           | ブール値       | いいえ         | `true`の場合、応答では、labelsフィールドの各ラベルの詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues"
```

応答の例:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "author" : {
         "state" : "active",
         "id" : 18,
         "web_url" : "https://gitlab.example.com/eileen.lowe",
         "name" : "Alexandra Bashirian",
         "avatar_url" : null,
         "username" : "eileen.lowe"
      },
      "milestone" : {
         "project_id" : 1,
         "description" : "Ducimus nam enim ex consequatur cumque ratione.",
         "state" : "closed",
         "due_date" : null,
         "iid" : 2,
         "created_at" : "2016-01-04T15:31:39.996Z",
         "title" : "v4.0",
         "id" : 17,
         "updated_at" : "2016-01-04T15:31:39.996Z"
      },
      "project_id" : 1,
      "assignees" : [{
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      }],
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "type" : "ISSUE",
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "closed_at" : null,
      "closed_by" : null,
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "moved_to_id" : null,
      "iid" : 6,
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "imported":false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/6",
      "references": {
        "short": "#6",
        "relative": "my-group/my-project#6",
        "full": "my-group/my-project#6"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/1/issues/76",
         "notes":"http://gitlab.example.com/api/v4/projects/1/issues/76/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/1/issues/76/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/1",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "weight": null,
      ...
   }
]
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`iteration`プロパティが含まれます。

```json
{
   "iteration": {
      "id":90,
      "iid":4,
      "sequence":2,
      "group_id":162,
      "title":null,
      "description":null,
      "state":2,
      "created_at":"2022-03-14T05:21:11.929Z",
      "updated_at":"2022-03-14T05:21:11.929Z",
      "start_date":"2022-03-08",
      "due_date":"2022-03-14",
      "web_url":"https://gitlab.com/groups/my-group/-/iterations/90"
   }
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

## グループイシューをリストする {#list-group-issues}

グループのイシューのリストを取得します。

プライベートグループの場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /groups/:id/issues
GET /groups/:id/issues?assignee_id=5
GET /groups/:id/issues?author_id=5
GET /groups/:id/issues?confidential=true
GET /groups/:id/issues?iids[]=42&iids[]=43
GET /groups/:id/issues?labels=foo
GET /groups/:id/issues?labels=foo,bar
GET /groups/:id/issues?labels=foo,bar&state=opened
GET /groups/:id/issues?milestone=1.0.0
GET /groups/:id/issues?milestone=1.0.0&state=opened
GET /groups/:id/issues?my_reaction_emoji=star
GET /groups/:id/issues?search=issue+title+or+description
GET /groups/:id/issues?state=closed
GET /groups/:id/issues?state=opened
```

サポートされている属性は以下のとおりです。

| 属性           | 型             | 必須   | 説明                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 整数または文字列   | はい        | グループのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                 |
| `assignee_id`       | 整数          | いいえ         | 指定されたユーザー`id`に割り当てられているイシューを返します。`assignee_username`と相互に排他的です。`None`は、未割り当てのイシューを返します。`Any`は、担当者がいるイシューを返します。 |
| `assignee_username` | 文字列配列     | いいえ         | 指定された`username`に割り当てられているイシューを返します。`assignee_id`と類似しており、`assignee_id`と相互に排他的です。GitLab Community Edition（CE）では、`assignee_username`配列には単一値のみが含まれている必要があります。そうでない場合には、無効なパラメータエラーが返されます。 |
| `author_id`         | 整数          | いいえ         | 指定されたユーザー`id`が作成したイシューを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`   | 文字列           | いいえ         | 指定された`username`が作成したイシューを返します。`author_id`と類似しており、`author_id`と相互に排他的です。 |
| `confidential`     | ブール値          | いいえ         | 非公開イシューまたは公開イシューをフィルタリングします。                                                                                         |
| `created_after`     | 日時         | いいえ         | 指定時刻以降に作成されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `created_before`    | 日時         | いいえ         | 指定時刻以前に作成されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `due_date`          | 文字列           | いいえ         | 期限がないイシュー、期限切れのイシュー、または期日が今週、今月、または2週間前から来月の間にあるイシューを返します。`0`（期限なし）、`any`、`today`、`tomorrow`、`overdue`、`week`、`month`、`next_month_and_previous_two_weeks`を指定できます。 |
| `epic_id`           | 整数      | いいえ         | 指定されたエピックIDに関連付けられているイシューを返します。`None`は、エピックに関連付けられていないイシューを返します。`Any`は、エピックに関連付けられているイシューを返します。PremiumおよびUltimateのみです。 |
| `iids[]`            | 整数の配列    | いいえ         | 指定された`iid`を持つイシューのみを返します。                                                                                 |
| `issue_type`        | 文字列           | いいえ         | 特定の種類のイシューに絞り込みます。`issue`、`incident`、`test_case`、`task`のいずれかです。 |
| `iteration_id`      | 整数 | いいえ         | 指定されたイテレーションIDに割り当てられているイシューを返します。`None`は、イテレーションに属していないイシューを返します。`Any`は、イテレーションに属しているイシューを返します。`iteration_title`と相互に排他的です。PremiumおよびUltimateのみです。 |
| `iteration_title`   | 文字列 | いいえ       | 指定されたタイトルのイテレーションに割り当てられているイシューを返します。`iteration_id`と類似しており、`iteration_id`と相互に排他的です。PremiumおよびUltimateのみです。|
| `labels`            | 文字列           | いいえ         | ラベル名のカンマ区切りリスト。イシューが返されるようにするには、イシューにすべてのラベルが含まれている必要があります。`None`は、ラベルのないすべてのイシューをリストします。`Any`は、1つ以上のラベルがあるすべてのイシューをリストします。`No+Label`（非推奨）は、ラベルのないすべてのイシューをリストします。定義済みの名前では大文字と小文字が区別されません。 |
| `milestone`         | 文字列           | いいえ         | マイルストーンのタイトル。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。       |
| `my_reaction_emoji` | 文字列           | いいえ         | 認証済みユーザーが、指定された`emoji`でリアクションしたイシューを返します。`None`は、リアクションがないイシューを返します。`Any`は、1つ以上のリアクションがあるイシューを返します。 |
| `non_archived`      | ブール値          | いいえ         | 非アーカイブ済みプロジェクトのイシューを返します。デフォルトはtrueです。 |
| `not`               | ハッシュ             | いいえ         | 指定されたパラメータに一致しないイシューを返します。`labels`、`milestone`、`author_id`、`author_username`、`assignee_id`、`assignee_username`、`my_reaction_emoji`、`search`、`in`を指定できます。 |
| `order_by`          | 文字列           | いいえ         | `created_at`、`updated_at`、`priority`、`due_date`、`relative_position`、`label_priority`、`milestone_due`、`popularity`、`weight`フィールドで並べ替えられたイシューを返します。デフォルトは`created_at`です。                                                               |
| `scope`             | 文字列           | いいえ         | 指定されたスコープ（`created_by_me`、`assigned_to_me`、または`all`）のイシューを返します。デフォルトは`all`です。 |
| `search`            | 文字列           | いいえ         | `title`と`description`でグループイシューを検索します。                                                                   |
| `sort`              | 文字列           | いいえ         | `asc`または`desc`の順にソートされたイシューを返します。デフォルトは`desc`です。                                                              |
| `state`             | 文字列           | いいえ         | すべてのイシューを返すか、または`opened`または`closed`のイシューのみを返します。                                                                 |
| `updated_after`     | 日時         | いいえ         | 指定時刻以降に更新されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `updated_before`    | 日時         | いいえ         | 指定時刻以前に更新されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `weight` | 整数       | いいえ         | 指定された`weight`のイシューを返します。`None`は、ウェイトが割り当てられていないイシューを返します。`Any`は、ウェイトが割り当てられているイシューを返します。PremiumおよびUltimateのみです。 |
| `with_labels_details` | ブール値        | いいえ         | `true`の場合、応答では、labelsフィールドの各ラベルの詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues"
```

応答の例:

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : null,
      "closed_by" : null,
      "user_notes_count": 1,
      "due_date": null,
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "my-project#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

## プロジェクトイシューをリストする {#list-project-issues}

{{< history >}}

- キーセットページネーションのサポートは、GitLab 18.3で[導入](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/26555)されました。

{{< /history >}}

プロジェクトイシューのリストを取得します。

非公開プロジェクトの場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /projects/:id/issues
GET /projects/:id/issues?assignee_id=5
GET /projects/:id/issues?author_id=5
GET /projects/:id/issues?confidential=true
GET /projects/:id/issues?iids[]=42&iids[]=43
GET /projects/:id/issues?labels=foo
GET /projects/:id/issues?labels=foo,bar
GET /projects/:id/issues?labels=foo,bar&state=opened
GET /projects/:id/issues?milestone=1.0.0
GET /projects/:id/issues?milestone=1.0.0&state=opened
GET /projects/:id/issues?my_reaction_emoji=star
GET /projects/:id/issues?search=issue+title+or+description
GET /projects/:id/issues?state=closed
GET /projects/:id/issues?state=opened
```

サポートされている属性は以下のとおりです。

| 属性             | 型           | 必須 | 説明 |
| --------------------- | -------------- | -------- | ----------- |
| `id`                  | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `assignee_id`         | 整数        | いいえ       | 指定されたユーザー`id`に割り当てられているイシューを返します。`assignee_username`と相互に排他的です。`None`は、未割り当てのイシューを返します。`Any`は、担当者がいるイシューを返します。 |
| `assignee_username`   | 文字列配列   | いいえ       | 指定された`username`に割り当てられているイシューを返します。`assignee_id`と類似しており、`assignee_id`と相互に排他的です。GitLab Community Edition（CE）では、`assignee_username`配列には単一値のみが含まれている必要があります。そうでない場合には、無効なパラメータエラーが返されます。 |
| `author_id`           | 整数        | いいえ       | 指定されたユーザー`id`が作成したイシューを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`     | 文字列         | いいえ       | 指定された`username`が作成したイシューを返します。`author_id`と類似しており、`author_id`と相互に排他的です。 |
| `confidential`        | ブール値        | いいえ       | 非公開イシューまたは公開イシューをフィルタリングします。 |
| `created_after`       | 日時       | いいえ       | 指定時刻以降に作成されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `created_before`      | 日時       | いいえ       | 指定時刻以前に作成されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `due_date`            | 文字列         | いいえ       | 期限がないイシュー、期限切れのイシュー、または期日が今週、今月、または2週間前から来月の間にあるイシューを返します。`0`（期限なし）、`any`、`today`、`tomorrow`、`overdue`、`week`、`month`、`next_month_and_previous_two_weeks`を指定できます。 |
| `epic_id`             | 整数        | いいえ       | 指定されたエピックIDに関連付けられているイシューを返します。`None`は、エピックに関連付けられていないイシューを返します。`Any`は、エピックに関連付けられているイシューを返します。PremiumおよびUltimateのみです。 |
| `iids[]`              | 整数の配列  | いいえ       | 指定された`iid`を持つイシューのみを返します。 |
| `issue_type`          | 文字列         | いいえ       | 特定の種類のイシューに絞り込みます。`issue`、`incident`、`test_case`、`task`のいずれかです。 |
| `iteration_id`        | 整数        | いいえ       | 指定されたイテレーションIDに割り当てられているイシューを返します。`None`は、イテレーションに属していないイシューを返します。`Any`は、イテレーションに属しているイシューを返します。`iteration_title`と相互に排他的です。PremiumおよびUltimateのみです。 |
| `iteration_title`     | 文字列         | いいえ       | 指定されたタイトルのイテレーションに割り当てられているイシューを返します。`iteration_id`と類似しており、`iteration_id`と相互に排他的です。PremiumおよびUltimateのみです。 |
| `labels`              | 文字列         | いいえ       | ラベル名のカンマ区切りリスト。イシューが返されるようにするには、イシューにすべてのラベルが含まれている必要があります。`None`は、ラベルのないすべてのイシューをリストします。`Any`は、1つ以上のラベルがあるすべてのイシューをリストします。`No+Label`（非推奨）は、ラベルのないすべてのイシューをリストします。定義済みの名前では大文字と小文字が区別されません。 |
| `milestone`           | 文字列         | いいえ       | マイルストーンのタイトル。`None`は、マイルストーンのないすべてのイシューをリストします。`Any`は、割り当てられているマイルストーンがあるすべてのイシューをリストします。 |
| `my_reaction_emoji`   | 文字列         | いいえ       | 認証済みユーザーが、指定された`emoji`でリアクションしたイシューを返します。`None`は、リアクションがないイシューを返します。`Any`は、1つ以上のリアクションがあるイシューを返します。 |
| `not`                 | ハッシュ           | いいえ       | 指定されたパラメータに一致しないイシューを返します。`labels`、`milestone`、`author_id`、`author_username`、`assignee_id`、`assignee_username`、`my_reaction_emoji`、`search`、`in`を指定できます。 |
| `order_by`            | 文字列         | いいえ       | `created_at`、`updated_at`、`priority`、`due_date`、`relative_position`、`label_priority`、`milestone_due`、`popularity`、`weight`フィールドで並べ替えられたイシューを返します。デフォルトは`created_at`です。 |
| `scope`               | 文字列         | いいえ       | 指定されたスコープ（`created_by_me`、`assigned_to_me`、または`all`）のイシューを返します。デフォルトは`all`です。 |
| `search`              | 文字列         | いいえ       | `title`と`description`でプロジェクトイシューを検索します。 |
| `sort`                | 文字列         | いいえ       | `asc`または`desc`の順にソートされたイシューを返します。デフォルトは`desc`です。 |
| `state`               | 文字列         | いいえ       | すべてのイシューを返すか、または`opened`または`closed`のイシューのみを返します。 |
| `updated_after`       | 日時       | いいえ       | 指定時刻以降に更新されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `updated_before`      | 日時       | いいえ       | 指定時刻以前に更新されたイシューを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `weight`              | 整数        | いいえ       | 指定された`weight`のイシューを返します。`None`は、ウェイトが割り当てられていないイシューを返します。`Any`は、ウェイトが割り当てられているイシューを返します。PremiumおよびUltimateのみです。 |
| `with_labels_details` | ブール値        | いいえ       | `true`の場合、応答では、labelsフィールドの各ラベルの詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |
| `cursor`              | 文字列         | いいえ       | キーセットページネーションで使用されるパラメータ。 |

このエンドポイントは、オフセットベースと[キーセットベースの](rest/_index.md#keyset-based-pagination)ページネーションの両方をサポートしています。結果のページを連続してリクエストする場合は、キーセットページネーションを使用する必要があります。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues"
```

応答の例:

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : "2016-01-05T15:31:46.176Z",
      "closed_by" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

## 単一イシュー {#single-issue}

管理者のみ行えます。

単一イシューを取得します。

これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /issues/:id
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数 | はい      | イシューのID                 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues/41"
```

応答の例:

```json
{
  "id": 1,
  "milestone": {
    "due_date": null,
    "project_id": 4,
    "state": "closed",
    "description": "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
    "iid": 3,
    "id": 11,
    "title": "v3.0",
    "created_at": "2016-01-04T15:31:39.788Z",
    "updated_at": "2016-01-04T15:31:39.788Z",
    "closed_at": "2016-01-05T15:31:46.176Z"
  },
  "author": {
    "state": "active",
    "web_url": "https://gitlab.example.com/root",
    "avatar_url": null,
    "username": "root",
    "id": 1,
    "name": "Administrator"
  },
  "description": "Omnis vero earum sunt corporis dolor et placeat.",
  "state": "closed",
  "iid": 1,
  "assignees": [
    {
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/lennie",
      "state": "active",
      "username": "lennie",
      "id": 9,
      "name": "Dr. Luella Kovacek"
    }
  ],
  "assignee": {
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/lennie",
    "state": "active",
    "username": "lennie",
    "id": 9,
    "name": "Dr. Luella Kovacek"
  },
  "type": "ISSUE",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "title": "Ut commodi ullam eos dolores perferendis nihil sunt.",
  "updated_at": "2016-01-04T15:31:46.176Z",
  "created_at": "2016-01-04T15:31:46.176Z",
  "closed_at": null,
  "closed_by": null,
  "subscribed": false,
  "user_notes_count": 1,
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://example.com/my-group/my-project/issues/1",
  "references": {
    "short": "#1",
    "relative": "#1",
    "full": "my-group/my-project#1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "weight": null,
  "has_tasks": false,
  "_links": {
    "self": "http://gitlab.example:3000/api/v4/projects/1/issues/1",
    "notes": "http://gitlab.example:3000/api/v4/projects/1/issues/1/notes",
    "award_emoji": "http://gitlab.example:3000/api/v4/projects/1/issues/1/award_emoji",
    "project": "http://gitlab.example:3000/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "moved_to_id": null,
  "service_desk_reply_to": "service.desk@gitlab.com"
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic": {
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

[GitLab Ultimate](https://about.gitlab.com/pricing/)のユーザーは、`health_status`プロパティも参照できます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

## 単一プロジェクトイシュー {#single-project-issue}

単一プロジェクトイシューを取得します。

非公開プロジェクトの場合、またはイシューが非公開の場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /projects/:id/issues/:issue_iid
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/41"
```

応答の例:

```json
{
   "project_id" : 4,
   "milestone" : {
      "due_date" : null,
      "project_id" : 4,
      "state" : "closed",
      "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
      "iid" : 3,
      "id" : 11,
      "title" : "v3.0",
      "created_at" : "2016-01-04T15:31:39.788Z",
      "updated_at" : "2016-01-04T15:31:39.788Z",
      "closed_at" : "2016-01-05T15:31:46.176Z"
   },
   "author" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
   },
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "state" : "closed",
   "iid" : 1,
   "assignees" : [{
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   }],
   "assignee" : {
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   },
   "type" : "ISSUE",
   "labels" : [],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 41,
   "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
   "updated_at" : "2016-01-04T15:31:46.176Z",
   "created_at" : "2016-01-04T15:31:46.176Z",
   "closed_at" : null,
   "closed_by" : null,
   "subscribed": false,
   "user_notes_count": 1,
   "due_date": null,
   "imported": false,
   "imported_from": "none",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
   "references": {
     "short": "#1",
     "relative": "#1",
     "full": "my-group/my-project#1"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

[GitLab Ultimate](https://about.gitlab.com/pricing/)のユーザーは、`health_status`プロパティも参照できます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

## 新しいイシュー {#new-issue}

新しいプロジェクトイシューを作成します。

```plaintext
POST /projects/:id/issues
```

サポートされている属性は以下のとおりです。

| 属性                                 | 型           | 必須 | 説明  |
|-------------------------------------------|----------------|----------|--------------|
| `id`                                      | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `assignee_id`                             | 整数        | いいえ       | イシューを割り当てるユーザーのID。GitLab Freeでのみ表示されます。 |
| `assignee_ids`                            | 整数の配列  | いいえ       | イシューを割り当てるユーザーのID。PremiumおよびUltimateのみです。|
| `confidential`                            | ブール値        | いいえ       | イシューを非公開として設定します。デフォルトは`false`です。  |
| `created_at`                              | 文字列         | いいえ       | イシューが作成された日時。日時文字列（8601形式）。たとえば`2016-03-11T03:45:40Z`などです。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `description`                             | 文字列         | いいえ       | イシューの説明。1,048,576文字に制限されています。 |
| `discussion_to_resolve`                   | 文字列         | いいえ       | 解決するディスカッションのID。これにより、イシューにデフォルトの説明が入力され、ディスカッションが解決済みとしてマークされます。`merge_request_to_resolve_discussions_of`と組み合わせて使用します。 |
| `due_date`                                | 文字列         | いいえ       | 期限。`YYYY-MM-DD`形式の日時文字列。たとえば、`2016-03-11`などです。 |
| `epic_id`                                 | 整数 | いいえ | イシューを追加するエピックのID。有効な値は0以上です。PremiumおよびUltimateのみです。 |
| `epic_iid`                                | 整数 | いいえ | イシューを追加するエピックのIID。有効な値は0以上です（非推奨。APIバージョン5で[削除予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)）。PremiumおよびUltimateのみです。 |
| `iid`                                     | 整数または文字列 | いいえ       | プロジェクトイシューの内部ID（管理者またはプロジェクトオーナーの権限が必要です）。 |
| `issue_type`                              | 文字列         | いいえ       | イシューのタイプ。`issue`、`incident`、`test_case`、`task`のいずれかです。デフォルトは`issue`です。 |
| `labels`                                  | 文字列         | いいえ       | 新しいイシューに割り当てるラベル名のカンマ区切りリスト。ラベルがまだ存在しない場合、新しいプロジェクトラベルが作成され、イシューに割り当てられます。  |
| `merge_request_to_resolve_discussions_of` | 整数        | いいえ       | すべてのイシューを解決するマージリクエストのIID。これにより、イシューにデフォルトの説明が入力され、すべてのディスカッションが解決済みとしてマークされます。descriptionまたはtitleを渡すと、これらの値がデフォルト値よりも優先されます。|
| `milestone_id`                            | 整数        | いいえ       | イシューを割り当てるマイルストーンのグローバルID。マイルストーンに関連付けられている`milestone_id`を検索するには、マイルストーンが割り当てられているイシューを表示し、[APIを使用して](#single-project-issue)イシューの詳細取得します。 |
| `title`                                   | 文字列         | はい      | イシューのタイトル。 |
| `weight`                                  | 整数        | いいえ       | イシューのウェイト。有効な値は0以上です。PremiumおよびUltimateのみです。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug"
```

応答の例:

```json
{
   "project_id" : 4,
   "id" : 84,
   "created_at" : "2016-01-07T12:44:33.959Z",
   "iid" : 14,
   "title" : "Issues with auth",
   "state" : "opened",
   "assignees" : [],
   "assignee" : null,
   "type" : "ISSUE",
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
   },
   "description" : null,
   "updated_at" : "2016-01-07T12:44:33.959Z",
   "closed_at" : null,
   "closed_by" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": null,
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/14",
   "references": {
     "short": "#14",
     "relative": "#14",
     "full": "my-group/my-project#14"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

### レート制限 {#rate-limits}

不正利用を防ぐため、ユーザーに対して、1分あたりの`Create`リクエストの数を特定の数に制限できます。[イシューのレート制限](../administration/settings/rate_limit_on_issues_creation.md)を参照してください。

## イシューを編集する {#edit-an-issue}

既存のプロジェクトイシューを更新します。このリクエストは、（`state_event`で）イシューを完了または再オープンするためにも使用されます。

リクエストを成功させるには、以下のパラメータのうち少なくとも1つが必要です。

- `:assignee_id`
- `:assignee_ids`
- `:confidential`
- `:created_at`
- `:description`
- `:discussion_locked`
- `:due_date`
- `:issue_type`
- `:labels`
- `:milestone_id`
- `:state_event`
- `:title`

```plaintext
PUT /projects/:id/issues/:issue_iid
```

サポートされている属性は以下のとおりです。

| 属性      | 型    | 必須 | 説明                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`    | 整数 | はい      | プロジェクトイシューの内部ID。                                                                       |
| `add_labels`   | 文字列  | いいえ       | イシューに追加するラベル名のカンマ区切りリスト。ラベルがまだ存在しない場合、新しいプロジェクトラベルが作成され、イシューに割り当てられます。 |
| `assignee_ids` | 整数の配列 | いいえ | イシューを割り当てるユーザーのID。すべての担当者の割り当てを解除するには、`0`に設定するか、空の値を指定します。 |
| `confidential` | ブール値 | いいえ       | イシューを非公開として更新します。                                                                        |
| `description`  | 文字列  | いいえ       | イシューの説明。1,048,576文字に制限されています。        |
| `discussion_locked` | ブール値 | いいえ  | イシューのディスカッションがロックされているかどうかを示すフラグ。ディスカッションがロックされている場合、プロジェクトメンバーのみがコメントを追加または編集できます。 |
| `due_date`     | 文字列  | いいえ       | 期限。`YYYY-MM-DD`形式の日時文字列。たとえば、`2016-03-11`などです。                                           |
| `epic_id`      | 整数 | いいえ | イシューを追加するエピックのID。有効な値は0以上です。PremiumおよびUltimateのみです。 |
| `epic_iid`     | 整数 | いいえ | イシューを追加するエピックのIID。有効な値は0以上です（非推奨。APIバージョン5で[削除予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)）。PremiumおよびUltimateのみです。 |
| `issue_type`   | 文字列  | いいえ       | イシューのタイプを更新します。`issue`、`incident`、`test_case`、`task`のいずれかです。 |
| `labels`       | 文字列  | いいえ       | イシューのラベル名のカンマ区切りリスト。すべてのラベルの割り当てを解除するには、空の文字列に設定します。ラベルがまだ存在しない場合、新しいプロジェクトラベルが作成され、イシューに割り当てられます。 |
| `milestone_id` | 整数 | いいえ       | イシューの割り当て先マイルストーンのグローバルID。マイルストーンの割り当てを解除するには、`0`に設定するか、空の値を指定します。|
| `remove_labels`| 文字列  | いいえ       | イシューから削除するラベル名のカンマ区切りリスト。                                                       |
| `state_event`  | 文字列  | いいえ       | イシューの状態イベント。イシューを完了するには`close`を使用し、再度開くには`reopen`を使用します。                      |
| `title`        | 文字列  | いいえ       | イシューのタイトル。                                                                                      |
| `updated_at`   | 文字列  | いいえ       | イシューが更新された日時。日時文字列で、ISO 8601形式（`2016-03-11T03:45:40Z`など）です（管理者またはプロジェクトオーナーの権限が必要です）。空の文字列またはnull値は使用できません。|
| `weight`       | 整数 | いいえ       | イシューのウェイト。有効な値は0以上です。PremiumおよびUltimateのみです。           |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close"
```

応答の例:

```json
{
   "created_at" : "2016-01-07T12:46:01.410Z",
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "username" : "eileen.lowe",
      "id" : 18,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe"
   },
   "state" : "closed",
   "title" : "Issues with auth",
   "project_id" : 4,
   "description" : null,
   "updated_at" : "2016-01-07T12:55:16.213Z",
   "closed_at" : "2016-01-08T12:55:16.213Z",
   "closed_by" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
    },
   "iid" : 15,
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 85,
   "assignees" : [],
   "assignee" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": "2016-07-22",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/15",
   "references": {
     "short": "#15",
     "relative": "#15",
     "full": "my-group/my-project#15"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"

   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。{{< /alert >}}

## イシューを削除する {#delete-an-issue}

管理者とプロジェクトオーナーのみが利用できます。

イシューを削除します。

```plaintext
DELETE /projects/:id/issues/:issue_iid
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85"
```

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

## イシューを並べ替える {#reorder-an-issue}

イシューを並べ替えます。[イシューを手動でソート](../user/project/issues/sorting_issue_lists.md#manual-sorting)すると、結果を確認できます。

```plaintext
PUT /projects/:id/issues/:issue_iid/reorder
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |
| `move_after_id` | 整数 | いいえ | このイシューの後に配置するプロジェクトイシューのグローバルID。 |
| `move_before_id` | 整数 | いいえ | このイシューの前に配置するプロジェクトイシューのグローバルID。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/reorder?move_after_id=51&move_before_id=92"
```

## イシューを移動する {#move-an-issue}

イシューを別のプロジェクトに移動します。ターゲットプロジェクトがソースプロジェクトである場合、またはユーザーに十分な権限がない場合には、ステータスコードの`400`のエラーメッセージが返されます。

特定のラベルまたはマイルストーンがターゲットプロジェクトにも同じ名前で存在する場合、これは移動されるイシューに割り当てられます。

```plaintext
POST /projects/:id/issues/:issue_iid/move
```

サポートされている属性は以下のとおりです。

| 属性       | 型    | 必須 | 説明                          |
|-----------------|---------|----------|--------------------------------------|
| `id`            | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid`     | 整数 | はい      | プロジェクトイシューの内部ID。 |
| `to_project_id` | 整数 | はい      | 新しいプロジェクトのID。            |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form to_project_id=5 \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/move"
```

応答の例:

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

## イシューをクローンする {#clone-an-issue}

指定されたプロジェクトにイシューをクローンします。可能な限り多くのデータがコピーされます。ただし、ターゲットプロジェクトにラベルやマイルストーンなどの同等の条件が含まれている場合に限ります。

十分な権限がない場合、状態コード`400`のエラーメッセージが返されます。

```plaintext
POST /projects/:id/issues/:issue_iid/clone
```

サポートされている属性は以下のとおりです。

| 属性       | 型           | 必須               | 説明                       |
| --------------- | -------------- | ---------------------- | --------------------------------- |
| `id`            | 整数または文字列 | はい | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`     | 整数        | はい | プロジェクトイシューの内部ID。 |
| `to_project_id` | 整数        | はい | 新しいプロジェクトのID。            |
| `with_notes`    | ブール値        | いいえ | [ノート](notes.md)付きでイシューをクローンします。デフォルトは`false`です。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/1/clone?with_notes=true&to_project_id=6"
```

応答の例:

```json
{
  "id":290,
  "iid":1,
  "project_id":143,
  "title":"foo",
  "description":"closed",
  "state":"opened",
  "created_at":"2021-09-14T22:24:11.696Z",
  "updated_at":"2021-09-14T22:24:11.696Z",
  "closed_at":null,
  "closed_by":null,
  "labels":[

  ],
  "milestone":null,
  "assignees":[
    {
      "id":179,
      "name":"John Doe2",
      "username":"john",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/john"
    }
  ],
  "author":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "type":"ISSUE",
  "assignee":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "user_notes_count":1,
  "merge_requests_count":0,
  "upvotes":0,
  "downvotes":0,
  "due_date":null,
  "imported":false,
  "imported_from": "none",
  "confidential":false,
  "discussion_locked":null,
  "issue_type":"issue",
  "severity": "UNKNOWN",
  "web_url":"https://gitlab.example.com/namespace1/project2/-/issues/1",
  "time_stats":{
    "time_estimate":0,
    "total_time_spent":0,
    "human_time_estimate":null,
    "human_total_time_spent":null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "blocking_issues_count":0,
  "has_tasks":false,
  "_links":{
    "self":"https://gitlab.example.com/api/v4/projects/143/issues/1",
    "notes":"https://gitlab.example.com/api/v4/projects/143/issues/1/notes",
    "award_emoji":"https://gitlab.example.com/api/v4/projects/143/issues/1/award_emoji",
    "project":"https://gitlab.example.com/api/v4/projects/143",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "references":{
    "short":"#1",
    "relative":"#1",
    "full":"namespace1/project2#1"
  },
  "subscribed":true,
  "moved_to_id":null,
  "service_desk_reply_to":null
}
```

## 通知 {#notifications}

以下のリクエストは、イシューの[メール通知](../user/profile/notifications.md)に関連しています。

### イシューをサブスクライブする {#subscribe-to-an-issue}

認証済みユーザーが通知を受信できるように、イシューをサブスクライブさせます。ユーザーがすでにイシューをサブスクライブしている場合、ステータスコード`304`が返されます。

```plaintext
POST /projects/:id/issues/:issue_iid/subscribe
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe"
```

応答の例:

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`weight`プロパティが含まれます。

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

GitLab PremiumまたはUltimateのユーザーが作成したイシューには、`epic`プロパティが含まれます。

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimateのユーザーが作成したイシューには、`health_status`プロパティが含まれます。

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

{{< alert type="warning" >}}

`epic_iid`属性は非推奨であり、APIバージョン5で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)です。代わりに`epic`属性の`iid`を使用してください。{{< /alert >}}

### イシューのサブスクライブを解除する {#unsubscribe-from-an-issue}

イシューから通知を受信しないようにするため、認証済みユーザーをイシューからサブスクライブ解除します。ユーザーがイシューをサブスクライブしていない場合、ステータスコード`304`が返されます。

```plaintext
POST /projects/:id/issues/:issue_iid/unsubscribe
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe"
```

応答の例:

```json
{
  "id": 93,
  "iid": 12,
  "project_id": 5,
  "title": "Incidunt et rerum ea expedita iure quibusdam.",
  "description": "Et cumque architecto sed aut ipsam.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.217Z",
  "updated_at": "2016-04-07T13:02:37.905Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignee": {
    "name": "Edwardo Grady",
    "username": "keyon",
    "id": 21,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/3e6f06a86cf27fa8b56f3f74f7615987?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/keyon"
  },
  "type" : "ISSUE",
  "closed_at": null,
  "closed_by": null,
  "author": {
    "name": "Vivian Hermann",
    "username": "orville",
    "id": 11,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/orville"
  },
  "subscribed": false,
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/12",
  "references": {
    "short": "#12",
    "relative": "#12",
    "full": "my-group/my-project#12"
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

## To Doアイテムを作成する {#create-a-to-do-item}

イシューに関する現在のユーザーのTo Doアイテムを手動で作成します。そのイシューに関してユーザーのTo Doアイテムがすでに存在する場合、ステータスコード`304`が返されます。

```plaintext
POST /projects/:id/issues/:issue_iid/todo
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/todo"
```

応答の例:

```json
{
  "id": 112,
  "project": {
    "id": 5,
    "name": "GitLab CI/CD",
    "name_with_namespace": "GitLab Org / GitLab CI/CD",
    "path": "gitlab-ci",
    "path_with_namespace": "gitlab-org/gitlab-ci"
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "Issue",
  "target": {
    "id": 93,
    "iid": 10,
    "project_id": 5,
    "title": "Vel voluptas atque dicta mollitia adipisci qui at.",
    "description": "Tempora laboriosam sint magni sed voluptas similique.",
    "state": "closed",
    "created_at": "2016-06-17T07:47:39.486Z",
    "updated_at": "2016-07-01T11:09:13.998Z",
    "labels": [],
    "milestone": {
      "id": 26,
      "iid": 1,
      "project_id": 5,
      "title": "v0.0",
      "description": "Accusantium nostrum rerum quae quia quis nesciunt suscipit id.",
      "state": "closed",
      "created_at": "2016-06-17T07:47:33.832Z",
      "updated_at": "2016-06-17T07:47:33.832Z",
      "due_date": null
    },
    "assignees": [{
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    }],
    "assignee": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    },
    "type" : "ISSUE",
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
    },
    "subscribed": true,
    "user_notes_count": 7,
    "upvotes": 0,
    "downvotes": 0,
    "merge_requests_count": 0,
    "due_date": null,
    "web_url": "http://gitlab.example.com/my-group/my-project/issues/10",
    "references": {
      "short": "#10",
      "relative": "#10",
      "full": "my-group/my-project#10"
    },
    "confidential": false,
    "discussion_locked": false,
    "issue_type": "issue",
    "severity": "UNKNOWN",
    "task_completion_status":{
       "count":0,
       "completed_count":0
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/issues/10",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```

{{< alert type="warning" >}}

`assignee`列は非推奨になりました。GitLab EE APIに準拠するように、シングルサイズの配列`assignees`として表示されるようになりました。

{{< /alert >}}

## イシューをエピックにプロモートする {#promote-an-issue-to-an-epic}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イシューをエピックにプロモートするには、`/promote`[クイックアクション](../user/project/quick_actions.md)を含むコメントを追加します。

イシューをエピックにプロモートする方法について詳しくは、[イシューをエピックにプロモートする](../user/project/issues/managing_issues.md#promote-an-issue-to-an-epic)を参照してください。

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

サポートされている属性は以下のとおりです。

| 属性   | 型           | 必須 | 説明 |
| :---------- | :------------- | :------- | :---------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | プロジェクトイシューの内部ID。 |
| `body`      | 文字列         | はい      | ノートのコンテンツ。新しい行の先頭に`/promote`が含まれている必要があります。ノートに`/promote`のみが含まれている場合は、イシューをプロモートしますが、コメントは追加しません。それ以外の場合、コメントは他の行で構成されます。|

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=Lets%20promote%20this%20to%20an%20epic%0A%0A%2Fpromote"
```

応答の例:

```json
{
   "id":699,
   "type":null,
   "body":"Lets promote this to an epic",
   "attachment":null,
   "author": {
      "id":1,
      "name":"Alexandra Bashirian",
      "username":"eileen.lowe",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url":"https://gitlab.example.com/eileen.lowe"
   },
   "created_at":"2020-12-03T12:27:17.844Z",
   "updated_at":"2020-12-03T12:27:17.844Z",
   "system":false,
   "noteable_id":461,
   "noteable_type":"Issue",
   "resolvable":false,
   "confidential":false,
   "noteable_iid":33,
   "commands_changes": {
      "promote_to_epic":true
   }
}
```

## タイムトラッキング {#time-tracking}

次のリクエストは、イシューの[タイムトラッキング](../user/project/time_tracking.md)に関連しています。

### イシューの推定時間を設定する {#set-a-time-estimate-for-an-issue}

このイシューの推定作業時間を設定します。

```plaintext
POST /projects/:id/issues/:issue_iid/time_estimate
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | 文字列  | はい      | 人間が読める形式での期間。たとえば、`3h30m`などです。 |
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。      |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。     |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m"
```

応答の例:

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

### イシューの推定時間をリセットする {#reset-the-time-estimate-for-an-issue}

このイシューの推定時間を0秒にリセットします。

```plaintext
POST /projects/:id/issues/:issue_iid/reset_time_estimate
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate"
```

応答の例:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

### イシューにかかった時間を追加する {#add-spent-time-for-an-issue}

このイシューにかかった時間を追加します。

```plaintext
POST /projects/:id/issues/:issue_iid/add_spent_time
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | 文字列  | はい      | 人間が読める形式での期間。たとえば`3h30m`などです。 |
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。    |
| `summary`   | 文字列  | いいえ       | かかった時間の概要。  |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h"
```

応答の例:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

### イシューにかかった時間をリセットする {#reset-spent-time-for-an-issue}

このイシューにかかった合計時間を0秒にリセットします。

```plaintext
POST /projects/:id/issues/:issue_iid/reset_spent_time
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time"
```

応答の例:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

### タイムトラッキング統計を取得する {#get-time-tracking-stats}

人間が読める形式（`1h30m`など）かつ秒単位で、イシューのタイムトラッキング統計を取得します。

非公開プロジェクトの場合、またはイシューが非公開の場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /projects/:id/issues/:issue_iid/time_stats
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats"
```

応答の例:

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

## マージリクエスト {#merge-requests}

次のリクエストは、イシューとマージリクエスト間の関係に関連しています。

### イシューに関連するマージリクエストをリストする {#list-merge-requests-related-to-issue}

イシューに関連するすべてのマージリクエストを取得します。

非公開プロジェクトの場合、またはイシューが非公開の場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /projects/:id/issues/:issue_iid/related_merge_requests
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/related_merge_requests"
```

応答の例:

```json
[
  {
    "id": 29,
    "iid": 11,
    "project_id": 1,
    "title": "Provident eius eos blanditiis consequatur neque odit.",
    "description": "Ut consequatur ipsa aspernatur quisquam voluptatum fugit. Qui harum corporis quo fuga ut incidunt veritatis. Autem necessitatibus et harum occaecati nihil ea.\r\n\r\ntwitter/flight#8",
    "state": "opened",
    "created_at": "2018-09-18T14:36:15.510Z",
    "updated_at": "2018-09-19T07:45:13.089Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "v2.x",
    "source_branch": "so_long_jquery",
    "user_notes_count": 9,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 14,
      "name": "Verna Hills",
      "username": "lawanda_reinger",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/de68a91aeab1cff563795fb98a0c2cc0?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/lawanda_reinger"
    },
    "assignee": {
      "id": 19,
      "name": "Jody Baumbach",
      "username": "felipa.kuvalis",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/felipa.kuvalis"
    },
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 1,
      "title": "v1.0",
      "description": "Et tenetur voluptatem minima doloribus vero dignissimos vitae.",
      "state": "active",
      "created_at": "2018-09-18T14:35:44.353Z",
      "updated_at": "2018-09-18T14:35:44.353Z",
      "due_date": null,
      "start_date": null,
      "web_url": "https://gitlab.example.com/twitter/flight/milestones/2"
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "cannot_be_merged",
    "sha": "3b7b528e9353295c1c125dad281ac5b5deae5f12",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "reference": "!11",
    "web_url": "https://gitlab.example.com/twitter/flight/merge_requests/4",
    "references": {
      "short": "!4",
      "relative": "!4",
      "full": "twitter/flight!4"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "changes_count": "10",
    "latest_build_started_at": "2018-12-05T01:16:41.723Z",
    "latest_build_finished_at": "2018-12-05T02:35:54.046Z",
    "first_deployed_to_production_at": null,
    "pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.com/gitlab-org/gitlab/pipelines/38980952"
    },
    "head_pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.example.com/twitter/flight/pipelines/38980952",
      "before_sha": "3c738a37eb23cf4c0ed0d45d6ddde8aad4a8da51",
      "tag": false,
      "yaml_errors": null,
      "user": {
        "id": 19,
        "name": "Jody Baumbach",
        "username": "felipa.kuvalis",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/felipa.kuvalis"
      },
      "created_at": "2018-12-05T01:16:13.342Z",
      "updated_at": "2018-12-05T02:35:54.086Z",
      "started_at": "2018-12-05T01:16:41.723Z",
      "finished_at": "2018-12-05T02:35:54.046Z",
      "committed_at": null,
      "duration": 4436,
      "coverage": "46.68",
      "detailed_status": {
        "icon": "status_warning",
        "text": "passed",
        "label": "passed with warnings",
        "group": "success-with-warnings",
        "tooltip": "passed",
        "has_details": true,
        "details_path": "/twitter/flight/pipelines/38",
        "illustration": null,
        "favicon": "https://gitlab.example.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
      }
    },
    "diff_refs": {
      "base_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb",
      "head_sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "start_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb"
    },
    "merge_error": null,
    "user": {
      "can_merge": true
    }
  }
]
```

### マージ時に特定のイシューをクローズするマージリクエストをリストする {#list-merge-requests-that-close-a-particular-issue-on-merge}

マージされたときに特定のイシューをクローズするすべてのマージリクエストを取得します。

非公開プロジェクトの場合、またはイシューが非公開の場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /projects/:id/issues/:issue_iid/closed_by
```

サポートされている属性は以下のとおりです。

| 属性   | 型           | 必須 | 説明                        |
| ----------- | ---------------| -------- | ---------------------------------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by"
```

応答の例:

```json
[
  {
    "id": 6471,
    "iid": 6432,
    "project_id": 1,
    "title": "add a test for cgi lexer options",
    "description": "closes #11",
    "state": "opened",
    "created_at": "2017-04-06T18:33:34.168Z",
    "updated_at": "2017-04-09T20:10:24.983Z",
    "target_branch": "main",
    "source_branch": "feature.custom-highlighting",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "assignee": null,
    "source_project_id": 1,
    "target_project_id": 1,
    "closed_at": null,
    "closed_by": null,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "sha": "5a62481d563af92b8e32d735f2fa63b94e806835",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/6432",
    "reference": "!6432",
    "references": {
      "short": "!6432",
      "relative": "!6432",
      "full": "gitlab-org/gitlab-test!6432"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## イシューの参加者をリストする {#list-participants-in-an-issue}

イシューの参加者であるユーザーをリストします。

非公開プロジェクトの場合、またはイシューが非公開の場合は、認証のために認証情報を提供する必要があります。これには、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して行うことをおすすめします。

```plaintext
GET /projects/:id/issues/:issue_iid/participants
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/participants"
```

応答の例:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user1"
  },
  {
    "id": 5,
    "name": "John Doe5",
    "username": "user5",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/4aea8cf834ed91844a2da4ff7ae6b491?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user5"
  }
]
```

## イシューに関するコメント {#comments-on-issues}

[ノートAPI](notes.md)を使用してコメントを操作します。

## ユーザーエージェントの詳細を取得する {#get-user-agent-details}

管理者のみが利用できます。

イシューを作成したユーザーのユーザーエージェント文字列とIPを取得します。スパムの追跡に使用されます。

```plaintext
GET /projects/:id/issues/:issue_iid/user_agent_detail
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail"
```

応答の例:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

## イシューの状態イベントをリストする {#list-issue-state-events}

どの状態が設定されたか、誰がその操作を行ったか、それがいつ発生したかを追跡するには、[Resource state events API](resource_state_events.md#issues)を使用します。

## インシデント {#incidents}

以下のリクエストは、[インシデント](../operations/incident_management/incidents.md)でのみ利用可能です。

### メトリクスの画像をアップロードする {#upload-metric-image}

[インシデント](../operations/incident_management/incidents.md)でのみ利用可能です。

インシデントの**メトリクス**タブに表示するメトリクスチャートのスクリーンショットをアップロードします。画像をアップロードするときに、画像をテキストまたは元のグラフへのリンクに関連付けることができます。URLを追加すると、アップロードされた画像の上にあるハイパーリンクを選択して、元のグラフにアクセスできます。

```plaintext
POST /projects/:id/issues/:issue_iid/metric_images
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |
| `file` | ファイル | はい      | アップロードされる画像ファイル。 |
| `url` | 文字列 | いいえ      | 詳細なメトリクスの情報を表示するためのURL。 |
| `url_text` | 文字列 | いいえ      | 画像またはURLの説明。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

応答の例:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### メトリクスの画像をリストする {#list-metric-images}

[インシデント](../operations/incident_management/incidents.md)でのみ利用可能です。

インシデントの**メトリクス**タブに表示されるメトリクスチャートのスクリーンショットをリストします。

```plaintext
GET /projects/:id/issues/:issue_iid/metric_images
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

応答の例:

```json
[
    {
        "id": 17,
        "created_at": "2020-11-12T20:07:58.156Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/17/sample_2054.png",
        "url": "example.com/metric"
    },
    {
        "id": 18,
        "created_at": "2020-11-12T20:14:26.441Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/18/sample_2054.png",
        "url": "example.com/metric"
    }
]
```

### メトリクスの画像を更新する {#update-metric-image}

[インシデント](../operations/incident_management/incidents.md)でのみ利用可能です。

インシデントの**メトリクス**タブに表示されるメトリクスチャートのスクリーンショットの属性を編集します。

```plaintext
PUT /projects/:id/issues/:issue_iid/metric_images/:image_id
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |
| `image_id` | 整数 | はい      | 画像のID。 |
| `url` | 文字列 | いいえ      | 詳細なメトリクスの情報を表示するためのURL。 |
| `url_text` | 文字列 | いいえ      | 画像またはURLの説明。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

応答の例:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### メトリクスの画像を削除する {#delete-metric-image}

[インシデント](../operations/incident_management/incidents.md)でのみ利用可能です。

インシデントの**メトリクス**タブに表示するメトリクスチャートのスクリーンショットを削除します。

```plaintext
DELETE /projects/:id/issues/:issue_iid/metric_images/:image_id
```

サポートされている属性は以下のとおりです。

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのグローバルIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `issue_iid` | 整数 | はい      | プロジェクトイシューの内部ID。 |
| `image_id` | 整数 | はい      | 画像のID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

次のステータスコードを返すことができます。

- 画像が正常に削除された場合は`204 No Content`。
- 画像を削除できなかった場合は`400 Bad Request`。
