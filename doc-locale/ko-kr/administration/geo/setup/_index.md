---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 설정
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 필수 요구 사항 {#prerequisites}

- 독립적으로 작동하는 두 개 이상의 GitLab 사이트:
  - 하나의 GitLab 사이트는 Geo **프라이머리** 사이트로 제공됩니다. [GitLab 참조 아키텍처 설명서](../../reference_architectures/_index.md)를 사용하여 이를 설정합니다. 각 Geo 사이트마다 다른 참조 아키텍처 크기를 사용할 수 있습니다. 이미 사용 중인 GitLab 인스턴스가 있다면 **프라이머리** 사이트로 사용할 수 있습니다.
  - 두 번째 GitLab 사이트는 Geo **세컨더리** 사이트로 제공됩니다. [GitLab 참조 아키텍처 설명서](../../reference_architectures/_index.md)를 사용하여 이를 설정합니다. 로그인하여 테스트하는 것이 좋습니다. 다만 **all of the data on the secondary are lost**은 **프라이머리** 사이트에서 복제하는 과정의 일부입니다.

    > [!note]
    > Geo는 여러 세컨더리를 지원합니다. 동일한 단계를 따르고 필요한 경우 변경할 수 있습니다.

- 두 사이트 모두에 대한 관리자 액세스. 많은 구성 작업은 사이트에 대한 루트 액세스 및 GitLab UI의 **운영자** 영역에 대한 액세스가 필요합니다.
- **프라이머리** 사이트에 Geo를 잠금 해제하기 위해 [GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 구독이 있는지 확인합니다. 모든 사이트에 필요한 라이센스는 1개뿐입니다.
- [Geo 실행 요구 사항](../_index.md#requirements-for-running-geo)을 모든 사이트에서 충족하는지 확인합니다. 예를 들어 사이트는 동일한 GitLab 버전을 사용해야 하며 사이트는 특정 포트를 통해 서로 통신할 수 있어야 합니다.
- **프라이머리** 및 **세컨더리** 사이트 저장소 구성이 일치하는지 확인합니다. 프라이머리 Geo 사이트에서 객체 저장소를 사용하는 경우 세컨더리 Geo 사이트도 사용해야 합니다. 자세한 내용은 [Geo와 객체 저장소](../replication/object_storage.md)를 참조하세요.
- **프라이머리** 사이트와 **세컨더리** 사이트 간에 시간이 동기화되었는지 확인합니다. 동기화된 시계는 Geo가 올바르게 작동하는 데 필요합니다. 예를 들어 **프라이머리** 및 **세컨더리** 사이트 간의 시간 드리프트가 1분을 초과하면 복제가 실패합니다.

## Linux 패키지 설치 사용 {#using-linux-package-installations}

Linux 패키지를 사용하여 GitLab을 설치한 경우(권장), Geo 설정 프로세스는 단일 노드 Geo 사이트를 설정해야 하는지 또는 다중 노드 Geo 사이트를 설정해야 하는지에 따라 달라집니다.

### 단일 노드 Geo 사이트 {#single-node-geo-sites}

두 Geo 사이트가 모두 [1K 참조 아키텍처](../../reference_architectures/1k_users.md) 를 기반으로 하는 경우 [단일 노드 2개에 대한 Geo 설정](two_single_node_sites.md)을 따릅니다.

외부 PostgreSQL 서비스(예: Amazon RDS)를 사용하는 경우 [단일 노드 2개에 대한 Geo 설정(외부 PostgreSQL 서비스 포함)](two_single_node_external_services.md)을 따릅니다.

GitLab 배포에 따라 LDAP, 객체 저장소 및 컨테이너 레지스트리에 대한 [추가 구성](#additional-configuration)이 필요할 수 있습니다.

### 다중 노드 Geo 사이트 {#multi-node-geo-sites}

하나 이상의 사이트에서 [40 RPS / 2,000 사용자 참조 아키텍처](../../reference_architectures/2k_users.md) 이상을 사용하는 경우 [여러 노드에 대한 Geo 구성](../replication/multiple_servers.md)을 참조하세요.

GitLab 배포에 따라 LDAP, 객체 저장소 및 컨테이너 레지스트리에 대한 [추가 구성](#additional-configuration)이 필요할 수 있습니다.

### 참조용 일반 단계 {#general-steps-for-reference}

1. PostgreSQL 인스턴스 선택에 따라 데이터베이스 복제를 설정합니다(`primary (read-write) <-> secondary (read-only)` 토폴로지):
   - [Linux 패키지 PostgreSQL 인스턴스 사용](database.md).
   - [외부 PostgreSQL 인스턴스 사용](external_database.md)
1. [GitLab 구성](../replication/configuration.md)을(를) 통해 **프라이머리** 및 **세컨더리** 사이트를 설정합니다.
1. [Geo 사이트 사용](../replication/usage.md) 가이드를 따릅니다.

GitLab 배포에 따라 LDAP, 객체 저장소 및 컨테이너 레지스트리에 대한 [추가 구성](#additional-configuration)이 필요할 수 있습니다.

### 추가 구성 {#additional-configuration}

GitLab 사용 방법에 따라 다음 구성이 필요할 수 있습니다:

- **프라이머리** 사이트에서 객체 저장소를 사용하는 경우 **세컨더리** 사이트에 대해 [객체 저장소 복제를 구성](../replication/object_storage.md)합니다.
- LDAP를 사용하는 경우 **세컨더리** 사이트에 대해 [세컨더리 LDAP 서버 구성](../../auth/ldap/_index.md)을(를) 수행합니다. 자세한 내용은 [Geo와 함께 LDAP](../replication/single_sign_on.md#ldap)을(를) 참조하세요.
- 컨테이너 레지스트리를 사용하는 경우 [컨테이너 레지스트리 복제 구성](../replication/container_registry.md)을(를) **프라이머리** 및 **세컨더리** 사이트에서 수행합니다.
- 문제 해결 속도를 높이려면 [상관 ID 전파 구성](../replication/troubleshooting/common.md#tracing-requests-across-geo-sites)을(를) 수행합니다.

모든 Geo 사이트에 대해 단일 통합 URL을 사용하려면 [통합 URL 구성](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)을(를) 수행해야 합니다.

## GitLab Charts 사용 {#using-gitlab-charts}

[GitLab Geo를 사용하여 GitLab 차트 구성](https://docs.gitlab.com/charts/advanced/geo/).

## Geo 및 자체 컴파일된 설치 {#geo-and-self-compiled-installations}

[자체 컴파일된 GitLab 설치](../../../install/self_compiled/_index.md)를 사용할 때 Geo는 지원되지 않습니다.

## 설치 후 설명서 {#post-installation-documentation}

**세컨더리** 사이트에 GitLab을 설치하고 초기 구성을 수행한 후 [설치 후 정보에 대한 다음 설명서](../_index.md#post-installation-documentation)를 참조하세요.
