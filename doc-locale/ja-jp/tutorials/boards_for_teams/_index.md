---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: チーム間の引き継ぎ用のイシューボードをセットアップする'
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、順番にイシューに取り組む2つのチームのために、[イシューボード](../../user/project/issue_board.md)と[スコープ付きラベル](../../user/project/labels.md#scoped-labels)を設定する方法を紹介します。

この例では、UXチームとフロントエンドチームの2つのイシューボードを作成します。以下の手順に従って、バックエンドや品質保証など、より多くのサブチームのイシューボードとワークフローを作成できます。

複数のチームにイシューボードを設定するには:

1. [グループを作成する](#create-a-group)
1. [プロジェクトを作成する](#create-a-project)
1. [ラベルの作成](#create-labels)
1. [チームイシューボードの作成](#create-team-issue-boards)
1. [機能のイシューの作成](#create-issues-for-features)

## はじめる前 {#before-you-begin}

- このチュートリアルで既存のグループを使用している場合は、グループのプランナーロール以上を持っていることを確認してください。
- このチュートリアルで既存のプロジェクトを使用している場合は、プロジェクトのプランナーロール以上を持っていることを確認してください。

## 目標ワークフロー {#the-goal-workflow}

すべての設定が完了すると、2つのチームは、たとえば次のように、あるボードから別のボードにイシューを受け渡すことができるようになります:

1. プロジェクトリーダーは、`Workflow::Ready for design`ラベルと`Frontend`ラベルを、**Redesign user profile page**（ユーザープロファイルページの再設計）という機能イシューに追加します。
1. UXチームの製品デザイナー:
   1. **UX workflow**（UX workflow）ボードの`Workflow::Ready for design`リストをチェックし、プロファイルページの再設計に取り組むことを決定します。

      ![3つのワークフロー列に3つのイシューがある「UXワークフロー」イシューボード](img/ux_board_filled_v16_0.png)

   1. **Redesign user profile page**（ユーザープロファイルページの再設計）イシューに自分自身を割り当てます。
   1. `Workflow::Design`リストにイシューカードをドラッグします。前のワークフローラベルは自動的に削除されます。
   1. ✨新しいデザイン✨を作成します。
   1. [イシューにデザインを追加](../../user/project/issues/design_management.md)します。
   1. `Workflow::Ready for development`リストにイシューカードをドラッグすると、このラベルが追加され、他の`Workflow::`ラベルが削除されます。
   1. イシューから自分自身の割り当てを解除します。
1. フロントエンドチームのデベロッパー:
   1. **Frontend workflow**（Frontend workflow）ボードの`Workflow::Ready for development`リストをチェックし、取り組むイシューを選択します。

      ![「開発準備完了」列に「UXワークフロー」ボードからの2つのイシューがある「Frontend workflow」イシューボード](img/frontend_board_filled_v16_0.png)

   1. **Redesign user profile page**（ユーザープロファイルページの再設計）イシューに自分自身を割り当てます。
   1. `Workflow::In development`リストにイシューカードをドラッグします。前のワークフローラベルは自動的に削除されます。
   1. [マージリクエスト](../../user/project/merge_requests/_index.md)にフロントエンドコードを追加します。
   1. `Workflow::Complete`ラベルを追加します。

## グループを作成する {#create-a-group}

プロジェクトの拡大に備えて、まずグループを作成します。グループを使用すると、関連する複数のプロジェクトを同時に管理できます。ユーザーをグループのメンバーとして追加し、ロールを割り当てます。

グループを作成するには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループを作成**を選択します。
1. フィールドに入力します。グループに`Paperclip Software Factory`という名前を付けます。
1. **グループを作成**を選択します。

空のグループを作成しました。次に、イシューとコードを保存するプロジェクトを作成します。

## プロジェクトを作成する {#create-a-project}

コードの主な開発作業は、プロジェクトとそのリポジトリで行われます。プロジェクトには、コードとパイプラインだけでなく、今後のコード変更の計画に使用されるイシューも含まれています。

空のプロジェクトを作成するには: 

1. グループ内で、左側のサイドバーの上部にある**新規作成**({{< icon name="plus" >}})を選択し、次に**このグループで** > **新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します:
   - **プロジェクト名**フィールドに、プロジェクト名`Paperclip Assistant`を入力します。
1. **プロジェクトを作成**を選択します。

## ラベルの作成 {#create-labels}

イシューが開発サイクルのどこにあるかを示すには、チームラベルと一連のワークフローラベルが必要です。

これらのラベルは`Paperclip Assistant`プロジェクトで作成できますが、`Paperclip Software Factory`グループで作成する方が適しています。このようにすると、これらのラベルは、以降に作成する他のすべてのプロジェクトでも使用できるようになります。

各ラベルを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、**Paperclip Software Factory**（Paperclip Software Factory）グループを見つけます。
1. 左側のサイドバーで、**管理** > **ラベル**を選択します。
1. **新しいラベル**を選択します。
1. **タイトル**フィールドに、ラベルの名前を入力します。`Frontend`で始まる。
1. オプション。使用可能な色から選択するか、**背景色**フィールドに特定の色を表す16進数のカラー値を入力して、色を選択します。
1. **ラベルを作成**を選択します。

これらの手順を繰り返して、必要なすべてのラベルを作成します:

- `Frontend`
- `Workflow::Ready for design`
- `Workflow::Design`
- `Workflow::Ready for development`
- `Workflow::In development`
- `Workflow::Complete`

## チームイシューボードの作成 {#create-team-issue-boards}

ラベルと同様に、イシューボードは**Paperclip Assistant**（Paperclip Assistant）プロジェクトで作成できますが、**Paperclip Software Factory**（Paperclip Software Factory）グループに含める方が適しています。このようにすると、このグループで以降に作成する可能性のあるすべてのプロジェクトからイシューを管理できます。

新しいグループイシューボードを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、**Paperclip Software Factory**（Paperclip Software Factory）グループを見つけます。
1. 左側のサイドバーで、**Plan** > **イシューボード**を選択します。
1. UXワークフローおよびフロントエンドワークフローボードを作成します。

**UX workflow**（UX workflow）イシューボードを作成するには:

1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成する**を選択します。
1. **Title field**（タイトルフィールド）に`UX workflow`と入力します。
1. **オープンリストを表示する**チェックボックスと**クローズドリストを表示する**チェックボックスをオフにします。
1. **ボードを作成する**を選択します。空のボードが表示されます。
1. `Workflow::Ready for design`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**（リストを作成）を選択します。
   1. 表示される列の**値**ドロップダウンリストから、`Workflow::Ready for design`ラベルを選択します。
   1. **ボードに追加**を選択します。
1. ラベル`Workflow::Design`と`Workflow::Ready for development`に対して前の手順を繰り返します。

![3つのワークフロー列がある空の「UXワークフロー」イシューボード](img/ux_board_empty_v16_0.png)

**Frontend workflow**（Frontend workflow）ボードを作成するには:

1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **新しいボードを作成する**を選択します。
1. **Title field**（タイトルフィールド）に`Frontend workflow`と入力します。
1. **オープンリストを表示する**チェックボックスと**クローズドリストを表示する**チェックボックスをオフにします。
1. **スコープ**を展開する。
1. **ラベル**の横にある**編集**を選択し、`Frontend`ラベルを選択します。
1. **ボードを作成する**を選択します。
1. `Workflow::Ready for development`ラベルのリストを作成します:
   1. イシューボードページの右上隅で、**Create list**（リストを作成）を選択します。
   1. 表示された列の**値**ドロップダウンリストから、`Workflow::Ready for development`ラベルを選択します。
   1. **ボードに追加**を選択します。
1. ラベル`Workflow::In development`と`Workflow::Complete`に対して前の手順を繰り返します。

![3つのワークフロー列がある空の「Frontend workflow」イシューボード](img/frontend_board_empty_v16_0.png)

今のところ、両方のボードのリストは空のはずです。次に、いくつかのイシューを入力します。

## 機能のイシューを作成する {#create-issues-for-features}

今後の機能、機能拡張、およびバグを追跡するには、いくつかのイシューを作成する必要があります。イシューはプロジェクトに属していますが、イシューボードから直接作成することもできます。

ボードからイシューを作成するには:

1. イシューボードページの上部左隅にあるドロップダウンリストで、現在のボード名を選択します。
1. **UX workflow**（UX workflow）を選択します。
1. `Workflow::Ready for development`リストで、**イシューの新規作成**({{< icon name="plus" >}})を選択します。
1. フィールドに入力します:
   1. **タイトル**で、`Redesign user profile page`を入力します。
   1. **プロジェクト**で、**Paperclip Software Factory / Paperclip Assistant**（Paperclip Software Factory / Paperclip Assistant）を選択します。
1. **イシューの作成**を選択します。ラベルリストで新しいイシューを作成したので、このラベルとともに作成されます。
1. `Frontend`ラベルを追加します。このラベルが付いたイシューのみがフロントエンドチームのボードに表示されるためです:
   1. イシューカード(タイトルではありません)を選択すると、右側にサイドバーが表示されます。
   1. サイドバーの**ラベル**セクションで、**編集**を選択します。
   1. **Assign labels**（ラベルを割り当てる）ドロップダウンリストから、`Workflow::Ready for design`ラベルと`Frontend`ラベルを選択します。選択したラベルにはチェックマークが付いています。
   1. ラベルへの変更を適用するには、**Assign labels**（ラベル）割り当ての横にある**X**（X）を選択するか、ラベルセクションの外側の任意の領域を選択します。

これらの手順を繰り返して、同じラベルを持つイシューをさらにいくつか作成します。

少なくとも1つのイシューがそこに表示され、製品デザイナーが作業を開始できるようになっているはずです。

おつかれさまでした。これで、チームは素晴らしいソフトウェアでコラボレーションを開始できます。次のステップとして、これらのボードを使用して[目標ワークフロー](#the-goal-workflow)を自分で試して、2つのチームのやり取りをシミュレートできます。

## GitLabでのプロジェクト管理の詳細 {#learn-more-about-project-management-in-gitlab}

[チュートリアルページ](../plan_and_track.md)で、プロジェクト管理に関する他のチュートリアルを見つけてください。
