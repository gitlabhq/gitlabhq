---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQLフィールド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`glql_integration`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14767)されました。デフォルトでは無効になっています。
- GitLab.comとGitLab 17.4で一部のグループとプロジェクトで有効になりました。
- GitLab 17.10で[実験](https://gitlab.com/gitlab-org/gitlab/-/issues/476990)から[ベータ](../../policy/development_stages_support.md#beta)に変更されました。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/work_items/476990)。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

GitLab Query Language（GLQL）では、フィールドは以下の用途で使用されます:

- [GLQLクエリ](_index.md#query-syntax)から返される結果をフィルタリングします。
- [組み込みビュー](_index.md#presentation-syntax)に表示される詳細を制御します。
- 組み込みビューに表示される結果をソートします。

組み込みビューの3つのパラメータでフィールドを使用します:

- **`query`** - 取得する項目を決定する条件を設定します。`query`パラメータには、`<field> <operator> <value>`の形式の1つ以上の式を含めることができます。複数の式は`and`で結合されます。例: `group = "gitlab-org" and author = currentUser()`。
- **`fields`** - ビューに表示する列と詳細を指定します。フィールドまたは[フィールド関数](functions.md#functions-in-embedded-views)のコンマ区切りリストです。例: `fields: title, state, health, epic, milestone, weight, updated`。
- **`sort`** - 特定の条件で項目を並べ替えます。ソート順（`asc`または`desc`）が続くフィールド名です。例: `sort: updated desc`。

## データソース {#data-sources}

サポートされているデータソースとそのフィールドのリストについては、[GLQLデータソース](data_sources/_index.md)を参照してください。

## トラブルシューティング {#troubleshooting}

### クエリタイムアウトエラー {#query-timeout-errors}

次のエラーメッセージが表示されることがあります:

```plaintext
Embedded view timed out. Add more filters to reduce the number of results.
```

```plaintext
Query temporarily blocked due to repeated timeouts. Please try again later or try narrowing your search scope.
```

これらのエラーは、クエリの実行に時間がかかりすぎた場合に発生します。大量の結果セットや広範囲な検索は、タイムアウトの原因となることがあります。

この問題を解決するには、検索スコープを制限するフィルターを追加します:

- `created`、`updated`、または`closed`のような日付フィールドを使用して、結果を特定の期間に制限する時間範囲フィルターを追加します。例: 

  ````yaml
  ```glql
  display: table
  fields: title, labels, created
  query: type = Issue and group = "gitlab-org" and label = "group::knowledge" and created > "2025-01-01" and created < "2025-03-01"
  ```
  ````

- 最新の更新でフィルタリングして、アクティブな項目に焦点を当てます:

  ````yaml
  ```glql
  display: table
  fields: title, labels, updated
  query: type = Issue and group = "gitlab-org" and label = "group::knowledge" and updated > -3m
  ```
  ````

- 可能な場合は、グループ全体の検索ではなく、プロジェクト固有のクエリを使用します:

  ````yaml
  ```glql
  display: table
  fields: title, state, assignee
  query: type = Issue and project = "gitlab-org/gitlab" and state = opened and updated > -1m
  ```
  ````

### エラー: `Invalid username reference` {#error-invalid-username-reference}

GLQLクエリで、数字で始まるユーザー名に`@`記号を使用すると、`Invalid username reference`というエラーが表示される場合があります。例: 

```plaintext
An error occurred when trying to display this embedded view:
* Error: Invalid username reference @123username
```

この問題は、GLQL組み込みビューレンダラーが、数字で始まるユーザー名に対する`@`メンションをサポートしていないために発生します。ただし、これらはGitLabでは有効です。

回避策としては、`@`記号を削除し、ユーザー名を引用符で囲みます。例: `assignee = @123username`の代わりに`assignee = "123username"`を使用します。

詳細については、[イシュー583119](https://gitlab.com/gitlab-org/gitlab/-/issues/583119)を参照してください。
