---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab과 대형 언어 모델 간의 게이트웨이입니다.
title: GitLab AI Gateway 설치
---

[AI Gateway](../administration/gitlab_duo/gateway.md)는 AI 기반 GitLab Duo 기능에 액세스할 수 있는 두 가지 서비스의 조합입니다:

- AI Gateway 서비스
- [GitLab Duo Agent Platform 서비스](../user/duo_agent_platform/_index.md)

## 인증 및 JSON Web Token(JWT) {#authentication-and-json-web-tokens-jwt}

GitLab Duo 기능에 액세스하기 위해 AI Gateway는 JWT를 사용하여 GitLab 인스턴스의 인증된 사용자로부터의 요청임을 확인합니다. GitLab 인스턴스가 토큰을 요청하면 서비스는 요청을 승인하는 단기 서명된 토큰을 발행합니다.

자체 AI Gateway를 호스팅할 때는 서명 키 쌍을 생성하여 환경 변수로 서비스에 전달해야 합니다.

각 서비스는 자체 키 쌍을 사용합니다:

- AI Gateway는 `AIGW_SELF_SIGNED_JWT__SIGNING_KEY` 및 `AIGW_SELF_SIGNED_JWT__VALIDATION_KEY`를 사용하여 GitLab Duo 코드 제안 및 GitLab Duo Chat 같은 기능을 지원합니다.
- GitLab Duo Agent Platform 서비스는 `DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY` 및 `DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY`를 사용합니다.

각 쌍은 다음 역할을 제공합니다:

- 서명 키는 서비스가 발행하는 토큰에 서명합니다.
- 유효성 검사 키는 키 로테이션 중에 토큰을 검증하므로 이전 키로 서명한 토큰은 만료될 때까지 유효하게 유지됩니다.

쌍의 두 키 모두 PEM 형식의 RSA 2048비트 개인 키여야 합니다. 이 키가 없으면 서비스가 토큰에 서명할 수 없으며 요청은 토큰 생성 오류로 실패합니다.

## Docker를 사용하여 설치 {#install-by-using-docker}

GitLab AI Gateway Docker 이미지는 모든 필요한 코드와 종속성을 단일 컨테이너에 포함합니다.

전제 조건:

- [Docker](https://docs.docker.com/engine/install/#server) 같은 Docker 컨테이너 엔진을 설치합니다.
- 네트워크에서 액세스할 수 있는 유효한 호스트명을 사용합니다. `localhost`를 사용하지 마세요.
- `linux/amd64` 아키텍처의 경우 약 340MB(압축)와 최소 512MB의 RAM이 필요합니다.
- 컨테이너가 `ai_gateway` 및 `duo-workflow-service` 서비스를 위해 최소 2개의 CPU에 액세스할 수 있는지 확인합니다.
- JWT 서명 키를 생성합니다:
  - GitLab Duo Agent Platform의 경우:

    ```shell
    openssl genrsa -out duo_workflow_jwt.key 2048
    openssl genrsa -out duo_workflow_validation.key 2048
    ```

  - AI Gateway의 경우(Duo Chat 같은 기능에 필수):

    ```shell
    openssl genrsa -out aigw_signing.key 2048
    openssl genrsa -out aigw_validation.key 2048
    ```

  > [!warning]
  > 생성된 모든 키 파일을 안전하게 보관하고 공개적으로 공유하지 않습니다. 이 키는 JWT 서명에 사용되며 민감한 자격증명으로 처리해야 합니다.

특히 높은 사용량 상황에서 더 나은 성능을 보장하려면 최소 요구 사항보다 더 많은 디스크 공간, 메모리 및 리소스를 할당하는 것을 고려합니다. 더 높은 RAM과 디스크 용량은 최대 부하 중 AI Gateway의 효율성을 향상시킬 수 있습니다.

GitLab AI Gateway에는 GPU가 필요하지 않습니다.

### AI Gateway 이미지 {#ai-gateway-images}

#### 표준 이미지 {#standard-images}

표준 AI Gateway 이미지는 다음 위치에서 사용할 수 있습니다:

- 컨테이너 레지스트리: [안정적](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)
- DockerHub: [안정적](https://hub.docker.com/r/gitlab/model-gateway/tags)

GitLab 버전이 `vX.Y.*-ee`인 경우 최신 `self-hosted-vX.Y.*-ee` 태그가 있는 AI Gateway 이미지를 사용합니다. 예를 들어:

- GitLab이 `v18.2.1-ee`에 있고 AI Gateway 이미지에 `self-hosted-v18.2.0-ee`, `self-hosted-v18.2.1-ee` 및 `self-hosted-v18.2.2-ee` 버전이 있으면 `self-hosted-v18.2.2-ee`를 사용합니다.
- GitLab이 `v18.2.1-ee`에 있고 AI Gateway 이미지에만 `self-hosted-v18.2.0-ee` 버전이 있으면 `self-hosted-v18.2.0-ee`을 사용합니다.

자세한 내용은 [자체 호스팅 AI Gateway 릴리스 프로세스](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/delivery/release.md)를 참조합니다.

> [!note]
> 야간 빌드에서는 하위 호환성이 보장되지 않습니다. 항상 명시적 버전 태그가 있는 안정적인 릴리스를 사용합니다.

#### FIPS 검증 이미지 {#fips-validated-images}

FIPS 140-3 검증 암호화가 필요한 환경의 경우 FIPS 검증 AI Gateway 이미지를 사용합니다. 이 이미지는 Red Hat UBI 9를 기반으로 하며 CMVP 검증 [Red Hat OpenSSL FIPS 공급자](https://access.redhat.com/compliance/fips)를 사용합니다.

FIPS 검증 AI Gateway 이미지는 다음 위치에서 사용할 수 있습니다:

- 컨테이너 레지스트리: [안정적](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/9518478)
- DockerHub: [안정적](https://hub.docker.com/r/gitlab/model-gateway-self-hosted-fips/tags)

표준 이미지와 동일한 버전 태그 형식을 사용합니다(`self-hosted-vX.Y.Z-ee`).

FIPS 검증 컨테이너를 시작하려면 [Docker run 명령](#start-a-container-from-the-image)에서 이미지 참조를 FIPS 이미지로 바꿉니다:

```shell
registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway/self-hosted-fips:<ai-gateway-tag>
```

### 이미지에서 컨테이너 시작 {#start-a-container-from-the-image}

1. 컨테이너를 시작하려면 다음 명령을 실행합니다:

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

   다음 플레이스홀더를 바꿉니다:

   - `<your_gitlab_instance>`: GitLab 인스턴스 URL(예: `https://gitlab.example.com`).
   - `<ai-gateway-tag>`: GitLab 인스턴스와 일치하는 버전입니다. GitLab 버전이 `vX.Y.0`인 경우 `self-hosted-vX.Y.0-ee`을 사용합니다.

   컨테이너 호스트에서 `http://localhost:5052`에 액세스하면 `{"error":"No authorization header presented"}`를 반환해야 합니다.

1. 포트 `5052` 및 `50052`가 호스트에서 컨테이너로 전달되도록 합니다. 포트 `5052`은 AI Gateway의 HTTP 통신을 처리합니다. 포트 `50052`은 GitLab Duo Agent Platform 서비스의 gRPC 통신을 처리합니다.
1. 오프라인 라이선스를 사용하는 GitLab 인스턴스의 경우 AIGW 컨테이너에서 `-e DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=<your_gitlab_instance>` 및 `-e AIGW_CUSTOMER_PORTAL_URL=<your_gitlab_instance>`를 설정합니다. 이 구성:
   - GitLab Duo Workflow 서비스가 로컬 GitLab 인스턴스에만 대해 인증되도록 강제합니다.
   - 도달할 수 없는 CustomersDot 호출로 인한 20초 지연을 제거합니다.
1. [AI 게이트웨이 URL](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway)과 [GitLab Duo Agent Platform 서비스 URL](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)을 구성합니다.
1. 선택 사항. 로컬 GitLab Duo Agent Platform 엔드포인트가 TLS를 사용하는 경우:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. **GitLab Duo** > **구성 변경**을 선택합니다.
   1. **GitLab Duo Agent 플랫폼 서비스에 TLS를 사용하세요** 체크박스를 선택합니다.

### 네트워크 액세스 제한 {#restrict-network-access}

시스템을 강화하려면 다음 네트워크 구성을 수행합니다:

- AI Gateway 컨테이너의 아웃바운드 네트워크 액세스를 제한합니다.
- 컨테이너에서 다른 모든 아웃바운드 트래픽을 차단합니다.

AI Gateway에는 다음에 대한 아웃바운드 액세스가 필요합니다. 이를 네트워크 제한에 대한 예외로 포함해야 합니다:

- GitLab 인스턴스(`AIGW_GITLAB_URL`).
- 구성된 AI 모델 공급자 엔드포인트(예: Anthropic, Gemini Enterprise Agent Platform 또는 Azure OpenAI).
- `customers.gitlab.com`(라이선스 검증용, 오프라인 라이선스를 사용하지 않는 경우).

> [!warning]
> 방화벽 규칙을 프로덕션 환경이 아닌 환경에서 테스트한 후에 적용합니다. 지나치게 제한적인 규칙으로 인해 AI Gateway 기능이 손상될 수 있습니다.

Linux 호스트에서 아웃바운드 액세스를 제한하려면 `DOCKER-USER` 체인에서 `iptables` 규칙을 사용합니다. 자세한 내용은 [Docker 패킷 필터링 및 방화벽](https://docs.docker.com/engine/network/packet-filtering-firewalls/)을 참조합니다.

## Docker를 NGINX 및 SSL로 설정 {#set-up-docker-with-nginx-and-ssl}

> [!note]
> NGINX 또는 Caddy를 역방향 프록시로 배포하는 이 방법은 [이슈 455854](https://gitlab.com/gitlab-org/gitlab/-/issues/455854)가 구현될 때까지 SSL을 지원하기 위한 임시 해결책입니다.

AI Gateway 인스턴스에 SSL을 사용하려면 다음을 사용합니다:

- Docker
- NGINX를 역방향 프록시로 사용
- SSL 인증서용 Let's Encrypt

NGINX는 외부 클라이언트와의 보안 연결을 관리합니다. AI Gateway로 전달하기 전에 들어오는 HTTPS 요청을 해독합니다.

전제 조건:

- Docker 및 Docker Compose 설치됨
- 등록되고 구성된 도메인 이름

### 구성 파일 생성 {#create-configuration-files}

작업 디렉터리에서 다음 파일을 생성하는 것부터 시작합니다.

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

### Let's Encrypt를 사용하여 SSL 인증서 설정 {#set-up-ssl-certificate-by-using-lets-encrypt}

SSL 인증서를 설정하려면:

- Docker 기반 NGINX 서버의 경우 Certbot은 [Let's Encrypt 인증서를 구현하는 자동화된 방법](https://phoenixnap.com/kb/letsencrypt-docker)을 제공합니다.
- 또는 [Certbot 수동 설치](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)를 사용할 수 있습니다.

### 환경 파일 생성 {#create-an-environment-file}

`.env` 파일을 생성하여 JWT 서명 및 검증 키를 저장합니다:

```shell
echo "AIGW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat aigw_signing.key)\"" > .env
echo "AIGW_SELF_SIGNED_JWT__VALIDATION_KEY=\"$(cat aigw_validation.key)\"" >> .env
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat duo_workflow_jwt.key)\"" >> .env
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY=\"$(cat duo_workflow_validation.key)\"" >> .env
```

### Docker Compose 파일 생성 {#create-a-docker-compose-file}

이제 `docker-compose.yaml` 파일을 생성합니다.

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

### 배포 및 검증 {#deploy-and-validate}

솔루션을 배포하고 검증하려면:

1. `nginx` 및 `AIGW` 컨테이너를 시작하고 실행 중인지 확인합니다:

   ```shell
   docker compose up
   docker ps
   ```

1. [AI Gateway에 액세스하도록 GitLab 인스턴스를 구성](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway)합니다.
1. GitLab 인스턴스를 구성하여 [GitLab Duo Agent Platform 서비스](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)의 URL에 액세스합니다.
1. 상태 확인을 수행하고 AI Gateway 및 Agent Platform 모두 액세스 가능한지 확인합니다.

## Helm 차트를 사용하여 설치 {#install-by-using-helm-chart}

전제 조건:

- 다음이 필요합니다:
  - DNS 레코드를 추가할 수 있는 도메인입니다.
  - Kubernetes 클러스터입니다.
  - `kubectl`의 작동 설치입니다.
  - Helm 버전 v3.11.0 이상의 작동 설치입니다.

자세한 내용은 [GKE 또는 EKS에서 GitLab 차트 테스트](https://docs.gitlab.com/charts/quickstart/)를 참조합니다.

### AI Gateway Helm 리포지토리 추가 {#add-the-ai-gateway-helm-repository}

AI Gateway Helm 리포지토리를 Helm 구성에 추가합니다:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### AI Gateway 설치 {#install-the-ai-gateway}

1. `ai-gateway` 네임스페이스를 생성합니다:

   ```shell
   kubectl create namespace ai-gateway
   ```

1. AI Gateway를 노출할 계획인 도메인의 인증서를 생성합니다.
1. 이전에 생성된 네임스페이스에서 TLS 시크릿을 생성합니다:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. [차트의 패키지 레지스트리](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages)에서 최신 패키지의 버전 번호를 가져옵니다.
1. AI Gateway가 API에 액세스하려면 GitLab 인스턴스의 위치를 알아야 합니다. 이를 수행하려면 `gitlab.url` 및 `gitlab.apiUrl`를 `ingress.hosts` 및 `ingress.tls` 값과 함께 다음과 같이 설정합니다:

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

`image.tag`로 사용할 수 있는 AI Gateway 버전 목록은 [컨테이너 레지스트리](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)에서 찾을 수 있습니다.

이 단계는 모든 리소스를 할당하고 AI Gateway가 시작되는 데 몇 초 정도 걸릴 수 있습니다.

기존 `nginx` Ingress 컨트롤러가 다른 네임스페이스에서 서비스를 제공하지 않는 경우 AI Gateway를 위해 자신의 **Ingress Controller**를 설정해야 할 수도 있습니다. Ingress가 다중 네임스페이스 배포에 맞게 올바르게 설정되었는지 확인합니다.

`ai-gateway` Helm 차트 버전의 경우 `helm search repo ai-gateway --versions`를 사용하여 적절한 차트 버전을 찾습니다.

Pod가 실행될 때까지 기다립니다:

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

Pod가 실행 중이면 IP ingress 및 DNS 레코드를 설정할 수 있습니다.

## 자체 서명 SSL 인증서를 사용하여 GitLab 인스턴스 또는 모델 엔드포인트에 연결 {#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate}

GitLab 인스턴스 또는 모델 엔드포인트가 자체 서명 인증서로 구성된 경우 루트 인증 기관(CA) 인증서를 AI Gateway의 인증서 번들에 추가해야 합니다.

이를 수행하려면 다음 중 하나를 수행할 수 있습니다:

- 루트 CA 인증서를 AI Gateway로 전달하여 인증이 성공하도록 합니다.
- 루트 CA 인증서를 AI Gateway 컨테이너의 CA 번들에 추가합니다.

### 루트 CA 인증서를 AI Gateway로 전달 {#pass-the-root-ca-certificate-to-the-ai-gateway}

루트 CA 인증서를 AI Gateway로 전달하고 인증이 성공하도록 하려면 `REQUESTS_CA_BUNDLE` 환경 변수를 설정합니다. GitLab은 [Certifi](https://pypi.org/project/certifi/)를 신뢰할 수 있는 기본 CA 목록으로 사용하므로 다음과 같이 사용자 지정 CA 번들을 구성합니다:

1. Certifi `cacert.pem` 파일을 다운로드합니다:

   ```shell
   curl "https://raw.githubusercontent.com/certifi/python-certifi/2024.07.04/certifi/cacert.pem" --output cacert.pem
   ```

1. 자체 서명 루트 CA 인증서를 파일에 추가합니다. 예를 들어 `mkcert`을 사용하여 인증서를 생성한 경우:

   ```shell
   cat "$(mkcert -CAROOT)/rootCA.pem" >> path/to/your/cacert.pem
   ```

1. `REQUESTS_CA_BUNDLE`을 `cacert.pem` 파일의 경로로 설정합니다. 예를 들어 GDK에서 다음을 `$GDK_ROOT/env.runit`에 추가합니다:

   ```shell
   export REQUESTS_CA_BUNDLE=/path/to/your/cacert.pem
   ```

### 루트 CA 인증서를 AI Gateway 컨테이너의 CA 번들에 추가 {#add-the-root-ca-certificate-to-the-ai-gateway-containers-ca-bundle}

AI Gateway가 사용자 지정 CA에 의해 서명된 GitLab Self-Managed 인스턴스의 인증서를 신뢰하도록 하려면 루트 CA 인증서를 AI Gateway 컨테이너의 CA 번들에 추가합니다.

이 방법은 차트의 이후 버전에서 루트 CA 번들에 대한 변경을 허용하지 않습니다.

AI Gateway의 Helm 차트 배포의 경우:

1. 사용자 지정 루트 CA 인증서를 로컬 파일에 추가합니다:

   ```shell
   cat customCA-root.crt >> ca-certificates.crt
   ```

1. AI Gateway 컨테이너에서 `/etc/ssl/certs/ca-certificates.crt` 번들 파일을 로컬 파일로 복사합니다:

   ```shell
   kubectl cp -n gitlab ai-gateway-55d697ff9d-j9pc6:/etc/ssl/certs/ca-certificates.crt ca-certificates.crt.
   ```

1. 로컬 파일에서 새 시크릿을 생성합니다:

   ```shell
   kubectl create secret generic ca-certificates -n gitlab --from-file=cacertificates.crt=ca-certificates.crt
   ```

1. 시크릿을 채팅 `values.yml`에서 사용하여 `volume` 및 `volumeMount`을 정의합니다. 이렇게 하면 컨테이너에 `/tmp/ca-certificates.crt` 파일이 생성됩니다:

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

1. `REQUESTS_CA_BUNDLE` 및 `SSL_CERT_FILE` 환경 변수를 설정하여 마운트된 파일을 가리킵니다:

   ```shell
   extraEnvironmentVariables:
     - name: REQUESTS_CA_BUNDLE
       value: /tmp/ca-certificates.crt
     - name: SSL_CERT_FILE
       value: /tmp/ca-certificates.crt
   ```

1. 차트를 다시 배포합니다.

[Issue 3](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/issues/3)이 Helm 차트에서 이를 기본적으로 지원하기 위해 존재합니다.

#### Docker 배포의 경우 {#for-a-docker-deployment}

Docker 배포의 경우 동일한 방법을 사용합니다. 유일한 차이점은 로컬 파일을 컨테이너에 마운트하기 위해 `--volume /root/ca-certificates.crt:/tmp/ca-certificates.crt`을 사용한다는 것입니다.

## AI Gateway Docker 이미지 업그레이드 {#upgrade-the-ai-gateway-docker-image}

AI Gateway를 업그레이드하려면 최신 Docker 이미지 태그를 다운로드합니다.

1. 실행 중인 컨테이너를 중지합니다:

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. 기존 컨테이너를 제거합니다:

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. 새 이미지를 가져와 [실행](#start-a-container-from-the-image)합니다.
1. 환경 변수가 모두 올바르게 설정되어 있는지 확인합니다.

## 보안 업데이트 및 이미지 검증 {#security-updates-and-image-verification}

최신 보안 패치를 실행 중인지 확인하려면 배포 방법에 따라 다음 지침을 따릅니다.

### Kubernetes 또는 Helm 배포의 경우 {#for-kubernetes-or-helm-deployments}

[차트 버전](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages) 0.7.0 이전 및 Kubernetes는 기본적으로 `imagePullPolicy: IfNotPresent`를 사용하며 태그가 변경되지 않은 경우 업데이트된 이미지를 가져오지 않습니다. 이는 동일한 버전 태그로 릴리스된 보안 패치를 놓칠 수 있습니다.

이미지 다이제스트를 사용하는 다음 방식을 사용해야 합니다:

```shell
# Find the image digest from the container registry
# Use this digest in your Helm install/upgrade command

helm upgrade --install ai-gateway \
  ai-gateway/ai-gateway \
  --set="image.tag=self-hosted-v18.2.1-ee@sha256:abc123..." \
  # ... other flags
```

또는 다음 방식 중 하나로 `imagePullPolicy`을 사용할 수 있습니다:

- `imagePullPolicy`을 항상으로 설정합니다:

  ```shell
  helm upgrade --install ai-gateway \
    ai-gateway/ai-gateway \
    --set="image.pullPolicy=Always" \
    # ... other flags
  ```

- `pullPolicy`을 `values.yaml`에 추가합니다:

  ```yaml
  image:
    pullPolicy: Always
  ```

업데이트 가져오기를 강제하려면:

```shell
kubectl rollout restart deployment/ai-gateway -n ai-gateway
```

### Docker 배포의 경우 {#for-docker-deployments}

업그레이드할 때 최신 이미지를 가져오고 있는지 확인합니다:

```shell
# Check current image digest
docker images --digests | grep ai-assist

# Pull latest version explicitly
docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>

# Verify digest changed
docker images --digests | grep ai-assist
```

변경 불가능한 배포를 위해 이미지 다이제스트를 사용하려면:

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

## 대체 설치 방법 {#alternative-installation-methods}

AI Gateway를 설치하는 대체 방법에 대한 정보는 [이슈 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773)을 참조합니다.

## 상태 확인 및 디버깅 {#health-check-and-debugging}

GitLab Duo 자체 호스팅 설치의 이슈를 디버깅하려면 다음 명령을 실행합니다:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

다음을 확인합니다:

- AI Gateway URL이 올바르게 구성되었습니다(`Ai::Setting.instance.ai_gateway_url` 통해).
- GitLab Duo 액세스가 `/admin/code_suggestions`을 통해 루트 사용자에 대해 명시적으로 활성화되었습니다.

액세스 이슈가 지속되면 인증이 올바르게 구성되어 있고 상태 확인이 통과하는지 확인합니다.

이슈가 지속되는 경우 오류 메시지에서 `AIGW_AUTH__BYPASS_EXTERNAL=true`로 인증을 우회할 수 있지만 이슈 해결에만 이를 수행합니다.

[상태 확인](../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo)을 실행할 수도 있습니다. 이를 수행하려면 **운영자** > **GitLab Duo**로 이동합니다.

이 테스트는 오프라인 환경에서 수행됩니다:

| 테스트 | 설명 |
|-----------------|-------------|
| 네트워크 | 다음을 테스트합니다: <br>\- AI Gateway URL이 `ai_settings` 테이블을 통해 데이터베이스에서 올바르게 구성되었습니다.<br> \- 인스턴스가 구성된 URL에 연결할 수 있습니다.<br><br>인스턴스가 URL에 연결할 수 없으면 방화벽 또는 프록시 서버 설정이 [연결을 허용](../administration/gitlab_duo/configure/_index.md)하는지 확인합니다. 환경 변수 `AI_GATEWAY_URL`는 이전 호환성을 위해 여전히 지원되지만 더 나은 관리 가능성을 위해 데이터베이스를 통해 URL을 구성하는 것이 좋습니다. |
| 라이선스 | 라이선스에 Code Suggestions 기능에 액세스할 수 있는 기능이 있는지 테스트합니다. |
| 시스템 교환 | Code Suggestions을 인스턴스에서 사용할 수 있는지 테스트합니다. 시스템 교환 평가에 실패하면 사용자가 인스턴스에서 GitLab Duo 기능을 사용하지 못할 수 있습니다. |

## AI Gateway 모니터링 {#monitor-the-ai-gateway}

Prometheus를 사용하여 AI Gateway 사용량 및 성능에 대한 메트릭을 수집합니다.

### AI Gateway의 Prometheus 메트릭 설정 {#set-up-prometheus-metrics-for-the-ai-gateway}

Prometheus 메트릭을 설정하려면:

1. 필수 환경 변수를 설정하고 포트 `8082`을 엽니다:

   ```shell
   -e AIGW_FASTAPI__METRICS_HOST=0.0.0.0
   -e AIGW_FASTAPI__METRICS_PORT=8082
   ```

### GitLab Duo Workflow 서비스를 위한 Prometheus 설정 {#set-up-prometheus-for-the-gitlab-duo-workflow-service}

GitLab Duo Workflow 서비스에서 Prometheus 메트릭을 설정하려면:

1. 필수 환경 변수를 설정하고 포트 `8083`을 엽니다:

   ```shell
   -e PROMETHEUS_METRICS__ADDR=0.0.0.0
   -e PROMETHEUS_METRICS__PORT=8083
   ```

1. `gitlab-ai-gateway` 컨테이너에서 메트릭 포트를 호스트에 노출합니다:

   - Docker CLI의 경우:

     ```shell
     -p 8082:8082 \
     -p 8083:8083 \
     ```

   - Docker Compose의 경우 `gitlab-ai-gateway` 서비스에 추가합니다:

     ```shell
     ports:
       - "8082:8082"
       - "8083:8083"
     ```

   이렇게 하면 AI Gateway 메트릭 엔드포인트가 포트 `8082`에 노출되고 GitLab Duo Workflow 서비스 메트릭 엔드포인트가 포트 `8083`에 노출됩니다.

1. AI Gateway 컨테이너를 다시 시작합니다.

### 메트릭을 스크랩하도록 Prometheus 구성 {#configure-prometheus-to-scrape-metrics}

AI Gateway 및 GitLab Duo Workflow 서비스에서 메트릭을 수집하려면 다음 `prometheus.yml` 구성을 Prometheus 인스턴스에 추가합니다. 이 구성에서 Prometheus는 매 15초마다 두 서비스에서 메트릭을 스크랩합니다.

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

### 메트릭 수집 확인 {#verify-metrics-collection}

AI Gateway 및 GitLab Duo Workflow 서비스의 대상을 수집하고 있는지 확인하려면:

1. Prometheus UI에서 **상태 > Targets**으로 이동합니다.
1. **경고** 또는 **그래프** 탭으로 이동하여 메트릭을 쿼리합니다. AI Gateway 및 GitLab Duo Workflow 서비스는 다음 엔드포인트에서 메트릭을 노출합니다:

   - AI Gateway: `http://<your_AIGW_domain>:8082/metrics`
   - GitLab Duo Workflow 서비스: `http://<your_duo_agent_platform_service_domain>:8083/metrics`

## AI Gateway가 자동 크기 조정이 필요한가요? {#does-the-ai-gateway-need-to-autoscale}

자동 크기 조정은 필수가 아니지만 가변 워크로드, 높은 동시성 요구 사항 또는 예측 불가능한 사용량 패턴이 있는 환경에 권장됩니다. GitLab 프로덕션 환경에서:

- 기본 설정: 2개의 CPU 코어와 8GB RAM이 있는 단일 AI Gateway 인스턴스는 약 40개의 동시 요청을 처리할 수 있습니다.
- 크기 조정 지침: AWS t3.2xlarge 인스턴스(8vCPU, 32GB RAM) 같은 더 큰 설정의 경우 게이트웨이는 기본 설정의 4배에 해당하는 최대 160개의 동시 요청을 처리할 수 있습니다.
- 요청 처리량: GitLab.com의 관찰된 사용량에 따르면 활성 사용자 1000명당 7RPS(초당 요청 수)가 계획을 위한 합리적인 지표입니다.
- 자동 크기 조정 옵션: Kubernetes Horizontal Pod Autoscaler(HPA) 또는 유사한 메커니즘을 사용하여 CPU, 메모리 사용률 또는 요청 지연 시간 임계값 같은 메트릭을 기반으로 인스턴스 수를 동적으로 조정합니다.

## 배포 크기별 구성 예 {#configuration-examples-by-deployment-size}

- 소형 배포:
  - 2개의 vCPU와 8GB RAM이 있는 단일 인스턴스입니다.
  - 최대 40개의 동시 요청을 처리합니다.
  - 최대 50명의 사용자와 예측 가능한 워크로드가 있는 팀 또는 조직입니다.
  - 고정 인스턴스로 충분할 수 있습니다. 비용 효율성을 위해 자동 크기 조정을 비활성화할 수 있습니다.
- 중형 배포:
  - 8개의 vCPU와 32GB RAM이 있는 단일 AWS t3.2xlarge 인스턴스입니다.
  - 최대 160개의 동시 요청을 처리합니다.
  - 50~200명의 사용자와 중간 정도의 동시성 요구 사항이 있는 조직입니다.
  - 50% CPU 사용률 또는 500ms 이상의 요청 지연 시간에 대한 임계값이 있는 Kubernetes HPA를 구현합니다.
- 대형 배포:
  - 여러 AWS t3.2xlarge 인스턴스 또는 동등한 클러스터입니다.
  - 각 인스턴스는 160개의 동시 요청을 처리하며 여러 인스턴스가 있는 수천 명의 사용자로 확장됩니다.
  - 200명 이상의 사용자와 가변적이고 높은 동시성 워크로드가 있는 엔터프라이즈입니다.
  - HPA를 사용하여 실시간 수요에 따라 Pod를 확장하고 클러스터 전체 리소스 조정을 위해 노드 자동 크기 조정과 결합합니다.

## AI Gateway 컨테이너 사양 및 리소스 할당 {#ai-gateway-container-specs-and-resource-allocation}

AI Gateway는 다음 리소스 할당에서 효과적으로 작동합니다:

- 컨테이너당 2개의 CPU 코어와 8GB의 RAM입니다.
- 컨테이너는 일반적으로 GitLab 프로덕션 환경에서 약 7.39% CPU 및 비례하는 메모리를 사용하며 성장 또는 버스트 활동 처리를 위한 여유를 남깁니다.

## 리소스 경합을 위한 완화 전략 {#mitigation-strategies-for-resource-contention}

- Kubernetes 리소스 요청 및 제한을 사용하여 AI Gateway 컨테이너가 보장된 CPU 및 메모리 할당을 받도록 합니다. 예를 들어:

  ```yaml
  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "32Gi"
      cpu: "8"
  ```

- Prometheus 및 Grafana 같은 도구를 구현하여 리소스 사용률(CPU, 메모리, 지연 시간)을 추적하고 병목 현상을 조기에 감지합니다.
- 노드 또는 인스턴스를 AI Gateway에만 전용으로 사용하여 다른 서비스와의 리소스 경합을 방지합니다.

## 크기 조정 전략 {#scaling-strategies}

- Kubernetes HPA를 사용하여 다음과 같은 실시간 메트릭을 기반으로 Pod를 확장합니다:
  - 평균 CPU 사용률이 50%를 초과합니다.
  - 요청 지연 시간이 일관되게 500ms 이상입니다.
  - Pod가 증가할 때 인프라 리소스를 동적으로 확장하도록 노드 자동 크기 조정을 활성화합니다.

## 크기 조정 권장사항 {#scaling-recommendations}

| 배포 크기 | 인스턴스 유형      | 리소스             | 용량(동시 요청) | 크기 조정 권장사항                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| 소형            | 2개의 vCPU, 8GB RAM | 단일 인스턴스        | 40                              | 고정 배포; 자동 크기 조정 없음.           |
| 중간           | AWS t3.2xlarge    | 단일 인스턴스     | 160                             | CPU 또는 지연 시간 임계값을 기반으로 한 HPA입니다.     |
| 대형            | 여러 t3.2xlarge | 클러스터된 인스턴스   | 인스턴스당 160               | 높은 수요를 위한 HPA + 노드 자동 크기 조정.     |

## 여러 GitLab 인스턴스 지원 {#support-multiple-gitlab-instances}

단일 AI Gateway를 배포하여 여러 GitLab 인스턴스를 지원하거나 인스턴스 또는 지역별로 별도의 AI Gateway를 배포할 수 있습니다. 적절한 선택을 결정하는 데 도움이 되도록 다음을 고려합니다:

- 청구 가능한 사용자 1000명당 약 7초당 요청의 예상 트래픽입니다.
- 모든 인스턴스에 걸친 총 동시 요청을 기반으로 한 리소스 요구 사항입니다.
- 각 GitLab 인스턴스에 대한 최고 관행 인증 구성입니다.

## AI Gateway 및 인스턴스의 위치 배치 {#co-locate-your-ai-gateway-and-instance}

AI Gateway는 다음을 통해 위치에 관계없이 사용자를 위한 최적의 성능을 보장하도록 전 세계 여러 지역에서 사용할 수 있습니다:

- GitLab Duo 기능의 응답 시간이 개선됩니다.
- 지리적으로 분산된 사용자의 지연 시간이 감소합니다.
- 데이터 주권 요구 사항 준수입니다.

AI Gateway를 GitLab 인스턴스와 동일한 지리적 영역에 배치하여 특히 Code Suggestions 같은 지연 시간에 민감한 기능에 대한 마찰 없는 개발자 환경을 제공하는 것이 좋습니다.

## 문제 해결 {#troubleshooting}

AI Gateway로 작업할 때 다음 이슈가 발생할 수 있습니다.

### OpenShift 권한 이슈 {#openshift-permission-issues}

OpenShift에서 AI Gateway를 배포할 때 OpenShift 보안 모델로 인해 권한 오류가 발생할 수 있습니다.

#### `/tmp`에서 읽기 전용 파일 시스템 {#read-only-filesystem-at-tmp}

AI Gateway는 `/tmp`에 쓰기 작업을 수행해야 합니다. 그러나 보안이 제한된 OpenShift 환경을 기반으로 `/tmp`은 읽기 전용일 수 있습니다.

이 이슈를 해결하려면 새 `EmptyDir` 볼륨을 생성하고 `/tmp`에 마운트합니다. 다음 방법 중 하나로 이를 수행할 수 있습니다:

- 명령줄에서:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- `values.yaml`에 추가됨:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

#### HuggingFace 모델 {#huggingface-models}

기본적으로 AI Gateway는 `/home/aigateway/.hf`을 사용하여 HuggingFace 모델을 캐시합니다. 이는 OpenShift의 보안 제한 환경에서 쓰기 가능하지 않을 수 있습니다. 이로 인해 다음과 같은 권한 오류가 발생할 수 있습니다:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

이를 해결하려면 `HF_HOME` 환경 변수를 쓰기 가능한 위치로 설정합니다. `/var/tmp/huggingface` 또는 컨테이너에서 쓰기 가능한 다른 디렉터리를 사용할 수 있습니다.

다음 방법 중 하나로 이를 구성할 수 있습니다:

- `values.yaml`에 추가합니다:

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- 또는 Helm 업그레이드 명령에 포함합니다:

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

이 구성은 AI Gateway가 OpenShift 보안 제약 조건을 준수하면서 HuggingFace 모델을 올바르게 캐시할 수 있도록 합니다. 선택하는 정확한 디렉터리는 특정 OpenShift 구성 및 보안 정책에 따라 다를 수 있습니다.

### 볼륨 마운트로 인해 Tokenizer 캐시가 가려짐 {#tokenizer-cache-shadowed-by-a-volume-mount}

AI Gateway 이미지의 사전 캐시된 Tokenizer 파일은 다음의 경우 볼륨 마운트로 인해 가려질 수 있습니다:

- 코드 완성 요청이 `500` 오류를 반환합니다.
- AI Gateway 로그는 `huggingface.co`에서 `Salesforce/codegen2-16B`를 다운로드하려고 시도하는 `transformers/utils/hub.py`에서 발생한 `OSError`를 표시합니다.

자체 호스팅 AI Gateway 이미지(`self-hosted-vX.Y.Z-ee`)는 `HF_HUB_OFFLINE=true`를 설정하고 빌드 시간에 Tokenizer를 사전 캐시하므로 런타임에 `huggingface.co`에 대한 네트워크 액세스가 발생하지 않아야 합니다. 네트워크 액세스가 발생하면 Helm 값의 빈 디렉터리가 `/home/aigateway/.hf`에 마운트되어 캐시된 파일을 덮어쓸 수 있습니다.

`huggingface.co`에 이그레스 액세스를 부여하여 이 이슈를 해결하려고 시도하지 마세요. 대신 이슈를 진단하려면 AI Gateway Pod에서 다음을 실행합니다:

```shell
ls -la /home/aigateway/.hf/hub/ 2>/dev/null || echo "NO_CACHE_DIR"
env | grep -E '^(HF_|TRANSFORMERS_)'
```

캐시 디렉터리가 없거나 비어 있으면 다음을 수행합니다:

1. `values.yaml`에서 `/home/aigateway/.hf` 또는 `HF_HOME`로 설정된 경로를 대상으로 하는 `volumeMounts`을 확인합니다.
1. 이미지의 기본 제공 캐시와 겹치지 않는 디렉터리로 마운트를 제거하거나 다시 매핑합니다.

### 자체 서명 인증서 오류 {#self-signed-certificate-error}

`[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain` 오류는 AI Gateway가 사용자 지정 인증 기관(CA)에 의해 서명된 인증서 또는 자체 서명 인증서를 사용하여 GitLab 인스턴스 또는 모델 엔드포인트에 연결하려고 할 때 AI Gateway에 의해 기록됩니다.

이를 해결하려면 [자체 서명 SSL 인증서를 사용하여 GitLab 인스턴스 또는 모델 엔드포인트에 연결](#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate)을 참조합니다.

### 토큰 생성 실패 {#token-creation-failed}

Duo Chat 같은 기능을 사용할 때 `Token creation failed` 오류가 발생하면 `AIGW_SELF_SIGNED_JWT__SIGNING_KEY` 및 `AIGW_SELF_SIGNED_JWT__VALIDATION_KEY` 환경 변수가 AI Gateway에서 설정되지 않았을 수 있습니다.

이 키는 AI Gateway가 단기 사용자 JWT를 발급하기 위해 필요합니다. 이 키가 없으면 AI Gateway가 토큰에 서명할 수 없으며 JWK 역직렬화 실패가 발생합니다.

이 이슈를 해결하려면:

1. 필수 키를 생성합니다:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   ```

1. 환경 변수로 전달하여 AI Gateway 컨테이너에 키를 추가합니다:

   ```shell
   -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
   -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)"
   ```

1. AI Gateway 컨테이너를 다시 시작합니다.

### PEM 파일 로드 시 SSL 인증서 오류 {#ssl-certificate-errors-when-loading-pem-files}

Docker 컨테이너로 PEM 파일을 로드할 때 `JWKError`이라는 오류가 발생하면 SSL 인증서 오류를 해결해야 할 수 있습니다.

이 이슈를 해결하려면 다음 환경 변수를 사용하여 Docker 컨테이너에서 적절한 인증서 번들 경로를 설정합니다:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

`/path/to/ca-bundle.pem`을 인증서 번들의 경로로 바꿉니다.
