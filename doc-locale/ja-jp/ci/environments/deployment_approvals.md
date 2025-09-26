---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 保護環境へのデプロイの前に承認を必須にする
title: デプロイの承認
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

保護環境へのデプロイに対して、追加の承認を必須にすることができます。必須の承認がすべて与えられるまで、デプロイはブロックされます。

デプロイの承認を使用して、テスト、セキュリティ、またはコンプライアンスのプロセスに対応します。たとえば、本番環境へのデプロイには承認を必須にする場合があります。

## デプロイの承認を設定する {#configure-deployment-approvals}

プロジェクトの保護環境へのデプロイに対して承認を必須にすることができます。

前提要件:

- 環境を更新するには、メンテナーロール以上が必要です。

プロジェクトのデプロイの承認を設定するには、次のようにします。

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

   ジョブは手動（`when: manual`）である必要はありません。

1. 必要な[承認ルール](#add-multiple-approval-rules)を追加します。

これで、プロジェクト内の環境では、デプロイ前に承認を必要とするようになります。

### 複数の承認ルールを追加する {#add-multiple-approval-rules}

{{< history >}}

- GitLab 15.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/345678)になりました。[機能フラグ`deployment_approval_rules`](https://gitlab.com/gitlab-org/gitlab/-/issues/345678)は削除されました。
- GitLab 15.11でUIの設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378445)されました。

{{< /history >}}

複数の承認ルールを追加して、デプロイジョブを承認および実行できるユーザーを制御します。

複数の承認ルールを設定するには、[CI/CDの設定](protected_environments.md#protecting-environments)を使用します。[APIを使用することも](../../api/group_protected_environments.md#protect-a-single-environment)できます。

環境にデプロイするすべてのジョブはブロックされ、実行前に承認を待ちます。必要な承認の数が、デプロイを許可されたユーザー数よりも少なくなるようにしてください。

ユーザーは、複数の承認者グループのメンバーであっても、1回のデプロイにつき承認できるのは1回のみです。[イシュー457541](https://gitlab.com/gitlab-org/gitlab/-/issues/457541)では、この挙動を変更し、同じユーザーが異なる複数の承認者グループから、1回のデプロイに対して複数の承認を与えられるようにすることが提案されています。

デプロイが承認されたら、[ジョブを手動で実行する](../jobs/job_control.md#run-a-manual-job)必要があります。

### 自己承認を許可する {#allow-self-approval}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381418)されました。
- [ユーザビリティの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/391258)により、GitLab 16.2で自動承認は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124638)されました。

{{< /history >}}

デフォルトでは、デプロイパイプラインをトリガーするユーザーは、そのデプロイジョブを承認することができません。

GitLab管理者は、すべてのデプロイを承認または却下できます。

デプロイジョブの自己承認を許可するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **保護環境**を展開します。
1. **承認のオプション**で、**パイプラインのトリガー元にデプロイの承認を許可する**チェックボックスをオンにします。

## デプロイを承認または却下する {#approve-or-reject-a-deployment}

複数の承認ルールがある環境では、次のことができます。

- デプロイを承認して、続行を許可する。
- デプロイを却下して、阻止する。

前提要件:

- 保護環境にデプロイする権限が必要です。

デプロイを承認または却下するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 環境名を選択します。
1. デプロイを見つけて、その**ステータスバッジ**を選択します。
1. （オプション）デプロイの承認または却下の理由を説明するコメントを追加します。
1. **承認する**または**却下**を選択します。

[APIを使用する](../../api/deployments.md#approve-or-reject-a-blocked-deployment)こともできます。

複数の承認者グループのメンバーであっても、1回のデプロイにつき承認できるのは1回のみです。[イシュー457541](https://gitlab.com/gitlab-org/gitlab/-/issues/457541)では、この挙動を変更し、同じユーザーが異なる複数の承認者グループから、1回のデプロイに対して複数の承認を与えられるようにすることが提案されています。

対応するデプロイジョブは、デプロイが承認された後も自動的には実行されません。

### デプロイの承認の詳細を表示する {#view-the-approval-details-of-a-deployment}

前提要件:

- 保護環境にデプロイする権限が必要です。

保護環境へのデプロイは、必要なすべての承認が与えられた後にのみ続行できます。

デプロイの承認の詳細を表示するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 環境名を選択します。
1. デプロイを見つけて、その**ステータスバッジ**を選択します。

承認ステータスの詳細が表示されます。

- 適格な承認者
- 承認済みの数と必要な承認の数
- 承認を与えたユーザー
- 承認または却下の履歴

## ブロックされたデプロイを表示する {#view-blocked-deployments}

デプロイがブロックされているかどうかなど、デプロイのステータスを確認します。

デプロイを表示するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. デプロイ先の環境を選択します。

**ブロック済み**ラベルが付いたデプロイはブロックされています。

[APIを使用](../../api/deployments.md#get-a-specific-deployment)してデプロイを表示することもできます。`status`フィールドは、デプロイがブロックされているかどうかを示します。

## 関連トピック {#related-topics}

- [デプロイの承認機能に関するエピック](https://gitlab.com/groups/gitlab-org/-/epics/6832)
