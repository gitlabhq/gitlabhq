---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo를 사용하여 GitLab 컨테이너 레지스트리 메타데이터 데이터베이스 활용
description: Geo를 사용하여 GitLab 컨테이너 레지스트리 메타데이터 데이터베이스 활용
---

Geo를 사용하여 GitLab 컨테이너 레지스트리를 사용하여 컨테이너 이미지를 복제합니다. 각 사이트의 컨테이너 레지스트리 메타데이터 데이터베이스는 독립적이며 Postgres 복제를 사용하지 않습니다.

각 보조 사이트는 메타데이터 데이터베이스를 위해 자체 별도의 PostgreSQL 인스턴스를 가져야 합니다.

## 컨테이너 레지스트리와 Geo를 사용하여 GitLab 인스턴스 생성 {#create-a-gitlab-instance-with-the-container-registry-and-geo}

전제 조건:

- GitLab의 새 인스턴스입니다.
- 데이터가 없는 인스턴스에 대해 구성된 컨테이너 레지스트리입니다.

Geo 지원을 설정하려면:

1. 주 사이트와 보조 사이트에 대해 Geo를 설정합니다. 자세한 내용은 [두 개의 단일 노드 사이트에 대해 Geo 설정](../../geo/setup/two_single_node_sites.md)을 참조하세요.
1. 주 사이트와 보조 사이트에서 [메타데이터 데이터베이스](../container_registry_metadata_database_new_install.md) 를 설정하여 각 사이트에 대해 별도의 [외부 데이터베이스](../container_registry_metadata_database.md#using-an-external-database)를 사용합니다.
1. [컨테이너 레지스트리 복제](../../geo/replication/container_registry.md#configure-container-registry-replication)를 구성합니다.

## 기존 Geo 사이트에 컨테이너 레지스트리를 추가 {#add-container-registries-to-existing-geo-sites}

전제 조건:

- 주 사이트 및 보조 사이트로 설정된 GitLab의 두 새 인스턴스입니다.
- 데이터가 없는 주 사이트에 대해 구성된 컨테이너 레지스트리입니다.

기존 Geo 보조 사이트에 컨테이너 레지스트리를 추가하려면:

1. 보조 사이트에서 [컨테이너 레지스트리 활성화](../container_registry.md)합니다.
1. 주 사이트와 보조 사이트에서 [메타데이터 데이터베이스](../container_registry_metadata_database_new_install.md) 를 설정하여 각 사이트에 대해 별도의 [외부 데이터베이스](../container_registry_metadata_database.md#using-an-external-database)를 사용합니다.
1. [컨테이너 레지스트리 복제](../../geo/replication/container_registry.md#configure-container-registry-replication)를 구성합니다.

## 기존 GitLab 인스턴스에 Geo 지원 및 컨테이너 레지스트리 추가 {#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab}

전제 조건:

- 컨테이너 레지스트리가 구성되지 않은 기존 GitLab 인스턴스입니다.
- 기존 Geo 사이트가 없습니다.

기존 인스턴스에 Geo 지원을 추가하고 두 Geo 사이트 모두에 컨테이너 레지스트리를 추가하려면:

1. 기존 인스턴스(주 사이트)에 대해 Geo를 설정하고 보조 사이트를 추가합니다. 자세한 내용은 [두 개의 단일 노드 사이트에 대해 Geo 설정](../../geo/setup/two_single_node_sites.md)을 참조하세요.
1. 주 사이트와 보조 사이트에서:
   1. [컨테이너 레지스트리 활성화](../container_registry.md#enable-the-container-registry)합니다.
   1. [메타데이터 데이터베이스](../container_registry_metadata_database_new_install.md) 를 설정하여 각 사이트에 대해 별도의 [외부 데이터베이스](../container_registry_metadata_database.md#using-an-external-database)를 사용합니다.
1. [컨테이너 레지스트리 복제](../../geo/replication/container_registry.md#configure-container-registry-replication)를 구성합니다.

## 구성된 컨테이너 레지스트리를 사용하는 인스턴스에 Geo 지원 추가 {#add-geo-support-to-an-instance-with-a-configured-container-registry}

다음 섹션에서는 구성된 컨테이너 레지스트리를 사용하는 기존 GitLab 인스턴스에 Geo 지원을 추가하는 지침을 제공합니다.

다음 중 하나를 설정할 수 있습니다:

- 외부 데이터베이스 연결입니다.
- 기본 컨테이너 레지스트리 메타데이터 데이터베이스입니다.

### 외부 컨테이너 레지스트리 메타데이터 데이터베이스 사용 {#use-an-external-container-registry-metadata-database}

전제 조건:

- 구성된 컨테이너 레지스트리를 사용하는 기존 GitLab 인스턴스입니다.
- 기존 Geo 사이트가 없습니다.

기존 인스턴스에 Geo 지원을 추가하고 컨테이너 레지스트리를 보조 사이트에 추가하려면:

1. 기존 인스턴스(주 사이트)에 대해 Geo를 설정하고 보조 사이트를 추가합니다. 자세한 내용은 [두 개의 단일 노드 사이트에 대해 Geo 설정](../../geo/setup/two_single_node_sites.md)을 참조하세요.
1. 보조 사이트에서:
   1. [컨테이너 레지스트리 활성화](../container_registry.md#enable-the-container-registry)합니다.
   1. [메타데이터 데이터베이스](../container_registry_metadata_database_new_install.md) 를 설정하여 별도의 [외부 데이터베이스](../container_registry_metadata_database.md#using-an-external-database)를 사용합니다.
1. [컨테이너 레지스트리 복제](../../geo/replication/container_registry.md#configure-container-registry-replication)를 구성합니다.

### 기본 컨테이너 레지스트리 메타데이터 데이터베이스 사용 {#use-the-default-container-registry-metadata-database}

전제 조건:

- 구성된 컨테이너 레지스트리를 사용하는 기존 GitLab 인스턴스입니다.
- 기본 PostgreSQL 인스턴스를 사용하는 컨테이너 레지스트리 메타데이터 데이터베이스입니다.
- 기존 Geo 사이트가 없습니다.

이 시나리오에서는 메타데이터 데이터베이스를 외부 PostgreSQL 인스턴스로 이동해야 합니다.

1. 다음 단계를 따라 [메타데이터 데이터베이스를 외부 PostgreSQL 인스턴스로 이동](../../postgresql/moving.md)합니다.
1. [기존 GitLab 인스턴스에 Geo 지원 및 컨테이너 레지스트리 추가](#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab)의 단계를 계속 진행합니다.

## 레거시 메타데이터에서 컨테이너 레지스트리 마이그레이션 {#migrate-the-container-registry-from-legacy-metadata}

이 시나리오에서는 레거시 메타데이터에서 기존 Geo 사이트의 외부 PostgreSQL 메타데이터 데이터베이스로 컨테이너 레지스트리를 마이그레이션해야 합니다.

전제 조건:

- GitLab 17.3 이상(데이터베이스 메타데이터 지원)
- 주 사이트 및 보조 사이트에 구성된 Geo
- 레거시 메타데이터를 사용하는 두 사이트의 컨테이너 레지스트리
- 두 레지스트리 모두 기존 데이터(푸시된 이미지)를 보유해야 합니다.

### 마이그레이션 단계 {#migration-steps}

다운타임은 가져오기 방법에 따라 달라집니다. 가져오기 방법에 대한 권장 사항은 [올바른 가져오기 방법 선택](../container_registry_metadata_database.md#choose-the-right-import-method)을 참조하세요.

> [!note]
> 마이그레이션 중에 마이그레이션되는 레지스트리는 읽기 전용입니다.

마이그레이션 중에 Geo 복제의 나머지는 계속됩니다.

메타데이터 데이터베이스를 마이그레이션하려면:

1. 보조 사이트에서 [기존 레거시 메타데이터를 새 메타데이터 데이터베이스로 마이그레이션](../container_registry_metadata_database.md#enable-the-database-for-existing-registries)합니다.
1. 주 사이트에서 [기존 레거시 메타데이터를 새 메타데이터 데이터베이스로 마이그레이션](../container_registry_metadata_database.md#enable-the-database-for-existing-registries)합니다.
1. Geo 복제가 계속 작동하는지 확인합니다.
