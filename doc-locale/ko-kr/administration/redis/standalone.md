---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Linux 패키지를 사용하여 독립 실행형 Redis 서버를 구성합니다. Redis 복제 또는 페일오버가 필요하지 않은 작은 GitLab 설치에 이 설정을 사용합니다.
title: Linux 패키지를 사용하는 독립 실행형 Redis
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Linux 패키지를 사용하여 독립 실행형 Redis 서버를 구성할 수 있습니다. 이 구성에서 Redis는 확장되지 않으며 단일 장애점을 나타냅니다. 그러나 확장된 환경에서는 환경이 더 많은 사용자를 처리하거나 처리량을 증가시킬 수 있도록 하는 것이 목표입니다. Redis 자체는 일반적으로 안정적이고 많은 요청을 처리할 수 있으므로 단일 인스턴스만 보유하는 것은 허용되는 절충안입니다. GitLab 확장 옵션에 대한 개요는 [참조 아키텍처](../reference_architectures/_index.md) 페이지를 참조하세요.

## 독립 실행형 Redis 인스턴스 설정 {#set-up-the-standalone-redis-instance}

아래 단계는 Linux 패키지로 Redis 서버를 구성하는 데 필요한 최소한의 단계입니다:

1. Redis 서버에 SSH로 연결합니다.
1. GitLab 다운로드 페이지에서 **steps 1 and 2**를 사용하여 원하는 Linux 패키지를 [다운로드하고 설치](https://about.gitlab.com/install/)합니다. 다운로드 페이지에서 다른 단계를 완료하지 마세요.

1. `/etc/gitlab/gitlab.rb`을 편집하고 내용을 추가합니다:

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   ## Only the primary GitLab application server should handle migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.
1. Redis 노드의 IP 주소 또는 호스트명, 포트 및 Redis 암호를 확인합니다. 이는 [GitLab 애플리케이션 서버를 구성](#set-up-the-gitlab-rails-application-instance)할 때 필요합니다.

[고급 구성 옵션](https://docs.gitlab.com/omnibus/settings/redis/)이 지원되며 필요한 경우 추가할 수 있습니다.

## GitLab Rails 애플리케이션 인스턴스 설정 {#set-up-the-gitlab-rails-application-instance}

GitLab이 설치된 인스턴스에서:

1. `/etc/gitlab/gitlab.rb` 파일을 편집하고 다음 콘텐츠를 추가합니다:

   ```ruby
   ## Disable Redis
   redis['enable'] = false

   gitlab_rails['redis_host'] = 'redis.example.com'
   gitlab_rails['redis_port'] = 6379

   ## Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. 변경 사항을 `/etc/gitlab/gitlab.rb`에 저장합니다.

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

## Redis 대신 Valkey 사용 {#use-valkey-instead-of-redis}

{{< history >}}

- GitLab 18.9에서 [베타](../../policy/development_stages_support.md#beta) 로 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)되었습니다.
- GitLab 19.0에서 [정식 버전(GA)으로 출시됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839).

{{< /history >}}

Redis의 대체 솔루션으로 [Valkey](https://valkey.io/)를 사용할 수 있습니다. Valkey는 Redis와 동일한 구성 옵션을 사용합니다.

독립 실행형 노드에서 Redis 대신 Valkey를 사용하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 내용을 추가합니다:

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Switch to Valkey
   redis['backend'] = 'valkey'

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

GitLab Rails 애플리케이션 구성은 동일하게 유지됩니다. `gitlab_rails['redis_host']`, `gitlab_rails['redis_port']`, 그리고 `gitlab_rails['redis_password']`을(를) Redis에서와 마찬가지로 구성합니다.

### 알려진 이슈 {#known-issues}

- 알려진 [이슈 589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642) 때문에 Admin Area는 Valkey 버전을 잘못 보고합니다. 이 이슈는 설치된 Valkey 버전이나 작동 방식에 영향을 미치지 않습니다.

## 문제 해결 {#troubleshooting}

[Redis 문제 해결 가이드](troubleshooting.md)를 참조하세요.
