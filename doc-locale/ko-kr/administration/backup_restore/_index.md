---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 백업 및 복원 개요
description: GitLab 인스턴스를 백업하고 복원합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스에는 소프트웨어 개발 또는 조직을 위한 중요한 데이터가 포함되어 있습니다. 정기적인 백업을 포함하는 재해 복구 계획을 수립하는 것이 중요합니다:

- 데이터 보호:  하드웨어 장애, 소프트웨어 버그 또는 실수로 인한 삭제로 인한 데이터 손실로부터 보호합니다.
- 재해 복구:  부작용 발생 시 GitLab 인스턴스 및 데이터를 복원합니다.
- 버전 제어:  이전 상태로 롤백할 수 있도록 하는 과거 스냅샷을 제공합니다.
- 준수:  특정 산업의 규정 요구 사항을 충족합니다.
- 마이그레이션:  GitLab을 새로운 서버 또는 환경으로 이동을 용이하게 합니다.
- 테스트 및 개발:  프로덕션 데이터의 위험 없이 업그레이드 또는 새 기능을 테스트하기 위한 사본을 생성합니다.

> [!note]
> 이 문서는 GitLab Community 및 Enterprise Edition에 적용됩니다. GitLab.com의 경우 데이터 보안이 보장되지만 GitLab.com에서 데이터를 내보내거나 백업할 수 없습니다.

## GitLab 백업 {#back-up-gitlab}

GitLab 인스턴스를 백업하는 절차는 배포의 특정 구성 및 사용 패턴에 따라 다릅니다. 데이터 유형, 스토리지 위치 및 볼륨과 같은 요소는 백업 방법, 스토리지 옵션 및 복원 프로세스에 영향을 미칩니다. 자세한 정보는 [GitLab 백업](backup_gitlab.md)을 참조하세요.

## GitLab 복원 {#restore-gitlab}

GitLab 인스턴스를 백업하는 절차는 배포의 특정 구성 및 사용 패턴에 따라 다릅니다. 데이터 유형, 스토리지 위치 및 볼륨과 같은 요소는 복원 프로세스에 영향을 미칩니다.

자세한 정보는 [GitLab 복원](restore_gitlab.md)을 참조하세요.

## 새 서버로 마이그레이션 {#migrate-to-a-new-server}

GitLab 백업 및 복원 기능을 사용하여 인스턴스를 새 서버로 마이그레이션합니다. GitLab Geo 배포의 경우 [계획된 장애 조치를 위한 Geo 재해 복구](../geo/disaster_recovery/planned_failover.md)를 고려하세요. 자세한 정보는 [새 서버로 마이그레이션](migrate_to_new_server.md)을 참조하세요.

## 대규모 참조 아키텍처 백업 및 복원 {#back-up-and-restore-large-reference-architectures}

대규모 참조 아키텍처를 정기적으로 백업하고 복원하는 것이 중요합니다. 객체 스토리지 데이터, PostgreSQL 데이터 및 Git 리포지토리에 대한 백업을 구성하고 복원하는 방법에 대한 정보는 [대규모 참조 아키텍처 백업 및 복원](backup_large_reference_architectures.md)을 참조하세요.

## 백업 아카이브 프로세스 {#backup-archive-process}

데이터 보존 및 시스템 무결성을 위해 GitLab은 백업 아카이브를 생성합니다. GitLab이 이 아카이브를 생성하는 방법에 대한 자세한 정보는 [백업 아카이브 프로세스](backup_archive_process.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [Geo](../geo/_index.md)
- [재해 복구 (Geo)](../geo/disaster_recovery/_index.md)
- [GitLab 그룹 마이그레이션](../../user/group/import/_index.md)
- [GitLab으로 가져오기 및 마이그레이션](../../user/import/_index.md)
- [GitLab Linux 패키지(Omnibus) - 백업 및 복원](https://docs.gitlab.com/omnibus/settings/backups/)
- [GitLab Helm 차트 - 백업 및 복원](https://docs.gitlab.com/charts/backup-restore/)
- [GitLab Operator - 백업 및 복원](https://docs.gitlab.com/operator/backup_and_restore/)
