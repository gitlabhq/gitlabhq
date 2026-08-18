---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 소프트웨어 아티팩트 공급망 수준(SLSA)
---

[소프트웨어 아티팩트 공급망 수준(SLSA)](https://slsa.dev/)는 "살사(salsa)"로 발음되며 업계의 합의로 정립된 공급망 보안을 위한 점진적으로 채택 가능한 지침의 집합입니다. 표준은 아티팩트 생산자, 검증자, 소비자, 인프라 제공자의 측면에서 정의됩니다.

인프라 제공자로서 GitLab은 사용자가 컨테이너 및 아티팩트와 관련된 메타데이터를 안전하게 생성할 수 있는 도구를 제공합니다. 또한 GitLab은 이 메타데이터를 검증하고 안전하게 사용하여 공급망을 강화하고 일부 공격 유형을 방지하는 메커니즘을 제공합니다.

## SLSA 수준 {#slsa-levels}

GitLab은 여러 수준에서 SLSA 사양을 준수하는 생성 증명(provenance)을 생성할 수 있습니다. 특정 수준을 달성하려면 특정 기준에 대한 자체 평가가 필요합니다.

자세한 정보는 SLSA [빌드: 추적 기본](https://slsa.dev/spec/v1.2/build-track-basics) 페이지를 참조하세요.

### 수준 1: 패키지 빌드 방법을 보여주는 생성 증명 {#level-1-provenance-showing-how-the-package-was-built}

SLSA 수준 1은 아티팩트가 빌드된 방식을 설명하는 자동으로 생성된 생성 증명이 필요하며, 다음을 포함합니다:

- 패키지를 빌드한 엔티티.
- 사용된 빌드 프로세스.
- 빌드에 대한 최상위 입력.

### 수준 2: 호스팅된 빌드 플랫폼에서 생성되는 서명된 생성 증명 {#level-2-signed-provenance-generated-by-a-hosted-build-platform}

SLSA 수준 2는 수준 1과 동일한 요구사항이 있지만 추가로 호스팅된 빌드 플랫폼이 생성된 생성 증명에 서명하도록 요구합니다. 서명은 다음과 같이 수행될 수 있습니다:

- 원본 빌드.
- 사후 재현 가능한 빌드.
- 생성 증명의 신뢰성을 보장하는 동등한 시스템.

GitLab은 [GitLab 러너에서 생성하는 모든 작업 아티팩트에 대해 자동으로 생성할 수 있는](../../runners/configure_runners.md#artifact-provenance-metadata) SLSA 수준 2 준수 생성 증명 명세를 제공합니다. 이 생성 증명 명세는 수준 1도 준수하며 러너 자체에서 생성됩니다.

이 수준에서 SLSA를 구현하면 많은 이점이 있습니다:

- 조직이 소프트웨어 및 빌드 플랫폼의 인벤토리를 만들 수 있도록 지원합니다.
- 디지털 서명을 통한 변조 방지.
- 공격 표면을 특정 빌드 플랫폼으로 감소합니다.

#### CI/CD 구성 요소를 사용하여 SLSA 생성 증명에 서명하고 검증 {#sign-and-verify-slsa-provenance-with-a-cicd-component}

[GitLab SLSA CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/slsa)는 다음에 대한 구성을 제공합니다:

- 러너 생성 증명 명세에 서명합니다.
- [검증 요약 증명(VSA)](https://slsa.dev/spec/v1.0/verification_summary)을 작업 아티팩트에 대해 생성합니다.

자세한 정보 및 예제 구성은 [SLSA 구성 요소 설명서](https://gitlab.com/components/slsa#slsa-supply-chain-levels-for-software-artifacts)를 참조하세요.

### 수준 3, 강화된 빌드 플랫폼 {#level-3-hardened-build-platform}

SLSA 수준 3은 수준 1과 2의 모든 요구사항을 구현하고 생성 증명에 대한 변조를 방지합니다. 예를 들어, 빌드 프로세스 자체를 손상시킨 공격자에 의한 변조를 방지하여.

이 증가된 변조 저항은 다음에서 비롯됩니다:

- 증가된 러너 격리.
- 사용자 정의 빌드 단계를 실행하는 환경에서 비밀 자료에 액세스할 수 없는지 확인합니다.
- 생성 증명의 모든 필드가 신뢰할 수 있는 제어 영역에서 빌드 플랫폼에 의해 생성되거나 검증되는지 확인합니다.

자세한 정보는 [SLSA 수준 3 페이지](level_3/_index.md) 및 [SLSA 생성 증명 사양](level_3/provenance_v1.md)을 참조하세요.
