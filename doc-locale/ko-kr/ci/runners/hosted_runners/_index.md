---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 호스팅 러너
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Dedicated

{{< /details >}}

GitLab 호스팅 러너를 사용하여 GitLab.com 및 GitLab Dedicated에서 CI/CD 작업을 실행합니다. 이러한 러너는 다양한 환경에서 애플리케이션을 빌드하고, 테스트하고, 배포할 수 있습니다.

자체 러너를 생성하고 등록하려면 [자체 관리 러너](https://docs.gitlab.com/runner/)를 참조하세요.

## GitLab.com용 호스팅 러너 {#hosted-runners-for-gitlabcom}

{{< details >}}

- 제공 서비스: GitLab.com

{{< /details >}}

이러한 러너는 GitLab.com과 완전히 통합되어 있으며 모든 프로젝트에 대해 기본적으로 활성화되어 있으며 구성이 필요하지 않습니다. 작업은 다음에서 실행할 수 있습니다:

- [Linux의 호스팅 러너](linux.md)
- [GPU 지원 호스팅 러너](gpu_enabled.md)
- [Windows의 호스팅 러너](windows.md)([베타](../../../policy/development_stages_support.md#beta))
- [macOS의 호스팅 러너](macos.md)([베타](../../../policy/development_stages_support.md#beta))

### GitLab.com 호스팅 러너 워크플로우 {#gitlabcom-hosted-runner-workflow}

호스팅 러너를 사용할 때:

- 각 작업은 새로 프로비저닝된 VM에서 실행되며, 이는 특정 작업에만 전용됩니다.
- 작업이 실행되는 가상 머신은 `sudo` 액세스가 암호 없이 제공됩니다.
- 스토리지는 운영 체제, 사전 설치된 소프트웨어가 포함된 컨테이너 이미지, 그리고 복제된 리포지토리의 복사본으로 공유됩니다. 즉, 작업이 사용할 수 있는 사용 가능한 무료 디스크 공간이 줄어듭니다.
- [태그 없음](../../yaml/_index.md#tags) 작업은 `small` Linux x86-64 러너에서 실행됩니다.

> [!note]
> GitLab.com의 호스팅 러너에서 처리한 작업은 프로젝트에 설정된 타임아웃과 관계없이 3시간 후에 타임아웃됩니다.

### GitLab.com용 호스팅 러너의 보안 {#security-of-hosted-runners-for-gitlabcom}

다음 섹션에서는 GitLab Runner 빌드 환경의 보안을 강화하는 추가 기본 제공 계층의 개요를 제공합니다.

GitLab.com용 호스팅 러너는 다음과 같이 구성됩니다:

- 방화벽 규칙은 임시 VM에서 공개 인터넷으로의 아웃바운드 통신만 허용합니다.
- 공개 인터넷에서 임시 VM으로의 인바운드 통신은 허용되지 않습니다.
- 방화벽 규칙은 VM 간 통신을 허용하지 않습니다.
- 임시 VM으로 허용되는 유일한 내부 통신은 러너 관리자에서입니다.
- 임시 러너 VM은 단일 작업을 수행하고 작업 실행 직후 삭제됩니다.

#### GitLab.com용 호스팅 러너의 아키텍처 다이어그램 {#architecture-diagram-of-hosted-runners-for-gitlabcom}

다음 그래픽은 GitLab.com용 호스팅 러너의 아키텍처 다이어그램을 보여줍니다.

![GitLab.com 호스팅 러너 아키텍처](img/gitlab-hosted_runners_architecture_v17_0.png)

러너가 인증하고 작업 페이로드를 실행하는 방법에 대한 자세한 내용은 [러너 실행 흐름](https://docs.gitlab.com/runner/#runner-execution-flow)을 참조하세요.

#### GitLab.com용 호스팅 러너의 작업 격리 {#job-isolation-of-hosted-runners-for-gitlabcom}

네트워크에서 러너를 격리하는 것 외에도, 각 임시 러너 VM은 단일 작업만 수행하고 작업 실행 직후 삭제됩니다. 다음 예시에서는 프로젝트의 파이프라인에서 세 개의 작업이 실행됩니다. 이러한 각 작업은 전용 임시 VM에서 실행됩니다.

![별도의 격리된 VM에서 실행되는 CI/CD 파이프라인 스테이지: 빌드, 테스트, 배포](img/build_isolation_v17_9.png)

빌드 작업은 `runner-ns46nmmj-project-43717858`에서 실행되었고, 테스트 작업은 `f131a6a2runner-new2m-od-project-43717858`에서 실행되었으며, 배포 작업은 `runner-tmand5m-project-43717858`에서 실행되었습니다.

GitLab은 CI 작업이 완료된 직후 임시 러너 VM을 제거하는 명령을 Google Compute API에 보냅니다. [Google Compute Engine 하이퍼바이저](https://cloud.google.com/blog/products/gcp/7-ways-we-harden-our-kvm-hypervisor-at-google-cloud-security-in-plaintext)는 가상 머신 및 관련 데이터를 안전하게 삭제하는 작업을 처리합니다.

GitLab.com용 호스팅 러너의 보안에 대한 자세한 내용은 다음을 참조하세요:

- [Google Cloud Infrastructure Security Design Overview 백서](https://cloud.google.com/docs/security/infrastructure/design/resources/google_infrastructure_whitepaper_fa.pdf)
- [GitLab Trust Center](https://about.gitlab.com/security/)
- GitLab 보안 규정 준수 제어

### GitLab.com용 호스팅 러너의 캐싱 {#caching-on-hosted-runners-for-gitlabcom}

호스팅 러너는 Google Cloud Storage(GCS) 버킷에 저장된 [분산 캐시](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching)를 공유합니다. 지난 14일 동안 업데이트되지 않은 캐시 콘텐츠는 [개체 수명 주기 관리 정책](https://cloud.google.com/storage/docs/lifecycle)을 기반으로 자동으로 제거됩니다. 업로드된 캐시 아티팩트의 최대 크기는 캐시가 압축 아카이브가 된 후 5GB일 수 있습니다.

캐싱 작동 방식에 대한 자세한 내용은 [GitLab.com용 호스팅 러너의 아키텍처 다이어그램](#architecture-diagram-of-hosted-runners-for-gitlabcom) 및 [GitLab CI/CD의 캐싱](../../caching/_index.md)을 참조하세요.

### GitLab.com용 호스팅 러너의 가격 {#pricing-of-hosted-runners-for-gitlabcom}

GitLab.com용 호스팅 러너에서 실행되는 작업은 네임스페이스에 할당된 [컴퓨팅 분](../../pipelines/compute_minutes.md)을 소비합니다. 이러한 러너에서 사용할 수 있는 분의 수는 [구독 요금제](https://about.gitlab.com/pricing/)에 포함된 컴퓨팅 분 또는 [추가로 구매한 컴퓨팅 분](../../../subscriptions/gitlab_com/compute_minutes.md)에 따라 달라집니다.

크기에 따라 머신 유형에 적용되는 비용 계수에 대한 자세한 내용은 [비용 계수](../../pipelines/compute_minutes.md#cost-factors-of-hosted-runners-for-gitlabcom)를 참조하세요.

### GitLab.com용 호스팅 러너의 SLO 및 릴리스 주기 {#slo--release-cycle-for-hosted-runners-for-gitlabcom}

SLO 목표는 CI/CD 작업의 90%가 120초 이내에 실행을 시작하도록 하는 것입니다. 오류율은 0.5% 미만이어야 합니다.

GitLab은 최신 버전의 [GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions)로 업데이트하는 것을 릴리스 후 1주일 내에 수행할 목표를 두고 있습니다. 모든 GitLab Runner 주요 변경 사항은 [지원 중단 및 제거](../../../update/deprecations.md)에서 찾을 수 있습니다.

## GitLab 커뮤니티 기여를 위한 호스팅 러너 {#hosted-runners-for-gitlab-community-contributions}

{{< details >}}

- 제공 서비스: GitLab.com

{{< /details >}}

[GitLab에 기여](https://about.gitlab.com/community/contribute/)하려는 경우, 작업은 GitLab 프로젝트 및 관련 커뮤니티 포크를 위해 전담하는 `gitlab-shared-runners-manager-X.gitlab.com` 플릿의 러너에서 선택됩니다.

이러한 러너는 당사의 `small` Linux x86-64 러너와 동일한 머신 유형으로 지원됩니다. GitLab.com의 호스팅 러너와 달리, GitLab 커뮤니티 기여를 위한 호스팅 러너는 최대 40번까지 재사용됩니다.

모든 사람이 기여하도록 권장되므로, 이러한 러너는 무료입니다.

## GitLab Dedicated용 호스팅 러너 {#hosted-runners-for-gitlab-dedicated}

{{< details >}}

- 제공 서비스: GitLab Dedicated

{{< /details >}}

GitLab Dedicated용 호스팅 러너는 필요에 따라 생성되며 GitLab Dedicated 인스턴스와 완전히 통합됩니다. 자세한 내용은 [GitLab Dedicated용 호스팅 러너](../../../administration/dedicated/hosted_runners.md)를 참조하세요.

## 지원되는 이미지 수명 주기 {#supported-image-lifecycle}

macOS 및 Windows의 호스팅 러너는 지원되는 이미지에서만 작업을 실행할 수 있습니다. 자신의 이미지를 가져올 수 없습니다. 지원되는 이미지는 다음과 같은 수명 주기를 갖습니다:

### 베타 {#beta}

새 이미지는 베타로 릴리스됩니다. 이를 통해 일반 공급 전에 피드백을 수집하고 잠재적 문제를 해결할 수 있습니다. 베타 이미지에서 실행 중인 모든 작업은 서비스 수준 계약에 의해 보장되지 않습니다. 베타 이미지를 사용하는 경우, 이슈를 생성하여 피드백을 제공할 수 있습니다.

### 일반 공급 {#general-availability}

이미지는 베타 단계를 완료한 후 일반적으로 사용 가능하게 되고 안정적인 것으로 간주됩니다. 일반 공급이 되기 위해 이미지는 다음 요구 사항을 충족해야 합니다:

- 보고된 모든 중요한 버그를 해결하여 베타 단계 완료
- 설치된 소프트웨어와 기본 OS의 호환성

일반적으로 사용 가능한 이미지에서 실행되는 작업은 정의된 서비스 수준 계약에 의해 보장됩니다.

### 지원 중단 {#deprecated}

최대 2개의 일반적으로 사용 가능한 이미지가 한 번에 지원됩니다. 새로운 일반적으로 사용 가능한 이미지가 릴리스된 후, 가장 오래된 일반적으로 사용 가능한 이미지는 지원 중단됩니다. 지원 중단된 이미지는 더 이상 업데이트되지 않으며 3개월 후에 삭제됩니다.

## 사용 데이터 {#usage-data}

GitLab Dedicated에서 GitLab 호스팅 러너 사용량의 컴퓨팅 분에 대한 [예상치를 볼 수](../../pipelines/dedicated_hosted_runner_compute_minutes.md) 있습니다.
