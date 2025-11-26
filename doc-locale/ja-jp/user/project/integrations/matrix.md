---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Matrix
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/)されました。

{{< /history >}}

GitLabを設定して、Matrixルームに通知を送信できます。

## GitLabでMatrixインテグレーションを設定する {#set-up-the-matrix-integration-in-gitlab}

Matrixルームに参加した後、GitLabを設定して通知を送信できます:

1. インテグレーションを有効にするには、次のようにします:
   - **For your group or project**（グループまたはプロジェクトの場合）:
     1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
     1. **設定** > **インテグレーション**を選択します。
   - **For your instance**（インスタンス）の場合:
     1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
     1. **設定** > **インテグレーション**を選択します。
1. **Matrix**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. オプション。**ホスト名**に、サーバーのホスト名を入力します。
1. **パイプライントークン**に、Matrixのユーザーからのトークン値を貼り付けます。
1. **トリガー**セクションで、Matrixで受信するGitLabイベントのチェックボックスを選択します。
1. **通知設定**セクションで、次のことを行います:
   - **Room identifier**（ルーム識別子）に、Matrixルームの識別子を貼り付けます。
   - オプション。**壊れたパイプラインのみ通知**チェックボックスをオンにして、失敗したパイプラインの通知のみを受信します。
   - オプション。**通知を送信するブランチ**ドロップダウンリストから、通知を受信するブランチを選択します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Matrixルームは、選択されたすべてのGitLabイベントを受信できるようになりました。
