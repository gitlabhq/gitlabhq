---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIゲートウェイに関する問題のトラブルシューティングを行います。
title: AIゲートウェイのトラブルシューティング
---

[AIゲートウェイ](install_ai_gateway.md)を使用する際に、次の問題が発生する可能性があります。

## OpenShiftのパーミッションの問題 {#openshift-permission-issues}

OpenShiftにAIゲートウェイをデプロイする場合、OpenShiftのセキュリティモデルにより、パーミッションエラーが発生することがあります。

### `/tmp`での読み取り専用ファイルシステム {#read-only-file-system-at-tmp}

AIゲートウェイは`/tmp`に書き込みます。ただし、OpenShift環境はセキュリティ制限があるため、`/tmp`が読み取り専用になっている場合があります。

この問題を解決するには、新しい`EmptyDir`ボリュームを作成し、次のいずれかの方法で`/tmp`にマウントします:

- コマンドラインから:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- `values.yaml`内:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

### HuggingFaceモデル {#huggingface-models}

デフォルトでは、AIゲートウェイはHuggingFaceモデルのキャッシュに`/home/aigateway/.hf`を使用しますが、OpenShiftのセキュリティ制限がある環境では書き込みできない場合があります。次のようなパーミッションエラーが発生することがあります:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

この問題を解決するには、`HF_HOME`環境変数を書き込み可能な場所に設定します。次のいずれかの方法で、`/var/tmp/huggingface`またはコンテナが書き込み可能な他のディレクトリを使用できます:

- `values.yaml`内:

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- Helmのアップグレードコマンド内:

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

この設定により、OpenShiftのセキュリティ制約に準拠しながら、AIゲートウェイがHuggingFaceモデルを適切にキャッシュできるようになります。選択する正確なディレクトリは、特定のOpenShiftの設定やセキュリティポリシーによって異なる場合があります。

## ボリュームマウントによってトークナイザーのキャッシュが隠される問題 {#tokenizer-cache-shadowed-by-a-volume-mount}

次の場合、AIゲートウェイイメージ内の事前キャッシュされたトークナイザーファイルがボリュームマウントによって隠されることがあります:

- コード補完のリクエストが`500`エラーを返す。
- AIゲートウェイのログに、`transformers/utils/hub.py`から`Salesforce/codegen2-16B`を`huggingface.co`からダウンロードしようとして発生した`OSError`が表示される。

セルフホストのAIゲートウェイイメージ（`self-hosted-vX.Y.Z-ee`）は`HF_HUB_OFFLINE=true`を設定し、ビルド時にトークナイザーを事前キャッシュするため、実行時に`huggingface.co`へのネットワークアクセスは発生しないはずです。ネットワークアクセスが発生する場合、Helmの値にある空のディレクトリが`/home/aigateway/.hf`にマウントされ、キャッシュされたファイルが上書きされている可能性があります。

`huggingface.co`へのエグレスアクセスを許可することでこの問題を解決しようとしないでください。代わりに、問題を診断するには、AIゲートウェイのポッドで次を実行します:

```shell
ls -la /home/aigateway/.hf/hub/ 2>/dev/null || echo "NO_CACHE_DIR"
env | grep -E '^(HF_|TRANSFORMERS_)'
```

キャッシュディレクトリが存在しないか空の場合は、次の操作を行います:

1. `/home/aigateway/.hf`または`HF_HOME`で設定されたパスを対象とする`volumeMounts`がないか、`values.yaml`を確認します。
1. マウントを削除するか、イメージの組み込みキャッシュと重複しないディレクトリに再マッピングします。

## 自己署名証明書のエラー {#self-signed-certificate-error}

AIゲートウェイが、カスタム認証局（CA）によって署名された証明書または自己署名証明書を使用しているGitLabインスタンスまたはモデルエンドポイントに接続しようとすると、次のエラーが発生することがあります:

```plaintext
[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain
```

この問題を解決するには、[自己署名SSL証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続する](install_ai_gateway.md#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate)を参照してください。

## トークン作成の失敗 {#token-creation-failed}

GitLab Duo Chatなどの機能を使用する際に`Token creation failed`エラーが発生する場合、AIゲートウェイに`AIGW_SELF_SIGNED_JWT__SIGNING_KEY`および`AIGW_SELF_SIGNED_JWT__VALIDATION_KEY`環境変数が設定されていない可能性があります。

これらのキーは、AIゲートウェイが短期間有効なユーザーJWTを発行するために必要です。これらのキーがない場合、AIゲートウェイはトークンに署名できず、JWKの逆シリアル化に失敗します。

この問題を解決するには:

1. 必要なキーを生成します:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   ```

1. 環境変数として渡すことで、キーをAIゲートウェイコンテナに追加します:

   ```shell
   -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
   -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)"
   ```

1. AIゲートウェイコンテナを再起動します。

## PEMファイルを読み込む際のSSL証明書エラー {#ssl-certificate-errors-when-loading-pem-files}

PEMファイルをDockerコンテナに読み込む際に`JWKError`というエラーが表示される場合、SSL証明書エラーを解決する必要がある可能性があります。

この問題を解決するには、次の環境変数を使用して、Dockerコンテナ内の適切な証明書バンドルパスを設定します:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

`/path/to/ca-bundle.pem`を、お使いの証明書バンドルへのパスに置き換えてください。

## オフラインのGitLabインスタンスに課金イベントを送信する際のエラー {#errors-when-sending-billing-events-to-an-offline-gitlab-instance}

オフライン環境では、AIゲートウェイはGitLabインスタンス上の`/api/v4/ai/billable_usage/events` APIエンドポイントにイベントを送信します。リクエストが失敗した場合は、AIゲートウェイのログでレスポンスのステータスを確認してください:

- `401`: `AIGW_BILLING_EVENT__API_KEY`が設定されていないか、トークンが無効です。
- `403`: トークンに[`ai_features`スコープ](../security/tokens/access_token_scopes.md)がないか、[サービスアカウント](../user/profile/service_accounts.md#create-a-service-account)に属していません。
- `404`: `local_billing_persistence`機能フラグが無効になっているか、GitLabインスタンスがオフラインライセンスを使用していません。

詳細については、[GitLabインスタンスへの課金イベントの送信](install_ai_gateway.md#send-billing-events-to-an-offline-gitlab-instance)を参照してください。
