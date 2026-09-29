---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 自己ホスト型Sigstoreスタックを使用してCI/CDアーティファクトとコンテナイメージに署名します。これにはFulcio設定とトラブルシューティングが含まれます。
title: 自己ホスト型Sigstoreでアーティファクトとコンテナイメージに署名する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managedを実行している場合、パブリックな[Sigstoreサービス](signing_examples.md)を使用してCI/CDアーティファクトとコンテナイメージに署名することはできません。このサービスはGitLab.comパイプラインのみを信頼し、独自のインスタンスからのパイプラインは信頼しません。代わりに、独自のSigstoreインフラストラクチャ（Fulcio、Rekor、および証明書透明性ログ）をGitLabインスタンスに接続することで、GitLab.comやインターネットに依存することなく、Cosignでアーティファクトに署名および検証できます。

GitLab OpenID Connect（OIDC）プロバイダがあなたの身元を証明し、Cosignは使用直後に署名キーを破棄し、Rekorはすべての署名イベントを透明性ログに記録します。

Fulcioが発行する証明書は署名に埋め込まれ、プロジェクトパス、コミットSHA、パイプラインソース、Runner環境、ジョブURLなど、どのパイプラインがそれを作成したかについての詳細が含まれます。

前提条件: 

- Sigstoreインフラストラクチャ（Fulcio、Rekor）およびGitLab CI/CD Runnerを設定するためのアクセス。
- ネットワークで実行されている自己ホスト型Sigstoreスタック。これにはFulcio、Rekor、および証明書透明性ログが含まれます。証明書透明性ログが必要です。Cosignは検証中に署名付き証明書タイムスタンプを検証するため、証明書透明性ログなしでデプロイされたFulcioは、Cosignが検証できない証明書を発行します。デプロイ手順については、以下を参照してください:
  - RekorとそのTrillianバックエンドの[Sigstore透明性ログインストールガイド](https://docs.sigstore.dev/logging/installation/)
  - Fulcioと証明書透明性ログの[Fulcioリポジトリ](https://github.com/sigstore/fulcio)
- 永続的な署名キーで設定されたRekor。
- GitLabインスタンスがプライベート認証局を使用するHTTPSを使用している場合、その認証局はFulcioとCI/CD Runnerの両方から信頼されている必要があります:
  - Fulcioコンテナにマウントされた認証局証明書。`SSL_CERT_FILE`をそのパスに設定します。
  - 各Runnerのオペレーティングシステム信頼ストアにインストールされた認証局証明書。
- CI/CD Runnerにインストールされた[Cosign](https://docs.sigstore.dev/cosign/system_config/installation/) v2.x以降。
- Sigstoreスタックからの信頼マテリアルファイルは、`/etc/sigstore/`のような共有場所にRunner上に配置されます:
  - FulcioルートCA証明書（`fulcio-root.pem`）
  - Rekor透明性ログ公開キー（`rekor-pub.pem`）
  - 証明書透明性ログ公開キー（`ctfe-pub.pem`）

## GitLabインスタンスを信頼するようにFulcioを設定する {#configure-fulcio-to-trust-your-gitlab-instance}

GitLabインスタンスを信頼するようにFulcioを設定して、キーレス署名中にGitLab CI/CDジョブからのOIDCトークンを検証できるようにします。Fulcioはトークンのクレームを署名証明書のフィールドにマップします。設定ファイルには、`oidc-issuers`セクションと`ci-issuer-metadata`セクションの両方が必要です。

Fulcioを設定するには:

1. 次のコマンドで正確なOIDC発行者URLを取得します。`https://gitlab.example.com`をGitLabインスタンスのURLに置き換えてください。Fulcioは正確な一致を必要とします。スキームと末尾のスラッシュの有無の両方が重要です。

   ```shell
   curl --silent "https://gitlab.example.com/.well-known/openid-configuration" | jq --raw-output .issuer
   ```

1. GitLabインスタンスの`oidc-issuers`エントリを持つFulcio OIDC設定ファイルを作成します。前のステップからの出力で`<gitlab_issuer_url>`を置き換えてください:

   ```yaml
   oidc-issuers:
     <gitlab_issuer_url>:
       issuer-url: <gitlab_issuer_url>
       client-id: sigstore
       type: ci-provider
       ci-provider: gitlab-pipeline
       contact: admin@example.com
       description: "GitLab Self-Managed OIDC"
   ```

1. 同じファイルで、[アップストリームのFulcio設定](https://github.com/sigstore/fulcio/blob/main/config/identity/config.yaml)からコピーしたGitLabクレームテンプレートを含む`ci-issuer-metadata`セクションを追加します。前のステップで使用したのと同じ値で`<gitlab_issuer_url>`を置き換えてください。

   各クレームが何にマップされるかについては、[OIDCトークンクレームからFulcio OIDへのマッピング](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md#mapping-oidc-token-claims-to-fulcio-oids)のGitLab列を参照してください。

   ```yaml
   ci-issuer-metadata:
     gitlab-pipeline:
       default-template-values:
         url: "<gitlab_issuer_url>"
         environment: ""
       extension-templates:
         build-signer-uri: "https://{{ .ci_config_ref_uri }}"
         build-signer-digest: "ci_config_sha"
         runner-environment: "runner_environment"
         source-repository-uri: "{{ .url }}/{{ .project_path }}"
         source-repository-digest: "sha"
         source-repository-ref: >-
           refs/{{if eq .ref_type "branch"}}heads/{{ else }}tags/{{end}}{{ .ref }}
         source-repository-identifier: "project_id"
         source-repository-owner-uri: "{{ .url }}/{{ .namespace_path }}"
         source-repository-owner-identifier: "namespace_id"
         build-config-uri: "https://{{ .ci_config_ref_uri }}"
         build-config-digest: "ci_config_sha"
         build-trigger: "pipeline_source"
         run-invocation-uri: >-
           {{ .url }}/{{ .project_path }}/-/jobs/{{ .job_id }}
         source-repository-visibility-at-signing: "project_visibility"
         deployment-environment: "environment"
       subject-alternative-name-template: "https://{{ .ci_config_ref_uri }}"
   ```

   > [!note]
   > このセクションはGitLabではなくSigstoreプロジェクトによって維持されています。変更がないかアップストリームファイルを定期的に確認し、それに合わせてコピーを更新してください。

## アーティファクトとコンテナイメージに署名する {#sign-artifacts-and-container-images}

ジョブのOIDCトークンを生成するには、`id_tokens`キーワードを使用します。CosignはこのトークンをFulcioに提示し、Fulcioは一時的な署名証明書を発行します。

Cosign v3は、署名設定ファイルを使用してSigstoreサービスエンドポイントと信頼マテリアルを指定します。これらのファイルを一度生成してRunnerに配布するか、次の例に示すように各ジョブで生成します。

```yaml
sign-artifact:
  stage: sign
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  variables:
    COSIGN_YES: "true"
  script:
    - cosign signing-config create
        --fulcio="url=http://<sigstore-host>:5555,api-version=1,start-time=2024-01-01T00:00:00Z,operator=my-org"
        --rekor="url=http://<sigstore-host>:3000,api-version=1,start-time=2024-01-01T00:00:00Z,operator=my-org"
        --rekor-config="ANY"
        --oidc-provider="url=https://gitlab.example.com,api-version=1,start-time=2024-01-01T00:00:00Z,operator=my-org"
        --out signing-config.json
    - cosign trusted-root create
        --fulcio="url=http://<sigstore-host>:5555,certificate-chain=/etc/sigstore/fulcio-root.pem,start-time=2024-01-01T00:00:00Z"
        --rekor="url=http://<sigstore-host>:3000,public-key=/etc/sigstore/rekor-pub.pem,start-time=2024-01-01T00:00:00Z"
        --ctfe="url=http://<sigstore-host>:6962,public-key=/etc/sigstore/ctfe-pub.pem,start-time=2024-01-01T00:00:00Z"
        --out trusted-root.json
    - cosign sign-blob
        --signing-config=signing-config.json
        --trusted-root=trusted-root.json
        --oidc-client-id=sigstore
        --identity-token=$SIGSTORE_ID_TOKEN
        --bundle=artifact.bundle
        artifact.txt
```

`start-time`の値は、[Sigstore protobuf仕様](https://github.com/sigstore/protobuf-specs)で定義されているように、サービスエンドポイントが有効と見なされる最も早い時刻です。Sigstoreスタックがデプロイされた日付を使用します。

`--oidc-client-id`の`sigstore`を、Fulcio OIDC発行者エントリで設定されたクライアントIDに置き換えてください。

Fulcio `oidc-issuers`設定で登録したのと同じ発行者URLを`--oidc-provider`に使用します。

### コンテナイメージに署名する {#sign-container-images}

コンテナイメージに署名するには、ファイルパスの代わりにイメージ参照とともに`cosign sign`を使用します。署名設定は同じです。

コンテナレジストリは、解決可能なホスト名でHTTPS経由で到達可能でなければなりません。レジストリは、独自の外部URLで認証レルムをアドバタイズします。Cosignは、ホストがリテラルプライベートまたはリンクローカルアドレスであるレルムを拒否します。`registry_external_url`がIPアドレスのみであるインスタンスはファイルに署名できますが、コンテナイメージには署名できません。

### Cosign v2.xの場合 {#for-cosign-v2x}

Cosign v2.xを使用している場合は、設定ファイルの代わりにURLフラグと環境変数を使用します:

```yaml
sign-artifact:
  stage: sign
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  variables:
    COSIGN_YES: "true"
    SIGSTORE_ROOT_FILE: /etc/sigstore/fulcio-root.pem
    SIGSTORE_REKOR_PUBLIC_KEY: /etc/sigstore/rekor-pub.pem
    SIGSTORE_CT_LOG_PUBLIC_KEY_FILE: /etc/sigstore/ctfe-pub.pem
  script:
    - cosign sign-blob
        --fulcio-url=http://<sigstore-host>:5555
        --rekor-url=http://<sigstore-host>:3000
        --oidc-issuer=https://gitlab.example.com
        --identity-token=$SIGSTORE_ID_TOKEN
        --output-signature=artifact.sig
        --output-certificate=artifact.crt
        artifact.txt
```

コンテナイメージの場合、[コンテナイメージに署名する](#sign-container-images)で説明されているようにCosign v3を使用します。

Cosign v2は証明書をbase64エンコードされたPEMとして書き込みます。別のツールに渡す前にデコードしてください。

Fulcio `oidc-issuers`設定で登録したのと同じ発行者URLを`--oidc-issuer`に使用します。

## 署名を検証する {#verify-signatures}

Cosign v3バンドルによる検証では、信頼マテリアルと予想される署名者のIDを使用します:

```shell
cosign verify-blob \
  --trusted-root=trusted-root.json \
  --bundle=artifact.bundle \
  --certificate-oidc-issuer=https://gitlab.example.com \
  --certificate-identity=https://gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main \
  artifact.txt
```

`--certificate-identity`の値は署名証明書のサブジェクト代替名であり、CI/CD設定パスから構築されます:

```plaintext
https://<CI_SERVER_HOST>/<CI_PROJECT_PATH>//.gitlab-ci.yml@<full ref>
```

そのパターンにおいて3つの詳細が重要です:

- スキームは常に`https://`です。これは、Fulcio設定の`subject-alternative-name-template`がそれを設定しているためです。これは、インスタンスがHTTP経由で到達可能な場合でも当てはまります。
- `.gitlab-ci.yml`の前の二重スラッシュは正しいです。その前のパスセグメントはプロジェクトであり、それに続く空のセグメントはデフォルトのCI/CD設定場所を保持します。
- 完全な参照は、ブランチパイプラインの場合は`refs/heads/<branch>`、タグパイプラインの場合は`refs/tags/<tag>`です。

Cosign v2で署名されたアーティファクトを検証するには、デタッチされた署名と証明書を渡します:

```shell
cosign verify-blob \
  --signature=artifact.sig \
  --certificate=artifact.crt \
  --certificate-oidc-issuer=https://gitlab.example.com \
  --certificate-identity=https://gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main \
  artifact.txt
```

## 関連トピック {#related-topics}

- パブリックSigstoreインスタンスを使用したGitLab.comの[署名例](signing_examples.md)
- [CI/CD OIDC IDトークン](../secrets/id_token_authentication.md)
- [Sigstore: カスタムコンポーネント](https://docs.sigstore.dev/cosign/system_config/custom_components/)

## トラブルシューティング {#troubleshooting}

自己ホスト型Sigstoreインフラストラクチャでアーティファクトに署名する際、次の問題が発生する可能性があります。

### エラー: `metadata not found for ci provider gitlab-pipeline` {#error-metadata-not-found-for-ci-provider-gitlab-pipeline}

このエラーは、Fulcio設定から`ci-issuer-metadata`セクションが欠落している場合に発生します。

この問題を解決するには、[GitLabインスタンスを信頼するようにFulcioを設定する](#configure-fulcio-to-trust-your-gitlab-instance)で文書化されているように、完全な`ci-issuer-metadata`ブロックを追加します。

### エラー: `ctfe public key not found for payload` {#error-ctfe-public-key-not-found-for-payload}

このエラーは、Cosignが自己ホスト型スタックの証明書透明性ログ公開キーを見つけられない場合に発生します。

この問題を解決するには、Cosign v3の`cosign trusted-root create`コマンドに`--ctfe`を含めるか、Cosign v2の`SIGSTORE_CT_LOG_PUBLIC_KEY_FILE`環境変数を設定します。

### エラー: `not enough verified log entries from transparency log` {#error-not-enough-verified-log-entries-from-transparency-log}

このエラーは、`trusted-root.json`のRekor公開キーがRekorインスタンスが使用しているキーと一致しなくなった場合に発生します。インメモリ署名者は、再起動のたびに新しいキーと新しい空のマークルツリー（Rekorの改ざん防止ログ構造）を生成します。したがって、再起動により信頼マテリアルが無効になり、再構築されるまですべてのジョブで署名が失敗します。

この問題を解決するには、実行中のインスタンスから現在のキーを読み込み、信頼されたルートを再生成します:

```shell
curl --silent --fail "http://<sigstore-host>:3000/api/v1/log/publicKey" --output /etc/sigstore/rekor-pub.pem
cosign trusted-root create \
  --fulcio="url=http://<sigstore-host>:5555,certificate-chain=/etc/sigstore/fulcio-root.pem,start-time=2024-01-01T00:00:00Z" \
  --rekor="url=http://<sigstore-host>:3000,public-key=/etc/sigstore/rekor-pub.pem,start-time=2024-01-01T00:00:00Z" \
  --ctfe="url=http://<sigstore-host>:6962,public-key=/etc/sigstore/ctfe-pub.pem,start-time=2024-01-01T00:00:00Z" \
  --out trusted-root.json
```

再生成された`trusted-root.json`をすべてのRunnerに配布します。

この問題を防止するには、Rekorを永続的な署名キーと固定ツリー識別子で設定します。

### エラー: `failed to verify signed certificate timestamp` {#error-failed-to-verify-signed-certificate-timestamp}

このエラーは、証明書に署名付き証明書タイムスタンプが含まれていない場合に発生します。これは、Fulcioが証明書透明性ログなしで実行されている場合に起こります。この設定では署名は成功し、検証のみが失敗します。

この問題を解決するには、証明書透明性ログを指す`--ct-log-url`でFulcioを設定し、信頼されたルートを作成する際に`--ctfe`を含めます。

### エラー: `x509: certificate signed by unknown authority` {#error-x509-certificate-signed-by-unknown-authority}

このエラーは、FulcioがGitLabインスタンスが提示するTLS証明書を検証できない場合に発生します。

この問題を解決するには、プライベート認証局証明書をFulcioコンテナにマウントし、`SSL_CERT_FILE`をそのパスに設定します。

OIDCプロバイダの初期化が失敗した場合でも、Fulcio `/healthz`エンドポイントは`SERVING`を報告します。コンテナログを使用して、プロバイダが読み込まれたことを確認します。
