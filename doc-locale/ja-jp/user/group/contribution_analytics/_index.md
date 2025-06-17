---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コントリビュート分析
---

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コントリビュート分析は、グループのメンバーが過去1週間、1か月間、または3か月間に行った[コントリビュートイベント](../../profile/contributions_calendar.md#user-contribution-events)の概要を提供します。インタラクティブな棒チャートと詳細なテーブルに、グループメンバー別のコントリビュートイベント（プッシュイベント、イシュー、マージリクエスト）が表示されます。

![コントリビュート分析の棒グラフ](img/contribution_analytics_push_v17_7.png)

コントリビュート分析を使用して、チームのアクティビティと個人のパフォーマンスに関するインサイトを取得し、この情報を以下に役立てます。

- ワークロードの分散: グループの一定期間のコントリビュートを分析し、パフォーマンスの高いグループメンバーや、個別にサポートすることで効果が得られる可能性があるグループメンバーを特定します。
- チームのコラボレーション: コードプッシュとレビューまたは承認の比率など、コントリビュートのバランスを評価して、協力的な開発プラクティスを実現します。
- トレーニングの機会: マージリクエストの承認率やイシュー解決率が低いなど、チームメンバーがメンターシップやトレーニングからメリットを得られる可能性のある分野を特定します。
- レトロスペクティブ評価: コントリビュート分析をレトロスペクティブに組み込んで、チームが目標をどの程度効果的に達成したかや、どのような調整が必要かを評価します。

### 追跡

コントリビュート分析は、プッシュイベントに基づいており、一意のコミットよりも信頼性の高いコントリビュートのビューを提供します。一意のコミットを数えると、コミットが複数のブランチにプッシュされた場合に重複が発生する可能性があります。プッシュイベントを追跡することで、GitLabはすべてのコントリビュートを正確に数えます。

たとえば、あるユーザーが1回のプッシュで3つのコミットをブランチAにプッシュするとします。その後、ユーザーはそれらのコミットのうち2つをブランチAからブランチBにプッシュします。GitLabは5つのコミットを記録しますが、ユーザーが行った一意のコミットは3つです。

## コントリビュート分析を表示する

コントリビュート分析を表示するには:

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **分析 > コントリビュート分析**を選択します。
1. オプション。結果をフィルタリングします。

   - 先週、先月、または3か月のコントリビュート分析を表示するには、3つのタブのいずれかを選択します。選択した期間は、すべてのチャートとテーブルに適用されます。
   - 棒チャートを拡大してグループメンバーのサブセットのみを表示するには、チャートの下にあるスライダー（{{< icon name="status-paused" >}}）を選択し、軸に沿ってスライドさせます。
   - コントリビュートテーブルを列でソートするには、列ヘッダーまたは山形記号（降順の場合は{{< icon name="chevron-lg-down" >}}、昇順の場合は{{< icon name="chevron-lg-up" >}}）を選択します。

1. オプション。グループメンバーのコントリビュートを表示するには、次のいずれかを実行します。

   - **コントリビュート分析**棒チャートで、メンバーの名前が記載された棒の上にカーソルをおきます。
   - **グループメンバーごとのコントリビュート**テーブルで、メンバーの名前を選択します。メンバーのGitLabプロファイルが表示され、[コントリビュートカレンダー](../../../user/profile/contributions_calendar.md)を調べることができます。

ユーザーのコントリビュートに関するメトリクスを取得するために、[GraphQL API](../../../api/graphql/reference/_index.md#groupcontributions)を使用することもできます。

## ClickHouseによるコントリビュート分析

GitLab.comでは、コントリビュート分析はClickHouse Cloudのクラスターを介して実行されます。GitLab Self-Managedでは、ClickHouseインテグレーションを設定するときに、PostgreSQL `events`テーブルからClickHouse `events`テーブルにデータが自動的に入力されます。大規模なインストールでは、このプロセスに時間がかかる場合があります。テーブルが完全に同期されると、新しいイベントは約3分の遅延でClickHouseで確認できるようになります。

詳細については、以下を参照してください。

- [ClickHouseインテグレーションガイドライン](../../../integration/clickhouse.md)
- [GitLabでのClickHouseの使用状況](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/clickhouse_usage/)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
