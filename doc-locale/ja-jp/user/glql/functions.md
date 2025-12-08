---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GLQL関数
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`glql_integration`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14767)されました。デフォルトでは無効になっています。
- GitLab.comで有効（GitLab 17.4、一部のグループとプロジェクト）。
- [ベータ](../../policy/development_stages_support.md#beta)ステータスにプロモート（GitLab 17.10）。
- GitLab 17.10で、実験的機能からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/476990)されました。
- GitLab 17.10のGitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になりました。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

[GitLab Query Language（GLQL）](_index.md)で関数を使用して、動的なクエリを作成します。

## クエリ内の関数 {#functions-inside-query}

クエリのコンテキストを特定するために、現在のユーザーまたは日付でフィルタリングするなど、[クエリ](_index.md#query-syntax)内で関数を使用します。

### 現在のユーザー {#current-user}

**Function name**（関数名）：`currentUser`

**パラメータ**: なし

**Syntax**（構文）: `currentUser()`

**説明**: 現在の認証済みユーザーに評価されます。

**Additional details**（補足情報）:

- クエリでこの関数を使用すると、認証されていないユーザーに対してクエリが失敗します。

**Examples**（例）:

- 現在の認証済みユーザーが担当者であるすべてのイシューをリストします:

  ```plaintext
  assignee = currentUser()
  ```

- 現在の認証済みユーザーが担当者であるが、作成者ではないすべてのマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and assignee = currentUser() and author != currentUser()
  ```

### 今日 {#today}

**Function name**（関数名）：`today`

**パラメータ**: なし

**Syntax**（構文）: `today()`

**説明**: ユーザーのタイムゾーンで今日の午前0時に評価されます。

**Additional details**（補足情報）:

- `=`演算子で使用すると、ユーザーのタイムゾーンで午前0時から午後11時59分までの時間範囲が考慮されます。

**Examples**（例）:

- 今日作成されたすべてのイシューをリストします:

  ```plaintext
  created = today()
  ```

- 今日マージされたすべてのマージリクエストをリストします:

  ```plaintext
  type = MergeRequest and merged = today()
  ```

## 埋め込みビューの関数 {#functions-in-embedded-views}

[埋め込みビュー](_index.md#embedded-views)の既存のフィールドから新しい列を派生させるには、`fields`パラメータに関数を含めます。

### 新しい列にラベルを抽出する {#extract-labels-into-a-new-column}

**Function name**（関数名）：`labels`

**パラメータ**: 1つ以上の`String`値

**Syntax**（構文）: `labels("field1", "field2")`

**説明**: 

`labels`関数は、1つ以上のラベル名の文字列値をパラメータとして受け取り、イシューのそれらのラベルのみを含むフィルタリングされた列を作成します。この関数はエクストラクターとしても機能するため、ラベルが抽出された場合、その列も表示するように選択すると、通常の`labels`列には表示されなくなります。

**Additional details**（補足情報）:

- デフォルトでは、この関数はラベル名との完全一致を検索します。任意の文字に一致する文字列内のワイルドカード文字（`*`）。
- 最小1つ、最大100個のラベル名を`labels`関数に渡すことができます。
- この関数に渡されるラベル名は大文字と小文字が区別されません。たとえば、`Deliverable`と`deliverable`は同等です。

**Examples**（例）:

- 列にすべての`workflow`スコープ付きラベルを含めます:

  ```plaintext
  labels("workflow::*")
  ```

- ラベル`Deliverable`、`Stretch`、および`Spike`を含めます:

  ```plaintext
  labels("Deliverable", "Stretch", "Spike")
  ```

- `backend`、`frontend`、および`end`で終わる他のすべてのラベルを含めます:

  ```plaintext
  labels("*end")
  ```

埋め込みビューに`labels`関数を含めるには:

````markdown
```glql
display: list
fields: title, health, due, labels("workflow::*"), labels
limit: 5
query: project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````
