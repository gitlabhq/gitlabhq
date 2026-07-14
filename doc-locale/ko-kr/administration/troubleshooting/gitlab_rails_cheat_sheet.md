---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Rails 콘솔 참고 자료
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이것은 트러블슈팅 중에 사용할 수 있도록 GitLab 지원 팀이 GitLab Rails 콘솔에 대해 수집한 정보입니다. 대부분의 내용이 기능별 트러블슈팅 페이지 및 섹션으로 이동되었으므로 기록 목적으로 여기에 나열됩니다. [&8147](https://gitlab.com/groups/gitlab-org/-/epics/8147#tree) 에픽을 참조하세요. 북마크를 적절히 업데이트할 수 있습니다.

> [!warning]
> 이러한 스크립트 중 일부는 올바르게 실행되지 않거나 적절한 조건에서 실행되지 않으면 손상을 줄 수 있습니다. 지원 엔지니어의 지도 하에 실행하거나 필요한 경우를 대비하여 복원할 준비가 된 인스턴스 백업과 함께 테스트 환경에서 실행할 것을 권장합니다.

현재 GitLab에서 문제가 발생하고 있다면 여기에서 가리키는 정보를 시도하기 전에 먼저 [Rails 콘솔](../operations/rails_console.md) 에 대한 가이드와 [지원 옵션](https://about.gitlab.com/support/)을 확인할 것을 권장합니다.

> [!warning]
> GitLab이 변경되면 코드 변경은 불가피하므로 일부 스크립트는 이전처럼 작동하지 않을 수 있습니다. 이러한 스크립트와 명령은 발견되거나 필요한 대로 추가되었으므로 최신 상태로 유지되지 않습니다. 앞서 언급한 대로 지원 엔지니어의 감독 하에 이러한 스크립트를 실행할 것을 권장합니다. 지원 엔지니어는 스크립트가 계속 제대로 작동하는지 확인하고 필요한 경우 최신 GitLab 버전용으로 스크립트를 업데이트할 수 있습니다.

## 미러 {#mirrors}

### `bad decrypt` 오류가 있는 미러 찾기 {#find-mirrors-with-bad-decrypt-errors}

이 내용은 Rake 작업으로 변환되었습니다. [현재 시크릿을 사용하여 데이터베이스 값을 복호화할 수 있는지 확인](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)을 참조하세요.

### 미러 사용자 및 토큰을 단일 서비스 계정으로 전송 {#transfer-mirror-users-and-tokens-to-a-single-service-account}

이 내용은 [리포지토리 미러링 트러블슈팅](../../user/project/repository/mirror/troubleshooting.md#transfer-mirror-users-and-tokens-to-a-single-service-account)으로 이동했습니다.

## 머지 리퀘스트 {#merge-requests}

## CI {#ci}

이 내용은 [CI/CD 유지보수](../cicd/maintenance.md)로 이동했습니다.

## 라이선스 {#license}

이 내용은 [라이선스 파일 또는 키로 GitLab EE 활성화](../license_file.md)로 이동했습니다.

## 레지스트리 {#registry}

### 프로젝트별 컨테이너 레지스트리 디스크 공간 사용량 {#registry-disk-space-usage-by-project}

컨테이너 레지스트리에서 프로젝트별 스토리지 공간을 보려면 [프로젝트별 레지스트리 디스크 공간 사용량](../packages/container_registry.md#registry-disk-space-usage-by-project)을 참조하세요.

### 정리 정책 실행 {#run-the-cleanup-policy}

컨테이너 레지스트리의 스토리지 공간을 줄이려면 [정리 정책 실행](../packages/container_registry.md#run-the-cleanup-policy)을 참조하세요.

## Sidekiq {#sidekiq}

이 내용은 [Sidekiq 트러블슈팅](../sidekiq/sidekiq_troubleshooting.md)으로 이동했습니다.

## Geo {#geo}

### 모든 업로드 재확인(또는 확인된 모든 SSF 데이터 유형) {#reverify-all-uploads-or-any-ssf-data-type-which-is-verified}

[Geo 레플리케이션 트러블슈팅](../geo/replication/troubleshooting/synchronization_verification.md#resync-and-reverify-multiple-components)으로 이동했습니다.

### 아티팩트 {#artifacts}

[Geo 레플리케이션 트러블슈팅](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)으로 이동했습니다.

### 리포지토리 확인 실패 {#repository-verification-failures}

[Geo 레플리케이션 트러블슈팅](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)으로 이동했습니다.

### 리포지토리 재동기화 {#resync-repositories}

[Geo 레플리케이션 트러블슈팅 - 리포지토리 유형 재동기화](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)로 이동했습니다.

[Geo 레플리케이션 트러블슈팅 - 프로젝트 및 프로젝트 wiki 리포지토리 재동기화](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)로 이동했습니다.

### Blob 유형 {#blob-types}

[Geo 레플리케이션 트러블슈팅](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)으로 이동했습니다.

## Service Ping 생성 {#generate-service-ping}

이 내용은 GitLab 개발 문서의 Service Ping 트러블슈팅으로 이동했습니다.
