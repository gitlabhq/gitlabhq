---
stage: Foundations
group: Design System
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインターフェースの再デザイン
description: 今後のGitLab UIの再設計について説明します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/18710) GitLab 18.5 ([with flags](../administration/feature_flags/_index.md)、名前は`paneled_view`)。デフォルトでは無効になっています。これは[実験的機能](../policy/development_stages_support.md)です。
- [GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/577994) GitLab 18.6で、[GitLab Duoの試験的な機能](gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)を使用するグループのメンバー向けに有効。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

このインターフェースの再設計により、インテリジェントエージェントが開発チームと並行して作業するAIネイティブのワークフローに向けてGitLab UIが準備されます。この最新化されたインターフェースは、永続的なサイドバーでAIインタラクションを一元化し、従来の開発タスクとAIアシストのワークフローの両方に対応できるパネルベースのレイアウトを導入し、ナビゲーションの複雑さを軽減します。

これは[実験的機能](../policy/development_stages_support.md)です。セルフマネージドのGitLabでこの機能フラグをテストするには: GitLabの管理者にお問い合わせください。

[イシュー577554](https://gitlab.com/gitlab-org/gitlab/-/issues/577554)でフィードバックをお寄せください。

![新しいUIを備えたプロジェクトページ](img/paneled_view_projects_v18_5.png)

## 新しいナビゲーションのオン/オフを切り替える {#turn-new-navigation-on-or-off}

前提要件: 

- 管理者が、ユーザーに関連するすべての機能フラグを有効にしている必要があります。特定のフラグについては、このページの上部にある履歴セクションを参照してください。

ユーザーアバターが左側のサイドバーにある場合は、以前のナビゲーションを使用していることを示しています。

新しいナビゲーションスタイルをオンにするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **新しいUI**切り替えをオンにします。

ページが更新され、新しいGitLabナビゲーションの調査を開始できます。

新しいナビゲーションスタイルをオフにするには:

1. 右上隅にある自分のアバターを選択します。
1. **新しいUI**切り替えをオフにします。

## 新機能 {#whats-new}

新しいUIをオンにすると、より丸みを帯びたエッジを備えた最新のデザインと、次の変更が適用されます。

### 検索バーが中央に移動 {#search-bar-moves-to-the-center}

**検索または移動先**フィールドが上部のバーの中央に移動し、より見つけやすくなりました。

### 上部のバーのボタンが右に移動 {#top-bar-buttons-move-to-the-right}

次のボタンが右上隅にあります:

- **新規作成**
- 割り当てられたイシュー
- 割り当てられたマージリクエスト
- To-Doアイテム
- **管理者**
- 自分のアバターとそのオプション

![新しいUIの上部バーボタン](img/paneled_view_top_buttons_v18_5.png)

### GitLab Duoに常にアクセス可能 {#gitlab-duo-is-always-accessible}

GitLab Duoチャット、セッション、および提案にアクセスするためのボタンは、すべてのGitLabビューに表示されます。サイドバーで開き、GitLab全体を移動するときに開いたままにすることができます。

![新しいUIを備えたGitLab Duoボタン](img/paneled_view_duo_sidebar_v18_5.png)

### 詳細パネルでの作業アイテムのオープンが改善されました {#improved-opening-work-items-in-the-details-panel}

すでに[作業アイテムをドロワーで開く](project/issues/managing_issues.md#open-issues-in-a-drawer)ことができました。GitLabは、作業のコンテキストにより適した詳細パネルを使用するようになりました。

フルページビューでアイテムを開くには、次のいずれかの操作を行います:

- イシューまたはエピックページで、アイテムを右クリックして、新しいタブで開きます。
- アイテムを選択し、詳細パネルからID（たとえば、`myproject#123456`）を選択します。

十分な画面スペースがある場合、詳細パネルは、開いたリストまたはボードの横に開きます。画面が小さい場合、詳細パネルはリストまたはボードパネルの一部を覆います。

![パネルに表示されたイシューとイシューパネルを並べて表示](img/paneled_view_issue_drawer_v18_5.png)

![パネルの一部を覆うパネルに表示されたイシュー。](img/paneled_view_issue_drawer_overlap_v18_5.png)

#### パネルで作業アイテムを開くための設定 {#set-preference-for-opening-work-items-in-a-panel}

デフォルトでは、イシューやエピックなどの作業アイテムは詳細パネルで開きます。オフにする場合は:

1. 上部のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **Plan** > **イシュー**または**エピック**を選択します。
1. イシューまたはエピックページの上部にある**オプションの表示**（{{< icon name="preferences" >}}）を選択し、**サイドパネルにアイテムを開く**切り替えをオフにします。

設定は保存され、GitLab全体に適用されます。
