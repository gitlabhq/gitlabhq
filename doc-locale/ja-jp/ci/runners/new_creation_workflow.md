---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 新しいRunner登録ワークフローに移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="disclaimer" />}}

GitLab 16.0では、Runner認証トークンを使用してRunnerを登録する新しいRunner作成ワークフローが導入されました。登録トークンを使用する従来のワークフローは非推奨になりました。削除について計画されているマイルストーンまたは日付はありません。代わりに、Runner作成ワークフローを使用してください。 

新しいワークフローの現在の開発状況については、[エピック7663](https://gitlab.com/groups/gitlab-org/-/epics/7663)を参照してください。

新しいアーキテクチャの技術設計と理論については、[次のGitLab Runnerトークンアーキテクチャ](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/runner_tokens/)を参照してください。

新しいRunner登録ワークフローに関して問題が発生した場合や懸念がある場合、または詳細情報が必要な場合は、[イシューをフィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/387993)でお知らせください。

## 新しいRunner登録ワークフロー

新しいRunner登録ワークフローでは、次のことを行います。

1. GitLab UIで直接、または[プログラムで](#creating-runners-programmatically)[Runnerを作成](runners_scope.md)します。
1. Runner認証トークンを受信します。
1. この設定でRunnerを登録する場合は、登録トークンの代わりにRunner認証トークンを使用します。複数のホストに登録されているRunnerマネージャーは、GitLab UIの同じRunnerに表示されますが、識別システムIDが付きます。

新しいRunner登録ワークフローには、次の利点があります。

- Runnerの所有権レコードを保持し、ユーザーへの影響を最小限に抑えました。
- 一意のシステムIDを追加すると、複数のRunnerで同じ認証トークンを再利用できるようになります。詳細については、[GitLab Runner設定の再利用](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-gitlab-runner-configuration)を参照してください。

## 計画された変更の推定時期

- GitLab 15.10以降で新しいRunner登録ワークフローを使用できます。
- GitLab 17.0で、Runner登録トークンを無効にする予定です。

## Runner登録ワークフローが中断しないようにする

GitLab 16.11以前では、従来のRunner登録ワークフローを使用できます。

GitLab 17.0では、従来のRunner登録ワークフローはデフォルトで無効になっています。従来のRunner登録ワークフローは、一時的に再有効化できます。詳細については、[GitLab 17.0以降で登録トークンを使用する](#using-registration-tokens-after-gitlab-170)を参照してください。

GitLab 17.0へのアップグレード時に新しいワークフローに移行しない場合、Runner登録が中断し、`gitlab-runner register`コマンドが`410 Gone - runner registration disallowed`エラーを返します。

ワークフローの中断を回避するには、次の操作を行います。

1. [Runnerを作成し](runners_scope.md)、認証トークンを取得します。
1. Runner登録ワークフローの登録トークンを、認証トークンに置き換えます。

{{< alert type="warning" >}}

GitLab 17.0以降では、Runner登録トークンは無効になっています。保存されたRunner登録トークンを使用して新しいRunnerを登録するには、[トークンを有効にする](../../administration/settings/continuous_integration.md#allow-runner-registration-tokens)必要があります。

{{< /alert >}}

## GitLab 17.0以降で登録トークンを使用する

GitLab 17.0以降で引き続き登録トークンを使用するには:

- GitLab.comでは、トップレベルグループ設定で[従来のRunner登録プロセスを手動で有効化できます](runners_scope.md#enable-use-of-runner-registration-tokens-in-projects-and-groups)。
- GitLab Self-Managedでは、**管理者**エリアの設定で[従来のRunner登録プロセスを手動で有効化できます](../../administration/settings/continuous_integration.md#allow-runner-registration-tokens)。

## 既存のRunnerへの影響

既存のRunnerは、GitLab 17.0にアップグレードした後も通常どおり動作します。この変更は、新しいRunnerの登録にのみ影響します。

[GitLab Runner Helmチャート](https://docs.gitlab.com/runner/install/kubernetes.html)は、ジョブが実行されるたびに新しいRunnerポッドを生成します。これらのRunnerについては、[従来のRunner登録を有効にする](#using-registration-tokens-after-gitlab-170)と、登録トークンを使用できます。GitLab 18.0以降では、[新しいRunner登録ワークフロー](#the-new-runner-registration-workflow)に移行する必要があります。

## `gitlab-runner register`コマンド構文の変更

`gitlab-runner register`コマンドは、登録トークンの代わりにRunner認証トークンを受け入れます。トークンは、**管理者**エリアの**Runner**ページから生成できます。Runner認証トークンは、`glrt-`プレフィックスで認識できます。

GitLab UIでRunnerを作成する場合、以前は`gitlab-runner register`コマンドでプロンプトが表示されていた設定値を指定します。これらのコマンドラインオプションは[非推奨](../../update/deprecations.md#registration-tokens-and-server-side-runner-arguments-in-post-apiv4runners-endpoint)になりました。

Runner認証トークンを次のように指定した場合:

- `--token`コマンドラインオプションを指定すると、`gitlab-runner register`コマンドは設定値を受け入れません。
- `--registration-token`コマンドラインオプションを指定すると、`gitlab-runner register`コマンドは設定値を無視します。

| トークン                                  | 登録コマンド                                                                                      |
|----------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Runner認証トークン            | `gitlab-runner register --token $RUNNER_AUTHENTICATION_TOKEN`                                             |
| Runner登録トークン（非推奨） | `gitlab-runner register --registration-token $RUNNER_REGISTRATION_TOKEN <runner configuration arguments>` |

認証トークンのプレフィックスは`glrt-`です。

自動化ワークフローへの影響を最小限に抑えるため、[従来の互換性のある登録処理](https://docs.gitlab.com/runner/register/#legacy-compatible-registration-process)は、従来のパラメーター`--registration-token`でRunner認証トークンが指定されている場合にトリガーされます。

GitLab 15.9のコマンド例:

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --tag-list "shell,mac,gdk,test" \
    --run-untagged "false" \
    --locked "false" \
    --access-level "not_protected" \
    --registration-token "REDACTED"
```

GitLab 15.10以降では、Runnerの作成や、タグリスト、ロックされたステータス、アクセスレベルなどの属性の設定をUIで実行できます。GitLab 15.11以降では、`glrt-`プレフィックスが付いたRunner認証トークンが指定されている場合、これらの属性は`register`への引数として受け入れられなくなりました。

新しいコマンドの例を次に示します。

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "REDACTED"
```

## 自動スケールへの影響

GitLab Runner OperatorやGitLab Runner Helmチャートなどの自動スケールシナリオでは、UIで生成されたRunner認証トークンが登録トークンを置き換えます。つまり、ジョブごとにRunnerを作成する代わりに、同じRunner設定がジョブ全体で再利用されます。特定のRunnerは、Runnerプロセスが開始されたときに生成される一意のシステムIDによって識別できます。

## プログラムによるRunnerの作成

GitLab 15.11以降では、[POST /user/runners REST API](../../api/users.md#create-a-runner-linked-to-a-user)を使用して、認証済みユーザーとしてRunnerを作成できます。これは、Runner設定が動的であるか、再利用できない場合にのみ使用してください。Runner設定が静的な場合は、既存のRunnerのRunner認証トークンを再利用してください。

Runnerの作成と登録を自動化する方法については、チュートリアル[Runnerの作成と登録の自動化](../../tutorials/automate_runner_creation/_index.md)を参照してください。

## Helmチャートを使用してGitLab Runnerをインストールする

一部のRunner設定オプションは、Runnerの登録中に設定できません。これらのオプションは、次の場合にのみ設定できます。

- UIでRunnerを作成する場合。
- `user/runners` REST APIエンドポイントを使用する場合。

次の設定オプションは、[`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/main/values.yaml)ではサポートされなくなりました。

```yaml
## All these fields are DEPRECATED and the runner WILL FAIL TO START with GitLab Runner 18.0 and later if you specify them.
## If a runner authentication token is specified in runnerRegistrationToken, the registration will succeed, however the
## other values will be ignored.
runnerRegistrationToken: ""
locked: true
tags: ""
maximumTimeout: ""
runUntagged: true
protected: true
```

`runnerRegistrationToken`フィールドは、`runnerToken`フィールドを置き換えます。Kubernetes上のGitLab Runnerの場合、HelmデプロイはRunner`authentication token`をRunnerワーカーポッドに渡し、Runner設定を作成します。GitLab 17.0では、GitLab.comにアタッチされたKubernetesホスト型Runnerが`runnerRegistrationToken`を使用する場合、Runnerワーカーポッドは作成時にサポートされていないRegistration APIメソッドを使用します。

Runner認証トークンを`secrets`に保存する場合は、それらも変更する必要があります。

従来のRunner登録ワークフローでは、フィールドは次のように指定されていました。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "REDACTED" # DEPRECATED, set to ""
  runner-token: ""
```

新しいRunner登録ワークフローでは、代わりに`runner-token`を使用する必要があります。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "" # need to leave as an empty string for compatibility reasons
  runner-token: "REDACTED"
```

{{< alert type="note" >}}

シークレット管理ソリューションで`runner-registration-token`に空の文字列を設定できない場合は、任意の文字列に設定できます。この値は、`runner-token`が存在する場合は無視されます。

{{< /alert >}}

## 既知の問題

### ポッド名がRunner詳細ページに表示されない

新しい登録ワークフローを使用してHelmチャートでRunnerを登録すると、ポッド名がRunner詳細ページに表示されません。詳細については、[イシュー423523](https://gitlab.com/gitlab-org/gitlab/-/issues/423523)を参照してください。

### Runner認証トークンがローテーション時に更新されない

#### 複数のRunnerマネージャーに登録されている同じRunnerでのトークンローテーション

自動トークンローテーションによる新しいワークフローを介して複数のホストマシンにRunnerを登録すると、最初のRunnerマネージャーのみが新しいトークンを受信します。残りのRunnerマネージャーは無効なトークンを引き続き使用するため、接続が解除されます。新しいトークンを使用するには、これらのマネージャーを手動で更新する必要があります。

#### GitLab Operatorでのトークンローテーション

新しいワークフローを介したGitLab Operatorを使用したRunnerの登録中、カスタムリソース定義のRunner認証トークンはトークンローテーション中に更新されません。これは次の場合に発生します。

- [カスタムリソース定義によって参照される](https://docs.gitlab.com/runner/install/operator.html#install-gitlab-runner)シークレットで、Runner認証トークン（`glrt-`プレフィックス付き）を使用している。
- Runner認証トークンに有効期限がある。Runner認証トークンの有効期限の詳細については、[認証トークンのセキュリティ](configure_runners.md#authentication-token-security)を参照してください。

詳細については、[イシュー186](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/186)を参照してください。
