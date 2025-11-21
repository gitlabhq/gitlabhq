---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: タイムアウトの設定、機密情報の保護、タグと変数による動作の制御、およびGitLab Runnerのアーティファクトとキャッシュの設定を行います。
title: Runnerの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、GitLab UIでRunnerを設定する方法について説明します。

GitLab RunnerをインストールしたマシンでRunnerを設定する必要がある場合は、[GitLab Runnerのドキュメント](https://docs.gitlab.com/runner/configuration/)を参照してください。

## ジョブの最大タイムアウトを設定する {#set-the-maximum-job-timeout}

各Runnerにジョブの最大タイムアウトを指定することで、ジョブのタイムアウトが最大タイムアウトよりも長いプロジェクトでRunnerを使用できないようにすることができます。ジョブの最大タイムアウトは、プロジェクトで定義されたジョブのタイムアウトよりも短い場合に適用されます。

Runnerの最大タイムアウトを設定するには、REST APIエンドポイント[`PUT /runners/:id`](../../api/runners.md#update-runners-details)の`maximum_timeout`パラメータを設定します。

### インスタンスRunnerの場合 {#for-an-instance-runner}

前提要件: 

- 管理者である必要があります。

GitLab Self-ManagedのインスタンスRunnerのジョブタイムアウトは、オーバーライドできます。

GitLab.comでは、GitLabでホストされるインスタンスRunnerのジョブタイムアウトをオーバーライドできません。代わりに、[プロジェクトで定義されたタイムアウト](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)を使用する必要があります。

ジョブの最大タイムアウトを設定するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、左側のサイドバーの下部にあるアバターを選択し、**管理者**を選択します。
1. **CI/CD > Runners**を選択します。
1. 編集するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **ジョブタイムアウトの最大値**フィールドに値（秒単位）を入力します。最小値は600秒（10分）です。
1. **変更を保存**を選択します。

### グループRunnerの場合 {#for-a-group-runner}

前提要件: 

- グループのオーナーロールが必要です。

ジョブの最大タイムアウトを設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **Runners**を選択します。
1. 編集するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **ジョブタイムアウトの最大値**フィールドに値（秒単位）を入力します。最小値は600秒（10分）です。
1. **変更を保存**を選択します。

### プロジェクトRunnerの場合 {#for-a-project-runner}

前提要件: 

- プロジェクトのオーナーロールが必要です。

ジョブの最大タイムアウトを設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **Runners**を展開します。
1. 編集するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **ジョブタイムアウトの最大値**フィールドに値（秒単位）を入力します。最小値は600秒（10分）です。定義されていない場合、代わりに[プロジェクトのジョブタイムアウト](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)が使用されます。
1. **変更を保存**を選択します。

## ジョブの最大タイムアウトの仕組み {#how-maximum-job-timeout-works}

**Example 1 - Runner timeout bigger than project timeout**（例1 - Runnerのタイムアウトがプロジェクトのタイムアウトより長い場合）

1. Runnerの`maximum_timeout`パラメータを24時間に設定します。
1. プロジェクトの**ジョブタイムアウトの最大値**を**2 hours**（2時間）に設定します。
1. ジョブを開始します。
1. ジョブは**2 hours**（2時間）後にタイムアウトします（実行時間がそれより長い場合）。

**Example 2 - Runner timeout not configured**（例2 - Runnerのタイムアウトが設定されていない場合）

1. Runnerから`maximum_timeout`パラメータの設定を削除します。
1. プロジェクトの**ジョブタイムアウトの最大値**を**2 hours**（2時間）に設定します。
1. ジョブを開始します。
1. ジョブは**2 hours**（2時間）後にタイムアウトします（実行時間がそれより長い場合）。

**Example 3 - Runner timeout smaller than project timeout**（例3 - Runnerのタイムアウトがプロジェクトのタイムアウトより短い場合）

1. Runnerの`maximum_timeout`パラメータを**30 minutes**（30分）に設定します。
1. プロジェクトの**ジョブタイムアウトの最大値**を2時間に設定します。
1. ジョブを開始します。
1. ジョブは**30 minutes**（30分）後にタイムアウトします（実行時間がそれより長い場合）。

## `script`および`after_script`タイムアウトを設定する {#set-script-and-after_script-timeouts}

{{< history >}}

- GitLab Runner 16.4で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4335)されました。

{{< /history >}}

`script`と`after_script`が終了するまでの時間を制御するには、`.gitlab-ci.yml`ファイルでタイムアウト値を指定します。

たとえば、長時間実行される`script`を早期に終了するようにタイムアウトを指定できます。これにより、[ジョブのタイムアウト](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)を超える前に、アーティファクトとキャッシュをアップロードできるようになります。`script`と`after_script`のタイムアウト値は、ジョブのタイムアウトより短くする必要があります。

- `script`のタイムアウトを設定するには、ジョブ変数`RUNNER_SCRIPT_TIMEOUT`を使用します。
- `after_script`のタイムアウトを設定し、デフォルトの5分をオーバーライドするには、ジョブ変数`RUNNER_AFTER_SCRIPT_TIMEOUT`を使用します。

これらの変数はいずれも、[Goの長さ書式](https://pkg.go.dev/time#ParseDuration)（`40s`、`1h20m`、`2h` `4h30m30s`など）をサポートします。

次に例を示します:

```yaml
job-with-script-timeouts:
  variables:
    RUNNER_SCRIPT_TIMEOUT: 15m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 10m
  script:
    - "I am allowed to run for min(15m, remaining job timeout)."
  after_script:
    - "I am allowed to run for min(10m, remaining job timeout)."

job-artifact-upload-on-timeout:
  timeout: 1h                           # set job timeout to 1 hour
  variables:
     RUNNER_SCRIPT_TIMEOUT: 50m         # only allow script to run for 50 minutes
  script:
    - long-running-process > output.txt # will be terminated after 50m

  artifacts: # artifacts will have roughly ~10m to upload
    paths:
      - output.txt
    when: on_failure # on_failure because script termination after a timeout is treated as a failure
```

### `after_script`を正常に実行する {#ensuring-after_script-execution}

`after_script`を正常に実行するには、`RUNNER_SCRIPT_TIMEOUT` + `RUNNER_AFTER_SCRIPT_TIMEOUT`の合計が、ジョブで設定されたタイムアウトを超えないようにする必要があります。

次の例は、メインスクリプトがタイムアウトした場合でも`after_script`が実行されるようにタイムアウトを設定する方法を示しています:

```yaml
job-with-script-timeouts:
  timeout: 5m
  variables:
    RUNNER_SCRIPT_TIMEOUT: 1m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 1m
  script:
    - echo "Starting build..."
    - sleep 120 # Wait 2 minutes to trigger timeout. Script aborts after 1 minute due to RUNNER_SCRIPT_TIMEOUT.
    - echo "Build finished."
  after_script:
    - echo "Starting Clean-up..."
    - sleep 15 # Wait just a few seconds. Runs successfully because it's within RUNNER_AFTER_SCRIPT_TIMEOUT.
    - echo "Clean-up finished."
```

`script`は`RUNNER_SCRIPT_TIMEOUT`によってキャンセルされますが、`after_script`は15秒で完了する（`RUNNER_AFTER_SCRIPT_TIMEOUT`とジョブの`timeout`値の両方よりも短い）ため、正常に実行されます。

## 機密情報を保護する {#protecting-sensitive-information}

インスタンスRunnerは、GitLabインスタンス内のすべてのグループとプロジェクトでデフォルトで使用できるため、セキュリティリスクが高まります。Runner executorとファイルシステムの構成は、セキュリティに影響します。Runnerホスト環境へのアクセス権を持つユーザーは、Runnerが実行したコードとRunner認証を表示できます。たとえば、Runner認証トークンへのアクセス権を持つユーザーは、Runnerをクローンして、ベクター攻撃で偽のジョブを送信できます。詳細については、[セキュリティに関する考慮事項](https://docs.gitlab.com/runner/security/)を参照してください。

## ロングポーリングを設定する {#configuring-long-polling}

ジョブのキュー時間を短縮し、GitLabサーバーの負荷を軽減するには、[ロングポーリング](long_polling.md)を設定します。

## フォークされたプロジェクトでインスタンスRunnerを使用する {#using-instance-runners-in-forked-projects}

プロジェクトがフォークされると、ジョブに関連するジョブ設定がコピーされます。プロジェクト用にインスタンスRunnerが設定されていて、ユーザーがそのプロジェクトをフォークすると、インスタンスRunnerは、このプロジェクトのジョブを処理します。

[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/364303)により、フォークされたプロジェクトのRunner設定が新しいプロジェクトのネームスペースと一致しない場合、`An error occurred while forking the project. Please try again.`メッセージが表示されます。

この問題を回避するには、フォークされたプロジェクトと新しいネームスペースでインスタンスRunnerの設定が一貫していることを確認します。

- フォークされたプロジェクトでインスタンスRunnerが**有効**になっている場合、新しいネームスペースでも**有効**にする必要があります。
- フォークされたプロジェクトでインスタンスRunnerが**無効**になっている場合、新しいネームスペースでも**無効**にする必要があります。

## プロジェクトのRunner登録トークンをリセットする（非推奨） {#reset-the-runner-registration-token-for-a-project-deprecated}

{{< alert type="warning" >}}

Runner登録トークンを渡し、特定の設定引数をサポートするオプションは、レガシーと見なされており、推奨されません。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](new_creation_workflow.md)を参照してください。

{{< /alert >}}

プロジェクトの登録トークンが漏洩したと思われる場合は、リセットする必要があります。登録トークンを使用して、プロジェクトの別のRunnerを登録できます。その新しいRunnerを使用して、シークレット変数の値を取得したり、プロジェクトコードをクローンしたりできます。

登録トークンは、次の手順でリセットできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **Runners**を展開します。
1. **New project runner**（新しいプロジェクトRunner）の右側にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **登録トークンをリセット**を選択します。
1. **トークンのリセット**を選択します。

登録トークンをリセットすると、そのトークンは無効になり、プロジェクトに新しいRunnerが登録されなくなります。また、新しい値をプロビジョニングおよび登録するために使用するツールで、登録トークンを更新する必要があります。

## 認証トークンのセキュリティ {#authentication-token-security}

{{< history >}}

- GitLab 15.3で`enforce_runner_token_expires_at`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30942)されました。デフォルトでは無効になっています。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/377902)になりました。機能フラグ`enforce_runner_token_expires_at`は削除されました。

{{< /history >}}

各Runnerは、[Runner認証トークン](../../api/runners.md#registration-and-authentication-tokens)を使用することで、GitLabインスタンスに接続して認証します。

トークンが侵害されるのを防ぐために、指定された間隔でトークンを自動的にローテーションすることができます。トークンがローテーションされると、Runnerの状態（`online`または`offline`）に関係なく、各Runnerに対して更新されます。

手動による介入は不要で、実行中のジョブに影響はありません。トークンローテーションの詳細については、[Runner認証トークンがローテーション時に更新されない](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated)を参照してください。

Runner認証トークンを手動で更新する必要がある場合は、コマンドを実行して[トークンをリセット](https://docs.gitlab.com/runner/commands/#gitlab-runner-reset-token)できます。

### Runner設定認証トークンをリセットする {#reset-the-runner-configuration-authentication-token}

Runnerの認証トークンが公開されている場合、攻撃者はそれを使用して[Runnerをクローン](https://docs.gitlab.com/runner/security/#cloning-a-runner)できる可能性があります。

Runner設定認証トークンは、次の手順でリセットできます:

1. 次の手順でRunnerを削除します:
   - [インスタンスRunnerを削除します](runners_scope.md#delete-instance-runners)。
   - [グループRunnerを削除します](runners_scope.md#delete-a-group-runner)。
   - [プロジェクトRunnerを削除します](runners_scope.md#delete-a-project-runner)。
1. 次の手順で新しいRunnerを作成して、新しいRunner認証トークンが割り当てられるようにします:
   - [インスタンスRunnerを作成します](runners_scope.md#create-an-instance-runner-with-a-runner-authentication-token)。
   - [グループRunnerを作成します](runners_scope.md#create-a-group-runner-with-a-runner-authentication-token)。
   - [プロジェクトRunnerを作成します](runners_scope.md#create-a-project-runner-with-a-runner-authentication-token)。
1. オプション。以前のRunner認証トークンが失効したことを確認するには、[Runners API](../../api/runners.md#verify-authentication-for-a-registered-runner)を使用します。

Runner設定認証トークンをリセットするために、[Runners API](../../api/runners.md)を使用することもできます。

### Runner認証トークンを自動的にローテーションする {#automatically-rotate-runner-authentication-tokens}

Runner認証トークンをローテーションする間隔を指定できます。Runner認証トークンを定期的にローテーションすることで、不正なトークンを介してGitLabインスタンスに不正アクセスされるリスクを最小限に抑えることができます。

前提要件: 

- Runnerは、[GitLab Runner 15.3以降](https://docs.gitlab.com/runner/#gitlab-runner-versions)を使用する必要があります。
- 管理者である必要があります。

次の手順でRunner認証トークンを自動的にローテーションできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、左側のサイドバーの下部にあるアバターを選択し、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. Runnerについて**Runners expiration**（Runnerの有効期限）を設定します。有効期限がない場合は空のままにします。
1. **変更を保存**を選択します。

一定期間の有効期限が切れる前に、Runnerは新しいRunner認証トークンを自動的に要求します。トークンローテーションの詳細については、[Runner認証トークンがローテーション時に更新されない](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated)を参照してください。

## Runnerが機密情報を公開しないようにする {#prevent-runners-from-revealing-sensitive-information}

Runnerが機密情報を公開しないようにするには、[保護ブランチ](../../user/project/repository/branches/protected.md) 、または[保護タグ](../../user/project/protected_tags.md)を含むジョブでのみジョブを実行するようにRunnerを設定します。

保護ブランチでジョブを実行するように設定されたRunnerは、[必要に応じてマージリクエストパイプラインでジョブを実行](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners)できます。

### インスタンスRunnerの場合 {#for-an-instance-runner-1}

前提要件: 

- 管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、左側のサイドバーの下部にあるアバターを選択し、**管理者**を選択します。
1. **CI/CD > Runners**を選択します。
1. 保護するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **保護**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### グループRunnerの場合 {#for-a-group-runner-1}

前提要件: 

- グループのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **Runners**を選択します。
1. 保護するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **保護**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### プロジェクトRunnerの場合 {#for-a-project-runner-1}

前提要件: 

- プロジェクトのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **Runners**を展開します。
1. 保護するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **保護**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## Runnerが実行できるジョブを制御する {#control-jobs-that-a-runner-can-run}

[タグ](../yaml/_index.md#tags)を使用して、Runnerが実行できるジョブを制御できます。たとえば、Railsテストスイートを実行するための依存関係を持つRunnerには、`rails`タグを指定できます。

GitLab CI/CDタグはGitタグとは異なります。GitLab CI/CDタグはRunnerに関連付けられています。Gitタグはコミットに関連付けられています。

### インスタンスRunnerの場合 {#for-an-instance-runner-2}

前提要件: 

- 管理者である必要があります。

インスタンスRunnerが実行できるジョブは、次の手順で制御できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、左側のサイドバーの下部にあるアバターを選択し、**管理者**を選択します。
1. **CI/CD > Runners**を選択します。
1. 編集するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. タグ付きジョブまたはタグなしジョブを実行するようにRunnerを設定します:
   - タグ付きジョブを実行するには、**タグ**フィールドに、ジョブタグをコンマで区切って入力します。たとえば、`macos`、`rails`などです。
   - タグなしジョブを実行するには、**タグのないジョブの実行**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### グループRunnerの場合 {#for-a-group-runner-2}

前提要件: 

- グループのオーナーロールが必要です。

グループRunnerが実行できるジョブは、次の手順で制御できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **Runners**を選択します。
1. 編集するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. タグ付きジョブまたはタグなしジョブを実行するようにRunnerを設定します:
   - タグ付きジョブを実行するには、**タグ**フィールドに、ジョブタグをコンマで区切って入力します。たとえば、`macos`、`ruby`などです。
   - タグなしジョブを実行するには、**タグのないジョブの実行**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### プロジェクトRunnerの場合 {#for-a-project-runner-2}

前提要件: 

- プロジェクトのオーナーロールが必要です。

プロジェクトRunnerが実行できるジョブは、次の手順で制御できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **Runners**を展開します。
1. 編集するRunnerの右側で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. タグ付きジョブまたはタグなしジョブを実行するようにRunnerを設定します:
   - タグ付きジョブを実行するには、**タグ**フィールドに、ジョブタグをコンマで区切って入力します。たとえば、`macos`、`ruby`などです。
   - タグなしジョブを実行するには、**タグのないジョブの実行**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### Runnerがタグを使用する仕組み {#how-the-runner-uses-tags}

#### Runnerがタグ付きジョブのみを実行する場合 {#runner-runs-only-tagged-jobs}

次の例は、Runnerがタグ付きジョブのみを実行するように設定されている場合の考えられる影響を示しています。

例1:

1. Runnerはタグ付きジョブのみを実行するように設定されており、`docker`タグが付いている。
1. `hello`タグを持つジョブが実行され、途中で停止する。

例2:

1. Runnerはタグ付きジョブのみを実行するように設定されており、`docker`タグが付いている。
1. `docker`タグを持つジョブが実行される。

例3:

1. Runnerはタグ付きジョブのみを実行するように設定されており、`docker`タグが付いている。
1. タグが定義されていないジョブが実行され、途中で停止する。

#### Runnerがタグなしジョブの実行を許可されている場合 {#runner-is-allowed-to-run-untagged-jobs}

次の例は、Runnerがタグ付きおよびタグなしジョブを実行するように設定されている場合の考えられる影響を示しています。

例1:

1. Runnerはタグなしジョブを実行するように設定されており、`docker`タグが付いている。
1. タグが定義されていないジョブが実行される。
1. `docker`タグが定義されている2番目のジョブが実行される。

例2:

1. Runnerはタグなしジョブを実行するように設定されており、タグは定義されていない。
1. タグが定義されていないジョブが実行される。
1. `docker`タグが定義されている2番目のジョブが途中で停止する。

#### Runnerとジョブに複数のタグがある場合 {#a-runner-and-a-job-have-multiple-tags}

ジョブとRunnerを一致させる選択ロジックは、ジョブで定義されている`tags`のリストに基づいています。

次の例は、Runnerとジョブに複数のタグがある場合の影響を示しています。Runnerがジョブの実行のために選択されるには、ジョブスクリプトブロックで定義されているすべてのタグを含んでいる必要があります。

例1:

1. Runnerはタグ`[docker, shell, gpu]`で設定されている。
1. ジョブにはタグ`[docker, shell, gpu]`があり、実行される。

例2:

1. Runnerはタグ`[docker, shell, gpu]`で設定されている。
1. ジョブにはタグ`[docker, shell,]`があり、実行される。

例3:

1. Runnerはタグ`[docker, shell]`で設定されている。
1. ジョブにはタグ`[docker, shell, gpu]`があり、実行されない。

### タグを使用して異なるプラットフォームでジョブを実行する {#use-tags-to-run-jobs-on-different-platforms}

タグを使用すると、さまざまなプラットフォームでさまざまなジョブを実行できます。たとえば、タグ`osx`を持つOS X Runnerとタグ`windows`を持つWindows Runnerがある場合、それぞれのプラットフォームでジョブを実行できます。

`.gitlab-ci.yml`の`tags`フィールドを更新します:

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```

### タグでCI/CD変数を使用する {#use-cicd-variables-in-tags}

`.gitlab-ci.yml`ファイルで、`tags`を含む[CI/CD変数](../variables/_index.md)を使用して、動的にRunnerを選択します:

```yaml
variables:
  KUBERNETES_RUNNER: kubernetes

  job:
    tags:
      - docker
      - $KUBERNETES_RUNNER
    script:
      - echo "Hello runner selector feature"
```

## 変数でRunnerの動作を設定する {#configure-runner-behavior-with-variables}

[CI/CD変数](../variables/_index.md)を使用して、RunnerのGitの動作をグローバルに、または個々のジョブに対して設定できます:

- [`GIT_STRATEGY`](#git-strategy)
- [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)
- [`GIT_CHECKOUT`](#git-checkout)
- [`GIT_CLEAN_FLAGS`](#git-clean-flags)
- [`GIT_FETCH_EXTRA_FLAGS`](#git-fetch-extra-flags)
- [`GIT_CLONE_EXTRA_FLAGS`](#git-clone-extra-flags)
- [`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags)
- [`GIT_SUBMODULE_FORCE_HTTPS`](#rewrite-submodule-urls-to-https)
- [`GIT_DEPTH`](#shallow-cloning)（シャロークローン）
- [`GIT_SUBMODULE_DEPTH`](#git-submodule-depth)
- [`GIT_CLONE_PATH`](#custom-build-directories)（カスタムビルドディレクトリ）
- [`TRANSFER_METER_FREQUENCY`](#artifact-and-cache-settings)（アーティファクト/キャッシュメーターの更新頻度）
- [`ARTIFACT_COMPRESSION_LEVEL`](#artifact-and-cache-settings)（アーティファクトアーカイバーの圧縮レベル）
- [`CACHE_COMPRESSION_LEVEL`](#artifact-and-cache-settings)（キャッシュアーカイバーの圧縮レベル）
- [`CACHE_REQUEST_TIMEOUT`](#artifact-and-cache-settings)（キャッシュリクエストのタイムアウト）
- [`RUNNER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`RUNNER_AFTER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`AFTER_SCRIPT_IGNORE_ERRORS`](#ignore-errors-in-after_script)

変数を使用して、Runnerが[ジョブ実行の特定のステージを試行](#job-stages-attempts)する回数を設定することもできます。

Kubernetes executorを使用する場合、変数を使用して、[リクエストと制限に対するKubernetes CPUおよびメモリの割り当てをオーバーライド](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources)できます。

[Runnerの機能フラグ](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)は、[ジョブとパイプラインの変数](https://docs.gitlab.com/runner/configuration/feature-flags/#enable-feature-flag-in-pipeline-configuration)としても受け入れられます。

### Git戦略 {#git-strategy}

`GIT_STRATEGY`変数は、ビルドディレクトリの準備方法とリポジトリコンテンツのフェッチ方法を設定します。この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

```yaml
variables:
  GIT_STRATEGY: clone
```

使用できる値は、`clone`、`fetch`、`none`、`empty`です。値を指定しない場合、ジョブは[プロジェクトのパイプライン設定](../pipelines/settings.md#choose-the-default-git-strategy)を使用します。

`clone`は最も時間がかかるオプションです。ジョブごとにリポジトリのクローンをゼロから作成して、ローカルの実行コピーが常に元の状態になるようにします。既存のワークツリーが見つかった場合は、クローンの作成前に削除されます。

`fetch`は、ローカルの実行コピーを再利用するため高速です（存在しない場合は、`clone`にフォールバックします）。`git clean`は、最後のジョブによって行われた変更を元に戻すために使用され、`git fetch`は、最後のジョブの実行後に行われたコミットを取得するために使用されます。

ただし、`fetch`は、前のワークツリーへのアクセスが必要です。これは、`shell`または`docker` executorを使用する場合に適しています。これらはワークツリーの保持を試み、デフォルトで再利用しようとするためです。

[Docker Machine Executor](https://docs.gitlab.com/runner/executors/docker_machine.html)を使用する場合、これには制限が伴います。

Git戦略の`none`もローカルの実行コピーを再利用しますが、通常、GitLabによって行われるすべてのGit操作をスキップします。GitLab Runnerのpre-cloneスクリプトも、残っている場合はスキップされます。この戦略では、場合によっては、`fetch`コマンドと`checkout`コマンドを[`.gitlab-ci.yml`スクリプト](../yaml/_index.md#script)に追加する必要があります。

これは、デプロイジョブなど、アーティファクトでのみ動作するジョブに使用できます。Gitリポジトリデータが残っている可能性がありますが、（残っていても）古くなっていると考えられます。キャッシュまたはアーティファクトからローカルの実行コピーに取り込まれたファイルのみを使用する必要があります。前のパイプラインからのキャッシュファイルとアーティファクトファイルがまだ残っている可能性があることに注意してください。

`none`とは異なり、`empty` Git戦略は、キャッシュファイルまたはアーティファクトファイルをダウンロードする前に、専用のビルドディレクトリを削除してから再作成します。この戦略では、GitLab Runnerのフックスクリプトが引き続き実行され（提供されている場合）、動作のさらなるカスタマイズを可能にします。次の場合は、`empty` Git戦略を使用します:

- リポジトリデータが存在する必要がない。
- ジョブが実行されるたびに、クリーンで制御された、またはカスタマイズされた開始状態が必要になる。

### Gitサブモジュール戦略 {#git-submodule-strategy}

ビルド前にコードをフェッチするときに、`GIT_SUBMODULE_STRATEGY`変数を使用して、[Gitサブモジュール](https://git-scm.com/book/en/v2/Git-Tools-Submodules)を含めるかどうか、またはどのように含めるかを制御します。これらは、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

使用可能な3つの値は、`none`、`normal`、`recursive`です:

- `none`は、プロジェクトコードの取得時にサブモジュールが含まれないことを意味します。この設定は、1.10より前のバージョンのデフォルトの動作と一致します。

- `normal`は、トップレベルのサブモジュールのみが含まれることを意味します。次のコマンドと同等です:

  ```shell
  git submodule sync
  git submodule update --init
  ```

- `recursive`は、すべてのサブモジュール（サブモジュールのサブモジュールを含む）が含まれることを意味します。この機能にはGit v1.8.1以降が必要です。Dockerに基づいていないexecutorでGitLab Runnerを使用する場合は、Gitのバージョンがその要件を満たしていることを確認してください。次のコマンドと同等です:

  ```shell
  git submodule sync --recursive
  git submodule update --init --recursive
  ```

この機能が正しく動作するには、（`.gitmodules`で）サブモジュールが次のいずれかで設定されている必要があります:

- 公開されているリポジトリのHTTP(S) URL
- 同じGitLabサーバー上にある別のリポジトリの相対パス[Gitサブモジュール](git_submodules.md)のドキュメントを参照してください。

[`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags)を使用して、追加のフラグを指定し、高度な動作を制御することができます。

### Git checkout {#git-checkout}

`GIT_CHECKOUT`変数を使用すると、`GIT_STRATEGY`が`clone`または`fetch`に設定されている場合に、`git checkout`を実行するかどうかを指定できます。指定しない場合、デフォルトはtrueです。これらは、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

`false`に設定すると、Runnerは次のようになります:

- `fetch`の実行時 - リポジトリを更新し、実行コピーを現在のリビジョンに残します。
- `clone`の実行時 - リポジトリをクローンして、実行コピーをデフォルトブランチに残します。

`GIT_CHECKOUT`が`true`に設定されている場合、`clone`と`fetch`の両方が同じように動作します。Runnerは、CIパイプラインに関連するリビジョンの実行コピーをチェックアウトします:

```yaml
variables:
  GIT_STRATEGY: clone
  GIT_CHECKOUT: "false"
script:
  - git checkout -B master origin/master
  - git merge $CI_COMMIT_SHA
```

### Git cleanフラグ {#git-clean-flags}

`GIT_CLEAN_FLAGS`変数を使用して、ソースをチェックアウトした後の`git clean`のデフォルトの動作を制御します。この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

`GIT_CLEAN_FLAGS`は、[`git clean`](https://git-scm.com/docs/git-clean)コマンドの利用可能なすべてのオプションを受け入れます。

`GIT_CHECKOUT: "false"`が指定されている場合、`git clean`は無効になります。

`GIT_CLEAN_FLAGS`の動作は次のようになります:

- 指定されていない場合、`git clean`フラグはデフォルトで`-ffdx`になります。
- 値`none`が指定されている場合、`git clean`は実行されません。

次に例を示します:

```yaml
variables:
  GIT_CLEAN_FLAGS: -ffdx -e cache/
script:
  - ls -al cache/
```

### Git fetchの追加フラグ {#git-fetch-extra-flags}

`GIT_FETCH_EXTRA_FLAGS`変数を使用して、`git fetch`の動作を制御します。この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

`GIT_FETCH_EXTRA_FLAGS`は、[`git fetch`](https://git-scm.com/docs/git-fetch)コマンドのすべてのオプションを受け入れます。ただし、`GIT_FETCH_EXTRA_FLAGS`フラグは、変更できないデフォルトのフラグの後に追加されます。

デフォルトのフラグは次のとおりです:

- [`GIT_DEPTH`](#shallow-cloning)。
- [refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec)のリスト。
- `origin`という名前のremote。

`GIT_FETCH_EXTRA_FLAGS`の動作は次のようになります:

- 指定されていない場合、`git fetch`フラグはデフォルトで`--prune --quiet`とデフォルトのフラグになります。
- 値`none`が指定されている場合、`git fetch`はデフォルトのフラグでのみ実行されます。

たとえば、デフォルトのフラグは`--prune --quiet`であるため、これを`--prune`だけでオーバーライドすることにより、`git fetch`をより冗長にすることができます:

```yaml
variables:
  GIT_FETCH_EXTRA_FLAGS: --prune
script:
  - ls -al cache/
```

上記の設定では、`git fetch`が次のように呼び出されます:

```shell
git fetch origin $REFSPECS --depth 20  --prune
```

上の`$REFSPECS`は、GitLabによってRunnerに内部的に提供される値です。

### Gitクローンの追加フラグ {#git-clone-extra-flags}

`GIT_CLONE_EXTRA_FLAGS`変数を使用して、ネイティブな`git clone`操作に追加の引数を渡します。この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

`GIT_CLONE_EXTRA_FLAGS`を使用するには:

- ネイティブ`git clone`機能を有効にするには、`FF_USE_GIT_NATIVE_CLONE`を`true`に設定します。
- フェッチの代わりにクローン戦略を使用するには、`GIT_STRATEGY`を`clone`に設定します。
- Gitクライアントは少なくともバージョン2.49である必要があります。[ヘルパーイメージ](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image)がLinuxフレーバーのイメージ、バージョン18.1以降の場合、この条件は自動的に満たされます。

`GIT_CLONE_EXTRA_FLAGS`は、`git clone`コマンドのすべてのオプションを受け入れます。これらのフラグはネイティブ`git clone`コマンドに追加され、代替リポジトリへの参照やクローンパフォーマンスの最適化など、高度なユースケースに柔軟性を提供します。

たとえば、参照リポジトリを使用してクローンのパフォーマンスを最適化できます:

```yaml
variables:
  FF_USE_GIT_NATIVE_CLONE: true
  GIT_STRATEGY: clone
  GIT_CLONE_EXTRA_FLAGS: "--reference-if-available /tmp/test"
```

`GIT_CLONE_EXTRA_FLAGS`が指定されていない場合、`git clone`はデフォルトのフラグのみを使用します。

### CIジョブから特定のサブモジュールを同期または除外する {#sync-or-exclude-specific-submodules-from-ci-jobs}

同期または更新する必要があるサブモジュールがどれかを制御するには、`GIT_SUBMODULE_PATHS`変数を使用します。この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

パス構文は[`git submodule`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-ltpathgt82308203)と同じです:

- 次のように、特定のパスを同期して更新できます:

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
  ```

- 次のように、特定のパスを除外できます:

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: ":(exclude)submoduleA :(exclude)submoduleB"
  ```

{{< alert type="warning" >}}

Gitはネストされたパスを無視します。ネストされたサブモジュールを無視するには、親サブモジュールを除外し、ジョブのスクリプトでそのクローンを手動で作成します。例: `git clone <repo> --recurse-submodules=':(exclude)nested-submodule'`。YAMLが正常に解析されるように、文字列を単一引用符で囲んでください。

{{< /alert >}}

### Gitサブモジュールの更新フラグ {#git-submodule-update-flags}

[`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)が`normal`または`recursive`のいずれかに設定されている場合、`GIT_SUBMODULE_UPDATE_FLAGS`変数を使用して`git submodule update`の動作を制御します。この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

`GIT_SUBMODULE_UPDATE_FLAGS`は、[`git submodule update`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-update--init--remote-N--no-fetch--no-recommend-shallow-f--force--checkout--rebase--merge--referenceltrepositorygt--depthltdepthgt--recursive--jobsltngt--no-single-branch--ltpathgt82308203)サブコマンドのすべてのオプションを受け入れます。ただし、`GIT_SUBMODULE_UPDATE_FLAGS`フラグは、いくつかのデフォルトのフラグの後に追加されます:

- [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)が`normal`または`recursive`に設定されている場合: `--init`。
- [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)が`recursive`に設定されている場合: `--recursive`。
- `GIT_DEPTH`。デフォルト値については、[シャロークローン](#shallow-cloning)セクションを参照してください。

Gitは引数リストで最後に出現するフラグを優先するため、`GIT_SUBMODULE_UPDATE_FLAGS`でフラグを手動で指定すると、これらのデフォルトフラグがオーバーライドされます。

たとえば、この変数を使用して次のことができます:

- `--remote`フラグを使用して、リポジトリ（デフォルト）で追跡されたコミットではなく、最新のリモート`HEAD`をフェッチして、すべてのサブモジュールを自動的に更新します。
- `--jobs 4`フラグを使用して、複数の並列ジョブでサブモジュールをフェッチすることにより、チェックアウトを高速化します。

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_UPDATE_FLAGS: --remote --jobs 4
script:
  - ls -al .git/modules/
```

上記の設定では、`git submodule update`が次のように呼び出されます:

```shell
git submodule update --init --depth 20 --recursive --remote --jobs 4
```

{{< alert type="warning" >}}

`--remote`フラグを使用する場合は、ビルドのセキュリティ、安定性、および再現性への影響に注意する必要があります。ほとんどの場合、設計どおりにサブモジュールコミットを明示的に追跡し、自動修正/依存関係ボットを使用してそれらを更新することをおすすめします。

（サブモジュールが）コミットされたリビジョンでサブモジュールをチェックアウトするうえで、`--remote`フラグは必要ありません。サブモジュールを最新のリモートバージョンに自動的に更新する場合にのみ、このフラグを使用します。

{{< /alert >}}

`--remote`の動作は、Gitのバージョンによって異なります。スーパープロジェクトの`.gitmodules`ファイルで指定されたブランチが、サブモジュールリポジトリのデフォルトブランチと異なる場合、一部のGitバージョンは以下のエラーで失敗する可能性があります:

`fatal: Unable to find refs/remotes/origin/<branch> revision in submodule path '<submodule-path>'`

Runnerは「ベストエフォート」フォールバックを実装して、サブモジュールの更新が失敗した場合にリモート参照のプルを試みます。

このフォールバックがお使いのGitのバージョンで動作しない場合は、次のいずれかの回避策を試してください:

- スーパープロジェクトの`.gitmodules`で設定されたブランチと一致するように、サブモジュールリポジトリのデフォルトブランチを更新します。
- `GIT_SUBMODULE_DEPTH`を`0`に設定します。
- サブモジュールを個別に更新し、`GIT_SUBMODULE_UPDATE_FLAGS`から`--remote`フラグを削除します。

### サブモジュールのURLをHTTPSに書き換える {#rewrite-submodule-urls-to-https}

{{< history >}}

- GitLab Runner 15.11で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198)されました。

{{< /history >}}

`GIT_SUBMODULE_FORCE_HTTPS`変数を使用して、すべてのGitおよびSSHサブモジュールURLをHTTPSに強制的に書き換えます。同じGitLabインスタンス上の絶対URLを使用するサブモジュールについては、GitまたはSSHプロトコルで設定されている場合でも、そのクローンを作成できます。

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_FORCE_HTTPS: "true"
```

GitLab Runnerは有効化されると、[CI/CDジョブトークン](../jobs/ci_job_token.md)を使用してサブモジュールをクローンします。トークンはジョブを実行しているユーザーの権限を使用しますが、SSH認証情報を必要としません。

### シャロークローン {#shallow-cloning}

`GIT_DEPTH`を使用して、フェッチとクローンの深さを指定できます。`GIT_DEPTH`はリポジトリのシャロークローンを作成し、クローン作成を大幅に高速化できます。これは、多数のコミットまたは古い大きなバイナリを持つリポジトリに役立ちます。値は`git fetch`と`git clone`に渡されます。

新しく作成されたプロジェクトには、[`git depth`のデフォルト値（`20`）](../pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)が自動的に設定されます。

深さ`1`を使用していて、ジョブのキューまたは再試行ジョブがある場合、ジョブは失敗する可能性があります。

Gitのフェッチとクローン作成はブランチ名などのrefに基づいて行われるため、Runnerは特定のコミットSHAをクローンできません。複数のジョブがキューにある場合、または古いジョブを再試行する場合、テスト対象のコミットはクローンされたGitの履歴に含まれている必要があります。`GIT_DEPTH`に小さすぎる値を設定すると、これらの古いコミットを実行できなくなり、ジョブログに`unresolved reference`が表示される可能性があります。その場合は、`GIT_DEPTH`をより高い値に変更することを再検討する必要があります。

`git describe`に依存するジョブは、`GIT_DEPTH`が設定されていると正しく動作しない場合があります。これは、Gitの履歴の一部のみが残っているためです。

次のコマンドで、最後の3つのコミットのみをフェッチまたはクローンできます:

```yaml
variables:
  GIT_DEPTH: "3"
```

この変数は、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

### Gitサブモジュールの深さ {#git-submodule-depth}

{{< history >}}

- GitLab Runner 15.5で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3651)されました。

{{< /history >}}

[`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)が`normal`または`recursive`のいずれかに設定されている場合は、`GIT_SUBMODULE_DEPTH`変数を使用してサブモジュールをフェッチおよびクローンする深さを指定します。これは、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、または特定のジョブに対して設定できます。

`GIT_SUBMODULE_DEPTH`変数を設定すると、サブモジュールに対してのみ[`GIT_DEPTH`](#shallow-cloning)設定が上書きされます。

次のコマンドで、最後の3つのコミットのみをフェッチまたはクローンできます:

```yaml
variables:
  GIT_SUBMODULE_DEPTH: 3
```

### カスタムビルドディレクトリ {#custom-build-directories}

デフォルトでは、GitLab Runnerは、`$CI_BUILDS_DIR`ディレクトリの一意のサブパスにリポジトリをクローンします。ただし、プロジェクトでは、特定のディレクトリ（Goプロジェクトなど）にコードが必要になる場合があります。その場合は、`GIT_CLONE_PATH`変数を指定して、リポジトリのクローンを作成するディレクトリをRunnerに指示できます:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/project-name

test:
  script:
    - pwd
```

`GIT_CLONE_PATH`は、常に`$CI_BUILDS_DIR`の内部にある必要があります。`$CI_BUILDS_DIR`で設定されたディレクトリは、executor、および[runners.builds_dir](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)設定の構成によって異なります。

これは、[Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscustom_build_dir-section)で`custom_build_dir`が有効になっている場合にのみ使用できます。

#### 並行処理を処理する {#handling-concurrency}

並行処理数が`1`より大きいexecutorを使用すると、障害が発生する可能性があります。`builds_dir`がジョブ間で共有されている場合、複数のジョブが同じディレクトリで動作している可能性があります。

Runnerはこの状況を防ごうとしません。Runnerの設定要件を遵守することは、管理者とデベロッパーの責任です。

このシナリオを回避するには、`$CI_BUILDS_DIR`で一意のパスを使用します。Runnerが、並行処理の一意の`ID`を提供する2つの追加変数を公開するからです:

- `$CI_CONCURRENT_ID`: 指定されたexecutorで実行されているすべてのジョブの一意のID。
- `$CI_CONCURRENT_PROJECT_ID`: 指定されたexecutorおよびプロジェクトで実行されているすべてのジョブの一意のID。

シナリオやexecutorを問わず確実に動作する最も安定した設定は、`GIT_CLONE_PATH`で`$CI_CONCURRENT_ID`を使用することです。次に例を示します:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/project-name

test:
  script:
    - pwd -P
```

`$CI_CONCURRENT_PROJECT_ID`は、`$CI_PROJECT_PATH`と組み合わせて使用する必要があります。`$CI_PROJECT_PATH`は、`group/subgroup/project`形式でリポジトリのパスを提供します。次に例を示します:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_PATH

test:
  script:
    - pwd -P
```

#### ネストされたパス {#nested-paths}

`GIT_CLONE_PATH`の値は1回展開されます。この値に変数をネストすることはできません。

たとえば、`.gitlab-ci.yml`ファイルで以下の両方の変数を定義します:

```yaml
variables:
  GOPATH: $CI_BUILDS_DIR/go
  GIT_CLONE_PATH: $GOPATH/src/namespace/project
```

`GIT_CLONE_PATH`の値は、`$CI_BUILDS_DIR/go/src/namespace/project`に1回展開され、`$CI_BUILDS_DIR`が展開されないため、失敗します。

### `after_script`のエラーを無視する {#ignore-errors-in-after_script}

ジョブで[`after_script`](../yaml/_index.md#after_script)を使用して、ジョブの`before_script`および`script`セクションの後に実行する必要があるコマンドの配列を定義できます。`after_script`コマンドは、スクリプトの終了ステータス（失敗または成功）に関係なく実行されます。

デフォルトでは、GitLab Runnerは`after_script`の実行時に発生するエラーを無視します。`after_script`の実行時にエラーが発生するとジョブが即座に失敗するように設定するには、`AFTER_SCRIPT_IGNORE_ERRORS` CI/CD変数を`false`に設定します。次に例を示します:

```yaml
variables:
  AFTER_SCRIPT_IGNORE_ERRORS: false
```

### ジョブステージの試行回数 {#job-stages-attempts}

実行中のジョブが以下のステージの実行を試みる回数を設定できます:

| 変数                        | 説明 |
|---------------------------------|-------------|
| `ARTIFACT_DOWNLOAD_ATTEMPTS`    | ジョブの実行中にアーティファクトをダウンロードする試行回数 |
| `EXECUTOR_JOB_SECTION_ATTEMPTS` | [`No Such Container`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4450)エラー後のジョブでセクションを実行する試行回数（[Docker executor](https://docs.gitlab.com/runner/executors/docker.html)のみ）。 |
| `GET_SOURCES_ATTEMPTS`          | ジョブの実行中にソースをフェッチする試行回数 |
| `RESTORE_CACHE_ATTEMPTS`        | ジョブの実行中にキャッシュを復元する試行回数 |

デフォルトの試行回数は1回です。

例:

```yaml
variables:
  GET_SOURCES_ATTEMPTS: 3
```

これらは、[`variables`](../yaml/_index.md#variables)セクションでグローバルに、またはジョブごとに設定できます。

## GitLab.comインスタンスRunnerで使用できないシステムコール {#system-calls-not-available-on-gitlabcom-instance-runners}

GitLab.comインスタンスRunnerはCoreOSで実行されます。つまり、C標準ライブラリから`getlogin`のような一部のシステムコールを使用することはできません。

## アーティファクトとキャッシュを設定する {#artifact-and-cache-settings}

アーティファクトとキャッシュの設定は、アーティファクトとキャッシュの圧縮率を制御します。これらの設定を使用して、ジョブによって生成されるアーカイブのサイズを指定します。

- 低速ネットワークでは、アーカイブが小さいほどアップロードが速くなる場合があります。
- 帯域幅とストレージについて心配する必要がない高速ネットワークでは、最速の圧縮率を使用する方が、生成されるアーカイブが大きくなるにもかかわらず、アップロードは速くなる場合があります。

圧縮されていないzipアーカイブのみがこの機能をサポートします。そのため、[GitLab Pages](../../user/project/pages/_index.md)が[HTTP Rangeリクエスト](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests)を処理できるようにするには、アーティファクトは`ARTIFACT_COMPRESSION_LEVEL: fastest`設定を使用する必要があります。

メーターを有効にして、アップロードとダウンロードの転送速度を表示できます。

`CACHE_REQUEST_TIMEOUT`設定を使用して、キャッシュのアップロードとダウンロードの最大時間を設定できます。キャッシュのアップロードが遅いときに、ジョブの時間が大幅に増加する場合は、この設定を使用します。

```yaml
variables:
  # output upload and download progress every 2 seconds
  TRANSFER_METER_FREQUENCY: "2s"

  # Use fast compression for artifacts, resulting in larger archives
  ARTIFACT_COMPRESSION_LEVEL: "fast"

  # Use no compression for caches
  CACHE_COMPRESSION_LEVEL: "fastest"

  # Set maximum duration of cache upload and download
  CACHE_REQUEST_TIMEOUT: 5
```

| 変数                     | 説明 |
|------------------------------|-------------|
| `TRANSFER_METER_FREQUENCY`   | メーターの転送速度を表示する頻度を指定します。これは特定の時間（`1s`や`1m30s`など）に設定できます。時間`0`は、メーターを無効にします（デフォルト）。値が設定されている場合、パイプラインにはアーティファクトとキャッシュのアップロードおよびダウンロードのプログレスメーターが表示されます。 |
| `ARTIFACT_COMPRESSION_LEVEL` | 圧縮率を調整するには、`fastest`、`fast`、`default`、`slow`、または`slowest`に設定します。この設定はFastzipアーカイバーでのみ機能するため、GitLab Runnerの機能フラグ[`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags)も有効にする必要があります。 |
| `CACHE_COMPRESSION_LEVEL`    | 圧縮率を調整するには、`fastest`、`fast`、`default`、`slow`、または`slowest`に設定します。この設定はFastzipアーカイバーでのみ機能するため、GitLab Runnerの機能フラグ[`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags)も有効にする必要があります。 |
| `CACHE_REQUEST_TIMEOUT`      | 単一ジョブのキャッシュのアップロードおよびダウンロード操作の最大時間を分単位で設定します。デフォルトは`10`分です。 |

## アーティファクト来歴メタデータ {#artifact-provenance-metadata}

{{< history >}}

- GitLab Runner 15.1で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28940)されました。

{{< /history >}}

Runnerは[SLSA Provenance](https://slsa.dev/spec/v1.0/provenance)を生成し、すべてのビルドアーティファクトに来歴をバインドする[SLSA Statement](https://slsa.dev/spec/v1.0/attestation-model#model-and-terminology)を生成できます。このステートメントは、アーティファクトの来歴メタデータと呼ばれます。

アーティファクト来歴メタデータを有効にするには、`RUNNER_GENERATE_ARTIFACTS_METADATA`環境変数を`true`に設定します。グローバルに変数を設定することも、個々のジョブに設定することもできます:

```yaml
variables:
  RUNNER_GENERATE_ARTIFACTS_METADATA: "true"

job1:
  variables:
    RUNNER_GENERATE_ARTIFACTS_METADATA: "true"
```

メタデータは、アーティファクトとともに保存されるプレーンテキストの`.json`ファイルでレンダリングされます。ファイル名は`{ARTIFACT_NAME}-metadata.json`です。`ARTIFACT_NAME`は、`.gitlab-ci.yml`ファイルで定義された[アーティファクトの名前](../jobs/job_artifacts.md#with-an-explicitly-defined-artifact-name)です。名前が定義されていない場合、デフォルトのファイル名は`artifacts-metadata.json`です。

### 来歴メタデータの形式 {#provenance-metadata-format}

アーティファクト来歴メタデータは、[in-toto v0.1 Statement](https://github.com/in-toto/attestation/tree/v0.1.0/spec#statement)形式で生成されます。これには、[SLSA 1.0 Provenance](https://slsa.dev/spec/v1.0/provenance)形式で生成された来歴情報が含まれています。

これらのフィールドには、デフォルトで入力された値が入ります:

| フィールド                                                             | 値 |
|-------------------------------------------------------------------|-------|
| `_type`                                                           | `https://in-toto.io/Statement/v0.1` |
| `subject`                                                         | メタデータが適用されるソフトウェアアーティファクトのセット |
| `subject[].name`                                                  | アーティファクトのファイル名。 |
| `subject[].sha256`                                                | アーティファクトの`sha256`チェックサム。 |
| `predicateType`                                                   | `https://slsa.dev/provenance/v1` |
| `predicate.buildDefinition.buildType`                             | `https://gitlab.com/gitlab-org/gitlab-runner/-/blob/{GITLAB_RUNNER_VERSION}/PROVENANCE.md`。例: v15.0.0。 |
| `predicate.runDetails.builder.id`                                 | Runnerの詳細ページを指すURI（例: `https://gitlab.com/gitlab-com/www-gitlab-com/-/runners/3785264`）。 |
| `predicate.buildDefinition.externalParameters`                    | ビルドコマンドの実行時に使用可能なCI/CD変数または環境変数の名前。シークレットを保護するため、この値は常に空の文字列として表されます。 |
| `predicate.buildDefinition.externalParameters.source`             | プロジェクトのURL。 |
| `predicate.buildDefinition.externalParameters.entryPoint`         | ビルドをトリガーしたCI/CDジョブの名前。 |
| `predicate.buildDefinition.internalParameters.name`               | Runnerの名前。 |
| `predicate.buildDefinition.internalParameters.executor`           | Runnerのexecutor。 |
| `predicate.buildDefinition.internalParameters.architecture`       | CI/CDジョブが実行されるアーキテクチャ。 |
| `predicate.buildDefinition.internalParameters.job`                | ビルドをトリガーしたCI/CDジョブのID。 |
| `predicate.buildDefinition.resolvedDependencies[0].uri`           | プロジェクトのURL。 |
| `predicate.buildDefinition.resolvedDependencies[0].digest.sha256` | プロジェクトのコミットリビジョン。 |
| `predicate.runDetails.metadata.invocationID`                      | ビルドをトリガーしたCI/CDジョブのID。 |
| `predicate.runDetails.metadata.startedOn`                         | ビルドが開始された時間。このフィールドは`RFC3339`形式です。 |
| `predicate.runDetails.metadata.finishedOn`                        | ビルドが終了した時間。メタデータの生成はビルド中に行われるため、この時間は、GitLabでレポートされている時間よりもわずかに前の時間になります。このフィールドは`RFC3339`形式です。 |

来歴ステートメントは、次の例のようになります:

```json
{
 "_type": "https://in-toto.io/Statement/v0.1",
 "predicateType": "https://slsa.dev/provenance/v1",
 "subject": [
  {
   "name": "x.txt",
   "digest": {
    "sha256": "ac097997b6ec7de591d4f11315e4aa112e515bb5d3c52160d0c571298196ea8b"
   }
  },
  {
   "name": "y.txt",
   "digest": {
    "sha256": "9eb634f80da849d828fcf42740d823568c49e8d7b532886134f9086246b1fdf3"
   }
  }
 ],
 "predicate": {
  "buildDefinition": {
   "buildType": "https://gitlab.com/gitlab-org/gitlab-runner/-/blob/2147fb44/PROVENANCE.md",
   "externalParameters": {
    "CI": "",
    "CI_API_GRAPHQL_URL": "",
    "CI_API_V4_URL": "",
    "CI_COMMIT_AUTHOR": "",
    "CI_COMMIT_BEFORE_SHA": "",
    "CI_COMMIT_BRANCH": "",
    "CI_COMMIT_DESCRIPTION": "",
    "CI_COMMIT_MESSAGE": "",
    [... additional environmental variables ...]
    "entryPoint": "build-job",
    "source": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement"
   },
   "internalParameters": {
    "architecture": "amd64",
    "executor": "docker+machine",
    "job": "10340684631",
    "name": "green-4.saas-linux-small-amd64.runners-manager.gitlab.com/default"
   },
   "resolvedDependencies": [
    {
     "uri": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement",
     "digest": {
      "sha256": "bdd2ecda9ef57b129c88617a0215afc9fb223521"
     }
    }
   ]
  },
  "runDetails": {
   "builder": {
    "id": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement/-/runners/12270857",
    "version": {
     "gitlab-runner": "2147fb44"
    }
   },
   "metadata": {
    "invocationID": "10340684631",
    "startedOn": "2025-06-13T07:25:13Z",
    "finishedOn": "2025-06-13T07:25:40Z"
   }
  }
 }
}
```

## ステージングディレクトリ {#staging-directory}

{{< history >}}

- GitLab Runner 15.0で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3403)されました。

{{< /history >}}

システムのデフォルトの一時ディレクトリにキャッシュとアーティファクトをアーカイブさせない場合は、別のディレクトリを指定できます。

システムのデフォルトの一時パスに制約がある場合は、ディレクトリの変更が必要になることがあります。ディレクトリの場所に高速ディスクを使用すると、パフォーマンスが向上することもあります。

ディレクトリを変更するには、CIジョブで変数として`ARCHIVER_STAGING_DIR`を設定するか、Runnerを登録するときにRunner変数を使用します（`gitlab register --env ARCHIVER_STAGING_DIR=<dir>`）。

指定したディレクトリは、抽出前にアーティファクトをダウンロードする場所として使用されます。`fastzip`アーカイバーを使用する場合、この場所はアーカイブ時のスクラッチ領域としても使用されます。

## パフォーマンスを向上させるために`fastzip`を設定する {#configure-fastzip-to-improve-performance}

{{< history >}}

- GitLab Runner 15.0で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3130)されました。

{{< /history >}}

`fastzip`を調整するには、[`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags)フラグが有効になっていることを確認してください。次に、以下のいずれかの環境変数を使用します。

| 変数                        | 説明 |
|---------------------------------|-------------|
| `FASTZIP_ARCHIVER_CONCURRENCY`  | 同時に圧縮されるファイルの数。デフォルトは、使用可能なCPUの数です。 |
| `FASTZIP_ARCHIVER_BUFFER_SIZE`  | 各ファイルに対して並行処理ごとに割り当てられるバッファサイズ。この数を超えるデータは、スクラッチ領域に移動します。デフォルトは2 MiBです。 |
| `FASTZIP_EXTRACTOR_CONCURRENCY` | 同時に解凍されるファイルの数。デフォルトは、使用可能なCPUの数です。 |

zipアーカイブ内のファイルは、順番に付加されます。そのため、同時圧縮が困難になります。`fastzip`は、最初にファイルをディスクに同時に圧縮し、その結果をzipアーカイブに順番にコピーすることで、この制限を回避します。

小さなファイルの場合、ディスクへの書き込みや内容の読み返しを避けるために、並行処理ごとに小さなバッファが使用されます。この設定は、`FASTZIP_ARCHIVER_BUFFER_SIZE`で制御できます。このバッファのデフォルトサイズは2 MiBであるため、並行処理数が16の場合、32 MiBが割り当てられます。バッファサイズを超えるデータは、ディスクに書き込まれ、そこから読み戻されます。したがって、バッファを使用せずに（`FASTZIP_ARCHIVER_BUFFER_SIZE: 0`）、スクラッチ領域のみを使用することも有効なオプションです。

`FASTZIP_ARCHIVER_CONCURRENCY`は、同時に圧縮されるファイルの数を制御します。前述のように、この設定により、使用されるメモリの量が増加する可能性があります。また、スクラッチ領域に書き込まれる一時データが増加する可能性もあります。デフォルトは使用可能なCPUの数ですが、メモリへの影響を考えると、これは必ずしも最適な設定であるとは限りません。

`FASTZIP_EXTRACTOR_CONCURRENCY`は、一度に解凍されるファイルの数を制御します。zipアーカイブからのファイルは、並行処理でネイティブに読み取ることができるため、エクストラクターが必要とする以上の追加メモリが割り当てられることはありません。これはデフォルトで、使用可能なCPUの数になります。
