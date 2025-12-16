---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Phorge
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863)されました。

{{< /history >}}

GitLabで[Phorge](https://we.phorge.it/)を[外部イシュートラッカー](../../../integration/external-issue-tracker.md)として使用できます。

## インテグレーションを設定する {#configure-the-integration}

GitLabプロジェクトでPhorgeを設定するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Phorge**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **プロジェクトのURL**に、PhorgeプロジェクトのURLを入力します。
1. **イシューのURL**に、PhorgeプロジェクトのイシューのURLを入力します。URLには`:id`が含まれている必要があります。GitLabはこのトークンをManiphestタスクID (`T123`など) に置き換えます。
1. **新しいイシューのURL**に、新しいPhorgeプロジェクトイシューのURLを入力します。このプロジェクトに関連するタグを事前入力するには、`?tags=`を使用します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

そのGitLabプロジェクトで、Phorgeプロジェクトへのリンクを確認できます。GitLabでPhorgeイシューとタスクを`T<ID>`で参照できるようになりました。ここで、`<ID>`はManiphestタスクID (`T123`など) です。
