---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabシークレットマネージャー
ignore_in_report: true
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16319)され、[フラグ](../../../development/feature_flags/_index.md) `secrets_manager`および`ci_tanukey_ui`とともに提供されました。デフォルトでは無効になっています。
- 機能フラグ`ci_tanukey_ui`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/549940)されました。
- GitLab 18.8で一部のユーザーがクローズドベータ版を利用できるようになりました。
- グループシークレットマネージャーが18.10で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17904)され、クローズドベータユーザーに[フラグ](../../../development/feature_flags/_index.md) `group_secrets_manager`とともに提供されました。
- GitLab 19.0でパブリックベータ版が[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21731)されました。

{{< /history >}}

シークレットは、CI/CDジョブが機能するために必要な機密情報を表します。シークレットには、アクセストークン、データベース認証情報、プライベートキーなどがあります。

ジョブにデフォルトで常に利用可能なCI/CD変数とは異なり、シークレットはジョブによって明示的にリクエストされなければなりません。

GitLabシークレットマネージャーを使用して、プロジェクトおよびグループのシークレットと認証情報を安全に保存および管理します。

GitLabシークレットマネージャーのパブリックベータ版は、**GitLab Premium and Ultimate**のお客様が利用できます。パブリックベータ版はGitLab.comまたはSelf-Managedインスタンスでオプトインできます。

## GitLab.comでのオプトイン {#opt-in-on-gitlabcom}

GitLab.comでは、トップレベルグループのオーナーが、そのグループのGitLabシークレットマネージャーをオプトインできます。トップレベルグループでオプトインすると、そのグループ内のすべてのサブグループおよびプロジェクトで利用可能になります。

前提条件: 

- トップレベルグループのオーナーロールが必要です。
- グループは**GitLab Premium or Ultimate**ティアである必要があります。

オプトインするには:

1. 左サイドバーで**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Secrets Manager**の切替をオンにします。

オプトイン後、グループおよびプロジェクトのオーナーは、サブグループおよびプロジェクトのシークレットマネージャーを個別に有効にできます。手順については、[Enable for a group or project](#enable-for-a-group-or-project)を参照してください。

## Self-Managedインスタンスでのオプトイン {#opt-in-on-self-managed}

Self-Managedインスタンスでは、まず管理者がインスタンスレベルでGitLabシークレットマネージャーをオプトインする必要があります。オプトイン後、オーナーは、自分のグループおよびプロジェクトでそれを有効にできます。

前提条件: 

- GitLabインスタンスへの管理者アクセス権が必要です。
- GitLab 19.0以降。
- OpenBaoがインストールおよび設定されている必要があります。詳細については、[administration](../../../administration/secrets_manager/_index.md)を参照してください。

オプトインするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 展開する**GitLabシークレットマネージャー**。
1. **Secrets Manager**の切替をオンにします。

オプトイン後、グループおよびプロジェクトのオーナーは、自分のネームスペースでシークレットマネージャーを有効にできます。手順については、[Enable for a group or project](#enable-for-a-group-or-project)を参照してください。

## グループまたはプロジェクトでの有効化 {#enable-for-a-group-or-project}

### プロジェクトの場合 {#for-a-project}

前提条件: 

- プロジェクトのオーナーロールが必要です。

プロジェクトでGitLabシークレットマネージャーを有効または無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **シークレットマネージャー**の切替をオンにして、シークレットマネージャーがプロビジョニングされるのを待ちます。

   > [!warning]
   > 後でプロジェクトのシークレットマネージャーを無効にすると、プロジェクトのすべてのシークレットは完全に削除されます。これらのシークレットは復元できません。

プロジェクト用に定義されたシークレットは、同じプロジェクトのパイプラインからのみアクセスできます。

### グループの場合 {#for-a-group}

前提条件: 

- グループのオーナーのロールを持っている必要があります。

グループでGitLabシークレットマネージャーを有効または無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **シークレットマネージャー**の切替をオンにして、シークレットマネージャーがプロビジョニングされるのを待ちます。

   > [!warning]
   > 後でグループのシークレットマネージャーを無効にすると、グループのすべてのシークレットは完全に削除されます。これらのシークレットは復元できません。

グループ用に定義されたシークレットは、グループ直下のプロジェクト、またはそのサブグループ階層内のパイプラインからのみアクセスできます。

## シークレットを定義する {#define-a-secret}

シークレットマネージャーにシークレットを追加して、セキュアなCI/CDパイプラインとワークフローに利用できます。

1. トップバーで**検索または移動先**を選択し、プロジェクトを見つけます
1. **セキュリティ** > **シークレットマネージャー**を選択します。
1. **シークレットを追加**を選択し、詳細を入力します:
   - **Name**: プロジェクト内で一意である必要があります。
   - **値**: 10 KB（10,000バイト）以下である必要があります。
   - **説明**: 最大200文字。
   - **環境**: 設定できる項目:
     - **すべて (デフォルト)** (`*`)
     - 特定の[環境](../../environments/_index.md#types-of-environments)。
     - ワイルドカード[環境](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。
   - **ブランチ**: プロジェクトの設定でのみ存在するオプションです。設定できる項目:
     - 特定のブランチ。
     - ワイルドカードブランチ（`*`文字を含む必要があります）。
   - **保護**: グループの設定でのみ存在するオプションです。オプション。エクスポートするシークレットを保護ブランチで実行されているパイプラインにのみ。
   - **ローテーションのリマインダー**: オプション。設定された日数が経過した後、シークレットをローテーションするようメールリマインダーを送信します。最低7日間。

シークレットを作成した後、それをパイプラインの設定またはジョブスクリプトで使用できます。

> [!warning]
> シークレットの値は、シークレットが作成または更新されたときに定義された特定の環境またはブランチで実行されているすべてのCI/CDパイプラインジョブからアクセス可能です。これらのシークレットの値にアクセスする権限を持つユーザーのみが、指定された環境またはブランチのジョブを実行できるようにしてください。

## ジョブスクリプトでシークレットを使用する {#use-secrets-in-job-scripts}

### プロジェクトのシークレットの場合 {#for-project-secrets}

前提条件: 

- GitLab Runner 19.0以降。

シークレットマネージャーで定義されたシークレットにアクセスするには、[`secrets`](../../yaml/_index.md#secrets)および`gitlab_secrets_manager`キーワードを使用します。

[ファイルタイプの変数](../../variables/_index.md#use-file-type-cicd-variables)と同様に、シークレットは次の環境変数として利用可能になります:

- シークレットのキーを環境変数名として使用します。
- シークレットの値は一時ファイルに保存されます。マスクされた変数とは異なり、シークレットにはスペースや改行を含めることができます。
- その一時ファイルのパスは環境変数値として扱われる。

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

もしジョブがシークレットの値を出力する場合（例えば`cat $KUBE_CA_PEM`を実行することによって）、GitLabはジョブログ内の値を`[MASKED]`に置き換えます。

### グループのシークレットの場合 {#for-group-secrets}

前提条件: 

- GitLab Runner 19.0以降。

グループシークレットにアクセスするには:

- [`secrets`](../../yaml/_index.md#secrets)および`gitlab_secrets_manager`キーワードを使用します。
- シークレットマネージャーのソースを`source`フィールドで`group/<full-path-to-group>`の形式で指定します。

例: 

```yaml
job:
  secrets:
    TEST_SECRET:
      gitlab_secrets_manager:
        name: foo
        source: group/<full-path-to-group>
  script:
   - cat $TEST_SECRET
```

## シークレットの権限を管理する {#manage-secrets-permissions}

### プロジェクトの場合 {#for-a-project-1}

前提条件: 

- プロジェクトのオーナーロールを持つユーザーは、シークレットの権限を管理できます。
- プロジェクトのメンテナーロールを持つユーザーは、定義された権限を表示できます。
- プロジェクトでシークレットマネージャーが有効になっている必要があります。

プロジェクトのシークレットの権限を更新するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **シークレットマネージャー**の下の**シークレットマネージャーのユーザー権限**セクションで、ユーザー権限を管理できます:
   - **追加**を選択して、特定のユーザー、グループ、またはロールの権限ルールを追加します。
   - 権限スコープを読み取り、書き込み（作成および更新）、およびシークレットの削除に設定できます。

### グループの場合 {#for-a-group-1}

前提条件: 

- グループのオーナーロールを持つユーザーは、シークレットの権限を管理できます。グループのオーナーロールを持つユーザーのみが、定義された権限を表示できます。
- グループでシークレットマネージャーが有効になっている必要があります。

グループのシークレットの権限を更新するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **シークレットマネージャー**の下の**シークレットマネージャーのユーザー権限**セクションで、ユーザー権限を管理できます:
   - **追加**を選択して、特定のユーザー、グループ、またはロールの権限ルールを追加します。
   - 権限スコープを読み取り、書き込み（作成および更新）、およびシークレットの削除に設定できます。

グループのオーナーロールを持つユーザーは、シークレットマネージャーでのすべての操作を実行する権限を常に持っています。

## プロジェクトまたはグループの削除 {#deletion-of-a-project-or-group}

[プロジェクトを削除](../../../user/project/working_with_projects.md#delete-a-project)または[グループを削除](../../../user/group/_index.md#schedule-a-group-for-deletion)すると、シークレットとともに:

- プロジェクトまたはグループのシークレットマネージャーは無効になり、シークレットストレージエンジンから削除されます。
- すべてのシークレットは完全に削除されます。

## プロジェクトまたはグループの転送 {#transfer-of-a-project-or-group}

[プロジェクトを転送](../../../user/project/working_with_projects.md#transfer-a-project)または[グループを転送](../../../user/group/manage.md#transfer-a-group)すると、シークレットとともに:

- プロジェクトまたはグループ用に定義されたシークレットは、新しいネームスペースのプロジェクトまたはグループには転送されません。
- プロジェクトまたはグループのシークレットマネージャーは無効になり、シークレットストレージエンジンから削除されます。
- すべてのシークレットは完全に削除されます。

## シークレットのローテーション通知 {#secret-rotation-notifications}

プロジェクトのオーナーロールを持つユーザーは、シークレットの設定で指定された日にシークレットをローテーションするようメール通知を受け取ります。

## 一般公開時の価格設定 {#pricing-at-general-availability}

GitLabシークレットマネージャーはオープンベータ期間中は無料ですが、一般公開されるとGitLabクレジットを消費します。サービスの中断を避けるため、一般公開前にGitLabクレジットのオンデマンド課金をオプトインする時間を与えるため、ご連絡いたします。

## フィードバックを提供する {#provide-feedback}

パブリックベータ期間中にフィードバックを共有したり、イシューを報告したりするには、[GitLabシークレットマネージャー: パブリックベータ版での顧客フィードバック](https://gitlab.com/gitlab-org/gitlab/-/work_items/598100)イシュー。

## トラブルシューティング {#troubleshooting}

### エラー: `reading from Vault: api error: status code 403` {#error-reading-from-vault-api-error-status-code-403}

CI/CDパイプラインジョブがシークレットをフェッチするのを試みるとき、このエラーが返される可能性があります:

```plaintext
ERROR: Job failed (system failure): resolving secrets: getting secret: get secret data: reading from Vault: api error: status code 403: 1 error occurred: * permission denied
```

このエラーは、ジョブが存在しないか削除されたシークレットをフェッチするのを試みたときに発生します。

### エラー: `inline auth JWT is required` {#error-inline-auth-jwt-is-required}

CI/CDパイプラインジョブがシークレットをフェッチするのを試みるとき、このエラーが返される可能性があります:

```plaintext
ERROR: Job failed (system failure): resolving secrets: creating vault client: configuring inline auth: inline auth JWT is required
```

このエラーは、シークレットが属すると予想されるプロジェクトまたはグループに対して、シークレットマネージャーインスタンスがまだプロビジョニングされていない場合に発生します。Runnerは、シークレットマネージャーロールがまだ存在しないため、認証を設定できません。

このエラーを解決するには、プロジェクトまたはグループで[Secrets Managerを有効化](#enable-for-a-group-or-project)します。

プロビジョニングが完了するのを待ち、シークレットを作成してからパイプラインを再実行してください。
