---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabと大規模言語モデル間のゲートウェイ。
title: GitLab AIゲートウェイをインストールする
---

この[AIゲートウェイ](../administration/gitlab_duo/gateway.md)は、AIネイティブなGitLab Duo機能へのアクセスを提供する2つのサービスの組み合わせです:

- AIゲートウェイサービス
- [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)サービス

## Dockerを使用してインストール {#install-by-using-docker}

GitLabAIゲートウェイのDockerイメージには、必要なすべてのコードと依存関係が1つのコンテナに含まれています。

前提条件: 

- Dockerのような[Docker](https://docs.docker.com/engine/install/#server)コンテナエンジンをインストールします。
- ネットワークからアクセスできる有効なホスト名を使用してください。`localhost`は使用しないでください。
- `linux/amd64`アーキテクチャ用に約340MB（圧縮）と、最低512MBのRAMがあることを確認してください。
- コンテナが`ai_gateway`サービスと`duo-workflow-service`サービス用に少なくとも2つのCPUにアクセスできることを確認してください。
- GitLab Duo Agent Platform機能のJWT署名キーを生成します:

  ```shell
  openssl genrsa -out duo_workflow_jwt.key 2048
  ```

  > [!warning]
  > `duo_workflow_jwt.key`ファイルを安全に保管し、公開しないでください。このキーはJWTトークンの署名に使用され、機密性の高い資格情報として扱われる必要があります。

特に高いワークロードの下でのパフォーマンスを向上させるには、最小要件よりも多くのディスクスペース、メモリ、リソースを割り当てることを検討してください。RAMとディスク容量が増加すると、AIゲートウェイの効率性はピーク負荷時に向上します。

GitLabAIゲートウェイにはGPUは必要ありません。

### AIゲートウェイイメージを見つける {#find-the-ai-gateway-image}

GitLab公式Dockerイメージは以下で利用可能です:

- コンテナレジストリ内:
  - [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)
  - [Nightly](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/8086262)
- DockerHub上:
  - [Stable](https://hub.docker.com/r/gitlab/model-gateway/tags)
  - [Nightly](https://hub.docker.com/r/gitlab/model-gateway-self-hosted/tags)

セルフホストモデルのAIゲートウェイの[リリース](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md)プロセスを表示します。

GitLabバージョンが`vX.Y.*-ee`の場合、最新の`self-hosted-vX.Y.*-ee`タグが付いたAIゲートウェイDockerイメージを使用します。たとえば、GitLabバージョンが`v18.2.1-ee`で、AIゲートウェイDockerイメージに次のものが含まれる場合:

- バージョン`self-hosted-v18.2.0-ee`、`self-hosted-v18.2.1-ee`、および`self-hosted-v18.2.2-ee`の場合、`self-hosted-v18.2.2-ee`を使用します。
- バージョン`self-hosted-v18.2.0-ee`と`self-hosted-v18.2.1-ee`の場合、`self-hosted-v18.2.1-ee`を使用します。
- バージョンが1つしかない場合（`self-hosted-v18.2.0-ee`）、`self-hosted-v18.2.0-ee`を使用します。

新しい機能はナイトリービルドから利用できますが、下位互換性は保証されていません。

> [!note]
> ナイトリーバージョンの使用は、GitLabバージョンがAIゲートウェイリリースより古い場合や新しい場合に互換性の問題を引き起こす可能性があるため、**not recommended**。必ず明示的なバージョンタグを使用してください。

### イメージからコンテナを開始する {#start-a-container-from-the-image}

1. コンテナを起動するには、次のコマンドラインを実行します:

   ```shell
   docker run -d -p 5052:5052 -p 50052:50052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
    registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
   ```

   次のプレースホルダーを置き換えてください:

   - `<your_gitlab_instance>`: あなたのGitLabインスタンスのURL（例: `https://gitlab.example.com`）。
   - `<your_gitlab_domain>`: あなたのドメイン（例: `gitlab.example.com`）。
   - `<ai-gateway-tag>`: あなたのGitLabインスタンスに一致するバージョン。あなたのGitLabバージョンが`vX.Y.0`の場合、`self-hosted-vX.Y.0-ee`を使用します。

   コンテナホストから`http://localhost:5052`にアクセスすると、`{"error":"No authorization header presented"}`が返されるはずです。

1. ホストから`5052`ポートと`50052`ポートがコンテナに転送されていることを確認してください。`5052`ポートはAIゲートウェイのHTTP通信を処理します。`50052`ポートはGitLab Duo Agent PlatformサービスのgRPC通信を処理します。
1. オフラインライセンスを使用するGitLabインスタンスの場合、AIGWコンテナで`-e DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=`（空文字列）を設定します。この設定では:
   - GitLab DuoワークフローサービスがローカルのGitLabインスタンスに対してのみ認証するように強制します。
   - CustomersDot呼び出しが到達不能であることによって引き起こされる20秒の遅延を解消します。
1. [AIゲートウェイ](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway) URLと[GitLab Duo Agent Platform](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)サービスURLを設定します。
1. モデルのセットアップに基づいて`DUO_AGENT_PLATFORM_SERVICE_SECURE`の環境変数を設定します:
   - TLSなしのセルフホストモデルを使用している場合、GitLabインスタンスで`DUO_AGENT_PLATFORM_SERVICE_SECURE`の環境変数を`false`に設定します:

     - Linuxパッケージインストールの場合: `gitlab_rails['env']`で、`'DUO_AGENT_PLATFORM_SERVICE_SECURE' => false`を設定します。
     - セルフコンパイルインストールの場合: `/etc/default/gitlab`で、`export DUO_AGENT_PLATFORM_SERVICE_SECURE=false`を設定します。

   - [GitLabマネージドモデル](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#gitlab-managed-models)を使用している場合、`DUO_AGENT_PLATFORM_SERVICE_SECURE`の環境変数は設定しないでください。

## NGINXとSSLでDockerをセットアップする {#set-up-docker-with-nginx-and-ssl}

> [!note]
> NGINXまたはCaddyをリバースプロキシとしてデプロイするこの方法は、[イシュー455854](https://gitlab.com/gitlab-org/gitlab/-/issues/455854)が実装されるまでのSSLをサポートする一時的な回避策です。

AIゲートウェイインスタンスにSSLを使用するには、次を使用します:

- Docker
- NGINXをリバースプロキシとして使用
- SSL証明書にはLet's Encrypt。

NGINXは外部クライアントとの安全な接続を管理します。受信したHTTPSリクエストをAIゲートウェイに渡す前に復号化する。

前提条件: 

- DockerおよびDocker Composeがインストール済み
- 登録され設定済みのドメイン名

### 設定ファイルを作成する {#create-configuration-files}

作業ディレクトリに次のファイルを作成することから始めます。

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

       # Forward all requests to the AI Gateway
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

       # Forward all requests to the AI Gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }
   ```

1. `grpc-nginx.conf`: 

```nginx
# Configuration for Duo Agent Platform with TLS
events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log debug;

    upstream grpcservers {
        server gitlab-ai-gateway:50052;
    }

    server {
        listen 8443 ssl;
        http2 on;

        ssl_certificate /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            grpc_pass grpc://grpcservers;
            grpc_set_header Host $host;
        }
    }
}
```

### Let's Encryptを使用してSSL証明書をセットアップする {#set-up-ssl-certificate-by-using-lets-encrypt}

SSL証明書をセットアップするには:

- DockerベースのNGINXサーバーの場合、Certbotは[Let's Encrypt](https://phoenixnap.com/kb/letsencrypt-docker)証明書を実装する自動化された方法を提供します。
- あるいは、[Certbotの手動インストール](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)を使用することもできます。

### 環境変数ファイルを作成する {#create-an-environment-file}

`.env`ファイルを作成してJWT署名キーを保存します:

```shell
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat duo_workflow_jwt.key)\"" > .env
```

### Docker Composeファイルを作成する {#create-a-docker-compose-file}

次に、`docker-compose.yaml`ファイルを作成します。

```yaml
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

grpc-proxy:
    image: nginx:alpine
    ports:
      - "8443:8443"
    volumes:
      - /path/to/grpc-nginx.conf:/etc/nginx/nginx.conf:ro
      - /path/to/fullchain.pem:/etc/nginx/ssl/server.crt:ro
      - /path/to/privkey.pem:/etc/nginx/ssl/server.key:ro
    networks:
      - proxy-network
    depends_on:
      - gitlab-ai-gateway
    restart: always

  gitlab-ai-gateway:
    image: registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
    ports:
      - "50052:50052" # Agent Platform gRPC exposed to the host
    expose:
      - "5052" # Only exposed internally to the proxy network
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

1. `nginx`および`AIGW`のコンテナを開始し、それらが実行されていることを確認します:

   ```shell
   docker compose up
   docker ps
   ```

1. [GitLabのインスタンスがAIゲートウェイにアクセスできるように](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway)設定します。

1. GitLabインスタンスが[GitLab Duo Agent Platform](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)サービスのURLにアクセスできるように設定します。

1. ヘルスチェックを実行し、AIゲートウェイとエージェントPlatformの両方にアクセスできることを確認します。

## Helmチャートを使用してインストールする {#install-by-using-helm-chart}

前提条件: 

- 次の条件を満たしている必要があります:
  - あなたが所有するドメインで、DNSレコードを追加できること。
  - Kubernetesクラスター。
  - `kubectl`の動作するインストール。
  - Helmの動作するインストール（バージョンv3.11.0以降）。

詳細については、[GKE](https://docs.gitlab.com/charts/quickstart/)またはEKSでGitLabチャートをテストするを参照してください。

### AIゲートウェイHelmリポジトリを追加する {#add-the-ai-gateway-helm-repository}

AIゲートウェイHelmリポジトリをHelm設定に追加します:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### AIゲートウェイをインストール {#install-the-ai-gateway}

1. `ai-gateway`ネームスペースを作成します:

   ```shell
   kubectl create namespace ai-gateway
   ```

1. AIゲートウェイを公開する予定のドメインの証明書を生成します。
1. 以前に作成したネームスペースにTLSシークレットを作成します:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. [チャートのパッケージレジストリ](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages)で最新パッケージのバージョン番号を取得します。

1. AIゲートウェイがAPIにアクセスするには、GitLabインスタンスがどこにあるかを知る必要があります。これを行うには、`gitlab.url`と`gitlab.apiUrl`を`ingress.hosts`と`ingress.tls`の値と共に次のように設定します:

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version <latest-package-in-registery> \
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

`image.tag`として使用できるAIゲートウェイバージョンのリストは、[コンテナ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)レジストリで確認できます。

このステップは、すべてのリソースが割り当てられAIゲートウェイが起動するまで数秒かかる場合があります。

既存の`nginx`Ingressコントローラーが別のネームスペース内のサービスを提供しない場合、AIゲートウェイ用に独自の**Ingress Controller**をセットアップする必要があるかもしれません。マルチネームスペースデプロイメント用にIngressが正しく設定されていることを確認してください。

`ai-gateway`Helmチャートのバージョンについては、`helm search repo ai-gateway --versions`を使用して適切なチャートバージョンを見つけてください。

ポッドが起動して実行されるのを待ちます:

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

ポッドが起動して実行されたら、IPイングレスとDNSレコードをセットアップできます。

## 自己署名SSL証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続する {#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate}

GitLabインスタンスまたはモデルエンドポイントが自己署名証明書で設定されている場合、ルート認証局（CA）証明書をAIゲートウェイの証明書バンドルに追加する必要があります。

これを行うには、次のいずれかの方法があります:

- ルート認証局証明書をAIゲートウェイに渡して、認証が成功するようにします。
- ルート認証局証明書をAIゲートウェイコンテナのCAバンドルに追加します。

### ルート認証局証明書をAIゲートウェイに渡す {#pass-the-root-ca-certificate-to-the-ai-gateway}

ルート認証局証明書をAIゲートウェイに渡し、認証が成功するようにするには、`REQUESTS_CA_BUNDLE`の環境変数を設定します。GitLabは信頼できるベースCAリストに[Certifi](https://pypi.org/project/certifi/)を使用するため、カスタムCAバンドルを次のように設定します:

1. Certifi `cacert.pem`ファイルをダウンロードします:

   ```shell
   curl "https://raw.githubusercontent.com/certifi/python-certifi/2024.07.04/certifi/cacert.pem" --output cacert.pem
   ```

1. 自己署名ルート認証局証明書をファイルに追加します。たとえば、`mkcert`を使用して証明書を作成した場合:

   ```shell
   cat "$(mkcert -CAROOT)/rootCA.pem" >> path/to/your/cacert.pem
   ```

1. `REQUESTS_CA_BUNDLE`を`cacert.pem`ファイルのパスに設定します。たとえば、GDKでは、`$GDK_ROOT/env.runit`に以下を追加します:

   ```shell
   export REQUESTS_CA_BUNDLE=/path/to/your/cacert.pem
   ```

### ルート認証局証明書をAIゲートウェイコンテナのCAバンドルに追加する {#add-the-root-ca-certificate-to-the-ai-gateway-containers-ca-bundle}

AIゲートウェイがカスタム認証局によって署名されたGitLabSelf-Managedインスタンスの証明書を信頼できるようにするには、ルート認証局証明書をAIゲートウェイコンテナのCAバンドルに追加します。

この方法では、チャートのバージョンでルートCAバンドルに加えられた変更は許可されません。

AIゲートウェイのHelmチャートデプロイメントに対してこれを行うには:

1. カスタムルート認証局証明書をローカルファイルに追加します:

   ```shell
   cat customCA-root.crt >> ca-certificates.crt
   ```

1. AIゲートウェイコンテナから`/etc/ssl/certs/ca-certificates.crt`バンドルファイルをローカルファイルにコピーします:

   ```shell
   kubectl cp -n gitlab ai-gateway-55d697ff9d-j9pc6:/etc/ssl/certs/ca-certificates.crt ca-certificates.crt.
   ```

1. ローカルファイルから新しいシークレットを作成します:

   ```shell
   kubectl create secret generic ca-certificates -n gitlab --from-file=cacertificates.crt=ca-certificates.crt
   ```

1. `values.yml`のシークレットを使用して、`volume`と`volumeMount`を定義します。これにより、`/tmp/ca-certificates.crt`ファイルがコンテナ内に作成されます:

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

1. マウントされたファイルを指すように`REQUESTS_CA_BUNDLE`と`SSL_CERT_FILE`の環境変数を設定します:

   ```shell
   extraEnvironmentVariables:
     - name: REQUESTS_CA_BUNDLE
       value: /tmp/ca-certificates.crt
     - name: SSL_CERT_FILE
       value: /tmp/ca-certificates.crt
   ```

1. チャートを再デプロイします。

Helmチャートでこれをネイティブにサポートするための[イシュー3](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/issues/3)が存在します。

#### Dockerデプロイの場合 {#for-a-docker-deployment}

Dockerデプロイの場合は、同じ方法を使用します。唯一の違いは、ローカルファイルをコンテナにマウントするには、`--volume /root/ca-certificates.crt:/tmp/ca-certificates.crt`を使用することです。

## AIゲートウェイDockerイメージをアップグレードする {#upgrade-the-ai-gateway-docker-image}

AIゲートウェイをアップグレードするには、最新のDockerイメージタグをダウンロードします。

1. 実行中のコンテナを停止します。

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. 既存のコンテナを削除します。

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. イメージをプルするし、[新しいイメージを実行](#start-a-container-from-the-image)します。

1. 環境変数がすべて正しく設定されていることを確認します。

## GitLab Dedicatedインスタンスの追加インストール手順 {#extra-installation-steps-for-gitlab-dedicated-instances}

セルフホストモデルのAIゲートウェイにアクセスするには、[GitLab Dedicatedインスタンス用のセルフホストモデルのAIゲートウェイを参照してください。](../administration/dedicated/configure_instance/_index.md#self-hosted-ai-gateway-for-gitlab-dedicated-instances)

## セキュリティアップデートとイメージの検証 {#security-updates-and-image-verification}

最新のセキュリティパッチを実行していることを確認するには、デプロイ方法に基づいて次のガイドラインに従ってください。

### KubernetesまたはHelmのデプロイの場合 {#for-kubernetes-or-helm-deployments}

0.7.0より前の[チャート](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages)バージョンとKubernetesは、デフォルトで`imagePullPolicy: IfNotPresent`を使用します。これは、タグが変更されていない場合、更新されたイメージをプルすることはありません。これは、同じバージョンタグでリリースされたセキュリティパッチを見逃す可能性があることを意味します。

イメージダイジェストを使用する次のアプローチを使用してください:

```shell
# Find the image digest from the container registry
# Use this digest in your Helm install/upgrade command

helm upgrade --install ai-gateway \
  ai-gateway/ai-gateway \
  --set="image.tag=self-hosted-v18.2.1-ee@sha256:abc123..." \
  # ... other flags
```

あるいは、次のいずれかの方法で`imagePullPolicy`を使用することもできます:

- `imagePullPolicy`を常に以下のように設定します:

  ```shell
  helm upgrade --install ai-gateway \
    ai-gateway/ai-gateway \
    --set="image.pullPolicy=Always" \
    # ... other flags
  ```

- `pullPolicy`を`values.yaml`に追加します:

  ```yaml
  image:
    pullPolicy: Always
  ```

更新のプルするを強制するには:

```shell
kubectl rollout restart deployment/ai-gateway -n ai-gateway
```

### Dockerデプロイの場合 {#for-docker-deployments}

アップグレード時には、最新のイメージをプルするしていることを検証するしてください:

```shell
# Check current image digest
docker images --digests | grep ai-assist

# Pull latest version explicitly
docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>

# Verify digest changed
docker images --digests | grep ai-assist
```

イミュータブルデプロイメントにイメージダイジェストを使用するには:

```shell
docker run -d -p 5052:5052 -p 50052:50052 \
 -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v18.2.1-ee@sha256:abc123...
```

## その他のインストール方法 {#alternative-installation-methods}

AIゲートウェイの代替インストール方法については、[イシュー463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773)を参照してください。

## ヘルスチェックとデバッグ {#health-check-and-debugging}

GitLab Duoセルフホストモデルのインストールに関する問題をデバッグするには、次のコマンドラインを実行します:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

以下を確認してください:

- AIゲートウェイのURLは正しく設定されています（`Ai::Setting.instance.ai_gateway_url`経由）。
- GitLab Duoへのアクセスは、ルートユーザーに対して`/admin/code_suggestions`を通じて明示的に有効化されています。

アクセスイシューが解決しない場合は、認証が正しく設定されていること、およびヘルスチェックが合格していることを確認してください。

解決しないイシューがある場合、エラーメッセージは`AIGW_AUTH__BYPASS_EXTERNAL=true`で認証をバイパスすることを提案するかもしれませんが、これはトラブルシューティングの場合のみにしてください。

また、**管理者** > **GitLab Duo**に移動して[ヘルスチェック](../administration/gitlab_duo/configure/gitlab_self_managed.md#run-a-health-check-for-gitlab-duo)を実行することもできます。

これらのテストはオフライン環境で実行されます:

| テスト | 説明 |
|-----------------|-------------|
| ネットワーク | 次の項目をテストします:<br>\- AIゲートウェイのURLが`ai_settings`テーブルを通じてデータベースに適切に設定されているか。<br> \- あなたのインスタンスが設定されたURLに接続できるか。<br><br>あなたのインスタンスがURLに接続できない場合、ファイアウォールまたはプロキシサーバーの設定が[接続を許可](../administration/gitlab_duo/configure/gitlab_self_managed.md)していることを確認してください。環境変数`AI_GATEWAY_URL`はレガシー互換性のために依然としてサポートされていますが、管理のしやすさの観点から、データベースを通じてURLを設定することをお勧めします。 |
| ライセンス | ライセンスにコード提案機能へのアクセス権があるかどうかをテストします。 |
| システム連携 | インスタンスでコード提案を使用できるかどうかをテストします。システム連携アセスメントが失敗した場合、ユーザーはGitLab Duo機能を使用できない可能性があります。 |

## AIゲートウェイを監視する {#monitor-the-ai-gateway}

Prometheusを使用して、AIゲートウェイの使用状況とパフォーマンスに関するメトリクスを収集します。

### AIゲートウェイ用のPrometheusメトリクスをセットアップする {#set-up-prometheus-metrics-for-the-ai-gateway}

Prometheusメトリクスをセットアップするには:

1. 必要な環境変数を設定し、`8082`ポートを開きます:

   ```shell
   -e AIGW_FASTAPI__METRICS_HOST=0.0.0.0
   -e AIGW_FASTAPI__METRICS_PORT=8082
   ```

### GitLab Duoワークフローサービス用のPrometheusをセットアップする {#set-up-prometheus-for-the-gitlab-duo-workflow-service}

GitLab DuoワークフローサービスでPrometheusメトリクスをセットアップするには:

1. 必要な環境変数を設定し、`8083`ポートを開きます:

   ```shell
   -e PROMETHEUS_METRICS__ADDR=0.0.0.0
   -e PROMETHEUS_METRICS__PORT=8083
   ```

1. `gitlab-ai-gateway`コンテナからホストにメトリクスポートを公開します:

   - DockerCLIの場合:

     ```shell
     -p 8082:8082 \
     -p 8083:8083 \
     ```

   - Docker Composeの場合、`gitlab-ai-gateway`サービスに追加します:

     ```shell
     ports:
       - "8082:8082"
       - "8083:8083"
     ```

   これにより、AIゲートウェイメトリクスエンドポイントは`8082`ポートで、GitLab Duoワークフローサービスメトリクスエンドポイントは`8083`ポートで公開されます。

1. AIゲートウェイコンテナを再起動します。

### Prometheusをメトリクスをスクレイプするように設定する {#configure-prometheus-to-scrape-metrics}

AIゲートウェイおよびGitLab Duoワークフローサービスからメトリクスを収集するには、次の`prometheus.yml`設定をPrometheusインスタンスに追加します。この設定では、Prometheusは15秒ごとに両方のサービスからメトリクスをスクレイプするします。

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ai-gateway'
    static_configs:
      - targets: ['<your_AIGW_domain>:8082']
    scheme: 'http'
    metrics_path: '/metrics'

  - job_name: 'duo-agent-platform-service'
    static_configs:
      - targets: ['<your_duo_agent_platform_service_domain>:8083']
    scheme: 'http'
    metrics_path: '/metrics'
```

### メトリクス収集の検証する {#verify-metrics-collection}

AIゲートウェイとGitLab Duoワークフローサービスのターゲットが収集されていることを検証するには:

1. PrometheusUIで、**ステータス > Targets**に移動します。
1. **アラート**または**グラフ**タブに移動してメトリクスをクエリするします。AIゲートウェイとGitLab Duoワークフローサービスは、次のエンドポイントでメトリクスを公開します:

   - AIゲートウェイ: `http://<your_AIGW_domain>:8082/metrics`
   - GitLab Duoワークフローサービス: `http://<your_duo_agent_platform_service_domain>:8083/metrics`

## AIゲートウェイはオートスケールする必要がありますか？ {#does-the-ai-gateway-need-to-autoscale}

オートスケールは必須ではありませんが、変動するワークロード、高い並行処理要件、または予測不能な使用パターンを持つ環境には推奨されます。GitLabの本番環境では:

- ベースラインセットアップ: 2 CPUコアと8 GB RAMを搭載した単一のAIゲートウェイインスタンスは、約40件の並行処理リクエストを処理できます。
- スケーリングガイドライン: AWS t3.2xlargeインスタンス（8 vCPU、32 GB RAM）のような大規模なセットアップでは、このゲートウェイは最大160件の並行処理リクエストを処理でき、これはベースラインセットアップの4倍に相当します。
- リクエストスループット: GitLab.comで観測された使用状況によると、1000アクティブユーザーあたり7 RPS（1秒あたりのリクエスト数）は、計画にとって妥当なメトリクスです。
- オートスケールのオプション: Kubernetes Horizontal Pod Autoscalers（HPA）または同様のメカニズムを使用して、CPU、メモリ使用率、または要求レイテンシーしきい値などのメトリクスに基づいてインスタンスの数を動的に調整します。

## デプロイサイズ別の設定例 {#configuration-examples-by-deployment-size}

- 小規模デプロイ:
  - 2 vCPUと8 GB RAMを備えた単一のインスタンス。
  - 最大40件の並行処理リクエストを処理します。
  - 最大50ユーザーで予測可能なワークロードを持つチームまたは組織。
  - 固定されたインスタンスで十分な場合があります。コスト効率性のためにオートスケールを無効にすることができます。
- 中規模デプロイ:
  - 8 vCPUと32 GB RAMを備えた単一のAWS t3.2xlargeインスタンス。
  - 最大160件の並行処理リクエストを処理します。
  - 50～200ユーザーで中程度の並行処理要件を持つ組織。
  - Kubernetes HPAを、CPU使用率が50％を超える、または要求レイテンシーが500ミリ秒を超えるしきい値で実装します。
- 大規模デプロイ:
  - 複数のAWS t3.2xlargeインスタンスまたは同等のクラスター。
  - 各インスタンスは160件の並行処理リクエストを処理し、複数のインスタンスで数千人のユーザーにスケールするできます。
  - 200人を超えるユーザーと変動する高並行処理ワークロードを持つ企業。
  - HPAを使用してリアルタイムの需要に基づいてポッドをスケールするし、クラスター全体のリソース調整のためにノードオートスケールと組み合わせます。

## AIゲートウェイコンテナはどのような仕様にアクセスでき、リソース割り当てはパフォーマンスにどのように影響しますか？ {#what-specs-does-the-ai-gateway-container-have-access-to-and-how-does-resource-allocation-affect-performance}

AIゲートウェイは次のリソース割り当ての下で効果的に動作します:

- コンテナあたり2 CPUコアと8 GBのRAM。
- コンテナは通常、GitLab本番環境で約7.39％のCPUとそれに比例するメモリを使用し、成長またはバーストアクティビティを処理するための余地を残しています。

## リソース競合の緩和戦略 {#mitigation-strategies-for-resource-contention}

- Kubernetesのリソースリクエストと制限を使用して、AIゲートウェイコンテナが保証されたCPUとメモリ割り当てを受け取るようにします。例: 

  ```yaml
  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "32Gi"
      cpu: "8"
  ```

- PrometheusやGrafanaのようなツールを実装して、リソース使用率（CPU、メモリ、レイテンシー）を追跡するし、ボトルネックを早期に検出します。
- ノードまたはインスタンスをAIゲートウェイに排他的に割り当てて、他のサービスとのリソース競合を防ぎます。

## スケーリング戦略 {#scaling-strategies}

- Kubernetes HPAを使用して、次のようなリアルタイムメトリクスに基づいてポッドをスケールするします:
  - 平均CPU使用率が50％を超える。
  - 要求レイテンシーが常に500ミリ秒を超える。
  - ノードオートスケールを有効にして、ポッドの増加に応じてインフラストラクチャリソースを動的にスケールするします。

## スケーリング推奨事項 {#scaling-recommendations}

| デプロイサイズ | インスタンスタイプ      | リソース             | 容量（並行処理リクエスト） | スケーリング推奨事項                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| S            | 2 vCPU、8 GB RAM | 単一のインスタンス        | 40                              | 固定デプロイ。 オートスケールなし。           |
| 中程度           | AWS t3.2xlarge    | 単一のインスタンス     | 160                             | CPUまたはレイテンシーのしきい値に基づくHPA。     |
| L            | 複数のt3.2xlarge | クラスター化されたインスタンス   | インスタンスあたり160               | HPA + 高需要向けノードオートスケール。     |

## 複数のGitLabインスタンスをサポートする {#support-multiple-gitlab-instances}

単一のAIゲートウェイをデプロイして複数のGitLabインスタンスをサポートすることも、インスタンスごとまたは地理的リージョンごとに個別のAIゲートウェイをデプロイすることもできます。どちらが適切かを判断するのに役立つのは次の点です:

- 1,000請求対象ユーザーあたり約7 1秒あたりのリクエスト数の予想トラフィック。
- すべてのインスタンスにおける合計並行処理リクエストに基づくリソース要件。
- 各GitLabインスタンスのベストプラクティス認証設定。

## AIゲートウェイとインスタンスを併置する {#co-locate-your-ai-gateway-and-instance}

AIゲートウェイは、場所に関わらずユーザーに最適なパフォーマンスを保証するために、世界中の複数の地域で利用可能です:

- GitLab Duo機能の応答時間の改善。
- 地理的に分散したユーザーのレイテンシーの削減。
- データ主権要件のコンプライアンス。

AIゲートウェイをGitLabインスタンスと同じ地理的リージョンに配置して、特にコード提案のようなレイテンシーの影響を受けやすい機能で、スムーズなDevExを提供できるようにする必要があります。

## トラブルシューティング {#troubleshooting}

AIゲートウェイを使用する際、次のイシューに遭遇する可能性があります。

### OpenShiftの権限イシュー {#openshift-permission-issues}

OpenShiftにAIゲートウェイをデプロイする際、OpenShiftのセキュリティモデルにより権限エラーが発生する可能性があります。

#### `/tmp`にある読み取り専用ファイルシステム {#read-only-filesystem-at-tmp}

AIゲートウェイは`/tmp`に書き込む必要があります。ただし、セキュリティ制限のあるOpenShift環境では、`/tmp`は読み取り専用である可能性があります。

このイシューを解決するするには、新しい`EmptyDir`ボリュームを作成し、それを`/tmp`にマウントします。これを行うには、次のいずれかの方法があります:

- コマンドラインから:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- `values.yaml`に追加:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

#### HuggingFaceモデル {#huggingface-models}

デフォルトでは、AIゲートウェイはHuggingFaceモデルのキャッシュに`/home/aigateway/.hf`を使用しますが、これはOpenShiftのセキュリティ制限された環境では書き込み可能でない場合があります。これにより、次のような権限エラーが発生する可能性があります:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

これを解決するするには、`HF_HOME`の環境変数を書き込み可能な場所に設定します。`/var/tmp/huggingface`またはコンテナが書き込み可能なその他のディレクトリを使用できます。

これを設定するには、次のいずれかの方法があります:

- `values.yaml`に追加:

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- または、Helmアップグレードコマンドラインに含めます:

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

この設定により、AIゲートウェイはOpenShiftのセキュリティ制約を尊重しつつ、HuggingFaceモデルを適切にキャッシュできます。選択する正確なディレクトリは、特定のOpenShift設定とセキュリティポリシーによって異なる場合があります。

### 自己署名証明書エラー {#self-signed-certificate-error}

AIゲートウェイがカスタム認証局（CA）によって署名された証明書または自己署名証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続しようとすると、AIゲートウェイによって`[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain`エラーがログに記録されます。

これを解決するするには、[自己署名SSL証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続する](#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate)を参照してください。

### PEMファイルの読み込み時のSSL証明書エラー {#ssl-certificate-errors-when-loading-pem-files}

DockerコンテナにPEMファイルを読み込む際に`JWKError`というエラーが発生した場合、SSL証明書エラーを解決する必要があるかもしれません。

このイシューを修正するには、Dockerコンテナで適切な証明書バンドルパスを設定するために、次の環境変数を使用します:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

`/path/to/ca-bundle.pem`を証明書バンドルのパスに置き換えます。
