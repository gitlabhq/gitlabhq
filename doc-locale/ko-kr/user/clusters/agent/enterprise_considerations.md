---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes와의 GitLab 통합을 사용하기 위한 모범 사례
---

Kubernetes용 에이전트와 Flux는 GitOps를 통해 Kubernetes에 배포할 때 최고의 환경을 제공합니다. GitLab은 배포를 위해 GitOps(풀 기반 배포라고도 함)를 사용할 것을 권장합니다. 하지만 회사가 GitOps로 전환할 수 없거나 파이프라인 기반 접근 방식을 사용해야 할 특정한(일반적으로 비프로덕션) 이유가 있을 수 있습니다. 이 페이지에서는 엔터프라이즈에서 GitOps를 사용하기 위한 모범 사례를 설명하며, 파이프라인 기반 배포에 대한 고려 사항도 포함합니다.

GitOps의 장점에 대한 설명을 보려면 [OpenGitOps 이니셔티브](https://opengitops.dev/about/)를 참조하세요.

## GitOps {#gitops}

- [Kubernetes 클러스터를 GitLab에 연결하여 시작](getting_started.md)에서는 Flux CLI를 사용하여 Flux를 설치하는 방법을 보여주지만, Flux 배포를 확장하고 자동화하려면 다음 중 하나를 수행해야 합니다:
  - [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator)를 사용합니다.
  - [Terraform](https://registry.terraform.io/providers/fluxcd/flux/latest/docs) 또는 [OpenTofu](https://search.opentofu.org/provider/fluxcd/flux/latest)로 설치합니다.
- [다중 테넌시 잠금](https://fluxcd.io/flux/installation/configuration/multitenancy/)을 사용하여 Flux를 구성합니다.
- 확장을 위해 Flux는 [수직](https://fluxcd.io/flux/installation/configuration/vertical-scaling/) 및 [수평 샤딩](https://fluxcd.io/flux/installation/configuration/sharding/)을 지원합니다.
- Flux 관련 지침은 Flux 문서의 [Flux 가이드](https://fluxcd.io/flux/guides/)를 참조하세요.
- 유지 관리를 단순화하려면 클러스터당 단일 GitLab Kubernetes 에이전트 설치를 실행해야 합니다. GitLab 도메인 전체에서 가장 대표(impersonation) 기능을 사용하여 에이전트 연결을 공유할 수 있습니다.
- 매니페스트를 저장하고 검색하기 위해 Flux `OCIRepository`를 사용하는 것을 고려하세요. GitLab 파이프라인을 사용하여 OCI 이미지를 빌드하고 컨테이너 레지스트리로 푸시할 수 있습니다.
- 피드백 루프를 단축하려면 관련 GitLab 파이프라인에서 즉시 GitOps 조정을 트리거합니다.
- 생성된 OCI 이미지에 서명하고 Flux에서 서명 및 확인한 이미지만 배포해야 합니다.
- Flux가 매니페스트에 액세스하는 데 사용되는 키를 정기적으로 회전해야 합니다. 에이전트 등록 토큰도 정기적으로 회전해야 합니다.

### OCI 컨테이너 {#oci-containers}

Git 리포지토리 대신 OCI 컨테이너를 사용할 때 매니페스트의 신뢰할 수 있는 소스는 여전히 Git 리포지토리입니다. OCI 컨테이너는 Git 리포지토리와 클러스터 간의 캐싱 계층으로 생각할 수 있습니다.

OCI 컨테이너를 사용하면 다음과 같은 몇 가지 이점이 있습니다:

- OCI는 확장성을 위해 설계되었습니다. GitLab Git 리포지토리는 확장성이 뛰어나지만 이러한 사용 사례를 위해 설계되지 않았습니다.
- 단일 Git 리포지토리는 여러 OCI 컨테이너의 소스가 될 수 있으며, 각 컨테이너는 작은 매니페스트 집합을 패키징합니다. 이러한 방식으로 매니페스트 집합을 검색해야 할 경우 전체 Git 리포지토리를 다운로드할 필요가 없습니다.
- OCI 리포지토리는 잘 알려진 버전 관리 체계를 따를 수 있으며, Flux는 해당 체계를 따르도록 자동으로 업데이트되도록 구성할 수 있습니다. 예를 들어 시멘틱 버전 관리를 사용하는 경우 Flux는 모든 부 버전과 패치 변경 사항을 자동으로 배포할 수 있으며, 주 버전은 수동 업데이트가 필요합니다.
- OCI 이미지에 서명할 수 있으며, 서명은 Flux로 확인할 수 있습니다.
- OCI 리포지토리는 이미지가 빌드된 후에도 컨테이너 레지스트리에서 검색할 수 있습니다.
- OCI 컨테이너를 빌드하는 작업을 통해 [보호 환경](../../../ci/environments/protected_environments.md), [배포 승인](../../../ci/environments/deployment_approvals.md), [배포 동결](../../project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) 등 일반적인 GitOps 도구에서 지원하지 않는 잘 알려진 릴리스 관리 기능을 사용할 수 있습니다.

## 파이프라인 기반 배포 {#pipeline-based-deployments}

파이프라인 기반 배포를 사용해야 하는 경우 다음 모범 사례를 따르세요:

- 클러스터당 배포되는 에이전트 수를 줄이려면 그룹과 프로젝트 전체에서 에이전트 연결을 공유합니다. 가능하면 클러스터당 하나의 에이전트 배포만 사용합니다.
- 대표(impersonation)를 사용하고 일반적인 Kubernetes RBAC을 사용하여 클러스터의 CI/CD 작업 접근을 최소화합니다.
