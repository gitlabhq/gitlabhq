---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Members APIに対するレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140633)されました。

{{< /history >}}

[delete members API](../../api/members.md#remove-a-member-from-a-group-or-project)に対する、グループ（またはプロジェクト）ごと、ユーザーごとのレート制限を設定できます。

レート制限を変更するには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **メンバーAPIのレート制限**を展開します。
1. **グループまたはプロジェクトあたりの一分あたりの最大リクエスト数**テキストボックスに、新しい値を入力します。
1. **変更を保存**を選択します。

レート制限:

- グループごと、またはプロジェクトごと、ユーザーごとに適用されます。
- 0に設定すると、レート制限を無効にできます。

レート制限のデフォルト値は`60`です。

レート制限を超えるリクエストは、`auth.log`ファイルに記録されます。

たとえば、制限を60に設定した場合、[delete members API](../../api/members.md#remove-a-member-from-a-group-or-project)に送信されるリクエストは、1分あたり300回のレート制限を超えると、ブロックされます。エンドポイントへのアクセスは、1分後に許可されます。
