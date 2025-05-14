---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Require approvals prior to deploying to a Protected Environment
title: デプロイの承認
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

保護環境へのデプロイに対して追加の承認を要求できます。必要な承認がすべて与えられるまでデプロイはブロックされます。

デプロイの承認を使用して、テスト、セキュリティ、またはコンプライアンスのプロセスに対応します。たとえば、本番環境へのデプロイに承認を要求することができます。

## デプロイの承認を設定する

プロジェクトの保護環境へのデプロイに対して承認を要求できます。

前提要件:

- 環境を更新するには、メンテナーロール以上が必要です。

プロジェクトのデプロイの承認を設定するには:

1. プロジェクトの`.gitlab-ci.yml`ファイルにデプロイジョブを作成します。

   ```yaml
   stages:
     - deploy

   production:
     stage: deploy
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
       action: start
   ```

   ジョブは手動である必要はありません（`when: manual`）。

1. 必要な[承認ルール](#add-multiple-approval-rules)を追加します。

プロジェクトの環境では、デプロイ前に承認が必要になります。

### 複数の承認ルールを追加する

{{< history >}}

- GitLab 15.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/345678)になりました。[`deployment_approval_rules`機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/345678)が削除されました。
- GitLab 15.11でUIの設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378445)されました。

{{< /history >}}

複数の承認ルールを追加して、デプロイジョブを承認および実行できるユーザーを制御します。

複数の承認ルールを設定するには、[CI/CDの設定](protected_environments.md#protecting-environments)を使用します。[APIを使用する](../../api/group_protected_environments.md#protect-a-single-environment)こともできます。

環境にデプロイするすべてのジョブはブロックされ、実行前に承認を待ちます。必要な承認の数がデプロイを許可されているユーザーの数よりも少なくなるようにしてください。

デプロイが承認されたら、[ジョブを手動で実行する](../jobs/job_control.md#run-a-manual-job)必要があります。

### 自己承認を許可する

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381418)されました。
- [ユーザビリティの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/391258)により、GitLab 16.2で自動承認は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124638)されました。

{{< /history >}}

デフォルトでは、デプロイパイプラインをトリガーするユーザーは、デプロイジョブを承認することができません。

GitLab管理者は、すべてのデプロイを承認または却下できます。

デプロイジョブの自己承認を許可するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **保護環境**を展開します。
1. **承認のオプション**で、**パイプラインのトリガー元にデプロイの承認を許可する**チェックボックスをオンにします。

## デプロイを承認または却下する

複数の承認ルールがある環境では、次のことができます。

- デプロイを承認して続行できるようにする。
- デプロイを却下してデプロイできないようにする。

前提要件:

- 保護環境にデプロイする権限が必要です。

デプロイを承認または却下するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 環境の名前を選択します。
1. デプロイを見つけて、その**状態バッジ**を選択します。
1. オプション。デプロイの承認理由または却下理由を説明するコメントを追加します。
1. **承認する**または**却下**を選択します。

[APIを使用する](../../api/deployments.md#approve-or-reject-a-blocked-deployment)こともできます。

デプロイが承認された後、対応するデプロイジョブは自動的に実行されません。

### デプロイの承認の詳細を表示する

前提要件:

- 保護環境にデプロイする権限が必要です。

保護環境へのデプロイは、必要なすべての承認が与えられた後にのみ続行できます。

デプロイの承認の詳細を表示するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 環境の名前を選択します。
1. デプロイを見つけて、その**状態バッジ**を選択します。

承認状態の詳細が表示されます。

- 承認対象者
- 与えられた承認の数と必要な承認の数
- 承認を与えたユーザー
- 承認または却下の履歴

## ブロックされたデプロイを表示する

デプロイがブロックされているかどうかなど、デプロイの状態を確認します。

デプロイを表示するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. デプロイ先の環境を選択します。

**ブロック済み**ラベルが付いたデプロイはブロックされています。

デプロイを表示するために、[APIを使用する](../../api/deployments.md#get-a-specific-deployment)こともできます。`status`フィールドは、デプロイがブロックされているかどうかを示します。

## 関連トピック

- [デプロイの承認機能エピック](https://gitlab.com/groups/gitlab-org/-/epics/6832)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
