---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Duoワークフロー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.5で[実験](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/606576)。
- `model`ディメンションがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/511)されました。
- `status`フィルターおよびディメンション、ならびに`flowTypesCount`、`returningUsersCount`、`joinedUsersCount`、`churnedUsersCount`、`previousPeriodUsersCount`、`createdMrCount`、`mergedMrCount`、および`closedMrCount`メトリクスがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/514)されました。
- `userTier`ディメンション、ならびに`flowTypesUsed`および`activeDays`フィルターがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/516)されました。
- `totalCount`における`status`パラメータがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/527)されました。
- `group`ディメンションがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/530)されました。
- `openMrCount`メトリクスがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/534)されました。
- `creditsPerMergedMrRatio`メトリックがGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/533)されました。
- `flowType`、`status`、および`user`フィルターにおける`!=`および`not in`演算子がGitLab 19.5で[導入](https://gitlab.com/gitlab-org/glql/-/merge_requests/537)されました。
- `model`ディメンションがモデルカタログ名を表示するようにGitLab 19.5で[変更](https://gitlab.com/gitlab-org/glql/-/merge_requests/539)されました。

{{< /history >}}

> [!flag]
> このデータソースは、GitLab Duo Agent Platformフロー分析エンジンから読み取ります。これは`dap_impact_v1`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)によって制御されます。このフラグはデフォルトで無効になっています。管理者は、ユーザーまたはトップレベルグループに対してこれを有効にできます。
>
> - ユーザーに対して有効にすると、そのグループにフラグがあるかどうかにかかわらず、ユーザーが選択し読み取ることができるすべてのグループまたはプロジェクトのデータをクエリが返します。
> - トップレベルグループに対して有効にすると、選択したすべてのグループおよびプロジェクトが有効なトップレベルグループ内にある場合にクエリがデータを返します。
>
> 選択したグループまたはプロジェクトのいずれかが有効なトップレベルグループの外にあり、かつフラグがユーザーに対して有効になっていない場合、クエリはエラーを返します。

このデータソースは、プロジェクトまたはグループ全体で実行されたGitLab Duo Agent Platformフロー（Duoワークフローとも呼ばれます）に関する集計されたメトリクス（使用したクレジット数を含む）を提供します。

## 許可されるモード {#allowed-modes}

- [`analytics`](../_index.md#analytics-mode)

## 許可されるスコープ {#allowed-scopes}

| スコープ     | 説明 |
|-----------|-------------|
| `project` | 特定のプロジェクトでGitLab Duo Agent Platformフローをクエリします。 |
| `group`   | サブグループを含む、グループ内のすべてのプロジェクトでGitLab Duo Agent Platformフローをクエリします。 |

複数のグループまたはプロジェクトにわたってGitLab Duoワークフローを集計するには、`in`演算子を使用したリストを使用します。詳細については、[複数のグループとプロジェクト](_index.md#multiple-groups-and-projects)を参照してください。

## クエリフィルター {#query-filters}

結果をフィルタリングするには、`query`パラメータでこれらのフィールドを使用します。

| フィールド                               | 名前（エイリアス）                              | 演算子                 |
| ----------------------------------- | --------------------------------------------- | ------------------------- |
| [アクティブな日数](#active-days)         | `activeDays`                                  | `=`、`>`、`<`、`>=`、`<=` |
| [作成日](#created)                 | `created`（`opened`、`openedAt`、`createdAt`） | `=`、`>`、`<`、`>=`、`<=` |
| [フロータイプ](#flow-type)             | `flowType`                                    | `=`、`!=`、`in`、`not in` |
| [使用されたフロータイプ](#flow-types-used) | `flowTypesUsed`                               | `=`、`>`、`<`、`>=`、`<=` |
| [ステータス](#status)                   | `status`                                      | `=`、`!=`、`in`、`not in` |
| [ユーザー](#user)                       | `user`                                        | `=`、`!=`、`in`、`not in` |

### アクティブな日数 {#active-days}

**説明**: ユーザーが選択した期間内にフローを作成した個別の日数でフローをフィルタリングします。`activeDays = 1`は、ちょうど1日だけアクティブだったユーザーに一致します。

**許可される値の型**: `Number`

**ノート**:

- このカウントは、ユーザーごとの選択された期間全体を対象とします。
- 範囲を指定するために2つの範囲演算子を組み合わせることができます。例: `activeDays >= 2 and activeDays <= 5`。ただし、同じフィールドに対して`=`を別の比較と組み合わせることはできません。

### 作成日 {#created}

**説明**: フローを作成日でフィルタリングします。複数の`created`条件を使用して、指定した期間を定義します。

**指定可能な値の型**:

- `AbsoluteDate`（形式は`YYYY-MM-DD`）
- `RelativeDate`（形式は`<sign><digit><unit>`で、signは`+`、`-`、または省略、digitは整数、`unit`は`d`（日）、`w`（週）、`m`（月）、または`y`（年）のいずれか）

**ノート**:

- `=`演算子の場合、GLQLはユーザーのタイムゾーンでの00:00から23:59までの時間範囲を考慮します。

### フロータイプ {#flow-type}

**説明**: フローをそのタイプでフィルタリングします。例: `software_development`、`code_review/v1`。

**指定可能な値の型**:

- `String`
- `List`（複数の値には`in`または`not in`演算子を使用）

### 使用されたフロータイプ {#flow-types-used}

**説明**: ユーザーが選択した期間内に実行した個別のフロータイプの数でフローをフィルタリングします。`flowTypesUsed >= 2`は、2つ以上のフロータイプを使用したユーザーに一致します。

**許可される値の型**: `Number`

**ノート**:

- このカウントは、ユーザーごとの選択された期間全体を対象とします。
- 同じ組み合わせルールが適用されます: 範囲を指定するために2つの範囲演算子を使用しますが、同じフィールドに対して`=`を別の比較と組み合わせることはできません。

### ステータス {#status}

**説明**: フローをそのライフサイクルステータスでフィルタリングします。

**指定可能な値の型**:

- `Enum`、`created`、`running`、`paused`、`finished`、`failed`、`stopped`、`input_required`、`plan_approval_required`、または`tool_call_approval_required`のいずれか1つ
- `List`（複数の値には`in`または`not in`演算子を使用）

**ノート**:

- 3つの`*_required`ステータスは、ユーザーの対応待ちのフローであり、`paused`とは異なります。
- ステータスは大文字と小文字を区別せずに照合されます。`completed`や`aborted`などの他のつづりは受け付けられません。

### ユーザー {#user}

**説明**: フローを実行したユーザーでフィルタリングします。

**指定可能な値の型**:

- `Number`（ユーザーID）
- `List`（複数のユーザーIDには`in`または`not in`演算子を使用）

> [!note]
> ユーザー名によるフィルタリングのサポートは[イシュー599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750)で追跡されています。

## ディメンション {#dimensions}

| ディメンション | 名前       | 説明 |
| --------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 作成日   | `created`  | 日付でグループ化します。`daily`、`weekly`、`monthly`、または`30d`（デフォルト: `monthly`）などの日数、およびオプションの`origin`の[`granularity`パラメータ](../_index.md#field-parameters)を受け付けます。例: `created(weekly)`、`created(granularity=30d, origin=2026-07-16)`。 |
| フロータイプ | `flowType` | フロータイプでグループ化します。 |
| グループ     | `group`    | グループでグループ化します。トップレベルグループから数えた`depth`パラメータを受け付け、`1`から`99`まで（デフォルト: `1`）の値を取るため、`group`はトップレベルグループを返し、`group(depth=2)`はそのサブグループを返します。その深さを超えるフロー、またはサブグループではなくその深さのプロジェクト内にあるフロー（たとえば、`depth=2`のときにトップレベルグループの直下にあるプロジェクト）にはグループがなく、結果にはグループなしの行が複数含まれる場合があります。 |
| モデル     | `model`    | フローが使用したモデル（モデルカタログ名を表示）でグループ化します。カタログにないモデルは、その生の識別子を表示します。モデルの帰属がないフローには名前がありません。行はフローが報告したモデル識別子によってグループ化されるため、1つのカタログ名が複数の行またはチャートバーに表示されることがあります。 |
| プロジェクト   | `project`  | プロジェクトでグループ化します。プロジェクトにスコープされていないフローは、プロジェクトなしの単一の行にグループ化されます。 |
| ステータス    | `status`   | フローステータスでグループ化します。行はアルファベット順ではなく、ライフサイクル順にソートされます。 |
| ユーザー      | `user`     | ユーザーでグループ化します（アバター、名前、ユーザー名を表示）。 |
| ユーザー階層 | `userTier` | `created(weekly)`などの別のディメンションも選択されている場合でも、選択した期間全体でユーザーが実行したフローの数によってユーザーをグループ化します。`thresholds`パラメータが必要です: 少なくとも`1`以上の厳密に昇順の整数を1〜9個含むリストで、デフォルトはありません。たとえば、`userTier(thresholds=[4, 25, 100])`は、`tier_0`（4フロー未満）、`tier_1`（4〜24）、`tier_2`（25〜99）、および`tier_3`（100以上）を返します。単一のしきい値は括弧なしで記述できます: `userTier(8)`。 |

## メトリクス {#metrics}

| メトリック                      | 名前                       | 説明 |
|-----------------------------|----------------------------|-------------|
| 離脱ユーザー数         | `churnedUsersCount`        | 前の期間にフローを実行したが、今回の期間には実行していない一意のユーザー数。 |
| クローズされたMR数の最大値         | `closedMrCountMax`         | 単一のフローによって作成された、クローズされたマージリクエストの最大数。 |
| クローズされたMR数の平均値        | `closedMrCountMean`        | フローごとに作成された、クローズされたマージリクエストの平均数。 |
| クローズされたMR数の最小値         | `closedMrCountMin`         | 単一のフローによって作成された、クローズされたマージリクエストの最小数。 |
| クローズされたMR数の分位数    | `closedMrCountQuantile`    | 指定された分位数における、フローごとに作成されたクローズされたマージリクエスト数。`0.01`と`0.99`の間の[`quantile`パラメータ](../_index.md#field-parameters)を受け付けます（デフォルト: `0.5`）。例: `closedMrCountQuantile(0.95)`。 |
| クローズされたMR数の合計         | `closedMrCountSum`         | すべてのフローによって作成された、クローズされたマージリクエストの合計数。 |
| 作成されたMR数の最大値        | `createdMrCountMax`        | 単一のフローによって作成されたマージリクエストの最大数。 |
| 作成されたMR数の平均値       | `createdMrCountMean`       | フローごとに作成されたマージリクエストの平均数。 |
| 作成されたMR数の最小値        | `createdMrCountMin`        | 単一のフローによって作成されたマージリクエストの最小数。 |
| 作成されたMR数の分位数   | `createdMrCountQuantile`   | 指定された分位数における、フローごとに作成されたマージリクエスト数。`0.01`と`0.99`の間の[`quantile`パラメータ](../_index.md#field-parameters)を受け付けます（デフォルト: `0.5`）。例: `createdMrCountQuantile(0.95)`。 |
| 作成されたMR数の合計        | `createdMrCountSum`        | すべてのフローによって作成されたマージリクエストの合計数。 |
| マージされたMRあたりのクレジット比率 | `creditsPerMergedMrRatio`  | フローによって作成され、後にマージされたマージリクエストごとに使用されたクレジット数。マージリクエストを作成しなかったフローも含め、すべてのフローからのクレジットがカウントされます。 |
| 使用クレジット数の最大値            | `creditsUsedMax`           | 単一のフローによって使用されたクレジットの最大数。 |
| 使用クレジット数の平均値           | `creditsUsedMean`          | フローごとに使用されたクレジットの平均数。 |
| 使用クレジット数の最小値            | `creditsUsedMin`           | 単一のフローによって使用されたクレジットの最小数。 |
| 使用クレジット数の分位数       | `creditsUsedQuantile`      | 指定された分位数における、フローごとに使用されたクレジット数。`0.01`と`0.99`の間の[`quantile`パラメータ](../_index.md#field-parameters)を受け付けます（デフォルト: `0.5`）。例: `creditsUsedQuantile(0.95)`。 |
| 使用クレジット数の合計            | `creditsUsedSum`           | すべてのフローによって使用されたクレジットの合計数。 |
| フロータイプ数            | `flowTypesCount`           | 一意のフロータイプの数。 |
| 参加ユーザー数          | `joinedUsersCount`         | 今回の期間にフローを実行したが、前回の期間には実行していない一意のユーザー数。 |
| マージされたMR数の最大値         | `mergedMrCountMax`         | 単一のフローによって作成された、マージされたマージリクエストの最大数。 |
| マージされたMR数の平均値        | `mergedMrCountMean`        | フローごとに作成された、マージされたマージリクエストの平均数。 |
| マージされたMR数の最小値         | `mergedMrCountMin`         | 単一のフローによって作成された、マージされたマージリクエストの最小数。 |
| マージされたMR数の分位数    | `mergedMrCountQuantile`    | 指定された分位数における、フローごとに作成された、マージされたマージリクエスト数。`0.01`と`0.99`の間の[`quantile`パラメータ](../_index.md#field-parameters)を受け付けます（デフォルト: `0.5`）。例: `mergedMrCountQuantile(0.95)`。 |
| マージされたMR数の合計         | `mergedMrCountSum`         | すべてのフローによって作成された、マージされたマージリクエストの合計数。 |
| オープンMR数の最大値           | `openMrCountMax`           | 単一のフローによって作成された、オープンのマージリクエストの最大数。 |
| オープンMR数の平均値          | `openMrCountMean`          | フローごとに作成された、オープンのマージリクエストの平均数。 |
| オープンMR数の最小値           | `openMrCountMin`           | 単一のフローによって作成された、オープンのマージリクエストの最小数。 |
| オープンMR数の分位数      | `openMrCountQuantile`      | 指定された分位数における、フローごとに作成された、オープンのマージリクエスト数。`0.01`と`0.99`の間の[`quantile`パラメータ](../_index.md#field-parameters)を受け付けます（デフォルト: `0.5`）。例: `openMrCountQuantile(0.95)`。 |
| オープンMR数の合計           | `openMrCountSum`           | すべてのフローによって作成された、オープンのマージリクエストの合計数。 |
| 前の期間のユーザー数 | `previousPeriodUsersCount` | 前の期間の一意のユーザー数。 |
| プロジェクト数              | `projectsCount`            | 一意のプロジェクトの数。プロジェクトにスコープされていないフローはカウントされないため、それらのフローの行は`0`を示します。 |
| 再訪ユーザー数       | `returningUsersCount`      | 前の期間にもフローを実行した一意のユーザー数。 |
| 合計数                 | `totalCount`               | オプションでステータスによってフィルタリングされた、フローの総数。1つ以上のフローステータス（`status`フィルターと同じ値）を持つオプションの`status`パラメータを受け付けます。例: `totalCount(status="finished")`または`totalCount(status=["paused", "input_required"])`。パラメータを指定しない場合、または`status=[]`の場合、すべてのフローがカウントされます。 |
| ユーザー数                 | `usersCount`               | 一意のユーザー数。 |

> [!note]
> `creditsPerMergedMrRatio`を含むクレジットメトリクスには、グループまたはプロジェクトのオーナーまたはセキュリティマネージャーロール、あるいは`read_agent_artifacts`権限を持つ[カスタムロール](../../custom_roles/abilities.md)が必要です。他のユーザーの場合、これらのメトリクスは空になります。

**ノート**:

- `returningUsersCount`、`joinedUsersCount`、`churnedUsersCount`、および`previousPeriodUsersCount`メトリクスは、各`created`バケットを直前のものと比較するため、`created`ディメンションも選択されている場合にのみ有効です。`created`フィルターだけでは不十分です。
- `mergedMrCount`、`closedMrCount`、および`openMrCount`メトリクスは、フローが作成し、後にマージされた、マージせずにクローズされた、またはまだオープンであるマージリクエストをカウントします。これらはそれらのマージリクエストの現在の状態に遅れることがあるため、最近マージされたマージリクエストがオープンとしてカウントされ続けることがあります。

## ソートフィールド {#sort-fields}

選択したディメンションまたはメトリクスに含まれる任意のフィールドでソートします。詳細については、[分析モードのソート](../_index.md#sorting)を参照してください。

## 例 {#examples}

- 過去30日間のフロータイプ別のフロー:

  ````yaml
  ```glql
  title: "Duo workflows by flow type (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: flowType as "Flow"
  metrics: totalCount as "Flows", usersCount as "Users", creditsUsedSum as "Credits"
  sort: totalCount desc
  ```
  ````

- 月次クレジット使用量の推移:

  ````yaml
  ```glql
  title: "Monthly Duo workflow credit usage trend"
  display: columnChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d
  dimensions: created(monthly) as "Month"
  metrics: creditsUsedSum as "Credits used"
  sort: created asc
  ```
  ````

- チャットフローを除く月次クレジット使用量:

  ````yaml
  ```glql
  title: "Monthly Duo workflow credits, excluding chat"
  display: columnChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d and flowType not in ("chat", "agentic_chat/v1")
  dimensions: created(monthly) as "Month", flowType as "Flow"
  metrics: creditsUsedSum as "Credits used"
  sort: created asc
  ```
  ````

- 過去30日間のモデル別クレジット:

  ````yaml
  ```glql
  title: "Duo workflow credits by model (last 30 days)"
  display: barChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: model as "Model"
  metrics: creditsUsedSum as "Credits used"
  sort: creditsUsedSum desc
  ```
  ````

- 過去30日間のクレジット別トップユーザー:

  ````yaml
  ```glql
  title: "Top users by Duo workflow credits (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: user as "User"
  metrics: totalCount as "Flows", creditsUsedSum as "Credits", creditsUsedMean as "Avg credits per flow"
  sort: creditsUsedSum desc
  limit: 10
  ```
  ````

- 過去30日間のステータス別フロー:

  ````yaml
  ```glql
  title: "Duo workflows by status (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: status as "Status"
  metrics: totalCount as "Flows", createdMrCountSum as "MRs created", mergedMrCountSum as "MRs merged", openMrCountSum as "MRs open"
  sort: status asc
  ```
  ````

- 週次ユーザー維持率:

  ````yaml
  ```glql
  title: "Weekly Duo workflow user retention"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d
  dimensions: created(weekly) as "Week"
  metrics: usersCount as "Users", returningUsersCount as "Returning", joinedUsersCount as "Joined", churnedUsersCount as "Churned"
  sort: created desc
  ```
  ````

- 過去30日間のアクティビティ階層およびフロータイプ別ユーザー:

  ````yaml
  ```glql
  title: "Duo workflow users by activity tier (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: userTier(thresholds=[4, 25, 100]) as "Tier", flowType as "Flow"
  metrics: totalCount as "Flows", usersCount as "Users"
  sort: userTier asc
  ```
  ````

- 過去30日間のステータス別フロー数の比較:

  ````yaml
  ```glql
  title: "Duo workflows by outcome (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  metrics: totalCount as "All", totalCount(status="finished") as "Completed", totalCount(status=["paused", "input_required"]) as "Waiting", totalCount(status="failed") as "Failed"
  ```
  ````

- 過去30日間のグループ比較:

  ````yaml
  ```glql
  title: "Duo workflow usage by subgroup (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: group(depth=2) as "Group"
  metrics: usersCount as "Users", creditsUsedSum as "Credits"
  sort: usersCount desc
  ```
  ````

- グループ化なしの全体使用状況:

  ````yaml
  ```glql
  title: "Duo workflow usage overview (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  metrics: totalCount as "Flows", usersCount as "Users", projectsCount as "Projects", creditsUsedQuantile(0.5) as "Median credits"
  ```
  ````
