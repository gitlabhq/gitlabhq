---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: お使いのGitLabインスタンスのマージリクエストの承認を設定します。
title: マージリクエストの承認
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストの承認ルールは、ユーザーが特定のプロジェクト設定をオーバーライドすることを防ぎます。有効にすると、これらの設定は、インスタンス内の[すべてのプロジェクトとグループに適用されます](../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)。

これらのマージリクエストの承認設定は、インスタンス全体に対して設定できます:

- **マージリクエストの作成者による承認を防止する**。プロジェクトメンテナーが、マージリクエストの作成者自身に自分のマージリクエストを承認させることを防ぎます。
- **コミットを追加したユーザーによる承認を防ぎます。** プロジェクトメンテナーが、ソースブランチにコミットを送信したユーザーに、マージリクエストの承認を許可することを防ぎます。
- **プロジェクトとマージリクエストの承認ルールの編集を防止**。ユーザーがプロジェクト設定または個々のマージリクエストで承認者リストを変更することを防ぎます。

以下もインスタンス全体のルールによって影響を受けます:

- [プロジェクトマージリクエストの承認ルール](../user/project/merge_requests/approvals/_index.md)。
- [グループマージリクエストの承認設定](../user/group/manage.md#group-merge-request-approval-settings)

## インスタンスのマージリクエスト承認設定を有効にする {#enable-merge-request-approval-settings-for-an-instance}

これを行うには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **プッシュルール**を選択します。
1. **マージリクエストの承認**を展開します。
1. いずれかの承認ルールのチェックボックスを選択します。
1. **変更を保存**を選択します。
