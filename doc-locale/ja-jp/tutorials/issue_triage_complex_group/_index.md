---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: イシュートリアージ用のサブグループを含む複合グループをセットアップする'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

イシュートリアージとは、タイプと重大度に応じて分類するプロセスです。プロジェクトが拡大し、イシューの作成数が増えるにつれて、受信するイシューをどのようにトリアージするかについてワークフローを作成する価値があります。

このチュートリアルでは、このシナリオのために、サブグループを持つGitLabグループをセットアップする方法を学びます。

イシュートリアージのために、サブグループを持つ複雑なグループのためにGitLabをセットアップするには、次の手順に従います:

1. [グループを作成する](#create-a-group)
1. [グループ内にサブグループを作成する](#create-subgroups-inside-a-group)
1. [サブグループ内にプロジェクトを作成する](#create-projects-inside-subgroups)
1. [タイプ、重大度、および優先順位の基準を決定する](#decide-on-the-criteria-for-types-severity-and-priority)
1. [基準をドキュメント化する](#document-your-criteria)
1. [スコープ付きラベルを作成する](#create-scoped-labels)
1. [新しいラベルを優先する](#prioritize-the-new-labels)
1. [親グループのイシュートリアージボードを作成する](#create-a-parent-group-issue-triage-board)
1. [機能のイシューを作成する](#create-issues-for-features)

## はじめる前 {#before-you-begin}

- このチュートリアルで既存のプロジェクトを使用している場合は、少なくともプロジェクトのレポーターロールが必要です。
  - 既存のプロジェクトに親グループがない場合は、グループを作成し、[プロジェクトのラベルをグループのラベルにプロモート](../../user/project/labels.md#promote-a-project-label-to-a-group-label)します。

## グループを作成する {#create-a-group}

[グループ](../../user/group/_index.md)は、本質的に、複数のプロジェクトのコンテナです。これにより、ユーザーは複数のプロジェクトを管理し、グループメンバーと一度に通信できます。

新しいグループを作成します:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループを作成**を選択します。
1. グループの詳細を入力します:
   - **グループ名**には、`Web App Dev`または別の値を入力します。
1. ページの下部にある**グループを作成**を選択します。

## サブグループ内にサブグループを作成する {#create-subgroups-inside-a-group}

[サブグループ](../../user/group/subgroups/_index.md)とは、グループ内のグループのことです。サブグループは、大規模なプロジェクトを編成し、権限を管理するのに役立ちます。

新しいサブグループを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、**Web App Dev**（Web App Dev）グループを見つけます。
1. **新規作成**（{{< icon name="plus" >}}）と**新しいサブグループ**を選択します。
1. サブグループの詳細を入力します:
   - **サブグループ名**には、`Frontend`または別の値を入力します。
1. **サブグループを作成**を選択します。
1. このプロセスを繰り返して、`Backend`という名前の2番目のサブグループを作成するか、別の値を入力します。

## サブグループ内にプロジェクトを作成する {#create-projects-inside-subgroups}

複数のプロジェクトにわたってイシューの追跡を管理するには、サブグループにプロジェクトを作成する必要があります。

新しいプロジェクトを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Frontend`サブグループを見つけます。
1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します:
   - **プロジェクト名**に、`Web UI`と入力します。詳細については、プロジェクトの[命名規則](../../user/reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)を参照してください。
1. ページの下部にある**プロジェクトを作成**を選択します。
1. このプロセスを繰り返して、`Frontend`サブグループに`Accessibility Audit`という名前の2番目のプロジェクトを作成し、`Backend`サブグループに`API`という名前の3番目のプロジェクトを作成します。

## タイプ、重大度、および優先順位の基準を決定する {#decide-on-the-criteria-for-types-severity-and-priority}

次に、以下を決定する必要があります:

- 認識する**Types**（タイプ）のイシュー。より詳細なアプローチが必要な場合は、タイプごとにサブタイプを作成することもできます。タイプは、チームにリクエストされる作業の種類を理解するために、作業を分類するのに役立ちます。
- 受信する作業がエンドユーザーに与える影響を定義し、優先順位付けを支援するための**priorities**（優先順位）と**severities**（重大度）のレベル。

このチュートリアルでは、次のことを決定したと仮定します:

- タイプ：`Bug`、`Feature`、および`Maintenance`
- 優先度：`1`、`2`、`3`、および`4`
- 重大度：`1`、`2`、`3`、および`4`

インスピレーションを得るには、GitLabでこれらをどのように定義するかをご覧ください:

- [タイプとサブタイプ](https://handbook.gitlab.com/handbook/engineering/metrics/#work-type-classification)
- [優先度](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#priority)
- [重大度](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity)

## 基準をドキュメント化する {#document-your-criteria}

すべての基準に同意したら、チームメイトがいつでもアクセスできる場所にすべて書き留めます。

たとえば、プロジェクトの[Wiki](../../user/project/wiki/_index.md)に追加したり、[GitLab Pages](../../user/project/pages/_index.md)で公開されている会社のハンドブックに追加したりします。

<!-- Idea for expanding this tutorial:
     Add steps for [creating a wiki page](../../user/project/wiki/_index.md#create-a-new-wiki-page). -->

## スコープ付きラベルを作成する {#create-scoped-labels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

次に、イシューに追加して分類するためのラベルを作成します。

これに最適なツールは[スコープ付きラベル](../../user/project/labels.md#scoped-labels)であり、これを使用して相互に排他的な属性を設定できます。

[以前に](#decide-on-the-criteria-for-types-severity-and-priority)組み立てたタイプ、重大度、および優先順位のリストを確認して、一致するスコープ付きラベルを作成します。

スコープ付きラベルの名前のダブルコロン（`::`）は、同じスコープの2つのラベルが一緒に使用されるのを防ぎます。たとえば、`type::feature`ラベルを、すでに`type::bug`が付いているイシューに追加すると、前のラベルが削除されます。

{{< alert type="note" >}}

スコープ付きラベルは、PremiumおよびUltimateプランで利用できます。Freeプランをご利用の場合は、代わりに通常のラベルを使用できます。ただし、それらは相互に排他的ではありません。

{{< /alert >}}

すべてのサブグループのすべてのプロジェクトでラベルを使用できるようにするには、まず、サブグループを含む親グループに移動します。ラベルを特定のサブグループのプロジェクトでのみ使用できるようにする場合は、サブグループ内から次の手順を実行します。

各ラベルを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、**Web App Dev**（Web App Dev）グループを見つけます。
1. **管理** > **ラベル**を選択します。
1. **新しいラベル**を選択します。
1. **タイトル**フィールドに、ラベルの名前を入力します。`type::bug`で始まる。
1. オプション。使用可能な色から選択するか、**背景色**フィールドに特定の色を表す16進数のカラー値を入力して、色を選択します。
1. **ラベルを作成**を作成を選択します。

手順3〜6を繰り返して、必要なすべてのラベルを作成します。次に例を示します:

- `type::bug`
- `type::feature`
- `type::maintenance`
- `priority::1`
- `priority::2`
- `priority::3`
- `priority::4`
- `severity::1`
- `severity::2`
- `severity::3`
- `severity::4`

## 新しいラベルを優先する {#prioritize-the-new-labels}

次に、新しいラベルを優先ラベルとして設定します。これにより、優先度またはラベルの優先度で並べ替えた場合、最も重要なイシューがイシューリストの最上部に表示されるようになります。

優先度またはラベル優先度でソートするとどうなるかについては、[イシューリストのソートと順序付け](../../user/project/issues/sorting_issue_lists.md)を参照してください。

ラベルを優先するには、次の手順に従います:

1. ラベルページで、優先するラベルの横にある**優先順位を付ける**（{{< icon name="star-o" >}}）を選択します。このラベルは、**優先ラベル**の下の、ラベルリストの最上部に表示されます。
1. これらのラベルの相対的な優先度を変更するには、リストを上下にドラッグします。リストの上位にあるラベルは、より高い優先度を取得します。
1. 以前に作成したすべてのラベルを優先します。優先度と重大度の高いラベルが、値の低いラベルよりもリストの上位にあることを確認してください。

![11個の優先ラベルのリスト](img/priority_labels_v16_3.png)

## 親グループイシュートリアージボードを作成する {#create-a-parent-group-issue-triage-board}

受信するイシューのバックログに備えて、ラベルでイシューを整理する[イシューボード](../../user/project/issue_board.md)を作成します。これを使用して、カードをさまざまなリストにドラッグすることで、イシューをすばやく作成し、ラベルを追加できます。

イシューボードを設定するには、次の手順に従います:

1. ボードのスコープを決定します。たとえば、イシューに重大度を割り当てるには、[グループイシューボード](../../user/project/issue_board.md#group-issue-boards)を作成します。
1. 左側のサイドバーで、**検索または移動先**を選択して、**Web App Dev**（Web App Dev）グループを見つけます。
1. **Plan** > **イシューボード**を選択します。
1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成する**を選択します。
1. **タイトル**フィールドに、`Issue triage (by severity)`と入力します。
1. **オープンリストを表示する**チェックボックスをオンのままにし、**クローズドリストを表示する**チェックボックスをオフにします。
1. **ボードを作成する**を選択します。空のボードが表示されます。
1. `severity::1`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**（リストを作成）を選択します。
   1. 表示される列の**値**ドロップダウンリストから、`severity::1`ラベルを選択します。
   1. リストの下部にある**ボードに追加**を選択します。
1. ラベル`severity::2`、`severity::3`、および`severity::4`について、前の手順を繰り返します。

サブグループのイシューボードを作成するには、サブグループ内から手順3〜10に従います。

今のところ、ボード内のリストは空である必要があります。次に、いくつかのイシューを入力された状態にします。

## 機能のイシューを作成する {#create-issues-for-features}

今後の機能とバグを追跡するには、いくつかのイシューを作成する必要があります。イシューはプロジェクトに属していますが、グループイシューボードから直接作成することもできます。

まず、計画された機能のイシューをいくつか作成します。バグを見つけたら、イシューを作成できます（あまり多くないことを願っています！）。

**Issue triage (by severity)**（重大度別のイシュートリアージ）ボードからイシューを作成するには、次の手順に従います:

1. **オープン**リストに移動します。このリストには、他のボードリストに適合しないイシューが表示されます。どの重大度ラベルがイシューに付いているか既にわかっている場合は、そのラベルのリストから直接作成できます。ラベルリストから作成された各イシューには、そのラベルが付けられていることに注意してください。

   今のところ、**オープン**リストの使用を続行します。
1. **オープン**リストで、**イシューの新規作成**アイコン（{{< icon name="plus" >}}）を選択します。
1. フィールドに入力します:
   - **タイトル**の下に、`Dark mode toggle`と入力します。
   - このイシューが適用されるプロジェクトを選択します。`Frontend / Web UI`を選択します。
1. **イシューの作成**を選択します。
1. これらの手順を繰り返して、さらにいくつかのイシューを作成します。

   たとえば、Web APIアプリをビルドしている場合、`Frontend`と`Backend`は異なるエンジニアリングチームを指します。プロジェクトは、スタック開発のさまざまな側面を指します。必要に応じてプロジェクトに割り当てて、次のイシューを作成します:

   - `User registration`
   - `Profile creation`
   - `Search functionality`
   - `Add to favorites`
   - `Push notifications`
   - `Social sharing`
   - `In-app messaging`
   - `Track progress`
   - `Feedback and ratings`
   - `Settings and preferences`

{{< alert type="note" >}}

あるプロジェクトのイシューボードのイシューは、他のプロジェクトのイシューボードからは見えません。同様に、あるサブグループのプロジェクトのイシューは、そのサブグループのイシューボードでのみ表示できます。親グループ内のすべてのプロジェクトのすべてのイシューを表示するには、親グループのイシューボードにいる必要があります。

{{< /alert >}}

最初のトリアージイシューボードができました！**オープン**リストからラベルリストのいずれかにいくつかのイシューをドラッグして、重大度ラベルのいずれかを追加してみてください。

![ラベルのないイシューと、イシューのラベル付けのために優先された「重大度」ラベルを使用したイシューボード](img/triage_board_v16_3.png)

## 次の手順 {#next-steps}

その後、次のことができるようになります:

- イシューボードの使用方法を微調整します。次のようなオプションがあります:
  - 現在のイシューボードを編集して、優先度と種類のラベルのリストも表示できるようにします。これにより、ボードが広くなり、水平スクロールが必要になる場合があります。
  - `Issue triage (by priority)`と`Issue triage (by type)`という名前の個別のイシューボードを作成します。これにより、さまざまなタイプのトリアージ作業を分離できますが、ボードを切り替える必要があります。
  - [チーム](../boards_for_teams/_index.md)間のチームハンドオフ用のイシューボードをセットアップします。
- イシューリストの優先度または重大度で、[各ラベルでフィルタリング](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)してイシューを参照します。利用可能な場合は、[「is one of」フィルター演算子](../../user/project/issues/managing_issues.md#filter-with-the-or-operator)を使用します。
- イシューを[タスク](../../user/tasks.md)に分割します。
- [`gitlab-triage` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage)を使用して、プロジェクト内のイシュートリアージを自動化するのに役立つポリシーを作成します。次のようなヒートマップを使用して、サマリーレポートを生成します:

  ![「優先度」と「重大度」のラベルが付いたイシューの対角ヒートマップ](img/triage_report_v16_3.png)

GitLabでのイシュートリアージの詳細については、[Issue Triage](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/)および[Triage Operations](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/)を参照してください。
