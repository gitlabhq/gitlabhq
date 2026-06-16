---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 확장을 위한Redis 구성
description: 확장을 위해Redis를 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

인프라 설정 및 GitLab 설치 방법에 따라 리포지토리를 구성하는 여러 가지 방법이 있습니다.

직접 Redis와 Sentinel을 설치 및 관리하거나, 호스팅된 클라우드 솔루션을 사용하거나, Linux 패키지에 번들로 제공되는 것을 사용하여 구성에만 집중할 수 있습니다. 필요에 맞는 것을 선택하세요.

## Redis 대신 Valkey 사용 {#use-valkey-instead-of-redis}

{{< history >}}

- GitLab 18.9에서 [베타](../../policy/development_stages_support.md#beta) 로 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)되었습니다.
- GitLab 19.0에서 [정식 버전(GA)으로 출시됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839).

{{< /history >}}

[Valkey](https://valkey.io/)는 Redis와 완벽하게 호환되는 오픈 소스 고성능 키/값 데이터 저장소입니다. GitLab은 Valkey를 Redis의 대안으로 지원합니다.

Valkey는 활성화되면 기본적으로 Redis와 동일한 사용자, 그룹, 데이터 디렉터리 및 로그 디렉터리 규칙을 사용합니다.

Redis 노드에서 Valkey로 전환하려면 `/etc/gitlab/gitlab.rb`에 다음을 추가하세요:

```ruby
redis['backend'] = 'valkey'
```

### 알려진 이슈 {#known-issues}

- 알려진 [이슈 589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642) 때문에 Admin Area는 Valkey 버전을 잘못 보고합니다. 이 이슈는 설치된 Valkey 버전이나 작동 방식에 영향을 미치지 않습니다.

## Linux 패키지를 사용한Redis 복제 및 페일오버 {#redis-replication-and-failover-using-the-linux-package}

이 설정은 [Linux **Enterprise Edition** (EE) 패키지](https://about.gitlab.com/install/?version=ee)를 사용하여 GitLab을 설치한 경우입니다.

Redis와 Sentinel은 패키지에 번들로 포함되어 있으므로 전체Redis 인프라(주 서버, 복제본 및 sentinel)를 설정하는 데 사용할 수 있습니다.

자세한 내용은 [Linux 패키지를 사용한Redis 복제 및 페일오버](replication_and_failover.md)를 참조하세요.

### TLS를 사용한 Redis 및 Sentinel 보안 {#secure-redis-and-sentinel-with-tls}

TLS(전송 계층 보안)를 사용하여Redis와 Sentinel 통신을 보호합니다. 표준 TLS 및 상호 TLS(mTLS) 활성화에 대한 자세한 지침은 [Redis및 Sentinel을 TLS로 보호](tls.md)를 참조하세요.

## 번들되지 않은Redis를 사용한Redis 복제 및 페일오버 {#redis-replication-and-failover-using-the-non-bundled-redis}

[Linux 패키지](https://about.gitlab.com/install/) 설치이거나 [직접 컴파일된 설치](../../install/self_compiled/_index.md)이지만 자신의 외부Redis 및 Sentinel 서버를 사용하려는 경우에 해당하는 설정입니다.

자세한 내용은 [직접 인스턴스를 제공하는Redis 복제 및 페일오버](replication_and_failover_external.md)를 참조하세요.

## Linux 패키지를 사용하는 독립 실행형 Redis {#standalone-redis-using-the-linux-package}

번들로 제공되는Redis를 사용하기 위해 [Linux **Community Edition** (CE) 패키지](https://about.gitlab.com/install/?version=ce)를 설치한 경우에 해당하는 설정이므로 Redis 서비스만 활성화된 패키지를 사용할 수 있습니다.

자세한 내용은 [Linux 패키지를 사용한 독립 실행형Redis](standalone.md)를 참조하세요.
