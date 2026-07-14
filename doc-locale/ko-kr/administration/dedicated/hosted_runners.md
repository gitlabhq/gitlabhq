---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 호스팅된 러너를 사용하여 GitLab Dedicated에서 CI/CD 작업을 실행합니다.
title: GitLab Dedicated 호스팅되는 러너
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated
- 상태:  제한된 가용성

{{< /details >}}

> [!note]
> 이 기능을 사용하려면 GitLab Dedicated의 호스팅된 러너에 대한 구독을 구매해야 합니다. GitLab Dedicated의 호스팅된 러너 제한 제공에 참여하려면 담당 Customer Success Manager 또는 계정 담당자에게 문의하세요.

GitLab 호스팅 [러너](../../ci/runners/_index.md)에서 CI/CD 작업을 실행할 수 있습니다. 이 러너는 GitLab에서 관리되며 GitLab Dedicated 인스턴스와 완벽하게 통합됩니다. GitLab 호스팅 Dedicated용 러너는 [인스턴스 러너](../../ci/runners/runners_scope.md#instance-runners)를 자동 크기 조정하며, GitLab Dedicated 인스턴스와 같은 리전의 AWS EC2에서 실행됩니다.

호스팅된 러너를 사용할 때:

- 각 작업은 새로 프로비저닝된 가상 머신(VM)에서 실행되며, 이는 특정 작업에 전용입니다.
- 작업이 실행되는 VM에는 암호 없이 `sudo` 액세스 권한이 있습니다.
- 스토리지는 운영 체제, 사전 설치된 소프트웨어가 포함된 이미지, 복제된 리포지토리의 복사본으로 공유됩니다. 이는 작업에 사용 가능한 여유 디스크 공간이 감소함을 의미합니다.
- 기본적으로 태그가 없는 작업은 소형 Linux x86-64 러너에서 실행됩니다. GitLab 관리자는 [GitLab에서 태그가 없는 작업 실행 옵션을 변경](#configure-hosted-runners-in-gitlab)할 수 있습니다.

## Linux의 호스팅된 러너 {#hosted-runners-on-linux}

GitLab Dedicated의 Linux 호스팅된 러너는 [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler/) 실행기를 사용합니다. 각 작업은 완전히 격리된 임시 가상 머신(VM)에서 Docker 환경을 가져오며 최신 버전의 Docker Engine에서 실행됩니다.

### Linux - x86-64용 머신 타입 {#machine-types-for-linux---x86-64}

다음 머신 타입은 Linux x86-64 호스팅된 러너에 사용할 수 있습니다.

| 크기     | 러너 태그                    | vCPU | 메모리 | 스토리지 |
|----------|-------------------------------|-------|--------|---------|
| 소형    | `linux-small-amd64`(기본값) | 2     | 8 GB   | 30 GB   |
| 중형   | `linux-medium-amd64`          | 4     | 16 GB  | 50 GB   |
| 대형    | `linux-large-amd64`           | 8     | 32 GB  | 100 GB  |
| 초대형  | `linux-xlarge-amd64`          | 16    | 64 GB  | 200 GB  |
| 2배 대형 | `linux-2xlarge-amd64`         | 32    | 128 GB | 200 GB  |

### Linux - Arm64용 머신 타입 {#machine-types-for-linux---arm64}

다음 머신 타입은 Linux Arm64 호스팅된 러너에 사용할 수 있습니다.

| 크기     | 러너 태그            | vCPU | 메모리 | 스토리지 |
|----------|-----------------------|-------|--------|---------|
| 소형    | `linux-small-arm64`   | 2     | 8 GB   | 30 GB   |
| 중형   | `linux-medium-arm64`  | 4     | 16 GB  | 50 GB   |
| 대형    | `linux-large-arm64`   | 8     | 32 GB  | 100 GB  |
| 초대형  | `linux-xlarge-arm64`  | 16    | 64 GB  | 200 GB  |
| 2배 대형 | `linux-2xlarge-arm64` | 32    | 128 GB | 200 GB  |

> [!note]
> 머신 타입 및 기본 프로세서 타입이 변경될 수 있습니다. 특정 프로세서 설계에 최적화된 작업은 일관성 없게 동작할 수 있습니다.

기본 러너 태그는 생성 시 할당됩니다. 관리자는 인스턴스 러너에 대해 [태그 설정을 수정](#configure-hosted-runners-in-gitlab)할 수 있습니다.

### 컨테이너 이미지 {#container-images}

Linux의 러너가 [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler/) 실행기를 사용하므로 `.gitlab-ci.yml` 파일에서 이미지를 정의하여 모든 컨테이너 이미지를 선택할 수 있습니다. 선택한 Docker 이미지가 기본 프로세서 아키텍처와 호환되는지 확인하세요. [`.gitlab-ci.yml` 파일 예제](../../ci/runners/hosted_runners/linux.md#example-gitlab-ciyml-file)를 참조하세요.

이미지가 설정되지 않으면 기본값은 `ruby:3.1`입니다.

Docker Hub 컨테이너 레지스트리의 이미지를 사용하면 [속도 제한](../settings/user_and_ip_rate_limits.md)에 걸릴 수 있습니다. 이는 GitLab Dedicated가 단일 NAT(Network Address Translation) IP 주소를 사용하기 때문입니다.

속도 제한을 피하려면 대신 다음을 사용하세요:

- [컨테이너 레지스트리](../../user/packages/container_registry/_index.md)에 저장된 이미지입니다.
- 속도 제한이 없는 다른 공개 레지스트리에 저장된 이미지입니다.
- 풀스루 캐시 역할을 하는 [종속성 프록시](../../user/packages/dependency_proxy/_index.md)입니다.

### Docker in Docker 지원 {#docker-in-docker-support}

러너는 `privileged` 모드에서 실행되도록 구성되어 [Docker in Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker)를 지원하여 Docker 이미지를 기본적으로 빌드하거나 격리된 작업 내에서 여러 컨테이너를 실행합니다.

## 호스팅된 러너 관리 {#manage-hosted-runners}

### Switchboard에서 호스팅된 러너 관리 {#manage-hosted-runners-in-switchboard}

Switchboard를 사용하여 GitLab Dedicated 인스턴스의 호스팅된 러너를 생성하고 볼 수 있습니다.

전제 조건:

- GitLab Dedicated의 호스팅된 러너에 대한 구독을 구매해야 합니다.

#### Switchboard에서 호스팅된 러너 생성 {#create-hosted-runners-in-switchboard}

각 인스턴스에서는 각 유형 및 크기 조합의 러너 하나를 생성할 수 있습니다. Switchboard는 사용 가능한 러너 옵션을 표시합니다.

호스팅된 러너를 생성하려면:

1. [Switchboard](https://console.gitlab-dedicated.com)에 로그인합니다.
1. 페이지 상단에서 **Hosted runners**를 선택합니다.
1. **New hosted runner**를 선택합니다.
1. 러너의 크기를 선택한 후 **Create hosted runner**를 선택합니다.

호스팅된 러너를 사용할 준비가 되면 이메일 알림을 받습니다.

기존 러너에 대해 구성된 [Outbound PrivateLink 연결](#outbound-privatelink-connections)은 새 러너에 적용되지 않습니다. 새 러너마다 별도의 요청이 필요합니다.

#### Switchboard에서 호스팅된 러너 보기 {#view-hosted-runners-in-switchboard}

호스팅된 러너를 보려면:

1. [Switchboard](https://console.gitlab-dedicated.com)에 로그인합니다.
1. 페이지 상단에서 **Hosted runners**를 선택합니다.
1. 선택사항. 호스팅된 러너 목록에서 GitLab에서 액세스하려는 러너의 **Runner ID**를 복사합니다.

### GitLab에서 호스팅된 러너 보기 및 구성 {#view-and-configure-hosted-runners-in-gitlab}

GitLab 관리자는 [**운영자** 영역](../admin_area.md#administering-runners)에서 GitLab Dedicated 인스턴스의 호스팅된 러너를 관리할 수 있습니다.

#### GitLab에서 호스팅된 러너 보기 {#view-hosted-runners-in-gitlab}

Runners 페이지 및 [플릿 대시보드](../../ci/runners/runner_fleet_dashboard.md)에서 GitLab Dedicated 인스턴스의 호스팅된 러너를 볼 수 있습니다.

전제 조건:

- 관리자여야 합니다.

> [!note]
> 계산 사용량 시각화는 사용할 수 없지만 일반 가용성을 위해 추가할 [에픽](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524)이 있습니다.

GitLab에서 호스팅된 러너를 보려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 선택사항. **플릿 대시보드**를 선택합니다.

#### GitLab에서 호스팅된 러너 구성 {#configure-hosted-runners-in-gitlab}

전제 조건:

- 관리자여야 합니다.

GitLab Dedicated 인스턴스의 호스팅된 러너를 구성할 수 있으며 러너 태그의 기본값을 변경할 수 있습니다.

사용 가능한 구성 옵션은 다음과 같습니다:

- [최대 작업 시간 초과 변경](../../ci/runners/configure_runners.md#for-an-instance-runner)합니다.
- [태그가 있거나 태그가 없는 작업을 실행하도록 러너 설정](../../ci/runners/configure_runners.md#for-an-instance-runner-2)합니다.

> [!note]
> 러너 설명 및 러너 태그에 대한 모든 변경 사항은 GitLab에서 제어하지 않습니다.

### GitLab에서 그룹 또는 프로젝트의 호스팅된 러너 비활성화 {#disable-hosted-runners-for-groups-or-projects-in-gitlab}

기본적으로 호스팅된 러너는 GitLab Dedicated 인스턴스의 모든 프로젝트 및 그룹에서 사용할 수 있습니다. GitLab 유지관리자는 [프로젝트](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-project) 또는 [그룹](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-group)에 대해 호스팅된 러너를 비활성화할 수 있습니다.

## 보안 및 네트워크 {#security-and-network}

GitLab Dedicated의 호스팅된 러너는 러너 빌드 환경의 보안을 강화하는 기본 제공 계층이 있습니다.

GitLab Dedicated의 호스팅된 러너는 다음 구성을 가집니다:

- 방화벽 규칙은 임시 VM에서 공개 인터넷으로의 아웃바운드 통신만 허용합니다.
- 방화벽 규칙은 공개 인터넷에서 임시 VM으로의 인바운드 통신을 허용하지 않습니다.
- 방화벽 규칙은 VM 간 통신을 허용하지 않습니다.
- 러너 관리자만 임시 VM과 통신할 수 있습니다.
- 임시 러너 VM은 단일 작업만 제공하며 작업 실행 후 삭제됩니다.

호스팅된 러너에서 AWS 계정으로의 [PrivateLink 연결을 활성화](#outbound-privatelink-connections)할 수도 있습니다.

자세한 내용은 [GitLab Dedicated의 호스팅된 러너](architecture.md#hosted-runners-for-gitlab-dedicated)에 대한 아키텍처 다이어그램을 참조하세요.

### 아웃바운드 PrivateLink 연결 {#outbound-privatelink-connections}

Outbound PrivateLink 연결은 GitLab Dedicated의 호스팅된 러너와 AWS VPC의 서비스 간에 안전한 연결을 생성합니다. 이 연결은 공개 인터넷에 트래픽을 노출하지 않으며 호스팅된 러너가 다음을 수행할 수 있습니다:

- 사용자 지정 비밀 관리자와 같은 개인 서비스에 액세스합니다.
- 인프라에 저장된 아티팩트 또는 작업 이미지를 검색합니다.
- 인프라에 배포합니다.

두 개의 Outbound PrivateLink 연결은 GitLab 관리 러너 계정의 모든 러너에 대해 기본적으로 존재합니다:

- GitLab 인스턴스로의 연결
- GitLab 제어 Prometheus 인스턴스로의 연결

이 연결은 사전 구성되어 있으며 수정할 수 없습니다. 테넌트의 Prometheus 인스턴스는 GitLab에서 관리되며 사용자가 액세스할 수 없습니다.

호스팅된 러너에 대해 다른 VPC 서비스와 함께 Outbound PrivateLink 연결을 사용하려면 [지원 요청을 통한 수동 구성이 필요합니다](configure_instance/network_security.md#add-an-outbound-privatelink-connection). 자세한 내용은 [Outbound PrivateLink 연결](configure_instance/network_security.md#outbound-privatelink-connections)을 참조하세요.

### IP 범위 {#ip-ranges}

GitLab Dedicated의 호스팅된 러너에 대한 IP 범위는 요청 시 사용할 수 있습니다. IP 범위는 최선의 노력으로 유지되며 인프라 변경으로 인해 언제든지 변경될 수 있습니다. 자세한 내용은 담당 Customer Success Manager 또는 계정 담당자에게 문의하세요.

## 호스팅된 러너 사용 {#use-hosted-runners}

[Switchboard에서 호스팅된 러너를 생성](#create-hosted-runners-in-switchboard)한 후 러너를 사용할 준비가 되면 사용할 수 있습니다.

러너를 사용하려면 `.gitlab-ci.yml` 파일의 작업 구성에서 [태그](../../ci/yaml/_index.md#tags)를 조정하여 사용하려는 호스팅된 러너와 일치하도록 합니다.

Linux 중형 x86-64 러너의 경우 다음과 같이 작업을 구성합니다:

   ```yaml
   job_name:
     tags:
       - linux-medium-amd64  # Use the medium-sized Linux runner
   ```

기본적으로 태그가 없는 작업은 소형 Linux x86-64 러너에서 선택됩니다. GitLab 관리자는 태그가 없는 작업을 실행하지 않도록 [GitLab에서 인스턴스 러너를 구성](#configure-hosted-runners-in-gitlab)할 수 있습니다.

작업 구성을 변경하지 않고 작업을 마이그레이션하려면 기존 작업 구성에서 사용되는 태그와 일치하도록 [호스팅된 러너 태그를 수정](#configure-hosted-runners-in-gitlab)합니다.

작업이 오류 메시지 `no runners that match all of the job's tags`로 인해 멈춰 있는 것을 보면:

1. 올바른 태그를 선택했는지 확인합니다
1. [인스턴스 러너가 프로젝트 또는 그룹에서 활성화되어 있는지 확인합니다](../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project).

## 업그레이드 {#upgrades}

러너 버전 업그레이드는 짧은 다운타임이 필요합니다. 러너는 GitLab Dedicated 테넌트의 예약된 유지보수 창 중에 업그레이드됩니다. [이슈](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4505)는 다운타임 없는 업그레이드를 구현하기 위해 존재합니다.

## 가격 {#pricing}

가격 세부 정보는 계정 담당자에게 문의하세요.

GitLab Dedicated 고객을 위해 30일 무료 평가판을 제공합니다. 평가판에 포함된 사항:

- 소형, 중형, 대형 Linux x86-64 러너
- 소형 및 중형 Linux Arm 러너
- 최대 100개의 동시 작업을 지원하는 제한된 자동 크기 조정 구성
