---
stage: Release Notes
group: Monthly Release
date: 2025-01-16
title: "GitLab 17.8 릴리스 정보"
description: "GitLab 17.8이 보호된 컨테이너 리포지토리로 보안 강화 기능과 함께 릴리스되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 1월 16일에 GitLab 17.8이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Co-Create Program을 통해 [Océane Legrand](https://gitlab.com/oceane_scania)는 Juan Pablo Gonzalez와 협력하면서 Conan 패키지 레지스트리 기능 세트를 향상시키는 노력을 주도했습니다. 이들의 작업은 Conan 버전 2 지원을 구현하면서 기능을 GA 준비 상태에 더 가깝게 가져오는 것에 집중했습니다. 이러한 협력은 Co-Create Program이 GitLab의 패키지 레지스트리 기능을 어떻게 크게 개선할 수 있는지 보여줍니다.

이들은 GitLab의 Senior Fullstack Engineer, Contributor Success인 [Raimund Hook](https://gitlab.com/stingrayza)에 의해 추천받았으며, Conan Package Registry 기능에 대한 지속적인 협력과 지속적인 반복을 강조했습니다. 이들의 작업은 GitLab 가치를 구현하며 플랫폼의 모든 Conan 사용자에게 이익이 될 것입니다.

Océane Legrand는 Scania의 Full Stack Developer로 AWS에서 자체 호스팅되는 GitLab 인스턴스 유지 관리를 담당합니다. "오픈 소스에서 하고 있는 작업은 GitLab과 Scania 모두에 영향을 미칩니다"라고 Océane은 말합니다. "Co-Create Program을 통한 기여는 Ruby 경험 및 배경 마이그레이션과 같은 새로운 기술을 제공했습니다. Scania의 팀이 업그레이드 중에 이슈에 직면했을 때, 프로그램을 통해 이미 마주쳤기 때문에 이슈를 해결하도록 도와줄 수 있었습니다."

[GitLab의 Co-Create Program에 대해 자세히 알아보기](https://about.gitlab.com/community/co-create/)에서 고객들이 당사의 제품 및 엔지니어링 팀과 직접 협력하여 새로운 기능을 개발하고 기존 기능을 개선합니다.

## 주요 기능 {#primary-features}

### 보호된 컨테이너 리포지토리로 보안 강화 {#enhance-security-with-protected-container-repositories}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/container_registry/container_repository_protection_rules.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)

{{< /details >}}

보호된 컨테이너 리포지토리의 롤아웃을 발표하게 되어 기쁩니다. 이는 GitLab의 컨테이너 레지스트리의 새로운 기능으로 컨테이너 이미지 관리의 보안 및 제어 문제를 해결합니다. 조직은 민감한 컨테이너 리포지토리에 대한 무단 액세스, 실수로 인한 수정, 세밀한 제어 부족, 규정 준수 유지의 어려움 등으로 어려움을 겪고 있습니다. 이 솔루션은 엄격한 액세스 제어, push, pull 및 관리 작업에 대한 세밀한 권한, GitLab CI/CD 파이프라인과의 원활한 통합을 통해 향상된 보안을 제공합니다.

보호된 컨테이너 리포지토리는 보안 침해 위험을 줄이고 중요한 자산에 대한 실수로 인한 변경을 줄임으로써 사용자에게 가치를 제공합니다. 이 기능은 보안을 유지하면서 개발 속도를 희생하지 않아 워크플로우를 간소화하고, 컨테이너 레지스트리의 전반적인 거버넌스를 개선하며, 중요한 컨테이너 자산이 조직의 필요에 따라 보호되고 있다는 것을 알고 있어 안심을 제공합니다.

이 기능 및 [보호된 패키지](https://gitlab.com/groups/gitlab-org/-/epics/5574) 기능은 `gerardo-navarro`와 Siemens 팀의 커뮤니티 기여입니다. GitLab에 많은 기여를 해주신 Gerardo와 Siemens의 나머지 팀원들에게 감사합니다! Gerardo와 Siemens 팀이 이 변경에 기여한 방법에 대해 자세히 알아보고 싶다면, Gerardo가 외부 기여자로서의 경험을 바탕으로 GitLab에 기여하기 위한 학습과 모범 사례를 공유하는 이 [비디오](https://www.youtube.com/watch?v=5-nQ1_Mi7zg)를 확인하세요.

### 릴리스와 관련된 배포 목록 {#list-the-deployments-related-to-a-release}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/releases/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501169)

{{< /details >}}

GitLab은 오랫동안 Git 태그에서 릴리스를 생성하고 배포를 추적하는 것을 지원해왔지만, 이 정보는 이전에 함께 모으기 어려운 여러 개의 별도 위치에 있었습니다. 이제 릴리스 페이지에서 직접 릴리스와 관련된 모든 배포를 볼 수 있습니다. 릴리스 관리자는 릴리스가 배포된 위치와 배포 대기 중인 환경을 빠르게 확인할 수 있습니다. 이는 태그된 배포에 대한 릴리스 정보를 표시하는 기존 배포 페이지 통합을 보완합니다.

두 기능 모두 GitLab에 기여해주신 [Anton Kalmykov](https://gitlab.com/antonkalmykov)에게 감사의 뜻을 표현합니다.

### GA의 머신러닝 모델 실험 추적 {#machine-learning-model-experiments-tracking-in-ga}

<!-- categories: MLOps -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/ml/experiment_tracking/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9341)

{{< /details >}}

머신러닝 모델을 만들 때, 데이터 과학자는 종종 모델의 성능을 향상시키기 위해 다양한 매개변수, 구성 및 기능 엔지니어링을 실험합니다. 데이터 과학자가 나중에 실험을 복제할 수 있도록 이 모든 메타데이터 및 관련 아티팩트를 추적하는 것은 간단하지 않습니다. 머신러닝 실험 추적은 매개변수, 메트릭 및 아티팩트를 GitLab에 직접 기록하도록 하여 나중에 쉽게 액세스할 수 있게 하면서 모든 실험 데이터를 GitLab 환경 내에 유지합니다. 이 기능은 이제 향상된 데이터 표시, 향상된 권한, GitLab과의 더 깊은 통합 및 버그 수정과 함께 일반적으로 사용 가능합니다.

### GitLab Dedicated의 Linux 호스트 러너가 제한적 출시 상태 {#hosted-runners-on-linux-for-gitlab-dedicated-now-in-limited-availability}

<!-- categories: GitLab Dedicated, GitLab Hosted Runners -->

{{< details >}}

- 티어: Gold
- 링크: [문서](../../administration/dedicated/hosted_runners.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509142)

{{< /details >}}

GitLab Dedicated의 Linux 호스트 러너의 제한적 출시를 소개하게 되어 기쁩니다.

러너 플릿을 관리하는 것은 복잡할 수 있으며 모든 CI/CD 작업이 개발자의 요구 사항을 충족하도록 확장될 수 있도록 상당한 경험이 필요합니다.

GitLab Dedicated의 호스트 러너를 사용하면 CI/CD 작업을 위해 완전히 관리되는 러너를 사용할 수 있습니다. 이들은 자신의 러너 인프라를 유지할 필요를 제거하고 GitLab Dedicated와 동일한 보안, 유연성 및 효율성을 러너에 제공합니다.

호스트 러너는 CI/CD 요구 사항을 자동으로 확장하여 피크 시간과 대규모 프로젝트 중에 최적의 성능을 보장합니다. 제한적 출시 릴리스에는 2~32 vCPU 범위의 다양한 크기의 Linux 러너와 8~128GB의 메모리가 포함됩니다.

제한적 출시 단계 동안 GitLab Dedicated의 호스트 러너에 액세스를 요청하려면 GitLab 담당자에게 문의하세요.

### macOS의 Large M2 Pro 호스트 러너(베타) {#large-m2-pro-hosted-runners-on-macos-beta}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../ci/runners/hosted_runners/macos.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/ci-cd/shared-runners/-/epics/19)

{{< /details >}}

모바일 DevOps 팀에 M2 Pro 성능을 제공합니다!

M1 러너의 최대 2배 성능과 x86-64 macOS 러너의 6배 성능으로 애플리케이션을 구축하고 배포할 때 개발 팀의 속도를 높일 수 있습니다.

GitLab CI/CD에 완전히 통합되고 주문형으로 사용 가능하며, 팀은 이제 Apple 에코시스템용 애플리케이션을 더 빠르게 만들고, 테스트하고, 배포할 수 있습니다.

오늘 `saas-macos-large-m2pro`을 태그로 `.gitlab-ci.yml` 파일에서 사용하여 새로운 M2 Pro 러너를 체험해보세요.

## 에이전틱 코어 {#agentic-core}

### GitLab MLOps Python Client 베타 {#gitlab-mlops-python-client-beta}

<!-- categories: MLOps -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/16193)

{{< /details >}}

데이터 과학자 및 머신러닝 엔지니어는 주로 Python 환경에서 작업하지만, 머신러닝 워크플로우를 GitLab의 MLOps 기능과 통합하려면 종종 컨텍스트 전환 및 GitLab의 API 구조 이해가 필요합니다. 이로 인해 개발 프로세스에 마찰이 생기고 실험 추적, 모델 아티팩트 관리 및 팀 구성원과의 협력 능력이 느려질 수 있습니다.

새로운 GitLab MLOps Python 클라이언트는 GitLab의 MLOps 기능에 대한 원활한 Pythonic 인터페이스를 제공합니다. 데이터 과학자는 이제 Python 스크립트 및 노트북에서 직접 GitLab의 [실험 추적](../../user/project/ml/experiment_tracking/_index.md) 및 [모델 레지스트리](../../user/project/ml/model_registry/_index.md) 기능과 상호 작용할 수 있습니다. 클라이언트에 포함되는 항목:

- **GitLab Experiment Tracking**: GitLab 내에서 머신러닝 실험을 쉽게 추적합니다.
- **Model Registry Integration**: GitLab의 모델 레지스트리에서 모델을 등록하고 관리합니다.
- **Experiment Management**: 클라이언트에서 직접 실험을 생성하고 관리합니다.
- **Run Tracking**: 훈련 실행을 쉽게 시작하고 모니터링합니다.

이 통합을 통해 데이터 과학자는 모델 개발에 집중하면서 GitLab에서 자동으로 ML 수명 주기 메타데이터를 캡처할 수 있습니다. Python 클라이언트는 기존 ML 워크플로우와 원활하게 작동하며 최소한의 설정이 필요하므로 GitLab의 MLOps 기능을 데이터 과학 커뮤니티에 더 쉽게 접근할 수 있도록 합니다.

더 광범위한 Python 및 데이터 과학 커뮤니티가 기여하고 피드백을 우리 [프로젝트의 리포지토리](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops)에 직접 공유하는 것을 환영합니다

## 규모 및 배포 {#scale-and-deployments}

### 삭제 대기 중인 하위 그룹 및 프로젝트 보기 {#view-subgroups-and-projects-pending-deletion}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/_index.md#view-inactive-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/457718)

{{< /details >}}

그룹을 삭제 대상으로 표시할 때, 영향을 받는 모든 하위 그룹 및 프로젝트에 대한 가시성이 필요합니다. 이전에는 삭제 대상으로 표시된 그룹만 "Pending deletion" 레이블을 표시했지만 하위 그룹 및 프로젝트는 표시하지 않아 어떤 콘텐츠를 삭제할 예정인지 식별하기 어려웠습니다.

이제 그룹을 삭제 대상으로 표시하면 모든 하위 그룹 및 프로젝트에 "Pending deletion" 레이블이 표시됩니다. 이 향상된 가시성은 전체 그룹 계층 구조에서 활성 콘텐츠와 곧 삭제될 콘텐츠를 빠르게 구분하는 데 도움이 됩니다.

### 이슈 또는 머지 리퀘스트에서 여러 할 일 항목을 추적 {#track-multiple-to-do-items-in-an-issue-or-merge-request}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/todos.md#actions-that-create-to-do-items) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)

{{< /details >}}

이제 단일 이슈 또는 머지 리퀘스트 내에서 여러 토론 및 언급을 추적할 수 있습니다. 새로운 다중 할 일 항목 기능을 사용하면 각 언급 또는 작업에 대해 별도의 할 일 항목을 받게 되어 중요한 업데이트 또는 주의가 필요한 요청을 놓치지 않습니다. 이 향상된 기능은 작업을 더 효과적으로 관리하고 팀의 필요에 더 효율적으로 대응하는 데 도움이 됩니다.

### 그룹의 프로젝트 생성 보호이제 Owner 포함 {#project-creation-protection-for-groups-now-includes-owners}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/_index.md#specify-who-can-add-projects-to-a-group) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/354355)

{{< /details >}}

프로젝트 생성은 **Allowed to create projects** 설정을 사용하여 그룹의 특정 역할로 제한할 수 있습니다. Owner 역할은 이제 옵션으로 사용 가능하므로 그룹에 대한 Owner 역할을 가진 사용자만 새 프로젝트를 생성하도록 제한할 수 있습니다. 이 역할은 이전에 선택 옵션에서 사용할 수 없었습니다.

이 커뮤니티 기여에 대해 [@yasuk](https://gitlab.com/yasuk)에게 감사합니다!

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 시크릿 검색이제 수정 단계 포함 {#secret-detection-now-includes-remediation-steps}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/505757)

{{< /details >}}

노출된 시크릿을 빠르게 수정하여 공격자가 노출된 자격 증명을 사용하여 시스템에 침입할 위험을 최소화하는 것이 중요합니다. 적절한 수정은 시크릿을 제거하는 것 이상으로 자격 증명 순환 및 잠재적 무단 액세스 조사와 같은 여러 단계가 필요합니다. 시스템을 안전하게 유지하기 위해 시크릿 검색은 이제 감지된 각 시크릿 검색 유형에 대한 특정 수정 단계를 포함합니다. 이 지침은 노출을 체계적으로 해결하고 보안 침해 위험을 줄이는 데 도움이 됩니다. 수정 단계는 파이프라인 완료 시 모든 취약성에 나타납니다.

### 취약성을 해결한 커밋 찾기 {#find-the-commit-that-resolved-a-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/372799)

{{< /details >}}

이전에는 취약성을 더 이상 감지하지 못한 경우, 취약성이 언제 또는 어디서 해결되었는지 확인할 수 있는 방법을 사용자에게 제공하지 않았습니다. 이제 취약성이 해결된 커밋 SHA로의 링크를 표시하여 수정 프로세스에 대한 더 나은 추적성과 통찰력을 제공합니다. 이를 통해 보안 및 개발 팀이 협력하고 취약성을 더 효과적으로 관리할 수 있습니다.

### 역할을 사용하여 프로젝트 구성원을 코드 소유자로 정의 {#use-roles-to-define-project-members-as-code-owners}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/codeowners/reference.md#add-a-role-as-a-code-owner) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/282438)

{{< /details >}}

`CODEOWNERS` 파일에서 코드 소유자로 역할을 사용하여 역할 기반 전문성 및 승인을 더 효율적으로 관리할 수 있습니다. 개별 사용자를 나열하거나 그룹을 만드는 대신 다음 구문을 사용할 수 있습니다:

- `@@developers` - Developer 역할을 가진 모든 사용자를 참조합니다.
- `@@maintainers` - Maintainer 역할을 가진 모든 사용자를 참조합니다.
- `@@owners` - Owner 역할을 가진 모든 사용자를 참조합니다.

예를 들어 `* @@maintainers`을 추가하여 리포지토리의 모든 변경 사항에 대해 모든 관리자의 승인을 요구합니다.

이는 팀 구성원이 프로젝트에 참여하고, 나가거나, 역할을 변경할 때 코드 소유자 관리를 단순화합니다. `CODEOWNERS` 파일은 GitLab이 지정된 역할을 가진 모든 사용자를 자동으로 포함하기 때문에 수동 업데이트 없이 최신 상태로 유지됩니다.

### Kubernetes 대시보드에서 일시 중지된 Flux 조정 보기 {#view-paused-flux-reconciliations-on-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501339)

{{< /details >}}

이전에는 Kubernetes 대시보드에서 Flux 수정을 일시 중지했을 때 일시 중지된 상태에 대한 명확한 표시가 없었습니다. 기존 상태 표시기 세트에 새로운 "Paused" 상태를 추가하여 Flux 수정이 일시 중지되었을 때 명확히 하고 배포 상태에 대한 더 나은 가시성을 제공합니다.

### Kubernetes 대시보드에서 Pod 검색 {#search-for-pods-on-the-dashboard-for-kubernetes}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/508010)

{{< /details >}}

Kubernetes 대시보드에서 대규모 배포에서 특정 Pod을 찾는 것은 시간이 많이 걸릴 수 있습니다. 새로운 검색 표시줄을 사용하면 이름으로 Pod을 빠르게 필터링할 수 있습니다. 검색은 모든 사용 가능한 Pod에서 작동하며 상태 필터와 조합하여 모니터링하거나 문제를 해결해야 하는 정확한 Pod을 찾을 수 있습니다.

### 머지 리퀘스트 승인 정책에서 여러 개의 구별되는 승인 작업 지원 {#support-multiple-distinct-approval-actions-in-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12319)

{{< /details >}}

이전에는 머지 리퀘스트 승인 정책이 정책당 단일 승인 규칙만 지원했으므로 "OR" 조건으로 쌓인 한 세트의 승인자만 허용했습니다. 결과적으로 다양한 역할, 개별 승인자 또는 별도 그룹으로부터 계층화된 보안 승인을 적용하기가 더 어려웠습니다.

이 업데이트를 통해 각 머지 리퀘스트 승인 정책에 대해 최대 5개의 승인 규칙을 생성할 수 있으므로 더 유연하고 강력한 승인 정책을 허용합니다. 각 규칙은 다양한 승인자 또는 역할을 지정할 수 있으며 각 규칙은 독립적으로 평가됩니다. 예를 들어 보안 팀은 Group A에서 한 명의 승인자와 Group B에서 한 명의 승인자를 요구하거나, 특정 역할에서 한 명과 지정된 그룹에서 다른 승인자를 요구하는 복잡한 승인 워크플로우를 정의하여 민감한 워크플로우에서 규정 준수 및 향상된 제어를 보장할 수 있습니다.

이 개선의 사용 사례는 다음을 포함합니다:

- **Distinct role approvals:** Developer 역할 승인 한 개와 Maintainer 역할 승인 한 개.
- **Role and group approvals**: Developer 또는 Maintainer 승인 한 개와 Security Group의 구성원 승인 한 개.
- **Distinct group approvals:** Python Experts Group의 구성원 승인 한 개와 Security Group의 구성원 승인 또 다른 개.

### GitLab Pages의 기본 도메인 리디렉션 {#primary-domain-redirect-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/_index.md#primary-domain)

{{< /details >}}

이제 GitLab Pages에서 기본 도메인을 설정하여 사용자 지정 도메인의 모든 요청을 기본 도메인으로 자동으로 리디렉션할 수 있습니다. 이는 SEO 순위를 유지하고 초기에 사이트에 액세스하기 위해 어떤 URL을 사용했는지에 관계없이 선호하는 도메인으로 방문자를 직접함으로써 일관된 브랜드 경험을 제공합니다.

### 보호된 패키지로 종속성 보호 {#safeguard-your-dependencies-with-protected-packages}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/packages/package_registry/package_protection_rules.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/323971)

{{< /details >}}

보호된 PyPI 패키지 지원을 소개하게 되어 기쁩니다. 이는 GitLab 패키지 레지스트리의 보안 및 안정성을 향상시키도록 설계된 새로운 기능입니다. 빠르게 진행되는 소프트웨어 개발 세계에서 패키지의 실수로 인한 수정 또는 삭제는 전체 개발 프로세스를 방해할 수 있습니다. 보호된 패키지는 의도하지 않은 변경으로부터 가장 중요한 종속성을 보호할 수 있게 함으로써 이 이슈를 해결합니다.

GitLab 17.8부터 보호 규칙을 생성하여 PyPI 패키지를 보호할 수 있습니다. 패키지가 보호 규칙과 일치하면 지정된 사용자만 패키지를 업데이트하거나 삭제할 수 있습니다. 이 기능을 통해 실수로 인한 변경을 방지하고, 규제 요구 사항에 대한 규정 준수를 개선하며, 수동 감독의 필요성을 줄임으로써 워크플로우를 간소화할 수 있습니다.

### 에픽의 사용자 지정 색상 {#customizable-colors-for-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/manage_epics.md#epic-color) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509924)

{{< /details >}}

이제 기존 값 및 사용자 지정 RGB 또는 16진 코드를 포함한 확장된 색상 옵션 세트로 에픽을 분류하는 데 더 많은 유연성이 있습니다. 이 향상된 시각적 사용자 지정을 통해 에픽을 쉽게 squad, 회사 이니셔티브 또는 계층 구조 수준과 연결할 수 있으므로 로드맵 및 에픽 보드에서 작업을 우선 순위 지정하고 구성하기가 더 간단합니다.

관리자는 [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다.

### 에픽 상위 항목 {#epic-ancestors}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509920)

{{< /details >}}

[에픽 계층 구조](../../user/group/epics/_index.md#relationships-between-epics-and-other-items)를 탐색하는 것이 이제 더 쉬워졌습니다. 이제 각 에픽의 상단에 눈에 띄게 표시되는 다시 설계된 Ancestry 위젯이 있습니다. 에픽 간의 관계를 빠르게 파악할 수 있으므로 즉시 및 궁극적인 부모를 한눈에 볼 수 있어 프로젝트 구조를 명확하게 유지하고 관련 에픽 간에 쉽게 이동할 수 있습니다.

관리자는 [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다.

### 에픽 건강 상태 {#epic-health-status}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/manage_epics.md#health-status) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509922)

{{< /details >}}

이제 에픽에 대한 새로운 건강 상태 기능으로 프로젝트의 진행 상황을 쉽게 전달할 수 있습니다. 상태를 "On track", "Needs attention" 또는 "At risk"로 설정하면 에픽의 건강 상태를 빠르게 시각적으로 표시하여 위험을 관리하고 프로젝트의 전반적인 상태에 대해 이해 관계자에게 알릴 수 있습니다.

관리자는 [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다.

### 에픽 부모 {#epic-parent}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509923)

{{< /details >}}

이제 에픽에서 직접 부모를 추가하여 에픽 계층 구조를 쉽게 관리할 수 있으며, 이슈의 경우와 마찬가지입니다. 이 간소화된 프로세스는 작업을 구성하는 데 더 많은 유연성을 제공하여 에픽 간의 관계를 빠르게 설정하고 프로젝트의 명확한 구조를 유지할 수 있습니다.

관리자는 [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다.

### 에픽에 소요된 시간 추적 {#track-time-spent-on-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/time_tracking.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509930)

{{< /details >}}

이제 에픽에서 직접 시간을 추적하여 프로젝트의 시간 관리에 대한 더 세밀한 제어를 할 수 있습니다. 이 새로운 기능을 사용하면 프로젝트의 여러 측면에 소요된 시간을 기록하여 진행 상황을 모니터링하고, 일정에 맞춰 계획하며, 스프린트 및 마일스톤을 작업할 때 예산을 유지할 수 있습니다.

### 에픽, 이슈 및 목표의 하위 항목에서 반복 필드 표시 {#show-iteration-field-on-child-items-in-epics-issues-and-objectives}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/iterations/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/510005)

{{< /details >}}

에픽 세부 정보를 볼 때 계획자는 어떤 하위 이슈가 반복(스프린트)으로 계획되었는지 그리고 아직 계획되지 않은 것이 무엇인지 볼 수 있어야 합니다. 이를 통해 팀은 모든 정의된 작업이 스프린트로 예약되도록 더 쉽게 확인할 수 있습니다.

에픽의 경우 관리자는 [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다.

### 에픽의 웹후크 {#webhooks-for-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509928)

{{< /details >}}

에픽 웹후크로 워크플로우 자동화를 강화하여 에픽에서 변경 사항이 발생할 때마다 선호하는 도구에서 실시간 업데이트를 받을 수 있습니다. GitLab을 다른 서비스와 통합하면 협력을 향상시키고, 프로젝트 개발 상황을 최신으로 유지하며, 애플리케이션 간에 지속적으로 전환하지 않고 프로세스를 간소화할 수 있습니다.

관리자는 [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다.

### 지원되는 웹후크 이벤트로 취약성 추가 {#add-vulnerabilities-as-supported-webhook-events}

<!-- categories: Notifications, Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md#vulnerability-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/366770)

{{< /details >}}

취약성과 관련된 작업에 대한 이벤트를 생성하는 웹후크 통합을 소개하여 외부 리소스와 자동화 및 통합을 허용합니다. 예를 들어 취약성이 생성되거나 취약성의 상태가 변경될 때 이벤트가 생성됩니다.

### `override_ci` 전략에 대해 중앙화된 워크플로우 규칙 적용 {#enforce-centralized-workflow-rules-for-the-override_ci-strategy}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/pipeline_execution_policies.md#override_project_ci) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/512123)

{{< /details >}}

파이프라인 실행 정책에서 `override_ci` 전략은 이제 정책에 정의된 작업뿐만 아니라 `include:project`을 사용할 때 프로젝트 구성에 정의된 작업에 대한 정책 적용을 지원하는 워크플로우 규칙의 사용을 지원합니다. 정책에 워크플로우 규칙을 정의하면 특정 규칙을 기반으로 파이프라인 실행 정책에 의해 실행된 작업을 필터링할 수 있습니다. 예를 들어 프로젝트에서 브랜치 파이프라인의 사용을 방지하는 규칙을 구성합니다.

워크플로우 규칙의 사용을 정책에 정의된 작업만 대상으로 분리하려면 모범 사례는 정책에서 전역적으로 규칙을 정의하는 대신 작업에 대한 규칙을 정의하는 것입니다. 또는 별도의 `include` 필드를 사용하여 작업 및 규칙을 그룹화할 수 있습니다.

이전에는 `override_ci` 전략을 사용할 때 워크플로우 규칙은 파이프라인 실행 정책에 정의된 작업에만 적용될 수 있었습니다.

`inject_ci` 전략은 변경되지 않았으며 워크플로우 규칙은 프로젝트의 워크플로우 규칙에 영향을 주지 않고 정책 작업이 적용될 때만 제어하는 데 사용될 수 있습니다.

### `skip_ci`를 파이프라인 실행 정책에 대해 구성 가능하도록 설정 {#make-skip_ci-configurable-for-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/pipeline_execution_policies.md#skip_ci-type) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15647)

{{< /details >}}

`[skip ci]` 지시문 처리에서 더 많은 유연성을 허용하는 파이프라인 실행 정책(PEPs)에 대한 새로운 구성 옵션을 도입했습니다. 이 기능은 시맨틱 릴리스와 같은 특정 자동화된 프로세스가 중요한 보안 및 규정 준수 확인이 수행되도록 하면서 파이프라인 실행을 우회해야 하는 시나리오를 해결합니다.

이 기능을 사용하려면 `skip_ci`을 `allowed: false`로 설정하거나 정책 편집기에서 **사용자가 파이프라인을 생략하지 못하도록 방지**를 활성화합니다. 그런 다음 `[skip ci]`을 사용할 수 있는 사용자 또는 서비스 계정을 지정합니다. 기본적으로 `skip_ci` 구성 내에서 예외로 제외되지 않으면 모든 사용자가 파이프라인 실행 작업을 생략하지 못합니다.

### 예약된 검사 실행 정책 파이프라인의 동시성 관리 {#manage-concurrency-of-scheduled-scan-execution-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/scan_execution_policies.md#concurrency-control) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13997)

{{< /details >}}

글로벌 예약 검사 실행 정책의 확장성을 개선하기 위해 검사 실행 정책에서 시간 창을 구성하는 새로운 기능을 도입했습니다. `time_window` 속성은 정책이 최적의 성능을 보장하기 위해 새 일정을 생성하고 실행하는 기간을 정의합니다.

새 속성을 사용하려면 YAML 모드를 사용하여 정책을 업데이트하고 [`time_window` 스키마](../../user/application_security/policies/scan_execution_policies.md#time_window-schema)를 따릅니다. 일정이 실행되어야 하는 시간 창에 대한 값을 초 단위로 제공할 수 있습니다. 예를 들어 `86400`은 24시간 시간 창입니다. 그런 다음 `distribution: random` 필드 및 값을 제공하여 정의된 시간 창 전체에서 일정이 무작위 시간에 실행되도록 합니다.

### Compliance Center의 'Frameworks' 보고서 탭의 UI 성능 확장 {#scaling-ui-performance-for-the-frameworks-report-tab-in-the-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/compliance_center/compliance_frameworks_report.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/477394)

{{< /details >}}

GitLab 17.8에서는 규정 준수 센터의 **프레임워크** 보고서 탭에 수천 개의 규정 준수 프레임워크가 있어도 규정 준수 센터가 빠르고 반응성 있게 유지되도록 백엔드에 변경 사항을 적용했습니다.

또한 **프레임워크** 탭에서 프레임워크에 대해 더 많은 정보를 찾고 클릭하면 GitLab은 오른쪽의 팝업 메뉴 정보의 일부로 해당 특정 프레임워크에 첨부된 최대 1,000개의 프로젝트를 반환합니다.

### GitLab Community Edition에서 사용 가능한 파이프라인 한계 {#pipeline-limits-available-in-gitlab-community-edition}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/287669)

{{< /details >}}

관리자는 이제 GitLab Community Edition 설치에 대해 CI/CD 한계를 설정하여 파이프라인 리소스 사용을 제어할 수 있습니다. 이전에는 이 기능이 GitLab Enterprise Edition에서만 사용 가능했습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.8)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
