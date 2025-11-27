---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Query Language（GLQL）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`glql_integration`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14767)されました。デフォルトでは無効になっています。
- GitLab.comのGitLab 17.4で、グループとプロジェクトのサブセットに対して有効になりました。
- GitLab 17.10で実験的機能からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/476990)されました。
- GitLab 17.10のGitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になりました。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

GitLab Query Language（GLQL）は、すべてのGitLabに対応する単一の言語を作成するための試みです。使い慣れた構文を使用して、プラットフォーム内のあらゆる場所からコンテンツをフィルタリングして埋め込むために使用します。

Markdownコードブロックにクエリを埋め込みます。埋め込みビューは、GLQLソースコードブロックのレンダリングされた出力です。

[GLQLを搭載した埋め込みビューのフィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509792)で、ごフィードバックをお寄せください。

## クエリ構文 {#query-syntax}

そのクエリ構文は、主に論理式で構成されています。これらの式は、`<field> <operator> <value> and ...`の構文に従います。

### フィールド {#fields}

フィールド名には、`assignee`、`author`、`label`、`milestone`のような値を使用できます。`type`フィールドは、オブジェクトの種類（`Issue`、`MergeRequest`など）または作業アイテムの種類（`Task`や`Objective`など）でクエリをフィルタリングするために使用できます。

サポートされているフィールド、サポートされている演算子、値の種類の完全なリストについては、[GLQLフィールド](fields.md)を参照してください。

### 演算子 {#operators}

**Comparison operators**（比較演算子）:

| GLQL演算子 | 説明                             | 検索での同等   |
|---------------|-----------------------------------------|------------------------|
| `=`           | 等しい / リスト内のすべてを含む           | `is`（=に等しい）        |
| `!=`          | 等しくない / リストに含まれていない | `is not`（=に等しくない）    |
| `in`          | リストに含まれる                       | `or` / `is one of`     |
| `>`           | より大きい                            | {{< icon name="dotted-circle" >}}対象外 |
| `<`           | より小さい                               | {{< icon name="dotted-circle" >}}対象外 |
| `>=`          | 以上（>=）                | {{< icon name="dotted-circle" >}}対象外 |
| `<=`          | 以下（<=）                   | {{< icon name="dotted-circle" >}}対象外 |

**Logical operators**（論理演算子）: `and`のみがサポートされています。`or`は、`in`比較演算子を使用することで、一部のフィールドで間接的にサポートされます。

### 値 {#values}

値には以下を含めることができます:

- 文字列
- 数字
- 相対日付（`-1d`、`2w`、`-6m`、`1y`など）
- 絶対日付（`YYYY-MM-DD`形式、`2025-01-01`など）
- 関数（ユーザーフィールドの場合は`currentUser()`、日付の場合は`today()`など）
- Enum値（マイルストーンの場合は`upcoming`や`started`など）
- ブール値（`true`または`false`）
- Null許容値（`null`、`none`、`any`など）
- GitLabの参照（ラベルの場合は`~label`、マイルストーンの場合は`%Backlog`、ユーザーの場合は`@username`など）
- 以前の値のいずれかを含むリスト（括弧`()`で囲み、カンマ`,`で区切ります）

## 埋め込みビュー {#embedded-views}

埋め込みビューは、MarkdownのGLQLソースコードブロックの出力です。ソースには、GLQLクエリの結果を表示する方法を記述したYAML属性と、クエリが含まれています。

### サポートされている領域 {#supported-areas}

{{< history >}}

- リポジトリMarkdownファイルの埋め込みビューは、[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197950)GitLab 18.3。

{{< /history >}}

埋め込みビューは、次の領域に表示できます:

- グループとプロジェクトのWiki
- 次の説明とコメント:
  - エピック
  - イシュー
  - マージリクエスト
  - 作業アイテム（タスク、OKR、またはエピック）
- リポジトリMarkdownファイル

### 構文 {#syntax}

埋め込みビューのソースの構文は、次のYAMLのスーパーセットです:

- `query`パラメータ: 論理演算子（`and`など）で結合された式。
- プレゼンテーションレイヤーに関連するパラメータ（`display`、`limit`、`fields`、`title`、`description`など）はYAMLとして表されます。

ビューは、Markdownでコードブロックとして定義されます（Mermaidなどの他のコードブロックと同様）。

例: 

- `gitlab-org/gitlab`の認証済みユーザーに割り当てられた最初の5つのオープンイシューのテーブルを表示します。
- 列`title`、`state`、`health`、`description`、`epic`、`milestone`、`weight`、`updated`を表示します。

````yaml
```glql
display: table
title: GLQL table 🎉
description: This view lists my open issues
fields: title, state, health, epic, milestone, weight, updated
limit: 5
query: group = "gitlab-org" AND assignee = currentUser() AND state = opened
```
````

このソースは、次のようなテーブルをレンダリングする必要があります:

![現在のユーザーに割り当てられているイシューを一覧表示するテーブル](img/glql_table_v18_5.png)

#### プレゼンテーションの構文 {#presentation-syntax}

{{< history >}}

- GitLab 17.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/508956)されました: YAMLフロントマターを使用したプレゼンテーションレイヤーの構成は非推奨です。
- `title`および`description`のパラメータは、GitLab 17.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183709)。
- 並べ替えとページネーションは、GitLab 18.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)。
- `collapsed`パラメータは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197824)。

{{< /history >}}

`query`パラメータとは別に、オプションのパラメータを追加して、ビューのプレゼンテーションの詳細を構成できます。

サポートされているパラメータ:

| パラメータ     | デフォルト                                       | 説明 |
| ------------- | --------------------------------------------- | ----------- |
| `collapsed`   | `false`                                       | ビューを折りたたむか展開するかを指定します。 |
| `description` | なし                                          | タイトルの下に表示するオプションの説明。 |
| `display`     | `table`                                       | データを表示する方法。サポートされているオプション：`table`、`list`、または`orderedList`。 |
| `fields`      | `title`                                       | ビューに含める[フィールド](fields.md#fields-in-embedded-views)のコンマ区切りリスト。 |
| `limit`       | `100`                                         | 最初のページネーションに表示するアイテムの数。最大値は`100`です。 |
| `sort`        | `updated desc`                                | ソート順（`asc`または`desc`）に従った、[データをソートするフィールド](fields.md#fields-to-sort-embedded-views-by)。 |
| `title`       | `Embedded table view`または`Embedded list view` | 埋め込みビューの上部に表示されるタイトル。 |

たとえば、`gitlab-org/gitlab`プロジェクトの認証済みユーザーに割り当てられた最初の5つのイシューを、期日（最も早い順）でソートし、`title`、`health`、`due`フィールドを表示する場合は、次のようになります:

````yaml
```glql
display: list
fields: title, health, due
limit: 5
sort: due asc
query: group = "gitlab-org" AND assignee = currentUser() AND state = opened
```
````

このソースは、次のようなリストをレンダリングする必要があります:

![現在のユーザーに割り当てられているイシューのリストを含む埋め込みビュー](img/glql_list_v18_5.png)

#### ページネーション {#pagination}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)されました。

{{< /history >}}

埋め込みビューには、デフォルトで結果の最初のページネーションが表示されます。`limit`パラメータは、表示されるアイテムの数を制御します。

次のページネーションを読み込むには、最後の行で**更に表示**を選択します。

#### フィールド関数 {#field-functions}

動的に生成された列を作成するには、ビューの`fields`パラメータで関数を使用します。完全なリストについては、[埋め込みビューの関数](functions.md#functions-in-embedded-views)を参照してください。

#### カスタムフィールドエイリアス {#custom-field-aliases}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/535558)されました。

{{< /history >}}

テーブルビューの列の名前をカスタム値に変更するには、`AS`構文キーワードを使用してフィールドにエイリアスを設定します。

````yaml
```glql
display: list
fields: title, labels("workflow::*") AS "Workflow", labels("priority::*") AS "Priority"
limit: 5
query: project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

このソースは、`Title`、`Workflow`、`Priority`の列を含むビューを表示します。

### アクションの表示 {#view-actions}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184788)されました。
- **再読み込み**アクションは、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/537310)。

{{< /history >}}

ビューがページに表示されたら、**View actions**（アクションの表示）（{{< icon name="ellipsis_v" >}}）ドロップダウンを使用して、アクションを実行します。

サポートされているアクション:

| アクション        | 説明                                                    |
| ------------- | -------------------------------------------------------------- |
| ソースを表示   | ビューのソースを表示します。                                   |
| ソースをコピー   | ビューのソースをクリップボードにコピーします。                      |
| コンテンツをコピー | テーブルまたはリストのコンテンツをクリップボードにコピーします。 |
| 再読み込み        | このビューを再読み込む。                                              |
