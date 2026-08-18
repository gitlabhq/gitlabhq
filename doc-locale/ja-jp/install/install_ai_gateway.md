---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabと大規模言語モデル間のゲートウェイ。
title: GitLab AIゲートウェイをインストールする
---

[AIゲートウェイ](../administration/gitlab_duo/gateway.md)は、AIネイティブなGitLab Duo機能へのアクセスを提供する2つのサービスの組み合わせです:

- AIゲートウェイサービス
- [GitLab Duo Agent Platformサービス](../user/duo_agent_platform/_index.md)

## 認証とJSON Web Tokens（JWT） {#authentication-and-json-web-tokens-jwt}

GitLab Duo機能にアクセスするため、AIゲートウェイはJWTを使用して、GitLabインスタンス上の認証済みユーザーからのリクエストであることを認証します。お使いのGitLabインスタンスがトークンをリクエストすると、サービスはリクエストを認証する短期間有効な署名済みトークンを発行します。

独自のAIゲートウェイをホストする場合、署名キーペアを生成し、キーを環境変数としてサービスに渡す必要があります。

各サービスは独自のキーペアを使用します:

- AIゲートウェイは、GitLab Duoコード提案やGitLab Duo Chatなどの機能に`AIGW_SELF_SIGNED_JWT__SIGNING_KEY`および`AIGW_SELF_SIGNED_JWT__VALIDATION_KEY`を使用します。
- GitLab Duo Agent Platformサービスは`DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY`および`DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY`を使用します。

各ペアは次のロールを提供します:

- 署名キーは、サービスが発行するトークンに署名します。
- 検証キーは、キーのローテーション中にトークンを検証し、以前のキーで署名されたトークンが期限切れになるまで有効なままであることを保証します。

キーペアの両方のキーは、PEM形式のRSA 2048ビット秘密キーである必要があります。これらのキーが不足している場合、サービスはトークンに署名できず、リクエストはトークン作成エラーで失敗します。

## Dockerを使用してインストールする {#install-by-using-docker}

GitLab AIゲートウェイDockerイメージには、必要なすべてのコードコンテナに格納されています。

前提条件: 

- [Docker](https://docs.docker.com/engine/install/#server)などのコンテナエンジンをインストールします。
- ネットワークでアクセス可能な有効なホスト名を使用します。`localhost`は使用しないでください。
- `linux/amd64`アーキテクチャ用に約340 MB（圧縮済み）、および最低512 MBのRAMがあることを確認します。
- コンテナが`ai_gateway`および`duo-workflow-service`サービス用に少なくとも2つのCPUにアクセスできることを確認します。
- JWT署名キーを生成します:
  - GitLab Duo Agent Platformの場合:

    ```shell
    openssl genrsa -out duo_workflow_jwt.key 2048
    openssl genrsa -out duo_workflow_validation.key 2048
    ```

  - AIゲートウェイの場合（Duo Chatなどの機能に必要）:

    ```shell
    openssl genrsa -out aigw_signing.key 2048
    openssl genrsa -out aigw_validation.key 2048
    ```

  > [!warning]
  > 生成されたすべてのキーファイルを安全に保管し、公開しないでください。これらのキーはJWTの署名に使用され、機密性の高い認証情報として扱われる必要があります。

特にヘビーユースの場合、パフォーマンスを向上させるために、最小要件よりも多くのディスク領域、メモリ、およびリソースを割り当てることを検討してください。RAMとディスク容量が増えると、ピーク時のAIゲートウェイの効率性が向上します。

GitLab AIゲートウェイにはGPUは必要ありません。

### AIゲートウェイイメージ {#ai-gateway-images}

#### 標準イメージ {#standard-images}

標準AIゲートウェイイメージは、次の場所で入手できます:

- コンテナレジストリ: [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)
- DockerHub: [Stable](https://hub.docker.com/r/gitlab/model-gateway/tags)

GitLabバージョンが`vX.Y.*-ee`の場合、最新の`self-hosted-vX.Y.*-ee`タグが付いたAIゲートウェイイメージを使用します。例: 

- GitLabが`v18.2.1-ee`で、AIゲートウェイイメージに`self-hosted-v18.2.0-ee`、`self-hosted-v18.2.1-ee`、`self-hosted-v18.2.2-ee`のバージョンがある場合は、`self-hosted-v18.2.2-ee`を使用します。
- GitLabが`v18.2.1-ee`で、AIゲートウェイイメージにバージョン`self-hosted-v18.2.0-ee`のみがある場合は、`self-hosted-v18.2.0-ee`を使用します。

詳細については、[セルフホスト型AIゲートウェイのリリースプロセス](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/delivery/release.md)を参照してください。

> [!note]
> 夜間ビルドでは、下位互換性は保証されません。明示的なバージョンタグが付いた安定したリリースを常に使用します。

#### FIPS検証済みイメージ {#fips-validated-images}

FIPS 140-3検証済み暗号化を必要とする環境では、FIPS検証済みAIゲートウェイイメージを使用します。このイメージはRed Hat UBI 9上に構築されており、CMVP検証済みの[Red Hat OpenSSL FIPSプロバイダー](https://access.redhat.com/compliance/fips)を使用しています。

FIPS検証済みAIゲートウェイイメージは、次の場所で入手できます:

- コンテナレジストリ: [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/9518478)
- DockerHub: [Stable](https://hub.docker.com/r/gitlab/model-gateway-self-hosted-fips/tags)

標準イメージと同じバージョンタグ形式（`self-hosted-vX.Y.Z-ee`）を使用します。

FIPS検証済みコンテナを起動するには、[Docker実行コマンド](#start-a-container-from-the-image)のイメージ参照をFIPSイメージに置き換えます:

```shell
registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway/self-hosted-fips:<ai-gateway-tag>
```

### イメージからコンテナを起動する {#start-a-container-from-the-image}

1. コンテナを起動するには、次のコマンドを実行します:

   ```shell
   docker run -d -p 5052:5052 -p 50052:50052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=<your_gitlab_instance>/api/v4/ \
    -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
    -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
    -e DUO_WORKFLOW_AUTH__ENABLED="true" \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
    registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
   ```

   次のプレースホルダーを置き換えます:

   - `<your_gitlab_instance>`: お使いのGitLabインスタンスのURL（例: `https://gitlab.example.com`）。
   - `<ai-gateway-tag>`: お使いのGitLabインスタンスに一致するバージョン。GitLabバージョンが`vX.Y.0`の場合、`self-hosted-vX.Y.0-ee`を使用します。

   コンテナホストから`http://localhost:5052`にアクセスすると、`{"error":"No authorization header presented"}`が返されるはずです。

1. ポート`5052`および`50052`がホストからコンテナに転送されていることを確認します。ポート`5052`は、AIゲートウェイのHTTP通信を処理します。ポート`50052`は、GitLab Duo Agent PlatformサービスのgRPC通信を処理します。
1. オフラインライセンスを使用するGitLabインスタンスの場合、AIGWコンテナで`-e DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=<your_gitlab_instance>`および`-e AIGW_CUSTOMER_PORTAL_URL=<your_gitlab_instance>`を設定します。この設定では:
   - GitLab Duo Workflow ServiceがローカルのGitLabインスタンスに対してのみ認証するように強制します。
   - 到達不能なCustomersDot呼び出しによって発生する20秒の遅延を解消します。
1. [AIゲートウェイ](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway) URLと[GitLab Duo Agent Platformサービス](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) URLを構成します。
1. オプション。オプション。GitLab Duo Agent PlatformエンドポイントでTLSを使用している場合:
   1. 右上隅で、**管理者**を選択します。
   1. **GitLab Duo** > **設定の変更**を選択します。
   1. **GitLab Duo Agent PlatformサービスでTLSを使用する**チェックボックスを選択します。

### ネットワークアクセスを制限する {#restrict-network-access}

システムを強化するために、次のネットワーク構成を行います:

- AIゲートウェイコンテナの送信ネットワークアクセスを制限します。
- コンテナからの他のすべての送信トラフィックをブロックします。

AIゲートウェイは、次の送信アクセスを必要とします。これらをネットワーク制限の例外として含めることを確認します:

- お使いのGitLabインスタンス（`AIGW_GITLAB_URL`）。
- 構成済みのAIモデルプロバイダーエンドポイント（例: Anthropic、Gemini Enterprise Agent Platform、またはAzure OpenAI）。
- オフラインライセンスを使用しない限り、ライセンス検証のための`customers.gitlab.com`。

> [!warning]
> 適用する前に、非本番環境でファイアウォールルールをテストします。厳しすぎるルールは、AIゲートウェイの機能を損なう可能性があります。

Linuxホストでの送信アクセスを制限するには、`DOCKER-USER`チェーンで`iptables`ルールを使用します。詳細については、[Dockerパケットフィルタリングとファイアウォール](https://docs.docker.com/engine/network/packet-filtering-firewalls/)を参照してください。

## DockerとNGINXおよびSSLを設定する {#set-up-docker-with-nginx-and-ssl}

> [!note]
> NGINXまたはCaddyをリバースプロキシとしてデプロイするこの方法は、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/455854) 455854が実装されるまでのSSLをサポートするための暫定的な回避策です。

AIゲートウェイインスタンスでSSLを使用するには、以下を使用します:

- Docker
- リバースプロキシとしてのNGINX
- Let's Encrypt（SSL証明書用）

NGINXは外部クライアントとの安全な接続を管理します。受信HTTPSリクエストを復号化してから、AIゲートウェイに渡します。

前提条件: 

- DockerとDocker Composeがインストール済み
- 登録および構成済みのドメイン名

### 構成ファイルを作成する {#create-configuration-files}

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
           # proxy_read_timeout is the longest allowed idle gap between response chunks,
           # not the total response time. Reasoning models can pause for minutes before responding.
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
           # proxy_read_timeout is the longest allowed idle gap between response chunks,
           # not the total response time. Reasoning models can pause for minutes before responding.
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

### Let's Encryptを使用してSSL証明書を設定する {#set-up-ssl-certificate-by-using-lets-encrypt}

SSL証明書を設定するには:

- DockerベースのNGINXサーバーの場合、Certbotは[Let's Encrypt証明書を実装する自動化された方法](https://phoenixnap.com/kb/letsencrypt-docker)を提供します。
- または、[Certbotの手動インストール](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)を使用することもできます。

### 環境ファイルを作成する {#create-an-environment-file}

JWT署名および検証キーを保存するための`.env`ファイルを作成します:

```shell
echo "AIGW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat aigw_signing.key)\"" > .env
echo "AIGW_SELF_SIGNED_JWT__VALIDATION_KEY=\"$(cat aigw_validation.key)\"" >> .env
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat duo_workflow_jwt.key)\"" >> .env
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY=\"$(cat duo_workflow_validation.key)\"" >> .env
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

### デプロイと検証 {#deploy-and-validate}

ソリューションをデプロイして検証するには:

1. `nginx`と`AIGW`コンテナを起動し、それらが実行中であることを確認します:

   ```shell
   docker compose up
   docker ps
   ```

1. GitLabインスタンスがAIゲートウェイにアクセスするように[構成](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway)します。
1. GitLabインスタンスが[GitLab Duo Agent Platformサービス](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)のURLにアクセスするように構成します。
1. ヘルスチェックを実行し、AIゲートウェイとAgent Platformの両方にアクセスできることを確認します。

## Helmチャートを使用してインストールする {#install-by-using-helm-chart}

前提条件: 

- 以下が必要です:
  - DNSレコードを追加できる、所有しているドメイン。
  - Kubernetesクラスター。
  - `kubectl`の動作するインストール。
  - Helmバージョンv3.11.0以降の動作するインストール。

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

1. AIゲートウェイを公開する予定のドメインの証明書を生成します。
1. 以前に作成したネームスペースにTLSシークレットを作成します:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. [チャートのパッケージレジストリ](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages)で最新のパッケージのバージョン番号を取得します。
1. AIゲートウェイがAPIにアクセスするには、GitLabインスタンスの場所を知っている必要があります。これを行うには、`gitlab.url`と`gitlab.apiUrl`を`ingress.hosts`と`ingress.tls`の値と共に次のように設定します:

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
     --set "extraEnvironmentVariables[0].name=AIGW_SELF_SIGNED_JWT__SIGNING_KEY" \
     --set "extraEnvironmentVariables[0].value=$(cat aigw_signing.key)" \
     --set "extraEnvironmentVariables[1].name=AIGW_SELF_SIGNED_JWT__VALIDATION_KEY" \
     --set "extraEnvironmentVariables[1].value=$(cat aigw_validation.key)" \
     --set "extraEnvironmentVariables[2].name=DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY" \
     --set "extraEnvironmentVariables[2].value=$(cat duo_workflow_jwt.key)" \
     --set "extraEnvironmentVariables[3].name=DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY" \
     --set "extraEnvironmentVariables[3].value=$(cat duo_workflow_validation.key)" \
     --set "extraEnvironmentVariables[4].name=DUO_WORKFLOW_AUTH__ENABLED" \
     --set "extraEnvironmentVariables[4].value={{ true | quote }}" \
     --timeout=300s --wait --wait-for-jobs
   ```

`image.tag`として使用できるAIゲートウェイバージョンのリストは、[コンテナレジストリ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)で見つけることができます。

このステップでは、すべてのリソースが割り当てられ、AIゲートウェイが起動するまでに数秒かかる場合があります。

既存の`nginx` Ingressコントローラーが別のネームスペースでサービスを提供しない場合、AIゲートウェイ用に独自の**Ingress Controller**を設定する必要があるかもしれません。マルチネームスペースデプロイメント用にIngressが正しく設定されていることを確認してください。

`ai-gateway` Helmチャートのバージョンについては、`helm search repo ai-gateway --versions`を使用して適切なチャートバージョンを見つけます。

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

GitLabインスタンスまたはモデルエンドポイントが自己署名証明書で構成されている場合、ルート認証局（CA）証明書をAIゲートウェイの証明書バンドルに追加する必要があります。

これを行うには、次のいずれかの方法があります:

- ルートCA証明書をAIゲートウェイに渡し、認証が成功するようにします。
- ルートCA証明書をAIゲートウェイコンテナのCAバンドルに追加します。

### ルートCA証明書をAIゲートウェイに渡す {#pass-the-root-ca-certificate-to-the-ai-gateway}

ルートCA証明書をAIゲートウェイに渡し、認証が成功するようにするには、`REQUESTS_CA_BUNDLE`環境変数を設定します。GitLabはベースとなる信頼済みCAリストに[Certifi](https://pypi.org/project/certifi/)を使用するため、カスタムCAバンドルを次のように構成します:

1. Certifi `cacert.pem`ファイルをダウンロードします:

   ```shell
   curl "https://raw.githubusercontent.com/certifi/python-certifi/2024.07.04/certifi/cacert.pem" --output cacert.pem
   ```

1. 自己署名ルートCA証明書をファイルに追記します。たとえば、証明書を作成するために`mkcert`を使用した場合:

   ```shell
   cat "$(mkcert -CAROOT)/rootCA.pem" >> path/to/your/cacert.pem
   ```

1. `REQUESTS_CA_BUNDLE`をお使いの`cacert.pem`ファイルへのパスに設定します。たとえば、GDKでは、`$GDK_ROOT/env.runit`に以下を追加します:

   ```shell
   export REQUESTS_CA_BUNDLE=/path/to/your/cacert.pem
   ```

### ルートCA証明書をAIゲートウェイコンテナのCAバンドルに追加する {#add-the-root-ca-certificate-to-the-ai-gateway-containers-ca-bundle}

AIゲートウェイがカスタムCAによって署名されたGitLab Self-Managedインスタンスの証明書を信頼できるようにするには、ルートCA証明書をAIゲートウェイコンテナのCAバンドルに追加します。

この方法では、チャートの以降のバージョンでルートCAバンドルに加えられた変更は許可されません。

AIゲートウェイのHelmチャートデプロイでこれを行うには:

1. カスタムルートCA証明書をローカルファイルに追記します:

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

1. チャット`values.yml`のシークレットを使用して、`volume`および`volumeMount`を定義します。これにより、コンテナに`/tmp/ca-certificates.crt`ファイルが作成されます:

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

1. マウントされたファイルを指すように`REQUESTS_CA_BUNDLE`と`SSL_CERT_FILE`環境変数を設定します:

   ```shell
   extraEnvironmentVariables:
     - name: REQUESTS_CA_BUNDLE
       value: /tmp/ca-certificates.crt
     - name: SSL_CERT_FILE
       value: /tmp/ca-certificates.crt
   ```

1. チャートを再デプロイします。

[イシュー](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/issues/3) 3は、Helmチャートでこれをネイティブにサポートするために存在します。

#### Dockerデプロイの場合 {#for-a-docker-deployment}

Dockerデプロイの場合も、同じ方法を使用します。唯一の違いは、ローカルファイルをコンテナにマウントするには、`--volume /root/ca-certificates.crt:/tmp/ca-certificates.crt`を使用することです。

## 相互TLS（mTLS）を必要とするモデルエンドポイントに接続する {#connect-to-a-model-endpoint-that-requires-mutual-tls-mtls}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6084)されました。

{{< /history >}}

モデルエンドポイントまたはその前にあるプロキシが、呼び出し元にクライアント証明書での認証を要求する場合、AIゲートウェイが証明書を提示するように構成します。このアプローチは、`curl --cert`オプションと同等です。

mTLSを必要とするモデルエンドポイントに接続するには、AIゲートウェイで次の環境変数を設定します:

| 変数                  | 必須 | 説明 |
|---------------------------|----------|-------------|
| `AIGW_MTLS__ENABLED`      | はい      | アップストリームモデルエンドポイントにクライアント証明書を提示するには、`true`に設定します。 |
| `AIGW_MTLS__CERT_FILE`    | はい      | クライアント証明書PEMファイルへのパス。結合された証明書と秘密キーを含めることができます。または、別のキーには`AIGW_MTLS__KEY_FILE`を使用します。 |
| `AIGW_MTLS__KEY_FILE`     | いいえ       | `AIGW_MTLS__CERT_FILE`にバンドルされていない場合のクライアント秘密キーへのパス。 |
| `AIGW_MTLS__KEY_PASSWORD` | いいえ       | 暗号化された秘密キーのパスワード。`AIGW_MTLS__KEY_FILE`が必要です。 |
| `AIGW_MTLS__VERIFY`       | いいえ       | アップストリームサーバー証明書の検証を無効にするには、`false`に設定します。`true`がデフォルトです。 |
| `AIGW_MTLS__CA_BUNDLE`    | いいえ       | アップストリームサーバー証明書を検証するために使用されるCAバンドルへのパス（例: 企業CA）。この変数が設定されていない場合、AIゲートウェイは`SSL_CERT_FILE`（設定されている場合）または組み込みのCAバンドルに対して検証します。 |

GitLab Helmチャートデプロイの場合、クライアント証明書をマウントし、変数を設定します:

```yaml
volumes:
  - name: mtls-client-cert
    secret:
      secretName: aigw-mtls-client-cert
      optional: false

volumeMounts:
  - name: mtls-client-cert
    mountPath: /certs
    readOnly: true

extraEnvironmentVariables:
  - name: AIGW_MTLS__ENABLED
    value: "true"
  - name: AIGW_MTLS__CERT_FILE
    value: /certs/client.pem
```

Dockerデプロイの場合、同じ環境変数を使用し、`--volume /path/to/client.pem:/certs/client.pem`で証明書をマウントします。

AIゲートウェイは、アップストリームサーバーがTLSハンドシェイク中に証明書をリクエストした場合にのみ、クライアント証明書を提示します。この設定は、クライアント証明書を必要としないモデルエンドポイントには影響しません。

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

1. 新しいイメージをプルして[実行](#start-a-container-from-the-image)します。
1. 環境変数がすべて正しく設定されていることを確認します。

## セキュリティアップデートとイメージ検証 {#security-updates-and-image-verification}

最新のセキュリティパッチを実行していることを確認するには、デプロイ方法に基づいてこれらのガイドラインに従ってください。

### KubernetesまたはHelmデプロイメントの場合 {#for-kubernetes-or-helm-deployments}

0.7.0より前の[チャート](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages)バージョンとKubernetesは、デフォルトで`imagePullPolicy: IfNotPresent`を使用します。これにより、タグが変更されていない場合、更新されたイメージはプルされません。これは、同じバージョンタグでリリースされたセキュリティパッチを見逃す可能性があることを意味します。

イメージダイジェストを使用する次のアプローチを使用する必要があります:

```shell
# Find the image digest from the container registry
# Use this digest in your Helm install/upgrade command

helm upgrade --install ai-gateway \
  ai-gateway/ai-gateway \
  --set="image.tag=self-hosted-v18.2.1-ee@sha256:abc123..." \
  # ... other flags
```

または、次のいずれかのアプローチで`imagePullPolicy`を使用できます:

- `imagePullPolicy`を常に設定します:

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

更新のプルを強制するには:

```shell
kubectl rollout restart deployment/ai-gateway -n ai-gateway
```

### Dockerデプロイメントの場合 {#for-docker-deployments}

アップグレード時に、最新イメージをプルしていることを検証します:

```shell
# Check current image digest
docker images --digests | grep ai-assist

# Pull latest version explicitly
docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>

# Verify digest changed
docker images --digests | grep ai-assist
```

イミュータブルなデプロイメントにイメージダイジェストを使用するには:

```shell
docker run -d -p 5052:5052 -p 50052:50052 \
 -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
 -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
 -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v18.2.1-ee@sha256:abc123...
```

## 代替インストール方法 {#alternative-installation-methods}

AIゲートウェイをインストールする代替方法については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/463773) 463773を参照してください。

## ヘルスチェックとデバッグ {#health-check-and-debugging}

GitLab Duo Self-Hostedインストールのデバッグを行うには、次のコマンドを実行します:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

以下を確認してください:

- AIゲートウェイのURLは正しく構成されています（`Ai::Setting.instance.ai_gateway_url`経由）。
- GitLab Duoアクセスは、`/admin/code_suggestions`経由でルートユーザーに対して明示的に有効にされています。

アクセスイシューが解決しない場合は、認証が正しく構成されており、ヘルスチェックが通過していることを確認します。

永続的なイシューがある場合、エラーメッセージは`AIGW_AUTH__BYPASS_EXTERNAL=true`で認証をバイパスすることを提案する可能性がありますが、これはトラブルシューティングの場合のみ行ってください。

**管理者** > **GitLab Duo**に移動して、[ヘルスチェック](../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo)を実行することもできます。

これらのテストはオフライン環境で実行されます:

| Test | 説明 |
|-----------------|-------------|
| ネットワーク | テスト対象:<br>\- AIゲートウェイURLが`ai_settings`テーブルを介してデータベースに適切に構成されているかどうか。<br> \- お使いのインスタンスが構成されたURLに接続できるかどうか。<br><br>インスタンスがURLに接続できない場合、ファイアウォールまたはプロキシサーバーの設定が[接続を許可](../administration/gitlab_duo/configure/_index.md)していることを確認してください。環境変数`AI_GATEWAY_URL`はレガシー互換性のためにまだサポートされていますが、管理性を向上させるためにはデータベースを介してURLを構成することをお勧めします。 |
| ライセンス | お使いのライセンスがコード提案機能にアクセスする能力があるかどうかをテストします。 |
| システム連携 | インスタンスでコード提案を使用できるかどうかをテストします。システム連携アセスメントが失敗した場合、ユーザーはGitLab Duo機能を使用できない可能性があります。 |

## AIゲートウェイを監視する {#monitor-the-ai-gateway}

Prometheusを使用して、AIゲートウェイの使用状況とパフォーマンスに関するメトリクスを収集します。

### AIゲートウェイのPrometheusメトリクスを設定する {#set-up-prometheus-metrics-for-the-ai-gateway}

Prometheusメトリクスを設定するには:

1. 必要な環境変数を設定し、ポート`8082`を開きます:

   ```shell
   -e AIGW_FASTAPI__METRICS_HOST=0.0.0.0
   -e AIGW_FASTAPI__METRICS_PORT=8082
   ```

### GitLab Duo Workflowサービス用にPrometheusを設定する {#set-up-prometheus-for-the-gitlab-duo-workflow-service}

GitLab Duo WorkflowサービスでPrometheusメトリクスを設定するには:

1. 必要な環境変数を設定し、ポート`8083`を開きます:

   ```shell
   -e PROMETHEUS_METRICS__ADDR=0.0.0.0
   -e PROMETHEUS_METRICS__PORT=8083
   ```

1. `gitlab-ai-gateway`コンテナからホストにメトリクスポートを公開します:

   - Docker CLIの場合:

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

   これにより、AIゲートウェイメトリクスエンドポイントがポート`8082`に、GitLab Duo Workflow Serviceメトリクスエンドポイントがポート`8083`に公開されます。

1. AIゲートウェイコンテナを再起動します。

### Prometheusをメトリクスのスクレイプに構成する {#configure-prometheus-to-scrape-metrics}

AIゲートウェイとGitLab Duo Workflowサービスからメトリクスを収集するには、次の`prometheus.yml`設定をPrometheusインスタンスに追加します。この設定では、Prometheusは15秒ごとに両方のサービスからメトリクスをスクレイプします。

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

### メトリクス収集を検証する {#verify-metrics-collection}

AIゲートウェイとGitLab Duo Workflowサービスのターゲットが収集されていることを検証するには:

1. Prometheus UIで、**ステータス > Targets**に移動します。
1. **アラート**または**グラフ**タブに移動してメトリクスをクエリします。AIゲートウェイとGitLab Duo Workflowサービスは、次のエンドポイントでメトリクスを公開します:

   - AIゲートウェイ: `http://<your_AIGW_domain>:8082/metrics`
   - GitLab Duo Workflowサービス: `http://<your_duo_agent_platform_service_domain>:8083/metrics`

## AIゲートウェイはオートスケールする必要がありますか？ {#does-the-ai-gateway-need-to-autoscale}

オートスケールは必須ではありませんが、変動するワークロード、高い並行処理要件、または予測不能な使用パターンを持つ環境には推奨されます。GitLab本番環境では:

- ベースライン設定: 2 CPUコアと8 GB RAMを備えた単一のAIゲートウェイインスタンスは、約40の並行処理リクエストを処理できます。
- スケーリングガイドライン: AWS t3.2xlargeインスタンス（8 vCPU、32 GB RAM）のような大規模な設定では、ゲートウェイはベースライン設定の4倍に相当する最大160の並行処理リクエストを処理できます。
- リクエストスループット: GitLab.comの観測された使用状況から、1000アクティブユーザーあたり7 RPS（1秒あたりのリクエスト数）が計画にとって合理的なメトリクスであることが示唆されています。
- オートスケールオプション: Kubernetes Horizontal Pod Autoscalers（HPA）または類似のメカニズムを使用して、CPU、メモリ使用率、または要求レイテンシーのしきい値などのメトリクスに基づいてインスタンスの数を動的に調整します。

## デプロイサイズ別の設定例 {#configuration-examples-by-deployment-size}

- 小規模デプロイ:
  - 2 vCPUと8 GB RAMを備えた単一のインスタンス。
  - 最大40の並行処理リクエストを処理します。
  - 最大50ユーザーで予測可能なワークロードを持つチームまたは組織。
  - 固定インスタンスで十分な場合があります。オートスケールはコスト効率性のために無効にできます。
- 中規模デプロイ:
  - 8 vCPUと32 GB RAMを備えた単一のAWS t3.2xlargeインスタンス。
  - 最大160の並行処理リクエストを処理します。
  - 50～200ユーザーで中程度の並行処理要件を持つ組織。
  - 50% CPU使用率または500msを超える要求レイテンシーのしきい値を持つKubernetes HPAを実装します。
- 大規模デプロイ:
  - 複数のAWS t3.2xlargeインスタンスまたは同等のもののクラスター。
  - 各インスタンスは160の並行処理リクエストを処理し、複数のインスタンスで数千人のユーザーにスケールします。
  - 200人以上のユーザーを抱え、変動する高並行処理ワークロードを持つ企業。
  - HPAを使用して、リアルタイムの需要に基づいてポッドをスケールし、クラスター全体のリソース調整のためにノードオートスケールと組み合わせます。

## AIゲートウェイコンテナの仕様とリソース割り当て {#ai-gateway-container-specs-and-resource-allocation}

AIゲートウェイは、次のリソース割り当てで効果的に動作します:

- コンテナあたり2 CPUコアと8 GBのRAM。
- コンテナは、通常、GitLab本番環境で約7.39%のCPUとそれに比例したメモリを利用し、成長やバーストアクティビティに対応する余地を残しています。

## リソース競合の軽減戦略 {#mitigation-strategies-for-resource-contention}

- Kubernetesのリクエストと制限を使用して、AIゲートウェイコンテナが保証されたCPUとメモリ割り当てを受け取ることを確認します。例: 

  ```yaml
  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "32Gi"
      cpu: "8"
  ```

- PrometheusやGrafanaのようなツールを実装して、リソース使用率（CPU、メモリ、レイテンシー）を追跡し、ボトルネックを早期に検出します。
- ノードまたはインスタンスをAIゲートウェイに排他的に割り当てて、他のサービスとのリソース競合を防ぎます。

## スケーリング戦略 {#scaling-strategies}

- Kubernetes HPAを使用して、次のようなリアルタイムのメトリクスに基づいてポッドをスケールします:
  - 平均CPU使用率が50%を超える。
  - 要求レイテンシーが常に500msを超える。
  - ノードオートスケールを有効にして、ポッドの増加に合わせてインフラストラクチャリソースを動的にスケールします。

## スケーリングの推奨事項 {#scaling-recommendations}

| デプロイサイズ | インスタンスタイプ      | リソース             | 容量（並行処理リクエスト） | スケーリングの推奨事項                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| S            | 2 vCPU、8 GB RAM | 単一インスタンス        | 40                              | 固定デプロイメント。オートスケールなし。           |
| 中           | AWS t3.2xlarge    | 単一インスタンス     | 160                             | CPUまたはレイテンシーのしきい値に基づくHPA。     |
| L            | 複数のt3.2xlarge | クラスター化されたインスタンス   | インスタンスあたり160               | 高需要のためのHPA + ノードオートスケール。     |

## 複数のGitLabインスタンスをサポートする {#support-multiple-gitlab-instances}

単一のAIゲートウェイをデプロイして複数のGitLabインスタンスをサポートするか、インスタンスまたは地理的リージョンごとに個別のAIゲートウェイをデプロイできます。どちらが適切かを判断するために、以下を考慮してください:

- 1,000請求対象ユーザーあたり毎秒約7リクエストの予想トラフィック。
- すべてのインスタンスにおける合計並行処理リクエスト数に基づくリソース要件。
- 各GitLabインスタンスのベストプラクティス認証設定。

## AIゲートウェイとインスタンスを併置する {#co-locate-your-ai-gateway-and-instance}

AIゲートウェイは、場所に関係なくユーザーに最適なパフォーマンスを保証するために、世界中の複数のリージョンで利用可能です:

- GitLab Duo機能の応答時間の改善。
- 地理的に分散したユーザーのレイテンシーを削減。
- データ主権要件へのコンプライアンス。

AIゲートウェイは、GitLabインスタンスと同じ地理的リージョンに配置し、特にレイテンシーに敏感なコード提案のような機能のために、スムーズなデベロッパーエクスペリエンスを提供する必要があります。

## トラブルシューティング {#troubleshooting}

AIゲートウェイを使用する際に、次のイシューに遭遇する可能性があります。

### OpenShiftのパーミッションイシュー {#openshift-permission-issues}

OpenShiftにAIゲートウェイをデプロイする際、OpenShiftのセキュリティモデルによりパーミッションエラーが発生する可能性があります。

#### `/tmp`にある読み取り専用ファイルシステム {#read-only-filesystem-at-tmp}

AIゲートウェイは`/tmp`への書き込みが必要です。ただし、セキュリティが制限されたOpenShift環境では、`/tmp`が読み取り専用である可能性があります。

このイシューを解決するには、新しい`EmptyDir`ボリュームを作成し、`/tmp`にマウントします。これを行うには、次のいずれかの方法があります:

- コマンドラインから:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- お使いの`values.yaml`に追加:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

#### HuggingFaceモデル {#huggingface-models}

デフォルトでは、AIゲートウェイはHuggingFaceモデルのキャッシュに`/home/aigateway/.hf`を使用しますが、OpenShiftのセキュリティ制限された環境では書き込み可能でない場合があります。これにより、次のようなパーミッションエラーが発生する可能性があります:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

これを解決するには、`HF_HOME`環境変数を書き込み可能な場所に設定します。`/var/tmp/huggingface`またはコンテナによって書き込み可能な任意のディレクトリを使用できます。

これは次のいずれかの方法で構成できます:

- お使いの`values.yaml`に追加:

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

この設定により、AIゲートウェイはOpenShiftのセキュリティ制約を尊重しながらHuggingFaceモデルを適切にキャッシュできます。選択する正確なディレクトリは、特定のOpenShift設定とセキュリティポリシーによって異なる場合があります。

### ボリュームマウントによってシャドウされたトークナイザーキャッシュ {#tokenizer-cache-shadowed-by-a-volume-mount}

AIゲートウェイイメージ内のプリキャッシュされたトークナイザーファイルは、次の場合にボリュームマウントによってシャドウされる可能性があります:

- コード補完リクエストが`500`エラーを返す。
- AIゲートウェイログに、`transformers/utils/hub.py`からの`OSError`が`huggingface.co`から`Salesforce/codegen2-16B`をダウンロードしようとしていることが表示される。

セルフホスト型AIゲートウェイイメージ（`self-hosted-vX.Y.Z-ee`）は`HF_HUB_OFFLINE=true`を設定し、ビルド時にトークナイザーをプリキャッシュするため、ランタイム時に`huggingface.co`へのネットワークアクセスは発生しないはずです。ネットワークアクセスが発生した場合、Helm値の空のディレクトリが`/home/aigateway/.hf`にマウントされ、キャッシュされたファイルを上書きする可能性があります。

`huggingface.co`へのエグレスアクセスを許可することで、このイシューを解決しようとしないでください。代わりに、イシューを診断するには、AIゲートウェイポッドで次を実行します:

```shell
ls -la /home/aigateway/.hf/hub/ 2>/dev/null || echo "NO_CACHE_DIR"
env | grep -E '^(HF_|TRANSFORMERS_)'
```

キャッシュディレクトリが見つからないか空の場合は、次を実行します:

1. `values.yaml`で、`/home/aigateway/.hf`または`HF_HOME`によって設定されたパスをターゲットとする`volumeMounts`があるかどうかを確認します。
1. マウントを、イメージの組み込みキャッシュと重ならないディレクトリに削除または再マッピングします。

### 自己署名証明書エラー {#self-signed-certificate-error}

AIゲートウェイがカスタム認証局（CA）によって署名された証明書または自己署名証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続しようとすると、AIゲートウェイによって`[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain`エラーがログに記録されます。

これを解決するには、[自己署名SSL証明書を使用してGitLabインスタンスまたはモデルエンドポイントに接続する](#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate)を参照してください。

### トークン作成失敗 {#token-creation-failed}

Duo Chatなどの機能を使用しているときに`Token creation failed`エラーが発生した場合、`AIGW_SELF_SIGNED_JWT__SIGNING_KEY`と`AIGW_SELF_SIGNED_JWT__VALIDATION_KEY`環境変数がAIゲートウェイに設定されていない可能性があります。

これらのキーは、AIゲートウェイが短期間有効なユーザーJWTを発行するために必要です。これらのキーがないと、AIゲートウェイはトークンに署名できず、JWKの逆シリアル化失敗を引き起こします。

この問題を解決するには、次の手順に従います:

1. 必要なキーを生成します:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   ```

1. キーを環境変数として渡すことにより、お使いのAIゲートウェイコンテナにキーを追加します:

   ```shell
   -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
   -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)"
   ```

1. AIゲートウェイコンテナを再起動します。

### PEMファイルの読み込み時のSSL証明書エラー {#ssl-certificate-errors-when-loading-pem-files}

DockerコンテナにPEMファイルを読み込むときに`JWKError`というエラーが発生した場合、SSL証明書エラーを解決する必要があるかもしれません。

このイシューを修正するには、次の環境変数を使用して、Dockerコンテナ内の適切な証明書バンドルパスを設定します:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

`/path/to/ca-bundle.pem`をお使いの証明書バンドルへのパスに置き換えます。
