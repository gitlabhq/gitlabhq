---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabと大規模言語モデル間のゲートウェイ。
title: GitLab AIゲートウェイをインストールする
---

[AIゲートウェイ](../user/gitlab_duo/gateway.md)は、AIネイティブGitLab Duoの機能へのアクセスを提供する2つのサービスを組み合わせたものです:

- AIゲートウェイサービス
- [GitLab Duo Agent Platformサービス](../user/duo_agent_platform/_index.md)。

## Dockerを使用してインストールする {#install-by-using-docker}

GitLab AIゲートウェイDockerイメージには、必要なコードと依存関係がすべて1つのコンテナに含まれています。

前提要件: 

- [Docker](https://docs.docker.com/engine/install/#server)などのDockerコンテナエンジンをインストールします。
- ネットワークからアクセスできる有効なホスト名を使用します。`localhost`は使用しないでください。
- `linux/amd64`アーキテクチャの場合、約340MB（圧縮）、RAMが最小512MBであることを確認してください。
- GitLab Duo Agent Platform機能のJWT署名キーを生成します:

  ```shell
  openssl genrsa -out duo_workflow_jwt.key 2048
  ```

  {{< alert type="warning" >}}`duo_workflow_jwt.key`ファイルを安全に保管し、公開しないでください。このキーはJWTトークンの署名に使用され、機密性の高い認証情報として扱う必要があります。{{< /alert >}}

特に高負荷時には、パフォーマンスを向上させるために、最小要件よりも多くのディスク容量、メモリ、リソースを割り当てることを検討してください。RAMとディスク容量を増やすことで、ピーク負荷時のAIゲートウェイの効率性を高めることができます。

GitLab AIゲートウェイにはGPUは不要です。

### AIゲートウェイイメージを探す {#find-the-ai-gateway-image}

GitLabの公式Dockerイメージは、以下で入手できます:

- コンテナレジストリで表示:
  - [Stable（安定版）](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)
  - [Nightly (ナイトリー)](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/8086262)
- DockerHubの場合:
  - [Stable（安定版）](https://hub.docker.com/r/gitlab/model-gateway/tags)
  - [Nightly (ナイトリー)](https://hub.docker.com/r/gitlab/model-gateway-self-hosted/tags)

[セルフホストAIゲートウェイのリリースプロセスを表示する](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md)。

GitLabのバージョンが`vX.Y.*-ee`の場合、最新の`self-hosted-vX.Y.*-ee`タグが付いたAIゲートウェイDockerイメージを使用します。たとえば、GitLabのバージョンが`v18.2.1-ee`で、AIゲートウェイDockerイメージに以下がある場合:

- バージョン`self-hosted-v18.2.0-ee`、`self-hosted-v18.2.1-ee`、および`self-hosted-v18.2.2-ee`の場合は、`self-hosted-v18.2.2-ee`を使用します。
- バージョン`self-hosted-v18.2.0-ee`および`self-hosted-v18.2.1-ee`の場合は、`self-hosted-v18.2.1-ee`を使用します。
- バージョンが1つのみ`self-hosted-v18.2.0-ee`の場合は、`self-hosted-v18.2.0-ee`を使用します。

新しい機能はナイトリービルドから利用できますが、下位互換性は保証されていません。

{{< alert type="note" >}}

ナイトリーバージョンを使用すると、GitLabのバージョンがAIゲートウェイのリリースより前または後の場合、互換性の問題が発生する可能性があるため、**not recommended**（推奨されません）。常に明示的なバージョンタグを使用してください。

{{< /alert >}}

### イメージからコンテナを起動する {#start-a-container-from-the-image}

1. 次のコマンドを実行し、`<your_gitlab_instance>`と`<your_gitlab_domain>`をGitLabインスタンスのURLとドメインに置き換えます:

   ```shell
   docker run -d -p 5052:5052 -p 50052:50052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
    registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag> \
   ```

   `<ai-gateway-tag>`をGitLabインスタンスに一致するバージョンに置き換えます。たとえば、GitLabのバージョンが`vX.Y.0`の場合は、`self-hosted-vX.Y.0-ee`を使用します。コンテナホストから、`http://localhost:5052`にアクセスすると、`{"error":"No authorization header presented"}`が返されるはずです。

1. ポート`5052`と`50052`がホストからコンテナに転送されていることを確認します。
1. [AIゲートウェイURL](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-your-gitlab-instance-to-access-the-ai-gateway)と[GitLab Duo Agent PlatformサービスURL](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)を設定します。

1. GitLab Duo Agent Platformに独自のセルフホストモデルを使用する予定で、URLがTLSで設定されていない場合は、GitLabインスタンスで`DUO_AGENT_PLATFORM_SERVICE_SECURE`環境変数を設定する必要があります:
   - Linuxパッケージインストールの場合は、`gitlab_rails['env']`で、`'DUO_AGENT_PLATFORM_SERVICE_SECURE' => false`を設定します
   - セルフコンパイルインストールの場合、`/etc/default/gitlab`で`export DUO_AGENT_PLATFORM_SERVICE_SECURE=false`を設定します

1. GitLab Duo Agent Platformに[GitLab AIベンダーモデル](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#gitlab-ai-vendor-models)を使用する場合は、GitLabインスタンスで`DUO_AGENT_PLATFORM_SERVICE_SECURE`環境変数を設定しないでください。

PEMファイルの読み込みで`JWKError`のようなエラーが発生した場合は、SSL証明書エラーを解決する必要があるかもしれません。

この問題を修正するには、次の環境変数を使用して、Dockerコンテナに適切な証明書バンドルパスを設定します:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

`/path/to/ca-bundle.pem`を証明書バンドルへの実際のパスに置き換えます。

## NGINXとSSLを使用してDockerをセットアップする {#set-up-docker-with-nginx-and-ssl}

{{< alert type="note" >}}

このNGINXまたはCaddyをリバースプロキシとしてデプロイする方法は、[イシュー455854](https://gitlab.com/gitlab-org/gitlab/-/issues/455854)が実装されるまでSSLをサポートする一時的な回避策です。

{{< /alert >}}

Docker、リバースプロキシとしてのNGINX、Let's Encrypt for SSL証明書を使用して、AIゲートウェイインスタンスにSSLを設定できます。

NGINXは外部クライアントとのセキュアな接続を管理し、受信HTTPSリクエストを復号化してから、AIゲートウェイに渡します。

前提要件: 

- DockerとDocker Composeがインストールされている
- DNSレコードが登録され、設定されたドメイン名

### 設定ファイルを作成 {#create-configuration-files}

まず、作業ディレクトリに次のファイルを作成します。

1. `nginx.conf`: 

   ```nginx
   user  nginx;
   worker_processes  auto;
   error_log  /var/log/nginx/error.log warn;
   pid        /var/run/nginx.pid;
   events {
       worker_connections  1024;
   }
   http {
       include       /etc/nginx/mime.types;
       default_type  application/octet-stream;
       log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';
       access_log  /var/log/nginx/access.log  main;
       sendfile        on;
       keepalive_timeout  65;
       include /etc/nginx/conf.d/*.conf;
   }
   ```

1. `default.conf`: 

   ```nginx
   # nginx/conf.d/default.conf
   server {
       listen 80;
       server_name _;

       # Forward all requests to the AI gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }

   server {
       listen 443 ssl;
       server_name _;

       # SSL configuration
       ssl_certificate /etc/nginx/ssl/server.crt;
       ssl_certificate_key /etc/nginx/ssl/server.key;

       # Configuration for self-signed certificates
       ssl_verify_client off;
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;
       ssl_prefer_server_ciphers on;
       ssl_session_cache shared:SSL:10m;
       ssl_session_timeout 10m;

       # Proxy headers
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;

       # WebSocket support (if needed)
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";

       # Forward all requests to the AI gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }
   ```

### Let's Encryptを使用してSSL証明書を設定する {#set-up-ssl-certificate-by-using-lets-encrypt}

次に、SSL証明書を設定します:

- DockerベースのNGINXサーバーの場合、Certbotは[Let's Encrypt証明書を実装する自動化された方法を提供します](https://phoenixnap.com/kb/letsencrypt-docker)。
- または、[Certbot手動インストール](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)を使用することもできます。

### 環境変数ファイルを作成する {#create-environment-file}

JWT署名キーを保存するための`.env`ファイルを作成します:

```shell
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat duo_workflow_jwt.key)\"" > .env
```

### Docker-composeファイルを作成する {#create-docker-compose-file}

次に、`docker-compose.yaml`ファイルを作成します。

```yaml
version: '3.8'

services:
  nginx-proxy:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /path/to/nginx.conf:/etc/nginx/nginx.conf:ro
      - /path/to/default.conf:/etc/nginx/conf.d/default.conf:ro
      - /path/to/fullchain.pem:/etc/nginx/ssl/server.crt:ro
      - /path/to/privkey.pem:/etc/nginx/ssl/server.key:ro
    networks:
      - proxy-network
    depends_on:
      - gitlab-ai-gateway

  gitlab-ai-gateway:
    image: registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
    expose:
      - "5052"
    environment:
      - AIGW_GITLAB_URL=<your_gitlab_instance>
      - AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/
    env_file:
      - .env
    networks:
      - proxy-network
    restart: always

networks:
  proxy-network:
    driver: bridge
```

### デプロイして検証する {#deploy-and-validate}

ソリューションをデプロイして検証するには:

1. `nginx`と`AIGW`のコンテナを起動し、実行されていることを確認します:

   ```shell
   docker-compose up
   docker ps
   ```

1. [AIゲートウェイにアクセスするようにGitLabインスタンスを設定する](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-your-gitlab-instance-to-access-the-ai-gateway)。

1. [GitLab Duo Agent Platformサービス](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)のURLにアクセスするようにGitLabインスタンスを設定します。

1. ヘルスチェックを実行し、AIゲートウェイとエージェントプラットフォームの両方にアクセスできることを確認します。

## Helm Chartを使用してインストールする {#install-by-using-helm-chart}

前提要件: 

- 以下が必要です:
  - DNSレコードを追加できる、所有しているドメイン
  - Kubernetesクラスター。
  - `kubectl`の動作インストール。
  - Helmの動作インストール、バージョンv3.11.0以降。

詳細については、[GKEまたはEKSでGitLabチャートをテストする](https://docs.gitlab.com/charts/quickstart/)を参照してください。

### AIゲートウェイHelmリポジトリを追加する {#add-the-ai-gateway-helm-repository}

AIゲートウェイHelmリポジトリをHelm設定に追加します:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### AIゲートウェイをインストールする {#install-the-ai-gateway}

1. `ai-gateway`ネームスペースを作成します:

   ```shell
   kubectl create namespace ai-gateway
   ```

1. AIゲートウェイを公開するドメインの証明書を生成します。
1. 以前に作成したネームスペースにTLSシークレットを作成します:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. AIゲートウェイがAPIにアクセスするには、GitLabインスタンスがどこにあるかを知る必要があります。これを行うには、`gitlab.url`と`gitlab.apiUrl`を`ingress.hosts`と`ingress.tls`の値とともに次のように設定します:

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version 0.5.0 \
     --namespace=ai-gateway \
     --set="image.tag=<ai-gateway-image-version>" \
     --set="gitlab.url=https://<your_gitlab_domain>" \
     --set="gitlab.apiUrl=https://<your_gitlab_domain>/api/v4/" \
     --set "ingress.enabled=true" \
     --set "ingress.hosts[0].host=<your_gateway_domain>" \
     --set "ingress.hosts[0].paths[0].path=/" \
     --set "ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
     --set "ingress.tls[0].secretName=ai-gateway-tls" \
     --set "ingress.tls[0].hosts[0]=<your_gateway_domain>" \
     --set="ingress.className=nginx" \
     --set "extraEnvironmentVariables[0].name=DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY" \
     --set "extraEnvironmentVariables[0].value=$(cat duo_workflow_jwt.key)" \
     --timeout=300s --wait --wait-for-jobs
   ```

`image.tag`として使用できるAIゲートウェイバージョンのリストは、[レジストリ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)にあります。

この手順では、すべてのリソースが割り当てられ、AIゲートウェイが起動するまでに数秒かかる場合があります。

既存の`nginx`Ingressコントローラーが別のネームスペースでサービスを提供しない場合は、AIゲートウェイ用に独自の**Ingress Controller**を設定する必要があるかもしれません。Ingressがマルチネームスペースデプロイ用に正しく設定されていることを確認してください。

`ai-gateway`Helm Chartのバージョンについては、`helm search repo ai-gateway --versions`を使用して、適切なチャートバージョンを見つけてください。

ポッドが起動して実行されるのを待ちます:

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

ポッドが起動して実行されたら、IP IngressとDNSレコードを設定できます。

## 自己署名SSL証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続する {#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate}

GitLabインスタンスまたはモデルエンドポイントが自己署名証明書で設定されている場合は、ルート認証局（CA）証明書をAIゲートウェイの証明書バンドルに追加する必要があります。

これを行うには、次のいずれかの方法があります:

- ルートCA証明書をAIゲートウェイに渡し、認証が成功するようにします。
- ルートCA証明書をAIゲートウェイコンテナのCAバンドルに追加します。

### ルートCA証明書をAIゲートウェイに渡す {#pass-the-root-ca-certificate-to-the-ai-gateway}

ルートCA証明書をAIゲートウェイに渡し、認証が成功するようにするには、`REQUESTS_CA_BUNDLE`環境変数を設定します。GitLabはベースの信頼できるCAリストに[Certifi](https://pypi.org/project/certifi/)を使用しているため、次のようにカスタムCAバンドルを設定します:

1. Certifi `cacert.pem`ファイルをダウンロードします:

   ```shell
   curl "https://raw.githubusercontent.com/certifi/python-certifi/2024.07.04/certifi/cacert.pem" --output cacert.pem
   ```

1. 自己署名ルートCA証明書をファイルに追加します。たとえば、`mkcert`を使用して証明書を作成した場合:

   ```shell
   cat "$(mkcert -CAROOT)/rootCA.pem" >> path/to/your/cacert.pem
   ```

1. `REQUESTS_CA_BUNDLE`を`cacert.pem`ファイルのパスに設定します。たとえば、GETでは、`$GDK_ROOT/env.runit`に次を追加します:

   ```shell
   export REQUESTS_CA_BUNDLE=/path/to/your/cacert.pem
   ```

### AIゲートウェイコンテナのCAバンドルにルートCA証明書を追加する {#add-the-root-ca-certificate-to-the-ai-gateway-containers-ca-bundle}

AIゲートウェイがカスタムCAによって署名されたGitLab Self-Managedインスタンスの証明書を信頼できるようにするには、ルートCA証明書をAIゲートウェイコンテナのCAバンドルに追加します。

この方法では、チャートのバージョンが新しい場合にルートCAバンドルに加えられた変更は許可されません。

AIゲートウェイのHelm Chartデプロイでこれを行うには:

1. カスタムルートCA証明書をローカルファイルに追加します:

   ```shell
   cat customCA-root.crt >> ca-certificates.crt
   ```

1. `/etc/ssl/certs/ca-certificates.crt`バンドルファイルをAIゲートウェイコンテナからローカルファイルにコピーします:

   ```shell
   kubectl cp -n gitlab ai-gateway-55d697ff9d-j9pc6:/etc/ssl/certs/ca-certificates.crt ca-certificates.crt.
   ```

1. ローカルファイルから新しいシークレットを作成します:

   ```shell
   kubectl create secret generic ca-certificates -n gitlab --from-file=cacertificates.crt=ca-certificates.crt
   ```

1. チャット`values.yml`でシークレットを使用して、`volume`と`volumeMount`を定義します。これにより、コンテナに`/tmp/ca-certificates.crt`ファイルが作成されます:

   ```shell
   volumes:
     - name: cacerts
       secret:
         secretName: ca-certificates
         optional: false

   volumeMounts:
     - name: cacerts
       mountPath: "/tmp"
       readOnly: true
   ```

1. `REQUESTS_CA_BUNDLE`と`SSL_CERT_FILE`環境変数を、マウントされたファイルを指すように設定します:

   ```shell
   extraEnvironmentVariables:
     - name: REQUESTS_CA_BUNDLE
       value: /tmp/ca-certificates.crt
     - name: SSL_CERT_FILE
       value: /tmp/ca-certificates.crt
   ```

1. チャートを再デプロイします。

[イシュー3](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/issues/3)は、Helm Chartでネイティブにこれをサポートするために存在します。

#### Dockerデプロイの場合 {#for-a-docker-deployment}

Dockerデプロイの場合は、同じ方法を使用します。唯一の違いは、コンテナにローカルファイルをマウントするには、`--volume /root/ca-certificates.crt:/tmp/ca-certificates.crt`を使用することです。

## AIゲートウェイDockerイメージをアップグレードする {#upgrade-the-ai-gateway-docker-image}

AIゲートウェイをアップグレードするには、最新のDockerイメージタグをダウンロードします。

1. 実行中のコンテナを停止します:

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. 既存のコンテナを削除します:

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. プルして[新しいイメージを実行](#start-a-container-from-the-image)します。

1. 環境変数がすべて正しく設定されていることを確認します。

## 代替インストール方法 {#alternative-installation-methods}

AIゲートウェイをインストールする別の方法については、[イシュー463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773)を参照してください。

## ヘルスチェックとデバッグ {#health-check-and-debugging}

セルフホストDuoインストールの問題をデバッグするには、次のコマンドを実行します:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

以下を確認してください:

- AIゲートウェイURLが正しく設定されている（`Ai::Setting.instance.ai_gateway_url`を使用）。
- `/admin/code_suggestions`を介して、ルートユーザーに対してDuoアクセスが明示的に有効になっている。

アクセスに関する問題が解決しない場合は、認証が正しく設定されていること、およびヘルスチェックに合格していることを確認してください。

問題が解決しない場合は、エラーメッセージで`AIGW_AUTH__BYPASS_EXTERNAL=true`による認証の回避が提案されることがありますが、これはトラブルシューティングの場合にのみ行ってください。

[ヘルスチェック](../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)は、**管理者** > **GitLab Duo**に移動して実行することもできます。

これらのテストはオフライン環境で実行されます:

| Test | 説明 |
|-----------------|-------------|
| ネットワーク | 以下をテストします:<br>\- AIゲートウェイURLが`ai_settings`テーブルを介してデータベースで正しく設定されているか。<br> \- インスタンスが設定されたURLに接続できるか。<br><br>インスタンスがURLに接続できない場合は、ファイアウォールまたはプロキシサーバーの設定で[接続を許可](../user/gitlab_duo/setup.md)されていることを確認してください。環境変数`AI_GATEWAY_URL`はレガシー互換性のために引き続きサポートされていますが、データベースを介してURLを設定することを推奨します。 |
| ライセンス | ライセンスにコード提案機能へのアクセス機能があるかどうかをテストします。 |
| システム交換 | コード提案をインスタンスで使用できるかどうかをテストします。システム交換評価が失敗した場合、ユーザーはGitLab Duo機能を使用できない可能性があります。 |

## AIゲートウェイはオートスケールする必要がありますか? {#does-the-ai-gateway-need-to-autoscale}

オートスケールは必須ではありませんが、変動するワークロード、高い並行処理要件、または予測できない使用パターンを持つ環境に推奨されます。GitLabの本番環境の場合:

- ベースライン設定: 2つのvCPUコアと8GBのRAMを搭載した単一のAIゲートウェイインスタンスは、約40件の同時リクエストを処理できます。
- スケールのガイドライン: より大規模な設定（AWS t3.2xlargeインスタンス（8つのvCPU、32GBのRAMなど））の場合、ゲートウェイは最大160件の同時リクエストを処理でき、ベースライン設定の4倍に相当します。
- リクエストスループット: GitLab.comでの利用状況の観察から、アクティブユーザー1,000人あたり7 RPS（1秒あたりのリクエスト数）が計画の妥当なメトリクスであることが示唆されています。
- オートスケールオプション: Kubernetes Horizontalポッドオートスケールs（HPA）または同様のメカニズムを使用して、CPU、メモリ使用率、要求レイテンシーのしきい値などのメトリクスに基づいてインスタンス数を動的に調整します。

## デプロイサイズ別の設定例 {#configuration-examples-by-deployment-size}

- 小規模なデプロイ:
  - 2 vCPUと8 GBのRAMを搭載した単一インスタンス。
  - 最大40件の同時リクエストを処理します。
  - 最大50人のユーザーと予測可能なワークロードを持つチームまたは組織。
  - 固定インスタンスで十分な場合があります。オートスケールは、コスト効率性のために無効にできます。
- 中規模なデプロイ:
  - 8 vCPUと32 GBのRAMを搭載した単一のAWS t3.2xlargeインスタンス。
  - 最大160件の同時リクエストを処理します。
  - 50 ～ 200人のユーザーと適度な並行処理要件を持つ組織。
  - 50% のCPU使用率または500ミリ秒を超える要求レイテンシーのしきい値でKubernetes HPAを実装します。
- 大規模なデプロイ:
  - 複数のAWS t3.2xlargeインスタンスまたは同等のもののクラスター。
  - 各インスタンスは160件の同時リクエストを処理し、複数のインスタンスを持つ数千人のユーザーにスケールします。
  - 200人を超えるユーザーと、変動する高並行処理ワークロードを持つ企業。
  - HPAを使用して、リアルタイムの需要に基づいてポッドをスケールし、クラスター全体のリソース調整のためにノードオートスケールと組み合わせます。

## AIゲートウェイコンテナがアクセスできる仕様は何ですか？また、リソースの割り当てはパフォーマンスにどのように影響しますか？ {#what-specs-does-the-ai-gateway-container-have-access-to-and-how-does-resource-allocation-affect-performance}

AIゲートウェイは、次のリソース割り当てで効果的に動作します:

- コンテナごとに2つのvCPUコアと8 GBのRAM。
- コンテナは通常、GitLabの本番環境で約7.39% のCPUと比例したメモリを使用し、成長やバーストアクティビティーの処理に対応できる余地を残しています。

## リソースの競合を軽減するための戦略 {#mitigation-strategies-for-resource-contention}

- Kubernetesのリソースリクエストと制限を使用して、AIゲートウェイコンテナが保証されたCPUおよびメモリ割り当てを受け取るようにします。例: 

  ```yaml
  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "32Gi"
      cpu: "8"
  ```

- PrometheusやGrafanaなどのツールを実装して、リソース使用率（CPU、メモリ、レイテンシー）を追跡し、ボトルネックを早期に検出します。
- ノードまたはインスタンスをAIゲートウェイ専用にして、他のサービスとのリソース競合を防ぎます。

## スケーリング戦略 {#scaling-strategies}

- Kubernetes HPAを使用して、次のようなリアルタイムのメトリクスに基づいてポッドをスケールします:
  - 平均CPU使用率が50% を超える。
  - 要求レイテンシーが常に500ミリ秒を超える。
  - ノードオートスケールを有効にして、ポッドの増加に応じてインフラストラクチャリソースを動的にスケールします。

## スケーリングに関する推奨事項 {#scaling-recommendations}

| デプロイサイズ | インスタンスタイプ      | リソース             | キャパシティ（同時リクエスト数） | スケーリングに関する推奨事項                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| S            | 2 vCPU、8 GB RAM | シングルインスタンス        | 40                              | 固定デプロイ；オートスケールなし。           |
| 中程度           | AWS t3.2xlarge    | シングルインスタンス     | 160                             | CPUまたはレイテンシーのしきい値に基づくHPA。     |
| L            | 複数のt3.2xlarge | クラスター化されたインスタンス   | インスタンスあたり160               | 高需要に対応するHPA + ノードオートスケール。     |

## 複数のGitLabインスタンスのサポート {#support-multiple-gitlab-instances}

単一のAIゲートウェイをデプロイして複数のGitLabインスタンスをサポートしたり、インスタンスごとまたは地理的リージョンごとに個別のAIゲートウェイをデプロイしたりできます。どちらが適切かを判断するために、以下を考慮してください:

- 1,000人の請求対象ユーザーあたり、1秒あたり約7件のトラフィックが予想される。
- すべてのインスタンスにわたる合計の同時リクエスト数に基づくリソース要件。
- 各GitLabインスタンスのベストプラクティス認証設定。

## AIゲートウェイとインスタンスのコロケーション {#co-locate-your-ai-gateway-and-instance}

AIゲートウェイは、場所に関係なく、ユーザーに最適なパフォーマンスを確保するために、グローバルに複数のリージョンで利用できます:

- Duo機能の応答時間の改善。
- 地理的に分散したユーザーのレイテンシーの削減。
- データの主権要件へのコンプライアンス。

GitLabインスタンスと同じ地理的リージョンにAIゲートウェイを配置して、特にコード提案のようなレイテンシーの影響を受けやすい機能に対して、摩擦のないDevExを提供するのに役立ちます。

## トラブルシューティング {#troubleshooting}

AIゲートウェイの操作中に、以下の問題が発生する可能性があります。

### OpenShiftのパーミッションに関するイシュー {#openshift-permission-issues}

OpenShiftにAIゲートウェイをデプロイすると、OpenShiftのセキュリティモデルが原因で、パーミッションエラーが発生する可能性があります。

#### `/tmp`ディレクトリの読み取り専用ファイルシステム {#read-only-filesystem-at-tmp}

AIゲートウェイは`/tmp`に書き込む必要があります。ただし、セキュリティが制限されているOpenShift環境では、`/tmp`が読み取り専用になっている可能性があります。

このイシューを解決するには、新しい`EmptyDir`ボリュームを作成し、`/tmp`にマウントします。これを行うには、次のいずれかの方法があります:

- コマンドラインから:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- 次の場所に追加: `values.yaml`:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

#### HuggingFaceモデル {#huggingface-models}

デフォルトでは、AIゲートウェイはHuggingFaceモデルをキャッシュするために`/home/aigateway/.hf`を使用しますが、これはOpenShiftのセキュリティが制限された環境では書き込み可能ではない可能性があります。これにより、次のようなパーミッションエラーが発生する可能性があります:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

これを解決するには、`HF_HOME`環境変数を書き込み可能な場所に設定します。`/var/tmp/huggingface`または、コンテナが書き込み可能な他のディレクトリを使用できます。

これを行うには、次のいずれかの方法があります:

- 次の場所に追加: `values.yaml`:

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- または、Helmアップグレードコマンドに含めます:

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

この設定により、AIゲートウェイは、OpenShiftのセキュリティ制約を尊重しながら、HuggingFaceモデルを適切にキャッシュできます。選択する正確なディレクトリは、特定のOpenShiftの設定およびセキュリティポリシーによって異なる場合があります。

### 自己署名証明書エラー {#self-signed-certificate-error}

AIゲートウェイがカスタムCA（CA）によって署名された証明書、または自己署名証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続しようとすると、`[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain`エラーがAIゲートウェイによってログに記録されます。

これを解決するには、[自己署名SSL証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続する](#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate)を参照してください。
