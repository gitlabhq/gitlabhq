---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 클러스터를 GitLab과 연결하기
description: "Kubernetes 통합, GitOps, CI/CD, 에이전트 배포 및 클러스터 관리."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Kubernetes 클러스터를 GitLab과 연결하여 클라우드 네이티브 솔루션을 배포하고, 관리하고, 모니터링할 수 있습니다.

Kubernetes 클러스터를 GitLab에 연결하려면 먼저 [클러스터에 에이전트 설치](install/_index.md)해야 합니다.

에이전트는 클러스터에서 실행되며, 다음과 같은 작업에 사용할 수 있습니다.

- 방화벽이나 NAT 뒤에 있는 클러스터와 통신합니다.
- 클러스터의 API 엔드포인트에 실시간으로 액세스합니다.
- 클러스터에서 발생하는 이벤트에 대한 정보를 푸시합니다.
- 매우 낮은 지연 시간으로 최신 상태가 유지되는 Kubernetes 개체의 캐시를 사용으로 설정합니다.

에이전트의 용도 및 아키텍처에 대한 자세한 내용은 [아키텍처 설명서](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)를 참조하세요.

GitLab에 연결하려는 모든 클러스터에 별도의 에이전트를 배포해야 합니다. 에이전트는 강력한 다중 테넌시 지원으로 설계되었습니다. 유지 관리 및 운영을 단순화하려면 클러스터당 하나의 에이전트만 실행해야 합니다.

에이전트는 항상 GitLab 프로젝트에 등록됩니다. 에이전트가 등록되고 설치되면, 에이전트와 클러스터의 연결을 다른 프로젝트, 그룹 및 사용자와 공유할 수 있습니다. 이 방식은 GitLab 자체에서 에이전트 인스턴스를 관리하고 구성할 수 있으며, 단일 설치를 여러 테넌트로 확장할 수 있습니다.

## GitLab 기능을 위해 지원되는 Kubernetes 버전 {#supported-kubernetes-versions-for-gitlab-features}

GitLab은 다음 Kubernetes 버전을 지원합니다. GitLab을 Kubernetes 클러스터에서 실행하려면 다른 버전의 Kubernetes가 필요할 수 있습니다.

- [Helm 차트](https://docs.gitlab.com/charts/installation/cloud/)의 경우입니다.
- [GitLab Operator](https://docs.gitlab.com/operator/installation/)의 경우입니다.

Kubernetes 버전을 언제든지 지원되는 버전으로 업그레이드할 수 있습니다.

- 1.36 (GitLab 버전 20.2가 릴리스되거나 1.39가 지원되기 시작할 때 지원 종료)
- 1.35 (GitLab 버전 19.10이 릴리스되거나 1.38이 지원되기 시작할 때 지원 종료)
- 1.34 (GitLab 버전 19.7이 릴리스되거나 1.37이 지원되기 시작할 때 지원 종료)

GitLab은 초기 릴리스 후 약 3개월 후에 새로운 Kubernetes 마이너 버전을 지원할 목표로 합니다. GitLab은 언제든지 최소 3개의 프로덕션 지원 Kubernetes 마이너 버전을 지원합니다.

새로운 Kubernetes 버전이 릴리스되면:

- 이 페이지는 약 4주 이내에 초기 스모크 테스트 결과로 업데이트됩니다.
- 새로운 Kubernetes 버전 지원이 지연되면, 이 페이지는 약 8주 이내에 예상 GitLab 지원 버전으로 업데이트됩니다.

에이전트를 설치할 때 Kubernetes 버전과 호환되는 Helm 버전을 사용하세요. Helm의 다른 버전은 작동하지 않을 수 있습니다. 호환되는 버전 목록은 [Helm 버전 지원 정책](https://helm.sh/docs/topics/version_skew/)을 참조하세요.

더 이상 지원되지 않는 API에 대한 지원은 GitLab이 더 이상 해당 API만 지원하는 Kubernetes 버전을 지원하지 않을 때 GitLab 코드베이스에서 제거될 수 있습니다.

일부 GitLab 기능은 여기에 나열되지 않은 버전에서 작동할 수 있습니다. [이 에픽](https://gitlab.com/groups/gitlab-org/-/epics/4827)은 Kubernetes 버전 지원을 추적합니다.

## Kubernetes 배포 워크플로 {#kubernetes-deployment-workflows}

두 가지 기본 워크플로 중에서 선택할 수 있습니다. GitOps 워크플로가 권장됩니다.

### GitOps 워크플로 {#gitops-workflow}

GitLab은 [GitOps를 위한 Flux](gitops.md) 사용을 권장합니다. 시작하려면 [튜토리얼: GitOps를 위한 Flux 설정](getting_started.md)을 참조하세요.

### GitLab CI/CD 워크플로 {#gitlab-cicd-workflow}

[**CI/CD** 워크플로](ci_cd_workflow.md)에서는 GitLab CI/CD를 구성하여 Kubernetes API를 사용해 클러스터를 쿼리하고 업데이트합니다.

이 워크플로는 **push-based**으로 간주됩니다. GitLab이 GitLab CI/CD에서 클러스터로 요청을 푸시하기 때문입니다.

다음 경우에 이 워크플로를 사용하세요:

- 파이프라인 기반 프로세스가 있을 때입니다.
- 에이전트로 마이그레이션해야 하지만 GitOps 워크플로가 사용 사례를 지원하지 않을 때입니다.

이 워크플로는 더 약한 보안 모델을 가지고 있습니다. 프로덕션 배포에는 CI/CD 워크플로를 사용하면 안 됩니다.

## 에이전트 연결 기술 세부사항 {#agent-connection-technical-details}

에이전트는 통신을 위해 KAS에 양방향 채널을 엽니다. 이 채널은 에이전트와 KAS 간의 모든 통신에 사용됩니다.

- 각 에이전트는 활성 및 유휴 스트림을 포함하여 최대 500개의 논리적 gRPC 스트림을 유지할 수 있습니다.
- gRPC 스트림에서 사용하는 TCP 연결의 수는 gRPC 자체에 의해 결정됩니다.
- 각 연결은 최대 2시간의 수명을 가지며, 1시간의 유예 기간이 있습니다.
  - KAS 앞의 프록시는 연결의 최대 수명에 영향을 미칠 수 있습니다. GitLab.com에서는 [2시간](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/68df3484087f0af368d074215e17056d8ab69f1c/attributes/default.rb#L217)입니다. 유예 기간은 최대 수명의 50%입니다.

채널 라우팅에 대한 자세한 정보는 [에이전트의 KAS 요청 라우팅](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kas_request_routing.md)을 참조하세요.

## 반응형 에이전트 {#receptive-agents}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/12180)되었습니다.

{{< /history >}}

반응형 에이전트를 사용하면 GitLab이 GitLab 인스턴스에 네트워크 연결을 설정할 수 없지만 GitLab으로부터 연결될 수 있는 Kubernetes 클러스터와 통합할 수 있습니다. 예를 들어, 다음과 같은 경우에 발생할 수 있습니다.

1. GitLab이 프라이빗 네트워크 또는 방화벽 뒤에서 실행되고 VPN을 통해서만 액세스할 수 있습니다.
1. Kubernetes 클러스터는 클라우드 공급자에서 호스팅되지만 인터넷에 노출되어 있거나 프라이빗 네트워크에서 도달할 수 있습니다.

이 기능이 사용으로 설정되면 GitLab에서 제공된 URL로 에이전트에 연결합니다. 에이전트와 반응형 에이전트를 동시에 사용할 수 있습니다.

## Kubernetes 통합 용어 정의 {#kubernetes-integration-glossary}

이 용어 정의는 GitLab Kubernetes 통합과 관련된 용어에 대한 정의를 제공합니다.

| 용어 | 정의 | 범위 |
| --- | --- | --- |
| GitLab Kubernetes용 에이전트 | 전체 제공 서비스로, 관련 기능 및 기본 구성 요소 `agentk` 및 `kas`를 포함합니다. | GitLab, Kubernetes, Flux |
| `agentk` | Kubernetes 관리 및 배포 자동화를 위해 GitLab과의 보안 연결을 유지하는 클러스터 측 구성 요소입니다. | GitLab |
| Kubernetes용 GitLab 에이전트 서버(`kas`) | Kubernetes 에이전트 통합을 위한 운영 및 로직을 처리하는 GitLab 측 구성 요소입니다. GitLab과 Kubernetes 클러스터 간의 연결 및 통신을 관리합니다. | GitLab |
| 풀 기반 배포 | Flux가 Git 리포지토리의 변경 사항을 확인하고 이러한 변경 사항을 클러스터에 자동으로 적용하는 배포 방법입니다. | GitLab, Kubernetes |
| 푸시 기반 배포 | GitLab CI/CD 파이프라인에서 Kubernetes 클러스터로 업데이트를 보내는 배포 방법입니다. | GitLab |
| Flux | 풀 기반 배포를 위해 에이전트와 통합되는 오픈소스 GitOps 도구입니다. | GitOps, Kubernetes |
| GitOps | 클라우드 및 Kubernetes 리소스의 관리 및 자동화에서 버전 제어 및 협업을 위해 Git을 사용하는 것과 관련된 일련의 관행입니다. | DevOps, Kubernetes |
| Kubernetes 네임스페이스 | 여러 사용자 또는 환경 간에 클러스터 리소스를 분할하는 Kubernetes 클러스터의 논리적 파티션입니다. | Kubernetes |

## 관련 항목 {#related-topics}

- [GitOps 워크플로](gitops.md)
- [GitOps 예제 및 학습 자료](gitops.md#related-topics)
- [GitLab CI/CD 워크플로](ci_cd_workflow.md)
- [에이전트 설치](install/_index.md)
- [에이전트 작업](work_with_agent.md)
- [기존 인증서 기반 통합에서 Kubernetes용 에이전트로 마이그레이션](../../infrastructure/clusters/migrate_to_gitlab_agent.md)
- [문제 해결](troubleshooting.md)
- [프로덕션 준비 GitOps 설정을 위한 가이드 탐색](https://gitlab.com/groups/guided-explorations/gl-k8s-agent/gitops/-/wikis/home#gitlab-agent-for-kubernetes-gitops-working-examples)
- [Kubernetes CI/CD 예제 및 학습 자료](ci_cd_workflow.md#related-topics)
- [에이전트 개발에 기여](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
