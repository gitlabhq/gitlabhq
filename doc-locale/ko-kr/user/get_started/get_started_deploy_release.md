---
stage: none
group: none
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 배포 및 의존성 관리
title: 애플리케이션 배포 및 릴리스 시작하기
---

애플리케이션 미리보기부터 시작해서 프로덕션으로 배포하여 실제 사용자에게 서비스하는 것까지 포함합니다. 컨테이너 및 패키지를 관리하고, 지속적 통합을 사용하여 애플리케이션을 제공하고, 기능 플래그 및 점진적 롤아웃을 사용하여 통제된 환경에서 애플리케이션을 릴리스합니다.

이러한 프로세스는 더 큰 워크플로우의 일부입니다:

!["애플리케이션 배포 및 릴리스" 섹션이 강조 표시된 GitLab에서 수행할 주요 작업 다이어그램.](img/get_started_release_v16_11.png)

## 1단계:  프로젝트의 아티팩트 저장 및 액세스 {#step-1-store-and-access-your-projects-artifacts}

패키지와 레지스트리를 사용하여 프로젝트의 의존성, 라이브러리 및 기타 아티팩트를 GitLab에 안전하게 저장하고 배포합니다.

패키지 레지스트리는 Maven, NPM, NuGet, PyPI, Conan을 포함한 다양한 패키지 형식을 지원합니다. 프로젝트 전체에 패키지를 저장하고 배포하는 중앙 집중식 위치를 제공합니다. 패키지 레지스트리를 GitLab CI/CD 파이프라인과 통합하여 패키지 게시를 자동화하고 원활한 개발 및 배포 워크플로우를 보장합니다.

컨테이너 레지스트리는 Docker 이미지를 위한 비공개 레지스트리 역할을 합니다. 이를 사용하여 조직 또는 공개적으로 Docker 및 OCI 이미지를 저장, 관리 및 배포합니다. 컨테이너 레지스트리를 GitLab CI/CD와 통합하여 컨테이너화된 애플리케이션을 구축, 테스트 및 배포합니다.

자세한 정보는 다음을 참조하세요:

- [패키지 및 레지스트리](../packages/_index.md)

## 2단계:  애플리케이션을 환경 전체에 배포 {#step-2-deploy-your-application-across-environments}

환경을 사용하여 개발, 스테이징, 프로덕션 등 다양한 스테이지에서 애플리케이션의 배포를 관리하고 추적합니다. 각 환경은 자체 고유한 구성, 변수 및 배포 설정을 가질 수 있습니다.

환경을 설정한 후 이를 모니터링할 수 있습니다. 배포한 위치(예: AWS)에서 배포를 주로 모니터링하지만 GitLab도 대시보드를 제공합니다. Kubernetes에 배포하는 경우 GitLab UI에서 라이브 클러스터 상태를 모니터링할 수 있습니다.

머지 리퀘스트의 일부로 임시 환경을 만들 수도 있습니다. 팀 멤버는 메인 브랜치에 변경 사항을 커밋하기 전에 변경 사항을 검토하고 테스트할 수 있습니다. 이러한 임시 환경을 검토 앱이라고 합니다.

자세한 정보는 다음을 참조하세요:

- [환경](../../ci/environments/_index.md)
- [AWS에 배포](../../ci/cloud_deployment/_index.md)
- [Kubernetes에 배포](../clusters/agent/_index.md)
- [Kubernetes용 대시보드](../../ci/environments/kubernetes_dashboard.md)
- [환경 대시보드](../../ci/environments/environments_dashboard.md)
- [작업 대시보드](../operations_dashboard/_index.md)
- [검토 앱](../../ci/review_apps/_index.md)

## 3단계:  지속적 전달 기능으로 규정 준수 유지 {#step-3-stay-compliant-with-continuous-delivery-features}

보호 환경을 사용하여 실수 또는 무단 배포를 방지하여 프로덕션 시스템의 안정성과 무결성을 유지합니다. 이러한 기능은 프로덕션과 같은 중요 환경으로의 배포를 보호하고 제어하는 방법을 제공합니다. 보호 환경을 정의하여 특정 사용자 또는 역할에 대한 액세스를 제한하여 권한이 있는 사용자만 변경 사항을 배포할 수 있도록 보장합니다.

배포 안정성은 지속적 전달 파이프라인의 일부이며 배포의 안정성과 보안을 보장하는 데 도움이 됩니다. GitLab은 배포 실패 시 자동 롤백과 배포의 성공을 확인하기 위한 사용자 정의 상태 확인을 정의할 수 있는 기능 같은 기본 제공 안전 메커니즘을 제공합니다.

배포 승인은 배포 프로세스에 추가 제어 및 협업 계층을 추가합니다. 지정된 승인자가 배포를 검토하고 진행하기 전에 배포를 승인해야 하는 승인 규칙을 정의할 수 있습니다. 승인은 환경, 브랜치 또는 배포 중인 특정 변경 사항 등 다양한 기준에 따라 설정할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [보호 환경](../../ci/environments/protected_environments.md)
- [배포 안정성](../../ci/environments/deployment_safety.md)
- [배포 승인](../../ci/environments/deployment_approvals.md)

## 4단계:  공개 또는 내부 사용자에게 릴리스 아티팩트 제공 {#step-4-ship-release-artifacts-to-the-public-or-internal-users}

릴리스 정보, 바이너리 에셋 및 기타 관련 정보를 포함하여 애플리케이션을 최종 사용자에게 패키징하고 배포하기 위해 릴리스를 사용합니다. 모든 브랜치에서 릴리스를 만들 수 있습니다.

릴리스를 환경과 통합하여 특정 환경(예: 프로덕션)에 배포할 때마다 자동으로 릴리스가 생성되도록 합니다. 릴리스가 발생할 때마다 알림을 받을 수 있으며, 릴리스 생성, 업데이트, 삭제 권한을 제어하도록 권한을 지정할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [릴리스](../project/releases/_index.md)

## 5단계:  변경 사항을 안전하게 롤아웃 {#step-5-roll-out-changes-safely}

점진적 롤아웃을 사용하여 애플리케이션을 일부 사용자나 서버에 점진적으로 배포합니다. 전체 사용자에게 롤아웃하기 전에 더 작은 규모에서 영향을 모니터링하고 평가할 수 있습니다.

GitLab의 기능 플래그는 전체 배포를 요구하지 않고 애플리케이션의 특정 기능을 활성화하거나 비활성화할 수 있는 방법을 제공합니다. 기능 플래그를 사용하여 새로운 기능을 안전하게 테스트하거나, A/B 테스트를 수행하거나, 사용자에게 변경 사항을 점진적으로 도입할 수 있습니다.

기능 플래그를 사용하면 코드 배포를 기능 릴리스에서 분리하여 사용자 경험을 더 효과적으로 제어하고 버그나 예기치 않은 동작이 발생할 위험을 줄일 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [점진적 롤아웃](../../ci/environments/incremental_rollouts.md)
- [기능 플래그](../../operations/feature_flags.md)

## 6단계:  정적 웹사이트 배포 {#step-6-deploy-a-static-website}

GitLab Pages를 사용하여 프로젝트의 설명서, 데모 또는 마케팅 페이지를 공개할 수 있습니다. GitLab의 리포지토리에서 직접 정적 웹사이트를 생성하세요. GitLab Pages는 Jekyll, Hugo, Middleman 같은 정적 사이트 생성기뿐만 아니라 일반 HTML, CSS 및 JavaScript를 지원합니다. 시작하려면 새 프로젝트를 생성하거나 기존 프로젝트를 사용하여 GitLab Pages 설정을 구성하고, 콘텐츠를 리포지토리에 푸시합니다. GitLab은 지정된 브랜치에 변경 사항을 푸시할 때마다 자동으로 웹사이트를 구축하고 배포합니다.

자세한 정보는 다음을 참조하세요:

- [GitLab Pages](../project/pages/_index.md)

## 7단계:  Auto Deploy로 의견 제시하기 {#step-7-go-opinionated-with-auto-deploy}

Auto Deploy는 애플리케이션 빌드 및 배포를 자동으로 처리하는 권장 설정 기반의 CI 템플릿입니다. 환경 변수를 사용하여 Auto DevOps 파이프라인을 미세 조정할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [Auto Deploy](../../topics/autodevops/stages.md#auto-deploy)
