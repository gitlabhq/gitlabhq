---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: イシュートリアージのために、複数のプロジェクトを持つグループを設定する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

イシュートリアージとは、種類と重大度に応じて分類するプロセスです。プロジェクトが拡大し、作成されるイシューが増えるにつれて、受信イシューをどのようにトリアージするかに関するワークフローを作成する価値があります。

このチュートリアルでは、このシナリオのために複数のプロジェクトを持つGitLabグループを設定する方法を学びます。

プロジェクトでイシュートリアージのためにGitLabを設定するには:

1. [グループを作成する](#create-a-group)
1. [グループ内にプロジェクトを作成する](#create-projects-inside-a-group)
1. [種類、重大度、優先順位の条件を決定する](#decide-on-the-criteria-for-types-severity-and-priority)
1. [条件をドキュメント化する](#document-your-criteria)
1. [スコープ付きラベルを作成する](#create-scoped-labels)
1. [新しいラベルの優先順位を設定する](#prioritize-the-new-labels)
1. [グループイシューボードを作成する](#create-a-group-issue-triage-board)
1. [機能のイシューを作成する](#create-issues-for-features)

## はじめる前 {#before-you-begin}

- このチュートリアルで既存のプロジェクトを使用している場合は、少なくともプロジェクトのレポーターロールを持っていることを確認してください。
  - 既存のプロジェクトに親グループがない場合は、グループを作成し、[プロジェクトラベルをグループラベルにプロモートします](../../user/project/labels.md#promote-a-project-label-to-a-group-label)。

## グループを作成する {#create-a-group}

[グループ](../../user/group/_index.md)とは、本質的に複数のプロジェクトのコンテナです。これにより、ユーザーは複数のプロジェクトを管理し、グループメンバーと一度に通信できます。

新しいグループを作成します:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループを作成**を選択します。
1. グループの詳細を入力します。
   - **グループ名**に`triage-tutorial`を入力します。
1. ページの下部にある**グループを作成**を選択します。

## グループ内にプロジェクトを作成する {#create-projects-inside-a-group}

複数のプロジェクトでイシューの追跡を管理するには、グループ内に少なくとも2つのプロジェクトを作成する必要があります。

新しいプロジェクトを作成するには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します:
   - **プロジェクト名**に、`test-project-1`と入力します。詳しくは、プロジェクトの[命名規則](../../user/reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)をご覧ください。
1. ページの下部にある**プロジェクトを作成**を選択します。
1. このプロセスを繰り返して、`test-project-2`という名前の2番目のプロジェクトを作成します。

## 種類、重大度、優先順位の条件を決定する {#decide-on-the-criteria-for-types-severity-and-priority}

次に、以下を決定する必要があります:

- 認識したいイシューの**Types**（種類）。より詳細なアプローチが必要な場合は、種類ごとにサブタイプを作成することもできます。種類は、チームにリクエストされた作業の種類を理解するために、作業を分類するのに役立ちます。
- 受信作業がエンドユーザーに与える影響を定義し、優先順位付けを支援するための**priorities**（優先順位）と**severities**（重大度）のレベル。

このチュートリアルでは、以下を決定したと仮定します:

- 種類: `Bug`、`Feature`、`Maintenance`
- 優先順位: `1`、`2`、`3`、`4`
- 重大度: `1`、`2`、`3`、`4`

参考までに、GitLabでこれらをどのように定義しているかをご覧ください:

- [種類とサブタイプ](https://handbook.gitlab.com/handbook/engineering/metrics/#work-type-classification)
- [優先順位](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#priority)
- [重大度](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity)

## 条件をドキュメント化する {#document-your-criteria}

すべての条件に同意したら、チームメイトが常にアクセスできる場所にすべて書き留めます。

たとえば、プロジェクトの[Wiki](../../user/project/wiki/_index.md)に追加したり、[GitLab Pages](../../user/project/pages/_index.md)で公開されている会社のハンドブックに追加したりします。

<!-- Idea for expanding this tutorial:
     Add steps for [creating a wiki page](../../user/project/wiki/_index.md#create-a-new-wiki-page). -->

## スコープ付きラベルを作成する {#create-scoped-labels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

次に、イシューに追加して分類するためのラベルを作成します。

これに最適なツールは、相互に排他的な属性を設定するために使用できる[スコープ付きラベル](../../user/project/labels.md#scoped-labels)です。

[以前に](#decide-on-the-criteria-for-types-severity-and-priority)作成した種類、重大度、優先順位のリストを確認して、一致するスコープ付きラベルを作成します。

スコープ付きラベルの名前のダブルコロン（`::`）は、同じスコープの2つのラベルが一緒に使用されるのを防ぎます。たとえば、`type::feature`ラベルが既にあるイシューに`type::bug`ラベルを追加すると、以前のラベルは削除されます。

{{< alert type="note" >}}

スコープ付きラベルは、GitLab PremiumとGitLab Ultimateプランで利用できます。Freeプランを使用している場合は、代わりに通常のラベルを使用できます。ただし、それらは相互に排他的ではありません。

{{< /alert >}}

各ラベルを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
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

## 新しいラベルの優先順位を設定する {#prioritize-the-new-labels}

次に、新しいラベルを優先ラベルとして設定します。これにより、優先順位またはラベルの優先順位でソートした場合に、最も重要なイシューがイシューリストの一番上に表示されるようになります。

優先度またはラベル優先度でソートするとどうなるかについては、[イシューリストのソートと順序付け](../../user/project/issues/sorting_issue_lists.md)を参照してください。

ラベルの優先順位を付けるには:

1. ラベルページで、優先順位を付けるラベルの横にある**優先順位を付ける**（{{< icon name="star-o" >}}）を選択します。このラベルは、**優先ラベル**の下の、ラベルリストの最上部に表示されます。
1. これらのラベルの相対的な優先度を変更するには、リストを上下にドラッグします。リストの上位にあるラベルは、より高い優先度を取得します。
1. 以前に作成したすべてのラベルに優先順位を付けます。優先順位と重大度が高いラベルが、値の低いラベルよりもリストの上位にあることを確認してください。

![11個の優先ラベルが設定されたスコープ付きラベルのリスト](img/priority_labels_v16_3.png)

## グループイシューボードを作成する {#create-a-group-issue-triage-board}

受信イシューバックログに備えて、ラベルでイシューを整理する[イシューボード](../../user/project/issue_board.md)を作成します。これを使用すると、カードをさまざまなリストにドラッグして、イシューをすばやく作成し、ラベルを追加できます。

イシューボードを設定するには:

1. ボードのスコープを決定します。たとえば、イシューに重大度を割り当てるために使用する[グループイシューボードを作成する](../../user/project/issue_board.md#group-issue-boards)などがあります。
1. 左側のサイドバーで、**検索または移動先**を選択し、**triage-tutorial**（triage-tutorial）グループを見つけます。
1. **Plan** > **イシューボード**を選択します。
1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成する**を選択します。
1. **タイトル**フィールドに、`Issue triage (by severity)`を入力します。
1. **オープンリストを表示する**チェックボックスを選択したまま、**クローズドリストを表示する**チェックボックスをオフにします。
1. **ボードを作成する**を選択します。空のボードが表示されます。
1. `severity::1`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**（リストを作成）（）を選択します。
   1. 表示される列で、**値**ドロップダウンリストから、`severity::1`ラベルを選択します。
   1. リストの下部にある**ボードに追加**を選択します。
1. ラベル`severity::2`、`severity::3`、および`severity::4`について、前の手順を繰り返します。

今のところ、ボードのリストは空である必要があります。次に、いくつかのイシューを入力された状態にします。

## 機能のイシューを作成する {#create-issues-for-features}

今後の機能とバグを追跡するには、いくつかのイシューを作成する必要があります。イシューはプロジェクトに属していますが、グループイシューボードから直接作成することもできます。

計画された機能のイシューをいくつか作成することから始めます。バグを見つけたら、それらのイシューを作成できます（あまり多くないことを願っています！）。

**Issue triage (by severity)**（重大度別のイシュートリアージ）ボードからイシューを作成するには:

1. **オープン**リストに移動します。このリストには、他のボードリストに適合しないイシューが表示されます。イシューに必要な重大度ラベルが既にわかっている場合は、そのラベルのリストから直接作成できます。ラベルリストから作成された各イシューには、そのラベルが付けられていることに注意してください。

   今のところ、**オープン**リストの使用に進みます。
1. **オープン**リストで、**イシューの新規作成**アイコン（{{< icon name="plus" >}}）を選択します。
1. フィールドに入力します:
   - **タイトル**の下に、`User registration`と入力します。
   - このイシューが適用されるプロジェクトを選択します。`test-project-1`を選択します。
1. **イシューの作成**を選択します。
1. これらの手順を繰り返して、さらにいくつかのイシューを作成します。

   たとえば、アプリをビルドしている場合、`test-project-1`と`test-project-2`がアプリケーションのバックエンドとフロントエンドを参照していると想像してください。次のイシューを作成し、必要に応じてプロジェクトに割り当てます:

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

最初のトリアージイシューボードの準備ができました。**オープン**リストからラベルリストのいずれかにイシューをドラッグして、重大度ラベルのいずれかを追加して試してみてください。

![ラベル付けイシューのラベルなしイシューと優先ラベルが設定された「重大度」イシューボード](img/triage_board_v16_3.png)

## 次の手順 {#next-steps}

その後、次のことができるようになります:

- イシューボードの使用方法を微調整します。次のようなオプションがあります:
  - 現在のイシューボードを編集して、優先順位と種類のラベルのリストも表示されるようにします。これにより、ボードが広くなり、水平スクロールが必要になる場合があります。
  - `Issue triage (by priority)`と`Issue triage (by type)`という名前の別のイシューボードを作成します。これにより、さまざまな種類のトリアージ作業を分離できますが、ボードを切り替える必要があります。
  - [チームハンドオフ](../boards_for_teams/_index.md)用のイシューボードをセットアップする
- イシューリストで優先順位または重大度別にイシューを参照し、[各ラベルでフィルターします](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)。利用可能な場合は、[「次のいずれか」フィルター演算子](../../user/project/issues/managing_issues.md#filter-with-the-or-operator)を使用します。
- イシューを[タスク](../../user/tasks.md)に分割します。
- [`gitlab-triage` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage)を使用して、プロジェクトでイシュートリアージを自動化するのに役立つポリシーを作成します。次のようなヒートマップを使用してサマリーレポートを生成します:

  ![「優先順位」と「重大度」ラベルが付いたイシューの対角ヒートマップ](img/triage_report_v16_3.png)

GitLabのイシュートリアージの詳細については、[Issue Triage](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/)と[Triage Operations](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/)をご覧ください。
