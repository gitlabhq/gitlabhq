---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシューとエピックの作成に関するレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

レート制限は、新しいエピックとイシューが作成されるペースを制御します。たとえば、制限を`300`に設定すると、[`Projects::IssuesController#create`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/controllers/projects/issues_controller.rb)アクションは、1分あたり300回のレートを超えるリクエストをブロックします。エンドポイントへのアクセスは、1分後に利用可能になります。

## レート制限を設定する {#set-the-rate-limit}

イシューとエピックの作成エンドポイントに対して行われるリクエストの数を制限するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Issues Rate Limits**（イシューレート制限）を展開します。
1. **Max requests per minute**（1分あたりの最大リクエスト数）に、新しい値を入力します。
1. **変更を保存**を選択します。

![1分あたりの最大リクエスト数のレート制限（ユーザーあたり300に設定）。](img/rate_limit_on_issues_creation_v14_2.png)

[エピック](../../user/group/epics/_index.md)の作成制限は、イシューの作成に適用される制限と同じです。レート制限:

- プロジェクトごと、ユーザーごとに個別に適用されます。
- IPアドレスごとには適用されません。
- レート制限を無効にするには、`0`に設定します。

レート制限を超えるリクエストは、`auth.log`ファイルに記録されます。
