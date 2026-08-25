---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL表示タイプ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab](https://gitlab.com/groups/gitlab-org/-/work_items/14767) 17.4で、`glql_integration`という機能フラグとともに[導入](../../administration/feature_flags/_index.md)されました。デフォルトでは無効になっています。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

表示タイプは、[埋め込みビュー](_index.md#embedded-views)がGLQLクエリの結果をどのようにレンダリングするかを制御します。ビューのソースで`display`パラメータを使用して、表示タイプを設定します。

`display`パラメータを設定しない場合、結果はリストとしてレンダリングされます。

一部の表示タイプは任意のクエリで動作します。その他は、データをディメンションとメトリクスに集約する[アナリティクスモード](_index.md#analytics-mode)でのみ動作します。

次の表示タイプはすべてのモードで利用できます:

| 表示タイプ                  | `display`の値 | 説明 |
| ----------------------------- | --------------- | ----------- |
| テーブル               | `table`         | 結果ごとに1行、フィールドごとに1列のテーブル。 |
| リスト                 | `list`          | 結果の順序なしリスト。 |
| 順序付きリスト | `orderedList`   | 結果の番号付きリスト。 |

次の表示タイプはアナリティクスモードでのみ利用できます:

| 表示タイプ                  | `display`の値 | 説明 |
| ----------------------------- | --------------- | ----------- |
| シングル統計 | `stat`          | 集約された単一のメトリクスが大きな値として表示されます。 |
| 縦棒チャート | `columnChart`   | 定義されたディメンションによってカテゴリー間でメトリクスを比較するチャート。 |
| 棒チャート | `barChart` | ディメンションで定義されたカテゴリ全体のメトリクスを比較する水平チャートです。 |
| 折れ線チャート     | `lineChart`     | 1つ以上のメトリクスをディメンションにわたる線としてプロットし、トレンドを示すチャート。 |
| エリアチャート     | `areaChart`     | トレンドとボリュームを示すために、1つ以上のメトリクスを塗りつぶされたエリアとしてディメンション上にチャートとしてプロットするチャートです。 |

## テーブル {#table}

テーブルは、結果ごとに1行、[フィールド](fields.md)ごとに1列をレンダリングします。

テーブルを列で並べ替えるには、列のヘッダーを選択します。このビューは、ビューに読み込まれた行を並べ替えます。結果セット全体ではありません。

### 例 {#example}

`gitlab-org/gitlab`プロジェクトで現在のユーザーに割り当てられた最初の5つのオープンイシューをテーブルとして、`title`、`state`、`health`、`epic`、`milestone`、`weight`、および`updated`列とともに表示するには:

````yaml
```glql
display: table
title: My open issues
fields: title, state, health, epic, milestone, weight, updated
limit: 5
query: type = Issue AND project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

## リスト {#list}

リストは結果を順序なしリストとしてレンダリングします。リストはデフォルトの表示タイプです。

### 例 {#example-1}

`gitlab-org/gitlab`プロジェクトで現在のユーザーに割り当てられた最初の5つのオープンイシューをリストとして、期限日で最も早いものから順に並べ替え、`title`、`health`、および`due`フィールドを表示するには:

````yaml
```glql
display: list
fields: title, health, due
limit: 5
sort: due asc
query: type = Issue AND project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

## 順序付きリスト {#ordered-list}

順序付きリストは結果を番号付きリストとしてレンダリングします。結果の順序が意味のある場合（例えばランキングなど）は、順序付きリストを使用します。

### 例 {#example-2}

`gitlab-org/gitlab`プロジェクトで現在のユーザーに割り当てられた最初の5つのオープンイシューを順序付きリストとして、期限日で最も早いものから順に並べ替え、`title`、`health`、および`due`フィールドを表示するには:

````yaml
```glql
display: orderedList
fields: title, health, due
limit: 5
sort: due asc
query: type = Issue AND project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

## シングル統計 {#single-stat}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241395)されました。

{{< /history >}}

シングル統計は、[アナリティクスモード](_index.md#analytics-mode)からの集約された1つのメトリクスを大きな値として可視化します。合計や割合など、重要な数値を強調するにはシングル統計を使用します。

シングル統計には以下が必要です:

- アナリティクスモード。`mode: analytics`で設定します。
- 1つのメトリクスのみ。`metrics`パラメータで設定します。
- `dimensions`なし。

値はメトリクスに基づいて自動的にフォーマットされます。例えば、カウントは千の区切りを使用し、割合はパーセンテージとして表示されます。

### 例 {#example-3}

過去30日間のコード提案の総数をシングル統計として表示するには:

````yaml
```glql
display: stat
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
metrics: totalCount
```
````

## 縦棒チャート {#column-chart}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21212)されました。

{{< /history >}}

縦棒チャートは、[アナリティクスモード](_index.md#analytics-mode)からの集約されたデータを可視化します。ディメンションで定義されたカテゴリー間でメトリクスを比較するには、縦棒チャートを使用します。

縦棒チャートには以下が必要です:

- アナリティクスモード。`mode: analytics`で設定します。
- 結果をグループ化するための1つまたは2つの`dimensions`。
- プロットするメトリクスが少なくとも1つ（`metrics`パラメータを使用）。

ディメンションとメトリクスの数がチャートのレンダリング方法を決定します:

- 1つ以上のメトリクスを持つ1つのディメンションは、各メトリクスの列をプロットします。これらの列をスタックするには、`displayConfig`の下に`stacked: true`を設定します。単一のメトリクスの場合、`stacked`は表示に影響しません。
- 1つのメトリクスを持つ2つのディメンションは、2番目のディメンションでグループ化された積み重ね縦棒チャートをプロットします。2つのディメンションがある場合、使用できるメトリクスは1つのみで、GitLabは`displayConfig.stacked`を無視します。

### 例 {#example-4}

過去30日間のコード提案の使用状況を言語別に縦棒チャートとして表示するには:

````yaml
```glql
display: columnChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount
```
````

メトリクスを並べてプロットする代わりに、単一の列にスタックするには:

````yaml
```glql
display: columnChart
displayConfig:
  stacked: true
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: acceptedCount, rejectedCount
```
````

## 棒チャート {#bar-chart}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21212)されました。

{{< /history >}}

棒チャートは、[アナリティクスモード](_index.md#analytics-mode)からの集計データを水平棒として可視化します。棒チャートは、特にカテゴリラベルが長い場合に、ディメンションで定義されたカテゴリ全体のメトリクスを比較するのに使用します。

棒チャートには以下が必要です:

- アナリティクスモード。`mode: analytics`で設定します。
- 結果をグループ化するための1つまたは2つの`dimensions`。
- プロットするメトリクスが少なくとも1つ（`metrics`パラメータを使用）。

ディメンションとメトリクスの数がチャートのレンダリング方法を決定します:

- 1つ以上のメトリクスを持つ1つのディメンションは、メトリクスごとに棒をプロットします。これらの棒をスタックするには、`displayConfig`の下で`stacked: true`を設定します。単一のメトリクスの場合、`stacked`は表示に影響しません。
- 1つのメトリクスを持つ2つのディメンションは、2番目のディメンションでグループ化されたスタックされた棒チャートをプロットします。2つのディメンションがある場合、使用できるメトリクスは1つのみで、GitLabは`displayConfig.stacked`を無視します。

### 例 {#example-5}

過去30日間の言語ごとのコード提案の使用状況を棒チャートとして表示するには:

````yaml
```glql
display: barChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount
```
````

メトリクスを並べてプロットするのではなく、単一の棒にスタックするには:

````yaml
```glql
display: barChart
displayConfig:
  stacked: true
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: acceptedCount, rejectedCount
```
````

## 折れ線チャート {#line-chart}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240016)されました。

{{< /history >}}

折れ線チャートは、[アナリティクスモード](_index.md#analytics-mode)からの集約されたデータを1つ以上の線として可視化します。時間経過など、ディメンションにわたるメトリクスの変化を示すには、折れ線チャートを使用します。

折れ線チャートには以下が必要です:

- アナリティクスモード。`mode: analytics`で設定します。
- X軸に正確に1つの`dimension`。
- プロットする`metric`が少なくとも1つ。各メトリクスは個別の線としてレンダリングされます。

### 例 {#example-6}

過去30日間のコード提案の使用状況を言語別に折れ線チャートとして、総提案数に1本、承認された提案数に1本の線を表示するには:

````yaml
```glql
display: lineChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount, acceptedCount
```
````

## エリアチャート {#area-chart}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/glql/-/work_items/103)されました。

{{< /history >}}

エリアチャートは、[アナリティクスモード](_index.md#analytics-mode)からの集計データを1つ以上の塗りつぶされたエリアとして可視化します。エリアチャートは、時間などディメンション全体のメトリクスがどのように変化するかを示し、トレンドの背後にあるボリュームを強調するのに使用します。

エリアチャートには以下が必要です:

- アナリティクスモード。`mode: analytics`で設定します。
- 結果をグループ化するための1つまたは2つの`dimensions`。
- プロットするメトリクスが少なくとも1つ（`metrics`パラメータを使用）。

ディメンションとメトリクスの数がチャートのレンダリング方法を決定します:

- 1つ以上のメトリクスを持つ1つのディメンションは、メトリクスごとにエリアをプロットします。エリアは半透明の塗りつぶしでオーバーラップします。代わりにエリアを累計的にスタックするには、`displayConfig`の下で`stacked: true`を設定します。単一のメトリクスの場合、`stacked`は表示に影響しません。
- 1つのメトリクスを持つ2つのディメンションは、2番目のディメンションでグループ化されたスタックされたエリアチャートをプロットします。2つのディメンションがある場合、使用できるメトリクスは1つのみで、GitLabは`displayConfig.stacked`を無視します。

### 例 {#example-7}

過去30日間に表示および承諾されたコード提案をオーバーラップするエリアとして表示するには:

````yaml
```glql
display: areaChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: timestamp
metrics: shownCount, acceptedCount
```
````

代わりにメトリクスを累計的にスタックするには:

````yaml
```glql
display: areaChart
displayConfig:
  stacked: true
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: timestamp
metrics: shownCount, acceptedCount
```
````

## ページネーションのサポート {#pagination-support}

すべてのモードで利用可能な表示タイプは、結果の最初のページを表示し、追加のページをフェッチするための**更に表示**アクションを提供します。詳細については、[ページネーション](_index.md#pagination)を参照してください。

アナリティクスモードの可視化はページネーションをサポートしていません。それらはすべての集約された結果を一度にレンダリングします。
