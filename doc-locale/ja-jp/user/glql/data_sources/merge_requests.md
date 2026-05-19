---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: マージリクエスト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。

{{< /history >}}

## クエリフィールド {#query-fields}

| フィールド                                                    | 名前（およびエイリアス）                             | 演算子                  |
| -------------------------------------------------------- | -------------------------------------------- | -------------------------- |
| [Approved by user](#mr-approved-by-user)                 | `approver`、`approvedBy`、`approvers`        | `=`、`!=`                  |
| [Assignees](#mr-assignees)                               | `assignee`、`assignees`                      | `=`、`!=`                  |
| [Author](#mr-author)                                     | `author`                                     | `=`、`!=`                  |
| [Closed at](#mr-closed-at)                               | `closed`、`closedAt`                         | `=`、`>`、`<`、`>=`、`<=`  |
| [作成日時](#mr-created-at)                             | `created`、`createdAt`、`opened`、`openedAt` | `=`、`>`、`<`、`>=`、`<=`  |
| [Draft](#mr-draft)                                       | `draft`                                      | `=`、`!=`                  |
| [環境](#mr-environment)                           | `environment`                                | `=`                        |
| [グループ](#mr-group)                                       | `group`                                      | `=`                        |
| [ID](#mr-identifier)                                     | `id`                                         | `=`、`in`                  |
| [サブグループを含む](#mr-include-subgroups)               | `includeSubgroups`                            | `=`、`!=`                  |
| [ラベル](#mr-labels)                                     | `label`、`labels`                            | `=`、`!=`                  |
| [Merged at](#mr-merged-at)                               | `merged`、`mergedAt`                         | `=`、`>`、`<`、`>=`、`<=`  |
| [Merged by user](#mr-merged-by-user)                     | `merger`、`mergedBy`                         | `=`                        |
| [マイルストーン](#mr-milestone)                               | `milestone`                                  | `=`、`!=`                  |
| [My reaction emoji](#mr-my-reaction-emoji)               | `myReaction`、`myReactionEmoji`              | `=`、`!=`                  |
| [プロジェクト](#mr-project)                                   | `project`                                    | `=`                        |
| [Reviewers](#mr-reviewers)                               | `reviewer`、`reviewers`、`reviewedBy`        | `=`、`!=`                  |
| [ソースブランチ](#mr-source-branch)                       | `sourceBranch`                               | `=`、`in`、`!=`            |
| [State](#mr-state)                                       | `state`                                      | `=`                        |
| [サブスクライブ](#mr-subscribed)                             | `subscribed`                                 | `=`、`!=`                  |
| [ターゲットブランチ](#mr-target-branch)                       | `targetBranch`                               | `=`、`in`、`!=`            |
| [Deployed at](#mr-deployed-at)                           | `deployed`、`deployedAt`                     | `=`、`>`、`<`、`>=`、`<=`  |
| [Updated at](#mr-updated-at)                             | `updated`、`updatedAt`                       | `=`、`>`、`<`、`>=`、`<=`  |

### ユーザーによる承認 {#mr-approved-by-user}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エイリアス`approvedBy`および`approvers`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- `Nullable`値のサポートはGitLab 18.3で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221)ました。

{{< /history >}}

**説明**: マージリクエストを承認した一人または複数のユーザーでマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）
- `List` （`String`または`User`の値を含む）
- `Nullable` （`null`、 `none`、または`any`のいずれか）

### 担当者 {#mr-assignees}

**説明**: それらに割り当てられている一人または複数のユーザーでマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）
- `Nullable` （`null`、 `none`、または`any`のいずれか）

**ノート**:

- `List`値と`in`演算子は、マージリクエストではサポートされていません。

### 作成者 {#mr-author}

**説明**: 作成者でマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）

**ノート**:

- `in`演算子は、マージリクエストではサポートされていません。

### Closed at {#mr-closed-at}

**説明**: クローズされた日付でマージリクエストをクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### Created at {#mr-created-at}

**説明**: 作成された日付でマージリクエストをクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### Draft {#mr-draft}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。

{{< /history >}}

**説明**: ドラフトステータスでマージリクエストをクエリします。

**指定可能な値の型**:

- `Boolean` （`true`または`false`のいずれか）

### Deployed at {#mr-deployed-at}

**説明**: デプロイされた日付でマージリクエストをクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### 環境 {#mr-environment}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。

{{< /history >}}

**説明**: デプロイされた環境でマージリクエストをクエリします。

**指定可能な値の型**: `String`

### グループ {#mr-group}

**説明**: 指定されたグループ内のすべてのプロジェクトでマージリクエストをクエリします。

**指定可能な値の型**: `String`

**ノート**:

- 一度にクエリできるグループは1つだけです。
- `group`は`project`フィールドと一緒に使用できません。
- `group`フィールドを使用すると、そのグループ、そのすべてのサブグループ、および子孫プロジェクト内のすべてのマージリクエストがクエリされます。
- デフォルトでは、マージリクエストはすべてのサブグループのすべての子孫プロジェクトで検索されます。グループの直下の子孫プロジェクトのみをクエリするには、[`includeSubgroups`フィールド](#mr-include-subgroups)を`false`に設定します。

### ID {#mr-identifier}

**説明**: IDでマージリクエストをクエリします。

**指定可能な値の型**:

- `Number` （正の整数のみ）
- `List` （`Number`値を含む）

### サブグループを含める {#mr-include-subgroups}

**説明**: グループの階層全体でマージリクエストをクエリします。

**指定可能な値の型**:

- `Boolean` （`true`または`false`のいずれか）

**ノート**:

- このフィールドは`group`フィールドと一緒にのみ使用できます。
- このフィールドの値はデフォルトで`false`です。

### ラベル {#mr-labels}

**説明**: 関連するラベルでマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `Label` （例: `~bug`, `~"team::planning"`）
- `Nullable` （`none`または`any`のいずれか）

**ノート**:

- `in`演算子は、マージリクエストではサポートされていません。
- スコープ付きラベル、またはスペースを含むラベルは引用符で囲む必要があります。

### Merged at {#mr-merged-at}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エイリアス`mergedAt`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- 演算子`>=`および`<=`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)ました。

{{< /history >}}

**説明**: マージされた日付でマージリクエストをクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### Merged by user {#mr-merged-by-user}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エイリアス`mergedBy`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。

{{< /history >}}

**説明**: マージリクエストをマージしたユーザーでマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）

### マイルストーン {#mr-milestone}

**説明**: 関連するマイルストーンでマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `Milestone` （例: `%Backlog`, `%"Awaiting Further Demand"`）
- `Nullable` （`none`または`any`のいずれか）

**ノート**:

- `in`演算子は、マージリクエストではサポートされていません。
- スペースを含むマイルストーンは引用符 （`"`）で囲む必要があります。

### My reaction emoji {#mr-my-reaction-emoji}

**説明**: 現在のユーザーの[絵文字リアクション](../../emoji_reactions.md)でマージリクエストをクエリします。

**指定可能な値の型**: `String`

### プロジェクト {#mr-project}

**説明**: 特定のプロジェクトでマージリクエストをクエリします。

**指定可能な値の型**: `String`

**ノート**:

- 一度にクエリできるプロジェクトは1つだけです。
- `project`フィールドは`group`フィールドと一緒に使用できません。
- 埋め込みビュー内で使用する場合、省略すると`project`は現在のプロジェクトであると見なされます。

### レビュアー {#mr-reviewers}

{{< history >}}

- エイリアス`reviewers`および`reviewedBy`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。

{{< /history >}}

**説明**: 一人または複数のユーザーによってレビューされたマージリクエストをクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）
- `Nullable` （`null`、 `none`、または`any`のいずれか）

### ソースブランチ {#mr-source-branch}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。

{{< /history >}}

**説明**: ソースブランチでマージリクエストをクエリします。

**指定可能な値の型:** `String`, `List`

**ノート**:

- `List`値は`in`および`!=`演算子でのみサポートされます。

### ステータス {#mr-state}

**説明**: ステータスでマージリクエストをクエリします。

**指定可能な値の型**:

- `Enum`、`opened`、`closed`、`merged`、または`all`のいずれか

**ノート**:

- `state`フィールドは`!=`演算子をサポートしていません。

### サブスクライブ済み {#mr-subscribed}

**説明**: 現在のユーザーが[通知](../../profile/notifications.md)をオンまたはオフに設定しているかでマージリクエストをクエリします。

**指定可能な値の型**: `Boolean`

### ターゲットブランチ {#mr-target-branch}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。

{{< /history >}}

**説明**: ターゲットブランチでマージリクエストをクエリします。

**指定可能な値の型:** `String`, `List`

**ノート**:

- `List`値は`in`および`!=`演算子でのみサポートされます。

### Updated at {#mr-updated-at}

**説明**: 最終更新日でマージリクエストをクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

## 表示フィールド {#display-fields}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- フィールド`sourceBranch`、`targetBranch`、`sourceProject`、および`targetProject`はGitLab 18.2で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)ました。

{{< /history >}}

| フィールド            | 名前またはエイリアス                         | 説明 |
| ---------------- | ------------------------------------- | ----------- |
| Approved by user | `approver`、`approvers`、`approvedBy` | マージリクエストを承認したユーザーを表示 |
| Assignees        | `assignee`、`assignees`               | マージリクエストに割り当てられたユーザーを表示 |
| Author           | `author`                              | マージリクエストの作成者を表示 |
| Closed at        | `closed`、`closedAt`                  | マージリクエストがクローズされてからの時間を表示 |
| 作成日時       | `created`、`createdAt`                | マージリクエストが作成されてからの時間を表示 |
| Deployed at      | `deployed`、`deployedAt`              | マージリクエストがデプロイされてからの時間を表示 |
| 説明      | `description`                         | マージリクエストの説明を表示 |
| Draft            | `draft`                               | マージリクエストがドラフト状態であるかどうかを示す`Yes`または`No`を表示 |
| ID               | `id`                                  | マージリクエストのIDを表示 |
| ラベル           | `label`、`labels`                     | マージリクエストに関連付けられたラベルを表示 |
| 最後のコメント     | `lastComment`                         | マージリクエストに対して行われた最後のコメントを表示 |
| Merged at        | `merged`、`mergedAt`                  | マージリクエストがマージされてからの時間を表示 |
| マイルストーン        | `milestone`                           | マージリクエストに関連付けられたマイルストーンを表示 |
| Reviewers        | `reviewer`、`reviewers`               | マージリクエストをレビューするために割り当てられたユーザーを表示 |
| ソースブランチ    | `sourceBranch`                        | マージリクエストのソースブランチを表示 |
| ソースプロジェクト   | `sourceProject`                       | マージリクエストのソースプロジェクトを表示 |
| State            | `state`                               | ステータスを示すバッジを表示。値は`Open`、 `Closed`、または`Merged`です |
| サブスクライブ       | `subscribed`                          | 現在のユーザーがサブスクライブされているかどうかを示す`Yes`または`No`を表示 |
| ターゲットブランチ    | `targetBranch`                        | マージリクエストのターゲットブランチを表示 |
| ターゲットプロジェクト   | `targetProject`                       | マージリクエストのターゲットプロジェクトを表示 |
| Title            | `title`                               | マージリクエストのタイトルを表示 |
| Updated at       | `updated`、`updatedAt`                | マージリクエストが最後に更新されてからの時間を表示 |

## ソートフィールド {#sort-fields}

| フィールド         | 名前（およびエイリアス）       | 説明                                     |
|---------------|------------------------|-------------------------------------------------|
| Closed at     | `closed`、`closedAt`   | クローズされた日付でソート                             |
| Created       | `created`、`createdAt` | 作成された日付でソート                            |
| Merged at     | `merged`、`mergedAt`   | マージされた日付でソート                              |
| マイルストーン     | `milestone`            | マイルストーンの期日でソート                      |
| 人気度    | `popularity`           | 高評価のリアクションの絵文字の数でソート |
| Title         | `title`                | タイトルでソート                                   |
| Updated at    | `updated`、`updatedAt` | 最終更新日でソート                       |

**例**:

- `gitlab-org`グループ内で私が作成したすべてのマージリクエストをマージ日（最新順）でソートしてリスト表示します:

  ````yaml
  ```glql
  display: table
  fields: title, reviewer, merged
  sort: merged desc
  query: group = "gitlab-org" and type = MergeRequest and state = merged and author = currentUser()
  limit: 10
  ```
  ````
