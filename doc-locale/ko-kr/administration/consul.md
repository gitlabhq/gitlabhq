---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Consul 설정 방법
description: Consul 클러스터를 구성합니다.
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Consul 클러스터는 [서버 및 클라이언트 에이전트](https://developer.hashicorp.com/consul/docs/agent)로 구성됩니다. 서버는 자신의 노드에서 실행되고 클라이언트는 다른 노드에서 실행되며 서버와 통신합니다.

GitLab Premium에는 번들로 제공되는 [Consul](https://www.consul.io/)(서비스 네트워킹 솔루션)이 포함되어 있으며, `/etc/gitlab/gitlab.rb`를 사용하여 관리할 수 있습니다.

## 전제 조건 {#prerequisites}

Consul을 구성하기 전에:

1. [참조 아키텍처](reference_architectures/_index.md#available-reference-architectures) 문서를 검토하여 필요한 Consul 서버 노드 수를 결정합니다.
1. 필요한 경우 방화벽에서 [적절한 포트가 열려](package_information/defaults.md#ports) 있는지 확인합니다.

## Consul 노드 구성 {#configure-the-consul-nodes}

각 Consul 서버 노드에서:

1. [GitLab 설치](https://about.gitlab.com/install/) 지침을 따르되, 물어볼 때 `EXTERNAL_URL` 값을 제공하지 마세요.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `retry_join` 섹션에 표시된 값을 바꾸면서 다음을 추가합니다. 아래 예제에는 세 개의 노드가 있으며, 두 개는 IP로 표시되고 하나는 FQDN으로 표시되어 있습니다. 어느 표기법이든 사용할 수 있습니다:

   ```ruby
   # Disable all components except Consul
   roles ['consul_role']

   # Consul nodes: can be FQDN or IP, separated by a whitespace
   consul['configuration'] = {
     server: true,
     retry_join: %w(10.10.10.1 consul1.gitlab.example.com 10.10.10.2)
   }

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [GitLab 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.
1. Consul이 올바르게 구성되었는지 확인하고 모든 서버 노드가 통신하는지 확인하려면 다음 명령을 실행합니다:

   ```shell
   sudo /opt/gitlab/embedded/bin/consul members
   ```

   출력은 다음과 유사해야 합니다:

   ```plaintext
   Node                 Address               Status  Type    Build  Protocol  DC
   CONSUL_NODE_ONE      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_TWO      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_THREE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   ```

   결과에 `alive`이(가) 아닌 상태의 노드가 표시되거나 세 개의 노드 중 하나라도 누락되면 [문제 해결 섹션](#troubleshooting-consul)을 참조합니다.

## Consul 노드 보안 {#securing-the-consul-nodes}

Consul 노드 간 통신을 보호하는 방법은 두 가지이며, TLS 또는 Gossip 암호화를 사용할 수 있습니다.

### TLS 암호화 {#tls-encryption}

기본적으로 TLS는 Consul 클러스터에 대해 활성화되어 있지 않으며, 기본 구성 옵션 및 해당 기본값은 다음과 같습니다:

```ruby
consul['use_tls'] = false
consul['tls_ca_file'] = nil
consul['tls_certificate_file'] = nil
consul['tls_key_file'] = nil
consul['tls_verify_client'] = nil
```

이러한 구성 옵션은 클라이언트 및 서버 노드 모두에 적용됩니다.

Consul 노드에서 TLS를 활성화하려면 `consul['use_tls'] = true`부터 시작합니다. 노드의 역할(서버 또는 클라이언트)과 TLS 기본 설정에 따라 추가 구성을 제공해야 합니다:

- 서버 노드에서는 최소한 `tls_ca_file`, `tls_certificate_file`, `tls_key_file`을(를) 지정해야 합니다.
- 클라이언트 노드에서 서버의 클라이언트 TLS 인증이 비활성화되어 있는 경우(기본적으로 활성화됨) 최소한 `tls_ca_file`을(를) 지정해야 하며, 그렇지 않으면 `tls_certificate_file`, `tls_key_file`을(를) 사용하여 클라이언트 TLS 인증서 및 키를 전달해야 합니다.

TLS가 활성화되면 기본적으로 서버는 mTLS를 사용하고 HTTPS 및 HTTP(그리고 TLS 및 비TLS RPC)를 모두 수신합니다. 클라이언트가 TLS 인증을 사용하도록 합니다. `consul['tls_verify_client'] = false`을(를) 설정하여 클라이언트 TLS 인증을 비활성화할 수 있습니다.

반면에 클라이언트는 서버 노드로의 나가는 연결에만 TLS를 사용하고 들어오는 요청에 대해 HTTP(및 비TLS RPC)만 수신합니다. `consul['https_port']`을(를) 음이 아닌 정수로 설정하여 클라이언트 Consul 에이전트가 들어오는 연결에 TLS를 사용하도록 적용할 수 있습니다(`8501`는 Consul의 기본 HTTPS 포트임). 이것이 작동하려면 `tls_certificate_file`과(와) `tls_key_file`도 전달해야 합니다. 서버 노드가 클라이언트 TLS 인증을 사용할 때 클라이언트 TLS 인증서 및 키는 TLS 인증 및 들어오는 HTTPS 연결 모두에 사용됩니다.

Consul 클라이언트 노드는 기본적으로 TLS 클라이언트 인증을 사용하지 않으며(서버와 달리) `consul['tls_verify_client'] = true`을(를) 설정하여 명시적으로 지시해야 합니다.

다음은 TLS 암호화의 몇 가지 예제입니다.

#### 최소 TLS 지원 {#minimal-tls-support}

다음 예제에서 서버는 들어오는 연결에 TLS를 사용합니다(클라이언트 TLS 인증 없음).

{{< tabs >}}

{{< tab title="Consul 서버 노드" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   consul['tls_verify_client'] = false
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Consul 클라이언트 노드" >}}

다음은 Patroni 노드에서 구성할 수 있습니다(예).

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Patroni는 들어오는 연결에 TLS를 사용하지 않는 로컬 Consul 에이전트와 통신합니다. 따라서 `patroni['consul']['url']`의 HTTP URL입니다.

{{< /tab >}}

{{< /tabs >}}

#### 기본 TLS 지원 {#default-tls-support}

다음 예제에서 서버는 상호 TLS 인증을 사용합니다.

{{< tabs >}}

{{< tab title="Consul 서버 노드" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Consul 클라이언트 노드" >}}

다음은 Patroni 노드에서 구성할 수 있습니다(예).

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Patroni는 들어오는 연결에 TLS를 사용하지 않지만 Consul 서버 노드에 TLS 인증을 사용하는 로컬 Consul 에이전트와 통신합니다. 따라서 `patroni['consul']['url']`의 HTTP URL입니다.

{{< /tab >}}

{{< /tabs >}}

#### 전체 TLS 지원 {#full-tls-support}

다음 예제에서 클라이언트와 서버 모두 상호 TLS 인증을 사용합니다.

상호 TLS 인증이 작동하려면 Consul 서버, 클라이언트 및 Patroni 클라이언트 인증서가 동일한 CA에서 발급되어야 합니다.

{{< tabs >}}

{{< tab title="Consul 서버 노드" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Consul 클라이언트 노드" >}}

다음은 Patroni 노드에서 구성할 수 있습니다(예).

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_verify_client'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   consul['https_port'] = 8501

   patroni['consul']['url'] = 'https://localhost:8501'
   patroni['consul']['cacert'] = '/path/to/ca.crt.pem'
   patroni['consul']['cert'] = '/opt/tls/patroni.crt.pem'
   patroni['consul']['key'] = '/opt/tls/patroni.key.pem'
   patroni['consul']['verify'] = true
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< /tabs >}}

### Gossip 암호화 {#gossip-encryption}

Gossip 프로토콜을 암호화하여 Consul 에이전트 간의 통신을 보호할 수 있습니다. 기본적으로 암호화는 활성화되어 있지 않으며, 암호화를 활성화하려면 공유 암호화 키가 필요합니다. 편의상 `gitlab-ctl consul keygen` 명령을 사용하여 키를 생성할 수 있습니다. 키는 32바이트 길이이며 Base 64로 인코딩되고 모든 에이전트에서 공유됩니다.

다음 옵션은 클라이언트 및 서버 노드 모두에서 작동합니다.

Gossip 프로토콜을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   consul['encryption_key'] = <base-64-key>
   consul['encryption_verify_incoming'] = true
   consul['encryption_verify_outgoing'] = true
   ```

1. GitLab 재구성:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

[기존 데이터 센터에서 암호화 활성화](https://developer.hashicorp.com/consul/docs/security/encryption#enable-on-an-existing-consul-datacenter)하려면 롤링 업데이트를 위해 이러한 옵션을 수동으로 설정합니다.

## Consul 노드 업그레이드 {#upgrade-the-consul-nodes}

Consul 노드를 업그레이드하려면 GitLab 패키지를 업그레이드합니다.

노드는 다음을 충족해야 합니다:

- Linux 패키지를 업그레이드하기 전에 정상 클러스터의 멤버여야 합니다.
- 한 번에 하나의 노드씩 업그레이드됩니다.

각 노드에서 다음 명령을 실행하여 클러스터의 기존 상태 문제를 식별합니다. 클러스터가 정상이면 명령은 빈 배열을 반환합니다:

```shell
curl "http://127.0.0.1:8500/v1/health/state/critical"
```

Consul 버전이 변경된 경우 `gitlab-ctl reconfigure`의 끝에 알림이 표시되어 새 버전을 사용하려면 Consul을 다시 시작해야 함을 알립니다.

Consul을 한 번에 하나의 노드씩 다시 시작합니다:

```shell
sudo gitlab-ctl restart consul
```

Consul 노드는 Raft 프로토콜을 사용하여 통신합니다. 현재 리더가 오프라인 상태가 되면 리더 선택이 있어야 합니다. 리더 노드가 클러스터 전체에서 동기화를 용이하게 하기 위해 존재해야 합니다. 너무 많은 노드가 동시에 오프라인 상태가 되면 클러스터가 쿼럼을 잃고 [합의 단절](https://developer.hashicorp.com/consul/docs/architecture/consensus) 때문에 리더를 선택하지 않습니다.

업그레이드 후 클러스터가 복구되지 않으면 [문제 해결 섹션](#troubleshooting-consul)을 참조합니다. [중단 복구](#outage-recovery)가 특별히 관심이 있을 수 있습니다.

GitLab은 Consul을 사용하여 쉽게 재생성할 수 있는 일시적 데이터만 저장합니다. 번들 Consul이 GitLab 자체 이외의 다른 프로세스에서 사용되지 않은 경우 [클러스터를 처음부터 재구축](#recreate-from-scratch)할 수 있습니다.

## Consul 문제 해결 {#troubleshooting-consul}

다음은 문제를 디버깅할 때 수행해야 할 몇 가지 작업입니다. 다음을 실행하여 오류 로그를 볼 수 있습니다:

```shell
sudo gitlab-ctl tail consul
```

### 클러스터 멤버십 확인 {#check-the-cluster-membership}

클러스터의 멤버 중 하나에서 다음을 실행하여 클러스터의 일부인 노드를 확인합니다:

```shell
sudo /opt/gitlab/embedded/bin/consul members
```

출력은 다음과 유사해야 합니다:

```plaintext
Node            Address               Status  Type    Build  Protocol  DC
consul-b        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
db-a            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
db-b            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
```

이상적으로 모든 노드의 `Status`이(가) `alive`여야 합니다.

### Consul 다시 시작 {#restart-consul}

Consul을 다시 시작해야 하는 경우 쿼럼을 유지하기 위해 제어된 방식으로 이를 수행하는 것이 중요합니다. 쿼럼이 손실되면 클러스터를 복구하기 위해 Consul [중단 복구](#outage-recovery) 프로세스를 따릅니다.

안전을 위해 클러스터가 손상되지 않도록 한 번에 하나의 노드에서만 Consul을 다시 시작하는 것이 좋습니다. 더 큰 클러스터의 경우 한 번에 여러 노드를 다시 시작할 수 있습니다. [Consul 합의 문서](https://developer.hashicorp.com/consul/docs/architecture/consensus#deployment-table)를 참조하여 허용할 수 있는 장애 수를 확인합니다. 이것은 지속할 수 있는 동시 재시작의 수입니다.

Consul을 다시 시작하려면:

```shell
sudo gitlab-ctl restart consul
```

### 통신할 수 없는 Consul 노드 {#consul-nodes-unable-to-communicate}

기본적으로 Consul은 [바인드](https://developer.hashicorp.com/consul/docs/agent/config/config-files#bind_addr)를 `0.0.0.0`로 시도하지만, 다른 Consul 노드가 통신할 수 있도록 노드의 첫 번째 개인 IP 주소를 알립니다. 다른 노드가 이 주소의 노드와 통신할 수 없으면 클러스터의 상태가 실패합니다.

이 문제가 발생하면 `gitlab-ctl tail consul`에 다음과 같은 메시지가 출력됩니다:

```plaintext
2017-09-25_19:53:39.90821     2017/09/25 19:53:39 [WARN] raft: no known peers, aborting election
2017-09-25_19:53:41.74356     2017/09/25 19:53:41 [ERR] agent: failed to sync remote state: No cluster leader
```

이를 해결하려면:

1. 다른 모든 노드가 이 노드에 도달할 수 있는 각 노드의 주소를 선택합니다.
1. `/etc/gitlab/gitlab.rb` 업데이트

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. GitLab 재구성;

   ```shell
   gitlab-ctl reconfigure
   ```

여전히 오류가 표시되면 영향을 받은 노드에서 [Consul 데이터베이스를 지우고 다시 초기화](#recreate-from-scratch)해야 할 수 있습니다.

### Consul이 시작되지 않음 - 여러 개인 IP {#consul-does-not-start---multiple-private-ips}

노드에 여러 개인 IP가 있으면 Consul은 알릴 개인 주소를 알 수 없으므로 시작할 때 즉시 종료됩니다.

다음과 같은 메시지가 `gitlab-ctl tail consul`에 출력됩니다:

```plaintext
2017-11-09_17:41:45.52876 ==> Starting Consul agent...
2017-11-09_17:41:45.53057 ==> Error creating agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
```

이를 해결하려면:

1. 다른 모든 노드가 이 노드에 도달할 수 있는 노드의 주소를 선택합니다.
1. `/etc/gitlab/gitlab.rb` 업데이트

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. GitLab 재구성;

   ```shell
   gitlab-ctl reconfigure
   ```

### 중단 복구 {#outage-recovery}

쿼럼을 깨뜨릴 수 있을 만큼 충분한 Consul 노드를 손실한 경우 클러스터는 실패한 것으로 간주되며 수동 개입 없이는 작동할 수 없습니다. 이 경우 처음부터 노드를 다시 만들거나 복구를 시도할 수 있습니다.

#### 처음부터 다시 생성 {#recreate-from-scratch}

기본적으로 GitLab은 재생성할 수 없는 것을 Consul 노드에 저장하지 않습니다. Consul 데이터베이스를 지우고 다시 초기화하려면:

```shell
sudo gitlab-ctl stop consul
sudo rm -rf /var/opt/gitlab/consul/data
sudo gitlab-ctl start consul
```

이 후 노드가 다시 시작되고 나머지 서버 에이전트가 다시 조인됩니다. 그 후 곧 클라이언트 에이전트도 다시 조인됩니다.

조인하지 않으면 클라이언트에서 Consul 데이터를 지워야 할 수도 있습니다:

```shell
sudo rm -rf /var/opt/gitlab/consul/data
```

#### 실패한 노드 복구 {#recover-a-failed-node}

Consul을 활용하여 다른 데이터를 저장하고 실패한 노드를 복원하려면 [Consul 가이드](https://developer.hashicorp.com/consul/tutorials/operate-consul/recovery-outage)를 따라 실패한 클러스터를 복구합니다.
