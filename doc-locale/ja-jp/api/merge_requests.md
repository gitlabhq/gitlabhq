---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabのマージリクエストのREST APIのドキュメント。
title: マージリクエストAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- Do not remove these outdated lines until the changes are actually implemented in the API -->

{{< history >}}

- `reference`はGitLab 12.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)になりました。
- `merged_by`はGitLab 14.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)になりました。
- `merge_status`はGitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204)になり、代わりに`detailed_merge_status`が推奨されます。
- GitLab 15.11で`with_merge_status_recheck`が[変更され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115948) 、権限が不十分なユーザーからのリクエストに対して無視されるように[フラグ](../administration/feature_flags/_index.md) `restrict_merge_status_recheck`が追加されました。デフォルトでは無効になっています。
- `approvals_before_merge`はGitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119503)になりました。
- `prepared_at`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122001)されました。
- GitLab 17.0で`merge_user_id`が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)。
- GitLab 17.0で`merge_user_username`が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)。
- GitLab 17.2で`order_by`の`merged_at`値が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)。
- `merge_after`はGitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165092)されました。
- `security_policy_violations`は、GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/473704)になりました。機能フラグ`policy_mergability_check`は削除されました。
- GitLab 19.0で`draft`フィルターパラメータが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098)。
- GitLab 19.0で、`wip`フィルターパラメータは[非推奨となりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098)。

{{< /history >}}

このAPIで[マージリクエスト](../user/project/merge_requests/_index.md)を管理します。次のことができます: 

- コードレビュープロセスの一部を自動化します。
- コードの変更を外部ツールに接続します。
- マージリクエスト情報を、お好みのフォーマットでGitLab以外のシステムに送信します。
- 外部システムからのデータに基づいて、マージリクエストを更新、承認、マージ、またはブロックします。

非公開情報に対するすべてのAPIコールには、認証が必要です。

## API v5での削除 {#removals-in-api-v5}

The `approvals_before_merge`属性は非推奨であり、API v5で[マージリクエスト承認API](merge_request_approvals.md)を優先して[削除予定](rest/deprecations.md)です。

## マージリクエストのリストを取得する {#list-merge-requests}

認証済みユーザーがアクセスできるすべてのマージリクエストをリストします。デフォルトでは、現在のユーザーが作成したマージリクエストのみを返します。すべてのマージリクエストを取得するには`scope=all`を使用します。

`state`パラメータを使用して、指定された状態（`opened`、`closed`、`locked`、`merged`）のマージリクエストのみを取得するか、すべての状態（`all`）のマージリクエストを取得します。`locked`は短期間であり一時的なため、通常、この状態で検索すると結果は返されません。マージリクエストのリストを制限するには、ページネーションパラメータ`page`と`per_page`を使用します。

```plaintext
GET /merge_requests
GET /merge_requests?state=opened
GET /merge_requests?state=all
GET /merge_requests?milestone=release
GET /merge_requests?labels=bug,reproduced
GET /merge_requests?author_id=5
GET /merge_requests?author_username=gitlab-bot
GET /merge_requests?my_reaction_emoji=star
GET /merge_requests?scope=assigned_to_me
GET /merge_requests?scope=reviews_for_me
GET /merge_requests?search=foo&in=title
```

サポートされている属性は以下のとおりです: 

| 属性                   | 型          | 必須 | 説明 |
|-----------------------------|---------------|----------|-------------|
| `approved_by_ids[]`         | 整数の配列 | いいえ       | 指定された`id`を持つすべてのユーザー（最大5人のユーザー）が承認したマージリクエストを返します。`None`は承認のないマージリクエストを返します。`Any`は承認のあるマージリクエストを返します。 |
| `approved_by_usernames[]`   | 文字列配列  | いいえ       | 指定された`username`を持つすべてのユーザー（最大5人のユーザー）が承認したマージリクエストを返します。`None`は承認のないマージリクエストを返します。`Any`は承認のあるマージリクエストを返します。 |
| `approver_ids[]`            | 整数の配列 | いいえ       | 指定された`id`IDを持つすべてのユーザーが、承認ルールに従って適格な承認者であるマージリクエストを返します。`None`は適格な承認者がいないマージリクエストを返し、`Any`は少なくとも1人の適格な承認者がいるマージリクエストを返します。PremiumおよびUltimateのみです。 |
| `assignee_id`               | 整数または文字列 | いいえ   | 指定されたユーザー`id`に割り当てられたマージリクエストを返します。`None`は未割り当てのマージリクエストを返します。`Any`は担当者に割り当てられているマージリクエストを返します。`assignee_username`と相互に排他的です。 |
| `assignee_username[]`       | 文字列配列  | いいえ       | 指定されたユーザー名に割り当てられたマージリクエストを返します。`assignee_id`と相互に排他的です。 |
| `author_id`                 | 整数       | いいえ       | 指定されたユーザー`id`が作成したマージリクエストを返します。`author_username`と相互に排他的です。`scope=all`または`scope=assigned_to_me`と組み合わせて指定します。 |
| `author_username`           | 文字列        | いいえ       | 指定された`username`が作成したマージリクエストを返します。`author_id`と相互に排他的です。 |
| `created_after`             | 日時      | いいえ       | 指定された日時以降に作成されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before`            | 日時      | いいえ       | 指定された日時以前に作成されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `deployed_after`            | 日時      | いいえ       | 指定された日時より後にデプロイされたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `deployed_before`           | 日時      | いいえ       | 指定された日時より前にデプロイされたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `environment`               | 文字列        | いいえ       | 指定された環境にデプロイされたマージリクエストを返します。 |
| `in`                        | 文字列        | いいえ       | `search`属性のスコーピングを変更します（`title`、`description`、またはこれらをカンマで結合した文字列）。デフォルトは`title,description`です。 |
| `labels`                    | 文字列        | いいえ       | カンマ区切りのラベルのリストに一致するマージリクエストを返します。`None`は、ラベルのないすべてのマージリクエストをリストします。`Any`は、少なくとも1つのラベルを持つすべてのマージリクエストをリストします。定義済みの名前では大文字と小文字が区別されません。 |
| `merge_user_id`             | 整数       | いいえ       | 指定されたユーザー`id`によってマージされたマージリクエストを返します。`merge_user_username`と相互に排他的です。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)されました。 |
| `merge_user_username`       | 文字列        | いいえ       | 指定された`username`を持つユーザーによってマージされたマージリクエストを返します。`merge_user_id`と相互に排他的です。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)されました。 |
| `milestone`                 | 文字列        | いいえ       | 特定のマイルストーンに対するマージリクエストを返します。`None`は、マイルストーンのないマージリクエストをリストします。`Any`は、割り当てられたマイルストーンを持つマージリクエストをリストします。 |
| `my_reaction_emoji`         | 文字列        | いいえ       | 認証されたユーザーが、指定された`emoji`でリアクションしたマージリクエストを返します。`None`は、リアクションがないマージリクエストを返します。`Any`は、1つ以上のリアクションがあるマージリクエストを返します。 |
| `non_archived`              | ブール値       | いいえ       | `true`の場合、アーカイブされていないプロジェクトからのマージリクエストのみを返します。デフォルトは`false`です。 |
| `not`                       | ハッシュ          | いいえ       | 指定されたパラメータに一致しないマージリクエストを返します。`labels`、`milestone`、`author_id`、`author_username`、`assignee_id`、`assignee_username`、`reviewer_id`、`reviewer_username`、`my_reaction_emoji`を指定できます。 |
| `order_by`                  | 文字列        | いいえ       | `created_at`、`updated_at`、`merged_at`（GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)）、`label_priority`、`priority`、`milestone_due`、`popularity`、または`title`フィールドで順序付けされたマージリクエストを返します。デフォルトは`created_at`です。 |
| `reviewer_id`               | 整数または文字列 | いいえ   | 指定されたユーザー`id`のユーザーが[レビュアー](../user/project/merge_requests/reviews/_index.md)であるマージリクエストを返します。`None`はレビュアーのいないマージリクエストを、`Any`はレビュアーのいるマージリクエストを返します。`reviewer_username`と相互に排他的です。 |
| `reviewer_username`         | 文字列        | いいえ       | 指定された`username`のユーザーが[レビュアー](../user/project/merge_requests/reviews/_index.md)であるマージリクエストを返します。`None`はレビュアーのいないマージリクエストを、`Any`はレビュアーのいるマージリクエストを返します。`reviewer_id`と相互に排他的です。 |
| `scope`                     | 文字列        | いいえ       | 指定されたスコープ（`created_by_me`、`assigned_to_me`、`reviews_for_me`、または`all`）のマージリクエストを返します。`reviews_for_me`は、現在のユーザーがレビュアーとして割り当てられているマージリクエストを返します。`created_by_me`がデフォルトです。 |
| `search`                    | 文字列        | いいえ       | `title`と`description`でマージリクエストを検索します。`in`属性と組み合わせます。 |
| `sort`                      | 文字列        | いいえ       | `asc`または`desc`の順にソートされたマージリクエストを返します。デフォルトは`desc`です。 |
| `source_branch`             | 文字列        | いいえ       | 指定されたソースブランチを持つマージリクエストを返します。 |
| `state`                     | 文字列        | いいえ       | すべてのマージリクエスト（`all`）または、`opened`、`closed`、`locked`、あるいは`merged`のみを返します。`all`がデフォルトです。 |
| `target_branch`             | 文字列        | いいえ       | 指定されたターゲットブランチを持つマージリクエストを返します。 |
| `updated_after`             | 日時      | いいえ       | 指定された日時以降に更新されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before`            | 日時      | いいえ       | 指定された日時以前に更新されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `view`                      | 文字列        | いいえ       | `simple`の場合、`iid`、URL、タイトル、説明、およびマージリクエストの基本的な状態を返します。 |
| `draft`                         | ブール値        | いいえ       | `draft`ステータスでマージリクエストをフィルタリングします。`true`はドラフトのマージリクエストのみを返し、`false`はドラフトではないマージリクエストを返します。`wip`と相互に排他的です。 |
| `wip`                           | 文字列         | いいえ       | GitLab 19.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098)となりました。代わりに`draft`を使用してください。`wip`ステータスでマージリクエストをフィルタリングします。`yes`はドラフトのマージリクエストのみを返し、`no`はドラフトではないマージリクエストを返します。 |
| `with_labels_details`       | ブール値       | いいえ       | `true`の場合、レスポンスではラベルフィールドの各ラベルに関する詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |
| `with_merge_status_recheck` | ブール値       | いいえ       | `true`の場合、このプロジェクションは`merge_status`フィールドの非同期再計算をリクエストします（ただし保証はしません）。デベロッパー、メンテナー、またはオーナーロールを持たないユーザーからリクエストされたときにこの属性を無視するには、`restrict_merge_status_recheck` [機能フラグ](../administration/feature_flags/_index.md)を有効にします。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)を返します。`view`が`simple`に設定されている場合、フィールドのサブセットを返します。それ以外の場合、レスポンスの属性には以下が含まれます:

| 属性                                | 型     | 説明 |
|------------------------------------------|----------|-------------|
| `allow_collaboration`                    | ブール値  | `true`の場合、このフォークは、ターゲットブランチにマージできるメンバーとのコラボレーションを可能にします。フォークからのマージリクエストにのみ使用されます。 |
| `allow_maintainer_to_push`               | ブール値  | 非推奨。代わりに`allow_collaboration`を使用してください。 |
| `approvals_before_merge`                 | 整数  | GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。承認ルールを設定するには、代わりに[マージリクエスト承認API](merge_request_approvals.md)を参照してください。GitLab PremiumおよびUltimateのみです。 |
| `assignee[]`                             | オブジェクト   | 非推奨。代わりに`assignees`を使用してください。 |
| `assignees[]`                            | 配列    | マージリクエストに割り当てられたユーザー。 |
| `assignees.avatar_url`                   | 文字列   | アサインされたユーザーのアバター画像の完全なURL。 |
| `assignees.id`                           | 整数  | アサインされたユーザーの一意のID。 |
| `assignees.locked`                       | ブール値  | `true`の場合、アサインされたユーザーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `assignees.name`                         | 文字列   | アサインされたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `assignees.public_email`                 | 文字列   | アサインされたユーザーの公開メールアドレス。 |
| `assignees.state`                        | 文字列   | アサインされたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `assignees.username`                     | 文字列   | マージリクエストにアサインされたユーザーのユーザー名。 |
| `assignees.web_url`                      | 文字列   | アサインされたユーザーのプロファイルページの完全なURL。 |
| `author[]`                               | オブジェクト   | マージリクエストを作成したユーザーに関する情報を含むオブジェクト。 |
| `author.avatar_url`                      | 文字列   | 作成者のアバター画像の完全なURL。 |
| `author.id`                              | 整数  | マージリクエストを作成したユーザーの一意のID。 |
| `author.locked`                          | ブール値  | `true`の場合、作成者のアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `author.name`                            | 文字列   | 作成者の表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `author.public_email`                    | 文字列   | 作成者の公開メールアドレス。 |
| `author.state`                           | 文字列   | ユーザーアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `author.username`                        | 文字列   | マージリクエストの作成者のユーザー名。 |
| `author.web_url`                         | 文字列   | 作成者のプロファイルページの完全なURL。 |
| `blocking_discussions_resolved`          | ブール値  | `true`の場合、マージリクエスト内のすべてのディスカッションスレッドは、マージする前に解決されている必要があります。 |
| `closed_at`                              | 日時 | マージリクエストがクローズされた時点のタイムスタンプ。 |
| `closed_by[]`                            | オブジェクト   | マージリクエストをクローズしたユーザーに関する情報を含むオブジェクト。`null`の場合、マージリクエストはオープンです。 |
| `closed_by.avatar_url`                   | 文字列   | クローズしたユーザーのアバター画像の完全なURL。 |
| `closed_by.id`                           | 整数  | マージリクエストをクローズしたユーザーの一意のID。 |
| `closed_by.locked`                       | ブール値  | `true`の場合、クローズしたユーザーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `closed_by.name`                         | 文字列   | クローズしたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `closed_by.public_email`                 | 文字列   | クローズしたユーザーの公開メールアドレス。 |
| `closed_by.state`                        | 文字列   | クローズしたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `closed_by.username`                     | 文字列   | マージリクエストをクローズしたユーザーのユーザー名。 |
| `closed_by.web_url`                      | 文字列   | クローズしたユーザーのプロファイルページの完全なURL。 |
| `created_at`                             | 日時 | マージリクエスト作成時のタイムスタンプ。 |
| `description`                            | 文字列   | マージリクエストの説明。キャッシュ用にHTMLとしてレンダリングされたMarkdownが含まれます。 |
| `description_html`                       | 文字列   | `render_html`が設定されている場合、記述のレンダリングされたHTMLバージョン。 |
| `detailed_merge_status`                  | 文字列   | 詳細なマージステータス情報。使用可能な値のリストについては、[マージ状態](#merge-status)を参照してください。 |
| `discussion_locked`                      | ブール値  | `true`の場合、ディスカッションはロックされます。ロックされたディスカッションでは、プロジェクトメンバーのみがコメントの追加、編集、または解決を行うことができます。 |
| `downvotes`                              | 整数  | マージリクエストに対する不同意の数。 |
| `draft`                                  | ブール値  | `true`の場合、マージリクエストは`draft`状態としてマークされます。 |
| `force_remove_source_branch`             | ブール値  | `true`の場合、プロジェクト設定はマージ後にソースブランチの削除を強制します。 |
| `has_conflicts`                          | ブール値  | `true`の場合、マージリクエストには競合があり、マージできません。`merge_status`プロパティに依存します。`merge_status`が`cannot_be_merged`でない限り、`false`を返します。 |
| `id`                                     | 整数  | マージリクエストの一意のID。 |
| `iid`                                    | 整数  | プロジェクト内のマージリクエストの内部ID。 |
| `imported`                               | ブール値  | `true`の場合、マージリクエストはインポートされました。 |
| `imported_from`                          | 文字列   | インポート元。例: `Bitbucket`。 |
| `labels[]`                               | 配列    | マージリクエストに割り当てられたラベルの配列。`with_labels_details`が`true`の場合、各ラベルの配列を返します。 |
| `labels.archived`                        | ブール値  | `with_labels_details`が`true`の場合、ラベルはアーカイブされます。 |
| `labels.color`                           | 文字列   | `with_labels_details`が`true`の場合、ラベルの背景色。 |
| `labels.description`                     | 文字列   | `with_labels_details`が`true`の場合、ラベルの記述テキスト。`null`の場合、ラベルに記述はありません。 |
| `labels.description_html`。               | 文字列   | `with_labels_details`が`true`の場合、ラベルのHTMLレンダリングされた記述。`null`の場合、ラベルに記述はありません。 |
| `labels.id`                              | 整数  | `with_labels_details`が`true`の場合、ラベルの一意のID。 |
| `labels.name`                            | 文字列   | `with_labels_details`が`true`の場合、ラベルの名前。 |
| `labels.text_color`                      | 文字列   | `with_labels_details`が`true`の場合、ラベルのテキストカラー。 |
| `merge_after`                            | 日時 | 設定されている場合、マージリクエストをマージできるタイムスタンプ。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)されました。 |
| `merge_commit_sha`                       | 文字列   | 設定されている場合、マージリクエストコミットのSHA。マージされるまで`null`を返します。 |
| `merge_status`                           | 文字列   | マージリクエストの状態。すべての潜在的なステータスを考慮する`detailed_merge_status`を代わりに使用してください。`has_conflicts`プロパティに影響します。レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204)になりました。 |
| `merge_user`                             | オブジェクト   | マージリクエストをマージしたユーザー、自動マージに設定したユーザー、または`null`に関する情報を含むオブジェクト。 |
| `merge_when_pipeline_succeeds`           | ブール値  | `true`の場合、マージリクエストは自動マージに設定されます。 |
| `merged_at`                              | 日時 | マージリクエストがマージされた時点のタイムスタンプ。 |
| `merged_by[]`                            | オブジェクト   | 非推奨。代わりに`merge_user`を使用してください。 |
| `milestone[]`                            | オブジェクト   | マージリクエストに割り当てられたマイルストーンに関する情報を含むオブジェクト。 |
| `milestone.created_at`                   | 日時 | マイルストーンが作成されたタイムスタンプ。 |
| `milestone.description`                  | 文字列   | マイルストーンの記述テキスト。`null`の場合、マイルストーンに記述はありません。 |
| `milestone.due_date`                     | 日付     | マイルストーンの期日。`null`の場合、マイルストーンに期日はありません。 |
| `milestone.expired`                      | ブール値  | `true`の場合、マイルストーンは期限切れです。 |
| `milestone.group_id`                     | 整数  | マイルストーンが属するグループのID。マイルストーンがグループマイルストーンの場合にのみ含まれます。 |
| `milestone.id`                           | 整数  | マイルストーンの一意のID。 |
| `milestone.iid`                          | 整数  | プロジェクトまたはグループ内のマイルストーンの内部ID。 |
| `milestone.project_id`                   | 整数  | マイルストーンが属するプロジェクトのID。マイルストーンがプロジェクトマイルストーンの場合にのみ含まれます。 |
| `milestone.start_date`                   | 日付     | マイルストーンの開始日。`null`の場合、マイルストーンに開始日はありません。 |
| `milestone.state`                        | 文字列   | マイルストーンの現在の状態。例: `active`または`closed`。 |
| `milestone.title`                        | 文字列   | マイルストーンの名前。 |
| `milestone.updated_at`                   | 日時 | マイルストーンが最後に更新されたタイムスタンプ。 |
| `milestone.web_url`                      | 文字列   | マイルストーンを表示するための完全なWeb URL。 |
| `prepared_at`                            | 日時 | マージリクエストが準備されたときのタイムスタンプ。このフィールドは、すべての[準備手順](#preparation-steps)が完了した後に1回だけ入力され、それ以上の変更が加えられても更新されません。 |
| `project_id`                             | 整数  | マージリクエストを含むプロジェクトのID。 |
| `reference`                              | 文字列   | 非推奨。代わりに`references`を使用してください。 |
| `references[]`                           | オブジェクト   | マージリクエストのすべての内部参照を含むオブジェクト。 |
| `references.full`                        | 文字列   | 完全なプロジェクトパスを含むマージリクエストへの完全な参照。例: `gitlab-org/gitlab!123`。グループまたはプロジェクト間でリクエストされた場合、`references.relative`と同一です。 |
| `references.relative`                    | 文字列   | 特定のプロジェクトまたはグループに対する参照。`!123`は現在のプロジェクト内のマージリクエスト、`other-project!123`は同じグループ内の別のプロジェクトのマージリクエスト。 |
| `references.short`                       | 文字列   | 最短のマージリクエストへの参照。例: `!123`。マージリクエストのプロジェクトからフェッチされた場合、`references.relative`と同一です。 |
| `reviewers[]`                            | 配列    | マージリクエストのレビュアー。 |
| `reviewers.avatar_url`                   | 文字列   | レビュアーのアバター画像の完全なURL。 |
| `reviewers.id`                           | 整数  | レビュアーの一意のID。 |
| `reviewers.locked`                       | ブール値  | `true`の場合、レビュアーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `reviewers.name`                         | 文字列   | レビュアーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `reviewers.public_email`                 | 文字列   | レビュアーの公開メールアドレス。 |
| `reviewers.state`                        | 文字列   | レビュアーのユーザーアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `reviewers.username`                     | 文字列   | マージリクエストレビュアーのユーザー名。 |
| `reviewers.web_url`                      | 文字列   | レビュアーのプロファイルページの完全なURL。 |
| `sha`                                    | 文字列   | ソースブランチのHEADコミットのSHA。 |
| `should_remove_source_branch`            | ブール値  | `true`の場合、マージ後にソースブランチは削除されます。 |
| `source_branch`                          | 文字列   | ソースブランチの名前。 |
| `source_project_id`                      | 整数  | ソースブランチのID。 |
| `squash`                                 | ブール値  | `true`の場合、マージ時にコミットをスカッシュします。 |
| `squash_commit_sha`                      | 文字列   | 設定されている場合、スカッシュコミットのSHA。マージされるまで空です。 |
| `squash_on_merge`                        | ブール値  | `true`の場合、マージ時にコミットがスカッシュされます。 |
| `state`                                  | 文字列   | マージリクエストの現在の状態。使用可能な値: `opened`、`closed`、`merged`、または`locked`。 |
| `target_branch`                          | 文字列   | ターゲットブランチの名前。 |
| `target_project_id`                      | 整数  | ターゲットプロジェクトのID（数値）。 |
| `task_completion_status[]`               | オブジェクト   | タスクリストの完了ステータスに関する情報を含むオブジェクト。 |
| `task_completion_status.completed_count` | 整数  | マージリクエストの記述にある完了したタスクリストアイテムの数。マージリクエストに記述がないか、タスクリストアイテムがない場合、`0`を返します。 |
| `task_completion_status.count`           | 整数  | マージリクエストの記述に見つかったタスクリストアイテムの総数。マージリクエストに記述がないか、タスクリストアイテムがない場合、`0`を返します。 |
| `time_stats[]`                           | オブジェクト   | このマージリクエストのタイムトラッキングに関する情報を含むオブジェクト。 |
| `time_stats.human_time_estimate`         | 文字列   | `time_stats.time_estimate`の人間が判読できるフォーマット。例: `3h 30m`。 |
| `time_stats.human_total_time_spent`      | 文字列   | `time_stats.total_time_spent`の人間が判読できるフォーマット。例: `3h 30m`。 |
| `time_stats.time_estimate`               | 整数  | マージリクエストを完了するための推定時間（秒単位）。 |
| `time_stats.total_time_spent`            | 整数  | マージリクエストでの作業に費やされた合計時間（秒単位）。 |
| `title`                                  | 文字列   | マージリクエストのタイトル。 |
| `title_html`                             | 文字列   | `render_html`が`true`の場合、タイトルのレンダリングされたHTMLバージョン。 |
| `updated_at`                             | 日時 | マージリクエストの最終更新時のタイムスタンプ。 |
| `upvotes`                                | 整数  | マージリクエストに対する同意の数。 |
| `user_notes_count`                       | 整数  | ユーザーコメントの数。 |
| `web_url`                                | 文字列   | マージリクエストを表示するためのWeb URL。 |
| `work_in_progress`                       | ブール値  | 非推奨。代わりに`draft`を使用してください。 |

その他のレスポンス:

- アクセストークンが無効な場合は`401 Unauthorized`。
- データベースのクエリがタイムアウトした場合の`408 Request Timeout`。
- 検証に失敗した場合の`422 Unprocessable Entity`。
- `search`パラメータを使用し、リクエストがレート制限された場合の`429 Too Many Requests`。

レスポンス例: 

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "allow_collaboration": false,
    "allow_maintainer_to_push": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-group/my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    }
  }
]
```

### マージリクエストリストのレスポンスに関する注記 {#merge-requests-list-response-notes}

- マージリクエストのリスト取得では、`merge_status`がプロアクティブに更新されない場合があります（`has_conflicts`にも影響します）。これは、コストのかかる操作になる可能性があるためです。このエンドポイントからこれらのフィールドの値が必要な場合は、クエリの`with_merge_status_recheck`パラメータを`true`に設定します。
- レスポンスデータに関する重要な注意点については、[マージリクエストリストレスポンスノート](#single-merge-request-response-notes)を参照してください。

## プロジェクトマージリクエストのリストを取得する {#list-project-merge-requests}

プロジェクトのすべてのマージリクエストをリストします。

```plaintext
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
GET /projects/:id/merge_requests?iids[]=42&iids[]=43
GET /projects/:id/merge_requests?milestone=release
GET /projects/:id/merge_requests?labels=bug,reproduced
GET /projects/:id/merge_requests?my_reaction_emoji=star
```

サポートされている属性は以下のとおりです: 

| 属性                       | 型           | 必須 | 説明 |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `iids[]`                        | 整数の配列  | いいえ       | 提供されたIIDに一致するマージリクエストを返します。 |
| `approved_by_ids[]`             | 整数の配列  | いいえ       | 指定された`id`を持つすべてのユーザー（最大5人のユーザー）が承認したマージリクエストを返します。`None`は承認のないマージリクエストを返します。`Any`は承認のあるマージリクエストを返します。 |
| `approved_by_usernames[]`       | 文字列配列   | いいえ       | 指定された`username`を持つすべてのユーザー（最大5人のユーザー）が承認したマージリクエストを返します。`None`は承認のないマージリクエストを返します。`Any`は承認のあるマージリクエストを返します。 |
| `approver_ids[]`                | 整数の配列  | いいえ       | 指定された`id`IDを持つすべてのユーザーが、承認ルールに従って適格な承認者であるマージリクエストを返します。`None`は適格な承認者がいないマージリクエストを返し、`Any`は少なくとも1人の適格な承認者がいるマージリクエストを返します。PremiumおよびUltimateのみです。 |
| `assignee_id`                   | 整数または文字列 | いいえ    | 指定されたユーザー`id`に割り当てられたマージリクエストを返します。`None`は未割り当てのマージリクエストを返します。`Any`は担当者に割り当てられているマージリクエストを返します。`assignee_username`と相互に排他的です。 |
| `assignee_username[]`           | 文字列配列   | いいえ       | 指定されたユーザー名に割り当てられたマージリクエストを返します。`assignee_id`と相互に排他的です。 |
| `author_id`                     | 整数        | いいえ       | 指定されたユーザー`id`が作成したマージリクエストを返します。`author_username`と相互に排他的です。 |
| `author_username`               | 文字列         | いいえ       | 指定された`username`が作成したマージリクエストを返します。`author_id`と相互に排他的です。 |
| `created_after`                 | 日時       | いいえ       | 指定された日時以降に作成されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before`                | 日時       | いいえ       | 指定された日時以前に作成されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `deployed_after`                | 日時       | いいえ       | 指定された日時以降にデプロイされたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `deployed_before`               | 日時       | いいえ       | 指定された日時以前にデプロイされたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `environment`                   | 文字列         | いいえ       | 指定された環境にデプロイされたマージリクエストを返します。 |
| `in`                            | 文字列         | いいえ       | `search`属性のスコーピングを変更します（`title`、`description`、またはこれらをカンマで結合した文字列）。デフォルトは`title,description`です。 |
| `labels`                        | 文字列         | いいえ       | カンマ区切りのラベルのリストに一致するマージリクエストを返します。`None`は、ラベルのないすべてのマージリクエストをリストします。`Any`は、少なくとも1つのラベルを持つすべてのマージリクエストをリストします。定義済みの名前では大文字と小文字が区別されません。 |
| `merge_user_id`                 | 整数        | いいえ       | 指定されたユーザー`id`によってマージされたマージリクエストを返します。`merge_user_username`と相互に排他的です。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)されました。 |
| `merge_user_username`           | 文字列         | いいえ       | 指定された`username`を持つユーザーによってマージされたマージリクエストを返します。`merge_user_id`と相互に排他的です。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)されました。 |
| `milestone`                     | 文字列         | いいえ       | 特定のマイルストーンに対するマージリクエストを返します。`None`は、マイルストーンのないマージリクエストをリストします。`Any`は、割り当てられたマイルストーンを持つマージリクエストをリストします。 |
| `my_reaction_emoji`             | 文字列         | いいえ       | 認証されたユーザーが、指定された`emoji`でリアクションしたマージリクエストを返します。`None`は、リアクションがないマージリクエストを返します。`Any`は、1つ以上のリアクションがあるマージリクエストを返します。 |
| `not`                           | ハッシュ           | いいえ       | 指定されたパラメータに一致しないマージリクエストを返します。`labels`、`milestone`、`author_id`、`author_username`、`assignee_id`、`assignee_username`、`reviewer_id`、`reviewer_username`、`my_reaction_emoji`を指定できます。 |
| `order_by`                      | 文字列         | いいえ       | `created_at`、`updated_at`、`merged_at`（GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)）、`label_priority`、`priority`、`milestone_due`、`popularity`、または`title`フィールドで順序付けされたマージリクエストを返します。デフォルトは`created_at`です。 |
| `reviewer_id`                   | 整数または文字列 | いいえ    | 指定されたユーザー`id`のユーザーが[レビュアー](../user/project/merge_requests/reviews/_index.md)であるマージリクエストを返します。`None`はレビュアーのいないマージリクエストを、`Any`はレビュアーのいるマージリクエストを返します。`reviewer_username`と相互に排他的です。  |
| `reviewer_username`             | 文字列         | いいえ       | 指定された`username`のユーザーが[レビュアー](../user/project/merge_requests/reviews/_index.md)であるマージリクエストを返します。`None`はレビュアーのいないマージリクエストを、`Any`はレビュアーのいるマージリクエストを返します。`reviewer_id`と相互に排他的です。 |
| `scope`                         | 文字列         | いいえ       | 指定されたスコープ（`created_by_me`、`assigned_to_me`、`reviews_for_me`、または`all`）のマージリクエストを返します。`reviews_for_me`は、現在のユーザーがレビュアーとして割り当てられているマージリクエストを返します。`all`がデフォルトです。 |
| `search`                        | 文字列         | いいえ       | `title`と`description`でマージリクエストを検索します。`in`属性と組み合わせます。 |
| `sort`                          | 文字列         | いいえ       | `asc`または`desc`の順にソートされたマージリクエストを返します。デフォルトは`desc`です。 |
| `source_branch`                 | 文字列         | いいえ       | 指定されたソースブランチを持つマージリクエストを返します。 |
| `state`                         | 文字列         | いいえ       | すべてのマージリクエスト（`all`）または、`opened`、`closed`、`locked`、あるいは`merged`のみを返します。`all`がデフォルトです。 |
| `target_branch`                 | 文字列         | いいえ       | 指定されたターゲットブランチを持つマージリクエストを返します。 |
| `updated_after`                 | 日時       | いいえ       | 指定された日時以降に更新されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before`                | 日時       | いいえ       | 指定された日時以前に更新されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `view`                          | 文字列         | いいえ       | `simple`の場合、`iid`、URL、タイトル、説明、およびマージリクエストの基本的な状態を返します。 |
| `draft`                     | ブール値           | いいえ       | `draft`ステータスでマージリクエストをフィルタリングします。`true`はドラフトのマージリクエストのみを返し、`false`はドラフトではないマージリクエストを返します。`wip`と相互に排他的です。 |
| `wip`                       | 文字列            | いいえ       | GitLab 19.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098)となりました。代わりに`draft`を使用してください。`wip`ステータスでマージリクエストをフィルタリングします。`yes`はドラフトのマージリクエストのみを返し、`no`はドラフトではないマージリクエストを返します。 |
| `with_labels_details`           | ブール値        | いいえ       | `true`の場合、レスポンスではラベルフィールドの各ラベルに関する詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |
| `with_merge_status_recheck`     | ブール値        | いいえ       | `true`の場合、このプロジェクションは`merge_status`フィールドの非同期再計算をリクエストします（ただし保証はしません）。デベロッパー、メンテナー、またはオーナーロールを持たないユーザーからリクエストされたときにこの属性を無視するには、`restrict_merge_status_recheck` [機能フラグ](../administration/feature_flags/_index.md)を有効にします。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                          | 型     | 説明 |
| ---------------------------------- | -------- | ----------- |
| `[].id`                            | 整数  | マージリクエストのID。 |
| `[].iid`                           | 整数  | マージリクエストの内部ID。 |
| `[].approvals_before_merge`        | 整数  | このマージリクエストがマージされる前に必要な承認の数。承認ルールを設定するには、[マージリクエスト承認API](merge_request_approvals.md)を参照してください。GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。PremiumおよびUltimateのみです。 |
| `[].assignee`                      | オブジェクト   | マージリクエストの最初の担当者。 |
| `[].assignees`                     | 配列    | マージリクエストの担当者。 |
| `[].author`                        | オブジェクト   | このマージリクエストを作成したユーザー。 |
| `[].blocking_discussions_resolved` | ブール値  | マージリクエストをマージする前に、すべてのディスカッションが必須な場合にのみ、すべてのディスカッションが解決されるかどうかを示します。 |
| `[].closed_at`                     | 日時 | マージリクエストがクローズされた時点のタイムスタンプ。 |
| `[].closed_by`                     | オブジェクト   | このマージリクエストをクローズしたユーザー。 |
| `[].created_at`                    | 日時 | マージリクエスト作成時のタイムスタンプ。 |
| `[].description`                   | 文字列   | マージリクエストの説明。 |
| `[].detailed_merge_status`         | 文字列   | マージリクエストの詳細なマージ状態。使用可能な値のリストについては、[マージ状態](#merge-status)を参照してください。 |
| `[].discussion_locked`             | ブール値  | マージリクエストのコメントがメンバーのみにロックされているかどうかを示します。 |
| `[].downvotes`                     | 整数  | マージリクエストに対する不同意の数。 |
| `[].draft`                         | ブール値  | マージリクエストがドラフトかどうかを示します。 |
| `[].force_remove_source_branch`    | ブール値  | プロジェクトの設定で、マージ後にソースブランチを削除するかどうかを示します。 |
| `[].has_conflicts`                 | ブール値  | マージリクエストに競合があり、マージできないかどうかを示します。`merge_status`プロパティに依存します。`merge_status`が`cannot_be_merged`でない限り、`false`を返します。 |
| `[].labels`                        | 配列    | マージリクエストのラベル。 |
| `[].merge_commit_sha`              | 文字列   | マージリクエストのコミットのSHA。マージされるまで`null`を返します。 |
| `[].merge_status`                  | 文字列   | マージリクエストの状態。`unchecked`、`checking`、`can_be_merged`、`cannot_be_merged`、または`cannot_be_merged_recheck`のいずれかです。`has_conflicts`プロパティに影響します。レスポンスデータに関する重要な注意点については、[単一マージリクエストのレスポンスに関する注意点](#single-merge-request-response-notes)を参照してください。GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204)になりました。代わりに`detailed_merge_status`を使用してください。 |
| `[].merge_user`                    | オブジェクト   | このマージリクエストをマージしたユーザー、自動マージに設定したユーザー、または`null`。 |
| `[].merge_when_pipeline_succeeds`  | ブール値  | マージリクエストが自動マージに設定されているかどうかを示します。 |
| `[].merged_at`                     | 日時 | マージリクエストがマージされたときのタイムスタンプ。 |
| `[].merged_by`                     | オブジェクト   | このマージリクエストをマージしたユーザー、または自動マージに設定したユーザー。GitLab 14.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)となり、[APIバージョン5](https://gitlab.com/groups/gitlab-org/-/epics/8115)で削除される予定です。代わりに`merge_user`を使用してください。 |
| `[].milestone`                     | オブジェクト   | マージリクエストのマイルストーン。 |
| `[].prepared_at`                   | 日時 | マージリクエストが準備されたときのタイムスタンプ。このフィールドは、すべての[準備ステップ](#preparation-steps)が完了した後に1回だけ入力され、変更が追加されても更新されません。 |
| `[].project_id`                    | 整数  | マージリクエストが存在するプロジェクトのID。常に`target_project_id`と等しくなります。 |
| `[].reference`                     | 文字列   | マージリクエストの内部参照。デフォルトでは短縮形式で返されます。GitLab 12.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)となり、[APIバージョン5](https://gitlab.com/groups/gitlab-org/-/epics/8115)で削除される予定です。代わりに`references`を使用してください。 |
| `[].references`                    | オブジェクト   | マージリクエストの内部参照。`short`、`relative`、および`full`参照が含まれます。`references.relative`はマージリクエストのグループまたはプロジェクトに対して相対的です。マージリクエストのプロジェクトからフェッチされた場合、`relative`形式と`short`形式は同一です。グループまたはプロジェクト全体でリクエストされた場合、`relative`形式と`full`形式は同一です。|
| `[].reviewers`                     | 配列    | マージリクエストのレビュアー。 |
| `[].sha`                           | 文字列   | マージリクエストの差分ヘッドSHA。 |
| `[].should_remove_source_branch`   | ブール値  | マージ後にソースブランチを削除するかどうかを示します。 |
| `[].source_branch`                 | 文字列   | マージリクエストのソースブランチ。 |
| `[].source_project_id`             | 整数  | マージリクエストのソースプロジェクトのID。マージリクエストの起点にフォークがない限り、`target_project_id`と同じです。 |
| `[].squash`                        | ブール値  | `true`の場合、マージ時にすべてのコミットを単一のコミットにスカッシュします。[プロジェクト設定](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)によって、この値がオーバーライドされる可能性があります。プロジェクトのスカッシュ設定を反映させたい場合は、代わりに`squash_on_merge`を使用してください。 |
| `[].squash_commit_sha`             | 文字列   | スカッシュコミットのSHA。マージされるまで空です。 |
| `[].squash_on_merge`               | ブール値  | マージ時にマージリクエストをスカッシュするかどうかを示します。 |
| `[].state`                         | 文字列   | マージリクエストの状態。`opened`、`closed`、`merged`、`locked`のいずれか。 |
| `[].target_branch`                 | 文字列   | マージリクエストのターゲットブランチ。 |
| `[].target_project_id`             | 整数  | マージリクエストのターゲットプロジェクトのID。 |
| `[].task_completion_status`        | オブジェクト   | タスクの完了状態。`count`と`completed_count`が含まれます。 |
| `[].time_stats`                    | オブジェクト   | マージリクエストのタイムトラッキング統計。`time_estimate`、`total_time_spent`、`human_time_estimate`、および`human_total_time_spent`が含まれます。 |
| `[].title`                         | 文字列   | マージリクエストのタイトル。 |
| `[].updated_at`                    | 日時 | マージリクエストが更新された時のタイムスタンプ。 |
| `[].upvotes`                       | 整数  | マージリクエストに対する同意の数。 |
| `[].user_notes_count`              | 整数  | マージリクエストのユーザーノート数。 |
| `[].web_url`                       | 文字列   | マージリクエストのWeb URL。 |
| `[].work_in_progress`              | ブール値  | 非推奨: 代わりに`draft`を使用してください。マージリクエストがドラフトかどうかを示します。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "locked": false,
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "reference": "!1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "squash_on_merge": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": 2
  }
]
```

レスポンスデータに関する重要な注意点については、[マージリクエストリストレスポンスノート](#merge-requests-list-response-notes)を参照してください。

## グループマージリクエストのリストを取得する {#list-group-merge-requests}

グループとそのサブグループのすべてのマージリクエストをリストします。

```plaintext
GET /groups/:id/merge_requests
GET /groups/:id/merge_requests?state=opened
GET /groups/:id/merge_requests?state=all
GET /groups/:id/merge_requests?milestone=release
GET /groups/:id/merge_requests?labels=bug,reproduced
GET /groups/:id/merge_requests?my_reaction_emoji=star
```

サポートされている属性は以下のとおりです: 

| 属性                   | 型              | 必須 | 説明 |
|-----------------------------|-------------------|----------|-------------|
| `id`                        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approved_by_ids[]`         | 整数の配列     | いいえ       | 指定された`id`を持つすべてのユーザー（最大5人のユーザー）が承認したマージリクエストを返します。`None`は承認のないマージリクエストを返します。`Any`は承認のあるマージリクエストを返します。 |
| `approved_by_usernames[]`   | 文字列配列      | いいえ       | 指定された`username`を持つすべてのユーザー（最大5人のユーザー）が承認したマージリクエストを返します。`None`は承認のないマージリクエストを返します。`Any`は承認のあるマージリクエストを返します。 |
| `approver_ids[]`            | 整数の配列     | いいえ       | 指定された`id`IDを持つすべてのユーザーが、承認ルールに従って適格な承認者であるマージリクエストを返します。`None`は適格な承認者がいないマージリクエストを返し、`Any`は少なくとも1人の適格な承認者がいるマージリクエストを返します。PremiumおよびUltimateのみです。 |
| `assignee_id`               | 整数または文字列 | いいえ       | 指定されたユーザー`id`に割り当てられたマージリクエストを返します。`None`は未割り当てのマージリクエストを返します。`Any`は担当者に割り当てられているマージリクエストを返します。`assignee_username`と相互に排他的です。 |
| `assignee_username[]`       | 文字列配列      | いいえ       | 指定されたユーザー名に割り当てられたマージリクエストを返します。`assignee_id`と相互に排他的です。 |
| `author_id`                 | 整数           | いいえ       | 指定されたユーザー`id`が作成したマージリクエストを返します。`author_username`と相互に排他的です。 |
| `author_username`           | 文字列            | いいえ       | 指定された`username`が作成したマージリクエストを返します。`author_id`と相互に排他的です。 |
| `created_after`             | 日時          | いいえ       | 指定された日時以降に作成されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before`            | 日時          | いいえ       | 指定された日時以前に作成されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `deployed_after`            | 日時          | いいえ       | 指定された日時以降にデプロイされたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `deployed_before`           | 日時          | いいえ       | 指定された日時以前にデプロイされたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `environment`               | 文字列            | いいえ       | 指定された環境にデプロイされたマージリクエストを返します。 |
| `in`                        | 文字列            | いいえ       | `search`属性のスコーピングを変更します（`title`、`description`、またはこれらをカンマで結合した文字列）。デフォルトは`title,description`です。 |
| `labels`                  | 文字列             | いいえ       | カンマ区切りのラベルのリストに一致するマージリクエストを返します。`None`は、ラベルのないすべてのマージリクエストをリストします。`Any`は、少なくとも1つのラベルを持つすべてのマージリクエストをリストします。定義済みの名前では大文字と小文字が区別されません。 |
| `merge_user_id`             | 整数           | いいえ       | 指定されたユーザー`id`によってマージされたマージリクエストを返します。`merge_user_username`と相互に排他的です。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)されました。 |
| `merge_user_username`       | 文字列            | いいえ       | 指定された`username`を持つユーザーによってマージされたマージリクエストを返します。`merge_user_id`と相互に排他的です。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)されました。 |
| `milestone`                 | 文字列            | いいえ       | 特定のマイルストーンに対するマージリクエストを返します。`None`は、マイルストーンのないマージリクエストをリストします。`Any`は、割り当てられたマイルストーンを持つマージリクエストをリストします。 |
| `my_reaction_emoji`         | 文字列            | いいえ       | 認証されたユーザーが、指定された`emoji`でリアクションしたマージリクエストを返します。`None`は、リアクションがないマージリクエストを返します。`Any`は、1つ以上のリアクションがあるマージリクエストを返します。 |
| `non_archived`              | ブール値           | いいえ       | `true`の場合、アーカイブされていないプロジェクトからのマージリクエストのみを返します。デフォルトは`true`です。 |
| `not`                       | ハッシュ              | いいえ       | 指定されたパラメータに一致しないマージリクエストを返します。`labels`、`milestone`、`author_id`、`author_username`、`assignee_id`、`assignee_username`、`reviewer_id`、`reviewer_username`、`my_reaction_emoji`を指定できます。 |
| `order_by`                  | 文字列            | いいえ       | `created_at`、`updated_at`、`merged_at`（GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)）、`label_priority`、`priority`、`milestone_due`、`popularity`、または`title`フィールドで順序付けされたマージリクエストを返します。デフォルトは`created_at`です。 |
| `reviewer_id`               | 整数または文字列 | いいえ       | 指定されたユーザー`id`のユーザーが[レビュアー](../user/project/merge_requests/reviews/_index.md)であるマージリクエストを返します。`None`はレビュアーのいないマージリクエストを、`Any`はレビュアーのいるマージリクエストを返します。`reviewer_username`と相互に排他的です。 |
| `reviewer_username`         | 文字列            | いいえ       | 指定された`username`のユーザーが[レビュアー](../user/project/merge_requests/reviews/_index.md)であるマージリクエストを返します。`None`はレビュアーのいないマージリクエストを、`Any`はレビュアーのいるマージリクエストを返します。`reviewer_id`と相互に排他的です。 |
| `scope`                     | 文字列            | いいえ       | 指定されたスコープ（`created_by_me`、`assigned_to_me`、`reviews_for_me`、または`all`）のマージリクエストを返します。`reviews_for_me`は、現在のユーザーがレビュアーとして割り当てられているマージリクエストを返します。`all`がデフォルトです。 |
| `search`                    | 文字列            | いいえ       | `title`と`description`でマージリクエストを検索します。`in`属性と組み合わせます。 |
| `sort`                      | 文字列            | いいえ       | `asc`または`desc`の順にソートされたマージリクエストを返します。デフォルトは`desc`です。 |
| `source_branch`             | 文字列            | いいえ       | 指定されたソースブランチを持つマージリクエストを返します。 |
| `source_project_id`         | 整数           | いいえ       | 指定されたソースプロジェクトIDを持つマージリクエストを返します。 |
| `state`                     | 文字列            | いいえ       | すべてのマージリクエスト（`all`）または、`opened`、`closed`、`locked`、あるいは`merged`のみを返します。`all`がデフォルトです。 |
| `target_branch`             | 文字列            | いいえ       | 指定されたターゲットブランチを持つマージリクエストを返します。 |
| `updated_after`             | 日時          | いいえ       | 指定された日時以降に更新されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before`            | 日時          | いいえ       | 指定された日時以前に更新されたマージリクエストを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `view`                      | 文字列            | いいえ       | `simple`の場合、`iid`、URL、タイトル、説明、およびマージリクエストの基本的な状態を返します。 |
| `draft`                     | ブール値           | いいえ       | `draft`ステータスでマージリクエストをフィルタリングします。`true`はドラフトのマージリクエストのみを返し、`false`はドラフトではないマージリクエストを返します。`wip`と相互に排他的です。 |
| `wip`                       | 文字列            | いいえ       | GitLab 19.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098)となりました。代わりに`draft`を使用してください。`wip`ステータスでマージリクエストをフィルタリングします。`yes`はドラフトのマージリクエストのみを返し、`no`はドラフトではないマージリクエストを返します。 |
| `with_labels_details`       | ブール値           | いいえ       | `true`の場合、レスポンスではラベルフィールドの各ラベルに関する詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |
| `with_merge_status_recheck` | ブール値           | いいえ       | `true`の場合、このプロジェクションは`merge_status`フィールドの非同期再計算をリクエストします（ただし保証はしません）。デベロッパー、メンテナー、またはオーナーロールを持たないユーザーからリクエストされたときにこの属性を無視するには、`restrict_merge_status_recheck` [機能フラグ](../administration/feature_flags/_index.md)を有効にします。 |

応答では、`group_id`はマージリクエストが存在するプロジェクトを含むグループのIDを表します。

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)を返します。`view`が`simple`に設定されている場合、フィールドのサブセットを返します。それ以外の場合、レスポンスの属性には以下が含まれます:

| 属性                                | 型     | 説明 |
|------------------------------------------|----------|-------------|
| `allow_collaboration`                    | ブール値  | `true`の場合、このフォークは、ターゲットブランチにマージできるメンバーとのコラボレーションを可能にします。フォークからのマージリクエストにのみ使用されます。 |
| `allow_maintainer_to_push`               | ブール値  | 非推奨。代わりに`allow_collaboration`を使用してください。 |
| `approvals_before_merge`                 | 整数  | GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。承認ルールを設定するには、代わりに[マージリクエスト承認API](merge_request_approvals.md)を参照してください。GitLab PremiumおよびUltimateのみです。 |
| `assignee[]`                             | オブジェクト   | 非推奨。代わりに`assignees`を使用してください。 |
| `assignees[]`                            | 配列    | マージリクエストに割り当てられたユーザー。 |
| `assignees.avatar_url`                   | 文字列   | アサインされたユーザーのアバター画像の完全なURL。 |
| `assignees.id`                           | 整数  | アサインされたユーザーの一意のID。 |
| `assignees.locked`                       | ブール値  | `true`の場合、アサインされたユーザーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `assignees.name`                         | 文字列   | アサインされたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `assignees.public_email`                 | 文字列   | アサインされたユーザーの公開メールアドレス。 |
| `assignees.state`                        | 文字列   | アサインされたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `assignees.username`                     | 文字列   | マージリクエストにアサインされたユーザーのユーザー名。 |
| `assignees.web_url`                      | 文字列   | アサインされたユーザーのプロファイルページの完全なURL。 |
| `author[]`                               | オブジェクト   | マージリクエストを作成したユーザーに関する情報を含むオブジェクト。 |
| `author.avatar_url`                      | 文字列   | 作成者のアバター画像の完全なURL。 |
| `author.id`                              | 整数  | マージリクエストを作成したユーザーの一意のID。 |
| `author.locked`                          | ブール値  | `true`の場合、作成者のアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `author.name`                            | 文字列   | 作成者の表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `author.public_email`                    | 文字列   | 作成者の公開メールアドレス。 |
| `author.state`                           | 文字列   | ユーザーアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `author.username`                        | 文字列   | マージリクエストの作成者のユーザー名。 |
| `author.web_url`                         | 文字列   | 作成者のプロファイルページの完全なURL。 |
| `blocking_discussions_resolved`          | ブール値  | `true`の場合、マージリクエスト内のすべてのディスカッションスレッドは、マージする前に解決されている必要があります。 |
| `closed_at`                              | 日時 | マージリクエストがクローズされた時点のタイムスタンプ。 |
| `closed_by[]`                            | オブジェクト   | マージリクエストをクローズしたユーザーに関する情報を含むオブジェクト。`null`の場合、マージリクエストはオープンです。 |
| `closed_by.avatar_url`                   | 文字列   | クローズしたユーザーのアバター画像の完全なURL。 |
| `closed_by.id`                           | 整数  | マージリクエストをクローズしたユーザーの一意のID。 |
| `closed_by.locked`                       | ブール値  | `true`の場合、クローズしたユーザーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `closed_by.name`                         | 文字列   | クローズしたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `closed_by.public_email`                 | 文字列   | クローズしたユーザーの公開メールアドレス。 |
| `closed_by.state`                        | 文字列   | クローズしたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `closed_by.username`                     | 文字列   | マージリクエストをクローズしたユーザーのユーザー名。 |
| `closed_by.web_url`                      | 文字列   | クローズしたユーザーのプロファイルページの完全なURL。 |
| `created_at`                             | 日時 | マージリクエスト作成時のタイムスタンプ。 |
| `description`                            | 文字列   | マージリクエストの説明。キャッシュ用にHTMLとしてレンダリングされたMarkdownが含まれます。 |
| `detailed_merge_status`                  | 文字列   | 詳細なマージステータス情報。使用可能な値のリストについては、[マージ状態](#merge-status)を参照してください。 |
| `discussion_locked`                      | ブール値  | `true`の場合、ディスカッションはロックされます。ロックされたディスカッションでは、プロジェクトメンバーのみがコメントの追加、編集、または解決を行うことができます。 |
| `downvotes`                              | 整数  | マージリクエストに対する不同意の数。 |
| `draft`                                  | ブール値  | `true`の場合、マージリクエストは`draft`状態としてマークされます。 |
| `force_remove_source_branch`             | ブール値  | `true`の場合、プロジェクト設定はマージ後にソースブランチの削除を強制します。 |
| `has_conflicts`                          | ブール値  | `true`の場合、マージリクエストには競合があり、マージできません。`merge_status`プロパティに依存します。`merge_status`が`cannot_be_merged`でない限り、`false`を返します。 |
| `id`                                     | 整数  | マージリクエストの一意のID。 |
| `iid`                                    | 整数  | プロジェクト内のマージリクエストの内部ID。 |
| `imported`                               | ブール値  | `true`の場合、マージリクエストはインポートされました。 |
| `imported_from`                          | 文字列   | インポート元。例: `Bitbucket`。 |
| `labels[]`                               | 配列    | マージリクエストに割り当てられたラベルの配列。`with_labels_details`が`true`の場合、各ラベルの配列を返します。 |
| `labels.archived`                        | ブール値  | `with_labels_details`が`true`の場合、ラベルはアーカイブされます。 |
| `labels.color`                           | 文字列   | `with_labels_details`が`true`の場合、ラベルの背景色。 |
| `labels.description`                     | 文字列   | `with_labels_details`が`true`の場合、ラベルの記述テキスト。`null`の場合、ラベルに記述はありません。 |
| `labels.description_html`                | 文字列   | `with_labels_details`が`true`の場合、ラベルのHTMLレンダリングされた記述。`null`の場合、ラベルに記述はありません。 |
| `labels.id`                              | 整数  | `with_labels_details`が`true`の場合、ラベルの一意のID。 |
| `labels.name`                            | 文字列   | `with_labels_details`が`true`の場合、ラベルの名前。 |
| `labels.text_color`                      | 文字列   | `with_labels_details`が`true`の場合、ラベルのテキストカラー。 |
| `merge_after`                            | 日時 | 設定されている場合、マージリクエストをマージできるタイムスタンプ。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)されました。 |
| `merge_commit_sha`                       | 文字列   | 設定されている場合、マージリクエストコミットのSHA。マージされるまで`null`を返します。 |
| `merge_status`                           | 文字列   | マージリクエストの状態。すべての潜在的なステータスを考慮する`detailed_merge_status`を代わりに使用してください。`has_conflicts`プロパティに影響します。レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204)になりました。 |
| `merge_user`                             | オブジェクト   | マージリクエストをマージしたユーザー、自動マージに設定したユーザー、または`null`に関する情報を含むオブジェクト。 |
| `merge_when_pipeline_succeeds`           | ブール値  | `true`の場合、マージリクエストは自動マージに設定されます。 |
| `merged_at`                              | 日時 | マージリクエストがマージされた時点のタイムスタンプ。 |
| `merged_by[]`                            | オブジェクト   | 非推奨。代わりに`merge_user`を使用してください。 |
| `milestone[]`                            | オブジェクト   | マージリクエストに割り当てられたマイルストーンに関する情報を含むオブジェクト。 |
| `milestone.created_at`                   | 日時 | マイルストーンが作成されたタイムスタンプ。 |
| `milestone.description`                  | 文字列   | マイルストーンの記述テキスト。`null`の場合、マイルストーンに記述はありません。 |
| `milestone.due_date`                     | 日付     | マイルストーンの期日。`null`の場合、マイルストーンに期日はありません。 |
| `milestone.expired`                      | ブール値  | `true`の場合、マイルストーンは期限切れです。 |
| `milestone.group_id`                     | 整数  | マイルストーンが属するグループのID。マイルストーンがグループマイルストーンの場合にのみ含まれます。 |
| `milestone.id`                           | 整数  | マイルストーンの一意のID。 |
| `milestone.iid`                          | 整数  | プロジェクトまたはグループ内のマイルストーンの内部ID。 |
| `milestone.project_id`                   | 整数  | マイルストーンが属するプロジェクトのID。マイルストーンがプロジェクトマイルストーンの場合にのみ含まれます。 |
| `milestone.start_date`                   | 日付     | マイルストーンの開始日。`null`の場合、マイルストーンに開始日はありません。 |
| `milestone.state`                        | 文字列   | マイルストーンの現在の状態。例: `active`または`closed`。 |
| `milestone.title`                        | 文字列   | マイルストーンの名前。 |
| `milestone.updated_at`                   | 日時 | マイルストーンが最後に更新されたタイムスタンプ。 |
| `milestone.web_url`                      | 文字列   | マイルストーンを表示するための完全なWeb URL。 |
| `prepared_at`                            | 日時 | マージリクエストが準備されたときのタイムスタンプ。このフィールドは、すべての[準備手順](#preparation-steps)が完了した後に1回だけ入力され、それ以上の変更が加えられても更新されません。 |
| `project_id`                             | 整数  | マージリクエストを含むプロジェクトのID。 |
| `reference`                              | 文字列   | 非推奨。代わりに`references`を使用してください。 |
| `references[]`                           | オブジェクト   | マージリクエストのすべての内部参照を含むオブジェクト。 |
| `references.full`                        | 文字列   | 完全なプロジェクトパスを含むマージリクエストへの完全な参照。例: `gitlab-org/gitlab!123`。グループまたはプロジェクト間でリクエストされた場合、`references.relative`と同一です。 |
| `references.relative`                    | 文字列   | 特定のプロジェクトまたはグループに対する参照。`!123`は現在のプロジェクト内のマージリクエスト、`other-project!123`は同じグループ内の別のプロジェクトのマージリクエスト。 |
| `references.short`                       | 文字列   | 最短のマージリクエストへの参照。例: `!123`。マージリクエストのプロジェクトからフェッチされた場合、`references.relative`と同一です。 |
| `reviewers[]`                            | 配列    | マージリクエストのレビュアー。 |
| `reviewers.avatar_url`                   | 文字列   | レビュアーのアバター画像の完全なURL。 |
| `reviewers.id`                           | 整数  | レビュアーの一意のID。 |
| `reviewers.locked`                       | ブール値  | `true`の場合、レビュアーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `reviewers.name`                         | 文字列   | レビュアーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `reviewers.public_email`                 | 文字列   | レビュアーの公開メールアドレス。 |
| `reviewers.state`                        | 文字列   | レビュアーのユーザーアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `reviewers.username`                     | 文字列   | マージリクエストレビュアーのユーザー名。 |
| `reviewers.web_url`                      | 文字列   | レビュアーのプロファイルページの完全なURL。 |
| `sha`                                    | 文字列   | ソースブランチのHEADコミットのSHA。 |
| `should_remove_source_branch`            | ブール値  | `true`の場合、マージ後にソースブランチは削除されます。 |
| `source_branch`                          | 文字列   | ソースブランチの名前。 |
| `source_project_id`                      | 整数  | ソースブランチのID。 |
| `squash`                                 | ブール値  | `true`の場合、マージ時にコミットをスカッシュします。 |
| `squash_commit_sha`                      | 文字列   | 設定されている場合、スカッシュコミットのSHA。マージされるまで空です。 |
| `squash_on_merge`                        | ブール値  | `true`の場合、マージ時にコミットがスカッシュされます。 |
| `state`                                  | 文字列   | マージリクエストの現在の状態。使用可能な値: `opened`、`closed`、`merged`、または`locked`。 |
| `target_branch`                          | 文字列   | ターゲットブランチの名前。 |
| `target_project_id`                      | 整数  | ターゲットプロジェクトのID（数値）。 |
| `task_completion_status[]`               | オブジェクト   | タスクリストの完了ステータスに関する情報を含むオブジェクト。 |
| `task_completion_status.completed_count` | 整数  | マージリクエストの記述にある完了したタスクリストアイテムの数。マージリクエストに記述がないか、タスクリストアイテムがない場合、`0`を返します。 |
| `task_completion_status.count`           | 整数  | マージリクエストの記述に見つかったタスクリストアイテムの総数。マージリクエストに記述がないか、タスクリストアイテムがない場合、`0`を返します。 |
| `time_stats[]`                           | オブジェクト   | このマージリクエストのタイムトラッキングに関する情報を含むオブジェクト。 |
| `time_stats.human_time_estimate`         | 文字列   | `time_stats.time_estimate`の人間が判読できるフォーマット。例: `3h 30m`。 |
| `time_stats.human_total_time_spent`      | 文字列   | `time_stats.total_time_spent`の人間が判読できるフォーマット。例: `3h 30m`。 |
| `time_stats.time_estimate`               | 整数  | マージリクエストを完了するための推定時間（秒単位）。 |
| `time_stats.total_time_spent`            | 整数  | マージリクエストでの作業に費やされた合計時間（秒単位）。 |
| `title`                                  | 文字列   | マージリクエストのタイトル。 |
| `updated_at`                             | 日時 | マージリクエストの最終更新時のタイムスタンプ。 |
| `upvotes`                                | 整数  | マージリクエストに対する同意の数。 |
| `user_notes_count`                       | 整数  | ユーザーコメントの数。 |
| `web_url`                                | 文字列   | マージリクエストを表示するためのWeb URL。 |
| `work_in_progress`                       | ブール値  | 非推奨。代わりに`draft`を使用してください。 |

その他のレスポンス:

- アクセストークンが無効な場合は`401 Unauthorized`。
- プロジェクトまたはマージリクエストが見つからない場合の`404 Not Found`。
- 検証に失敗した場合の`422 Unprocessable Entity`。
- `search`パラメータを使用し、リクエストがレート制限された場合の`429 Too Many Requests`。

レスポンス例: 

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-10-22",
      "start_date": "2018-09-08",
      "web_url": "gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true
  }
]
```

レスポンスデータに関する重要な注意点については、[マージリクエストリストレスポンスノート](#merge-requests-list-response-notes)を参照してください。

## マージリクエストを取得する {#retrieve-a-merge-request}

マージリクエストに関する情報を取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid
```

サポートされている属性は以下のとおりです: 

| 属性                        | 型              | 必須 | 説明 |
|----------------------------------|-------------------|----------|-------------|
| `id`                             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`              | 整数           | はい      | マージリクエストの内部ID。 |
| `include_diverged_commits_count` | ブール値           | いいえ       | `true`の場合、レスポンスにターゲットブランチより遅れているコミットが含まれます。 |
| `include_rebase_in_progress`     | ブール値           | いいえ       | `true`の場合、レスポンスにリベース操作が進行中かどうかが含まれます。 |
| `render_html`                    | ブール値           | いいえ       | `true`の場合、レスポンスには、タイトルと説明用にレンダリングされたHTMLが含まれます。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)を返します。その他のレスポンス:

- アクセストークンが無効な場合は`401 Unauthorized`。
- アクセスが拒否された場合の`403 Forbidden`。
- プロジェクトまたはマージリクエストが見つからない場合の`404 Not Found`。
- データベースのクエリがタイムアウトした場合の`408 Request Timeout`。
- リソースロックの競合が存在する場合の`409 Conflict`。
- 検証に失敗した場合の`422 Unprocessable Entity`。
- `search`パラメータを使用し、リクエストがレート制限された場合の`429 Too Many Requests`。

### レスポンス {#response}

| 属性                                                   | 型     | 説明 |
|-------------------------------------------------------------|----------|-------------|
| `allow_collaboration`                                       | ブール値  | `true`の場合、このフォークは、ターゲットブランチにマージできるメンバーとのコラボレーションを可能にします。フォークからのマージリクエストにのみ使用されます。 |
| `allow_maintainer_to_push`                                  | ブール値  | 非推奨。代わりに`allow_collaboration`を使用してください。 |
| `approvals_before_merge`                                    | 整数  | GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。承認ルールを設定するには、代わりに[マージリクエスト承認API](merge_request_approvals.md)を参照してください。GitLab PremiumおよびUltimateのみです。 |
| `assignee[]`                                                | オブジェクト   | 非推奨。代わりに`assignees`を使用してください。 |
| `assignees[]`                                               | 配列    | マージリクエストに割り当てられたユーザー。 |
| `assignees.avatar_url`                                      | 文字列   | アサインされたユーザーのアバター画像の完全なURL。 |
| `assignees.id`                                              | 整数  | アサインされたユーザーの一意のID。 |
| `assignees.locked`                                          | ブール値  | `true`の場合、アサインされたユーザーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `assignees.name`                                            | 文字列   | アサインされたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `assignees.public_email`                                    | 文字列   | アサインされたユーザーの公開メールアドレス。 |
| `assignees.state`                                           | 文字列   | アサインされたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `assignees.username`                                        | 文字列   | マージリクエストにアサインされたユーザーのユーザー名。 |
| `assignees.web_url`                                         | 文字列   | アサインされたユーザーのプロファイルページの完全なURL。 |
| `author[]`                                                  | オブジェクト   | マージリクエストを作成したユーザーに関する情報を含むオブジェクト。 |
| `author.avatar_url`                                         | 文字列   | 作成者のアバター画像の完全なURL。 |
| `author.id`                                                 | 整数  | マージリクエストを作成したユーザーの一意のID。 |
| `author.locked`                                             | ブール値  | `true`の場合、作成者のアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `author.name`                                               | 文字列   | 作成者の表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `author.public_email`                                       | 文字列   | 作成者の公開メールアドレス。 |
| `author.state`                                              | 文字列   | ユーザーアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `author.username`                                           | 文字列   | マージリクエストの作成者のユーザー名。 |
| `author.web_url`                                            | 文字列   | 作成者のプロファイルページの完全なURL。 |
| `blocking_discussions_resolved`                             | ブール値  | `true`の場合、マージリクエスト内のすべてのディスカッションスレッドは、マージする前に解決されている必要があります。 |
| `changes_count`                                             | 文字列   | 設定されている場合、マージリクエストで行われた変更の数。マージリクエストが作成されたときは空です。非同期に設定されます。整数ではなく、文字列です。表示および保存する変更が多すぎるマージリクエストの場合、値の上限は1000であり、文字列`"1000+"`を返します。[新規マージリクエスト用の空のAPIフィールド](#empty-api-fields-for-new-merge-requests)を参照してください。 |
| `closed_at`                                                 | 日時 | マージリクエストがクローズされた時点のタイムスタンプ。 |
| `closed_by[]`                                               | オブジェクト   | マージリクエストをクローズしたユーザーに関する情報を含むオブジェクト。`null`の場合、マージリクエストはオープンです。 |
| `closed_by.avatar_url`                                      | 文字列   | クローズしたユーザーのアバター画像の完全なURL。 |
| `closed_by.id`                                              | 整数  | マージリクエストをクローズしたユーザーの一意のID。 |
| `closed_by.locked`                                          | ブール値  | `true`の場合、クローズしたユーザーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `closed_by.name`                                            | 文字列   | クローズしたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `closed_by.public_email`                                    | 文字列   | クローズしたユーザーの公開メールアドレス。 |
| `closed_by.state`                                           | 文字列   | クローズしたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `closed_by.username`                                        | 文字列   | マージリクエストをクローズしたユーザーのユーザー名。 |
| `closed_by.web_url`                                         | 文字列   | クローズしたユーザーのプロファイルページの完全なURL。 |
| `created_at`                                                | 日時 | マージリクエスト作成時のタイムスタンプ。 |
| `description`                                               | 文字列   | マージリクエストの説明。キャッシュ用にHTMLとしてレンダリングされたMarkdownが含まれます。 |
| `detailed_merge_status`                                     | 文字列   | 詳細なマージステータス情報。使用可能な値のリストについては、[マージ状態](#merge-status)を参照してください。 |
| `diff_refs[]`                                               | オブジェクト   | このマージリクエストのベース、HEAD、および開始SHAの参照を含むオブジェクト。マージリクエストの最新の差分バージョンに対応します。マージリクエストの作成時は空であり、非同期的に入力されます。[新規マージリクエスト用の空のAPIフィールド](#empty-api-fields-for-new-merge-requests)を参照してください。 |
| `diff_refs.base_sha`                                        | 文字列   | ソースブランチとターゲットブランチが分岐したマージベースコミットのSHA。 |
| `diff_refs.start_sha`                                       | 文字列   | ターゲットブランチコミットのSHA。差分の開始点。通常、`base_sha`と同じです。 |
| `diff_refs.head_sha`                                        | 文字列   | ソースブランチのHEADコミットのSHA。マージリクエスト内の最新のコミット。 |
| `discussion_locked`                                         | ブール値  | `true`の場合、ディスカッションはロックされます。ロックされたディスカッションでは、プロジェクトメンバーのみがコメントの追加、編集、または解決を行うことができます。 |
| `diverged_commits_count`                                    | 整数  | 設定されている場合、ソースブランチがターゲットブランチに対して遅れているコミットの数。 |
| `downvotes`                                                 | 整数  | マージリクエストに対する不同意の数。 |
| `draft`                                                     | ブール値  | `true`の場合、マージリクエストは`draft`状態としてマークされます。 |
| `first_contribution`                                        | ブール値  | `true`の場合、作成者のこのプロジェクトへの最初のコントリビュート。 |
| `first_deployed_to_production_at`                           | 日時 | 最初のデプロイメントが完了した時点のタイムスタンプ。 |
| `force_remove_source_branch`                                | ブール値  | `true`の場合、プロジェクト設定はマージ後にソースブランチの削除を強制します。 |
| `has_conflicts`                                             | ブール値  | `true`の場合、マージリクエストには競合があり、マージできません。`merge_status`プロパティに依存します。`merge_status`が`cannot_be_merged`でない限り、`false`を返します。 |
| `head_pipeline[]`                                           | オブジェクト   | マージリクエストのソースブランチのHEADコミットで実行されるパイプライン。より完全な情報が含まれているため、`pipeline`の代わりに使用します。現在のユーザーがこのプロジェクトのパイプラインを表示できる場合にのみ公開されます。 |
| `head_pipeline.before_sha`                                  | 文字列   | このパイプラインの前のコミットのSHA。 |
| `head_pipeline.committed_at`                                | 日時 | コミットが行われたときのタイムスタンプ。 |
| `head_pipeline.coverage`                                    | 数値   | テストカバレッジのパーセンテージ。例: `98.29`。 |
| `head_pipeline.created_at`                                  | 日時 | パイプラインが作成されたときのタイムスタンプ。 |
| `head_pipeline.detailed_status[]`                           | オブジェクト   | このパイプラインの詳細なステータスを含むフィールドを持つオブジェクト。 |
| `head_pipeline.detailed_status.action[]`                    | オブジェクト   | 設定されている場合、このパイプラインで利用可能なアクションを含むオブジェクト。 |
| `head_pipeline.detailed_status.action.button_title`         | 文字列   | アクションのボタンタイトル。 |
| `head_pipeline.detailed_status.action.confirmation_message` | 文字列   | アクションの確認メッセージ。 |
| `head_pipeline.detailed_status.action.icon`                 | 文字列   | アクションのアイコン。 |
| `head_pipeline.detailed_status.action.method`               | 文字列   | アクションのHTTPメソッド。例: `POST`。 |
| `head_pipeline.detailed_status.action.path`                 | 文字列   | アクションのパス。例: `"/namespace1/project1/-/jobs/2/cancel"`。 |
| `head_pipeline.detailed_status.action.title`                | 文字列   | アクションのタイトル。 |
| `head_pipeline.detailed_status.details_path`                | 文字列   | 詳細ビューへのパス。例: `"/test-group/test-project/-/pipelines/287"`。 |
| `head_pipeline.detailed_status.favicon`                     | 文字列   | ステータスファビコンへのパス。 |
| `head_pipeline.detailed_status.group`                       | 文字列   | ステータスグループ。例: `success`。 |
| `head_pipeline.detailed_status.has_details`                 | ブール値  | 設定されている場合、詳細ビューが利用可能です。 |
| `head_pipeline.detailed_status.icon`                        | 文字列   | ステータスアイコン名。例: `"status_success"`。 |
| `head_pipeline.detailed_status.illustration.content`        | 文字列   | イラストのコンテンツテキスト。例: `"This job depends on upstream jobs that need to succeed in order for this job to be triggered"`。 |
| `head_pipeline.detailed_status.illustration.image`          | 文字列   | イラスト画像へのパス。 |
| `head_pipeline.detailed_status.illustration.size`           | 文字列   | イラストのサイズ。 |
| `head_pipeline.detailed_status.illustration.title`          | 文字列   | イラストのタイトル。例: `"This job has not been triggered yet"`。 |
| `head_pipeline.detailed_status.label`                       | 文字列   | パイプラインのステータスラベル。例: `"passed"`。 |
| `head_pipeline.detailed_status.text`                        | 文字列   | パイプラインのステータステキスト（`"passed"`など）。 |
| `head_pipeline.detailed_status.tooltip`                     | 文字列   | パイプラインのツールチップテキスト（`"passed"`など）。 |
| `head_pipeline.duration`                                    | 整数  | パイプラインの実行時間（秒単位）。 |
| `head_pipeline.finished_at`                                 | 日時 | パイプラインが完了したときのタイムスタンプ。 |
| `head_pipeline.id`                                          | 整数  | パイプラインの一意の数値識別子。`ci_pipelines`テーブルへの外部キー。 |
| `head_pipeline.iid`                                         | 整数  | パイプラインの内部数値ID。 |
| `head_pipeline.project_id`                                  | 整数  | パイプラインを含むプロジェクトの数値ID。 |
| `head_pipeline.queued_duration`                             | 整数  | キューに入れられていた時間（秒単位）。 |
| `head_pipeline.ref`                                         | 文字列   | パイプラインが実行されるGit参照 (ブランチまたはタグ) の名前。 |
| `head_pipeline.sha`                                         | 文字列   | パイプラインをトリガーしたコミットのSHA。 |
| `head_pipeline.source`                                      | 文字列   | パイプラインがトリガーされた方法。例: `push`、`merge_request_event`、または`api` |
| `head_pipeline.started_at`                                  | 日時 | パイプラインの実行が開始されたときのタイムスタンプ。 |
| `head_pipeline.status`                                      | 文字列   | パイプラインの現在のステータス。使用可能な値: `success`、`failed`、`running`、`pending` |
| `head_pipeline.tag`                                         | ブール値  | `true`の場合、このパイプラインはGitタグで実行されています。 |
| `head_pipeline.updated_at`                                  | 日時 | パイプラインが最後に更新されたときのタイムスタンプ。 |
| `head_pipeline.user[]`                                      | オブジェクト   | パイプラインをトリガーしたユーザーに関する情報を含むオブジェクト。 |
| `head_pipeline.user.avatar_url`                             | 文字列   | ユーザーのアバター画像への完全なURL。 |
| `head_pipeline.user.id`                                     | 整数  | パイプラインをトリガーしたユーザーの一意のID。 |
| `head_pipeline.user.locked`                                 | ブール値  | `true`の場合、パイプラインをトリガーしたユーザーアカウントは、認証試行の失敗によりロックされており、ロックの有効期限が切れるか、管理者がアカウントのロックを解除するまでサインインできません。 |
| `head_pipeline.user.name`                                   | 文字列   | パイプラインをトリガーしたユーザーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `head_pipeline.user.public_email`                           | 文字列   | パイプラインをトリガーしたユーザーの公開メールアドレス。 |
| `head_pipeline.user.state`                                  | 文字列   | パイプラインをトリガーしたユーザーのアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `head_pipeline.user.username`                               | 文字列   | パイプラインをトリガーしたユーザーのユーザー名。 |
| `head_pipeline.user.web_url`                                | 文字列   | パイプラインをトリガーしたユーザーのプロフィールページへの完全なURL。 |
| `head_pipeline.web_url`                                     | 文字列   | パイプラインページへの完全なURL。 |
| `head_pipeline.yaml_errors`                                 | 文字列   | YAML設定のエラー。例: `widgets:build: needs 'widgets:test'`） |
| `id`                                                        | 整数  | マージリクエストのID。 |
| `iid`                                                       | 整数  | マージリクエストの内部ID。 |
| `imported`                                                  | ブール値  | `true`の場合、マージリクエストはインポートされました。 |
| `imported_from`                                             | 文字列   | インポート元。例: `Bitbucket`。 |
| `labels[]`                                                  | 配列    | マージリクエストに割り当てられたラベルの配列。`with_labels_details`が`true`の場合、各ラベルの配列を返します。 |
| `labels.archived`                                           | ブール値  | `with_labels_details`が`true`の場合、ラベルはアーカイブされます。 |
| `labels.color`                                              | 文字列   | `with_labels_details`が`true`の場合、ラベルの背景色。 |
| `labels.description`                                        | 文字列   | `with_labels_details`が`true`の場合、ラベルの記述テキスト。`null`の場合、ラベルに記述はありません。 |
| `labels.description_html`                                   | 文字列   | `with_labels_details`が`true`の場合、ラベルのHTMLレンダリングされた記述。`null`の場合、ラベルに記述はありません。 |
| `labels.id`                                                 | 整数  | `with_labels_details`が`true`の場合、ラベルの一意のID。 |
| `labels.name`                                               | 文字列   | `with_labels_details`が`true`の場合、ラベルの名前。 |
| `labels.text_color`                                         | 文字列   | `with_labels_details`が`true`の場合、ラベルのテキストカラー。 |
| `latest_build_finished_at`                                  | 日時 | マージリクエストの最新ビルドが完了した時点のタイムスタンプ。 |
| `latest_build_started_at`                                   | 日時 | マージリクエストの最新ビルドが開始された時点のタイムスタンプ。 |
| `merge_after`                                               | 日時 | 設定されている場合、マージリクエストをマージできるタイムスタンプ。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)されました。 |
| `merge_commit_sha`                                          | 文字列   | 設定されている場合、マージリクエストコミットのSHA。マージされるまで`null`を返します。 |
| `merge_error`                                               | 文字列   | 設定されている場合、マージが失敗したときに表示されるエラーメッセージ。マージ可能性を確認するには、代わりに`detailed_merge_status`を使用してください。 |
| `merge_status`                                              | 文字列   | マージリクエストの状態。すべての潜在的なステータスを考慮する`detailed_merge_status`を代わりに使用してください。`has_conflicts`プロパティに影響します。レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204)になりました。 |
| `merge_user[]`                                              | オブジェクト   | このマージリクエストをマージしたユーザー、自動マージに設定したユーザー、または`null`。 |
| `merge_when_pipeline_succeeds`                              | ブール値  | `true`の場合、マージリクエストは自動マージに設定されます。 |
| `merged_at`                                                 | 日時 | マージリクエストがマージされた時点のタイムスタンプ。 |
| `merged_by[]`                                               | オブジェクト   | このマージリクエストをマージしたユーザー、または自動マージに設定したユーザー。GitLab 14.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)となり、[APIバージョン5](https://gitlab.com/groups/gitlab-org/-/epics/8115)で削除される予定です。代わりに`merge_user`を使用してください。 |
| `milestone[]`                                               | オブジェクト   | マージリクエストに割り当てられたマイルストーンに関する情報を含むオブジェクト。 |
| `milestone.created_at`                                      | 日時 | マイルストーンが作成されたタイムスタンプ。 |
| `milestone.description`                                     | 文字列   | マイルストーンの記述テキスト。`null`の場合、マイルストーンに記述はありません。 |
| `milestone.due_date`                                        | 日付     | マイルストーンの期日。`null`の場合、マイルストーンに期日はありません。 |
| `milestone.expired`                                         | ブール値  | `true`の場合、マイルストーンは期限切れです。 |
| `milestone.group_id`                                        | 整数  | マイルストーンが属するグループのID。マイルストーンがグループマイルストーンの場合にのみ含まれます。 |
| `milestone.id`                                              | 整数  | マイルストーンの一意のID。 |
| `milestone.iid`                                             | 整数  | プロジェクトまたはグループ内のマイルストーンの内部ID。 |
| `milestone.project_id`                                      | 整数  | マイルストーンが属するプロジェクトのID。マイルストーンがプロジェクトマイルストーンの場合にのみ含まれます。 |
| `milestone.start_date`                                      | 日付     | マイルストーンの開始日。`null`の場合、マイルストーンに開始日はありません。 |
| `milestone.state`                                           | 文字列   | マイルストーンの現在の状態。例: `active`または`closed`。 |
| `milestone.title`                                           | 文字列   | マイルストーンの名前。 |
| `milestone.updated_at`                                      | 日時 | マイルストーンが最後に更新されたタイムスタンプ。 |
| `milestone.web_url`                                         | 文字列   | マイルストーンを表示するための完全なWeb URL。 |
| `pipeline[]`                                                | オブジェクト   | マージリクエストのブランチHEADで実行されているパイプライン。`head_pipeline`にはより多くの情報が含まれているため、代わりとして使用することを検討してください。 |
| `prepared_at`                                               | 日時 | マージリクエストが準備されたときのタイムスタンプ。このフィールドは、すべての[準備手順](#preparation-steps)が完了した後に1回だけ入力され、それ以上の変更が加えられても更新されません。 |
| `project_id`                                                | 整数  | マージリクエストを含むプロジェクトのID。 |
| `rebase_in_progress`                                        | ブール値  | `true`の場合、Sidekiqはこのブランチでリベース操作を実行しています。 |
| `reference`                                                 | 文字列   | 非推奨。代わりに`references`を使用してください。GitLab 12.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)となり、[APIバージョン5](https://gitlab.com/groups/gitlab-org/-/epics/8115)で削除される予定です。代わりに`references`を使用してください。 |
| `references[]`                                              | オブジェクト   | マージリクエストのすべての内部参照を含むオブジェクト。 |
| `references.full`                                           | 文字列   | 完全なプロジェクトパスを含むマージリクエストへの完全な参照。例: `gitlab-org/gitlab!123`。グループまたはプロジェクト間でリクエストされた場合、`references.relative`と同一です。 |
| `references.relative`                                       | 文字列   | 特定のプロジェクトまたはグループに対する参照。`!123`は現在のプロジェクト内のマージリクエスト、`other-project!123`は同じグループ内の別のプロジェクトのマージリクエスト。 |
| `references.short`                                          | 文字列   | 最短のマージリクエストへの参照。例: `!123`。マージリクエストのプロジェクトからフェッチされた場合、`references.relative`と同一です。 |
| `reviewers[]`                                               | 配列    | マージリクエストのレビュアー。 |
| `reviewers.avatar_url`                                      | 文字列   | レビュアーのアバター画像の完全なURL。 |
| `reviewers.id`                                              | 整数  | レビュアーの一意のID。 |
| `reviewers.locked`                                          | ブール値  | `true`の場合、レビュアーのアカウントは認証試行の失敗によりロックされており、ロックが解除されるか、管理者がアカウントを解除するまでサインインできません。 |
| `reviewers.name`                                            | 文字列   | レビュアーの表示名。現在のユーザーの権限に基づいて、削除済みの可能性があります。 |
| `reviewers.public_email`                                    | 文字列   | レビュアーの公開メールアドレス。 |
| `reviewers.state`                                           | 文字列   | レビュアーのユーザーアカウントの現在の状態。指定可能な値: `active`、`blocked`、または`deactivated`。 |
| `reviewers.username`                                        | 文字列   | マージリクエストレビュアーのユーザー名。 |
| `reviewers.web_url`                                         | 文字列   | レビュアーのプロファイルページの完全なURL。 |
| `sha`                                                       | 文字列   | ソースブランチのHEADコミットのSHA。 |
| `should_remove_source_branch`                               | ブール値  | `true`の場合、マージ後にソースブランチは削除されます。 |
| `source_branch`                                             | 文字列   | ソースブランチの名前。 |
| `source_project_id`                                         | 整数  | ソースブランチのID。 |
| `squash`                                                    | ブール値  | `true`の場合、マージ時にコミットをスカッシュします。 |
| `squash_commit_sha`                                         | 文字列   | 設定されている場合、スカッシュコミットのSHA。マージされるまで空です。 |
| `squash_on_merge`                                           | ブール値  | `true`の場合、マージ時にコミットがスカッシュされます。 |
| `state`                                                     | 文字列   | マージリクエストの現在の状態。使用可能な値: `opened`、`closed`、`merged`、または`locked`。 |
| `subscribed`                                                | ブール値  | `true`の場合、現在の認証済みユーザーはこのマージリクエストを購読します。 |
| `target_branch`                                             | 文字列   | ターゲットブランチの名前。 |
| `target_project_id`                                         | 整数  | ターゲットプロジェクトのID（数値）。 |
| `task_completion_status[]`                                  | オブジェクト   | タスクリストの完了ステータスに関する情報を含むオブジェクト。 |
| `task_completion_status.completed_count`                    | 整数  | マージリクエストの記述にある完了したタスクリストアイテムの数。マージリクエストに記述がないか、タスクリストアイテムがない場合、`0`を返します。 |
| `task_completion_status.count`                              | 整数  | マージリクエストの記述に見つかったタスクリストアイテムの総数。マージリクエストに記述がないか、タスクリストアイテムがない場合、`0`を返します。 |
| `time_stats[]`                                              | オブジェクト   | このマージリクエストのタイムトラッキングに関する情報を含むオブジェクト。 |
| `time_stats.human_time_estimate`                            | 文字列   | `time_stats.time_estimate`の人間が判読できるフォーマット。例: `3h 30m`。 |
| `time_stats.human_total_time_spent`                         | 文字列   | `time_stats.total_time_spent`の人間が判読できるフォーマット。例: `3h 30m`。 |
| `time_stats.time_estimate`                                  | 整数  | マージリクエストを完了するための推定時間（秒単位）。 |
| `time_stats.total_time_spent`                               | 整数  | マージリクエストでの作業に費やされた合計時間（秒単位）。 |
| `title`                                                     | 文字列   | マージリクエストのタイトル。 |
| `updated_at`                                                | 日時 | マージリクエストの最終更新時のタイムスタンプ。 |
| `upvotes`                                                   | 整数  | マージリクエストに対する同意の数。 |
| `user[]`                                                    | オブジェクト   | マージリクエストに対してリクエストされたユーザーの権限。 |
| `user.can_merge`                                            | ブール値  | `true`の場合、現在の認証済みユーザーはこのマージリクエストをマージすることができます。 |
| `user_notes_count`                                          | 整数  | ユーザーコメントの数。 |
| `web_url`                                                   | 文字列   | マージリクエストを表示するためのWeb URL。 |
| `work_in_progress`                                          | ブール値  | 非推奨。代わりに`draft`を使用してください。 |

レスポンス例: 

```json
{
  "id": 155016530,
  "iid": 133,
  "project_id": 15513260,
  "title": "Manual job rules",
  "description": "",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "created_at": "2022-05-13T07:26:38.402Z",
  "updated_at": "2022-05-14T03:38:31.354Z",
  "merged_by": null, // Deprecated and will be removed in API v5. Use `merge_user` instead.
  "merge_user": null,
  "merged_at": null,
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "target_branch": "main",
  "source_branch": "manual-job-rules",
  "user_notes_count": 0,
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 4155490,
    "username": "marcel.amirault",
    "name": "Marcel Amirault",
    "state": "active",
    "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
    "web_url": "https://gitlab.com/marcel.amirault"
  },
  "assignees": [],
  "assignee": null,
  "reviewers": [],
  "source_project_id": 15513260,
  "target_project_id": 15513260,
  "labels": [],
  "draft": false,
  "work_in_progress": false,
  "milestone": null,
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "mergeable",
  "sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "discussion_locked": null,
  "should_remove_source_branch": null,
  "force_remove_source_branch": true,
  "reference": "!133", // Deprecated. Use `references` instead.
  "references": {
    "short": "!133",
    "relative": "!133",
    "full": "marcel.amirault/test-project!133"
  },
  "web_url": "https://gitlab.com/marcel.amirault/test-project/-/merge_requests/133",
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
  "has_conflicts": false,
  "blocking_discussions_resolved": true,
  "approvals_before_merge": null, // deprecated, use [Merge request approvals API](merge_request_approvals.md)
  "subscribed": true,
  "changes_count": "1",
  "latest_build_started_at": "2022-05-13T09:46:50.032Z",
  "latest_build_finished_at": null,
  "first_deployed_to_production_at": null,
  "pipeline": { // Use `head_pipeline` instead.
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940"
  },
  "head_pipeline": {
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940",
    "before_sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "tag": false,
    "yaml_errors": null,
    "user": {
      "id": 4155490,
      "username": "marcel.amirault",
      "name": "Marcel Amirault",
      "state": "active",
      "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
      "web_url": "https://gitlab.com/marcel.amirault"
    },
    "started_at": "2022-05-13T09:46:50.032Z",
    "finished_at": "2022-05-13T09:47:20.697Z",
    "committed_at": null,
    "duration": 30,
    "queued_duration": 10,
    "coverage": null,
    "detailed_status": {
      "icon": "status_failed",
      "text": "failed",
      "label": "failed",
      "group": "failed",
      "tooltip": "failed",
      "has_details": true,
      "details_path": "/marcel.amirault/test-project/-/pipelines/538317940",
      "illustration": null,
      "favicon": "/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png"
    },
    "archived": false
  },
  "diff_refs": {
    "base_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab",
    "head_sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
    "start_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab"
  },
  "merge_error": null,
  "first_contribution": false,
  "user": {
    "can_merge": true
  },
  "approvals_before_merge": { // Available for GitLab Premium and Ultimate tiers only
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
  },
}
```

### 単一のマージリクエストのレスポンスに関する注記 {#single-merge-request-response-notes}

各マージリクエストのマージ可能性（`merge_status`）は、このエンドポイントに対してリクエストが行われるときに非同期的にチェックされます。更新されたステータスを取得するには、このAPIエンドポイントをポーリングします。これは`merge_status`に依存するため、`has_conflicts`プロパティに影響します。`merge_status`が`cannot_be_merged`ではない場合には、`false`を返します。

### マージの状態 {#merge-status}

表示される可能性があるすべてのステータスを考慮するために、`merge_status`の代わりに`detailed_merge_status`を使用してください。

- `detailed_merge_status`フィールドには、マージリクエストに関連する次のいずれかの値を指定できます。
  - `approvals_syncing`: マージリクエストの承認を同期しています。
  - `checking`: Gitは有効なマージが可能かどうかをテストしています。
  - `ci_must_pass`: マージする前にCI/CDパイプラインが成功する必要があります。
  - `ci_still_running`: CI/CDパイプラインがまだ実行中です。
  - `commits_status`: ソースブランチが存在し、コミットが含まれている必要があります。
  - `conflict`: ソースブランチとターゲットブランチの間に競合があります。
  - `discussions_not_resolved`: マージリクエストをマージする前に、すべてのディスカッションを解決する必要があります。
  - `draft_status`: マージリクエストがドラフトであるため、マージできません。
  - `jira_association_missing`: タイトルまたは説明でJiraのイシューを参照する必要があります。設定するには、[マージされるリクエストに対する関連Jiraイシューを要求](../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged)を参照してください。
  - `mergeable`: ブランチは、ターゲットブランチに問題なくマージできます。
  - `merge_request_blocked`: 別のマージリクエストによってブロックされています。
  - `merge_time`: 指定された時刻を経過するまでマージできません。
  - `need_rebase`: マージリクエストをリベースする必要があります。
  - `not_approved`: マージする前に承認が必要です。
  - `not_open`: マージする前に、マージリクエストを開く必要があります。
  - `preparing`: マージリクエストの差分を作成しています。
  - `requested_changes`: マージリクエストには、変更をリクエストしたレビュアーがいます。
  - `security_policy_pipeline_check`: セキュリティポリシーが適用されている場合、最新のコミットに対するすべてのパイプラインは、マージリクエストがマージされる前に成功する必要があります。
  - `security_policy_violations`: すべてのセキュリティポリシーを満たす必要があります。
  - `status_checks_must_pass`: マージする前に、すべての状態チェックに合格する必要があります。
  - `unchecked`: Gitは、有効なマージが可能かどうかをまだテストしていません。
  - `locked_paths`: デフォルトブランチにマージする前に、他のユーザーによってロックされているパスをロック解除する必要があります。
  - `locked_lfs_files`: マージする前に、他のユーザーによってロックされているLFSファイルをロック解除する必要があります。
  - `title_regex`: プロジェクト設定で設定されている場合、タイトルが予期される正規表現に一致するかどうかを確認します。

### 準備手順 {#preparation-steps}

`prepared_at`フィールドは、以下の手順が完了した後に1回だけ入力された状態になります。

- 差分を作成する。
- パイプラインを作成する。
- マージ可能性を確認する。
- すべてのGit LFSオブジェクトをリンクする。
- 通知を送信する。

マージリクエストにさらに変更が加えられた場合、`prepared_at`フィールドは更新されません。

## マージリクエストの参加者を取得する {#retrieve-merge-request-participants}

マージリクエストの参加者を取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  },
  {
    "id": 2,
    "name": "John Doe2",
    "username": "user2",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
    "web_url": "http://localhost/user2"
  }
]
```

## マージリクエストレビュアーを取得する {#retrieve-merge-request-reviewers}

マージリクエストのレビュアーを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/reviewers
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

レスポンス例: 

```json
[
  {
    "user": {
      "id": 1,
      "name": "John Doe1",
      "username": "user1",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
      "web_url": "http://localhost/user1"
    },
    "state": "unreviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  },
  {
    "user": {
      "id": 2,
      "name": "John Doe2",
      "username": "user2",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
      "web_url": "http://localhost/user2"
    },
    "state": "reviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  }
]
```

## マージリクエストコミットを取得する {#retrieve-merge-request-commits}

マージリクエストのコミットを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                     | 型         | 説明 |
|-------------------------------|--------------|-------------|
| `commits`                     | オブジェクト配列 | マージリクエスト内のコミット。 |
| `commits[].id`                | 文字列       | コミットのID。 |
| `commits[].short_id`          | 文字列       | コミットの短いID。 |
| `commits[].created_at`        | 日時     | `committed_date`フィールドと同一です。 |
| `commits[].parent_ids`        | 配列        | 親コミットのID。 |
| `commits[].title`             | 文字列       | コミットタイトル。 |
| `commits[].message`           | 文字列       | コミットメッセージ。 |
| `commits[].author_name`       | 文字列       | コミット作成者の名前。 |
| `commits[].author_email`      | 文字列       | コミット作成者のメールアドレス。 |
| `commits[].authored_date`     | 日時     | コミットの作成日時。 |
| `commits[].committer_name`    | 文字列       | コミッターの名前。 |
| `commits[].committer_email`   | 文字列       | コミッターのメールアドレス。 |
| `commits[].committed_date`    | 日時     | コミット日時。 |
| `commits[].trailers`          | オブジェクト       | コミットについて解析されたGitトレーラー。重複するキーには最後の値のみが含まれます。 |
| `commits[].extended_trailers` | オブジェクト       | コミットについて解析されたGitトレーラー。 |
| `commits[].web_url`           | 文字列       | マージリクエストのWeb URL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/commits"
```

レスポンス例: 

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T11:50:22+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T11:50:22+03:00",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T09:06:12+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T09:06:12+03:00",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
  }
]
```

## マージリクエストの依存関係を取得する {#retrieve-merge-request-dependencies}

マージリクエストがマージされる前に解決する必要がある依存関係を取得する。

> [!note]
> ユーザーがブロック中のマージリクエストにアクセスできない場合、`blocking_merge_request`属性は返されません。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blocks
```

サポートされている属性は以下のとおりです: 

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "blocking_merge_request": {
      "id": 145,
      "iid": 12,
      "project_id": 7,
      "title": "Interesting MR",
      "description": "Does interesting things.",
      "state": "opened",
      "created_at": "2024-07-05T21:29:11.172Z",
      "updated_at": "2024-07-05T21:29:11.172Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "v2.x",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        },
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "unchecked",
      "detailed_merge_status": "unchecked",
      "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!12",
      "references": {
        "short": "!12",
        "relative": "!12",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 146,
      "iid": 13,
      "project_id": 7,
      "title": "Really cool MR",
      "description": "Adds some stuff",
      "state": "opened",
      "created_at": "2024-07-05T21:31:34.811Z",
      "updated_at": "2024-07-27T02:57:08.054Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "remove-from",
      "user_notes_count": 0,
      "upvotes": 1,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhose/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": {
        "id": 59,
        "iid": 6,
        "project_id": 7,
        "title": "Sprint 1718897375",
        "description": "Accusantium omnis iusto a animi.",
        "state": "active",
        "created_at": "2024-06-20T15:29:35.739Z",
        "updated_at": "2024-06-20T15:29:35.739Z",
        "due_date": null,
        "start_date": null,
        "expired": false,
        "web_url": "https://localhost/my-group/my-project/-/milestones/6"
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "not_approved",
      "sha": "daa75b9b17918f51f43866ff533987fda71375ea",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": "2024-07-11T18:50:46.215Z",
      "reference": "!13",
      "references": {
        "short": "!13",
        "relative": "!13",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/13",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## マージリクエストの依存関係を削除する {#delete-a-merge-request-dependency}

マージリクエストの依存関係を削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/blocks/:block_id
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | 認証されたユーザーが所有しているプロジェクトのIDまたは[エンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |
| `block_id`          | 整数           | はい      | ブロックのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks/1"
```

戻り値:

- 依存関係が正常に削除された場合は、`204 No Content`。
- マージリクエストを更新するための権限がユーザーにない場合は、`403 Forbidden`。
- ブロックしているマージリクエストを読むための権限がユーザーにない場合は、`403 Forbidden`。

## マージリクエストの依存関係を作成する {#create-a-merge-request-dependency}

マージリクエストの依存関係を作成します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/blocks
```

サポートされている属性は以下のとおりです: 

| 属性                    | 型              | 必須    | 説明 |
|------------------------------|-------------------|-------------|-------------|
| `id`                         | 整数または文字列 | はい         | 認証されたユーザーが所有しているプロジェクトのIDまたは[エンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`          | 整数           | はい         | ブロックされるマージリクエストの内部ID。 |
| `blocking_merge_request_id`  | 整数           | 条件付き | ブロック中のマージリクエストのグローバルID。`blocking_merge_request_iid`が提供されない場合、必須です。 |
| `blocking_merge_request_iid` | 整数           | 条件付き | ブロック中のマージリクエストのIID。`blocking_merge_request_id`が提供されない場合、必須です。 |
| `blocking_project_id`        | 整数または文字列 | いいえ          | ブロック中のマージリクエストを含むプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。`blocking_merge_request_iid`が異なるプロジェクトのマージリクエストを参照する場合、必須です。現在のプロジェクトにデフォルトで設定されます。 |

IIDを使用したリクエストの例（同じプロジェクト）:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_iid=2"
```

IIDを使用したリクエストの例（クロスプロジェクト）:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_iid=5&blocking_project_id=2"
```

グローバルIDを使用したリクエストの例（レガシーメソッド）:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_id=12345"
```

戻り値:

- 依存関係が正常に作成された場合は`201 Created`。
- ブロックしているマージリクエストの保存に失敗した場合は、`400 Bad request`。
- ブロックしているマージリクエストを読むための権限がユーザーにない場合は、`403 Forbidden`。
- ブロックしているマージリクエストが見つからない場合は、`404 Not found`。
- ブロックがすでに存在する場合は、`409 Conflict`。

レスポンス例: 

```json
{
  "id": 1,
  "blocking_merge_request": {
    "id": 145,
    "iid": 12,
    "project_id": 7,
    "title": "Interesting MR",
    "description": "Does interesting things.",
    "state": "opened",
    "created_at": "2024-07-05T21:29:11.172Z",
    "updated_at": "2024-07-05T21:29:11.172Z",
    "merged_by": null,
    "merge_user": null,
    "merged_at": null,
    "merge_after": "2018-09-07T11:16:00.000Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "master",
    "source_branch": "v2.x",
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 2,
      "username": "aiguy123",
      "name": "AI GUY",
      "state": "active",
      "locked": false,
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "https://localhost/aiguy123"
    },
    "assignees": [
      {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      }
    ],
    "assignee": {
      "id": 2,
      "username": "aiguy123",
      "name": "AI GUY",
      "state": "active",
      "locked": false,
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "https://localhost/aiguy123"
    },
    "reviewers": [
      {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/root"
      }
    ],
    "source_project_id": 7,
    "target_project_id": 7,
    "labels": [],
    "draft": false,
    "imported": false,
    "imported_from": "none",
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "detailed_merge_status": "unchecked",
    "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "prepared_at": null,
    "reference": "!12",
    "references": {
      "short": "!12",
      "relative": "!12",
      "full": "my-group/my-project!12"
    },
    "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "squash_on_merge": false,
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": null
  },
  "project_id": 7
}
```

## ブロックされたマージリクエストを取得する {#retrieve-blocked-merge-requests}

マージリクエストによってブロックされたマージリクエストを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blockees
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blockees"
```

レスポンス例: 

```json
[
  {
    "id": 18,
    "blocking_merge_request": {
      "id": 71,
      "iid": 10,
      "project_id": 7,
      "title": "At quaerat occaecati voluptate ex explicabo nisi.",
      "description": "Aliquid distinctio officia corrupti ad nemo natus ipsum culpa.",
      "state": "merged",
      "created_at": "2024-07-05T19:44:14.023Z",
      "updated_at": "2024-07-05T19:44:14.023Z",
      "merged_by": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merge_user": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merged_at": "2024-06-26T19:44:14.123Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "Brickwood-Brunefunc-417",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "can_be_merged",
      "detailed_merge_status": "not_open",
      "merge_after": null,
      "sha": null,
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": null,
      "prepared_at": null,
      "reference": "!10",
      "references": {
        "short": "!10",
        "relative": "!10",
        "full": "flightjs/Flight!10"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/10",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 176,
      "iid": 14,
      "project_id": 7,
      "title": "second_mr",
      "description": "Signed-off-by: Lucas Zampieri <lzampier@redhat.com>",
      "state": "opened",
      "created_at": "2024-07-08T19:12:29.089Z",
      "updated_at": "2024-08-27T19:27:17.045Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "second_mr",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/fc3634394c590e212d964e8e0a34c4d9b8c17c992f4d6d145d75f9c21c1c3b6e?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "commits_status",
      "merge_after": null,
      "sha": "3a576801e528db79a75fbfea463673054ff224fb",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!14",
      "references": {
        "short": "!14",
        "relative": "!14",
        "full": "flightjs/Flight!14"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/14",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## マージリクエストの変更を取得する {#retrieve-merge-request-changes}

> [!warning]
> このエンドポイントはGitLab 15.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/322117)になり、API v5で[削除が予定されています](rest/deprecations.md)。代わりに[マージリクエストの差分を一覧表示](#list-merge-request-diffs)エンドポイントを使用してください。
> <!-- Do not remove line until endpoint is actually removed -->

マージリクエストに関する情報（ファイルや変更を含む）を取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |
| `access_raw_diffs`  | ブール値           | いいえ       | Gitaly経由で変更差分を取得します。 |
| `unidiff`           | ブール値           | いいえ       | [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html)形式で変更差分を表示します。デフォルトはfalseです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610)されました。 |

一連の変更に関連付けられた差分には、APIによって返される他の差分、またはUIで表示される他の差分と同じサイズの制限が適用されます。これらの制限が結果に影響する場合、`overflow`フィールドには値`true`が含まれます。このような制限なしで差分データを取得するには、`access_raw_diffs`パラメータを追加します。これにより、データベースからではなく、Gitalyから直接差分にアクセスします。このアプローチは一般に時間がかかり、リソースを大量に消費しますが、データベースを基盤とする差分に適用されるサイズ制限の対象にはなりません。Gitalyに固有の制限は引き続き適用されます。

レスポンス例: 

```json
{
  "id": 21,
  "iid": 1,
  "project_id": 4,
  "title": "Blanditiis beatae suscipit hic assumenda et molestias nisi asperiores repellat et.",
  "state": "reopened",
  "created_at": "2015-02-02T19:49:39.159Z",
  "updated_at": "2015-02-02T20:08:49.959Z",
  "target_branch": "secret_token",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Chad Hamill",
    "username": "jarrett",
    "id": 5,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/b95567800f828948baf5f4160ebb2473?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/jarrett"
  },
  "assignee": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/root"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "Qui voluptatibus placeat ipsa alias quasi. Deleniti rem ut sint. Optio velit qui distinctio.",
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "mergeable",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "changes": [
    {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
    }
  ],
  "overflow": false
}
```

## マージリクエストの差分のリストを取得する {#list-merge-request-diffs}

{{< history >}}

- `generated_file`は、GitLab 16.9で`collapse_generated_diff_files`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141576)されました。デフォルトでは無効になっています。
- GitLab 16.10で、[GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/432670)で有効化されました。
- `generated_file`は、GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478)となりました。機能フラグ`collapse_generated_diff_files`は削除されました。
- `collapsed`および`too_large`のレスポンス属性が、GitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633)。

{{< /history >}}

マージリクエストで変更されたファイルの差分をリスト表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/diffs
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |
| `page`              | 整数           | いいえ       | 返される結果のページ。デフォルトは1です。 |
| `per_page`          | 整数           | いいえ       | ページあたりの結果数。デフォルトは20です。 |
| `unidiff`           | ブール値           | いいえ       | [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html)形式で差分を表示します。デフォルトはfalseです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610)されました。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性        | 型    | 説明 |
|------------------|---------|-------------|
| `a_mode`         | 文字列  | ファイルの古いファイルモード。 |
| `b_mode`         | 文字列  | ファイルの新しいファイルモード。 |
| `collapsed`      | ブール値 | ファイルの差分は除外されていますが、リクエストに応じてフェッチできます。 |
| `deleted_file`   | ブール値 | ファイルは削除されました。 |
| `diff`           | 文字列  | ファイルに加えられた変更の差分の表現。 |
| `generated_file` | ブール値 | ファイルは[生成されたものとしてマーク](../user/project/merge_requests/changes.md#collapse-generated-files)されています。 |
| `new_file`       | ブール値 | ファイルが追加されました。 |
| `new_path`       | 文字列  | ファイルの新しいパス。 |
| `old_path`       | 文字列  | ファイルの古いパス。 |
| `renamed_file`   | ブール値 | ファイルの名前が変更されました。 |
| `too_large`      | ブール値 | ファイルの差分は除外されており、取得できません。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/diffs?page=1&per_page=2"
```

レスポンス例: 

```json
[
  {
    "old_path": "README",
    "new_path": "README",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -Title\ +README",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  },
  {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@\ -1.9.7\ +1.9.8",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }
]
```

> [!note]
> このエンドポイントは[マージリクエストの差分制限](../administration/instance_limits.md#diff-limits)の対象です。差分制限を超えるマージリクエストは、結果が制限されて返されます。

## マージリクエストのraw diffを表示する {#show-merge-request-raw-diffs}

マージリクエストで変更されたファイルのraw diffを表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/raw_diffs
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、プログラムで使用するraw difレスポンスを返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/raw_diffs"
```

レスポンス例: 

```diff
        diff --git a/lib/api/helpers.rb b/lib/api/helpers.rb
index 31525ad523553c8d7eff163db3e539058efd6d3a..f30e36d6fdf4cd4fa25f62e08ecdbf4a7b169681 100644
--- a/lib/api/helpers.rb
+++ b/lib/api/helpers.rb
@@ -944,6 +944,10 @@ def send_git_blob(repository, blob)
       body ''
     end

+    def send_git_diff(repository, diff_refs)
+      header(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))
+    end
+
     def send_git_archive(repository, **kwargs)
       header(*Gitlab::Workhorse.send_git_archive(repository, **kwargs))

diff --git a/lib/api/merge_requests.rb b/lib/api/merge_requests.rb
index e02d9eea1852f19fe5311acda6aa17465eeb422e..f32b38585398a18fea75c11d7b8ebb730eeb3fab 100644
--- a/lib/api/merge_requests.rb
+++ b/lib/api/merge_requests.rb
@@ -6,6 +6,8 @@ class MergeRequests < ::API::Base
     include PaginationParams
     include Helpers::Unidiff

+    helpers ::API::Helpers::HeadersHelpers
+
     CONTEXT_COMMITS_POST_LIMIT = 20

     before { authenticate_non_get! }
```

> [!note]
> このエンドポイントは[マージリクエストの差分制限](../administration/instance_limits.md#diff-limits)の対象です。差分制限を超えるマージリクエストは、結果が制限されて返されます。

## マージリクエストパイプラインのリストを取得する {#list-merge-request-pipelines}

マージリクエストのすべてのパイプラインを一覧表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

マージリクエストパイプラインのリストを制限するには、ページネーションパラメータ`page`と`per_page`を使用します。

レスポンス例: 

```json
[
  {
    "id": 77,
    "sha": "959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d",
    "ref": "main",
    "status": "success"
  }
]
```

## マージリクエストパイプラインを作成する {#create-merge-request-pipeline}

[マージリクエストの新しいパイプライン](../ci/pipelines/merge_request_pipelines.md)を作成します。このエンドポイントから作成されたパイプラインは、標準のブランチ/タグパイプラインを実行しません。ジョブを作成するには、`only: [merge_requests]`を使用して`.gitlab-ci.yml`を設定します。

新しいパイプラインは次のいずれかになります。

- デタッチされたマージリクエストパイプライン。
- [プロジェクト設定が有効](../ci/pipelines/merged_results_pipelines.md#enable-merged-results-pipelines)な場合は、[マージ結果パイプライン](../ci/pipelines/merged_results_pipelines.md)。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/pipelines
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

レスポンス例: 

```json
{
  "id": 2,
  "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
  "ref": "refs/merge-requests/1/head",
  "status": "pending",
  "web_url": "http://localhost/user1/project1/pipelines/2",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://example.com"
  },
  "created_at": "2019-09-04T19:20:18.267Z",
  "updated_at": "2019-09-04T19:20:18.459Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_pending",
    "text": "pending",
    "label": "pending",
    "group": "pending",
    "tooltip": "pending",
    "has_details": false,
    "details_path": "/user1/project1/pipelines/2",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png"
  },
  "archived": false
}
```

## マージリクエストを作成する {#create-a-merge-request}

新しいマージリクエストを作成します。

```plaintext
POST /projects/:id/merge_requests
```

| 属性                  | 型              | 必須 | 説明 |
|----------------------------|-------------------|----------|-------------|
| `id`                       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `source_branch`            | 文字列            | はい      | ソースブランチ。 |
| `target_branch`            | 文字列            | はい      | ターゲットブランチ。 |
| `title`                    | 文字列            | はい      | MRのタイトル。 |
| `allow_collaboration`      | ブール値           | いいえ       | ターゲットブランチにマージできるメンバーからのコミットを許可します。 |
| `approvals_before_merge`   | 整数           | いいえ       | このマージリクエストをマージする前に必要な承認の数（下記参照）。承認ルールを設定するには、[マージリクエストの承認API](merge_request_approvals.md)を参照してください。GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。PremiumおよびUltimateのみです。 |
| `allow_maintainer_to_push` | ブール値           | いいえ       | `allow_collaboration`のエイリアス。 |
| `assignee_id`              | 整数           | いいえ       | 担当者のユーザーID。 |
| `assignee_ids`             | 整数の配列     | いいえ       | マージリクエストを割り当てるユーザーのID。すべての担当者の割り当てを解除するには、`0`に設定するか、空の値を指定します。 |
| `description`              | 文字列            | いいえ       | マージリクエストの説明。1,048,576文字に制限されています。 |
| `labels`                   | 文字列            | いいえ       | マージリクエストのラベル（カンマ区切りのリスト）。ラベルがまだ存在しない場合は、新しいプロジェクトラベルが作成され、マージリクエストに割り当てられます。 |
| `merge_after`              | 文字列            | いいえ       | マージリクエストをマージできるようになる日付。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)されました。 |
| `milestone_id`             | 整数           | いいえ       | マイルストーンのグローバルID。`milestone`と相互に排他的です。 |
| `milestone`                | 文字列            | いいえ       | プロジェクトまたは祖先グループのマイルストーンのタイトルを、マージリクエストに割り当てます。完全一致（大文字と小文字を区別）。`milestone_id`と相互に排他的です。 |
| `remove_source_branch`     | ブール値           | いいえ       | マージ時にマージリクエストがソースブランチを削除するかどうかを示すフラグ。 |
| `reviewer_ids`             | 整数の配列     | いいえ       | マージリクエストにレビュアーとして追加されたユーザーのID。すべてのレビュアーの設定を解除するには、値を`0`に設定するか、空のままにすると、レビュアーは追加されません。 |
| `squash`                   | ブール値           | いいえ       | `true`の場合、マージ時にすべてのコミットを単一のコミットにスカッシュします。提供されない場合、[プロジェクトのスカッシュオプション設定](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)にデフォルトで設定されます。プロジェクトの設定が、マージ時にこの値を上書きする可能性があります。 |
| `target_project_id`        | 整数           | いいえ       | ターゲットプロジェクトのID（数値）。 |

レスポンス例: 

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "imported": false,
  "imported_from": "none",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。

## マージリクエストを更新する {#update-a-merge-request}

既存のマージリクエストを更新します。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid
```

| 属性                  | 型              | 必須 | 説明 |
|----------------------------|-------------------|----------|-------------|
| `id`                       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`        | 整数           | はい      | マージリクエストのID。 |
| `add_labels`               | 文字列            | いいえ       | マージリクエストに追加するラベル名のカンマ区切りリスト。ラベルがまだ存在しない場合は、新しいプロジェクトラベルが作成され、マージリクエストに割り当てられます。 |
| `allow_collaboration`      | ブール値           | いいえ       | ターゲットブランチにマージできるメンバーからのコミットを許可します。 |
| `allow_maintainer_to_push` | ブール値           | いいえ       | `allow_collaboration`のエイリアス。 |
| `assignee_id`              | 整数           | いいえ       | マージリクエストを割り当てるユーザーのID。すべての担当者の割り当てを解除するには、`0`に設定するか、空の値を指定します。 |
| `assignee_ids`             | 整数の配列     | いいえ       | マージリクエストを割り当てるユーザーのID。すべての担当者の割り当てを解除するには、`0`に設定するか、空の値を指定します。 |
| `description`              | 文字列            | いいえ       | マージリクエストの説明。1,048,576文字に制限されています。 |
| `discussion_locked`        | ブール値           | いいえ       | マージリクエストのディスカッションがロックされているかどうかを示すフラグ。ロックされているディスカッションでは、プロジェクトメンバーのみがコメントを追加、編集、または解決できます。 |
| `labels`                   | 文字列            | いいえ       | マージリクエストのラベル名のカンマ区切りリスト。すべてのラベルの割り当てを解除するには、空の文字列に設定します。ラベルがまだ存在しない場合は、新しいプロジェクトラベルが作成され、マージリクエストに割り当てられます。 |
| `merge_after`              | 文字列            | いいえ       | マージリクエストをマージできるようになる日付。GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510992)されました。 |
| `milestone_id`             | 整数           | いいえ       | マージリクエストを割り当てるマイルストーンのグローバルID。マイルストーンの割り当てを解除するには、`0`に設定するか、空の値を指定します。`milestone`と相互に排他的です。 |
| `milestone`                | 文字列            | いいえ       | プロジェクトまたは祖先グループのマイルストーンのタイトルを、マージリクエストに割り当てます。完全一致（大文字と小文字を区別）。`milestone_id`と相互に排他的です。 |
| `remove_labels`            | 文字列            | いいえ       | マージリクエストから削除するラベル名のカンマ区切りリスト。 |
| `remove_source_branch`     | ブール値           | いいえ       | マージ時にマージリクエストがソースブランチを削除するかどうかを示すフラグ。 |
| `reviewer_ids`             | 整数の配列     | いいえ       | マージリクエストにレビュアーとして設定されたユーザーのID。すべてのレビュアーの設定を解除するには、値を`0`に設定するか、空の値を指定します。 |
| `squash`                   | ブール値           | いいえ       | `true`の場合、マージ時にすべてのコミットを単一のコミットにスカッシュします。提供されない場合、[プロジェクトのスカッシュオプション設定](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)にデフォルトで設定されます。プロジェクトがスカッシュを**必須**または**許可しない**ように設定されている場合、その設定がマージ時に優先されます。 |
| `state_event`              | 文字列            | いいえ       | 新しい状態（close/reopen）。 |
| `target_branch`            | 文字列            | いいえ       | ターゲットブランチ。 |
| `title`                    | 文字列            | いいえ       | MRのタイトル。 |

上記の属性のうち、必須ではない属性を1つ以上含める必要があります。

レスポンス例: 

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。

## マージリクエストを削除する {#delete-a-merge-request}

マージリクエストを削除します。管理者とプロジェクトオーナーのみがマージリクエストを削除できます。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/merge_requests/85"
```

## マージリクエストをマージする {#merge-a-merge-request}

{{< history >}}

- [マージトレイン](../ci/pipelines/merge_trains.md)が有効なプロジェクトにおけるマージトレインへの`auto_merge`リクエストのルーティングは、GitLab 19.1で`fix_merge_api_train_bypass`という名前の[機能フラグ](../administration/feature_flags/_index.md)によって[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237922)されました。デフォルトでは無効になっています。直接マージする代わりに、マージリクエストがマージトレインに追加されます。
- 機能フラグ`fix_merge_api_train_bypass`はGitLab 19.1で削除されました。

{{< /history >}}

このAPIを使用して、マージリクエストで送信された変更を受け入れてマージします。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

サポートされている属性は以下のとおりです: 

| 属性                      | 型              | 必須 | 説明 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`            | 整数           | はい      | マージリクエストの内部ID。 |
| `auto_merge`                   | ブール値           | いいえ       | もし`true`であれば、チェックがパスするとマージリクエストがマージされます。 |
| `merge_commit_message`         | 文字列            | いいえ       | カスタムGitLab Duoマージコミットメッセージ。 |
| `merge_when_pipeline_succeeds` | ブール値           | いいえ       | GitLab 17.11で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/521291)になりました。代わりに`auto_merge`を使用してください。 |
| `sha`                          | 文字列            | いいえ       | 存在する場合、このSHAはソースブランチのHEADと一致する必要があります。レビューされたコミットのみがマージされることを保証するために使用します。 |
| `should_remove_source_branch`  | ブール値           | いいえ       | `true`の場合、ソースブランチを削除します。 |
| `squash_commit_message`        | 文字列            | いいえ       | カスタムスカッシュコミットメッセージ。 |
| `squash`                       | ブール値           | いいえ       | `true`の場合、マージ時にすべてのコミットを単一のコミットにスカッシュします。 |

このAPIは、失敗時に特定のHTTPステータスコードを返します。

| HTTPステータス | メッセージ                                    | 理由 |
|-------------|--------------------------------------------|--------|
| `401`       | `401 Unauthorized`                         | このユーザーには、このマージリクエストを受け入れる権限がありません。 |
| `405`       | `405 Method Not Allowed`                   | マージリクエストをマージできません。 |
| `409`       | `SHA does not match HEAD of source branch` | 指定された`sha`パラメータがソースのHEADと一致しません。 |
| `422`       | `Branch cannot be merged`                  | マージリクエストのマージに失敗しました。 |

レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。

レスポンス例: 

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

## デフォルトのマージrefパスへマージする {#merge-to-default-merge-ref-path}

可能であれば、マージリクエストのソースブランチとターゲットブランチ間の変更を、ターゲットプロジェクトリポジトリの`refs/merge-requests/:iid/merge` refにマージします。このrefには、標準マージアクションが実行された場合のターゲットブランチの状態が含まれています。

このアクションは、マージリクエストのターゲットブランチの状態を一切変更しないため、標準マージアクションではありません。

このref（`refs/merge-requests/:iid/merge`）は、このAPIにリクエストを送信するときに必ずしも上書きされるわけではありませんが、refに可能な限り最新の状態が含まれるようにします。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/merge_ref
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

このAPIは特定のHTTPステータスコードを返します:

| HTTPステータス | メッセージ                          | 理由 |
|-------------|----------------------------------|--------|
| `200`       | _（なし）_                         | 成功。`refs/merge-requests/:iid/merge`のHEADコミットを返します。 |
| `400`       | `Merge request is not mergeable` | マージリクエストに競合があります。 |
| `400`       | `Merge ref cannot be updated`    |        |
| `400`       | `Unsupported operation`          | GitLabデータベースは読み取り専用モードです。 |

レスポンス例: 

```json
{
  "commit_id": "854a3a7a17acbcc0bbbea170986df1eb60435f34"
}
```

## パイプライン成功時にマージをキャンセルする {#cancel-merge-when-pipeline-succeeds}

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

このAPIは特定のHTTPステータスコードを返します:

| HTTPステータス | メッセージ  | 理由 |
|-------------|----------|--------|
| `201`       | _（なし）_ | 成功、またはマージリクエストがすでにマージされています。 |
| `406`       | `Can't cancel the automatic merge` | マージリクエストは完了されています。 |

レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。

レスポンス例: 

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

## マージリクエストをリベースする {#rebase-a-merge-request}

マージリクエストの`source_branch`を`target_branch`に対して自動的にリベースします。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数        | はい      | マージリクエストの内部ID。 |
| `skip_ci`           | ブール値        | いいえ       | CIパイプラインの作成をスキップするには、`true`に設定します。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/rebase"
```

このAPIは特定のHTTPステータスコードを返します:

| HTTPステータス | メッセージ                                    | 理由 |
|-------------|--------------------------------------------|--------|
| `202`       | _（メッセージなし）_ | 正常にキューに追加されました。 |
| `403`       | `Cannot push to source branch` | マージリクエストのソースブランチにプッシュする権限がありません。 |
| `403`       | `Source branch does not exist` | マージリクエストのソースブランチにプッシュする権限がありません。 |
| `403`       | `Source branch is protected from force push` | マージリクエストのソースブランチにプッシュする権限がありません。 |
| `409`       | `Failed to enqueue the rebase operation` | 長時間実行されるトランザクションによってリクエストがブロックされた可能性があります。 |

リクエストがキューに正常に追加された場合、レスポンスには以下の内容が含まれます:

```json
{
  "rebase_in_progress": true
}
```

[マージリクエストを取得する](#retrieve-a-merge-request)エンドポイントを`include_rebase_in_progress`パラメータと共にポーリングして、非同期リクエストのステータスを確認できます。

リベース操作が進行中の場合、レスポンスには以下の内容が含まれます。

```json
{
  "rebase_in_progress": true,
  "merge_error": null
}
```

リベース操作が正常に完了すると、レスポンスには以下の内容が含まれます。

```json
{
  "rebase_in_progress": false,
  "merge_error": null
}
```

リベース操作が失敗した場合、レスポンスには以下の内容が含まれます。

```json
{
  "rebase_in_progress": false,
  "merge_error": "Rebase failed. Please rebase locally"
}
```

## マージリクエストに関するノート {#comments-on-merge-requests}

[ノート](notes.md)リソースはコメントを作成します。

## マージ時に完了するイシューのリストを取得する {#list-issues-that-close-on-merge}

マージリクエストがマージされたときにクローズされるイシューを一覧表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/closes_issues
```

サポートされている属性は以下のとおりです: 

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)を返します。GitLabイシュートラッカーを使用すると、次のレスポンス属性が返されます。

| 属性                   | 型     | 説明 |
|-----------------------------|----------|-------------|
| `[].assignee`               | オブジェクト   | イシューの最初の担当者。 |
| `[].assignees`              | 配列    | イシューの担当者。 |
| `[].author`                 | オブジェクト   | このイシューを作成したユーザー。 |
| `[].blocking_issues_count`  | 整数  | このイシューがブロックしているイシューの数。 |
| `[].closed_at`              | 日時 | イシューがクローズされた時点のタイムスタンプ。 |
| `[].closed_by`              | オブジェクト   | このイシューをクローズしたユーザー。 |
| `[].confidential`           | ブール値  | イシューが非公開であるかどうかを示します。 |
| `[].created_at`             | 日時 | イシューが作成された時点のタイムスタンプ。 |
| `[].description`            | 文字列   | イシューの説明。 |
| `[].discussion_locked`      | ブール値  | イシューのコメントがメンバーのみにロックされているかどうかを示します。 |
| `[].downvotes`              | 整数  | イシューに対する不同意の数。 |
| `[].due_date`               | 日付     | イシューの期限。 |
| `[].id`                     | 整数  | イシューのID。 |
| `[].iid`                    | 整数  | イシューの内部ID。 |
| `[].issue_type`             | 文字列   | イシューのタイプ。`issue`、`incident`、`test_case`、`requirement`、`task`のいずれかです。 |
| `[].labels`                 | 配列    | イシューのラベル。 |
| `[].merge_requests_count`   | 整数  | マージ時にイシューをクローズするマージリクエストの数。 |
| `[].milestone`              | オブジェクト   | イシューのマイルストーン。 |
| `[].project_id`             | 整数  | イシュープロジェクトのID。 |
| `[].state`                  | 文字列   | イシューの状態。`opened`または`closed`を指定できます。 |
| `[].task_completion_status` | オブジェクト   | `count`と`completed_count`が含まれます。 |
| `[].time_stats`             | オブジェクト   | イシューの時間統計。`time_estimate`、`total_time_spent`、`human_time_estimate`、および`human_total_time_spent`が含まれます。 |
| `[].title`                  | 文字列   | イシューのタイトル。 |
| `[].type`                   | 文字列   | イシューのタイプ。`issue_type`と同じですが、大文字です。 |
| `[].updated_at`             | 日時 | イシューが更新された時点のタイムスタンプ。 |
| `[].upvotes`                | 整数  | イシューに対する同意の数。 |
| `[].user_notes_count`       | 整数  | イシューのユーザーノート数。 |
| `[].web_url`                | 文字列   | イシューのWeb URL。 |
| `[].weight`                 | 整数  | イシューのウェイト。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、Jiraなどの外部イシュートラッカーを使用する場合の次のレスポンス属性を返します。

| 属性  | 型    | 説明 |
|------------|---------|-------------|
| `[].id`    | 整数 | イシューのID。 |
| `[].title` | 文字列  | イシューのタイトル。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/closes_issues"
```

GitLabイシュートラッカーを使用する場合のレスポンス例:

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 1,
    "title": "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description": "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2024-09-06T10:58:49.002Z",
    "updated_at": "2024-09-06T11:01:40.710Z",
    "closed_at": null,
    "closed_by": null,
    "labels": [
      "label"
    ],
    "milestone": {
      "project_id": 1,
      "description": "Ducimus nam enim ex consequatur cumque ratione.",
      "state": "closed",
      "due_date": null,
      "iid": 2,
      "created_at": "2016-01-04T15:31:39.996Z",
      "title": "v4.0",
      "id": 17,
      "updated_at": "2016-01-04T15:31:39.996Z"
    },
    "assignees": [
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": null,
        "web_url": "https://gitlab.example.com/root"
      }
    ],
    "author": {
      "id": 18,
      "username": "eileen.lowe",
      "name": "Alexandra Bashirian",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/eileen.lowe"
    },
    "type": "ISSUE",
    "assignee": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/root"
    },
    "user_notes_count": 1,
    "merge_requests_count": 1,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "issue_type": "issue",
    "web_url": "https://gitlab.example.com/my-group/my-project/-/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "weight": null,
    "blocking_issues_count": 0
 }
]
```

Jiraなどの外部イシュートラッカーを使用する場合のレスポンス例:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## マージリクエストに関連するイシューのリストを取得する {#list-issues-related-to-the-merge-request}

マージリクエストのタイトル、説明、コミットメッセージ、コメント、ディスカッションから関連するイシューを一覧表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/related_issues
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/related_issues"
```

GitLabイシュートラッカーを使用する場合のレスポンス例:

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
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "iid" : 6,
      "labels" : [],
      "user_notes_count": 1,
      "changes_count": "1"
   }
]
```

Jiraなどの外部イシュートラッカーを使用する場合のレスポンス例:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## マージリクエストにサブスクライブする {#subscribe-to-a-merge-request}

認証済みユーザーが通知を受信できるように、マージリクエストにサブスクライブさせます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/subscribe
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

ユーザーがすでにマージリクエストをサブスクライブしている場合、エンドポイントはステータスコード`HTTP 304 Not Modified`を返します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/subscribe"
```

レスポンス例: 

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。

## マージリクエストのサブスクライブを解除する {#unsubscribe-from-a-merge-request}

認証済みのユーザーをマージリクエストからサブスクライブ解除し、そのマージリクエストからのマージリクエスト通知の配信を止めます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/unsubscribe"
```

ユーザーがマージリクエストをサブスクライブしていない場合、エンドポイントはステータスコード`HTTP 304 Not Modified`を返します。

レスポンス例: 

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

レスポンスデータに関する重要な注意点については、[単一マージリクエストレスポンスノート](#single-merge-request-response-notes)を参照してください。

## To Doアイテムを作成する {#create-a-to-do-item}

マージリクエストに関する現在のユーザーのTo Doアイテムを手動で作成します。そのマージリクエストに関するユーザーのTo Doアイテムがすでに存在している場合、このエンドポイントはステータスコード`HTTP 304 Not Modified`を返します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/27/todo"
```

レスポンス例: 

```json
{
  "id": 113,
  "project": {
    "id": 3,
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
  "target_type": "MergeRequest",
  "target": {
    "id": 27,
    "iid": 7,
    "project_id": 3,
    "title": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
    "description": "Veniam sunt nihil modi earum cumque illum delectus. Nihil ad quis distinctio quia. Autem eligendi at quibusdam repellendus.",
    "state": "merged",
    "created_at": "2016-06-17T07:48:04.330Z",
    "updated_at": "2016-07-01T11:14:15.537Z",
    "target_branch": "allow_regex_for_project_skip_ref",
    "source_branch": "backup",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca",
      "discussion_locked": false
    },
    "assignee": {
      "name": "Dr. Gabrielle Strosin",
      "username": "barrett.krajcik",
      "id": 4,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/733005fcd7e6df12d2d8580171ccb966?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/barrett.krajcik"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "source_project_id": 3,
    "target_project_id": 3,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 3,
      "title": "v1.0",
      "description": "Quis ea accusantium animi hic fuga assumenda.",
      "state": "active",
      "created_at": "2016-06-17T07:47:33.840Z",
      "updated_at": "2016-06-17T07:47:33.840Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "detailed_merge_status": "not_open",
    "subscribed": true,
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 7,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "squash": false,
    "web_url": "http://example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/merge_requests/7",
  "body": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
  "state": "pending",
  "created_at": "2016-07-01T11:14:15.530Z"
}
```

## マージリクエスト差分バージョンを取得する {#retrieve-merge-request-diff-versions}

マージリクエストの差分バージョンを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| 属性           | 型    | 必須 | 説明                           |
|---------------------|---------|----------|---------------------------------------|
| `id`                | 文字列  | はい      | プロジェクトのID。                |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |

レスポンス内のSHAの説明については、[APIレスポンスのSHA](#shas-in-the-api-response)を参照してください。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions"
```

レスポンス例: 

```json
[{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f"
}, {
  "id": 108,
  "head_commit_sha": "3eed087b29835c48015768f839d76e5ea8f07a24",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-25T14:21:33.028Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "72c30d1f0115fc1d2bb0b29b24dc2982cbcdfd32"
}]
```

### APIレスポンスのSHA {#shas-in-the-api-response}

| SHAフィールド          | 目的                                                                             |
|--------------------|-------------------------------------------------------------------------------------|
| `base_commit_sha`  | ソースブランチとターゲットブランチ間のマージベースコミットSHA。        |
| `head_commit_sha`  | ソースブランチのHEADコミット。                                               |
| `start_commit_sha` | この差分バージョンが作成された時点でのターゲットブランチのHEADコミットSHA。 |

## マージリクエスト差分バージョンを取得する {#retrieve-a-merge-request-diff-version}

{{< history >}}

- `collapsed`および`too_large`のレスポンス属性が、GitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633)。

{{< /history >}}

マージリクエストの特定の差分バージョンを取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

サポートされている属性は以下のとおりです: 

| 属性           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 文字列  | はい      | プロジェクトのID。 |
| `merge_request_iid` | 整数 | はい      | マージリクエストの内部ID。 |
| `version_id`        | 整数 | はい      | マージリクエストの差分バージョンのID。 |
| `unidiff`           | ブール値 | いいえ       | [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html)形式で差分を表示します。デフォルトはfalseです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610)されました。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                     | 型         | 説明 |
|-------------------------------|--------------|-------------|
| `id`                          | 整数      | マージリクエストの差分バージョンのID。 |
| `base_commit_sha`             | 文字列       | ソースブランチとターゲットブランチ間のマージベースコミットSHA。 |
| `commits`                     | オブジェクト配列 | マージリクエスト差分のコミット。 |
| `commits[].id`                | 文字列       | コミットのID。 |
| `commits[].short_id`          | 文字列       | コミットの短いID。 |
| `commits[].created_at`        | 日時     | `committed_date`フィールドと同一です。 |
| `commits[].parent_ids`        | 配列        | 親コミットのID。 |
| `commits[].title`             | 文字列       | コミットタイトル。 |
| `commits[].message`           | 文字列       | コミットメッセージ。 |
| `commits[].author_name`       | 文字列       | コミット作成者の名前。 |
| `commits[].author_email`      | 文字列       | コミット作成者のメールアドレス。 |
| `commits[].authored_date`     | 日時     | コミットの作成日時。 |
| `commits[].committer_name`    | 文字列       | コミッターの名前。 |
| `commits[].committer_email`   | 文字列       | コミッターのメールアドレス。 |
| `commits[].committed_date`    | 日時     | コミット日時。 |
| `commits[].trailers`          | オブジェクト       | コミットについて解析されたGitトレーラー。重複するキーには最後の値のみが含まれます。 |
| `commits[].extended_trailers` | オブジェクト       | コミットについて解析されたGitトレーラー。 |
| `commits[].web_url`           | 文字列       | マージリクエストのWeb URL。 |
| `created_at`                  | 日時     | マージリクエストの作成日時。 |
| `diffs`                       | オブジェクト配列 | マージリクエスト差分バージョンでの差分。 |
| `diffs[].a_mode`              | 文字列       | ファイルの古いファイルモード。 |
| `diffs[].b_mode`              | 文字列       | ファイルの新しいファイルモード。 |
| `diffs[].collapsed`           | ブール値      | ファイルの差分は除外されていますが、リクエストに応じてフェッチできます。 |
| `diffs[].deleted_file`        | ブール値      | ファイルは削除されました。 |
| `diffs[].diff`                | 文字列       | 差分の内容。 |
| `diffs[].generated_file`      | ブール値      | ファイルは[生成されたものとしてマーク](../user/project/merge_requests/changes.md#collapse-generated-files)されています。 |
| `diffs[].new_file`            | ブール値      | ファイルが追加されました。 |
| `diffs[].new_path`            | 文字列       | ファイルの新しいパス。 |
| `diffs[].old_path`            | 文字列       | ファイルの古いパス。 |
| `diffs[].renamed_file`        | ブール値      | ファイルの名前が変更されました。 |
| `diffs[].too_large`           | ブール値      | ファイルの差分は除外されており、取得できません。 |
| `head_commit_sha`             | 文字列       | ソースブランチのHEADコミット。 |
| `merge_request_id`            | 整数      | マージリクエストのID。 |
| `patch_id_sha`                | 文字列       | マージリクエスト差分の[パッチID](https://git-scm.com/docs/git-patch-id)。 |
| `real_size`                   | 文字列       | マージリクエスト差分の変更の数。 |
| `start_commit_sha`            | 文字列       | この差分バージョンが作成された時点でのターゲットブランチのHEADコミットSHA。 |
| `state`                       | 文字列       | マージリクエスト差分の状態。`collected`、`overflow`、`without_files`のいずれかです。非推奨の値は`timeout`、`overflow_commits_safe_size`、`overflow_diff_files_limit`、`overflow_diff_lines_limit`です。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions/1"
```

レスポンス例: 

```json
{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f",
  "commits": [{
    "id": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
    "short_id": "33e2ee85",
    "parent_ids": [],
    "title": "Change year to 2018",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-26T17:44:29.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-26T17:44:29.000+03:00",
    "created_at": "2016-07-26T17:44:29.000+03:00",
    "message": "Change year to 2018",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30"
  }, {
    "id": "aa24655de48b36335556ac8a3cd8bb521f977cbd",
    "short_id": "aa24655d",
    "parent_ids": [],
    "title": "Update LICENSE",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:53.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:53.000+03:00",
    "created_at": "2016-07-25T17:21:53.000+03:00",
    "message": "Update LICENSE",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/aa24655de48b36335556ac8a3cd8bb521f977cbd"
  }, {
    "id": "3eed087b29835c48015768f839d76e5ea8f07a24",
    "short_id": "3eed087b",
    "parent_ids": [],
    "title": "Add license",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:20.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:20.000+03:00",
    "created_at": "2016-07-25T17:21:20.000+03:00",
    "message": "Add license",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/3eed087b29835c48015768f839d76e5ea8f07a24"
  }],
  "diffs": [{
    "old_path": "LICENSE",
    "new_path": "LICENSE",
    "a_mode": "0",
    "b_mode": "100644",
    "diff": "@@ -0,0 +1,21 @@\n+The MIT License (MIT)\n+\n+Copyright (c) 2018 Administrator\n+\n+Permission is hereby granted, free of charge, to any person obtaining a copy\n+of this software and associated documentation files (the \"Software\"), to deal\n+in the Software without restriction, including without limitation the rights\n+to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n+copies of the Software, and to permit persons to whom the Software is\n+furnished to do so, subject to the following conditions:\n+\n+The above copyright notice and this permission notice shall be included in all\n+copies or substantial portions of the Software.\n+\n+THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n+IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n+FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n+AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n+LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n+OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n+SOFTWARE.\n",
    "collapsed": false,
    "too_large": false,
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }]
}
```

## マージリクエストのタイムトラッキングを設定する {#set-a-time-estimate-for-a-merge-request}

このマージリクエストの推定作業時間を設定します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/time_estimate
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |
| `duration`          | 文字列            | はい      | `3h30m`などの、人間が読める形式での期間。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_estimate?duration=3h30m"
```

レスポンス例: 

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

## マージリクエストのタイムトラッキングをリセットする {#reset-the-time-estimate-for-a-merge-request}

このマージリクエストの推定時間を0秒にリセットします。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_time_estimate
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | プロジェクトのマージリクエストの内部ID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_time_estimate"
```

レスポンス例: 

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## マージリクエストの使用時間を追加する {#add-spent-time-for-a-merge-request}

このマージリクエストにかかった時間を追加します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/add_spent_time
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |
| `duration`          | 文字列            | はい      | `3h30m`などの、人間が読める形式での期間。 |
| `summary`           | 文字列            | いいえ       | かかった時間の概要。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/add_spent_time?duration=1h"
```

レスポンス例: 

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

## マージリクエストの使用時間をリセットする {#reset-spent-time-for-a-merge-request}

このマージリクエストにかかった合計時間を0秒にリセットします。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_spent_time
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | プロジェクトのマージリクエストの内部ID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_spent_time"
```

レスポンス例: 

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## タイムトラッキング統計を取得する {#retrieve-time-tracking-statistics}

マージリクエストのタイムトラッキング統計を取得する。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/time_stats
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_stats"
```

レスポンス例: 

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

## 承認 {#approvals}

承認については、[マージリクエストの承認](merge_request_approvals.md)を参照してください。

## マージリクエストのステータスイベントのリストを取得する {#list-merge-request-state-events}

どの状態が設定されたか、誰が設定したか、いつ発生したかを追跡するには、[リソース状態イベントAPI](resource_state_events.md#merge-requests)を参照してください。

## トラブルシューティング {#troubleshooting}

### 新しいマージリクエストの空のAPIフィールド {#empty-api-fields-for-new-merge-requests}

マージリクエストを作成すると、`diff_refs`フィールドと`changes_count`フィールドは最初は空になります。これらのフィールドは、マージリクエストの作成後に非同期的に入力されます。詳細については、[イシュー386562](https://gitlab.com/gitlab-org/gitlab/-/issues/386562)とGitLabフォーラムの[関連するディスカッション](https://forum.gitlab.com/t/diff-refs-empty-after-mr-is-created/78975)を参照してください。
