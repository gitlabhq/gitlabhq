---
stage: Security Platform
group: Secrets Manager Application
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secrets Manager
ignore_in_report: true
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16319)され、[機能フラグ](../../../development/feature_flags/_index.md) `secrets_manager`と`ci_tanukey_ui`とともに利用できます。デフォルトでは無効になっています。
- 機能フラグ`ci_tanukey_ui`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/549940)されました。
- GitLab 18.8で一部のユーザーがクローズドベータ版を利用できるようになりました。
- グループのシークレットマネージャーは18.10で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17904)され、クローズドベータユーザー向けに[機能フラグ](../../../development/feature_flags/_index.md) `group_secrets_manager`とともに利用可能になりました。
- GitLab 19.0でクローズドベータからパブリックベータに[変更](https://gitlab.com/groups/gitlab-org/-/work_items/21731)されました。

{{< /history >}}

シークレットとは、CI/CDジョブが機能するために必要な機密情報を指します。シークレットには、アクセストークン、データベース認証情報、秘密キーなどがあります。

デフォルトで常にジョブが利用できるCI/CD変数とは異なり、シークレットはジョブから明示的にリクエストする必要があります。

GitLab Secrets Managerを使用すると、プロジェクトおよびグループのシークレットと認証情報を安全に保存、管理できます。

GitLab Secrets Managerは、パブリックベータ期間中は無料ですが、一般提供されるとGitLabクレジットを消費します。サービスの中断を避けるため、一般提供の前に通知が届き、オンデマンドのGitLabクレジット課金をオプトインする時間が与えられます。

クリックスルーデモについては、[GitLab Secrets Manager](https://click-through-demo-generator-27bd12.gitlab.io/demos/demo-20260506-094904/)を参照してください。
<!-- Demo published on 2026-05-27 -->

パブリックベータ期間中のフィードバックは、[イシュー598100](https://gitlab.com/gitlab-org/gitlab/-/work_items/598100)で共有してください。

## GitLab Secrets Managerを有効にする {#enable-gitlab-secrets-manager}

シークレットマネージャーがトップレベルグループで有効になっている場合、そのグループ内のすべてのサブグループとプロジェクトでも利用できます。

GitLab Self-Managedでは、管理者がまず[GitLab Secrets Managerをインストールして有効にする](../../../administration/secrets_manager/_index.md)必要があります。シークレットマネージャーがインストールされ有効になった後、インスタンス上で特定のグループおよびプロジェクトに対して有効にすることができます。

### プロジェクトの場合 {#for-a-project}

前提条件: 

- プロジェクトのオーナーロールが必要です。

プロジェクトでGitLab Secrets Managerを有効または無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **シークレットマネージャー**切替をオンにして、シークレットマネージャーがプロビジョニングされるまで待ちます。

   > [!warning]
   > 後でプロジェクトのSecrets Managerを無効にすると、そのプロジェクトのシークレットはすべて完全に削除されます。これらのシークレットは復元できません。

プロジェクトに定義されたシークレットには、同じプロジェクトのパイプラインからのみアクセスできます。

### グループの場合 {#for-a-group}

前提条件: 

- グループのオーナーのロールを持っている必要があります。

グループでGitLab Secrets Managerを有効または無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **シークレットマネージャー**切替をオンにして、シークレットマネージャーがプロビジョニングされるまで待ちます。

   > [!warning]
   > 後でグループのSecrets Managerを無効にすると、そのグループのシークレットはすべて完全に削除されます。これらのシークレットは復元できません。

グループに定義されたシークレットには、そのグループ直下のプロジェクト、またはそのサブグループ階層内のプロジェクトのパイプラインからのみアクセスできます。

## シークレットを定義する {#define-a-secret}

シークレットマネージャーにシークレットを追加すると、安全なCI/CDパイプラインおよびワークフローで使用できます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **シークレットマネージャー**を選択します。
1. **シークレットを追加**を選択し、詳細を入力します:
   - **Name**: プロジェクト内で一意である必要があります。
   - **値**: 10 KB（10,000バイト）以下である必要があります。
   - **説明**: 最大200文字までです。
   - **環境**: 次のいずれかを指定できます:
     - **すべて（デフォルト）**（`*`）
     - 特定の[環境](../../environments/_index.md#types-of-environments)。
     - [ワイルドカード環境](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。
   - **ブランチ**: このオプションはプロジェクトの設定にのみ存在します。次のいずれかを指定できます:
     - 特定のブランチ。
     - ワイルドカードブランチ（`*`文字を含める必要があります）。
   - **保護**: このオプションはグループの設定にのみ存在します。オプション。保護ブランチで実行されるパイプラインにのみシークレットをエクスポートします。
   - **ローテーションのリマインダー**: オプション。設定した日数が経過した後、シークレットのローテーションを促すメールリマインダーを送信します。最小値は7日です。

シークレットを作成した後、パイプライン設定またはジョブスクリプトで使用できます。

> [!warning]
> シークレットの値には、そのシークレットの作成時または更新時に定義された特定の環境またはブランチで実行されるすべてのCI/CDパイプラインジョブからアクセスできます。これらのシークレットの値にアクセスする権限を持つユーザーのみが、指定した環境またはブランチのジョブを実行できることを確認してください。

## ジョブスクリプトでシークレットを使用する {#use-secrets-in-job-scripts}

デフォルトでは、[ファイルタイプのCI/CD変数](../../variables/_index.md#use-file-type-cicd-variables)と同様に、シークレットは関連する環境変数を持つファイルとしてジョブ内で利用可能になります:

- そのシークレットのキーは、環境変数名です。
- そのシークレットの値は一時ファイルに保存されます。マスクされたCI/CD変数とは異なり、シークレットにはスペースや改行を含めることができます。
- 一時ファイルへのパスは、環境変数の値です。

シークレットをジョブスクリプト内で、ファイルを入力として受け入れるコマンドとともに使用するか、またはオプションで直接[シークレットを環境変数として使用](#use-a-secret-as-an-environment-variable-with-file-false)します。

ジョブがシークレットの値を出力する場合、GitLabはジョブログ内の値を`[MASKED]`に置き換えます。

### プロジェクトシークレットの場合 {#for-project-secrets}

前提条件: 

- GitLab Runner 19.0以降。

プロジェクトのシークレットマネージャーに保存されているシークレットにアクセスするには、[`secrets`](../../yaml/_index.md#secrets)と`gitlab_secrets_manager`キーワードを使用します。

例: 

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube-cert
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

### グループシークレットの場合 {#for-group-secrets}

前提条件: 

- GitLab Runner 19.0以降。

グループのシークレットマネージャーに保存されているシークレットにアクセスするには:

- [`secrets`](../../yaml/_index.md#secrets)キーワードと`gitlab_secrets_manager`キーワードを使用します。
- グループをシークレットマネージャーのソースとして、`source`フィールドに`group/<full-path-to-group>`の形式で指定します。

例: 

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube-cert
        source: group/my-group/my-subgroup
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

### シークレットを`file: false`で環境変数として使用する {#use-a-secret-as-an-environment-variable-with-file-false}

シークレットを環境変数として使用し、ファイルに保存しない場合は、シークレットに`file: false`を設定します。例: 

```yaml
job:
  secrets:
    DEPLOY_SECRET:
      gitlab_secrets_manager:
        name: deploy-credentials
      file: false
  script:
    - my_deploy_command --user username --pass $DEPLOY_SECRET
```

この例では、シークレットはジョブに対して`DEPLOY_SECRET`変数として利用可能になり、他のどの環境変数と同様に使用できます。

## シークレットの権限を管理する {#manage-secrets-permissions}

### プロジェクトの場合 {#for-a-project-1}

前提条件: 

- シークレットの権限を管理するには、プロジェクトのオーナーロールが必要です。
- プロジェクトのメンテナーロールを持つユーザーは、定義済みの権限を表示できます。
- プロジェクトでSecrets Managerが有効になっている必要があります。

プロジェクトのシークレットの権限を更新するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **シークレットマネージャー**の下にある**シークレットマネージャーのユーザー権限**セクションで、ユーザー権限を管理できます:
   - 特定のユーザー、グループ、またはロールの権限ルールを追加するには、**追加**を選択します。
   - シークレットに対して、読み取り、書き込み（作成および更新）、削除の権限スコープを設定できます。

### グループの場合 {#for-a-group-1}

前提条件: 

- シークレットの権限を管理するには、グループのオーナーロールが必要です。グループのオーナーロールを持つユーザーのみが、定義済みの権限を表示できます。
- グループでSecrets Managerが有効になっている必要があります。

グループのシークレットの権限を更新するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **シークレットマネージャー**の下にある**シークレットマネージャーのユーザー権限**セクションで、ユーザー権限を管理できます:
   - 特定のユーザー、グループ、またはロールの権限ルールを追加するには、**追加**を選択します。
   - シークレットに対して、読み取り、書き込み（作成および更新）、削除の権限スコープを設定できます。

グループのオーナーロールを持つユーザーには、Secrets Managerにおけるすべての操作の実行権限が常に付与されます。

## プロジェクトまたはグループを削除する {#deletion-of-a-project-or-group}

シークレットを含む[プロジェクトを削除](../../../user/project/working_with_projects.md#delete-a-project)または[グループを削除](../../../user/group/_index.md#schedule-a-group-for-deletion)すると、次の処理が行われます:

- プロジェクトまたはグループのシークレットマネージャーが無効になり、シークレットストレージエンジンから削除されます。
- すべてのシークレットが完全に削除されます。

## プロジェクトまたはグループを転送する {#transfer-of-a-project-or-group}

シークレットを含む[プロジェクトを転送](../../../user/project/working_with_projects.md#transfer-a-project)または[グループを転送](../../../user/group/manage.md#transfer-a-group)すると、次の処理が行われます:

- プロジェクトまたはグループに定義されたシークレットは、新しいネームスペースのプロジェクトまたはグループには転送されません。
- プロジェクトまたはグループのシークレットマネージャーが無効になり、シークレットストレージエンジンから削除されます。
- すべてのシークレットが完全に削除されます。

## シークレットのローテーション通知 {#secret-rotation-notifications}

プロジェクトのオーナーロールを持つユーザーは、シークレットの設定で指定された日に、シークレットのローテーションを促すメール通知を受け取ります。

## CI/CD以外のワークロードからシークレットにアクセスする {#access-secrets-from-non-cicd-workloads}

GitLab CI/CDのジョブとして実行されないワークロードは、シークレットマネージャーAPIを通じてシークレットを読み取ることができます。詳細については、[CI/CD以外のワークロードからシークレットにアクセスする](non_cicd_access.md)を参照してください。

## 関連トピック {#related-topics}

- [シークレット監査ツール（変数用）](https://gitlab.com/guided-explorations/secrets-management/secret-audit-tool-for-variables): GitLabのグループ階層をスキャンし、名前に認証情報（パスワード、トークン、APIキーなど）が含まれている可能性のあるCI/CD変数を探すコミュニティツールです。GitLab Secrets Managerに移行する変数を特定するのに役立つHTMLレポートを生成します。

## トラブルシューティング {#troubleshooting}

### エラー: `reading from Vault: api error: status code 403` {#error-reading-from-vault-api-error-status-code-403}

CI/CDパイプラインジョブがシークレットをフェッチしようとすると、このエラーが返されることがあります:

```plaintext
ERROR: Job failed (system failure): resolving secrets: getting secret: get secret data: reading from Vault: api error: status code 403: 1 error occurred: * permission denied
```

このエラーは、ジョブが存在しない、または削除済みのシークレットをフェッチしようとした場合に発生します。

### エラー: `inline auth JWT is required` {#error-inline-auth-jwt-is-required}

CI/CDパイプラインジョブがシークレットをフェッチしようとすると、このエラーが返されることがあります:

```plaintext
ERROR: Job failed (system failure): resolving secrets: creating vault client: configuring inline auth: inline auth JWT is required
```

このエラーは、シークレットが属すると想定されるプロジェクトまたはグループに対して、シークレットマネージャーインスタンスがまだプロビジョニングされていない場合に発生します。シークレットマネージャーロールがまだ存在しないため、Runnerが認証を設定できません。

このエラーを解決するには、プロジェクトまたはグループでシークレットマネージャーを有効にしてください。

プロビジョニングが完了するまで待ち、シークレットを作成してからパイプラインを再実行してください。
