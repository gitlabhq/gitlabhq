---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ノート作成のレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ノート作成エンドポイントへのリクエストに対する、ユーザーごとのレート制限を構成できます。

ノート作成レート制限を変更するには、次の手順に従ってください:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Notes rate limit**（ノートレート制限）を展開します。
1. **1分あたりの最大リクエスト数**ボックスに、新しい値を入力します。
1. オプション。**レート制限から除外するユーザー**ボックスに、制限を超過することを許可するユーザーをリスト表示します。
1. **変更を保存**を選択します。

この制限は次のとおりです:

- ユーザーごとに個別に適用されます。
- IPアドレスごとには適用されません。

デフォルト値は`300`です。

レート制限を超えたリクエストは、`auth.log`ファイルに記録されます。

たとえば、300の制限を設定した場合、[`Projects::NotesController#create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/notes_controller.rb)アクションを使用するリクエストは、1分あたり300のレート制限を超えるとブロックされます。エンドポイントへのアクセスは、1分後に許可されます。
