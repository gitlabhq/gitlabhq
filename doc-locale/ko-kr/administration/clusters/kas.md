---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Relay(KAS) 설치
description: GitLab Relay(KAS)를 관리합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab Relay(KAS)는 GitLab과 함께 설치되는 구성 요소입니다. GitLab과 외부 시스템 간의 양방향 gRPC 통신을 위한 중앙 통신 중계 역할을 합니다. 다음이 포함됩니다:

- 러너:  [Job Router](../../ci/runners/job_router/_index.md) 및 [Runner Controllers](../../ci/runners/job_router/runner_controllers.md)를 사용하는 데 필요합니다.
- Kubernetes 클러스터:  [Agent for Kubernetes](../../user/clusters/agent/_index.md)를 사용하는 데 필요합니다.

KAS는 이전에 Kubernetes Agent Server로 알려졌습니다. 이름은 Kubernetes를 넘어선 진화된 역할을 반영하기 위해 변경되었습니다.

GitLab Relay(KAS)는 GitLab.com에서 `wss://kas.gitlab.com`에서 설치되어 사용 가능합니다. GitLab Self-Managed를 사용하는 경우 기본적으로 GitLab Relay(KAS)가 설치되어 사용 가능합니다.

## 설치 옵션 {#installation-options}

GitLab 관리자는 GitLab Relay(KAS) 설치를 제어할 수 있습니다:

- [Linux 패키지 설치](#for-linux-package-installations)의 경우입니다.
- [GitLab Helm 차트 설치](#for-gitlab-helm-chart)의 경우입니다.

### Linux 패키지 설치 {#for-linux-package-installations}

Linux 패키지 설치용 GitLab Relay(KAS)는 단일 노드 또는 여러 노드에서 동시에 활성화할 수 있습니다. 기본적으로 GitLab Relay(KAS)는 활성화되어 `ws://gitlab.example.com/-/kubernetes-agent/`에서 사용 가능합니다.

#### 단일 노드에서 비활성화 {#disable-on-a-single-node}

단일 노드에서 GitLab Relay(KAS)를 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_kas['enable'] = false
   ```

1. [GitLab 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

#### 여러 노드에서 KAS 활성화 {#turn-on-kas-on-multiple-nodes}

KAS 인스턴스는 Redis의 잘 알려진 위치에 프라이빗 주소를 등록하여 서로 통신합니다. 각 KAS는 프라이빗 주소 세부 정보를 제시하도록 구성되어야 다른 인스턴스에서 도달할 수 있습니다.

여러 노드에서 KAS를 활성화하려면:

1. [공통 구성](#common-configuration)을 추가합니다.
1. 다음 옵션 중 하나에서 구성을 추가합니다:

   - [옵션 1 - 명시적 수동 구성](#option-1---explicit-manual-configuration)
   - [옵션 2 - 자동 CIDR 기반 구성](#option-2---automatic-cidr-based-configuration)
   - [옵션 3 - 수신기 구성 기반 자동 구성](#option-3---automatic-configuration-based-on-listener-configuration)

1. [GitLab 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. (선택 사항) GitLab Rails 및 Sidekiq 노드를 분리한 다중 서버 환경을 사용하는 경우 Sidekiq 노드에서 KAS를 활성화합니다.

##### 공통 구성 {#common-configuration}

각 KAS 노드에서 `/etc/gitlab/gitlab.rb`의 파일을 편집하고 다음 구성을 추가합니다:

```ruby
gitlab_kas_external_url 'wss://kas.gitlab.example.com/'

gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'

# private_api_listen_address examples, pick one:

gitlab_kas['private_api_listen_address'] = 'A.B.C.D:8155' # Listen on a particular IPv4. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = '[A:B:C::D]:8155' # Listen on a particular IPv6. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = 'kas-N.gitlab.example.com:8155' # Listen on all IPv4 and IPv6 interfaces that the DNS name resolves to. Each node must use its own unique domain.
# gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces.
# gitlab_kas['private_api_listen_address'] = '0.0.0.0:8155' # Listen on all IPv4 interfaces.
# gitlab_kas['private_api_listen_address'] = '[::]:8155' # Listen on all IPv6 interfaces.

# Uncomment below to enable KAS to KAS TLS communication
# gitlab_kas['private_api_certificate_file'] = '<path_to_kas_server_crt_file>'
# gitlab_kas['private_api_key_file'] = '<path_to_kas_server_certificate_key>'

gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_HOST' => '<server-name-from-cert>' # Add if you want to use TLS for KAS->KAS communication. This name is used to verify the TLS certificate host name instead of the host in the URL of the destination KAS.
  'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/",
}

gitlab_rails['gitlab_kas_external_url'] = 'wss://gitlab.example.com/-/kubernetes-agent/'
gitlab_rails['gitlab_kas_internal_url'] = 'grpc://kas.internal.gitlab.example.com'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
```

**Do not**: `private_api_listen_address`를 프라이빗 주소에서 수신하도록 설정합니다:

- `localhost`
- `127.0.0.1` 또는 `::1`와 같은 루프백 IP 주소
- UNIX 소켓

다른 KAS 노드는 이러한 주소에 도달할 수 없습니다.

단일 노드 구성의 경우 `private_api_listen_address`를 프라이빗 주소에서 수신하도록 설정할 수 있습니다.

##### 옵션 1 - 명시적 수동 구성 {#option-1---explicit-manual-configuration}

각 KAS 노드에서 `/etc/gitlab/gitlab.rb`의 파일을 편집하고 `OWN_PRIVATE_API_URL` 환경 변수를 명시적으로 설정합니다:

```ruby
gitlab_kas['env'] = {
  # OWN_PRIVATE_API_URL examples, pick one. Each node must use its own unique IP or DNS name.
  # Use grpcs:// when using TLS on the private API endpoint.

  'OWN_PRIVATE_API_URL' => 'grpc://A.B.C.D:8155' # IPv4
  # 'OWN_PRIVATE_API_URL' => 'grpcs://A.B.C.D:8155' # IPv4 + TLS
  # 'OWN_PRIVATE_API_URL' => 'grpc://[A:B:C::D]:8155' # IPv6
  # 'OWN_PRIVATE_API_URL' => 'grpc://kas-N-private-api.gitlab.example.com:8155' # DNS name
}
```

##### 옵션 2 - 자동 CIDR 기반 구성 {#option-2---automatic-cidr-based-configuration}

{{< history >}}

- GitLab 16.5.0에서 [도입](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464)되었습니다.
- GitLab 17.8.1에서 `OWN_PRIVATE_API_CIDR`에 [여러 CIDR 지원 추가](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2183)되었습니다.

{{< /history >}}

예를 들어 KAS 호스트에 IP 주소 및 호스트 이름이 동적으로 할당되는 경우 `OWN_PRIVATE_API_URL` 변수에서 정확한 IP 주소 또는 호스트 이름을 설정할 수 없을 수 있습니다.

정확한 IP 주소 또는 호스트 이름을 설정할 수 없는 경우 `OWN_PRIVATE_API_CIDR`을 구성하여 KAS가 하나 이상의 [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)에 따라 `OWN_PRIVATE_API_URL`을 동적으로 구성하도록 설정할 수 있습니다:

이 방법을 사용하면 각 KAS 노드가 CIDR이 변경되지 않는 한 작동하는 정적 구성을 사용할 수 있습니다.

각 KAS 노드에서 `/etc/gitlab/gitlab.rb`의 파일을 편집하여 `OWN_PRIVATE_API_URL` URL을 동적으로 구성합니다:

1. 공통 구성에서 `OWN_PRIVATE_API_URL`을 주석으로 처리하여 이 변수를 비활성화합니다.
1. `OWN_PRIVATE_API_CIDR`을 구성하여 KAS 노드가 수신하는 네트워크를 지정합니다. KAS를 시작하면 지정된 CIDR과 일치하는 호스트 주소를 선택하여 사용할 프라이빗 IP 주소를 결정합니다.
1. `OWN_PRIVATE_API_PORT`을 구성하여 다른 포트를 사용합니다. 기본적으로 KAS는 `private_api_listen_address` 매개변수의 포트를 사용합니다.
1. 프라이빗 API 엔드포인트에서 TLS를 사용하는 경우 `OWN_PRIVATE_API_SCHEME=grpcs`을 구성합니다. 기본적으로 KAS는 `grpc` 스키마를 사용합니다.

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8', # IPv4 example
  # 'OWN_PRIVATE_API_CIDR' => '2001:db8:8a2e:370::7334/64', # IPv6 example
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8,2001:db8:8a2e:370::7334/64', # multiple CIRDs example

  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### 옵션 3 - 수신기 구성 기반 자동 구성 {#option-3---automatic-configuration-based-on-listener-configuration}

{{< history >}}

- GitLab 16.5.0에서 [도입](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464)되었습니다.
- [업데이트됨](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/510) KAS를 모든 루프백이 아닌 IP 주소에서 수신하고 게시하며, `private_api_listen_network`의 값을 기반으로 IPv4 및 IPv6 주소를 필터링합니다.

{{< /history >}}

KAS 노드는 `private_api_listen_network` 및 `private_api_listen_address` 설정을 기반으로 사용 가능한 IP 주소를 결정할 수 있습니다:

- `private_api_listen_address`이 고정 IP 주소 및 포트 번호(예: `ip:port`)로 설정된 경우 이 IP 주소를 사용합니다.
- `private_api_listen_address`에 IP 주소(예: `:8155`)가 없거나 지정되지 않은 IP 주소(예: `[::]:8155` 또는 `0.0.0.0:8155`)가 있는 경우 KAS는 모든 루프백이 아닌 링크-로컬이 아닌 IP 주소를 노드에 할당합니다. IPv4 및 IPv6 주소는 `private_api_listen_network`의 값을 기반으로 필터링됩니다.
- `private_api_listen_address`이 `hostname:PORT`(예: `kas-N-private-api.gitlab.example.com:8155`)인 경우 KAS는 DNS 이름을 확인하고 모든 IP 주소를 노드에 할당합니다. 이 모드에서는 KAS가 첫 번째 IP 주소에서만 수신합니다(이 동작은 [Go 표준 라이브러리](https://pkg.go.dev/net#Listen)에 의해 정의됩니다). IPv4 및 IPv6 주소는 `private_api_listen_network`의 값을 기반으로 필터링됩니다.

KAS의 프라이빗 API 주소를 모든 IP 주소에 노출하기 전에 이 작업이 조직의 보안 정책과 충돌하지 않는지 확인합니다. 프라이빗 API 엔드포인트는 모든 요청에 대해 유효한 인증 토큰이 필요합니다.

각 KAS 노드에서 `/etc/gitlab/gitlab.rb`의 파일을 편집합니다:

예 1. 모든 IPv4 및 IPv6 인터페이스에서 수신합니다:

```ruby
# gitlab_kas['private_api_listen_network'] = 'tcp' # this is the default value, no need to set it.
gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces
```

예 2. 모든 IPv4 인터페이스에서 수신합니다:

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp4'
gitlab_kas['private_api_listen_address'] = ':8155'
```

예 3. 모든 IPv6 인터페이스에서 수신합니다:

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp6'
gitlab_kas['private_api_listen_address'] = ':8155'
```

환경 변수를 사용하여 `OWN_PRIVATE_API_URL`을 구성하는 스키마 및 포트를 재정의할 수 있습니다:

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### 여러 KAS 인스턴스가 있는 로드 밸런서 또는 리버스 프록시 사용 {#use-a-load-balancer-or-reverse-proxy-with-multiple-kas-instances}

> [!warning]
> KAS 앞에 로드 밸런서 또는 리버스 프록시를 배치할 때 내부 API 노출을 방지하기 위해 외부 및 내부 트래픽에 대한 별도의 엔드포인트를 구성합니다.

KAS는 다양한 포트에서 트래픽을 제공합니다:

- 포트 8150(`listen_address`):  에이전트 연결(WebSocket/gRPC)
- 포트 8153(`internal_api_listen_address`):  GitLab Rails API(gRPC)

  > [!warning]
  > 포트 8153을 공개적으로 노출하지 마세요. 포트가 인증되지만 GitLab Rails 인스턴스만 액세스할 수 있어야 합니다.

로드 밸런서 또는 리버스 프록시를 사용할 때 KAS를 보호하려면 두 개의 별도 엔드포인트를 구성합니다:

- 외부 엔드포인트:  포트 8150(에이전트용)
- 내부 엔드포인트:  포트 8153(GitLab Rails 전용, 네트워크 또는 방화벽으로 제한됨)

이 분리를 통해 내부 API는 공개 액세스로부터 격리된 상태로 유지됩니다.

예를 들어 NGINX에서 네트워크 제한이 있는 내부 엔드포인트를 구성합니다:

```nginx
# Internal endpoint (network-restricted)
server {
  listen 8443 ssl http2;
  server_name kas-internal.example.com;

  # Optional: allow 10.0.1.0/24; deny all;

  location /gitlab.agent. {
    grpc_pass grpc://kas-backend:8153;
  }
}
```

별도의 엔드포인트를 사용하도록 GitLab을 구성합니다(`/etc/gitlab/gitlab.rb`):

```ruby
gitlab_rails['gitlab_kas_external_url'] = 'wss://kas-external.example.com'
gitlab_rails['gitlab_kas_internal_url'] = 'grpcs://kas-internal.example.com:8443'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://kas-external.example.com/k8s-proxy/'
```

주요 구성 포인트:

- 내부 트래픽에 별도의 도메인, 포트 또는 IP 제한을 사용합니다.
- 클라우드 로드 밸런서의 경우 포트 8150 및 8153에 대해 별도의 대상 그룹을 구성합니다.

##### GitLab Relay(KAS) 노드 설정 {#gitlab-relay-kas-node-settings}

| 설정                                             | 설명 |
|-----------------------------------------------------|-------------|
| `gitlab_kas['private_api_listen_network']`          | KAS가 수신하는 네트워크 제품군입니다. 기본값은 IPv4 및 IPv6 네트워크 모두에 대해 `tcp`입니다. IPv4의 경우 `tcp4`, IPv6의 경우 `tcp6`로 설정합니다. |
| `gitlab_kas['private_api_listen_address']`          | KAS가 수신하는 주소입니다. `0.0.0.0:8155`로 설정하거나 클러스터의 다른 노드에서 도달 가능한 IP 및 포트로 설정합니다. |
| `gitlab_kas['api_secret_key']`                      | KAS와 GitLab 간의 인증에 사용되는 공유 암호입니다. 값은 Base64로 인코딩되어야 하며 정확히 32바이트 길이여야 합니다. |
| `gitlab_kas['private_api_secret_key']`              | 다른 KAS 인스턴스 간의 인증에 사용되는 공유 암호입니다. 값은 Base64로 인코딩되어야 하며 정확히 32바이트 길이여야 합니다. |
| `gitlab_kas['private_api_certificate_file']`        | KAS 서버 인증서 파일의 전체 경로입니다. `OWN_PRIVATE_API_SCHEME` 또는 `OWN_PRIVATE_API_URL`이 `grpcs`일 때 필요합니다. |
| `gitlab_kas['private_api_key_file']`                | KAS 서버 인증서 키 파일의 전체 경로입니다. `OWN_PRIVATE_API_SCHEME` 또는 `OWN_PRIVATE_API_URL`이 `grpcs`일 때 필요합니다. |
| `OWN_PRIVATE_API_SCHEME`                            | `OWN_PRIVATE_API_URL`을 구성할 때 사용할 스키마를 지정하는 데 사용되는 선택적 값입니다. `grpc` 또는 `grpcs`일 수 있습니다. |
| `OWN_PRIVATE_API_URL`                               | KAS가 서비스 검색에 사용하는 환경 변수입니다. 구성하는 노드의 호스트 이름 또는 IP 주소로 설정합니다. 노드는 클러스터의 다른 노드에서 도달 가능해야 합니다. |
| `OWN_PRIVATE_API_HOST`                              | TLS 인증서 호스트 이름을 확인하는 데 사용되는 선택적 값입니다. <sup>1</sup> 클라이언트는 이 값을 서버의 TLS 인증서 파일의 호스트 이름과 비교합니다. |
| `OWN_PRIVATE_API_PORT`                              | `OWN_PRIVATE_API_URL`을 구성할 때 사용할 포트를 지정하는 데 사용되는 선택적 값입니다. |
| `OWN_PRIVATE_API_CIDR`                              | `OWN_PRIVATE_API_URL`을 구성할 때 사용할 사용 가능한 네트워크의 IP 주소를 지정하는 데 사용되는 선택적 값입니다. |
| `gitlab_kas['client_timeout_seconds']`              | 클라이언트가 KAS에 연결하기 위한 시간 초과입니다. |
| `gitlab_kas_external_url`                           | 클러스터 내 `agentk`에 대한 사용자 대면 URL입니다. 정규화된 도메인 또는 하위 도메인<sup>2</sup> 또는 GitLab 외부 URL일 수 있습니다. <sup>3</sup> 비어 있으면 GitLab 외부 URL로 기본값이 설정됩니다. |
| `gitlab_rails['gitlab_kas_external_url']`           | 클러스터 내 `agentk`에 대한 사용자 대면 URL입니다. 비어 있으면 `gitlab_kas_external_url`로 기본값이 설정됩니다. |
| `gitlab_rails['gitlab_kas_external_k8s_proxy_url']` | Kubernetes API 프록싱을 위한 사용자 대면 URL입니다. 비어 있으면 `gitlab_kas_external_url`을 기반으로 한 URL로 기본값이 설정됩니다. |
| `gitlab_rails['gitlab_kas_internal_url']`           | GitLab 백엔드가 KAS와 통신하는 데 사용하는 내부 URL입니다. |

**각주**:

1. `OWN_PRIVATE_API_URL` 또는 `OWN_PRIVATE_API_SCHEME`이 `grpcs`로 시작할 때 아웃바운드 연결에 대해 TLS가 활성화됩니다.
1. 예를 들어, `wss://kas.gitlab.example.com/`.
1. 예를 들어, `wss://gitlab.example.com/-/kubernetes-agent/`.

#### 독립형 KAS 노드 구성 {#configure-a-standalone-kas-node}

Omnibus를 구성하여 KAS를 다른 구성 요소와 별도로 실행합니다.

각 Rails 노드에서:

```ruby
## KAS Config
gitlab_kas['enable'] = false

gitlab_rails['gitlab_kas_enabled'] = true
gitlab_rails['gitlab_kas_external_url'] = 'wss://kas.example.com/-/kubernetes-agent/'
gitlab_rails['gitlab_kas_internal_url'] = 'grpc://<KAS_NODE_IP_OR_DOMAIN>:8153' # If you want to configure multiple KAS nodes that are behind an internal LB, then use 'grpc://<LB_IP_OR_DOMAIN>:<port>'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://kas.example.com/-/kubernetes-agent/k8s-proxy/'
```

각 KAS 노드에서:

```ruby
### External URL
external_url 'https://kas.example.com'

### Avoid running unnecessary services ###
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = true
postgresql['enable'] = false
prometheus['enable'] = false
puma['enable'] = false
redis['enable'] = false
sidekiq['enable'] = false

### Prevent database connections during 'gitlab-ctl reconfigure' ###
gitlab_rails['rake_cache_clear'] = false
gitlab_rails['auto_migrate'] = false

gitlab_kas['redis_password'] = '<redis_password>'

# Uncomment below if using Redis high availability with Sentinel
# gitlab_kas['redis_sentinels'] = [
#  {host: '<REDIS_IP>', port: 26379},
#  {host: '<REDIS_IP>', port: 26379},
#  {host: '<REDIS_IP>', port: 26379},
# ]
# gitlab_kas['redis_sentinels_master_name'] = 'gitlab-redis'
# gitlab_kas['redis_sentinels_password'] = '<redis_sentinels_password>'

### GitLab Relay (KAS) ###
gitlab_kas['enable'] = true
gitlab_kas_external_url 'wss://kas.example.com/-/kubernetes-agent/'
gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8155'

gitlab_kas['listen_address'] = '<KAS_NODE_PRIVATE_IP>:8150'
gitlab_kas['observability_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8151'
gitlab_kas['internal_api_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8153'
gitlab_kas['kubernetes_api_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8154'

```

### GitLab Helm 차트의 경우 {#for-gitlab-helm-chart}

[GitLab-KAS 차트를 사용하는 방법](https://docs.gitlab.com/charts/charts/gitlab/kas/)을 확인합니다.

## Kubernetes API 프록시 쿠키 {#kubernetes-api-proxy-cookie}

{{< history >}}

- GitLab 15.10에서 `kas_user_access` 및 `kas_user_access_project` 이름의 [기능 플래그](../feature_flags/_index.md) 를 사용하여 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104504)되었습니다. 기본적으로 비활성화됨.
- 기능 플래그 `kas_user_access` 및 `kas_user_access_project`은 GitLab 16.1에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123479)되었습니다.
- 기능 플래그 `kas_user_access` 및 `kas_user_access_project`은 GitLab 16.2에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835)되었습니다.

{{< /history >}}

GitLab Relay(KAS)는 다음 중 하나를 사용하여 Kubernetes API 요청을 Kubernetes용 GitLab 에이전트로 프록시합니다:

- [CI/CD 작업](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md)입니다.
- [GitLab 사용자 자격 증명](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md)입니다.

사용자 자격 증명으로 인증하려면 Rails가 GitLab 프론트엔드에 대한 쿠키를 설정합니다. 이 쿠키는 `_gitlab_kas`라고 불리며 암호화된 세션 ID를 포함하며 [`_gitlab_session` 쿠키](../../user/profile/_index.md#cookies-used-for-sign-in)와 같습니다. `_gitlab_kas` 쿠키는 사용자를 인증하고 권한을 부여하기 위해 모든 요청과 함께 KAS 프록시 엔드포인트로 전송되어야 합니다.

## 수신 에이전트 활성화 {#enable-receptive-agents}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/12180)되었습니다.

{{< /history >}}

[수신 에이전트](../../user/clusters/agent/_index.md#receptive-agents)를 사용하면 GitLab이 GitLab 인스턴스에 대한 네트워크 연결을 설정할 수 없지만 GitLab에서 연결할 수 있는 Kubernetes 클러스터와 통합할 수 있습니다.

전제 조건:

- 운영자 액세스

수신 에이전트를 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **Kubernetes용 GitLab 에이전트**를 확장합니다.
1. **수신 모드 활성화** 토글을 켭니다.

## Kubernetes API 프록시 응답 헤더 허용 목록 구성 {#configure-kubernetes-api-proxy-response-header-allowlist}

{{< history >}}

- GitLab 18.3에서 `kas_k8s_api_proxy_response_header_allowlist` 이름의 [플래그](../feature_flags/_index.md) 를 사용하여 [도입](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/642)되었습니다. 기본적으로 비활성화됨.
- GitLab 18.7에서 [일반 공개](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/642)됩니다. 기능 플래그 `kas_k8s_api_proxy_response_header_allowlist` 제거됨.

{{< /history >}}

KAS의 Kubernetes API 프록시는 응답 헤더에 허용 목록을 사용합니다. 안전하고 잘 알려진 Kubernetes 및 HTTP 헤더는 기본적으로 허용됩니다.

허용된 응답 헤더 목록은 [응답 헤더 허용 목록](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/kubernetes_api/server/proxy_headers.go)을 참조하세요.

기본 허용 목록에 없는 응답 헤더가 필요한 경우 KAS 구성에 응답 헤더를 추가할 수 있습니다.

허용된 추가 응답 헤더를 추가하려면:

```yaml
agent:
  kubernetes_api:
    extra_allowed_response_headers:
      - 'X-My-Custom-Header-To-Allow'
```

더 많은 응답 헤더 추가에 대한 지원은 [이슈 550614](https://gitlab.com/gitlab-org/gitlab/-/issues/550614)에서 추적됩니다.

## 문제 해결 {#troubleshooting}

GitLab Relay(KAS)를 사용하는 동안 이슈가 발생하면 다음 명령을 실행하여 서비스 로그를 봅니다:

```shell
kubectl logs -f -l=app=kas -n <YOUR-GITLAB-NAMESPACE>
```

Linux 패키지 설치에서 `/var/log/gitlab/gitlab-kas/`의 로그를 찾습니다.

[개별 에이전트와의 이슈를 해결](../../user/clusters/agent/troubleshooting.md)할 수도 있습니다.

### 구성 파일을 찾을 수 없음 {#configuration-file-not-found}

다음 오류 메시지가 표시되면:

```plaintext
time="2020-10-29T04:44:14Z" level=warning msg="Config: failed to fetch" agent_id=2 error="configuration file not found: \".gitlab/agents/test-agent/config.yaml\
```

경로는 다음 중 하나에 대해 잘못되었습니다:

- 에이전트가 등록된 리포지토리입니다.
- 에이전트 구성 파일입니다.

이 이슈를 해결하려면 경로가 올바른지 확인합니다.

### 오류: `dial tcp <GITLAB_INTERNAL_IP>:443: connect: connection refused` {#error-dial-tcp-gitlab_internal_ip443-connect-connection-refused}

GitLab Self-Managed를 실행 중이고:

- 인스턴스가 SSL 종료 프록시 뒤에서 실행되지 않습니다.
- 인스턴스에 GitLab 인스턴스 자체에서 HTTPS가 구성되어 있지 않습니다.
- 인스턴스의 호스트 이름이 로컬로 프라이빗 IP 주소로 확인됩니다.

GitLab Relay(KAS)가 GitLab API에 연결하려고 하면 다음 오류가 발생할 수 있습니다:

```json
{"level":"error","time":"2021-08-16T14:56:47.289Z","msg":"GetAgentInfo()","correlation_id":"01FD7QE35RXXXX8R47WZFBAXTN","grpc_service":"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel","grpc_method":"Connect","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": dial tcp 172.17.0.4:443: connect: connection refused"}
```

Linux 패키지 설치의 경우 이 이슈를 해결하려면 `/etc/gitlab/gitlab.rb`에서 다음 매개변수를 설정합니다. `gitlab.example.com`을 GitLab 인스턴스의 호스트 이름으로 바꿉니다:

```ruby
gitlab_kas['gitlab_address'] = 'http://gitlab.example.com'
```

### 오류: `x509: certificate signed by unknown authority` {#error-x509-certificate-signed-by-unknown-authority}

GitLab URL에 도달하려고 할 때 이 오류가 발생하면 GitLab 인증서를 신뢰하지 않는다는 의미입니다.

GitLab 애플리케이션 서버의 KAS 로그에서 비슷한 오류를 볼 수 있습니다:

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

이 오류를 해결하려면 `/etc/gitlab/trusted-certs` 디렉토리에 내부 CA의 공개 인증서를 설치합니다.

또는 KAS를 구성하여 사용자 지정 디렉토리에서 인증서를 읽도록 할 수 있습니다. 이를 수행하려면 `/etc/gitlab/gitlab.rb`의 파일에 다음 구성을 추가합니다:

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

변경 사항을 적용하려면:

1. GitLab을 재구성합니다:

```shell
sudo gitlab-ctl reconfigure
```

1. GitLab Relay(KAS)를 다시 시작합니다:

```shell
gitlab-ctl restart gitlab-kas
```

### 오류: `GRPC::DeadlineExceeded in Clusters::Agents::NotifyGitPushWorker` {#error-grpcdeadlineexceeded-in-clustersagentsnotifygitpushworker}

이 오류는 클라이언트가 기본 시간 초과 기간(5초) 내에 응답을 받지 못할 때 발생할 가능성이 높습니다. 이슈를 해결하려면 `/etc/gitlab/gitlab.rb` 구성 파일을 수정하여 클라이언트 시간 초과를 증가시킬 수 있습니다.

#### 해결 단계 {#steps-to-resolve}

1. 시간 초과 값을 늘리도록 다음 구성을 추가하거나 업데이트합니다:

```ruby
gitlab_kas['client_timeout_seconds'] = "10"
```

1. GitLab을 재구성하여 변경 사항을 적용합니다:

```shell
gitlab-ctl reconfigure
```

#### 참고 {#note}

시간 초과 값을 특정 요구 사항에 맞게 조정할 수 있습니다. 이슈가 해결되었는지 확인하고 시스템 성능에 영향을 주지 않도록 테스트를 권장합니다.

### 오류: `Blocked Kubernetes API proxy response header` {#error-blocked-kubernetes-api-proxy-response-header}

Kubernetes 클러스터에서 Kubernetes API 프록시를 통해 사용자에게 전송될 때 HTTP 응답 헤더가 손실되면 KAS 로그 또는 Sentry 인스턴스에서 다음 오류를 확인합니다:

```plaintext
Blocked Kubernetes API proxy response header. Please configure extra allowed headers for your instance in the KAS config with `extra_allowed_response_headers` and have a look at the troubleshooting guide at https://docs.gitlab.com/administration/clusters/kas/#troubleshooting.
```

이 오류는 Kubernetes API 프록시가 응답 헤더 허용 목록에 정의되지 않았기 때문에 응답 헤더를 차단했다는 의미입니다.

응답 헤더 추가에 대한 자세한 내용은 [응답 헤더 허용 목록 구성](#configure-kubernetes-api-proxy-response-header-allowlist)을 참조하세요.

더 많은 응답 헤더 추가에 대한 지원은 [이슈 550614](https://gitlab.com/gitlab-org/gitlab/-/issues/550614)에서 추적됩니다.
