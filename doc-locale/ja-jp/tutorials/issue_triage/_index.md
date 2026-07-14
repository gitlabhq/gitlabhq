---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'チュートリアル: イシュートリアージ用のプロジェクトをセットアップする'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

トリアージとは、タイプと重大度に応じて分類するプロセスです。プロジェクトが成長し、人々がより多くのイシューを作成するにつれて、受信イシューをトリアージするためのワークフローを作成する価値があります。

このチュートリアルでは、このためのGitLabプロジェクトを設定する方法を学習します。

プロジェクトでイシュートリアージのためにGitLabを設定するには:

1. [プロジェクトを作成する](#create-a-project)
1. [タイプ、重大度、優先順位の基準を決定する](#decide-on-the-criteria-for-types-severity-and-priority)
1. [基準をドキュメント化する](#document-your-criteria)
1. [スコープ付きラベルを作成する](#create-scoped-labels)
1. [新しいラベルを優先する](#prioritize-the-new-labels)
1. [イシュートリアージボードを作成する](#create-an-issue-triage-board)
1. [機能のイシューを作成する](#create-issues-for-features)

## はじめる前 {#before-you-begin}

- このチュートリアルで既存のプロジェクトを使用している場合は、プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーのロールを持っていることを確認してください。
- 以下の手順に従い、後でプロジェクトの親グループを作成することを決定し、ラベルを最大限に活用するには、プロジェクトラベルをグループラベルにプロモートする必要があります。まずグループを作成することを検討してください。

## プロジェクトを作成する {#create-a-project}

プロジェクトには、今後のコード変更を計画するために使用されるイシューが含まれています。

既に作業中のプロジェクトがある場合は、[タイプ、重大度、および優先順位の基準を決定する](#decide-on-the-criteria-for-types-severity-and-priority)に進んでください。

空のプロジェクトを作成するには: 

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します。
   - **プロジェクト名**に、`Issue triage tutorial`と入力します。
1. **プロジェクトを作成**を選択します。

## タイプ、重大度、優先順位の基準を決定する {#decide-on-the-criteria-for-types-severity-and-priority}

次に、以下を決定する必要があります:

- **Types**。より詳細なアプローチが必要な場合は、各タイプにサブタイプを作成することもできます。タイプは、チームにリクエストされる作業の種類を理解するために、作業を分類するのに役立ちます。
- **priorities**順位と**severities**のレベルを、受信作業がエンドユーザーに与える影響を定義し、優先順位付けを支援するために使用します。

このチュートリアルでは、以下を決定したとします:

- タイプ: `Bug`バグ、`Feature`機能、および`Maintenance`メンテナンス
- 優先順位: `1`、`2`、`3`、および`4`
- 重大度: `1`、`2`、`3`、および`4`

GitLabでのこれらの定義については、以下を参照してください:

- [タイプとサブタイプ](https://handbook.gitlab.com/handbook/engineering/metrics/#work-type-classification)
- [優先](https://handbook.gitlab.com/handbook/product-development/how-we-work/issue-triage/#priority)順位
- [重大度](https://handbook.gitlab.com/handbook/product-development/how-we-work/issue-triage/#severity)

## 基準をドキュメント化する {#document-your-criteria}

すべての基準に同意したら、チームメイトがいつでもアクセスできる場所にすべて書き留めてください。

たとえば、プロジェクトの[Wiki](../../user/project/wiki/_index.md)、または[GitLab Pages](../../user/project/pages/_index.md)で公開されている会社のハンドブックに追加します。

<!-- Idea for expanding this tutorial:
     Add steps for [creating a wiki page](../../user/project/wiki/_index.md#create-a-new-wiki-page). -->

## スコープ付きラベルを作成する {#create-scoped-labels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

次に、イシューを分類するために追加するラベルを作成します。

これに最適なツールは[スコープ付きラベル](../../user/project/labels.md#scoped-labels)で、これを使用して相互に排他的な属性を設定できます。

[以前に](#decide-on-the-criteria-for-types-severity-and-priority)まとめたタイプ、重大度、および優先順位のリストを確認し、一致するスコープ付きラベルを作成する必要があります。

スコープ付きラベルの名前にあるダブルコロン (`::`) は、同じスコープの2つのラベルが同時に使用されるのを防ぎます。たとえば、`type::feature`ラベルを既に`type::bug`があるイシューに追加すると、以前のラベルが削除されます。

> [!note]
> スコープ付きラベルはPremiumプランとUltimateプランで利用できます。Freeプランを使用している場合は、代わりに通常のラベルを使用できます。ただし、それらは相互に排他的ではありません。

各ラベルを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**管理** > **ラベル**を選択します。
1. **新しいラベル**を選択します。
1. **タイトル**フィールドに、ラベルの名前を入力します。`type::bug`で始まる。
1. オプション。使用可能な色から選択するか、**背景色**フィールドに特定の色を表す16進数のカラー値を入力して、色を選択します。
1. **ラベル**を作成を選択します。

必要なすべてのラベルを作成するために、これらの手順を繰り返します:

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

次に、新しいラベルを優先ラベルとして設定します。これにより、優先順位またはラベルの優先順位でソートした場合に、最も重要なイシューがイシューリストの最上部に表示されるようになります。

優先順位またはラベルの優先順位でソートした場合に何が起こるかについては、[イシューリストのソートと順序付け](../../user/project/issues/sorting_issue_lists.md)を参照してください。

ラベルの優先度を設定するには:

1. ラベルページで、優先するラベルの横にある星 ({{< icon name="star-o" >}}) を選択します。このラベルは、ラベルリストの最上部、**優先ラベル**の下に表示されます。
1. これらのラベルの相対的な優先度を変更するには、リストを上下にドラッグします。リストの上位にあるラベルは、より高い優先度を取得します。
1. 以前に作成したすべてのラベルを優先します。優先順位と重大度が高いラベルが、低い値のラベルよりもリストの上位にあることを確認してください。

![11個の優先ラベル付きスコープ付きラベルのリスト](img/priority_labels_v16_3.png)

## イシュートリアージボードを作成する {#create-an-issue-triage-board}

受信イシューバックログに備えるには、イシューをラベルで整理する[イシューボード](../../user/project/issue_board.md)を作成します。これを使用して、カードをさまざまなリストにドラッグすることで、イシューをすばやく作成し、ラベルを追加できます。

イシューボードを設定するには:

1. ボードのスコープを決定します。たとえば、イシューに重大度を割り当てるために使用するボードを作成します。
1. トップバーで**検索または移動先**を選択し、**Issue triage tutorial**プロジェクトを見つけます。
1. **計画** > **イシューボード**を選択します。
1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成**を選択します。
1. **タイトル**フィールドに`Issue triage (by severity)`と入力します。
1. **オープンリストを表示する**チェックボックスをオンにし、**クローズドリストを表示する**チェックボックスをオフにします。
1. **ボードを作成する**を選択します。空のボードが表示されるはずです。
1. `severity::1`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**を選択します。
   1. 表示されるカラムで、**値**ドロップダウンリストから`severity::1`ラベルを選択します。
   1. **ボードに追加**を選択します。
1. 以前の手順を`severity::2`、`severity::3`、および`severity::4`ラベルに対して繰り返します。

現時点では、ボードのリストは空であるはずです。次に、いくつかのイシューをそれらに投入します。

## 機能のイシューを作成する {#create-issues-for-features}

今後の機能やバグを追跡するには、いくつかのイシューを作成する必要があります。イシューはプロジェクトに属しますが、イシューボードから直接作成することもできます。

まず、計画された機能のイシューをいくつか作成します。バグを見つけたら(バグが多すぎないことを願っています！)、イシューを作成できます。

**Issue triage (by severity)**ボードからイシューを作成するには:

1. **オープン**リストで、**イシューの新規作成** ({{< icon name="plus" >}}) を選択します。**オープン**リストには、他のどのボードリストにも適合しないイシューが表示されます。

   どの重大度ラベルをイシューに付けるべきか既に分かっている場合は、そのラベルリストから直接作成できます。ラベルリストから作成された各イシューには、そのラベルが付けられます。
1. フィールドに入力します:
   - **タイトル**の下に、`User registration`と入力します。
1. **イシューを作成**を選択します。
1. さらにいくつかのイシューを作成するために、これらの手順を繰り返します。

   たとえば、アプリを構築している場合は、次のイシューを作成します:

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

最初のトリアージイシューボードの準備ができました！**オープン**リストからいくつかのイシューをラベルリストのいずれかにドラッグして、いずれかの重大度ラベルを追加してみてください。

![ラベルが付いていないイシューと、イシューのラベル付けに使用する優先度別の「重大度」ラベルが表示されているイシューボード](img/triage_board_v16_3.png)

## 次の手順 {#next-steps}

その後、次のことができるようになります。

- イシューボードの使用方法を微調整する。次のようなオプションがあります。
  - 現在のイシューボードを編集して、優先順位とタイプラベルのリストも持つようにします。これにより、ボードが広くなり、水平スクロールが必要になる場合があります。
  - 別々のイシューボードを`Issue triage (by priority)`と`Issue triage (by type)`という名前で作成します。これにより、さまざまな種類のトリアージ作業を分離できますが、ボードを切り替える必要があります。
  - [チームハンドオフ用のイシューボードを設定する](../boards_for_teams/_index.md)。
- イシューリストで、優先順位または重大度別にイシューを閲覧し、[各ラベルでフィルター](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)します。利用可能な場合は、[「いずれかである」フィルター演算子](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)を使用してください。
- イシューを[タスク](../../user/tasks.md)に分解します。
- [`gitlab-triage` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage)を使用して、プロジェクト内のイシュートリアージを自動化するポリシーを作成します。次のレポートのように、ヒートマップを含む概要レポートを生成します:

  ![「優先」および「重大度」ラベルを持つイシューの斜めヒートマップ](img/triage_report_v16_3.png)

GitLabでのイシュートリアージの詳細については、[イシュートリアージ](https://handbook.gitlab.com/handbook/product-development/how-we-work/issue-triage/)と[トリアージオペレーション](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/developer-experience/triage-operations/)を参照してください。
