---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GLQLフィールド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`glql_integration`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14767)されました。デフォルトでは無効になっています。
- GitLab.comのGitLab 17.4で、グループとプロジェクトのサブセットに対して有効になりました。
- GitLab 17.10で[ベータ](../../policy/development_stages_support.md#beta)ステータスに昇格しました。
- GitLab 17.10で、実験的機能からベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/476990)されました。
- GitLab 17.10のGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

GitLab Query Language（GLQL）を使用すると、フィールドは次の目的で使用されます:

- [GLQLクエリ](_index.md#query-syntax)から返された結果をフィルタリングします。
- [埋め込みビュー](_index.md#presentation-syntax)に表示される詳細を制御します。
- 埋め込みビューに表示される結果をソートします。

フィールドは、3つの埋め込みビューパラメータで使用します:

- **`query`** - 取得するアイテムを決定する条件を設定します
- **`fields`** - ビューに表示する列と詳細を指定します
- **`sort`** - 特定の条件でアイテムを並べ替えます

次のセクションでは、各コンポーネントで使用可能なフィールドについて説明します。

## クエリ内のフィールド {#fields-inside-query}

埋め込みビューでは、`query`パラメータを使用して、`<field> <operator> <value>`形式の1つ以上の式を含めることができます。複数の式は`and`で結合されます（例: `group = "gitlab-org" and author = currentUser()`）。

前提要件: 

- エピックのクエリは、PremiumおよびUltimateティアで使用できます。

次の表に、使用可能なすべてのクエリフィールドとその仕様の概要を示します:

| フィールド                                   | 名前（およびエイリアス）                             | 演算子                 | サポート対象 |
| --------------------------------------- | -------------------------------------------- | ------------------------- | ------------- |
| [ユーザーによる承認](#approved-by-user)   | `approver`、`approvedBy`、`approvers`        | `=`、`!=`                 | マージリクエスト |
| [担当者](#assignees)                 | `assignee`、`assignees`                      | `=`、`in`、`!=`           | イシュー、エピック、マージリクエスト |
| [作成者](#author)                       | `author`                                     | `=`、`in`、`!=`           | イシュー、エピック、マージリクエスト |
| [ケイデンス](#cadence)                     | `cadence`                                    | `=`、`in`                 | イシュー |
| [クローズ日](#closed-at)                 | `closed`、`closedAt`                         | `=`、`>`、`<`、`>=`、`<=` | イシュー、エピック |
| [機密](#confidential)           | `confidential`                               | `=`、`!=`                 | イシュー、エピック |
| [作成日](#created-at)               | `created`、`createdAt`、`opened`、`openedAt` | `=`、`>`、`<`、`>=`、`<=` | イシュー、エピック、マージリクエスト |
| [カスタムフィールド](#custom-field)           | `customField("Field name")`                  | `=`                       | イシュー、エピック |
| [ドラフト](#draft)                         | `draft`                                      | `=`、`!=`                 | マージリクエスト |
| [期限](#due-date)                   | `due`、`dueDate`                             | `=`、`>`、`<`、`>=`、`<=` | イシュー、エピック |
| [環境](#environment)             | `environment`                                | `=`                       | マージリクエスト |
| [エピック](#epic)                           | `epic`                                       | `=`、`!=`                 | イシュー |
| [グループ](#group)                         | `group`                                      | `=`                       | イシュー、エピック、マージリクエスト |
| [ヘルスステータス](#health-status)         | `health`、`healthStatus`                     | `=`、`!=`                 | イシュー、エピック |
| [ID](#id)                               | `id`                                         | `=`、`in`                 | イシュー、エピック、マージリクエスト |
| [サブグループを含める](#include-subgroups) | `includeSubgroups`                           | `=`、`!=`                 | イシュー、エピック、マージリクエスト |
| [イテレーション](#iteration)                 | `iteration`                                  | `=`、`in`、`!=`           | イシュー |
| [ラベル](#labels)                       | `label`、`labels`                            | `=`、`in`、`!=`           | イシュー、エピック、マージリクエスト |
| [マージ日](#merged-at)                 | `merged`、`mergedAt`                         | `=`、`>`、`<`、`>=`、`<=` | マージリクエスト |
| [ユーザーによるマージ](#merged-by-user)       | `merger`、`mergedBy`                         | `=`                       | マージリクエスト |
| [マイルストーン](#milestone)                 | `milestone`                                  | `=`、`in`、`!=`           | イシュー、エピック、マージリクエスト |
| [リアクションの絵文字](#my-reaction-emoji) | `myReaction`、`myReactionEmoji`              | `=`、`!=`                 | イシュー、エピック、マージリクエスト |
| [プロジェクト](#project)                     | `project`                                    | `=`                       | イシュー、マージリクエスト |
| [レビュアー](#reviewers)                 | `reviewer`、`reviewers`、`reviewedBy`        | `=`、`!=`                 | マージリクエスト |
| [ソースブランチ](#source-branch)         | `sourceBranch`                               | `=`、`in`、`!=`           | マージリクエスト |
| [ステート](#state)                         | `state`                                      | `=`                       | イシュー、エピック、マージリクエスト |
| [ステータス](#status)                       | `status`                                     | `=`                       | イシュー |
| [サブスクリプション](#subscribed)               | `subscribed`                                 | `=`、`!=`                 | イシュー、エピック、マージリクエスト |
| [ターゲットブランチ](#target-branch)         | `targetBranch`                               | `=`、`in`、`!=`           | マージリクエスト |
| [型](#type)                           | `type`                                       | `=`、`in`                 | イシュー、エピック、マージリクエスト |
| [更新日](#updated-at)               | `updated`、`updatedAt`                       | `=`、`>`、`<`、`>=`、`<=` | イシュー、エピック、マージリクエスト |
| [ウェイト](#weight)                       | `weight`                                     | `=`、`!=`                 | イシュー |

### ユーザーによる承認 {#approved-by-user}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エイリアス`approvedBy`と`approvers`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- `Nullable`値のサポートがGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221)されました。

{{< /history >}}

**説明**: マージリクエストを承認した1人以上のユーザーでマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `User`（例: `@username`）
- `List`（`String`または`User`値を含む）
- `Nullable`（`null`、`none`、または`any`のいずれか）

**Examples**（例）:

- 現在のユーザーと`@johndoe`によって承認されたすべてのマージリクエストをリストします

  ```plaintext
  type = MergeRequest and approver = (currentUser(), @johndoe)
  ```

- まだ承認されていないすべてのマージリクエストをリストします

  ```plaintext
  type = MergeRequest and approver = none
  ```

### 担当者 {#assignees}

{{< history >}}

- エイリアス`assignees`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- 担当者によるエピックのクエリのサポートは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: 割り当てられている1人以上のユーザーによって、イシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `User`（例: `@username`）
- `List`（`String`または`User`値を含む）
- `Nullable`（`null`、`none`、または`any`のいずれか）

**Additional details**（補足情報）:

- `List`値と`in`演算子は、`MergeRequest`型ではサポートされていません。

**Examples**（例）:

- 担当者が`@johndoe`のすべてのイシューをリストします:

  ```plaintext
  assignee = @johndoe
  ```

- 担当者が`@johndoe`と`@janedoe`の両方であるすべてのイシューをリストします:

  ```plaintext
  assignee = (@johndoe, @janedoe)
  ```

- 担当者が`@johndoe`または`@janedoe`のいずれかであるすべてのイシューをリストします:

  ```plaintext
  assignee in (@johndoe, @janedoe)
  ```

- 担当者が`@johndoe`または`@janedoe`のいずれでもないすべてのイシューをリストします:

  ```plaintext
  assignee != (@johndoe, @janedoe)
  ```

- 担当者が`@johndoe`であるすべてのマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and assignee = @johndoe
  ```

### 作成者 {#author}

{{< history >}}

- 作成者によるエピックのクエリのサポートは、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。
- `in`演算子のサポートは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221)。

{{< /history >}}

**説明**: 作成者別にイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `User`（例: `@username`）
- `List`（`String`または`User`値を含む）

**Additional details**（補足情報）:

- `in`演算子は、`MergeRequest`型ではサポートされていません。

**Examples**（例）:

- 作成者が`@johndoe`のすべてのイシューをリストします:

  ```plaintext
  author = @johndoe
  ```

- 作成者が`@johndoe`または`@janedoe`のいずれかであるすべてのエピックをリストします:

  ```plaintext
  type = Epic and author in (@johndoe, @janedoe)
  ```

- 作成者が`@johndoe`であるすべてのマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and author = @johndoe
  ```

### ケイデンス {#cadence}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74)されました。

{{< /history >}}

**説明**: イシューのイテレーションが一部である[ケイデンス](../group/iterations/_index.md#iteration-cadences)でイシューをクエリします。

**Allowed value types**（許可される値の型）:

- `Number`（正の整数のみ）
- `List`（`Number`値を含む）
- `Nullable`（`none`または`any`のいずれか）

**Additional details**（補足情報）:

- イシューが持つことができるイテレーションは1つのみであるため、`=`演算子は`List`型の`cadence`フィールドでは使用できません。

**Examples**（例）:

- ケイデンスID `123456`の一部であるイテレーションを持つすべてのイシューをリストします:

  ```plaintext
  cadence = 123456
  ```

- 任意のケイデンス`123`または`456`の一部であるイテレーションを持つすべてのイシューをリストします:

  ```plaintext
  cadence in (123, 456)
  ```

### クローズ日 {#closed-at}

{{< history >}}

- エイリアス`closedAt`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- 演算子`>=`および`<=`は、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)。
- クローズ日によるエピックのクエリのサポートは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: クローズ日によってイシューまたはエピックをクエリします。

**Allowed value types**（許可される値の型）:

- `AbsoluteDate`（`YYYY-MM-DD`形式）
- `RelativeDate`（`<sign><digit><unit>`形式。符号は`+`、`-`、または省略、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）または`y`（年）のいずれか）

**Additional details**（補足情報）:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンの00:00〜23:59と見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

**Examples**（例）:

- 昨日以降にクローズされたすべてのイシューをリストします:

  ```plaintext
  closed > -1d
  ```

- 今日クローズされたすべてのイシューをリストします:

  ```plaintext
  closed = today()
  ```

- 2023年2月にクローズされたすべてのイシューをリストします:

  ```plaintext
  closed > 2023-02-01 and closed < 2023-02-28
  ```

### 機密 {#confidential}

{{< history >}}

- 機密性によるエピックのクエリのサポートは、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: プロジェクトメンバーへの表示によってイシューまたはエピックをクエリします。

**Allowed value types**（許可される値の型）:

- `Boolean`（`true`または`false`のいずれか）

**Additional details**（補足情報）:

- GLQLを使用してクエリされた機密イシューは、表示権限を持つユーザーにのみ表示されます。

**Examples**（例）:

- すべての機密イシューをリストします:

  ```plaintext
  confidential = true
  ```

- 機密でないすべてのイシューをリストします:

  ```plaintext
  confidential = false
  ```

### 作成日 {#created-at}

{{< history >}}

- エイリアス`createdAt`、`opened`、および`openedAt`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- 演算子`>=`および`<=`は、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)。
- 作成日によるエピックのクエリのサポートは、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 作成日によってイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `AbsoluteDate`（`YYYY-MM-DD`形式）
- `RelativeDate`（`<sign><digit><unit>`形式。符号は`+`、`-`、または省略、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）または`y`（年）のいずれか）

**Additional details**（補足情報）:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンの00:00〜23:59と見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

**Examples**（例）:

- 先週作成されたすべてのイシューをリストします:

  ```plaintext
  created > -1w
  ```

- 今日作成されたすべてのイシューをリストします:

  ```plaintext
  created = today()
  ```

- 2025年1月に作成され、まだオープンなすべてのイシューをリストします:

  ```plaintext
  created > 2025-01-01 and created < 2025-01-31 and state = opened
  ```

### カスタムフィールド {#custom-field}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/233)されました。

{{< /history >}}

**説明**: [カスタムフィールド](../work_items/custom_fields.md)でイシューまたはエピックをクエリします。

**Allowed value types**（許可される値の型）:

- `String`（シングルセレクトのカスタムフィールドの場合）
- `List`（マルチセレクトのカスタムフィールドの場合は`String`）

**Additional details**（補足情報）:

- カスタムフィールドの名前と値では、大文字と小文字は区別されません。

**Examples**（例）

- シングルセレクトの「Subscription」カスタムフィールドが「Free」に設定されているすべてのイシューをリストします:

  ```plaintext
  customField("Subscription") = "Free"
  ```

- シングルセレクトの「Subscription」および「Team」カスタムフィールドが、それぞれ「Free」および「Engineering」に設定されているすべてのイシューをリストします:

  ```plaintext
  customField("Subscription") = "Free" and customField("Team") = "Engineering"
  ```

- マルチセレクトの「Category」カスタムフィールドが「Markdown」および「Text Editors」に設定されているすべてのイシューをリストします:

  ```plaintext
  customField("Category") = ("Markdown", "Text Editors")
  ```

  または:

  ```plaintext
  customField("Category") = "Markdown" and customField("Category") = "Text Editors"
  ```

### ドラフト {#draft}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。

{{< /history >}}

**説明**: マージリクエストをドラフトステータスでクエリします。

**Allowed value types**（許可される値の型）:

- `Boolean`（`true`または`false`のいずれか）

**Examples**（例）:

- すべてのドラフトマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and draft = true
  ```

- ドラフト状態にないすべてのマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and draft = false
  ```

### 期限 {#due-date}

{{< history >}}

- エイリアス`dueDate`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- 演算子`>=`および`<=`は、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)。
- 期日によるエピックのクエリのサポートは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: 期日によってイシューまたはエピックをクエリします。

**Allowed value types**（許可される値の型）:

- `AbsoluteDate`（`YYYY-MM-DD`形式）
- `RelativeDate`（`<sign><digit><unit>`形式。符号は`+`、`-`、または省略、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）または`y`（年）のいずれか）

**Additional details**（補足情報）:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンの00:00〜23:59と見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

**Examples**（例）:

- 1週間後が期日のすべてのイシューをリストします:

  ```plaintext
  due < 1w
  ```

- 2025年1月1日時点で延滞していたすべてのイシューをリストします:

  ```plaintext
  due < 2025-01-01
  ```

- 今日が期日のすべてのイシューをリストします（昨日または明日が期日ではない）:

  ```plaintext
  due = today()
  ```

- 過去1か月で延滞していたすべてのイシューをリストします:

  ```plaintext
  due > -1m and due < today()
  ```

### 環境 {#environment}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。

{{< /history >}}

**説明**: デプロイされている環境によってマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `String`

**Examples**（例）:

- 環境`production`にデプロイされたすべてのマージリクエストをリストします:

  ```plaintext
  environment = "production"
  ```

### エピック {#epic}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)されました。

{{< /history >}}

**説明**: 親エピックIDまたは参照でイシューをクエリします。

**Allowed value types**（許可される値の型）:

- `Number`（エピックID）
- `String`（`&123`のようなエピック参照を含む）
- `Epic`（例: `&123`、`gitlab-org&123`）

**Examples**（例）:

- プロジェクト`gitlab-org/gitlab`でエピック`&123`を親として持つすべてのイシューをリストします:

  ```plaintext
  project = "gitlab-org/gitlab" and epic = &123
  ```

- プロジェクト`gitlab-org/gitlab`でエピック`gitlab-com&123`を親として持つすべてのイシューをリストします:

  ```plaintext
  project = "gitlab-org/gitlab" and epic = gitlab-com&123
  ```

### グループ {#group}

**説明**: 指定されたグループ内のすべてのプロジェクトでイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `String`

**Additional details**（補足情報）:

- 一度にクエリできるグループは1つのみです。
- `group`は、`project`フィールドと一緒に使用することはできません。
- グループオブジェクト（エピックなど）の埋め込みビュー内で使用する場合に省略すると、`group`は現在のグループであると見なされます。
- `group`フィールドを使用すると、そのグループ、すべてのサブグループ、および子プロジェクト内のすべてのオブジェクトがクエリされます。
- デフォルトでは、イシューまたはマージリクエストは、すべてのサブグループのすべての子孫プロジェクトで検索されます。グループの直接の子プロジェクトのみをクエリするには、[`includeSubgroups`フィールド](#include-subgroups)を`false`に設定します。

**Examples**（例）:

- `gitlab-org`グループとそのサブグループのイシューをリストします:

  ```plaintext
  group = "gitlab-org"
  ```

- `gitlab-org`グループとそのサブグループのすべてのタスクをリストします:

  ```plaintext
  group = "gitlab-org" and type = Task
  ```

### ヘルスステータス {#health-status}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- エイリアス`healthStatus`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- ヘルスステータスによるエピックのクエリのサポートは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。

{{< /history >}}

**説明**: ヘルスステータスでイシューまたはエピックをクエリします。

**Allowed value types**（許可される値の型）:

- `StringEnum`（`"needs attention"`、`"at risk"`、または`"on track"`のいずれか）
- `Nullable`（`null`、`none`、または`any`のいずれか）

**Examples**（例）:

- ヘルスステータスが設定されていないすべてのイシューをリストします:

  ```plaintext
  health = any
  ```

- ヘルスステータスが「対応が必要」であるすべてのイシューをリストします:

  ```plaintext
  health = "needs attention"
  ```

### ID {#id}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/92)されました。
- IDによるエピックのクエリのサポートは、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: ID別にイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `Number`（正の整数のみ）
- `List`（`Number`値を含む）

**Examples**（例）:

- ID `123`のイシューをリストします:

  ```plaintext
  id = 123
  ```

- ID `1`、`2`、または`3`のイシューをリストします:

  ```plaintext
  id in (1, 2, 3)
  ```

- ID `1`、`2`、または`3`のすべてのマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and id in (1, 2, 3)
  ```

### サブグループを含める {#include-subgroups}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/106)されました。
- このフィールドをエピックで使用するためのサポートが、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: グループの階層全体で、イシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `Boolean`（`true`または`false`のいずれか）

**Additional details**（補足情報）:

- このフィールドは、`group`フィールドでのみ使用できます。
- このフィールドの値は、デフォルトで`false`に設定されています。

**Examples**（例）:

- `gitlab-org`グループの直接の子である任意のプロジェクト内のイシューを一覧表示します:

  ```plaintext
  group = "gitlab-org" and includeSubgroups = false
  ```

- `gitlab-org`グループの階層全体内の任意のプロジェクト内のイシューを一覧表示します:

  ```plaintext
  group = "gitlab-org" and includeSubgroups = true
  ```

### イテレーション {#iteration}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74)されました。
- イテレーション値の型のサポートが、GitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79)。

{{< /history >}}

**説明**: 関連付けられた[イテレーション](../group/iterations/_index.md)でイシューをクエリします。

**Allowed value types**（許可される値の型）:

- `Number`（正の整数のみ）
- `Iteration`（例: `*iteration:123456`）
- `List`（`Number`または`Iteration`値を含む）
- `Enum`（`current`のみがサポートされています）
- `Nullable`（`none`または`any`のいずれか）

**Additional details**（補足情報）:

- イシューが持つことができるイテレーションは1つのみであるため、`=`演算子は`List`型の`iteration`フィールドでは使用できません。
- `in`演算子は、`MergeRequest`型ではサポートされていません。

**Examples**（例）:

- ID `123456`のイシューを一覧表示します（クエリで数値を使用）:

  ```plaintext
  iteration = 123456
  ```

- イテレーション`123`または`456`の一部であるすべてのイシューを一覧表示します（数値を使用）:

  ```plaintext
  iteration in (123, 456)
  ```

- ID `123456`のイテレーションを持つすべてのイシューを一覧表示します（イテレーション構文を使用）:

  ```plaintext
  iteration = *iteration:123456
  ```

- イテレーション`123`または`456`の一部であるすべてのイシューを一覧表示します（イテレーション構文を使用）:

  ```plaintext
  iteration in (*iteration:123, *iteration:456)
  ```

- 現在のイテレーション内のすべてのイシューを一覧表示します

  ```plaintext
  iteration = current
  ```

### ラベル {#labels}

{{< history >}}

- ラベル値の型のサポートが、GitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79)。
- エイリアス`labels`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- ラベルでエピックをクエリするためのサポートが、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 関連付けられたラベルでイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `Label`（例: `~bug`、`~"team::planning"`）
- `List`（`String`または`Label`値を含む）
- `Nullable`（`none`または`any`のいずれか）

**Additional details**（補足情報）:

- スコープ付きラベル、またはスペースを含むラベルは引用符で囲む必要があります。
- `in`演算子は、`MergeRequest`型ではサポートされていません。

**Examples**（例）:

- ラベル`~bug`が付いたすべてのイシューを一覧表示します:

  ```plaintext
  label = ~bug
  ```

- ラベル`~"workflow::in progress"`が付いていないすべてのイシューを一覧表示します:

  ```plaintext
  label != ~"workflow::in progress"
  ```

- ラベル`~bug`および`~"team::planning"`が付いたすべてのイシューを一覧表示します:

  ```plaintext
  label = (~bug, ~"team::planning")
  ```

- ラベル`~bug`または`~feature`が付いたすべてのイシューを一覧表示します:

  ```plaintext
  label in (~bug, ~feature)
  ```

- ラベルに`~bug`または`~feature`のいずれも含まれていないすべてのイシューを一覧表示します:

  ```plaintext
  label != (~bug, ~feature)
  ```

- スコープ付きラベルが適用されないすべてのイシューをスコープ`workflow::`で一覧表示します:

  ```plaintext
  label != ~"workflow::*"
  ```

- ラベル`~bug`および`~"team::planning"`を持つすべてのマージリクエストを一覧表示します

  ```plaintext
  type = MergeRequest and label = (~bug, ~"team::planning")
  ```

### マージ日時 {#merged-at}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エイリアス`mergedAt`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- 演算子`>=`および`<=`は、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)。

{{< /history >}}

**説明**: マージリクエストがマージされた日付でマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `AbsoluteDate`（`YYYY-MM-DD`形式）
- `RelativeDate`（`<sign><digit><unit>`形式。符号は`+`、`-`、または省略、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）または`y`（年）のいずれか）

**Additional details**（補足情報）:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンの00:00〜23:59と見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

**Examples**（例）:

- 過去6か月にマージされたすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and merged > -6m
  ```

- 2025年1月にマージされたすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and merged > 2025-01-01 and merged < 2025-01-31
  ```

### マージしたユーザー {#merged-by-user}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エイリアス`mergedBy`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。

{{< /history >}}

**説明**: マージリクエストをマージしたユーザーでマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `User`（例: `@username`）

**Examples**（例）:

- 現在のユーザーがマージしたすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and merger = currentUser()
  ```

### マイルストーン {#milestone}

{{< history >}}

- マイルストーン値の型のサポートが、GitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/77)。
- マイルストーンでエピックをクエリするためのサポートが、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 関連付けられたマイルストーンで、イシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `Milestone`（例: `%Backlog`、`%"Awaiting Further Demand"`）
- `List`（`String`または`Milestone`値を含む）
- `Nullable`（`none`または`any`のいずれか）

**Additional details**（補足情報）:

- スペースを含むマイルストーンは、引用符（`"`）で囲む必要があります。
- イシューが持つことができるマイルストーンは1つのみであるため、`=`演算子を`milestone`フィールドの`List`型で使用することはできません。
- `in`演算子は、`MergeRequest`および`Epic`型ではサポートされていません。
- `Epic`タイプは、`none`や`any`のようなワイルドカードのマイルストーンフィルターをサポートしていません。

**Examples**（例）:

- マイルストーン`%Backlog`のすべてのイシューを一覧表示します:

  ```plaintext
  milestone = %Backlog
  ```

- マイルストーン`%17.7`または`%17.8`のすべてのイシューを一覧表示します:

  ```plaintext
  milestone in (%17.7, %17.8)
  ```

- 今後のマイルストーンにあるすべてのイシューを一覧表示します:

  ```plaintext
  milestone = upcoming
  ```

- 現在のマイルストーンにあるすべてのイシューを一覧表示します:

  ```plaintext
  milestone = started
  ```

- マイルストーンが`%17.7`または`%17.8`のいずれでもないすべてのイシューを一覧表示します:

  ```plaintext
  milestone != (%17.7, %17.8)
  ```

### リアクション絵文字 {#my-reaction-emoji}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223)されました。

{{< /history >}}

**説明**: 現在のユーザーの[絵文字リアクション](../emoji_reactions.md)によって、イシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `String`

**Examples**（例）:

- 現在のユーザーが賛成の絵文字で反応したすべてのイシューを一覧表示します:

  ```plaintext
  myReaction = "thumbsup"
  ```

- 現在のユーザーが反対の絵文字で反応しなかったすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and myReaction != "thumbsdown"
  ```

### プロジェクト {#project}

**説明**: 特定のプロジェクト内のイシューまたはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `String`

**Additional details**（補足情報）:

- 一度にクエリできるプロジェクトは1つのみです。
- `project`フィールドは、`group`フィールドと一緒に使用することはできません。
- 埋め込みビュー内で使用する場合に省略すると、`project`は現在のプロジェクトであると見なされます。

**Examples**（例）:

- `gitlab-org/gitlab`プロジェクト内のすべてのイシューと作業アイテムを一覧表示します:

  ```plaintext
  project = "gitlab-org/gitlab"
  ```

### レビュアー {#reviewers}

{{< history >}}

- エイリアス`reviewers`と`reviewedBy`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。

{{< /history >}}

**説明**: 1人以上のユーザーによってレビューされたマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `String`
- `User`（例: `@username`）
- `Nullable`（`null`、`none`、または`any`のいずれか）

**Examples**（例）:

- 現在のユーザーによってレビューされたすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and reviewer = currentUser()
  ```

### ソースブランチ {#source-branch}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。

{{< /history >}}

**説明:**それらのソースブランチでマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `String`、`List`

**Additional details**（補足情報）:

- `List`の値は、`in`および`!=`演算子でのみサポートされています。

**Examples**（例）:

- 特定のブランチからのすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and sourceBranch = "feature/new-feature"
  ```

- 複数のブランチからのすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and sourceBranch in ("main", "develop")
  ```

- 特定のブランチからではないすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and sourceBranch != "main"
  ```

### ステート {#state}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/96)されました。
- ステータス別のエピックのクエリのサポートが、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: ステータスでイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `Enum`
  - イシューおよび作業アイテムタイプの場合、`opened`、`closed`、または`all`のいずれか
  - `MergeRequest`タイプの場合、`opened`、`closed`、`merged`、または`all`のいずれか

**Additional details**（補足情報）:

- `state`フィールドは`!=`演算子をサポートしていません。

**Examples**（例）:

- クローズされたすべてのイシューを一覧表示します:

  ```plaintext
  state = closed
  ```

- オープンされたすべてのイシューを一覧表示します:

  ```plaintext
  state = opened
  ```

- それらのステータスに関係なく、すべてのイシューを一覧表示します（デフォルトも同様）:

  ```plaintext
  state = all
  ```

- マージされたすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and state = merged
  ```

### ステータス {#status}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。

{{< /history >}}

**説明:**それらのステータスでイシューをクエリします。

**Allowed value types**（許可される値の型）: `String`

**Examples**（例）:

- To Doのステータスを持つすべてのイシューを一覧表示します:

  ```plaintext
  status = "To do"
  ```

### サブスクライブ {#subscribed}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223)されました。

{{< /history >}}

**説明**: 現在のユーザーがオンまたはオフに[通知を設定](../profile/notifications.md)しているかどうかによって、イシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `Boolean`

**Examples**（例）:

- 現在のユーザーが通知をオンに設定しているすべてのオープンなイシューを一覧表示します:

  ```plaintext
  state = opened and subscribed = true
  ```

- 現在のユーザーが通知をオフに設定しているすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and subscribed = false
  ```

### ターゲットブランチ {#target-branch}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。

{{< /history >}}

**説明:**それらのターゲットブランチによってマージリクエストをクエリします。

**Allowed value types**（許可される値の型）: `String`、`List`

**Additional details**（補足情報）:

- `List`の値は、`in`および`!=`演算子でのみサポートされています。

**Examples**（例）:

- 特定のブランチをターゲットとするすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and targetBranch = "feature/new-feature"
  ```

- 複数のブランチをターゲットとするすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and targetBranch in ("main", "develop")
  ```

- 特定のブランチをターゲットとしていないすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and targetBranch != "main"
  ```

### 型 {#type}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)されました。
- エピックのクエリのサポートが、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: クエリするオブジェクトのタイプ: イシュー、エピック、またはマージリクエスト。

**Allowed value types**（許可される値の型）:

- `Enum`、次のいずれかになります:
  - `Issue`
  - `Incident`
  - `Epic`
  - `TestCase`
  - `Requirement`
  - `Task`
  - `Ticket`
  - `Objective`
  - `KeyResult`
  - `MergeRequest`
- `List`（1つ以上の`enum`値を含む）

**Additional details**（補足情報）:

- 埋め込みビュー内で使用する場合に省略すると、デフォルトの`type`は`Issue`になります。
- `type = Epic`クエリは、[グループ](#group)フィールドでのみ一緒に使用できます。
- `in`演算子を使用して、同じクエリ内の他のタイプと`Epic`タイプおよび`MergeRequest`タイプを結合することはできません。

**Examples**（例）:

- インシデントを一覧表示します:

  ```plaintext
  type = incident
  ```

- イシューとタスクをリスト表示する:

  ```plaintext
  type in (Issue, Task)
  ```

- 現在のユーザーに割り当てられたすべてのマージリクエストを一覧表示します:

  ```plaintext
  type = MergeRequest and assignee = currentUser()
  ```

- グループ`gitlab-org`内の現在のユーザーが作成者であるすべてのエピックを一覧表示します

  ```plaintext
  group = "gitlab-org" and type = Epic and author = currentUser()
  ```

### 更新日時 {#updated-at}

{{< history >}}

- エイリアス`updatedAt`がGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137)されました。
- 演算子`>=`および`<=`は、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58)。
- 最終更新日によるエピックのクエリのサポートが、GitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)。

{{< /history >}}

**説明**: 最後に更新された日時でイシュー、エピック、またはマージリクエストをクエリします。

**Allowed value types**（許可される値の型）:

- `AbsoluteDate`（`YYYY-MM-DD`形式）
- `RelativeDate`（`<sign><digit><unit>`形式。符号は`+`、`-`、または省略、数字は整数、`unit`は`d`（日）、`w`（週）、`m`（月）または`y`（年）のいずれか）

**Additional details**（補足情報）:

- `=`演算子の場合、時間範囲はユーザーのタイムゾーンの00:00〜23:59と見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

**Examples**（例）:

- 過去1か月に編集されていないすべてのイシューを一覧表示します:

  ```plaintext
  updated < -1m
  ```

- 今日編集されたすべてのイシューを一覧表示します:

  ```plaintext
  updated = today()
  ```

- 過去1週間に編集されていないすべてのオープンMRを一覧表示します:

  ```plaintext
  type = MergeRequest and state = opened and updated < -1w
  ```

### ウェイト {#weight}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

**説明**: それらのウェイトでイシューをクエリします。

**Allowed value types**（許可される値の型）:

- `Number`（正の整数または0のみ）
- `Nullable`（`null`、`none`、または`any`のいずれか）

**Additional details**（補足情報）:

- 比較演算子`<`および`>`は使用できません。

**Examples**（例）:

- ウェイトが5のすべてのイシューを一覧表示します:

  ```plaintext
  weight = 5
  ```

- ウェイトが5ではないすべてのイシューを一覧表示します:

  ```plaintext
  weight != 5
  ```

## 埋め込みビューのフィールド {#fields-in-embedded-views}

{{< history >}}

- フィールド`iteration`がGitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74)されました。
- マージリクエストのサポートが、GitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/491246)。
- フィールド`lastComment`がGitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/512154)されました。
- エピックのサポートは、GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680)されました。
- フィールド`status`、`sourceBranch`、`targetBranch`、`sourceProject`、および`targetProject`がGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407)されました。
- GitLab 18.3で、エピックのフィールド`health`、および`type`が[導入されました](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)。
- フィールド`subscribed`がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223)されました。

{{< /history >}}

埋め込みビューでは、`fields`ビューパラメータはフィールドのコンマ区切りリスト、またはレンダリングされた埋め込みビューに含めるフィールドを示すために使用できるフィールド関数です（例: `fields: title, state, health, epic, milestone, weight, updated`）。

| フィールド            | 名前またはエイリアス                         | サポートされているオブジェクト             | 説明 |
| ---------------- | ------------------------------------- | ----------------------------- | ----------- |
| ユーザーによる承認 | `approver`、`approvers`、`approvedBy` | マージリクエスト                | マージリクエストを承認したユーザーを表示します |
| 担当者        | `assignee`、`assignees`               | イシュー、マージリクエスト        | オブジェクトに割り当てられたユーザーを表示します |
| 作成者           | `author`                              | イシュー、エピック、マージリクエスト | オブジェクトの作成者を表示します |
| クローズ日        | `closed`、`closedAt`                  | イシュー、エピック、マージリクエスト | オブジェクトがクローズされてからの時間を表示します |
| 機密     | `confidential`                        | イシュー、エピック                 | オブジェクトが機密かどうかを示す`Yes`または`No`を表示します |
| 作成日       | `created`、`createdAt`                | イシュー、エピック、マージリクエスト | オブジェクトが作成されてからの経過時間を表示します |
| 説明      | `description`                         | イシュー、エピック、マージリクエスト | オブジェクトの説明を表示します |
| ドラフト            | `draft`                               | マージリクエスト                | `Yes`または`No`を表示して、マージリクエストがドラフト状態にあるかどうかを示します |
| 期限         | `due`、`dueDate`                      | イシュー、エピック                 | オブジェクトの期日までの時間を表示します |
| エピック             | `epic`                                | イシュー                        | イシューのエピックへのリンクを表示します。PremiumプランおよびUltimateプランで利用できます。 |
| ヘルスステータス    | `health`、`healthStatus`              | イシュー、エピック                 | オブジェクトのヘルスステータスを示すバッジを表示します。Ultimateプランで利用可能です |
| ID               | `id`                                  | イシュー、エピック、マージリクエスト | オブジェクトのIDを表示します |
| イテレーション        | `iteration`                           | イシュー                        | オブジェクトに関連付けられたイテレーションを表示します。PremiumプランおよびUltimateプランで利用できます。 |
| ラベル           | `label`、`labels`                     | イシュー、エピック、マージリクエスト | オブジェクトに関連付けられたラベルを表示します。特定のラベルをフィルタリングするためのパラメータを受け入れることができます。例: `labels("workflow::*", "backend")` |
| 最後のコメント     | `lastComment`                         | イシュー、エピック、マージリクエスト | オブジェクトに対して行われた最後のコメントを表示します |
| マージ日        | `merged`、`mergedAt`                  | マージリクエスト                | マージリクエストがマージされてからの経過時間を表示します |
| マイルストーン        | `milestone`                           | イシュー、エピック、マージリクエスト | オブジェクトに関連付けられているマイルストーンを表示します |
| レビュアー        | `reviewer`、`reviewers`               | マージリクエスト                | マージリクエストのレビューに割り当てられたユーザーを表示します |
| ソースブランチ    | `sourceBranch`                        | マージリクエスト                | マージリクエストのソースブランチを表示します |
| ソースプロジェクト   | `sourceProject`                       | マージリクエスト                | マージリクエストのソースブランチプロジェクトを表示します |
| 開始日       | `start`、`startDate`                  | エピック                         | エピックの開始日を表示します |
| ステート            | `state`                               | イシュー、エピック、マージリクエスト | オブジェクトの状態を示すバッジを表示します。イシューとエピックの場合、値は`Open`または`Closed`です。マージリクエストの場合、値は`Open`、`Closed`、または`Merged`です |
| ステータス           | `status`                              | イシュー                        | イシューのステータスを示すバッジを表示します。たとえば、「To Do」や「完了」などがあります。PremiumプランおよびUltimateプランで利用できます。 |
| サブスクリプション       | `subscribed`                          | イシュー、エピック、マージリクエスト | 現在のユーザーがオブジェクトをサブスクライブしているかどうかを示す`Yes`または`No`を表示します |
| ターゲットブランチ    | `targetBranch`                        | マージリクエスト                | マージリクエストのターゲットブランチを表示します。 |
| ターゲットプロジェクト   | `targetProject`                       | マージリクエスト                | マージリクエストのターゲットプロジェクトを表示します |
| タイトル            | `title`                               | イシュー、エピック、マージリクエスト | オブジェクトのタイトルを表示します |
| 型             | `type`                                | イシュー、エピック                 | 作業アイテムのタイプ（`Issue`、`Task`、`Objective`など）を表示します |
| 更新日       | `updated`、`updatedAt`                | イシュー、エピック、マージリクエスト | オブジェクトが最後に更新されてからの経過時間を表示します |
| ウェイト           | `weight`                              | イシュー                        | オブジェクトのウェイトを表示します。PremiumプランおよびUltimateプランで利用できます。 |

## 埋め込みビューをソートするためのフィールド {#fields-to-sort-embedded-views-by}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/178)されました。
- ヘルスステータスでエピックをソートするサポートが、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222)されました。

{{< /history >}}

埋め込みビューでは、`sort`ビューパラメータは、指定されたフィールドと順序で結果をソートするソート順序（`asc`または`desc`）が続くフィールド名です。

| フィールド         | 名前（およびエイリアス）         | サポート対象                 | 説明                                     |
|---------------|--------------------------|-------------------------------|-------------------------------------------------|
| クローズ日     | `closed`、`closedAt`     | イシュー、エピック、マージリクエスト | クローズ日でソート                             |
| 作成済み       | `created`、`createdAt`   | イシュー、エピック、マージリクエスト | 作成日でソート                            |
| 期限      | `due`、`dueDate`         | イシュー、エピック                 | 期日でソート                                |
| ヘルスステータス | `health`、`healthStatus` | イシュー、エピック                 | ヘルスステータスでソート                           |
| マージ日     | `merged`、`mergedAt`     | マージリクエスト                | マージ日でソート                              |
| マイルストーン     | `milestone`              | イシュー、マージリクエスト        | マイルストーンの期日でソート                      |
| 人気度    | `popularity`             | イシュー、エピック、マージリクエスト | 絵文字リアクションの賛成数でソート |
| 開始日    | `start`、`startDate`     | エピック                         | 開始日でソート                              |
| タイトル         | `title`                  | イシュー、エピック、マージリクエスト | タイトルでソート                                   |
| 更新日    | `updated`、`updatedAt`   | イシュー、エピック、マージリクエスト | 最終更新日でソート                       |
| ウェイト        | `weight`                 | イシュー                        | ウェイトでソート                                  |

**Examples**（例）:

- `gitlab-org/gitlab`プロジェクト内のすべてのイシューをタイトルでソートして表示します。列`state`、`title`、および`updated`を表示します。

  ````yaml
  ```glql
  display: table
  fields: state, title, updated
  sort: title asc
  query: project = "gitlab-org/gitlab" and type = Issue
  ```
  ````

- 認証されたユーザーに割り当てられた`gitlab-org`グループ内のすべてのマージリクエストをマージ日（最新順）でソートして表示します。列`title`、`reviewer`、および`merged`を表示します。

  ````yaml
  ```glql
  display: table
  fields: title, reviewer, merged
  sort: merged desc
  query: group = "gitlab-org" and type = MergeRequest and state = merged and author = currentUser()
  limit: 10
  ```
  ````

- `gitlab-org`グループ内のすべてのエピックを開始日（最も古い順）でソートして表示します。列`title`、`state`、および`startDate`を表示します。

  ````yaml
  ```glql
  display: table
  fields: title, state, startDate
  sort: startDate asc
  query: group = "gitlab-org" and type = Epic
  ```
  ````

- 割り当てられたウェイトを持つ`gitlab-org`グループ内のすべてのイシューを、ウェイト（最も高い順）でソートして表示します。列`title`、`weight`、および`health`を表示します。

  ````yaml
  ```glql
  display: table
  fields: title, weight, health
  sort: weight desc
  query: group = "gitlab-org" and weight = any
  ```
  ````

- `gitlab-org`グループ内のすべてのイシューを今日から1週間以内に期限が来るように、期日（最も早い順）でソートして表示します。列`title`、`duedate`、および`assignee`を表示します。

  ````yaml
  ```glql
  display: table
  fields: title, dueDate, assignee
  sort: dueDate asc
  query: group = "gitlab-org" and due >= today() and due <= 1w
  ```
  ````

## トラブルシューティング {#troubleshooting}

### クエリタイムアウトエラー {#query-timeout-errors}

次のエラーメッセージが表示される場合があります:

```plaintext
Embedded view timed out. Add more filters to reduce the number of results.
```

```plaintext
Query temporarily blocked due to repeated timeouts. Please try again later or try narrowing your search scope.
```

これらのエラーは、クエリの実行に時間がかかりすぎると発生します。結果セットが大きい場合や、検索範囲が広い場合、タイムアウトが発生する可能性があります。

この問題を解決するには、フィルターを追加して検索範囲を制限します:

- `created`、`updated`、または`closed`のような日付フィールドを使用して、結果を特定の期間に制限する期間フィルターを追加します。次に例を示します:

  ````yaml
  ```glql
  display: table
  fields: title, labels, created
  query: group = "gitlab-org" and label = "group::knowledge" and created > "2025-01-01" and created < "2025-03-01"
  ```
  ````

- アクティブな項目に焦点を当てるために、最近の更新でフィルタリングします:

  ````yaml
  ```glql
  display: table
  fields: title, labels, updated
  query: group = "gitlab-org" and label = "group::knowledge" and updated > -3m
  ```
  ````

- 可能な場合は、グループ全体の検索ではなく、プロジェクト固有のクエリを使用します:

  ````yaml
  ```glql
  display: table
  fields: title, state, assignee
  query: project = "gitlab-org/gitlab" and state = opened and updated > -1m
  ```
  ````
