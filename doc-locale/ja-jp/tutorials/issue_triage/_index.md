---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: イシュートリアージ用のプロジェクトをセットアップする'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

イシュートリアージとは、種類と重大度に応じて分類するプロセスです。プロジェクトが拡大し、イシューの作成数が増えるにつれて、受信イシューをどのようにトリアージするかに関するワークフローを作成する価値があります。

このチュートリアルでは、このためのGitLabプロジェクトをセットアップする方法を学びます。

プロジェクトでイシュートリアージを行うためにGitLabをセットアップするには、次の手順に従います:

1. [プロジェクトを作成する](#create-a-project)
1. [種類、重大度、優先順位の条件を決定する](#decide-on-the-criteria-for-types-severity-and-priority)
1. [条件をドキュメント化する](#document-your-criteria)
1. [スコープ付きラベルを作成する](#create-scoped-labels)
1. [新しいラベルの優先順位を設定する](#prioritize-the-new-labels)
1. [イシュートリアージイシューボード](#create-an-issue-triage-board)を作成する
1. [フィーチャーのイシューを作成する](#create-issues-for-features)

## はじめる前 {#before-you-begin}

- このチュートリアルで既存のプロジェクトを使用している場合は、プロジェクトのレポーターロール以上を持っていることを確認してください。
- 以下の手順に従い、後でプロジェクトの親グループを作成する場合、ラベルを最大限に活用するには、プロジェクトのラベルをグループラベルにプロモートする必要があります。最初にグループを作成することを検討してください。

## プロジェクトを作成する {#create-a-project}

プロジェクトには、今後のコード変更の計画に使用されるイシューが含まれています。

作業中のプロジェクトが既にある場合は、[種類、重大度、優先順位の条件を決定する](#decide-on-the-criteria-for-types-severity-and-priority)に進んでください。

空のプロジェクトを作成するには: 

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します。
   - **プロジェクト名**に、`Issue triage tutorial`と入力します。
1. **プロジェクトを作成**を選択します。

## 種類、重大度、優先順位の条件を決定する {#decide-on-the-criteria-for-types-severity-and-priority}

次に、以下を決定する必要があります:

- 認識するイシューの**Types**（種類）。より詳細なアプローチが必要な場合は、種類ごとにサブタイプを作成することもできます。種類は、チームにリクエストされた作業の種類を理解するために、作業を分類するのに役立ちます。
- **priorities**（優先度）と**severities**（重大度）のレベルを定義して、受信作業がエンドユーザーに与える影響を定義し、優先順位付けを支援します。

このチュートリアルでは、以下を決定したと仮定します:

- 種類：`Bug`、`Feature`、および`Maintenance`
- 優先度：`1`、`2`、`3`、および`4`
- 重大度：`1`、`2`、`3`、および`4`

参考までに、GitLabでこれらをどのように定義するかをご覧ください:

- [種類とサブタイプ](https://handbook.gitlab.com/handbook/engineering/metrics/#work-type-classification)
- [優先度](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#priority)
- [重大度](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity)

## 条件をドキュメント化する {#document-your-criteria}

すべての条件に同意したら、チームメイトが常にアクセスできる場所にすべて書き留めます。

たとえば、プロジェクトの[Wiki](../../user/project/wiki/_index.md)に追加するか、[GitLab Pages](../../user/project/pages/_index.md)で公開されている会社のハンドブックに追加します。

<!-- Idea for expanding this tutorial:
     Add steps for [creating a wiki page](../../user/project/wiki/_index.md#create-a-new-wiki-page). -->

## スコープ付きラベルを作成する {#create-scoped-labels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

次に、イシューに追加して分類するためのラベルを作成します。

これに最適なツールは、相互に排他的な属性を設定するために使用できる[スコープ付きラベル](../../user/project/labels.md#scoped-labels)です。

[以前](#decide-on-the-criteria-for-types-severity-and-priority)に組み立てた種類、重大度、優先順位のリストを確認して、一致するスコープ付きラベルを作成します。

スコープ付きラベルの名前のダブルコロン（`::`）は、同じスコープの2つのラベルが一緒に使用されるのを防ぎます。たとえば、`type::feature`ラベルが既にあるイシューに`type::bug`ラベルを追加すると、前のラベルが削除されます。

{{< alert type="note" >}}

スコープ付きラベルは、PremiumおよびUltimateプランで利用できます。Freeプランを使用している場合は、代わりに通常のラベルを使用できます。ただし、それらは相互に排他的ではありません。

{{< /alert >}}

各ラベルを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **管理** > **ラベル**を選択します。
1. **新しいラベル**を選択します。
1. **タイトル**フィールドに、ラベルの名前を入力します。`type::bug`で始まる。
1. オプション。使用可能な色から選択するか、**背景色**フィールドに特定の色を表す16進数のカラー値を入力して、色を選択します。
1. **ラベルを作成**を作成を選択します。

これらの手順を繰り返して、必要なすべてのラベルを作成します:

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

## 新しいラベルの優先順位を設定する {#prioritize-the-new-labels}

次に、新しいラベルを優先ラベルとして設定します。これにより、優先度またはラベルの優先度で並べ替える場合に、最も重要なイシューがイシューリストの最上部に表示されるようになります。

優先度またはラベル優先度でソートするとどうなるかについては、[イシューリストのソートと順序付け](../../user/project/issues/sorting_issue_lists.md)を参照してください。

ラベルの優先度を設定するには:

1. [ラベル]ページで、優先順位を付けたいラベルの横にある星印（{{< icon name="star-o" >}}）を選択します。このラベルは、**優先ラベル**の下の、ラベルリストの最上部に表示されます。
1. これらのラベルの相対的な優先度を変更するには、リストを上下にドラッグします。リストの上位にあるラベルは、より高い優先度を取得します。
1. 以前に作成したすべてのラベルの優先順位を設定します。優先度と重大度が高いラベルが、値が低いラベルよりもリストの上位にあることを確認してください。

![11個の優先順位が設定されたスコープ付きラベルのリスト](img/priority_labels_v16_3.png)

## イシュートリアージイシューボード {#create-an-issue-triage-board}

受信イシューバックログに備えて、ラベルでイシューを整理する[イシューボード](../../user/project/issue_board.md)を作成します。これを使用すると、カードをさまざまなリストにドラッグして、イシューをすばやく作成し、ラベルを追加できます。

イシューボードを設定するには、次の手順に従います:

1. イシューボードのスコープを決定します。たとえば、重大度をイシューに割り当てるために使用するイシューボードを1つ作成します。
1. 左側のサイドバーで、**検索または移動先**を選択し、**Issue triage tutorial**（イシュートリアージチュートリアル）プロジェクトを見つけます。
1. **Plan** > **イシューボード**を選択します。
1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成する**を選択します。
1. **タイトル**フィールドに、`Issue triage (by severity)`と入力します。
1. **オープンリストを表示する**チェックボックスをオンにしたまま、**クローズドリストを表示する**チェックボックスをオフにします。
1. **ボードを作成する**を選択します。空のイシューボードが表示されます。
1. `severity::1`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**（リストを作成）を選択します。
   1. 表示される列の**値**ドロップダウンリストから、`severity::1`ラベルを選択します。
   1. **ボードに追加**を選択します。
1. ラベル`severity::2`、`severity::3`、および`severity::4`に対して前の手順を繰り返します。

今のところ、イシューボードのリストは空である必要があります。次に、入力されたいくつかのイシューを追加します。

## フィーチャーのイシューを作成する {#create-issues-for-features}

今後のフィーチャーとバグを追跡するには、いくつかのイシューを作成する必要があります。イシューはプロジェクトに属していますが、イシューボードから直接作成することもできます。

計画されたフィーチャーのイシューをいくつか作成することから始めます。バグを見つけたら、それらのイシューを作成できます（あまり多くないことを願っています）。

**Issue triage (by severity)**（イシュートリアージ（重大度別））イシューボードからイシューを作成するには、次の手順に従います:

1. **オープン**リストで、**イシューの新規作成**（{{< icon name="plus" >}}）を選択します。**オープン**リストには、他のイシューボードリストに適合しないイシューが表示されます。

   イシューにどの重大度ラベルを付ける必要があるかを既に知っている場合は、そのラベルリストから直接作成できます。ラベルリストから作成された各イシューには、そのラベルが付けられます。
1. フィールドに入力します:
   - **タイトル**に、`User registration`を入力します。
1. **イシューの作成**を選択します。
1. これらの手順を繰り返して、さらにいくつかのイシューを作成します。

   たとえば、アプリをビルドする場合は、次のイシューを作成します:

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

最初のトリアージイシューボードの準備ができました。**オープン**リストからラベルリストのいずれかにイシューをドラッグして、重大度ラベルのいずれかを追加してみてください。

![ラベル付けされていないイシューと、イシューにラベルを付けるために優先順位が付けられた「重大度」ラベルを持つイシューボード](img/triage_board_v16_3.png)

## 次の手順 {#next-steps}

その後、次のことができるようになります:

- イシューボードの使用方法を微調整します。次のようなオプションがあります:
  - 現在のイシューボードを編集して、優先度と種類のラベルのリストを含めることもできます。このようにすると、イシューボードが広くなり、水平スクロールが必要になる場合があります。
  - `Issue triage (by priority)`と`Issue triage (by type)`という名前の個別のイシューボードを作成します。このようにすると、さまざまな種類のトリアージ作業を分離できますが、イシューボードを切り替える必要が生じます。
  - [チームハンドオフのためにイシューボードを設定する](../boards_for_teams/_index.md)。
- イシューリストで優先度または重大度でイシューを参照し、[各ラベルでフィルター処理](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)します。利用可能な場合は、[「次のいずれか」フィルター演算子](../../user/project/issues/managing_issues.md#filter-with-the-or-operator)を使用してください。
- イシューを[タスク](../../user/tasks.md)に分割します。
- [`gitlab-triage` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage)を使用して、プロジェクトのイシュートリアージを自動化するのに役立つポリシーを作成します。次のようなヒートマップを含むサマリーレポートを生成します:

  ![「優先度」と「重大度」のラベルが付いたイシューの斜めヒートマップ](img/triage_report_v16_3.png)

GitLabのイシュートリアージの詳細については、[イシュートリアージ](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/)と[トリアージ操作](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/)を参照してください。
