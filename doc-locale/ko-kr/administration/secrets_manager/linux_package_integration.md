---
stage: Sec
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab의 Linux 패키지 배포를 위해 OpenBao 설치하기
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9669)되었습니다(베타).

{{< /history >}}

Kubernetes 클러스터를 사용하여 Linux 패키지로 설치된 GitLab 인스턴스와 함께 OpenBao를 실행합니다. OpenBao는 클러스터에서 실행되고 PostgreSQL 데이터베이스에 연결됩니다. GitLab Rails와 Sidekiq는 HTTPS를 통해 OpenBao에 연결합니다.

OpenBao를 두 가지 방식으로 실행할 수 있습니다:

- **Colocated cluster**:  로컬 Kubernetes 배포(예: k3s)가 Linux 패키지 인스턴스와 같은 호스트에서 실행됩니다. Linux 패키지 번들 NGINX는 OpenBao 외부 URL에 대한 TLS 종료 리버스 프록시 역할을 합니다. GitLab 애플리케이션은 Kubernetes가 공유 네트워크에 노출하는 엔드포인트를 통해 OpenBao에 연결합니다.
- **External Kubernetes cluster**:  OpenBao는 별도의 Kubernetes 클러스터에서 실행됩니다. 클러스터 Ingress와 TLS 종료를 설계합니다. GitLab Rails와 Sidekiq는 노출된 OpenBao URL에 연결합니다. 다중 노드 Linux 패키지 배포가 있거나 클라우드 공급자의 관리형 Kubernetes 서비스를 사용하려는 경우 이 방식을 고려하세요.

> [!note]
> Linux 패키지 관리 [PostgreSQL 클러스터](../postgresql/replication_and_failover.md)는 OpenBao 데이터베이스 백엔드로 지원되지 않습니다. GitLab에 이러한 클러스터를 사용하는 경우 OpenBao용 별도의 PostgreSQL 인스턴스를 프로비저닝하세요. 자체 관리형이거나 관리형 클라우드 데이터베이스 서비스일 수 있습니다. 자세한 내용은 [이슈 7292](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/7292)를 참조하세요.

## 전제 조건 {#prerequisites}

{{< tabs >}}

{{< tab title="같은 위치의 클러스터" >}}

- Linux 패키지로 설치된 GitLab 19.0 이상(관리자 액세스 포함).
- 같은 호스트에 설치된 로컬 Kubernetes 배포.
- `helm`과 `kubectl`이 호스트에서 사용 가능합니다.
- OpenBao 도메인을 호스트의 공개 IP 주소로 가리키는 DNS 레코드.

{{< /tab >}}

{{< tab title="외부 클러스터" >}}

- Linux 패키지로 설치된 GitLab 인스턴스(관리자 액세스 포함).
- Linux 패키지 인스턴스 노드에서 액세스 가능한 외부 Kubernetes 클러스터.
- `helm`과 `kubectl`이 클러스터에 액세스하도록 구성되었습니다.
- OpenBao 도메인을 클러스터 Ingress IP 주소로 가리키는 DNS 레코드.

{{< /tab >}}

{{< /tabs >}}

## 요구 사항 {#requirements}

{{< tabs >}}

{{< tab title="같은 위치의 클러스터" >}}

OpenBao를 설치하기 전에 Kubernetes 배포가 다음 요구 사항을 충족하는지 확인하세요:

- [OpenBao 크기 조정 권장 사항](_index.md#sizing-recommendations)은 Linux 패키지 인스턴스의 요구 사항과 Kubernetes 클러스터의 요구 사항 외에도 충족되어야 합니다.
- 같은 위치의 Kubernetes의 아무것도 GitLab에서 이미 사용 중인 포트에 연결하려고 시도하지 않아야 합니다. 많은 소규모 Kubernetes 배포는 기본적으로 포트 80과 443에 바인딩되는 로드 밸런서를 설치합니다. Linux 패키지 관리 NGINX가 이미 해당 포트에서 수신 대기 중이므로 이러한 구성 요소를 비활성화하세요.
- 같은 위치의 Kubernetes는 Linux 패키지 인스턴스와 네트워크를 공유해야 하므로 Linux 패키지 관리 NGINX가 외부 OpenBao 트래픽을 OpenBao 서비스로 라우팅하고 해당 서비스의 요청을 수신할 수 있습니다. Linux 패키지 인스턴스는 서비스가 Kubernetes `LoadBalancer` 또는 `NodePort`를 통해 노출되는지 관계없이, 공유 네트워크 내에서 둘 다 도달 가능한 한 신경 쓰지 않습니다.

{{< /tab >}}

{{< tab title="외부 클러스터" >}}

OpenBao를 설치하기 전에 설정이 다음 요구 사항을 충족하는지 확인하세요:

- [OpenBao 크기 조정 권장 사항](_index.md#sizing-recommendations)은 Kubernetes 클러스터에 의해 충족되어야 합니다.
- 클러스터의 OpenBao 포드와 Linux 패키지 인스턴스 노드 간에 네트워크 연결이 존재해야 합니다. 이 연결을 설정하는 방법은 인프라에 따라 다릅니다. 예를 들어 VPC 피어링, 공유 VPC 또는 방화벽 규칙을 사용할 수 있습니다. GitLab Rails와 Sidekiq는 클러스터에서 노출된 OpenBao URL에 도달할 수 있어야 합니다.
- OpenBao 데이터베이스로 Linux 패키지 관리 PostgreSQL을 사용하는 경우 PostgreSQL 노드는 클러스터 포드 CIDR에서 TCP 연결을 수락해야 합니다. 방화벽 또는 보안 그룹 규칙을 구성하여 데이터베이스 포트에서 이 트래픽을 허용하세요.

{{< /tab >}}

{{< /tabs >}}

## 시작하기 전에 {#before-you-begin}

{{< tabs >}}

{{< tab title="같은 위치의 클러스터" >}}

시작하기 전에:

1. Kubernetes CNI(포드 네트워크)의 CIDR을 수집합니다. 나중에 PostgreSQL 인증을 구성하는 데 필요합니다.
1. Linux 패키지 인스턴스와 Kubernetes 간에 공유되는 네트워크 인터페이스의 IP 주소(`<SHARED_NETWORK_IP>`)를 수집합니다. 나중에 여러 구성 값에 필요합니다.
1. OpenBao를 설치하기 전에 Kubernetes 배포가 완전히 실행 중인지 확인하세요.
1. `kubectl` 컨텍스트가 이 클러스터로 설정되어 있는지 확인하세요(`KUBECONFIG`이 올바르게 구성됨).

{{< /tab >}}

{{< tab title="외부 클러스터" >}}

시작하기 전에:

1. Kubernetes 포드 네트워크의 CIDR을 수집합니다. 나중에 PostgreSQL 인증을 구성하는 데 필요합니다.
1. OpenBao가 사용하는 PostgreSQL 인스턴스의 주소(`<POSTGRES_ADDRESS>`)를 수집합니다. 이는 Linux 패키지 PostgreSQL 노드의 IP 주소이거나 외부 또는 관리형 PostgreSQL 인스턴스의 엔드포인트입니다.
1. OpenBao를 설치하기 전에 Kubernetes 클러스터가 완전히 실행 중인지 확인하세요.
1. `kubectl` 컨텍스트가 이 클러스터로 설정되어 있는지 확인하세요(`KUBECONFIG`이 올바르게 구성됨).

{{< /tab >}}

{{< /tabs >}}

## OpenBao PostgreSQL 데이터베이스 프로비저닝 {#provision-the-openbao-postgresql-database}

> [!note]
> `gitlab-psql`는 Linux 패키지 관리 PostgreSQL을 사용할 때만 사용 가능합니다. 대신 외부 또는 관리형 PostgreSQL 인스턴스를 사용하는 경우 해당 인스턴스에서 동일한 SQL 명령을 실행합니다. 사용자 및 데이터베이스 생성 논리는 동일합니다.

`gitlab-psql`은 Unix 소켓을 통해 연결되고 TCP 수신기가 필요하지 않으므로 `gitlab-ctl reconfigure` 전에 이 명령을 실행할 수 있습니다.

OpenBao PostgreSQL 데이터베이스를 프로비저닝하려면:

1. OpenBao 데이터베이스 사용자를 위한 강력한 암호를 선택합니다. 이 섹션의 마지막 단계에서 Kubernetes 시크릿에 같은 암호를 사용합니다.

1. OpenBao 데이터베이스 사용자를 생성합니다:

   ```shell
   sudo gitlab-psql \
     -c "CREATE USER openbao WITH PASSWORD '<strong-password>';"
   ```

1. OpenBao 데이터베이스를 생성합니다:

   ```shell
   sudo gitlab-psql \
     -c "CREATE DATABASE openbao OWNER openbao;"
   ```

1. Kubernetes 네임스페이스와 데이터베이스 암호를 Helm 차트에 전달하는 시크릿을 생성합니다:

   ```shell
   kubectl create namespace openbao

   kubectl create secret generic openbao-db-secret \
     --namespace openbao \
     --from-literal=password='<strong-password>'
   ```

## Helm을 사용하여 OpenBao 설치 {#install-openbao-by-using-helm}

{{< tabs >}}

{{< tab title="같은 위치의 클러스터" >}}

Helm을 사용하여 OpenBao를 설치하려면:

1. GitLab Helm 리포지토리를 추가합니다:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. `openbao-values.yaml` 파일을 생성하고 다음 내용으로 자리 표시자 값을 실제 도메인과 IP 주소로 바꿉니다:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<SHARED_NETWORK_IP>"
           port: 5432
           database: openbao
           username: openbao
           sslMode: "disable"
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   gatewayRoute:
     enabled: false
   ```

1. OpenBao를 설치합니다:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

   `--wait`을 사용하지 마세요. 포드가 PostgreSQL에 연결할 수 없기 때문입니다. PostgreSQL은 `gitlab-ctl reconfigure` 이후 포드 네트워크에서만 TCP 연결을 수락합니다. 현재 포드는 `CrashLoopBackOff` 상태입니다.

   사용 가능한 모든 차트 옵션은 [OpenBao Helm 차트 설명서](https://docs.gitlab.com/charts/charts/openbao/)를 참조하세요.

1. OpenBao 서비스에 사용할 내부 URL을 정의합니다. 여러 옵션이 있습니다:

   - 로드 밸런서. 같은 위치의 Kubernetes 클러스터에서 내부 로드 밸런서를 사용하는 경우 `oak['components']['openbao']['internal_url']` 설정을 `gitlab.rb` 파일로 설정하여 로드 밸런서의 내부 URL로 요청을 OpenBao Kubernetes 서비스로 라우팅할 수 있습니다. 이 경우 내부 URL이 내부 로드 밸런서 IP로 확인되도록 DNS를 구성해야 합니다.
   - 클러스터 `nodePort`. OpenBao 차트 서비스를 Kubernetes 서비스 유형 `nodePort`에서 실행하도록 사용자 지정하면 내부 URL도 해당 값으로 구성할 수 있습니다.
   - 서비스 `clusterIP`. 이 옵션이 가장 간단할 것 같습니다. OpenBao 내부 URL을 OpenBao 서비스 `clusterIP`와 직접 통신하도록 알려서 같은 위치의 클러스터에 대한 로드 밸런서를 완전히 건너뛸 수도 있습니다. 이 옵션은 Linux 패키지 관리 NGINX가 이미 있기 때문에 머신에 로드 밸런서를 하나 더 설치할 필요가 없습니다.

   다음을 실행하여 OpenBao 서비스의 `clusterIP`을 찾을 수 있습니다:

   ```shell
   kubectl -n openbao get svc openbao-active \
     -o jsonpath='{.spec.clusterIP}'
   ```

   내부 URL의 IP는 Kubernetes 클러스터 외부의 호스트 머신에서 액세스할 수 있어야 합니다. 클러스터를 구성하여 선택한 `<SHARED_NETWORK_IP>`에서 IP를 할당하세요.

{{< /tab >}}

{{< tab title="외부 클러스터" >}}

Helm을 사용하여 OpenBao를 설치하려면:

1. GitLab Helm 리포지토리를 추가합니다:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. `openbao-values.yaml` 파일을 생성하고 다음 내용으로 자리 표시자 값을 실제 도메인과 PostgreSQL 주소로 바꿉니다:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<POSTGRES_ADDRESS>"
           port: 5432
           database: openbao
           username: openbao
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   # The chart deploys a Kubernetes Ingress resource by default, which you need to provide the hostname to be reachable for GitLab Rails and Sidekiq
   # Alternatively, you could configure it to deploy an HTTPRoute resource, if you prefer to deploy a Gateway API controller.
   #
   # For available network ingress and TLS configuration options, see:
   # https://docs.gitlab.com/charts/charts/openbao/#ingress-and-tls-configuration-options
   ingress:
     enabled: true
     hostname: "<OPENBAO_DOMAIN>"
   ```

1. OpenBao를 설치합니다:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

사용 가능한 모든 차트 옵션은 [OpenBao Helm 차트 설명서](https://docs.gitlab.com/charts/charts/openbao/)를 참조하세요.

{{< /tab >}}

{{< /tabs >}}

## GitLab 구성 {#configure-gitlab}

{{< tabs >}}

{{< tab title="같은 위치의 클러스터" >}}

GitLab 호스트의 `/etc/gitlab/gitlab.rb`에 다음을 추가하고 자리 표시자 값을 실제 IP 주소와 도메인으로 바꿉니다:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
# Use the shared network IP to restrict exposure to the shared network.
# Using '0.0.0.0' makes PostgreSQL listen on all interfaces, including public ones.
postgresql['listen_address'] = '<SHARED_NETWORK_IP>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.42.0.0/16 with the CIDR of your Kubernetes CNI (pod network).
postgresql['md5_auth_cidr_addresses'] = %w[10.42.0.0/16]

# OAK: OpenBao reverse proxy via GitLab NGINX.
oak['enable'] = true
oak['network_address'] = '<SHARED_NETWORK_IP>'

oak['components']['openbao']['enable'] = true

# Replace 'https://openbao.example.com' with the URL of the DNS record
# you configured for OpenBao, which resolves to your host's public IP address.
oak['components']['openbao']['external_url'] = 'https://openbao.example.com'

# Example of service clusterIP. Replace <CLUSTER_IP> with the IP taken
# from the previous step.
#
# A nodePort would look similar: specify the cluster node IP with the port
# you chose when you deployed OpenBao.
#
# If behind a load balancer: 'http://openbao-internal.example.com'
oak['components']['openbao']['internal_url'] = 'http://<CLUSTER_IP>:8200'

# The URL that the GitLab application uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

이 구성에서:

- `postgresql['listen_address']`은 공유 네트워크 IP입니다. `trust_auth_cidr_addresses` 또는 `md5_auth_cidr_addresses`에 나열되지 않은 CIDR의 연결은 PostgreSQL에서 거부됩니다.
- `postgresql['trust_auth_cidr_addresses']`은 CIDR 블록(localhost만) 목록입니다. 이 블록의 연결은 암호가 필요하지 않습니다. 이 주소는 GitLab 서비스에서 사용합니다.
- `postgresql['md5_auth_cidr_addresses']`은 포드 CIDR의 CIDR 블록 목록입니다. 이 블록의 연결은 암호가 필요합니다. 이 주소는 OpenBao 포드에서 사용합니다. 암호 인증. OpenBao 포드에서 사용합니다.
- `oak['network_address']`은 공유 네트워크 IP입니다. NGINX 수신 대기 지시문에서 사용합니다.
- `oak['components']['openbao']['internal_url']`은 GitLab 애플리케이션이 OpenBao와 통신하는 데 사용하는 URL입니다.
- `gitlab_rails['openbao']['url']`은 GitLab 애플리케이션에서 사용하는 OpenBao URL입니다.

GitLab `external_url` 설정이 `https://`를 사용하면 Let's Encrypt가 이미 활성화됩니다. OpenBao `external_url` 스키마를 `https://`로 설정하는 것으로 충분합니다. GitLab은 자동으로 기존 Let's Encrypt 인증서에 OpenBao 도메인을 주체 대체 이름(SAN)으로 추가합니다.

대신 사용자 지정 인증서를 사용하려면 다음을 추가합니다:

```ruby
oak['components']['openbao']['ssl_certificate']     = '/etc/gitlab/ssl/openbao.example.com.crt'
oak['components']['openbao']['ssl_certificate_key'] = '/etc/gitlab/ssl/openbao.example.com.key'
```

{{< /tab >}}

{{< tab title="외부 클러스터" >}}

각 GitLab 애플리케이션 노드의 `/etc/gitlab/gitlab.rb`에 다음을 추가하고 자리 표시자 값을 실제 주소와 도메인으로 바꿉니다:

```ruby
# The URL GitLab Rails uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

별도의 Sidekiq 노드가 있는 경우 각 Sidekiq 노드의 `/etc/gitlab/gitlab.rb`에 동일한 `gitlab_rails['openbao']` 설정을 추가합니다. 시크릿을 프로비저닝하는 Sidekiq 워커도 OpenBao에 대한 액세스가 필요합니다.

OpenBao 데이터베이스로 Linux 패키지 관리 PostgreSQL을 사용하는 경우 PostgreSQL 노드의 `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
postgresql['listen_address'] = '<POSTGRES_ADDRESS>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.0.0.0/14 with the CIDR of your Kubernetes pod network.
postgresql['md5_auth_cidr_addresses'] = %w[10.0.0.0/14]
```

{{< /tab >}}

{{< /tabs >}}

## 구성 변경 적용 {#apply-configuration-changes}

{{< tabs >}}

{{< tab title="같은 위치의 클러스터" >}}

구성 변경을 적용합니다:

```shell
sudo gitlab-ctl reconfigure
```

이 명령은 단일 패스에서 모든 구성을 적용합니다:

- PostgreSQL은 Kubernetes 포드에서 TCP 연결을 수락하기 시작합니다.
- NGINX는 OpenBao 가상 호스트(TLS 종료 및 HTTP에서 HTTPS 리디렉션 포함)로 구성됩니다.
- Let's Encrypt 인증서가 발급되거나 해당하는 경우 갱신됩니다.

{{< /tab >}}

{{< tab title="외부 클러스터" >}}

`gitlab.rb`을 업데이트한 각 노드에서 구성 변경을 적용합니다:

```shell
sudo gitlab-ctl reconfigure
```

PostgreSQL 노드에서 이렇게 하면 PostgreSQL이 클러스터 포드 네트워크에서 TCP 연결을 수락합니다. Rails 및 Sidekiq 노드에서 이는 OpenBao URL 구성을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

## OpenBao가 준비될 때까지 기다리기 {#wait-for-openbao-to-become-ready}

롤아웃이 완료될 때까지 기다립니다:

```shell
kubectl -n openbao rollout status deployment openbao
```

같은 위치의 클러스터의 경우 이전에 `CrashLoopBackOff` 상태였던 포드는 `gitlab-ctl reconfigure`가 완료된 후 정상이 됩니다.

## 설치 확인 {#verify-the-installation}

설치를 확인하려면:

1. OpenBao에 도달할 수 있는지 확인합니다:

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

   성공적인 응답은 다음과 같습니다:

   ```json
   {
     "initialized": true,
     "sealed": false,
     "standby": false,
     "version": "2.0.0"
   }
   ```

1. [GitLab Secrets Manager 활성화](../../ci/secrets/secrets_manager/_index.md#enable-for-a-group-or-project).
