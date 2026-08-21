---
stage: Release Notes
group: Monthly Release
date: 2026-02-19
title: "GitLab 18.9 릴리스 정보"
description: "GitLab 18.9 릴리스 - GitLab Duo Agent Platform Self-Hosted 모델이 이제 클라우드 라이선스에서 사용 가능"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026년 2월 19일에 GitLab 18.9가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Pooja Ghanghas {#this-months-notable-contributor-pooja-ghanghas}

Pooja는 레거시 드롭다운 컴포넌트를 최신 드롭다운 아키텍처로 마이그레이션하는 GitLab의 지속적인 노력에 상당한 기여를 했습니다. 이러한 마이그레이션은 세심한 주의와 이전 및 새로운 컴포넌트 시스템에 대한 이해가 필요합니다. Pooja는 여러 마이그레이션 전반에 걸쳐 일관되게 고품질의 작업을 제공했으며, [diff 파일 헤더](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189621), [코드 블록 버블 메뉴](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194129), [온콜 스케줄 로테이션 담당자 컴포넌트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186247), [새로운 리소스 드롭다운](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209598) 업데이트를 포함합니다.

GitLab의 Tenant Scale::Organizations 담당 Staff Frontend Engineer인 [Peter Hegman](https://gitlab.com/peterhegman)이 이 인정을 위해 Pooja를 추천했으며 다음과 같이 언급했습니다: "이 마이그레이션은 꽤 까다로울 수 있는데 그녀가 여러 개를 완료했습니다. 기여해주셔서 감사합니다!"

이러한 마이그레이션 노력 외에도 Pooja는 [마일스톤 및 반복에 상태 추가](https://gitlab.com/gitlab-org/gitlab/-/issues/524100)를 포함한 기능 개발에 기여했으며, 이는 그녀가 병합을 위해 상당한 노력을 기울인 기능입니다. GitLab의 Plan:Project Management 담당 Staff Fullstack Engineer인 [Marc Saleiko](https://gitlab.com/msaleiko)가 그녀의 작업을 인정했습니다: "이것은 귀중한 기여이며 이 기능을 잘 전달했습니다!" 그녀의 경험을 되돌아보면서 Pooja는 다음과 같이 공유했습니다: "그것이 어떻게 나왔는지에 대해 자랑스럽고 나에게 훌륭한 학습 경험이었습니다."

또한 그녀는 GitLab 코드베이스 전반에 걸쳐 수많은 버그 수정 및 유지보수 개선을 기여했습니다. Pooja의 작업은 GitLab 사용자 인터페이스의 유지보수성과 일관성을 직접 개선하여 기여자와 팀 멤버 모두가 기능을 빌드하고 유지보수하기 쉽게 만들며, GitLab 프론트엔드 아키텍처를 앞으로 나아가도록 돕습니다.

Pooja, GitLab 코드베이스를 개선하기 위한 지속적인 기여와 저희 기여자 커뮤니티의 신뢰할 수 있는 일원이 되어주셔서 감사합니다!

Pooja의 기여에 대해 더 알고 싶으신가요? 그녀의 [GitLab 프로필](https://gitlab.com/poojaghanghas479)을 확인해보세요.

## 주요 기능 {#primary-features}

### GitLab Duo Agent Platform Self-Hosted 모델이 이제 클라우드 라이선스에서 사용 가능 {#gitlab-duo-agent-platform-self-hosted-models-now-available-for-cloud-licenses}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/_index.md#gitLab-duo-agent-platform) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20949)

{{< /details >}}

GitLab Duo Agent Platform은 이제 클라우드 라이선스가 있는 GitLab Self-Managed 고객에게 일반 공급됩니다. 이 기능에 대한 청구는 [사용량 기반](../../subscriptions/gitlab_credits.md)입니다.

관리자는 GitLab Duo Agent Platform과 함께 사용할 [호환 모델](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)을 구성할 수 있습니다. AWS Bedrock 또는 Azure OpenAI를 사용하는 관리자는 Anthropic Claude 또는 OpenAI GPT 모델도 구성할 수 있습니다.

아직 Ultimate 버전이 아니신가요? [Duo Agent Platform이 포함된 무료 체험판 시작](https://docs.gitlab.com/#gitlab-duo-agent-platform-available-in-ultimate-trials).

### GitLab Duo Agent Platform(베타)을 통한 취약성 해결 {#vulnerability-resolution-with-gitlab-duo-agent-platform-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/duo_agent_platform/flows/foundational_flows/agentic_sast_vulnerability_resolution.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20150)

{{< /details >}}

SAST 취약성의 심사 및 수정은 애플리케이션 보안에서 가장 시간이 많이 걸리는 작업 중 하나입니다. 실제 취약성을 확인한 후 개발자는 발견 사항을 파악하고, 영향을 받는 코드를 찾으며, 적절한 수정을 작성해야 합니다. 이 모든 것은 시간과 전문 지식이 필요합니다. GitLab 18.9에서 우리는 Agentic SAST Vulnerability Resolution을 도입하고 있습니다. SAST 취약성에 대한 해결을 트리거하면 GitLab Duo는 자동으로 발견 사항을 분석하고, 주변 코드 컨텍스트를 이유 있게 살펴보며, 컨텍스트를 인식한 수정을 생성하고, 수동 개입 없이 머지 리퀘스트를 생성합니다.

주요 기능은 다음을 포함합니다:

- Agentic 다단계 해결: 단일 코드 제안을 생성하는 것이 아니라 GitLab Duo Agent Platform은 취약성을 이유 있게 살펴보고, 코드베이스를 평가하며, 잘 정보에 입각한 수정을 생성합니다.
- 자동 머지 리퀘스트 생성: 중요도와 높은 심각도 SAST 취약성에 대해 제안된 코드 수정이 포함된 검토 준비가 완료된 머지 리퀘스트를 생성합니다.
- 품질 점수: 생성된 각 수정에는 품질 평가가 포함되어 있어 검토자가 제안된 수정에 대한 신뢰도를 빠르게 파악할 수 있습니다.

SAST 취약성 해결은 취약성 보고서와 개별 취약성 세부 정보 페이지에서 사용 가능합니다. 개별 취약성 세부 정보 페이지에서 직접 해결을 트리거할 수 있습니다.

이 기능은 Ultimate 고객을 위한 무료 베타로 제공됩니다. 우리는 [이슈 585626](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)에서 피드백을 환영합니다.

### 축소 가능한 파일 트리를 사용하여 리포지토리 탐색 {#navigate-repositories-with-collapsible-file-tree}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/repository/files/file_tree_browser.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17781)

{{< /details >}}

이제 축소 가능한 파일 트리를 사용하여 리포지토리 파일을 찾아볼 수 있습니다. 트리는 프로젝트 구조에 대한 포괄적인 보기를 제공하므로 디렉토리를 인라인으로 확장 및 축소하고, 리포지토리의 다양한 부분에 있는 파일 간을 이동하며, 작업하는 동안 컨텍스트를 유지할 수 있습니다.

파일 트리는 리포지토리 파일이나 디렉토리를 볼 때 크기 조정 가능한 사이드바로 나타납니다. 키보드 단축키로 표시 여부를 전환하고, 이름이나 확장자로 파일을 필터링하며, 복잡한 프로젝트 계층을 탐색할 수 있습니다. 트리는 현재 위치와 동기화되므로 주 콘텐츠 영역에서 파일을 선택하면 트리가 업데이트되어 해당 파일을 표시합니다.

기존 리포지토리 구조와 파일 구성은 변경되지 않습니다. 파일 간에 이동하는 데 필요한 페이지 로드가 더 적으므로 이 기능은 소규모 프로젝트에서 수천 개의 파일이 있는 대규모 코드베이스로 확장됩니다.

### 파일에서 CI/CD 입력 포함 {#include-cicd-inputs-from-a-file}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../ci/inputs/_index.md#define-pipeline-inputs-in-external-files) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415636)

{{< /details >}}

이전에는 파이프라인 입력을 파이프라인의 spec 섹션 내에서만 정의할 수 있었습니다. 이 제한으로 인해 여러 프로젝트 간에 입력 구성을 재사용하기가 어려웠습니다.

이 릴리스에서는 이제 익숙한 `include` 키워드를 사용하여 외부 파일에서 입력 정의를 포함할 수 있습니다. 입력 목록을 별도의 위치에 유지할 수 있으면 많은 프로젝트 또는 파이프라인에 걸쳐 관리 가능한 솔루션을 가질 수 있습니다. 중앙 집중식 입력 구성을 유지할 수 있으며 외부 소스에서 입력 값을 동적으로 관리할 수도 있습니다.

### GitLab.com에서 웹 기반 커밋 서명 {#web-based-commit-signing-on-gitlabcom}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/project/repository/signed_commits/web_commits.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/17775)

{{< /details >}}

커밋이 암호화 방식으로 서명되도록 하는 것은 코드 무결성 및 규정 준수 요구 사항을 충족하는 데 필수적입니다. 이전에는 웹 기반 커밋 서명이 GitLab Self-Managed에서만 사용 가능했습니다.

이제 GitLab.com은 웹 기반 커밋 서명을 지원합니다. 그룹 또는 프로젝트에 대해 활성화되면 GitLab 웹 인터페이스를 통해 생성된 커밋은 GitLab 서명 키로 자동 서명되며 **검증됨** 배지로 표시되어 리포지토리의 진정성에 대한 암호화 증명을 제공합니다.

주요 세부 정보:

- 요구 사항에 따라 그룹 또는 프로젝트 설정에서 활성화합니다.
- 모든 웹 기반 커밋(Web IDE 편집, 병합, API 작업)은 활성화되면 자동으로 서명됩니다.

이는 GitLab.com 보안 기능을 GitLab Self-Managed와 일치하도록 하고 조직 전반에 걸친 포괄적인 커밋 서명 정책의 기초를 제공합니다.

### 컨테이너 가상 레지스트리 이제 사용 가능(베타) {#container-virtual-registry-now-available-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/packages/virtual_registry/container/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20820)

{{< /details >}}

최신 컨테이너 기반 개발에는 Docker Hub, Harbor, Quay 및 개인 레지스트리를 포함한 여러 레지스트리에서 이미지에 액세스해야 합니다. 컨테이너 가상 레지스트리 없이는 플랫폼 엔지니어가 각 프로젝트와 CI/CD 파이프라인을 구성하여 여러 레지스트리에서 개별적으로 인증하고 끌어와야 합니다. 이는 구성 복잡성을 증가시키고, 순차적 레지스트리 쿼리로 인한 끌어오기 속도를 저하시키며, 컨테이너 소스 전반에 일관된 보안 정책을 구현하기 어렵게 합니다.

컨테이너 가상 레지스트리는 여러 업스트림 컨테이너 레지스트리를 단일 엔드포인트 뒤에 집계하여 이러한 문제를 해결합니다. 플랫폼 엔지니어는 하나의 URL을 통해 오래 지속되는 토큰 인증을 사용하여 Docker Hub, Harbor, Quay 및 기타 레지스트리를 구성할 수 있습니다. 지능형 캐싱은 끌어오기 성능을 개선하는 한편 GitLab 인증 시스템과 통합되어 중앙 집중식 액세스 제어 및 감사 로깅을 제공합니다.

컨테이너 가상 레지스트리 API는 현재 GitLab Premium 및 Ultimate 고객을 위한 베타로 사용 가능합니다. 베타 참가자는 [GitLab API](../../api/container_virtual_registries.md)를 사용하여 컨테이너 가상 레지스트리를 생성하고, 공유 가능한 구성으로 여러 업스트림 소스를 구성하며, 가상 레지스트리를 통해 컨테이너 이미지를 끌어올 수 있습니다. 베타는 IAM 인증이 필요한 레지스트리를 지원하지 않습니다. IAM 인증이 필요한 클라우드 공급자 레지스트리에 대한 지원은 [이 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20919)에서 추적됩니다.

GitLab.com에서 이 기능은 기능 플래그 뒤에 있습니다. 액세스를 요청하거나 피드백을 공유하려면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630)에 댓글을 달아주세요.

### 새로운 보안 대시보드 차트: 경과 시간에 따른 취약성 {#new-security-dashboard-chart-vulnerabilities-by-age}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md#vulnerabilities-by-age) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/17417)

{{< /details >}}

새로운 **경과 시간에 따른 취약성** 차트는 환경에서 취약성이 얼마나 오래 열려 있었는지 이해하도록 도와줍니다.

차트는 처음 감지된 이후 경과된 시간을 기준으로 미해결 취약성의 분포를 보여줍니다. 취약성을 심각도 또는 보고서 유형별로 그룹화할 수 있어 수정 활동이 필요한 위치를 파악하는 데 도움이 됩니다.

## 에이전틱 코어 {#agentic-core}

### Self-Managed 및 Dedicated를 위한 JetBrains IDE의 OAuth 지원 {#oauth-support-in-jetbrains-ides-for-self-managed-and-dedicated}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [문서](https://docs.gitlab.com/editor_extensions/jetbrains_ide/setup/#authenticate-with-gitlab) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1337)

{{< /details >}}

JetBrains IDE용 GitLab Duo 플러그인은 이제 GitLab Self-Managed 및 GitLab Dedicated에 대한 OAuth 인증을 지원합니다. 이는 모든 JetBrains 사용자가 이제 더 빠르고 안전한 로그인 환경을 즐길 수 있음을 의미합니다. 개인 액세스 토큰이 필요하지 않습니다.

## 규모 및 배포 {#scale-and-deployments}

### 청구 불가능한 최소 액세스 사용자 {#non-billable-minimal-access-users}

<!-- categories: Seat Cost Management -->

{{< details >}}

- 티어: Premium
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/permissions.md#users-with-minimal-access) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/584275)

{{< /details >}}

이전에는 ID 공급자를 사용하여 GitLab Self-Managed Premium에서 사용자 프로비저닝을 자동화하는 조직이 잠재적인 문제에 직면할 수 있었습니다. ID 공급자 동기화가 라이선스가 있는 좌석 한도를 초과하는 사용자를 추가하려고 할 때 관리자는 활성 액세스가 필요하지 않은 사용자를 위해 추가 좌석을 구매하거나 실패를 방지하기 위해 수동으로 개입해야 합니다.

이제 GitLab Self-Managed Premium 구독의 최소 액세스 역할을 가진 사용자는 더 이상 청구 가능한 좌석으로 계산되지 않으며, GitLab.com Premium, GitLab.com Ultimate, GitLab Self-Managed Ultimate에서 최소 액세스가 작동하는 방식과 일치합니다. 이 변경은 ID 공급자 동기화 중에 좌석 한도를 초과할 수 있는 사용자에게 최소 액세스 역할을 자동으로 할당하는 [제한된 액세스](../../subscriptions/manage_seats.md#restricted-access) 기능을 활성화합니다. 이 변경은 예상치 못한 청구 초과 또는 수동 개입 없이 동기화가 순조롭게 실행되도록 유지합니다.

### 기본 사이트의 Geo 데이터 관리 보기 {#geo-data-management-view-on-primary-site}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../administration/admin_area.md#data-management)

{{< /details >}}

이제 기본 사이트에서 직접 데이터 무결성을 문제 해결하고 확인할 수 있습니다. 이는 기본 Geo 사이트에 자세한 확인 상태 정보를 제공하는 새로운 데이터 관리 보기 덕분입니다. 이 개선 사항은 기본 확인 및 문제 해결 작업을 위해 보조 사이트에 액세스해야 할 필요를 없앱니다.

이전에는 이 확인 상태를 보조 사이트 UI를 통해서만 액세스할 수 있었습니다. 이제 기본 사이트의 데이터 관리 보기를 사용하여 다음을 수행할 수 있습니다:

- 기본 사이트에서 모든 복제 가능한 데이터 유형에 대한 자세한 확인 상태 보기
- 기본 UI에서 직접 데이터 삭제 및 문제 해결 작업 수행
- 보조 사이트를 추가하기 전에 기본 사이트에서 Geo 구성 설정 및 확인

이 개선 사항은 UI를 사용한 포괄적인 자체 서비스 이슈 해결을 향한 첫 번째 단계이며, 일상적인 유지보수 및 이슈 해결을 위해 여러 사이트에 액세스해야 할 필요를 줄입니다.

### Ultimate 평가판에서 사용 가능한 GitLab Duo Agent Platform {#gitlab-duo-agent-platform-available-in-ultimate-trials}

<!-- categories: Acquisition, Duo Agent Platform -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../subscriptions/free_trials.md#gitlab-duo-agent-platform-trials) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20353)

{{< /details >}}

GitLab을 평가하는 팀은 이제 복잡한 개발 워크플로우를 자동화하고 수동 작업을 줄이는 에이전트 AI 기능을 테스트할 수 있습니다. GitLab Ultimate 평가판에 가입하고 사용자당 24개의 평가 크레딧과 함께 Duo Agent Platform에 액세스할 수 있으며, 30일 평가 기간 동안 자율 작업 실행 및 다단계 워크플로우 오케스트레이션의 실제 경험을 할 수 있습니다. 평가 크레딧은 프로비저닝 날짜로부터 30일 동안 사용 가능하므로 시작하기 전에 팀의 준비 상태를 고려하세요.

[무료 평가판 시작](https://gitlab.com/-/trial_registrations/new). 현재 유료 고객은 계정 팀을 통해 평가 크레딧에 액세스할 수 있습니다. [영업팀에 문의](https://about.gitlab.com/sales/)하여 자세히 알아보세요.

### 이제 Cloud Native Hybrid 배포를 위해 Zero Downtime Upgrade 지원 {#zero-downtime-upgrades-now-supported-for-cloud-native-hybrid-deployments}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/charts/installation/upgrade/#upgrade-with-zero-downtime)

{{< /details >}}

Zero Downtime Upgrade는 이제 Cloud Native Hybrid 배포에 대해 공식 지원됩니다.

엔터프라이즈 고객은 DevSecOps 플랫폼을 항상 사용할 수 있어야 하므로 업그레이드 관련 다운타임이 중요한 운영 문제입니다. 지금까지 Zero Downtime Upgrade는 Linux 패키지 기반 고가용성 배포에만 지원되었으며, 이는 많은 고객이 클라우드 네이티브 Kubernetes 배포가 인프라 전략에 더 적합했을 때에도 VM 기반 아키텍처로 향하게 했습니다.

우리는 수년 동안 자신의 Cloud Native Hybrid SaaS 인스턴스를 제로 다운타임으로 업그레이드해왔습니다. 이 릴리스로 우리는 Kubernetes에서 GitLab을 실행하는 자체 관리 고객에게 동일한 운영 경험을 제공하고 있습니다.

업그레이드 절차는 포괄적으로 테스트되었으며 이제 완전히 문서화되어 버전 업그레이드 중에 가용성을 유지할 수 있다는 자신감을 제공합니다.

### 그룹 및 해당 콘텐츠 보관 {#archive-a-group-and-its-content}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/group/manage.md#archive-a-group) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15019)

{{< /details >}}

완료된 이니셔티브 및 포기된 프로젝트 관리가 이제 더 쉬워졌습니다. 이제 모든 하위 그룹 및 프로젝트를 포함한 전체 그룹을 한 번에 보관할 수 있으며, 각 프로젝트를 수동으로 보관해야 할 필요가 없습니다.

그룹을 보관할 때:

- 모든 중첩된 하위 그룹 및 프로젝트가 자동으로 보관됩니다.
- 보관된 콘텐츠는 명확한 상태 배지와 함께 **비활성** 탭으로 이동합니다.
- 그룹 데이터는 참조 또는 복구를 위해 읽기 전용 모드에서 완전히 액세스할 수 있습니다.
- 쓰기 권한이 보관된 그룹 및 해당 콘텐츠 전반에 걸쳐 비활성화됩니다.

**설정** 페이지 외에도 목록 보기의 작업 메뉴에서 직접 그룹 및 프로젝트를 보관할 수 있습니다. 더 이상 간단한 관리 작업을 위해 여러 화면을 탐색할 필요가 없습니다. 이 매우 요청된 기능은 관리 오버헤드를 크게 줄이는 동시에 활성 작업과 비활성 작업 간의 명확한 분리로 작업 공간을 정리된 상태로 유지합니다. [에픽 18616](https://gitlab.com/groups/gitlab-org/-/epics/18616)에서 피드백을 공유하세요.

### Redis의 대체 옵션으로 Valkey(베타) {#valkey-as-replacement-option-for-redis-beta}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/redis/_index.md#use-valkey-instead-of-redis)

{{< /details >}}

GitLab 18.9부터 Valkey는 Linux 패키지의 Redis에 대한 선택적 대체로 번들됩니다. Redis는 라이선스를 AGPLv3으로 변경했으며, 이는 오픈 소스 고객에게 적합하지 않습니다. GitLab Self-Managed 고객의 보안 및 유지보수성을 보장하기 위해 우리는 Redis에서 Valkey로 전환하고 있으며, Valkey는 허용 가능한 BSD 라이선스를 유지하는 커뮤니티 기반 포크입니다.

전환 일정:

- GitLab 18.9(이 릴리스): Valkey는 선택적 대체(베타)로 번들됩니다. 편의에 따라 Redis에서 Valkey로 전환할 수 있습니다. Valkey Sentinel 지원이 포함됩니다.
- GitLab 19.0(2026년 5월): Valkey가 기본값이 되고 Redis 바이너리가 Linux 패키지에서 제거됩니다. 기존 Redis 구성 설정은 계속 기능하며 역호환성을 위해 적용됩니다.

이 전환은 Linux 패키지의 번들 Redis에만 영향을 줍니다. 외부 Redis 배포를 사용하는 확장된 아키텍처의 고객은 Redis를 계속 사용할 수 있습니다. 우리는 Redis와 Valkey 간의 잠재적 기능 차이를 모니터링하고 있으며 에코시스템이 발전함에 따라 지침을 제공할 것입니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Java pom.xml 매니페스트 파일에 대한 SBOM 지원이 있는 종속성 검사 {#dependency-scanning-with-sbom-support-for-java-pomxml-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/585886)

{{< /details >}}

GitLab [SBOM을 사용한 종속성 검사](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)는 이제 Java `pom.xml` 매니페스트 파일 스캔을 지원합니다. 이전에는 Maven을 사용하는 Java 프로젝트의 종속성 검사에는 그래프 파일이 있어야 했습니다. 이제 그래프 파일을 사용할 수 없으면 분석기가 자동으로 `pom.xml` 파일 스캔으로 대체하여 취약성 분석을 위해 직접 종속성만 추출하고 보고합니다. 이 개선으로 Java 프로젝트가 그래프 파일을 요구하지 않고도 종속성 검사를 더 쉽게 활성화할 수 있습니다.

매니페스트 대체를 활성화하려면 `DS_ENABLE_MANIFEST_FALLBACK` CI/CD 변수를 `"true"`로 설정합니다.

### Python requirements.txt 매니페스트 파일에 대한 SBOM 지원이 있는 종속성 검사 {#dependency-scanning-with-sbom-support-for-python-requirementstxt-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/586921)

{{< /details >}}

GitLab [SBOM을 사용한 종속성 검사](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)는 이제 Python `requirements.txt` 매니페스트 파일 스캔을 지원합니다. 이전에는 Python 프로젝트의 종속성 검사에는 잠금 파일이 있어야 했습니다. 이제 잠금 파일을 사용할 수 없으면 분석기가 자동으로 `requirements.txt` 파일 스캔으로 대체하여 취약성 분석을 위해 직접 종속성만 추출하고 보고합니다. 이 개선으로 Python 프로젝트가 잠금 파일을 요구하지 않고도 종속성 검사를 더 쉽게 활성화할 수 있습니다.

매니페스트 대체를 활성화하려면 `DS_ENABLE_MANIFEST_FALLBACK` CI/CD 변수를 `"true"`로 설정합니다.

### 엔터프라이즈 사용자에 대해 개인 스니펫 제한 {#restrict-personal-snippets-for-enterprise-users}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/group/manage.md#restrict-personal-snippets-for-enterprise-users)

{{< /details >}}

GitLab.com을 사용하는 조직은 엔터프라이즈 사용자가 개인 스니펫을 통해 민감한 코드를 실수로 노출하지 않도록 해야 합니다. 이전에는 사용자가 개인 네임스페이스에서 스니펫을 생성하는 것을 방지할 방법이 없었으며, 스니펫이 실수로 공개로 설정되면 보안 위험이 될 수 있습니다.

그룹 소유자는 이제 엔터프라이즈 사용자에 대해 개인 스니펫 생성을 제한할 수 있으며, 코드가 공유되는 위치에 대한 더 엄격한 제어를 유지하는 데 도움이 됩니다. 제한되면 엔터프라이즈 사용자는 개인 네임스페이스에서 스니펫을 생성할 수 없습니다.

### Rapid Diffs는 커밋 변경 사항에 대한 성능 개선 {#rapid-diffs-improves-performance-for-commit-changes}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/repository/commits/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/17804)

{{< /details >}}

많은 변경된 파일이나 실질적인 수정 사항으로 커밋을 검토하는 것은 느릴 수 있습니다. Rapid Diffs 기술은 이제 커밋 페이지(`/-/commits/<SHA>`)를 구동하여 더 빠른 로드 시간, 더 부드러운 스크롤 및 더 빠른 응답성 상호 작용을 제공합니다.

Rapid Diffs를 사용하면 다음을 알 수 있습니다:

- 페이지 매김이 없는 환경입니다.
- 더 빠른 초기 로드로 더 빨리 코드 작업을 시작할 수 있습니다.
- 파일 간에 더 빠르게 탐색할 수 있는 새로운 파일 브라우저가 있는 새로 고쳐진 인터페이스입니다.
- 변경된 파일이 많은 경우에도 반응형 상호 작용입니다.

기존 기능은 모두 보존됩니다. Rapid Diffs가 GitLab의 다른 영역으로 확장되면 동일한 성능 이점이 따릅니다.

### 가져오기 API에서 Bitbucket Cloud API 토큰 지원 {#support-for-bitbucket-cloud-api-tokens-in-import-api}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../api/import.md#import-repository-from-bitbucket-cloud)

{{< /details >}}

GitLab 가져오기 API는 이제 Bitbucket Cloud API 토큰을 지원하여 Bitbucket Cloud에서 리포지토리를 가져오는 보다 안전한 방법을 제공합니다.

[Atlassian이 앱 비밀번호를 더 이상 사용하지 않습니다](https://www.atlassian.com/blog/bitbucket/bitbucket-cloud-transitions-to-api-tokens-enhancing-security-with-app-password-deprecation). 대신 API 토큰을 사용하고 있으며, 우리는 19.0에서 앱 비밀번호 지원을 제거할 계획입니다.

GitLab UI를 통해 Bitbucket Cloud에서 가져오기는 이 변경의 영향을 받지 않습니다.

### 중앙 집중식 보안 거버넌스 및 구성 {#centralized-security-governance-and-configuration}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

조직 전체에서 보안 스캐너 범위를 관리하고 시각화합니다. 이 릴리스는 보안 구성 프로필을 도입하며, 시크릿 검색 프로필부터 시작합니다. 보안 팀은 이제 대규모 조직을 보호할 수 있는 더 강력한 지휘 센터를 갖추고 있습니다.

**Profile-based security configuration**

각 프로젝트에 대해 YAML 파일을 수동으로 편집하는 대신 이제 여러 이점을 제공하는 사전 구성된 보안 구성 프로필을 사용할 수 있습니다:

- 표준화된 거버넌스: 사전 구성된 프로필은 생산성을 방해하지 않고 적절한 경계를 적용합니다. 사용자 지정 역할 구성을 요구하지 않고도 표준화된 보안 모범 사례를 적용할 수 있습니다.
- 확장 가능한 관리: 한 번의 작업으로 수백 또는 수천 개의 프로젝트에 동일한 프로필을 적용합니다.

시크릿 검색 프로필은 사용 가능한 첫 번째 보안 구성 프로필입니다. 다음과 같은 이점을 제공합니다:

- 활성적으로 시크릿을 식별하고 리포지토리에 커밋되는 것을 차단합니다.
- 하나의 프로필이 전체 개발 워크플로우 전반에서 시크릿 검색을 관리합니다. 다양한 트리거 유형에 대해 별도의 구성을 관리할 필요가 없습니다.

**Enhanced security inventory**

보안 인벤토리는 각 그룹의 보안 태세를 평가하기 위한 기본 대시보드 역할을 하도록 업그레이드되었습니다:

- 그룹 및 프로젝트 계층: 명확한 아이콘으로 인벤토리의 하위 그룹과 프로젝트를 쉽게 구별합니다.
- 일괄 작업: 새 **Bulk Action** 메뉴를 사용하면 모든 선택된 프로젝트 및 하위 그룹에 걸쳐 보안 스캐너 프로필을 동시에 적용하거나 비활성화할 수 있습니다.
- 시각적 범위 상태: 색상으로 구분된 상태 표시줄(활성화됨, 활성화 안 됨 또는 실패함)을 빠르게 식별하여 세부 정보에 대한 도움말을 표시합니다.
- 프로필 상태 표시기: 프로필 세부 정보에서 사용 가능한 트리거 유형을 확인합니다.

### 보안 속성 {#security-attributes}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/attributes/_index.md)

{{< /details >}}

보안 속성([GitLab 18.6에서 베타로 도입됨](gitlab-18-6-released.md#security-attributes-beta))은 이제 일반 공급됩니다.

보안 속성을 통해 보안 팀은 비즈니스 영향, 애플리케이션, 비즈니스 단위, 인터넷 노출 및 위치를 포함하여 프로젝트에 비즈니스 컨텍스트를 적용할 수 있습니다. 조직의 분류법과 일치하도록 사용자 지정 속성 범주를 만들 수도 있습니다. 이러한 속성을 적용하면 위험 태세 및 조직 컨텍스트를 기반으로 보안 인벤토리의 항목을 필터링하고 우선 순위를 지정할 수 있습니다.

### 보안 대시보드: 시간에 따른 취약성 차트 개선 {#security-dashboards-vulnerabilities-over-time-chart-improvements}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md#vulnerabilities-over-time) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/19780)

{{< /details >}}

**시간에 따른 취약성** 차트가 업데이트되어 취약성 인벤토리를 보다 정확하게 볼 수 있습니다.

차트는 이전에 더 이상 감지되지 않는 취약성을 포함했으며, 활성 취약성의 상태를 정확하게 나타내지 않은 부풀려진 숫자로 이어졌습니다.

우리는 일부 경우에 수를 약간 변경할 수 있는 두 가지 추가 이슈를 알고 있습니다. [이슈 590022](https://gitlab.com/gitlab-org/gitlab/-/issues/590022) 및 [이슈 590018](https://gitlab.com/gitlab-org/gitlab/-/issues/590018)을 팔로우하여 업데이트를 확인하세요.

### 프로젝트에 대해 CI/CD 작업 메트릭 보기(제한적 출시) {#view-cicd-job-metrics-for-projects-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/analytics/ci_cd_analytics.md#cicd-job-performance-metrics) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18548)

{{< /details >}}

GitLab CI/CD 파이프라인 분석은 이제 CI/CD 파이프라인 및 CI/CD 작업 성능 추세를 결합하여 개발자가 비효율적이거나 문제가 있는 CI/CD 작업을 빠르게 식별할 수 있습니다. 이러한 기능은 GitLab UI에 직접 포함되어 있으므로 개발자는 CI/CD 작업 성능 문제를 식별하고 해결하는 데 필요한 도구를 컨텍스트에 갖추고 있어 개발 팀의 속도와 전체 생산성에 큰 영향을 미칠 수 있습니다. 플랫폼 관리자의 경우 이 보기의 CI/CD 작업 데이터는 엔터프라이즈 규모에서 GitLab을 운영할 때 외부 또는 사용자 정의 CI/CD 작업 관찰성 솔루션을 사용해야 할 필요성을 줄입니다.

### CI 작업 로그에 타임스탬프 추가 {#add-timestamps-to-ci-job-logs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../ci/jobs/job_logs.md#timestamps) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/202293)

{{< /details >}}

이제 각 CI 작업 로그 줄의 타임스탬프를 보고 성능 병목 현상을 식별하고 오래 실행되는 작업을 디버그할 수 있습니다. 타임스탬프는 UTC 형식으로 표시됩니다. 타임스탬프를 사용하여 성능 문제를 이슈 해결하고, 병목 현상을 식별하고, 특정 빌드 단계의 기간을 측정합니다. GitLab Self-Managed의 경우 GitLab 러너 18.7 이상이 필요합니다.

### CI/CD 카탈로그 컴포넌트 분석 {#cicd-catalog-component-analytics}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../ci/components/_index.md#view-cicd-catalog-project-analytics) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/579458)

{{< /details >}}

이전에는 팀이 조직 전체에서 CI/CD 카탈로그 컴포넌트 프로젝트가 어떻게 사용되고 있는지에 대한 가시성이 부족했습니다. 이제 높은 수준에서 사용량 수와 채택 패턴을 볼 수 있으며, 어느 컴포넌트 프로젝트가 가장 가치 있는지 이해하고 카탈로그 투자를 최적화할 수 있습니다.

### 머지 리퀘스트에서 하위 파이프라인의 보안 보고서 보기 {#view-security-reports-from-child-pipelines-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18377)

{{< /details >}}

이제 머지 리퀘스트 위젯에서 직접 하위 파이프라인의 보안 및 규정 준수 보고서를 볼 수 있습니다. 이전에는 여러 파이프라인을 수동으로 탐색하여 보안 이슈를 식별해야 했으며, 특히 모노리포 및 복잡한 테스트 설정에서 비효율적인 워크플로우를 만들었습니다.

이 개선으로 머지 리퀘스트 위젯은 하위 파이프라인의 보고서를 상위 파이프라인 결과와 함께 직접 표시하며, 각 하위 파이프라인의 보고서가 개별적으로 표시되고 다운로드할 수 있는 아티팩트가 있습니다. 이는 모든 보안 검사를 통합된 보기로 제공하여 실패 조사에 소요되는 시간을 크게 줄이고 상위-하위 파이프라인을 사용할 때 더 빠른 머지 리퀘스트 검토를 가능하게 합니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.9)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
