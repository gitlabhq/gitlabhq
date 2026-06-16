---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 러너를 설정하고 관리합니다.
title: 러너 시작하기
---

러너 관리는 CI/CD 작업 실행 인프라를 관리하는 전체 수명 주기를 포함합니다:

- 러너 배포 및 등록
- 특정 워크로드에 대한 실행기 구성
- 조직 성장에 맞게 용량 확장

러너 관리 프로세스는 더 큰 워크플로의 일부입니다:

![계획, 생성, 검증(러너 관리 포함), 보안, 릴리스 및 모니터링의 GitLab 워크플로.](img/get_started_runner_v18_3.png)

범위와 태그를 통해 러너 액세스를 관리하고, 성능을 모니터링하고, 러너 플릿을 유지합니다.

## 1단계:  러너 설치 {#step-1-install-runners}

CI/CD 작업을 실행하는 애플리케이션을 만들기 위해 GitLab 러너를 설치합니다.

설치에는 대상 인프라에 러너를 다운로드하고 설정하는 작업이 포함됩니다. 설치 프로세스는 대상 운영 체제에 따라 다릅니다. GitLab은 Linux, Windows, macOS 및 z/OS용 바이너리 및 설치 지침을 제공합니다. 플랫폼과 요구사항을 기반으로 설치 방법을 선택하세요.

자세한 내용은 [러너 설치](https://docs.gitlab.com/runner/install/)를 참조하세요.

## 2단계:  러너 등록 {#step-2-register-runners}

GitLab 인스턴스와 러너가 설치된 머신 간의 인증된 통신을 설정하기 위해 러너를 등록합니다. 등록은 인증 토큰을 사용하여 개별 러너를 GitLab 인스턴스에 연결합니다. 등록 중에 러너의 범위, 실행기 유형 및 러너의 작동 방식을 결정하는 다른 구성 매개변수를 지정합니다.

러너를 등록하기 전에 특정 GitLab 그룹 또는 프로젝트로 제한할지 여부를 결정해야 합니다. 등록 중에 자체 관리 러너를 다양한 액세스 범위로 구성하여 사용 가능한 프로젝트를 결정할 수 있습니다:

- 인스턴스 러너:  GitLab 인스턴스의 모든 프로젝트에서 사용 가능
- 그룹 러너:  특정 그룹의 모든 프로젝트 및 해당 하위 그룹에서 사용 가능
- 프로젝트 러너:  특정 프로젝트에서만 사용 가능

러너를 등록할 때 태그를 추가하여 작업을 적절한 러너로 라우팅합니다. 의미 있는 태그를 지정하고 `.gitlab-ci.yml` 파일에서 참조하여 필요한 기능이 있는 러너에서 작업이 실행되도록 합니다.

CI/CD 작업이 실행되면 지정된 태그를 보고 사용할 러너를 알 수 있습니다. 태그는 작업에 사용 가능한 러너 목록을 필터링하는 유일한 방법입니다.

자세한 정보는 다음을 참조하세요:

- [러너 등록](https://docs.gitlab.com/runner/register/)
- [새로운 러너 등록 워크플로로 마이그레이션](../../ci/runners/new_creation_workflow.md)
- [인스턴스 러너](../../ci/runners/runners_scope.md#instance-runners)
- [그룹 러너](../../ci/runners/runners_scope.md#group-runners)
- [프로젝트 러너](../../ci/runners/runners_scope.md#project-runners)
- [태그](../../ci/yaml/_index.md#tags)

## 3단계:  실행기 선택 {#step-3-choose-executors}

GitLab 러너 실행기는 러너에서 CI/CD 작업을 실행할 수 있는 다양한 환경 및 방법입니다. 파이프라인 작업이 실제로 실행되는 방식과 위치를 결정합니다. 적절한 구성은 작업이 올바른 보안 경계를 가진 적절한 환경에서 실행되도록 보장합니다.

러너를 등록할 때 실행기를 선택해야 합니다. 러너는 실행기 시스템을 사용하여 작업이 실행되는 위치와 방식을 결정합니다. 실행기는 각 작업이 실행되는 환경을 결정합니다. 인프라 및 작업 요구사항과 일치하는 실행기를 선택합니다.

예를 들어:

- CI/CD 작업에서 PowerShell 명령을 실행하려면 Windows 서버에 러너를 설치한 후 쉘 실행기를 사용하는 러너를 등록할 수 있습니다.
- CI/CD 작업에서 사용자 지정 Docker 컨테이너의 명령을 실행하려면 Linux 서버에 러너를 설치한 후 Docker 실행기를 사용하는 러너를 등록할 수 있습니다.

이러한 예제는 가능한 구성의 몇 가지일 뿐입니다. 러너를 가상 머신에 설치하고 다른 가상 머신을 실행기로 사용하도록 할 수 있습니다.

자세한 내용은 [실행기](https://docs.gitlab.com/runner/executors/)를 참조하세요.

## 4단계:  러너 구성 및 작업 실행 시작 {#step-4-configure-runners-and-start-running-jobs}

`config.toml` 파일을 편집하여 러너를 구성할 수 있습니다. 이 파일은 러너를 설치하고 등록할 때 자동으로 생성됩니다. 이 파일에서 특정 러너 또는 모든 러너의 설정을 편집할 수 있습니다. 동시성 제한, 로깅 수준, 캐시 설정, CPU 제한 및 실행기별 매개변수를 설정하도록 구성합니다. 러너 플릿 전체에서 일관된 구성을 사용합니다.

러너가 구성되고 프로젝트에 사용 가능한 상태가 된 후 CI/CD 작업에서 러너를 사용할 수 있습니다.

러너는 일반적으로 러너를 설치한 동일한 머신에서 작업을 처리합니다. 그러나 러너가 컨테이너, Kubernetes 클러스터 또는 클라우드의 자동 확장 인스턴스에서 작업을 처리하도록 할 수도 있습니다.

자세한 정보는 다음을 참조하세요:

- [러너 구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/)
- [CI/CD 작업](../../ci/jobs/_index.md)

## 5단계:  러너 계속 구성, 확장 및 최적화 {#step-5-continue-to-configure-scale-and-optimize-your-runners}

고급 러너 기능은 작업 실행 효율성을 개선하고 복잡한 CI/CD 워크플로를 위한 특화된 기능을 제공합니다. 이러한 최적화는 작업 런타임을 줄이고 자동 크기 조정, 성능 모니터링, 러너 플릿 관리 및 특화된 구성을 통해 개발자 경험을 향상시킵니다.

자동 크기 조정은 작업 수요에 따라 러너 용량을 자동으로 조정하고, 성능 최적화는 효율적인 리소스 활용을 보장합니다. 이러한 기능을 통해 인프라 비용을 제어하면서 변동하는 워크로드를 처리할 수 있습니다.

러너 플릿 관리는 여러 러너를 위한 중앙 집중식 제어 및 모니터링을 제공하여 엔터프라이즈 규모의 러너 배포를 가능하게 합니다. 러너 플릿 확장에는 여러 러너 간 용량 조정 및 운영 모범 사례 구현이 포함됩니다.

내장 Prometheus 메트릭을 사용하여 러너 상태와 성능을 모니터링합니다. 활성 작업 수, CPU 활용률, 메모리 사용량, 작업 성공률 및 큐 길이와 같은 주요 메트릭을 추적하여 러너가 효율적으로 작동하도록 할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [자동 크기 조정 구성](https://docs.gitlab.com/runner/runner_autoscale/)
- [러너 플릿 확장](https://docs.gitlab.com/runner/fleet_scaling/)
- [러너 플릿 구성 및 모범 사례](../../topics/runner_fleet_design_guides/_index.md)
- [러너 성능 모니터링](https://docs.gitlab.com/runner/monitoring/)
- [러너 플릿 대시보드](../../ci/runners/runner_fleet_dashboard.md)
- [롱 폴링](../../ci/runners/long_polling.md)
- [Docker-in-Docker 구성](https://docs.gitlab.com/runner/executors/docker/)
- [러너 인프라 도구 키트(GRIT)](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit)
