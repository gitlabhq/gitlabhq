---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'チュートリアル: トリアージのための複数のグループプロジェクトを使用してイシューをセットアップする'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

トリアージとは、種類と重大度に応じて分類するプロセスです。プロジェクトが成長し、より多くのイシューが作成されるにつれて、受信イシューをトリアージする方法のワークフローを作成する価値があります。

このチュートリアルでは、このシナリオに合わせて、複数のプロジェクトを持つGitLabグループを設定する方法を学びます。

プロジェクトでイシュートリアージのためにGitLabを設定するには:

1. [グループを作成する](#create-a-group)
1. [プロジェクトをグループ内に作成する](#create-projects-inside-a-group)
1. [種類、重大度、および優先順位の基準を決定](#decide-on-the-criteria-for-types-severity-and-priority)
1. [基準をドキュメント化](#document-your-criteria)
1. [スコープ付きラベルを作成](#create-scoped-labels)
1. [新しいラベルを優先](#prioritize-the-new-labels)
1. [グループイシューボードを作成する](#create-a-group-issue-triage-board)
1. [機能のイシューを作成](#create-issues-for-features)

## はじめる前 {#before-you-begin}

- このチュートリアルで既存のプロジェクトを使用している場合は、プロジェクトでレポーター、デベロッパー、メンテナー、またはオーナーロールを持っていることを確認してください。
  - 既存のプロジェクトに親グループがない場合は、グループを作成し、プロジェクトのラベルをグループラベルに[プロモート](../../user/project/labels.md#promote-a-project-label-to-a-group-label)します。

## グループを作成する {#create-a-group}

A [グループ](../../user/group/_index.md)は、本質的に複数のプロジェクトのコンテナです。これにより、ユーザーは複数のプロジェクトを管理し、グループメンバーと一度にコミュニケーションをとることができます。

新規グループを作成するには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループを作成**を選択します。
1. グループの詳細を入力します。
   - **グループ名**に`triage-tutorial`を入力します。
1. ページ下部の**グループを作成**を選択します。

## グループ内にプロジェクトを作成する {#create-projects-inside-a-group}

複数のプロジェクトにわたるイシュートラッキングを管理するには、グループ内に少なくとも2つのプロジェクトを作成する必要があります。

新規プロジェクトを作成するには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します。
   - **プロジェクト名**に、`test-project-1`と入力します。詳細については、プロジェクトの[命名規則](../../user/reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)を参照してください。
1. ページ下部の**プロジェクトを作成**を選択します。
1. このプロセスを繰り返して、`test-project-2`という名前の2番目のプロジェクトを作成します。

## 種類、重大度、および優先順位の基準を決定 {#decide-on-the-criteria-for-types-severity-and-priority}

次に、以下を決定する必要があります:

- 認識したい**Types**のイシュー。よりきめ細かいアプローチが必要な場合は、各種類にサブタイプを作成することもできます。種類は、チームにリクエストされる作業の種類を理解するために、作業を分類するのに役立ちます。
- **priorities**と**severities**のレベル。これは、受信する作業がエンドユーザーに与える影響を定義し、優先順位付けを支援するためです。

このチュートリアルでは、以下を決定したとします:

- 種類: `Bug`、`Feature`、および`Maintenance`
- 優先: `1`、`2`、`3`、および`4`
- 重大度: `1`、`2`、`3`、および`4`

参考として、GitLabでこれらをどのように定義しているかを参照してください:

- [種類とサブタイプ](https://handbook.gitlab.com/handbook/engineering/metrics/#work-type-classification)
- [優先](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#priority)
- [重大度](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity)

## 基準をドキュメント化 {#document-your-criteria}

すべての基準に同意したら、チームメイトがいつでもアクセスできる場所にすべてを書き留めてください。

たとえば、プロジェクトの[Wiki](../../user/project/wiki/_index.md)に追加したり、[GitLab Pages](../../user/project/pages/_index.md)で公開された会社のハンドブックに追加したりします。

<!-- Idea for expanding this tutorial:
     Add steps for [creating a wiki page](../../user/project/wiki/_index.md#create-a-new-wiki-page). -->

## スコープ付きラベルを作成 {#create-scoped-labels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

次に、イシューを分類するために追加するラベルを作成します。

これに最適なツールは[スコープ付きラベル](../../user/project/labels.md#scoped-labels)で、これを使用して相互に排他的な属性を設定できます。

[以前に](#decide-on-the-criteria-for-types-severity-and-priority)まとめた種類、重大度、および優先順位のリストと照合して、一致するスコープ付きラベルを作成します。

スコープ付きラベル名にあるダブルコロン（`::`）は、同じスコープの2つのラベルが一緒に使用されるのを防ぎます。たとえば、`type::feature`ラベルをすでに`type::bug`を持つイシューに追加すると、以前のものが削除されます。

> [!note]
>
> スコープ付きラベルはPremiumおよびUltimateプランで利用できます。Freeプランの場合は、代わりに通常のラベルを使用できます。ただし、それらは相互に排他的ではありません。

各ラベルを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **管理** > **ラベル**を選択します。
1. **新しいラベル**を選択します。
1. **タイトル**フィールドにラベルの名前を入力します。から開始します。`type::bug`で始まる。
1. （オプション）利用可能な色から色を選択するか、**背景色**フィールドに特定の色の16進数のカラー値を入力します。
1. **ラベル**を作成を選択します。

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

## 新しいラベルを優先 {#prioritize-the-new-labels}

ここで、新しいラベルを優先ラベルとして設定します。これにより、イシューを優先順位またはラベル優先順位でソートした場合に、最も重要なイシューがイシューリストの最上部に表示されるようになります。

優先順またはラベル優先順でソートした場合に何が起こるかについては、[イシューリストのソートと順序付け](../../user/project/issues/sorting_issue_lists.md)を参照してください。

ラベルの優先順位を付けるには:

1. ラベルページで、優先順位を付けたいラベルの横にある**優先順位を付ける**（{{< icon name="star-o" >}}）を選択します。このラベルは、**優先ラベル**の下のラベルリストの最上部に表示されます。
1. これらのラベルの相対的な優先度を変更するには、リストを上下にドラッグします。リストの上位にあるラベルほど優先順位が高くなります。
1. 以前に作成したすべてのラベルの優先順位を付けます。優先順位と重大度が高いラベルが、値の低いラベルよりもリストの上位にあることを確認してください。

![11個の優先ラベル付きスコープ付きラベルのリスト](img/priority_labels_v16_3.png)

## グループイシューボードを作成する {#create-a-group-issue-triage-board}

受信するイシューバックログに備えて、イシューをラベルで整理する[イシューボード](../../user/project/issue_board.md)を作成します。これを使用して、カードをさまざまなリストにドラッグすることで、イシューをすばやく作成し、ラベルを追加できます。

イシューボードを設定するには:

1. ボードのスコープを決定します。たとえば、イシューに重大度を割り当てるために使用する[グループイシューボード](../../user/project/issue_board.md#group-issue-boards)を作成します。
1. トップバーで**検索または移動先**を選択し、**triage-tutorial**グループを見つけます。
1. **計画** > **イシューボード**を選択します。
1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成**を選択します。
1. **タイトル**フィールドに`Issue triage (by severity)`を入力します。
1. **オープンリストを表示する**チェックボックスをオンのままにし、**クローズドリストを表示する**チェックボックスをオフにします。
1. **ボードを作成する**を選択します。空のボードが表示されます。
1. `severity::1`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**を選択します。
   1. 表示される列で、**値**ドロップダウンリストから`severity::1`ラベルを選択します。
   1. リストの下部で、**ボードに追加**を選択します。
1. ラベル`severity::2`、`severity::3`、および`severity::4`についても、前の手順を繰り返します。

現時点では、ボード内のリストは空であるはずです。次に、いくつかのイシューでそれらを埋めます。

## 機能のイシューを作成 {#create-issues-for-features}

今後の機能やバグを追跡するには、いくつかのイシューを作成する必要があります。イシューはプロジェクトに属しますが、グループイシューボードから直接作成することもできます。

計画された機能のイシューをいくつか作成することから始めます。バグを見つけたら（うまくいけばあまり多くない！）、それらのイシューを作成できます。

**Issue triage（by severity）**ボードからイシューを作成するには:

1. **オープン**リストに移動します。このリストには、他のボードリストに適合しないイシューが表示されます。どの重大度ラベルをイシューに付けるべきか既に分かっている場合は、そのラベルのリストから直接作成できます。ラベルリストから作成された各イシューには、そのラベルが付与されることに注意してください。

   ここでは、**オープン**リストを使用します。
1. **オープン**リストで、**イシューの新規作成**アイコン（{{< icon name="plus" >}}）を選択します。
1. フィールドに入力します:
   - **タイトル**の下に、`User registration`を入力します。
   - このイシューが適用されるプロジェクトを選択します。`test-project-1`を選択します。
1. **イシューを作成**を選択します。
1. これらの手順を繰り返して、さらにいくつかのイシューを作成します。

   たとえば、アプリを構築している場合、`test-project-1`と`test-project-2`がアプリケーションのバックエンドとフロントエンドを指していると想像してください。以下に示すイシューを作成し、必要に応じてプロジェクトに割り当てます:

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

最初のトリアージイシューボードが準備できました！**オープン**リストからいくつかのイシューをラベルリストのいずれかにドラッグして、いずれかの重大度ラベルを追加してみてください。

![ラベルのないイシューと、イシューへのラベル付けに使用する優先度付き「重大度」ラベルを示すイシューボード](img/triage_board_v16_3.png)

## 次の手順 {#next-steps}

その後、次のことができるようになります。

- イシューボードの使用方法を微調整する。次のようなオプションがあります。
  - 現在のイシューボードを編集して、優先順位と種類ラベルのリストも持たせます。このようにすると、ボードが広くなり、水平スクロールが必要になる場合があります。
  - `Issue triage (by priority)`と`Issue triage (by type)`という名前の個別のイシューボードを作成します。このようにすると、さまざまな種類のトリアージ作業を分離できますが、ボードを切り替える必要があります。
  - [チームハンドオフのためのイシューボードを設定する](../boards_for_teams/_index.md)。
- イシューリストで優先度または重大度別にイシューを閲覧し、[各ラベルでフィルタリング](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)します。利用可能な場合は、[「is one of」フィルター演算子](../../user/project/issues/managing_issues.md#filter-the-list-of-issues)を使用してください。
- イシューを[タスク](../../user/tasks.md)に分解します。
- [`gitlab-triage` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage)を使用して、プロジェクトでイシュートリアージを自動化するポリシーを作成します。次のようなヒートマップ付きの概要レポートを生成します:

  ![「優先」と「重大度」ラベル付きのイシューの対角ヒートマップ](img/triage_report_v16_3.png)

GitLabでのイシュートリアージの詳細については、[イシュートリアージ](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/)と[トリアージオペレーション](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/)を参照してください。
