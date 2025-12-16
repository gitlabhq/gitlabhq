---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes向けGitLabエージェントのトラブルシューティング
---

Kubernetes向けGitLabエージェントを使用しているときに、トラブルシューティングが必要な問題が発生する可能性があります。

まず、サービスログを表示することから始めます:

```shell
kubectl logs -f -l=app.kubernetes.io/name=gitlab-agent -n gitlab-agent
```

GitLab管理者の場合は、[Kubernetes向けGitLabエージェントサーバーのログ](../../../administration/clusters/kas.md#troubleshooting)も表示できます。

## トランスポート: WebSocketダイアルに失敗したダイアル中のエラー {#transport-error-while-dialing-failed-to-websocket-dial}

```json
{
  "level": "warn",
  "time": "2020-11-04T10:14:39.368Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://gitlab-kas:443/-/kubernetes-agent\\\": dial tcp: lookup gitlab-kas on 10.60.0.10:53: no such host\""
}
```

このエラーは、`kas-address`とエージェントポッドの間に接続の問題がある場合に発生します。この問題を解決するには、`kas-address`が正確であることを確認してください。

```json
{
  "level": "error",
  "time": "2021-06-25T21:15:45.335Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc= \"transport: Error while dialing failed to WebSocket dial: expected handshake response status code 101 but got 301\""
}
```

このエラーは、`kas-address`に末尾のスラッシュが含まれていない場合に発生します。この問題を解決するには、`wss`または`ws`のURLが、`wss://GitLab.host.tld:443/-/kubernetes-agent/`や`ws://GitLab.host.tld:80/-/kubernetes-agent/`のように末尾のスラッシュで終わっていることを確認してください。

## WebSocketダイアルに失敗したダイアル中のエラー: ハンドシェイクリクエストの送信に失敗しました {#error-while-dialing-failed-to-websocket-dial-failed-to-send-handshake-request}

```json
{
  "level": "warn",
  "time": "2020-10-30T09:50:51.173Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent\\\": net/http: HTTP/1.x transport connection broken: malformed HTTP response \\\"\\\\x00\\\\x00\\\\x06\\\\x04\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x05\\\\x00\\\\x00@\\\\x00\\\"\""
}
```

このエラーは、エージェント側で`wss`を`kas-address`として構成したが、`wss`でエージェントサーバーが利用できない場合に発生します。この問題を解決するには、両側で同じスキームが構成されていることを確認してください。

## grpcのエンコードにデコンプレッサーがインストールされていません {#decompressor-is-not-installed-for-grpc-encoding}

```json
{
  "level": "warn",
  "time": "2020-11-05T05:25:46.916Z",
  "msg": "GetConfiguration.Recv failed",
  "error": "rpc error: code = Unimplemented desc = grpc: Decompressor is not installed for grpc-encoding \"gzip\""
}
```

このエラーは、エージェントのバージョンがエージェントサーバー（KAS）のバージョンより新しい場合に発生します。この問題を修正するには、`agentk`とエージェントサーバーの両方が同じバージョンであることを確認してください。

## 不明な認証局によって署名された証明書 {#certificate-signed-by-unknown-authority}

```json
{
  "level": "error",
  "time": "2021-02-25T07:22:37.158Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent/\\\": x509: certificate signed by unknown authority\""
}
```

このエラーは、GitLabインスタンスが、エージェントに不明な内部認証局によって署名された証明書を使用している場合に発生します。

この問題を修正するには、[Helmインストールのカスタマイズ](install/_index.md#customize-the-helm-installation)によって、CA証明書ファイルをエージェントに提示します。`helm install`コマンドに`--set-file config.kasCaCert=my-custom-ca.pem`を追加します。ファイルは、有効なPEMまたはDERエンコードされた証明書である必要があります。

`agentk`を設定された`config.kasCaCert`値でデプロイすると、証明書が`configmap`に追加され、証明書ファイルが`/etc/ssl/certs`にマウントされます。

たとえば、`kubectl get configmap -lapp=gitlab-agent -o yaml`コマンドを使用します:

```yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    ca.crt: |-
      -----BEGIN CERTIFICATE-----
      MIIFmzCCA4OgAwIBAgIUE+FvXfDpJ869UgJitjRX7HHT84cwDQYJKoZIhvcNAQEL
      ...truncated certificate...
      GHZCTQkbQyUwBWJOUyOxW1lro4hWqtP4xLj8Dpq1jfopH72h0qTGkX0XhFGiSaM=
      -----END CERTIFICATE-----
  kind: ConfigMap
  metadata:
    annotations:
      meta.helm.sh/release-name: self-signed
      meta.helm.sh/release-namespace: gitlab-agent-self-signed
    creationTimestamp: "2023-03-07T20:12:26Z"
    labels:
      app: gitlab-agent
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: gitlab-agent
      app.kubernetes.io/version: v15.9.0
      helm.sh/chart: gitlab-agent-1.11.0
    name: self-signed-gitlab-agent
    resourceVersion: "263184207"
kind: List
```

GitLabアプリケーションサーバーの[エージェントサーバー (KAS) logs](../../../administration/logs/_index.md#gitlab-agent-server-for-kubernetes-logs)に同様のエラーが表示される場合があります:

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

このエラーを解決するには、`/etc/gitlab/trusted-certs`ディレクトリに[内部CAの公開証明書をインストール](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)します。

または、カスタムディレクトリから証明書を読み取るようにKASを設定することもできます。次の設定を`/etc/gitlab/gitlab.rb`に追加します:

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

変更を適用するには、再構成します:

1. GitLabを再構成します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-kas`を再起動します。

   ```shell
   gitlab-ctl restart gitlab-kas
   ```

## エラー: `Failed to register agent pod` {#error-failed-to-register-agent-pod}

エージェントポッドのログに、エラーメッセージ`Failed to register agent pod. Please make sure the agent version matches the server version`が表示される場合があります。

この問題を解決するには、エージェントのバージョンがGitLabのバージョンと一致していることを確認してください。

バージョンが一致し、エラーが解決しない場合:

1. `gitlab-kas`が`gitlab-ctl status gitlab-kas`で実行されていることを確認します。
1. エージェントが正常に機能していることを確認するには、`gitlab-kas` [ログ](../../../administration/logs/_index.md#gitlab-agent-server-for-kubernetes-logs)を確認してください。

## ワークロードで脆弱性スキャンを実行できませんでした: jobs.batchは既に存在します {#failed-to-perform-vulnerability-scan-on-workload-jobsbatch-already-exists}

```json
{
  "level": "error",
  "time": "2022-06-22T21:03:04.769Z",
  "msg": "Failed to perform vulnerability scan on workload",
  "mod_name": "starboard_vulnerability",
  "error": "running scan job: creating job: jobs.batch \"scan-vulnerabilityreport-b8d497769\" already exists"
}
```

Kubernetes向けGitLabエージェントは、各ワークロードをスキャンするジョブを作成することにより、脆弱性スキャンを実行します。スキャンが中断された場合、これらのジョブが残され、さらにジョブを実行する前にクリーンアップする必要がある場合があります。次のコマンドを実行して、これらのジョブをクリーンアップできます:

```shell
kubectl delete jobs -l app.kubernetes.io/managed-by=starboard -n gitlab-agent
```

[これらのジョブのクリーンアップをより堅牢にする作業を進めています。](https://gitlab.com/gitlab-org/gitlab/-/issues/362016)

## 解析中のエラー {#parse-error-during-installation}

エージェントをインストールすると、次のエラーが発生する場合があります:

```shell
Error: parse error at (gitlab-agent/templates/observability-secret.yaml:1): unclosed action
```

このエラーは通常、互換性のないバージョンのHelmによって発生します。この問題を解決するには、Helmのバージョンが[Kubernetesのバージョンと互換性がある](_index.md#supported-kubernetes-versions-for-gitlab-features)ことを確認してください。

## Kubernetes用ダッシュボードのエラー`GitLab Agent Server: Unauthorized` {#gitlab-agent-server-unauthorized-error-on-dashboard-for-kubernetes}

[Kubernetes用ダッシュボード](../../../ci/environments/kubernetes_dashboard.md)ページの`GitLab Agent Server: Unauthorized. Trace ID: <...>`のようなエラーは、次のいずれかが原因である可能性があります:

- エージェントの設定ファイルの`user_access`エントリが存在しないか、間違っています。解決するには、[Kubernetesアクセス権をユーザーに付与する](user_access.md)を参照してください。
- ブラウザーに複数の[`_gitlab_kas` cookie](../../../administration/clusters/kas.md#kubernetes-api-proxy-cookie)があり、KASに送信されました。最も可能性が高い原因は、同じサイトでホストされている複数のGitLabインスタンスです。

  たとえば、`gitlab.com`は`kas.gitlab.com`をターゲットとする`_gitlab_kas` cookieを設定しましたが、cookieは`kas.staging.gitlab.com`にも送信されるため、`staging.gitlab.com`でエラーが発生します。

  一時的に解決するには、ブラウザのcookieストアから`gitlab.com`の`_gitlab_kas` cookieを削除します。[イシュー418998](https://gitlab.com/gitlab-org/gitlab/-/issues/418998)は、この既知の問題の修正を提案しています。
- GitLabとKASは異なるサイトで実行されます。たとえば、GitLabは`gitlab.example.com`で、KASは`kas.example.com`で実行されます。GitLabはこのユースケースをサポートしていません。詳細については、[issue 416436](https://gitlab.com/gitlab-org/gitlab/-/issues/416436)を参照してください。

## エージェントのバージョンの不一致 {#agent-version-mismatch}

GitLabのKubernetesクラスターページの**エージェント**タブに、`Agent version mismatch: The agent versions do not match each other across your cluster's pods.`という警告が表示される場合があります。

この警告は、Kubernetes（`kas`）用のエージェントサーバーによって古いバージョンのエージェントがキャッシュされていることが原因である可能性があります。`kas`は、期限切れのエージェントのバージョンを定期的に削除するため、エージェントとGitLabが調整されるまで、少なくとも20分待つ必要があります。

警告が解決しない場合は、クラスターにインストールされているエージェントを更新してください。

## Kubernetes APIプロキシの応答ヘッダーが失われるか、ブロックされます {#kubernetes-api-proxy-response-headers-are-lost-or-blocked}

KubernetesクラスターからKubernetes APIプロキシを介してユーザーに送信されると、HTTP応答ヘッダーがブロックされる可能性があります。

このエラーは、応答ヘッダーがKASのデフォルトの許可リストに含まれていない場合に発生する可能性があります。

この問題を解決する方法については、[ブロックされた応答ヘッダー](../../../administration/clusters/kas.md#error-blocked-kubernetes-api-proxy-response-header)を参照してください。
