---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 일련의 다이어그램을 통해 GitLab Dedicated 아키텍처를 알아봅니다.
title: GitLab Dedicated 아키텍처
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

이 페이지는 GitLab Dedicated에 대한 아키텍처 문서 및 다이어그램을 제공합니다.

## 상위 수준 개요 {#high-level-overview}

다음 다이어그램은 GitLab Dedicated의 아키텍처 상위 수준 개요를 보여주며, GitLab과 고객이 관리하는 다양한 AWS 계정은 Switchboard 애플리케이션으로 제어됩니다.

![GitLab Dedicated 아키텍처의 상위 수준 개요 다이어그램입니다.](img/high_level_architecture_diagram_v18_0.png)

GitLab Dedicated 테넌트 인스턴스를 관리할 때:

- Switchboard는 AWS 클라우드 공급자 간 공유되는 글로벌 구성 관리를 담당하며, 테넌트가 액세스할 수 있습니다.
- Amp는 고객 테넌트 계정과의 상호작용을 담당하며, 예상 역할 및 정책 구성, 필요한 서비스 활성화, 환경 프로비저닝 등을 수행합니다.

편집 액세스 권한이 있는 GitLab 팀 멤버는 Lucidchart에서 다이어그램의 [소스](https://lucid.app/lucidchart/e0b6661c-6c10-43d9-8afa-1fe0677e060c/edit?page=0_0#) 파일을 업데이트할 수 있습니다.

## 테넌트 네트워크 {#tenant-network}

고객 테넌트 계정은 단일 AWS 클라우드 공급자 계정입니다. 단일 계정은 자체 VPC에서 완전한 테넌시 격리를 제공하며, 고유한 리소스 할당량을 포함합니다.

클라우드 공급자 계정은 자체 격리된 VPC에서 매우 탄력적인 GitLab 설치가 존재하는 위치입니다. 프로비저닝 시 고객 테넌트는 고가용성(HA) GitLab 주 사이트와 GitLab Geo 보조 사이트에 액세스할 수 있습니다.

![격리된 VPC에 있으며 매우 탄력적인 GitLab 설치를 포함하는 GitLab 관리 AWS 계정의 다이어그램입니다.](img/tenant_network_diagram_v18_0.png)

편집 액세스 권한이 있는 GitLab 팀 멤버는 Lucidchart에서 다이어그램의 [소스](https://lucid.app/lucidchart/0815dd58-b926-454e-8354-c33fe3e7bff0/edit?invitationId=inv_a6b618ff-6c18-4571-806a-bfb3fe97cb12) 파일을 업데이트할 수 있습니다.

### Gitaly 설정 {#gitaly-setup}

GitLab Dedicated는 Gitaly를 [분할된 설정](../gitaly/praefect/_index.md#before-deploying-gitaly-cluster-praefect)으로 배포하며, Gitaly Cluster(Praefect) 구성이 아닙니다.

- 고객 리포지토리는 여러 가상 머신 전체에 분산되어 있습니다.
- GitLab은 고객을 대신하여 저장소 가중치를 관리합니다.

### Geo 설정 {#geo-setup}

GitLab Dedicated는 [재해 복구](disaster_recovery.md)를 위해 Geo를 활용합니다.

Geo는 활성-활성 장애 조치 구성을 사용하지 않습니다. 자세한 내용은 [Geo](../geo/_index.md)를 참조하세요.

### AWS PrivateLink 연결 {#aws-privatelink-connection}

> [!note]
> Geo 마이그레이션을 Dedicated로 수행하는 데 필요합니다. 그 외에는 선택 사항입니다.

선택적으로, GitLab Dedicated 인스턴스의 경우 [AWS PrivateLink](https://aws.amazon.com/privatelink/)를 연결 게이트웨이로 사용하여 개인 연결성을 사용할 수 있습니다.

[인바운드](configure_instance/network_security.md#inbound-privatelink-connections) 와 [아웃바운드](configure_instance/network_security.md#outbound-privatelink-connections) PrivateLink 연결이 모두 지원됩니다.

#### 인바운드 {#inbound}

![GitLab 관리 AWS VPC가 인바운드 AWS PrivateLink를 사용하여 고객 관리 AWS VPC와 연결하는 다이어그램입니다.](img/privatelink_inbound_v18_0.png)

편집 액세스 권한이 있는 GitLab 팀 멤버는 Lucidchart에서 다이어그램의 [소스](https://lucid.app/lucidchart/933b958b-bfad-4898-a8ae-182815f159ca/edit?invitationId=inv_38b9a265-dff2-4db6-abdb-369ea1e92f5f) 파일을 업데이트할 수 있습니다.

#### 아웃바운드 {#outbound}

![GitLab 관리 AWS VPC가 아웃바운드 AWS PrivateLink를 사용하여 고객 관리 AWS VPC와 연결하는 다이어그램입니다.](img/privatelink_outbound_v18_0.png)

편집 액세스 권한이 있는 GitLab 팀 멤버는 Lucidchart에서 다이어그램의 [소스](https://lucid.app/lucidchart/5aeae97e-a3c4-43e3-8b9d-27900d944147/edit?invitationId=inv_0e4fee9f-cf63-439c-9bf9-71ecbfbd8979&page=F5pcfQybsAYU8#) 파일을 업데이트할 수 있습니다.

#### 마이그레이션을 위한 AWS PrivateLink {#aws-privatelink-for-migration}

또한 AWS PrivateLink는 마이그레이션 목적으로도 사용됩니다. 고객의 Dedicated GitLab 인스턴스는 AWS PrivateLink를 사용하여 GitLab Dedicated로의 마이그레이션을 위한 데이터를 가져올 수 있습니다.

![간소화된 Dedicated Geo 설정의 다이어그램입니다.](img/dedicated_geo_simplified_v18_0.png)

편집 액세스 권한이 있는 GitLab 팀 멤버는 Lucidchart에서 다이어그램의 [소스](https://lucid.app/lucidchart/1e83e102-37b3-48a9-885d-e72122683bce/edit?view_items=AzvnMfovRJe3p&invitationId=inv_c02140dd-416b-41b5-b14a-7288b54bb9b5) 파일을 업데이트할 수 있습니다.

## GitLab Dedicated용 호스팅되는 러너 {#hosted-runners-for-gitlab-dedicated}

다음 다이어그램은 GitLab Dedicated 인스턴스, 공인 인터넷 및 선택적으로 AWS PrivateLink를 사용하는 고객 AWS 계정에 상호 연결된 GitLab 러너를 포함하는 GitLab 관리 AWS 계정을 보여줍니다.

![GitLab Dedicated용 호스팅되는 러너 아키텍처의 다이어그램입니다.](img/hosted-runners-architecture_v17_3.png)

러너가 작업 페이로드를 인증하고 실행하는 방식에 대한 자세한 내용은 [러너 실행 플로우](https://docs.gitlab.com/runner/#runner-execution-flow)를 참조하세요.

편집 액세스 권한이 있는 GitLab 팀 멤버는 Lucidchart에서 다이어그램의 [소스](https://lucid.app/lucidchart/0fb12de8-5236-4d80-9a9c-61c08b714e6f/edit?invitationId=inv_4a12e347-49e8-438e-a28f-3930f936defd) 파일을 업데이트할 수 있습니다.
