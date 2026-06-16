---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 프라이머리 사이트를 보조 사이트로 승격하여 기본 점검 및 동기화 단계에 따라 최소한의 다운타임으로 GitLab을 마이그레이션하기 위해 Geo를 사용합니다.
title: 계획된 페일오버를 위한 재해 복구
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

재해 복구의 주요 사용 사례는 계획되지 않은 중단 시에 비즈니스 연속성을 보장하는 것입니다. 하지만 계획된 페일오버와 함께 사용하여 확장된 다운타임 없이 GitLab 인스턴스를 지역 간에 마이그레이션할 수 있습니다.

Geo 사이트 간의 복제는 비동기이므로 계획된 페일오버는 프라이머리 사이트에 대한 업데이트가 차단되는 유지 관리 기간이 필요합니다. 이 기간의 길이는 보조 사이트를 프라이머리 사이트와 완전히 동기화하는 데 걸리는 시간에 따라 다릅니다. 동기화가 완료되면 데이터 손실 없이 페일오버가 발생할 수 있습니다.

이 문서에서는 이미 완전히 구성되고 작동하는 Geo 설정이 있다고 가정합니다. 진행하기 전에 이 문서와 [재해 복구](_index.md) 페일오버 문서를 전체적으로 읽으세요. 계획된 페일오버는 주요 작업이며, 잘못 수행하면 데이터 손실의 높은 위험이 있습니다. 필요한 단계에 익숙해질 때까지 절차를 반복하고, 정확하게 수행할 수 있다는 높은 확신을 가질 때까지 연습하세요.

## 페일오버 권장 사항 {#recommendations-for-failover}

이러한 권장 사항을 따르면 원활한 페일오버 프로세스를 보장하고 데이터 손실 또는 확장된 다운타임의 위험을 줄일 수 있습니다.

### 동기화 및 검증 실패 해결 {#resolve-sync-and-verification-failures}

**실패함** 또는 **대기 중** 항목이 [기본 점검](#preflight-checks) 중에 있으면 (수동 검증 또는 `gitlab-ctl promotion-preflight-checks`를 실행할 때), 다음 중 하나가 될 때까지 페일오버가 차단됩니다:

- 해결됨:  성공적으로 동기화되고 (필요한 경우 수동으로 보조 사이트에 복사) 검증됨.
- 수용 가능한 것으로 문서화됨:  다음과 같은 명확한 근거와 함께:
  - 이러한 특정 실패에 대해 수동 체크섬 비교가 통과합니다.
  - 리포지토리는 더 이상 사용되지 않으며 제외할 수 있습니다.
  - 항목은 중요하지 않은 것으로 식별되며 페일오버 후에 복사할 수 있습니다.

동기화 및 검증 실패 진단에 대한 도움은 [Geo 동기화 및 검증 오류 문제 해결](../replication/troubleshooting/synchronization_verification.md)을 참조하세요.

### 데이터 무결성 해결 계획 {#plan-for-data-integrity-resolution}

Geo 복제를 처음 설정한 후 일반적으로 나타나는 데이터 무결성 문제를 해결하기 위해 페일오버 완료 전에 4~6주의 시간을 할애하세요. 여기에는 고아 데이터베이스 레코드 또는 일관성 없는 파일 참조가 포함될 수 있습니다. 지침은 [일반적인 Geo 오류 문제 해결](../replication/troubleshooting/common.md)을 참조하세요.

유지 관리 기간 동안 어려운 결정을 피하기 위해 동기화 문제를 조기에 해결하기 시작하세요:

1. 4~6주 전:  미해결 동기화 문제를 식별하고 해결하기 시작하세요.
1. 1주일 전:  모든 남은 동기화 문제의 해결 또는 문서화를 목표로 하세요.
1. 1~2일 전:  새로운 실패를 해결하세요.
1. 몇 시간 전:  새로운 실패가 있는지 마지막으로 확인하세요.

성공을 보장하려면 미해결 동기화 오류로 인해 페일오버를 중단할 시점을 명확히 하는 기준을 작성하세요.

### Geo 환경에서 백업 타이밍 테스트 {#test-backup-timing-in-geo-environments}

> [!warning]
> Geo 복제본 데이터베이스의 백업은 활성 데이터베이스 트랜잭션 중에 취소될 수 있습니다.

백업 절차를 미리 테스트하고 이러한 전략을 고려하세요:

- 프라이머리 사이트에서 직접 백업을 수행합니다. 이것이 성능에 영향을 미칠 수 있습니다.
- 백업 중에 복제에서 격리될 수 있는 전용 읽기 복제본을 사용하세요.
- 낮은 활동 기간 동안 백업을 예약하세요.

### 포괄적인 폴백 절차 준비 {#prepare-comprehensive-fallback-procedures}

> [!warning]
> 승격이 완료되기 전에 롤백 결정 지점을 계획하세요. 나중에 폴백하면 데이터 손실이 발생할 수 있습니다.

원본 프라이머리 사이트로 되돌리기 위한 구체적인 단계를 문서화하세요. 여기에 포함된 내용:

- 페일오버를 중단할 시점의 결정 기준.
- DNS 되돌리기 절차.
- 원본 프라이머리 사이트를 다시 활성화하는 프로세스. [강등된 프라이머리 사이트를 다시 온라인으로 전환](bring_primary_back.md)을 참조하세요.
- 사용자 커뮤니케이션 계획.

### 스테이징 환경에서 페일오버 런북 개발 {#develop-a-failover-runbook-in-a-staging-environment}

성공을 보장하려면 이 고도의 수동 작업을 전체 세부사항으로 연습하고 문서화하세요:

1. 아직 없다면 프로덕션과 유사한 환경을 프로비저닝하세요.
1. 스모크 테스트. 예를 들어, 그룹을 추가하고, 작업을 추가하고, 러너를 추가하고, `git push`을 사용하고, 이슈에 이미지를 추가합니다.
1. 보조 사이트로 페일오버합니다.
1. 스모크 테스트를 실행합니다. 문제를 확인합니다.
1. 이러한 단계 중에 수행된 모든 작업, 담당자, 예상 결과, 리소스 링크를 기록하세요.
1. 런북과 스크립트를 개선하기 위해 필요에 따라 반복하세요.

## 모든 데이터가 자동으로 복제되는 것은 아닙니다 {#not-all-data-is-automatically-replicated}

Geo가 지원하지 않는 GitLab 기능을 사용 중인 경우, 보조 사이트에 해당 기능과 관련된 데이터의 최신 복사본이 있는지 확인하기 위해 별도의 조치를 취해야 합니다. 이것이 유지 관리 기간을 크게 연장할 수 있습니다. Geo에서 지원하는 기능 목록은 [복제된 데이터 유형 표](../replication/datatypes.md#replicated-data-types)를 참조하세요.

파일에 저장된 데이터의 경우 이 기간을 최대한 짧게 유지하는 일반적인 전략은 `rsync`을 사용하여 데이터를 전송하는 것입니다. 초기 `rsync`는 유지 관리 기간 전에 수행할 수 있습니다. 나중의 `rsync` 절차 (유지 관리 기간 내의 최종 전송 포함)는 프라이머리 사이트와 보조 사이트 간의 변경 사항만 전송합니다.

Git 리포지토리 중심의 `rsync` 사용 전략은 [리포지토리 이동](../../operations/moving_repositories.md)을 참조하세요. 이러한 전략을 다른 파일 기반 데이터로 사용하도록 조정할 수 있습니다.

### 컨테이너 레지스트리 {#container-registry}

기본적으로 컨테이너 레지스트리는 보조 사이트에 자동으로 복제되지 않습니다. 이것을 수동으로 구성해야 합니다. 자세한 내용은 [컨테이너 레지스트리 for a secondary site](../replication/container_registry.md)를 참조하세요.

프라이머리 사이트에서 컨테이너 레지스트리에 로컬 스토리지를 사용하는 경우, `rsync`을 사용하여 컨테이너 레지스트리 객체를 페일오버하려는 보조 사이트로 전송할 수 있습니다:

```shell
# Run from the secondary site
rsync --archive --perms --delete root@<geo-primary>:/var/opt/gitlab/gitlab-rails/shared/registry/. /var/opt/gitlab/gitlab-rails/shared/registry
```

또는 프라이머리 사이트에서 컨테이너 레지스트리를 [백업](../../backup_restore/_index.md#back-up-gitlab)하고 보조 사이트로 복원합니다:

1. 프라이머리 사이트에서 레지스트리만 백업하고 [백업에서 특정 디렉터리 제외](../../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup):

   ```shell
   # Create a backup in the /var/opt/gitlab/backups folder
   sudo gitlab-backup create SKIP=db,uploads,builds,artifacts,lfs,terraform_state,pages,repositories,packages
   ```

1. 프라이머리 사이트에서 생성된 백업 tarball을 보조 사이트의 `/var/opt/gitlab/backups` 폴더에 복사합니다.
1. 보조 사이트에서 [GitLab 복원](../../backup_restore/_index.md#restore-gitlab) 문서에 따라 레지스트리를 복원합니다.

### 고급 검색을 위한 데이터 복구 {#recover-data-for-advanced-search}

고급 검색은 Elasticsearch 또는 OpenSearch에서 제공됩니다. 고급 검색을 위한 데이터는 보조 사이트에 자동으로 복제되지 않습니다.

새로 승격된 프라이머리 사이트에서 고급 검색을 위한 데이터를 복구하려면:

{{< tabs >}}

{{< tab title="GitLab 17.2 이상" >}}

1. Elasticsearch로 검색 비활성화:

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. [전체 인스턴스 다시 인덱싱](../../../integration/advanced_search/elasticsearch.md#index-the-instance).
1. [인덱싱 상태 확인](../../../integration/advanced_search/elasticsearch.md#check-indexing-status).
1. [백그라운드 작업의 상태 모니터링](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs).
1. Elasticsearch로 검색 활성화:

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< tab title="GitLab 17.1 이상" >}}

1. Elasticsearch로 검색 비활성화:

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. 인덱싱을 일시 중지하고 진행 중인 작업이 완료될 때까지 5분 동안 기다립니다:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. 처음부터 인스턴스를 다시 인덱싱합니다:

   ```shell
   sudo gitlab-rake gitlab:elastic:index
   ```

1. 인덱싱을 재개합니다:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

1. [인덱싱 상태 확인](../../../integration/advanced_search/elasticsearch.md#check-indexing-status).
1. [백그라운드 작업의 상태 모니터링](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs).
1. Elasticsearch로 검색 활성화:

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< /tabs >}}

## 기본 점검 {#preflight-checks}

계획된 페일오버를 예약하기 전에 이러한 기본 점검을 확인하여 프로세스가 원활하게 진행되도록 하세요. 각 단계는 아래에서 더 자세히 설명됩니다.

프라이머리 사이트가 다운된 후 실제 페일오버 프로세스 중에 이 명령을 실행하여 보조 사이트를 승격하기 전에 최종 검증 점검을 수행합니다:

```shell
gitlab-ctl promotion-preflight-checks
```

`gitlab-ctl promotion-preflight-checks` 명령은 페일오버 프로세스의 일부이며 프라이머리 사이트가 다운되어야 합니다. 프라이머리 사이트가 여전히 실행 중인 동안 사전 유지 관리 검증 도구로 사용할 수 없습니다. 이 명령을 실행하면 프라이머리 사이트가 다운되었는지를 묻는 프롬프트가 표시됩니다. `No`로 답변하면 이 오류가 표시됩니다: `ERROR: primary node must be down`.

프라이머리 사이트가 여전히 작동 중인 동안 사전 유지 관리 검증을 위해 아래의 수동 점검을 사용하세요.

### DNS TTL {#dns-ttl}

[프라이머리 도메인 DNS 레코드 업데이트](_index.md#optional-updating-the-primary-domain-dns-record)를 계획 중인 경우, DNS 변경의 빠른 전파를 보장하기 위해 낮은 TTL (time-to-live)을 설정하는 것을 고려하세요.

### 객체 스토리지 {#object-storage}

대규모 GitLab 설치가 있거나 다운타임을 허용할 수 없는 경우, 계획된 페일오버를 예약하기 전에 [Object Storage로 마이그레이션](../replication/object_storage.md)하는 것을 고려하세요. 이렇게 하면 유지 관리 기간의 길이와 잘못 실행된 계획된 페일오버로 인한 데이터 손실의 위험이 모두 감소합니다.

GitLab에서 보조 사이트의 객체 스토리지 복제를 관리하도록 하려면 [Object Storage 복제](../replication/object_storage.md)을 참조하세요.

### 각 보조 사이트의 구성 검토 {#review-the-configuration-of-each-secondary-site}

데이터베이스 설정은 보조 사이트에 자동으로 복제됩니다. 그러나 `/etc/gitlab/gitlab.rb` 파일을 수동으로 설정해야 하며, 사이트마다 다릅니다. Mattermost, OAuth 또는 LDAP 통합과 같은 기능이 프라이머리 사이트에서 활성화되었지만 보조 사이트에서 활성화되지 않으면 페일오버 중에 손실됩니다.

두 사이트 모두에 대해 `/etc/gitlab/gitlab.rb` 파일을 검토하세요. 계획된 페일오버를 예약하기 전에 보조 사이트가 프라이머리 사이트가 하는 모든 것을 지원하는지 확인하세요. [GitLab Geo Roles](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)이 올바르게 구성되었는지 확인하세요.

### 시스템 점검 실행 {#run-system-checks}

프라이머리 및 보조 사이트 모두에서 다음을 실행합니다:

```shell
gitlab-rake gitlab:check
gitlab-rake gitlab:geo:check
```

두 사이트 모두에서 오류를 보고하면 계획된 페일오버를 예약하기 전에 해결하세요.

### 노드 간 시크릿 및 SSH 호스트 키가 일치하는지 확인 {#check-that-secrets-and-ssh-host-keys-match-between-nodes}

SSH 호스트 키 및 `/etc/gitlab/gitlab-secrets.json` 파일은 모든 노드에서 동일해야 합니다. 모든 노드에서 다음을 실행하고 출력을 비교하여 이를 확인합니다:

```shell
sudo sha256sum /etc/ssh/sshhost /etc/gitlab/gitlab-secrets.json
```

파일이 다르면 [GitLab 시크릿을 수동으로 복제](../replication/configuration.md#step-1-manually-replicate-secret-gitlab-values) 하고 필요에 따라 보조 사이트에 [SSH 호스트 키를 복제](../replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys)하세요.

### HTTPS에 대해 올바른 인증서가 설치되어 있는지 확인 {#check-that-the-correct-certificates-are-installed-for-https}

프라이머리 사이트와 프라이머리 사이트에서 액세스하는 모든 외부 사이트에서 공개 CA에서 발급한 인증서를 사용하면 이 단계를 안전하게 건너뛸 수 있습니다.

다음 중 하나라도 해당하면 보조 사이트에 올바른 인증서를 설치해야 합니다:

- 프라이머리 사이트에서 인바운드 연결을 보호하기 위해 사용자 지정 또는 자체 서명된 TLS 인증서를 사용합니다.
- 프라이머리 사이트에서 사용자 지정 또는 자체 서명된 인증서를 사용하는 외부 서비스에 연결합니다.

자세한 내용은 [사용자 지정 인증서 사용](../replication/configuration.md#step-4-optional-using-custom-certificates)을 보조 사이트와 함께 참조하세요.

### Geo 복제가 최신인지 확인 {#ensure-geo-replication-is-up-to-date}

유지 관리 기간은 Geo 복제 및 검증이 완전히 완료될 때까지 끝나지 않습니다. 기간을 최대한 짧게 유지하려면 활성 사용 중에 이러한 프로세스가 최대 100%에 가까운지 확인해야 합니다.

보조 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다. 복제된 객체 (녹색으로 표시)는 100%에 가까워야 하며 실패 (빨간색으로 표시)가 없어야 합니다. 많은 비율의 객체가 아직 복제되지 않았으면 (회색으로 표시), 사이트에 완료할 시간을 더 갖도록 고려하세요:

   ![보조 사이트의 동기화 상태를 보여주는 Geo 운영자 대시보드](img/geo_dashboard_v14_0.png)

객체 복제에 실패하면 유지 관리 기간을 예약하기 전에 조사하세요. 복제에 실패한 모든 객체는 계획된 페일오버 후에 손실됩니다.

복제 실패의 일반적인 원인은 프라이머리 사이트에서 데이터가 누락된 것입니다. 이러한 실패를 해결하려면 다음 중 하나를 수행하세요:

- 백업에서 데이터를 복원합니다.
- 누락된 데이터에 대한 참조를 제거합니다.

### 복제된 데이터의 무결성 확인 {#verify-the-integrity-of-replicated-data}

페일오버를 진행하기 전에 검증이 완료되었는지 확인하세요. 검증에 실패한 손상된 데이터는 페일오버 중에 손실될 수 있습니다.

자세한 내용은 [자동 백그라운드 검증](background_verification.md)을 참조하세요.

### 예정된 유지 관리에 대해 사용자에게 알림 {#notify-users-of-scheduled-maintenance}

프라이머리 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **메시지**를 선택합니다.
1. 유지 관리 기간을 알리는 메시지를 추가합니다. 동기화 완료에 필요한 시간을 추정하려면 **Geo** > **사이트**로 이동합니다.
1. **전체 알림 메시지 추가하기**를 선택합니다.

### 페일오버 중 러너 연결성 {#runner-connectivity-during-failover}

인스턴스 URL이 구성된 방식에 따라 페일오버 후 러너 플릿을 100%로 유지하기 위한 추가 단계가 있을 수 있습니다.

러너를 등록하는 데 사용되는 토큰은 프라이머리 또는 보조 인스턴스에서 작동해야 합니다. 페일오버 후 연결 문제가 표시되면 시크릿이 [보조 구성](../setup/two_single_node_sites.md#manually-replicate-secret-gitlab-values) 중에 복사되지 않았을 가능성이 있습니다. [러너 토큰 재설정](../../backup_restore/troubleshooting_backup_gitlab.md#reset-runner-registration-tokens)할 수 있지만, 시크릿이 동기화되지 않으면 러너와 관련되지 않은 다른 문제가 발생할 수 있습니다.

러너가 반복적으로 GitLab 인스턴스에 연결할 수 없으면 일정 시간 동안 연결을 시도하지 않습니다. 기본적으로 이 기간은 1시간입니다. 이를 방지하려면 GitLab 인스턴스에 도달할 수 있을 때까지 러너를 종료하세요. [`check_interval` 문서](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-check_interval-works)를 참조하고, `unhealthy_requests_limit` 및 `unhealthy_interval` 구성 옵션을 참조하세요.

- 우리의 **Location aware URL**을 사용하는 경우:  DNS 구성에서 이전 프라이머리가 제거되면 러너는 자동으로 가장 가까운 다음 인스턴스에 연결됩니다.
- 별도의 URL을 사용하는 경우:  현재 프라이머리 사이트에 연결된 모든 러너는 승격되면 새로운 프라이머리 사이트에 연결하도록 업데이트해야 합니다.
- 현재 보조 사이트에 연결된 러너가 있는 경우:  페일오버 중에 [보조 러너 처리 방법](../secondary_proxy/runners.md#handling-a-planned-failover-with-secondary-runners)을 참조하세요.

### OpenBao 사전 요구 사항 {#openbao-prerequisites}

GitLab Helm 차트와 함께 [OpenBao](https://docs.gitlab.com/charts/charts/openbao/)가 설치된 경우, **프라이머리** 클러스터에 여전히 액세스할 수 있는 동안 이러한 점검을 완료하세요.

#### 보조 사이트에서 봉인 해제 시크릿이 있는지 확인 {#verify-the-unseal-secret-is-present-on-the-secondary}

`gitlab-openbao-unseal` Kubernetes 시크릿이 보조 클러스터에 있어야 합니다. 그것이 있는지 확인합니다:

```shell
kubectl --namespace gitlab get secret gitlab-openbao-unseal
```

시크릿이 누락되면 진행하기 전에 프라이머리에서 복사하세요. 자세한 내용은 [시크릿 백업](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets)을 참조하세요.

#### OpenBao 데이터베이스 복제 검증 {#validate-openbao-database-replication}

보조 OpenBao 데이터베이스는 `openbao` 스키마를 포함한 프라이머리 PostgreSQL의 읽기 복제본입니다. 계획된 페일오버 전에 복제가 최신이고 보조 데이터가 프라이머리와 일치하는지 확인합니다.

프라이머리 데이터베이스를 이미 사용할 수 없으면 보조는 마지막 복제된 트랜잭션까지의 데이터를 포함합니다. 마지막 복제 후 프라이머리에 기록된 모든 시크릿은 손실됩니다.

## 프라이머리 사이트에 대한 업데이트 방지 {#prevent-updates-to-the-primary-site}

모든 데이터가 보조 사이트에 복제되도록 하려면 프라이머리 사이트에서 업데이트 (쓰기 요청)를 비활성화하여 보조 사이트가 따라잡을 시간을 주세요:

1. 프라이머리 사이트에서 [유지 관리 모드](../../maintenance_mode/_index.md)를 활성화합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
1. Sidekiq 대시보드에서 **Cron**을 선택합니다.
1. 비Geo 정기적 백그라운드 작업을 비활성화하려면 `Disable All`을 선택합니다.
1. 이러한 cron 작업에 대해 `Enable`을 선택합니다:

   - `geo_metrics_update_worker`
   - `geo_prune_event_log_worker`
   - `geo_verification_cron_worker`
   - `repository_check_worker`

   이러한 cron 작업을 다시 활성화하는 것은 계획된 페일오버가 성공적으로 완료되기 위해 필수적입니다.

## 모든 데이터 복제 및 검증 완료 {#finish-replicating-and-verifying-all-data}

1. Geo에서 관리하지 않는 데이터를 수동으로 복제하는 경우 지금 최종 복제 프로세스를 트리거하세요.
1. 프라이머리 사이트에서:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
   1. Sidekiq 대시보드에서 **Queues**를 선택합니다. 이름에 `geo`를 포함한 큐를 제외하고 모든 큐가 0으로 떨어질 때까지 기다립니다. 이러한 큐는 사용자가 제출한 작업을 포함합니다. 큐가 비기 전에 페일오버하면 작업이 손실됩니다.
   1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다. 페일오버하려는 보조 사이트에서 다음 조건이 참인지 확인합니다:

      - 모든 복제 미터가 100% 복제되고 0% 실패에 도달합니다.
      - 모든 검증 미터가 100% 검증되고 0% 실패에 도달합니다.
      - 데이터베이스 복제 지연 시간은 0 ms입니다.
      - Geo 로그 커서는 최신 (0 이벤트 뒤쪽)입니다.

1. 보조 사이트에서:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
   1. Sidekiq 대시보드에서 **Queues**를 선택합니다. 모든 `geo` 큐가 0개의 대기 중 및 0개의 실행 중인 작업으로 떨어질 때까지 기다립니다.
   1. [무결성 점검 실행](../../raketasks/check.md)을 수행하여 CI 아티팩트, LFS 객체 및 파일 스토리지의 업로드 무결성을 검증합니다.

이 시점에서 보조 사이트는 프라이머리 사이트가 가지고 있는 모든 것의 최신 복사본을 포함하여 페일오버 시 데이터 손실이 없음을 보장합니다.

## 보조 사이트 승격 {#promote-the-secondary-site}

복제가 완료되면 [보조 사이트를 프라이머리 사이트로 승격](_index.md)합니다. 이 프로세스는 보조 사이트에 대한 짧은 중단을 발생시키며, 사용자가 다시 로그인해야 할 수 있습니다. 단계를 올바르게 따르면 이전 프라이머리 Geo 사이트가 비활성화되고 사용자 트래픽이 새로 승격된 사이트로 흐릅니다.

승격이 완료되면 유지 관리 기간이 끝나고 새로운 프라이머리 사이트는 이제 이전 사이트에서 차이가 나기 시작합니다.

페일오버가 완료된 후 전체 알림 메시지를 제거하는 것을 잊지 마세요.

모든 것이 예상대로 작동하면 [이전 사이트를 보조 사이트로 다시 가져올 수](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site) 있습니다.

### 이전 프라이머리로 폴백 {#fall-back-to-the-old-primary}

새로 승격된 프라이머리 사이트에 문제가 있으면 [이전 사이트로 다시 페일오버](bring_primary_back.md)할 수 있습니다. 다만 새로운 프라이머리 사이트에서 수행한 모든 변경 사항이 손실됩니다.
