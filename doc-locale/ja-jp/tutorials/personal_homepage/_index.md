---
stage: Growth
group: Engagement
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'チュートリアル: パーソナルホームページを使用する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.1で`personal_homepage`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/546151)されました。デフォルトでは無効になっています。
- [GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/554048)で、GitLab 18.4の一部ユーザーに対して有効化されました。
- [GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/17932)で有効になったのは、GitLab 18.5です。

{{< /history >}}

<!-- vale gitlab_base.FutureTense = NO -->

パーソナルホームページは、あなたに関連するすべての情報を1か所に集約します。注意が必要な新しい作業アイテムをすばやく特定したり、中断したところから再開したりできます。

このチュートリアルに沿って、ホームページの操作方法を学び、最大限に活用する方法を学びましょう。

## はじめる前 {#before-you-begin}

[パーソナルホームページ](../../user/profile/preferences.md#choose-your-homepage)を、環境設定のデフォルトのホームページとして設定します。

## ホームページへのアクセス {#access-the-homepage}

GitLabのどこからでもパーソナルホームページにアクセスできます:

- 左側のサイドバーの上部にある**ホームページ**を選択します。
- 左側のサイドバーで、**検索または移動先**を選択し、**あなたの作業**を選択し、次に**ホーム**を選択します。

## ホームページのレイアウト {#layout-of-the-homepage}

上部付近で、アバターを選択してステータスを設定します。ステータスを設定すると、アバターにステータスバッジと絵文字が表示され、カーソルを合わせるとステータステキストが表示されます。

アバターの下に、あなたが関与しているマージリクエストとイシューの数が表示されます。

**Items that need your attention**（注意が必要なアイテム）リストには、GitLab全体のあなたの入力を必要とするすべての作業アイテムが表示されます。

**Follow the latest updates**（最新の更新をフィードする）には、GitLab全体のアクティビティーと、関心のある特定のプロジェクトとユーザーのアクティビティーが表示されます。

ホームページの右側に移動して、最近表示したもののリストを取得します。

## ホームページを使用して1日を始める {#use-the-homepage-to-start-your-day}

いくつかの方法について説明しましょう。ホームページを使用して、その日の作業を開始できます:

1. **Items that need your attention**（注意が必要なアイテム）リストのフィルターを使用して、あなたにとって最も重要なイベントを表示します。たとえば、失敗したパイプラインが原因でブロックされているマージリクエストを確認するには、フィルタードロップダウンリストから**ビルド失敗**を選択します。
1. ホームページの上部付近で、**あなたのレビューが必要なマージリクエスト数**を選択して、あなたのレビューが必要なマージリクエストを表示し、他のユーザーのブロックを解除できるようにします。

たとえば、作業中の内容を追跡することもできます:

1. **Follow the latest updates**（最新の更新をフィードする）セクションで、**アクティビティー**フィルターを使用して、最近の作業を表示します。リンクを選択してイシューまたはマージリクエストに直接移動し、中断したところから再開します。
1. **最近表示したもの**セクションのリンクを選択して、作業を開始したアイテムに戻ります。

## チームアクティビティーとの接続を維持する {#stay-connected-with-team-activity}

プロジェクトで共同作業を行っている場合は、プロジェクトにStar付きを追加すると、将来簡単に見つけられるようになります。次に、ホームページを使用して、そのプロジェクトで何が起こっているかの概要を把握します。

プロジェクトにStar付きを追加して、ホームページでそのアクティビティーを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. ページの右上隅にある**Star付き** ({{< icon name="star" >}})を選択します。
1. 左側のサイドバーの上部にある**ホームページ**を選択します。
1. **Follow the latest updates**（最新の更新をフィードする）セクションで、ドロップダウンリストから**Star付きのプロジェクト**を選択します。

チームとより効果的に共同作業を行うために、他のGitLabユーザーをフォローして、彼らが何に取り組んでいるかを確認できます:

1. たとえば、`https://gitlab.example.com/username`のGitLabでユーザーのプロファイルに移動し、**フォローする**を選択します。または、GitLabのどこかで名前の上にカーソルを合わせると表示される小さなポップオーバーで、**フォローする**を選択します。
1. 左側のサイドバーの上部にある**ホームページ**を選択します。
1. **Follow the latest updates**（最新の更新をフィードする）セクションで、ドロップダウンリストから**フォロー中のユーザー**を選択します。

## 関連トピック {#related-topics}

ホームページから表示およびアクセスできるさまざまな作業アイテムについて、詳細をご覧ください。

- [To-Doリスト](../../user/todos.md)
- [マージリクエスト](../../user/project/merge_requests/_index.md)
- [イシュー](../../user/project/issues/_index.md)
