---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 作業アイテム
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

作業アイテムには、次のタイプが含まれます: `Issue`、`Incident`、`TestCase`、`Requirement`、`Task`、`Ticket`、`Objective`、`KeyResult`、および`Epic`。

> [!note]
> エピックのクエリは、PremiumおよびUltimateでのみ利用可能です。

## クエリフィールド {#query-fields}

| フィールド                                                          | 名前（およびエイリアス）                             | 演算子                  | タイプ              |
| -------------------------------------------------------------- | -------------------------------------------- | -------------------------- | ------------------ |
| [Assignees](#workitem-assignees)                               | `assignee`、`assignees`                      | `=`、`in`、`!=`            | すべて                |
| [Author](#workitem-author)                                     | `author`                                     | `=`、`in`、`!=`            | すべて                |
| [ケイデンス](#workitem-cadence)                                   | `cadence`                                    | `=`、`in`                  | エピックを除くすべて    |
| [Closed at](#workitem-closed-at)                               | `closed`、`closedAt`                         | `=`、`>`、`<`、`>=`、`<=`  | すべて                |
| [機密](#workitem-confidential)                         | `confidential`                               | `=`、`!=`                  | すべて                |
| [作成日時](#workitem-created-at)                             | `created`、`createdAt`、`opened`、`openedAt` | `=`、`>`、`<`、`>=`、`<=`  | すべて                |
| [カスタムフィールド](#workitem-custom-field)                         | `customField("Field name")`                  | `=`                        | すべて                |
| [期限](#workitem-due-date)                                 | `due`、`dueDate`                             | `=`、`>`、`<`、`>=`、`<=`  | すべて                |
| [エピック](#workitem-epic)                                         | `epic`                                       | `=`、`!=`                  | エピックを除くすべて    |
| [グループ](#workitem-group)                                       | `group`                                      | `=`                        | すべて                |
| [ヘルスステータス](#workitem-health-status)                       | `health`、`healthStatus`                     | `=`、`!=`                  | すべて                |
| [ID](#workitem-identifier)                                     | `id`                                         | `=`、`in`                  | すべて                |
| [サブグループを含む](#workitem-include-subgroups)               | `includeSubgroups`                           | `=`、`!=`                  | すべて                |
| [イテレーション](#workitem-iteration)                               | `iteration`                                  | `=`、`in`、`!=`            | エピックを除くすべて    |
| [ラベル](#workitem-labels)                                     | `label`、`labels`                            | `=`、`in`、`!=`            | すべて                |
| [マイルストーン](#workitem-milestone)                               | `milestone`                                  | `=`、`in`、`!=`            | すべて                |
| [My reaction emoji](#workitem-my-reaction-emoji)               | `myReaction`、`myReactionEmoji`              | `=`、`!=`                  | すべて                |
| [親](#workitem-parent)                                     | `parent`                                     | `=`、`!=`                  | エピックを除くすべて    |
| [プロジェクト](#workitem-project)                                   | `project`                                    | `=`                        | エピックを除くすべて    |
| [State](#workitem-state)                                       | `state`                                      | `=`                        | すべて                |
| [ステータス](#workitem-status)                                     | `status`                                     | `=`                        | エピックを除くすべて    |
| [サブスクライブ](#workitem-subscribed)                             | `subscribed`                                 | `=`、`!=`                  | すべて                |
| [Updated at](#workitem-updated-at)                             | `updated`、`updatedAt`                       | `=`、`>`、`<`、`>=`、`<=`  | すべて                |
| [ウェイト](#workitem-weight)                                     | `weight`                                     | `=`、`!=`                  | エピックを除くすべて    |

### 担当者 {#workitem-assignees}

{{< history >}}

- エイリアス`assignees`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- エピックを担当者でクエリする機能がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: 作業アイテムを、1人または複数の担当作成者でクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）
- `List` （`String`または`User`の値を含む）
- `Nullable` （`null`、 `none`、または`any`のいずれか）

### 作成者 {#workitem-author}

{{< history >}}

- 作成者でエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。
- `in`オペレーターがGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221)。

{{< /history >}}

**説明**: 作業アイテムをその作成者でクエリします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）
- `List` （`String`または`User`の値を含む）

### ケイデンス {#workitem-cadence}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74)されました。

{{< /history >}}

**説明**: エピックを除く作業アイテムを、作業アイテムのイテレーションが属する[ケイデンス](../../group/iterations/_index.md#iteration-cadences)でクエリします。

**指定可能な値の型**:

- `Number` （正の整数のみ）
- `List` （`Number`値を含む）
- `Nullable` （`none`または`any`のいずれか）

**ノート**:

- 作業アイテムは1つのイテレーションしか持てないため、`cadence`フィールドに`List`タイプで`=`オペレーターを使用することはできません。

### Closed at {#workitem-closed-at}

{{< history >}}

- エイリアス`closedAt`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- 演算子`>=`および`<=`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)ました。
- クローズ日でエピックをクエリする機能がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: 作業アイテムを、それらがクローズされた日付でクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### Confidential {#workitem-confidential}

{{< history >}}

- エピックをその機密性でクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムを、プロジェクトメンバーへの表示レベルでクエリします。

**指定可能な値の型**:

- `Boolean` （`true`または`false`のいずれか）

**ノート**:

- GLQLを使用してクエリされた機密の作業アイテムは、それらを閲覧する権限を持つユーザーにのみ表示されます。

### Created at {#workitem-created-at}

{{< history >}}

- エイリアス`createdAt`、`opened`、および`openedAt`がGitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)。
- 演算子`>=`および`<=`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)ました。
- 作成日でエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムを、それらが作成された日付でクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### カスタムフィールド {#workitem-custom-field}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/233)されました。

{{< /history >}}

**説明**: [カスタムフィールド](../../work_items/custom_fields.md)で作業アイテムをクエリします。

**指定可能な値の型**:

- `String` (単一選択カスタムフィールドの場合)
- `List` (`String`、複数選択カスタムフィールドの場合)

**ノート**:

- カスタムフィールド名と値は、大文字と小文字を区別しません。

### 期限日 {#workitem-due-date}

{{< history >}}

- エイリアス`dueDate`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- 演算子`>=`および`<=`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)ました。
- 期限日でエピックをクエリする機能がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: 作業アイテムを、それらが期日となる日付でクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### エピック {#workitem-epic}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)されました。

{{< /history >}}

**説明**: 作業アイテムを、その親エピックIDまたは参照でクエリします。

**指定可能な値の型**:

- `Number` (エピックID)
- `String` (エピックの参照 (`&123`など) を含む)
- `Epic` （例: `&123`, `gitlab-org&123`）

### グループ {#workitem-group}

**説明**: 指定されたグループ内のすべてのプロジェクトで作業アイテムをクエリします。

**指定可能な値の型**: `String`

**ノート**:

- 一度にクエリできるグループは1つだけです。
- `group`は`project`フィールドと一緒に使用できません。
- グループオブジェクト (エピックなど) 内の埋め込みビューで使用する場合、`group`は現在のグループであると見なされます。
- `group`フィールドを使用すると、そのグループ内のすべてのオブジェクト、そのすべてのサブグループ、および子プロジェクトをクエリします。
- デフォルトでは、作業アイテムはすべてのサブグループのすべての子孫プロジェクトで検索されます。グループの直下の子孫プロジェクトのみをクエリするには、[`includeSubgroups`フィールド](#workitem-include-subgroups)を`false`に設定します。

### ヘルスステータス {#workitem-health-status}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- エイリアス`healthStatus`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- ヘルスステータスでエピックをクエリする機能がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: 作業アイテムをそのヘルスステータスでクエリします。

**指定可能な値の型**:

- `StringEnum` (`"needs attention"`、`"at risk"`、または`"on track"`のいずれか)
- `Nullable` （`null`、 `none`、または`any`のいずれか）

### ID {#workitem-identifier}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/92)されました。
- IDでエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムをそれらのIDでクエリします。

**指定可能な値の型**:

- `Number` （正の整数のみ）
- `List` （`Number`値を含む）

### サブグループを含める {#workitem-include-subgroups}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/106)されました。
- エピックでこのフィールドを使用する機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: グループの階層全体で作業アイテムをクエリします。

**指定可能な値の型**:

- `Boolean` （`true`または`false`のいずれか）

**ノート**:

- このフィールドは`group`フィールドと一緒にのみ使用できます。
- このフィールドの値はデフォルトで`false`です。

### イテレーション {#workitem-iteration}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74)されました。
- イテレーション値のタイプに対するサポートはGitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79)。

{{< /history >}}

**説明**: エピックを除く作業アイテムを、関連する[イテレーション](../../group/iterations/_index.md)でクエリします。

**指定可能な値の型**:

- `Number` （正の整数のみ）
- `Iteration` （例: `*iteration:123456`）
- `List` （`Number`または`Iteration`の値を含む）
- `Enum` (`current`のみがサポートされます)
- `Nullable` （`none`または`any`のいずれか）

**ノート**:

- 作業アイテムは1つのイテレーションしか持てないため、`iteration`フィールドに`List`タイプで`=`オペレーターを使用することはできません。

### ラベル {#workitem-labels}

{{< history >}}

- ラベル値のタイプに対するサポートはGitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79)。
- エイリアス`labels`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- ラベルでエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムを、それらに関連付けられたラベルでクエリします。

**指定可能な値の型**:

- `String`
- `Label` （例: `~bug`, `~"team::planning"`）
- `List` （`String`または`Label`の値を含む）
- `Nullable` （`none`または`any`のいずれか）

**ノート**:

- スコープ付きラベル、またはスペースを含むラベルは引用符で囲む必要があります。

### マイルストーン {#workitem-milestone}

{{< history >}}

- マイルストーン値のタイプに対するサポートはGitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/77)。
- マイルストーンでエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムを、それらに関連付けられたマイルストーンでクエリします。

**指定可能な値の型**:

- `String`
- `Milestone` （例: `%Backlog`, `%"Awaiting Further Demand"`）
- `List` （`String`または`Milestone`の値を含む）
- `Nullable` （`none`または`any`のいずれか）

**ノート**:

- スペースを含むマイルストーンは引用符 （`"`）で囲む必要があります。
- 作業アイテムは1つのマイルストーンしか持てないため、`milestone`フィールドに`List`タイプで`=`オペレーターを使用することはできません。
- `Epic`タイプは、`none`や`any`のようなワイルドカードマイルストーンフィルターをサポートしていません。

### My reaction emoji {#workitem-my-reaction-emoji}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223)されました。

{{< /history >}}

**説明**: 現在のユーザーの[絵文字リアクション](../../emoji_reactions.md)で作業アイテムをクエリします。

**指定可能な値の型**: `String`

### 親 {#workitem-parent}

**説明**: エピックを除く作業アイテムを、その親作業アイテムまたはエピックでクエリします。

**指定可能な値の型**:

- `Number` (親ID)
- `String` (参照 (`#123`など) を含む)
- `WorkItem` （例: `#123`, `gitlab-org/gitlab#123`）
- `Epic` （例: `&123`, `gitlab-org&123`）

### プロジェクト {#workitem-project}

**説明**: 特定のプロジェクトで、エピックを除く作業アイテムをクエリします。

**指定可能な値の型**: `String`

**ノート**:

- 一度にクエリできるプロジェクトは1つだけです。
- `project`フィールドは`group`フィールドと一緒に使用できません。
- 埋め込みビュー内で使用する場合、省略すると`project`は現在のプロジェクトであると見なされます。

### ステータス {#workitem-state}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/96)されました。
- ステータスでエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムを状態によってクエリします。

**指定可能な値の型**:

- `Enum` (`opened`、`closed`、または`all`のいずれか)

**ノート**:

- `state`フィールドは`!=`演算子をサポートしていません。

### ステータス {#workitem-status}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。

{{< /history >}}

**説明:**作業アイテムをそのステータスでクエリします。

**指定可能な値の型:** `String`

### サブスクライブ済み {#workitem-subscribed}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223)されました。

{{< /history >}}

**説明**: 現在のユーザーが[通知](../../profile/notifications.md)をオンまたはオフに設定しているかどうかで作業アイテムをクエリします。

**指定可能な値の型**: `Boolean`

### Updated at {#workitem-updated-at}

{{< history >}}

- エイリアス`updatedAt`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)ました。
- 演算子`>=`および`<=`はGitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)ました。
- 最終更新日でエピックをクエリする機能がGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作業アイテムを、それらが最終更新された日時でクエリします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

### ウェイト {#workitem-weight}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

**説明**: エピックを除く作業アイテムを、そのウェイトでクエリします。

**指定可能な値の型**:

- `Number` (正の整数または0のみ)
- `Nullable` （`null`、 `none`、または`any`のいずれか）

**ノート**:

- 比較オペレーター`<`および`>`は使用できません。

## 表示フィールド {#display-fields}

{{< history >}}

- フィールド`iteration`がGitLab 17.6で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74)。
- フィールド`lastComment`がGitLab 17.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/512154)。
- エピックのサポートがGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。
- フィールド`status`がGitLab 18.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)。
- エピックのフィールド`health`と`type`がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。
- フィールド`subscribed`がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223)。

{{< /history >}}

| フィールド            | 名前またはエイリアス                         | タイプ           | 説明 |
| ---------------- | ------------------------------------- | --------------- | ----------- |
| Assignees        | `assignee`、`assignees`               | すべて             | オブジェクトに割り当てられたユーザーを表示 |
| Author           | `author`                              | すべて             | オブジェクトの作成者を表示 |
| Closed at        | `closed`、`closedAt`                  | すべて             | オブジェクトがクローズされてからの時間を表示 |
| 機密     | `confidential`                        | すべて             | オブジェクトが機密であるかどうかを示す`Yes`または`No`を表示 |
| 作成日時       | `created`、`createdAt`                | すべて             | オブジェクトが作成されてからの時間を表示 |
| 説明      | `description`                         | すべて             | オブジェクトの説明を表示 |
| 期限         | `due`、`dueDate`                      | すべて             | オブジェクトの期日までの時間を表示 |
| エピック             | `epic`                                | エピックを除くすべて | エピックへのリンクを表示。PremiumおよびUltimateで利用可能です |
| ヘルスステータス    | `health`、`healthStatus`              | すべて             | ヘルスステータスを示すバッジを表示。Ultimateで利用可能です |
| ID               | `id`                                  | すべて             | オブジェクトのIDを表示 |
| イテレーション        | `iteration`                           | エピックを除くすべて | イテレーションを表示。PremiumおよびUltimateで利用可能です |
| ラベル           | `label`、`labels`                     | すべて             | ラベルを表示。特定のラベルをフィルタリングするためのパラメータを受け入れられます。例: `labels("workflow::*", "backend")` |
| 最後のコメント     | `lastComment`                         | すべて             | オブジェクトに対して行われた最終コメントを表示 |
| マイルストーン        | `milestone`                           | すべて             | オブジェクトに関連付けられたマイルストーンを表示 |
| 開始日       | `start`、`startDate`                  | エピックのみ       | エピックの開始日を表示 |
| State            | `state`                               | すべて             | ステータスを示すバッジを表示。値は`Open`または`Closed`です。 |
| ステータス           | `status`                              | エピックを除くすべて | ステータスを示すバッジを表示。例: 「To Do」または「完了」。PremiumおよびUltimateで利用可能です |
| サブスクライブ       | `subscribed`                          | すべて             | 現在のユーザーがサブスクライブされているかどうかを示す`Yes`または`No`を表示 |
| Title            | `title`                               | すべて             | オブジェクトのタイトルを表示 |
| タイプ             | `type`                                | すべて             | 作業アイテムのタイプを表示します。例: `Issue`、`Task`、または`Objective` |
| Updated at       | `updated`、`updatedAt`                | すべて             | オブジェクトが最終更新されてからの時間を表示 |
| ウェイト           | `weight`                              | エピックを除くすべて | ウェイトを表示。PremiumおよびUltimateで利用可能です |

## ソートフィールド {#sort-fields}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/178)されました。
- ヘルスステータスでエピックをソートする機能がGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

| フィールド         | 名前（およびエイリアス）         | タイプ           | 説明                                     |
|---------------|--------------------------|-----------------|------------------------------------------------ |
| Closed at     | `closed`、`closedAt`     | すべて             | クローズされた日付でソート                             |
| Created       | `created`、`createdAt`   | すべて             | 作成された日付でソート                            |
| 期限      | `due`、`dueDate`         | すべて             | 期日でソート                                |
| ヘルスステータス | `health`、`healthStatus` | すべて             | ヘルスステータスでソート                           |
| マイルストーン     | `milestone`              | エピックを除くすべて | マイルストーンの期日でソート                      |
| 人気度    | `popularity`             | すべて             | 高評価のリアクションの絵文字の数でソート |
| 開始日    | `start`、`startDate`     | エピックのみ       | 開始日でソート                              |
| Title         | `title`                  | すべて             | タイトルでソート                                   |
| Updated at    | `updated`、`updatedAt`   | すべて             | 最終更新日でソート                       |
| ウェイト        | `weight`                 | エピックを除くすべて | ウェイトでソート                                  |

**例**:

- `gitlab-org/gitlab`プロジェクト内のすべてのイシューをタイトルでソートしてリスト表示します:

  ````yaml
  ```glql
  display: table
  fields: state, title, updated
  sort: title asc
  query: project = "gitlab-org/gitlab" and type = Issue
  ```
  ````

- `gitlab-org`グループ内のすべてのエピックを開始日 (最も古いものが最初) でソートしてリスト表示します:

  ````yaml
  ```glql
  display: table
  fields: title, state, startDate
  sort: startDate asc
  query: group = "gitlab-org" and type = Epic
  ```
  ````

- `gitlab-org`グループ内の割り当てられたウェイトを持つすべてのイシューをウェイト (最も高いものが最初) でソートしてリスト表示します:

  ````yaml
  ```glql
  display: table
  fields: title, weight, health
  sort: weight desc
  query: type = Issue and group = "gitlab-org" and weight = any
  ```
  ````

- `gitlab-org`グループ内の、本日より1週間以内のすべてのイシューを期限日 (最も早いものが最初) でソートしてリスト表示します:

  ````yaml
  ```glql
  display: table
  fields: title, dueDate, assignee
  sort: dueDate asc
  query: type = Issue and group = "gitlab-org" and due >= today() and due <= 1w
  ```
  ````
