---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リカバリーキー管理
---

リカバリーキーは、OpenBaoの緊急クレデンシャルです。プライマリJWT認証メソッドが使用できなくなったときに、一時的なルートトークンを生成するために使用します。

リカバリーキーは、シークレットフェッチやネームスペースプロビジョニングなどの通常の操作では使用されません。高特権のクレデンシャルとして扱い、安全に保存してください。

> [!warning]
> リカバリーキーはOpenBaoデータベースに保存されているデータを復号化することはできません。すべてのOpenBaoデータは、設定されたアンシールメカニズムによって保護されています。これは、`gitlab-openbao-unseal` Kubernetesシークレットに保存されている静的キー、あるいは外部KMSのいずれかです。アンシールメカニズムは、リカバリーキーとは別にバックアップしてください。

このページでコマンドを実行するには、ツールボックスポッドの名前が必要です。それを見つけるには、次を実行します:

```shell
kubectl get pods -n gitlab -lapp=toolbox
```

以下のコマンドでは、`<toolbox-pod-name>`の代わりにポッド名を使用してください。

## リカバリーキーを保存 {#store-the-recovery-key}

インシデントが発生する前に、初期設定時にこのコマンドを一度実行してください:

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:store"
```

このコマンドはOpenBaoでリカバリーキーを生成し、暗号化された状態でGitLabデータベースに保存します。

> [!warning]
> リカバリーキーは1度しか生成できません。`recovery_key:store`を2回目に実行したり、`recovery_key:fetch`の実行後に実行したりすることはできません。

このコマンドを実行するまで、OpenBaoはポッドを再起動するたびに警告`[WARN]  core: post-unseal upgrade seal keys failed: error="no recovery key found"`をログに記録します。キーを保存すると、その警告は停止します。

## 保存されたリカバリーキーを表示 {#view-the-stored-recovery-key}

GitLabデータベースからリカバリーキーをフェッチして表示するには、次を実行します:

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
```

> [!warning]
> コマンドは、キーをプレーンテキストで表示する前に確認を求めます。出力を安全に保存してください。ログに記録したり、安全なチャンネル以外で共有したりしないでください。

## リカバリーキーを保存せずにフェッチ {#fetch-the-recovery-key-without-storing-it}

`recovery_key:fetch`を使用して、リカバリーキーをGitLabデータベースに保存せずにターミナルに生成および表示します。このタスクは、キーを外部システム（パスワードマネージャーやハードウェアセキュリティモジュールなど）に保存する場合に使用します。

> [!warning]
> リカバリーキーは1度しか生成できません。`recovery_key:fetch`を2回目に実行したり、`recovery_key:store`の実行後に実行したりすることはできません。

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:fetch"
```

このタスクは、キーを生成および表示する前に確認を求めます。キーはプレーンテキストで表示されます。

## リカバリーキーからルートトークンを生成 {#generate-a-root-token-from-the-recovery-key}

JWT認証の再構成やシールの移行など、特権的なOpenBao操作を実行する必要がある場合は、リカバリーキーを使用して一時的なルートトークンを生成します。たとえば、別のドメインを持つGeoセカンダリサイトに失敗した場合などです。詳細については、[JWT認証を設定](../geo/disaster_recovery/_index.md#optional-configure-jwt-authentication)を参照してください。

> [!warning]
> 必要な操作が完了したらすぐにルートトークンを失効する。ルートトークンは、すべてのOpenBao操作およびネームスペースへの無制限のアクセス権を持ちます。

`bao`バイナリはOpenBaoポッド内で利用可能です。すべてのコマンドは`kubectl exec`を使用して実行します。ポートフォワードは不要です。

1. リカバリーキーを取得する:

   ```shell
   kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
     gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
   ```

   `recovery_key:fetch`を使用してキーを外部に保存した場合は、代わりにその場所から取得する。

1. OpenBaoポッド名を取得する:

   ```shell
   kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name
   ```

   以下のステップでは、`<openbao-pod-name>`をこのコマンドからの出力で置き換えます。たとえば、`pod/gitlab-openbao-0`などです。

1. OTPを生成する:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -generate-otp"
   ```

   以下のコマンドでは、`<otp>`をこの出力で置き換えます。

1. ルート生成を初期化する:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -init -otp=<otp>"
   ```

   成功した応答には、`Started: true`と`Nonce`の値が含まれます。以下のステップでは、`<nonce>`をこの`Nonce`の値で置き換えます。

1. リカバリーキーを送信する:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "echo '<recovery_key>' | BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -nonce=<nonce>"
   ```

   OpenBaoは単一のリカバリーキーシェアで設定されているため、操作はすぐに完了します。成功した応答には、`Complete: true`と`Encoded Token`の値が含まれます。次のステップでは、`<encoded_token>`をこのトークン値で置き換えます。

1. ルートトークンをデコードする:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -decode=<encoded_token> -otp=<otp>"
   ```

   以下のステップでは、`<root_token>`をデコードされたルートトークンで置き換えます。

1. ルートトークンが機能することを確認する:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token lookup"
   ```

   成功した応答には`policies  [root]`が含まれます。

1. 必要な特権操作を実行します。

1. ルートトークンを失効する:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token revoke -self"
   ```
