---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 세컨더리 사이트를 위한 컨테이너 레지스트리
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

**세컨더리** Geo 사이트에서 **프라이머리** Geo 사이트에서 가져온 컨테이너 이미지를 복제하는 컨테이너 레지스트리를 설정할 수 있습니다. 이 컨테이너 이미지 복제는 재해 복구 목적으로만 사용됩니다.

**세컨더리** Geo 사이트의 컨테이너 레지스트리에 푸시하지 않습니다. 데이터가 **프라이머리** 사이트로 전파되지 않기 때문입니다.

**세컨더리** 사이트에서 컨테이너 레지스트리 데이터를 가져오는 것은 권장하지 않습니다. 데이터가 오래되었을 수 있기 때문입니다. [이슈 365864](https://gitlab.com/gitlab-org/gitlab/-/issues/365864)는 이 문제를 해결할 수 있습니다. 관심을 등록하기 위해 이슈에 투표하도록 권장합니다.

> [!warning]
> **Important:** 컨테이너 레지스트리 메타데이터 데이터베이스는 컨테이너 이미지 복제와는 별개입니다. 컨테이너 이미지는 프라이머리 사이트에서 세컨더리 사이트로 복제되지만 메타데이터 데이터베이스는 복제되지 않습니다. GitLab Geo를 컨테이너 레지스트리 메타데이터 데이터베이스가 활성화된 상태로 사용할 때는 각 Geo 사이트(프라이머리 및 세컨더리 모두)에서 컨테이너 레지스트리를 위해 별도의 외부 PostgreSQL 인스턴스를 구성해야 합니다. 컨테이너 레지스트리 메타데이터 데이터베이스는 기본 GitLab 관리형 PostgreSQL 데이터베이스를 사용할 수 없습니다. 각 사이트의 메타데이터 데이터베이스는 이들 사이의 복제 없이 독립적으로 작동합니다. 설정 지침은 [외부 데이터베이스 사용](../../packages/container_registry_metadata_database.md#using-an-external-database)을 참조하세요.

## 지원되는 컨테이너 레지스트리 {#supported-container-registries}

Geo는 다음 유형의 컨테이너 레지스트리를 지원합니다:

- [Docker](https://distribution.github.io/distribution/)
- [OCI](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)

## 지원되는 이미지 형식 {#supported-image-formats}

다음 컨테이너 레지스트리 이미지 형식은 Geo에서 지원됩니다:

- [Docker V2, schema 1](https://distribution.github.io/distribution/spec/deprecated-schema-v1/)
- [Docker V2, schema 2](https://distribution.github.io/distribution/spec/manifest-v2-2/)
- [OCI (Open Container Initiative)](https://github.com/opencontainers/image-spec)

또한 Geo는 [BuildKit 캐시 이미지](https://github.com/moby/buildkit)도 지원합니다.

## 지원되는 스토리지 {#supported-storage}

### Docker {#docker}

지원되는 레지스트리 스토리지 드라이버에 대한 자세한 내용은 [Docker 레지스트리 스토리지 드라이버](https://distribution.github.io/distribution/storage-drivers/)를 참조하세요.

레지스트리를 배포할 때 [로드 밸런싱 고려사항](https://distribution.github.io/distribution/about/deploying/#load-balancing-considerations) 을 읽고 GitLab 통합 [컨테이너 레지스트리](../../packages/container_registry.md#use-object-storage)에 대한 스토리지 드라이버를 설정하는 방법을 확인하세요.

### OCI 아티팩트를 지원하는 레지스트리 {#registries-that-support-oci-artifacts}

다음 레지스트리는 OCI 아티팩트를 지원합니다:

- CNCF Distribution - 로컬/오프라인 확인
- Azure Container Registry (ACR)
- Amazon Elastic Container Registry (ECR)
- Google Artifact Registry (GAR)
- GitHub Packages 컨테이너 레지스트리 (GHCR)
- Bundle Bar

자세한 내용은 [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec)을 참조하세요.

## 컨테이너 레지스트리 복제 구성 {#configure-container-registry-replication}

클라우드 또는 로컬 스토리지에 사용할 수 있도록 스토리지에 구애받지 않는 복제를 활성화할 수 있습니다. 새 이미지가 **프라이머리** 사이트에 푸시될 때마다 각 **세컨더리** 사이트는 자체 컨테이너 리포지토리로 이미지를 가져옵니다.

컨테이너 레지스트리 복제를 구성하려면:

1. [**프라이머리** 사이트](#configure-primary-site)를 구성합니다.
1. [**세컨더리** 사이트](#configure-secondary-site)를 구성합니다.
1. 컨테이너 레지스트리 [복제](#verify-replication)를 확인합니다.

### 프라이머리 사이트 구성 {#configure-primary-site}

컨테이너 레지스트리가 **프라이머리** 사이트에서 설정되고 작동하는지 확인한 후 다음 단계를 진행하세요.

새 컨테이너 이미지를 복제하려면 컨테이너 레지스트리가 모든 푸시에 대해 **프라이머리** 사이트로 알림 이벤트를 보내야 합니다. 컨테이너 레지스트리와 **프라이머리** 사이트의 웹 노드 간에 공유되는 토큰은 통신을 더 안전하게 하는 데 사용됩니다.

1. GitLab **프라이머리** 서버로 SSH를 수행하고 루트로 로그인합니다(GitLab HA의 경우 레지스트리 노드만 필요함):

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   # Configure the registry to listen on the public/internal interface
   # Replace with the appropriate interface (for example, '0.0.0.0' for all interfaces)
   registry['registry_http_addr'] = '0.0.0.0:5000'
   registry['notifications'] = [
     {
       'name' => 'geo_event',
       'url' => 'https://<example.com>/api/v4/container_registry_event/events',
       'timeout' => '500ms',
       'threshold' => 5,
       'backoff' => '1s',
       'headers' => {
         'Authorization' => ['<replace_with_a_secret_token>']
       }
     }
   ]
   ```

   `<example.com>`을 프라이머리 사이트의 `/etc/gitlab/gitlab.rb` 파일에 정의된 `external_url`로 바꾸고, `<replace_with_a_secret_token>`를 문자로 시작하는 대소문자 구분 영숫자 문자열로 바꿉니다. `/dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 32 | sed "s/^[0-9]*//"; echo`을 사용하여 생성할 수 있습니다.

   > [!note]
   > 외부 레지스트리(GitLab과 통합되지 않은 레지스트리)를 사용하는 경우 `/etc/gitlab/gitlab.rb` 파일에서 알림 보안 암호(`registry['notification_secret']`)만 지정하면 됩니다.

1. GitLab HA만 해당합니다. 모든 웹 노드에서 `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   registry['notification_secret'] = '<replace_with_a_secret_token_generated_above>'
   ```

1. 방금 업데이트한 각 노드를 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

### 세컨더리 사이트 구성 {#configure-secondary-site}

컨테이너 레지스트리가 **세컨더리** 사이트에서 설정되고 작동하는지 확인한 후 다음 단계를 진행하세요.

다음 단계는 컨테이너 이미지가 복제되기를 원하는 각 **세컨더리** 사이트에서 수행해야 합니다.

**세컨더리** 사이트가 **프라이머리** 사이트 컨테이너 레지스트리와 안전하게 통신할 수 있도록 하려면 모든 사이트에 대해 단일 키 쌍이 필요합니다. **세컨더리** 사이트는 이 키를 사용하여 **프라이머리** 사이트 컨테이너 레지스트리에 액세스하기 위해 풀 전용 기능이 있는 수명이 짧은 JWT를 생성합니다.

**세컨더리** 사이트의 각 애플리케이션 및 Sidekiq 노드에서:

1. 노드로 SSH를 수행하고 `root` 사용자로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key`을 **프라이머리** 사이트에서 노드로 복사합니다.
1. `/etc/gitlab/gitlab.rb`을 편집하고 다음을 추가합니다:

   ```ruby
   gitlab_rails['geo_registry_replication_enabled'] = true

   # Primary registry's hostname and port, it will be used by
   # the secondary node to directly communicate to primary registry
   gitlab_rails['geo_registry_replication_primary_api_url'] = 'https://primary.example.com:5050/'
   ```

1. 변경 사항이 적용되도록 노드를 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

### 복제 확인 {#verify-replication}

컨테이너 레지스트리 복제가 작동하는지 확인하려면 **세컨더리** 사이트에서:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **노드**를 선택합니다. 초기 복제 또는 "백필"이 여전히 진행 중일 수 있습니다.

각 Geo 사이트의 동기화 프로세스는 **프라이머리** 사이트의 **Geo Nodes** 대시보드에서 브라우저로 모니터링할 수 있습니다.

## 문제 해결 {#troubleshooting}

### 컨테이너 레지스트리 복제가 활성화되어 있는지 확인 {#confirm-that-container-registry-replication-is-enabled}

이는 [Rails 콘솔](../../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 확인할 수 있습니다:

```ruby
Geo::ContainerRepositoryRegistry.replication_enabled?
```

### 컨테이너 레지스트리 알림 이벤트 누락 {#missing-container-registry-notification-event}

1. 프라이머리 사이트의 컨테이너 레지스트리에 이미지가 푸시되면 [컨테이너 레지스트리 알림](../../packages/container_registry.md#configure-container-registry-notifications)이 트리거되어야 합니다.
1. 프라이머리 사이트의 컨테이너 레지스트리는 `https://<example.com>/api/v4/container_registry_event/events`의 프라이머리 사이트 API를 호출합니다.
1. 프라이머리 사이트는 `geo_events` 테이블에 `replicable_name: 'container_repository', model_record_id: <ID of the container repository>`로 된 레코드를 삽입합니다.
1. 레코드는 PostgreSQL에 의해 세컨더리 사이트의 데이터베이스로 복제됩니다.
1. Geo Log Cursor 서비스는 새 이벤트를 처리하고 Sidekiq 작업 `Geo::EventWorker`를 대기열에 추가합니다.

이것이 올바르게 작동하는지 확인하려면 프라이머리 사이트의 레지스트리에 이미지를 푸시하고 Rails 콘솔에서 다음 명령을 실행하여 알림이 수신되었고 이벤트로 처리되었는지 확인합니다:

```ruby
Geo::Event.where(replicable_name: 'container_repository')
```

`geo.log`을 확인하여 `Geo::ContainerRepositorySyncService`의 항목을 찾으면 이를 추가로 확인할 수 있습니다.

### 레지스트리 이벤트 로그 응답 상태 401 Unauthorized 허용 안 됨 {#registry-events-logs-response-status-401-unauthorized-unaccepted}

`401 Unauthorized` 오류는 프라이머리 사이트의 컨테이너 레지스트리 알림이 Rails 애플리케이션에 의해 허용되지 않아서 GitLab에 무언가가 푸시되었음을 알리지 못함을 나타냅니다.

이를 해결하려면 레지스트리 알림과 함께 전송되는 인증 헤더가 [프라이머리 사이트 구성](#configure-primary-site) 단계에서 수행해야 하는 대로 프라이머리 사이트에 구성된 것과 일치하는지 확인합니다.

#### 레지스트리 오류: `token from untrusted issuer: "<token>"` {#registry-error-token-from-untrusted-issuer-token}

Geo에서 컨테이너 이미지를 복제할 때 오류 `token from untrusted issuer: "<token>"`이 표시될 수 있습니다.

이 문제는 컨테이너 레지스트리 구성이 올바르지 않아서 Sidekiq의 JWT 인증이 실패할 때 발생합니다.

이 문제를 해결하려면:

1. 두 사이트가 [세컨더리 사이트 구성](#configure-secondary-site)에 설명된 대로 단일 서명 키 쌍을 공유하는지 확인합니다.
1. 두 컨테이너 레지스트리와 프라이머리 및 세컨더리 사이트 모두가 동일한 토큰 발급자를 사용하도록 구성되어 있는지 확인합니다. 자세한 내용은 [별도 노드에서 GitLab 및 레지스트리 구성](../../packages/container_registry.md#configure-gitlab-and-registry-on-separate-nodes-linux-package-installations)을 참조하세요.
1. 다중 노드 배포의 경우 Sidekiq 노드에 구성된 발급자가 레지스트리에 구성된 값과 일치하는지 확인합니다.

### 컨테이너 레지스트리 동기화 이벤트 수동 트리거 {#manually-trigger-a-container-registry-sync-event}

문제 해결을 지원하기 위해 컨테이너 레지스트리 복제 프로세스를 수동으로 트리거할 수 있습니다:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. **복제 세부 정보**에서 **Secondary Site** 항목으로 **컨테이너 리포지토리**를 선택합니다.
1. 한 행에 대해 **재동기화**를 선택하거나 **전체 재동기화**를 선택합니다.

세컨더리의 Rails 콘솔에서 다음 명령을 실행하여 수동으로 재동기화를 트리거할 수도 있습니다:

```ruby
registry = Geo::ContainerRepositoryRegistry.first # Choose a Geo registry entry
registry.replicator.sync # Resync the container repository
pp registry.reload # Look at replication state fields

#<Geo::ContainerRepositoryRegistry:0x00007f54c2a36060
 id: 1,
 container_repository_id: 1,
 state: "2",
 retry_count: 0,
 last_sync_failure: nil,
 retry_at: nil,
 last_synced_at: Thu, 28 Sep 2023 19:38:05.823680000 UTC +00:00,
 created_at: Mon, 11 Sep 2023 15:38:06.262490000 UTC +00:00>
```

`state` 필드는 동기화 상태를 나타냅니다:

- `"0"`: 동기화 대기 중(일반적으로 동기화된 적이 없음을 의미)
- `"1"`: 동기화 시작(동기화 작업이 현재 실행 중)
- `"2"`: 성공적으로 동기화됨
- `"3"`: 동기화 실패

### 다운타임 후 리포지토리 재동기화 안 됨 {#repository-not-resynced-after-downtime}

컨테이너 레지스트리 복제가 `geo_container_repository_replication` 기능 플래그 또는 잘못된 구성으로 인해 일정 기간 동안 비활성화된 경우 해당 기간 동안 푸시된 이미지는 자동으로 **세컨더리** 사이트로 동기화되지 않을 수 있습니다.

다운타임 중에 생성된 새 컨테이너 리포지토리는 복제가 다시 활성화된 후 백필 워커에 의해 자동으로 선택됩니다. 그러나 기존 컨테이너 리포지토리(예: 기존 리포지토리에 푸시된 새 태그)에 대한 업데이트는 자동으로 재동기화되지 않습니다. Geo 관리자 UI는 동기화 상태가 콘텐츠 확인이 아닌 레지스트리 항목 상태를 기반으로 하기 때문에 여전히 100% 복제를 보고할 수 있습니다.

업데이트된 컨테이너 리포지토리는 **프라이머리** 사이트 재검증 주기가 체크섬 불일치를 감지한 후 결과적으로 재동기화됩니다. 재검증 간격에 대한 자세한 내용은 [리포지토리 재검증](../disaster_recovery/background_verification.md#repository-re-verification)을 참조하세요.

재검증 대기 대신 즉시 재동기화를 강제하려면 [복제 또는 검증 수동 재시도](troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)를 참조하세요.
