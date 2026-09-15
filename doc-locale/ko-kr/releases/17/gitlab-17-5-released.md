---
stage: Release Notes
group: Monthly Release
date: 2024-10-17
title: "GitLab 17.5 릴리스 정보"
description: "Duo Quick Chat 소개와 함께 GitLab 17.5 릴리스"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 10월 17일에 GitLab 17.5가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Jim Ender {#this-months-notable-contributor-jim-ender}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Jim은 GitLab에서 [거의 100개의 백로그 이슈를 종료](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=closed&assignee_username%5B%5D=Jimender2&first_page_size=100)하는 노력을 주도한 것으로 인정받았습니다. 그는 흥미로운 토론을 나누는 많은 주간 커뮤니티 페어링 세션에 적극적으로 참여합니다. Jim은 또한 [GitLab Community Discord](https://discord.gg/gitlab)에서 GitLab 지원 요청을 해결하고 새로운 기여자를 안내하며 사람들을 지원합니다. Jim은 중요 인프라 및 ERP 시스템용 소프트웨어를 작성하는 산업 기술 회사에서 일합니다.

"작은 기여도 프로젝트를 개선하는 데 도움이 된다"고 Jim은 말합니다. "문서 기여와 같은 작은 것도 다른 사람들에게 도움이 됩니다. 전체 새로운 기능을 주도할 필요는 없습니다."

Jim은 GitLab의 기여자 성공 담당 직원인 [Lee Tickett](https://gitlab.com/leetickett-gitlab)에 의해 추천되었습니다. "이슈 분류/큐레이션은 더 넓은 커뮤니티를 참여시키기 위한 제 목록의 맨 위에 있었고, Jim은 여기서 길을 닦고 있습니다."라고 Lee는 말합니다.

GitLab의 기여자 성공 담당 시니어 프로그램 매니저인 [Daniel Murphy](https://gitlab.com/daniel-murphy)가 추천에 의견을 추가했습니다. "새로운 기여자에 대한 Jim의 뛰어난 지원과 그들을 시작하도록 지도하는 것은 우리가 GitLab을 함께 만드는 커뮤니티로 성장하도록 도와줍니다."

"제가 검토한 [머지 리퀘스트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163849)에서 인상적인 작업을 했습니다!"라고 GitLab의 시니어 프론트엔드 엔지니어인 [Vanessa Otto](https://gitlab.com/vanessaotto)는 말합니다. "Jim은 빠르게 반응했고, 제안을 즉시 이해했으며, 이를 완벽하게 구현했습니다. Jim의 접근 방식에서 그러한 효율성과 명확성을 보는 것이 좋았습니다."

Jim과 GitLab에 기여한 모든 오픈소스 커뮤니티에 매우 감사합니다!

## 주요 기능 {#primary-features}

### Duo Quick Chat 소개 {#introducing-duo-quick-chat}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md#in-an-editor-window) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15218)

{{< /details >}}

코드에 있는 정확한 위치에서 작동하도록 설계된 AI 기반 채팅인 Duo Quick Chat을 소개합니다. Duo Quick Chat은 편집 중인 줄에서 직접 작동하여 코드에서 벗어나지 않고도 실시간 지원을 제공합니다. 리팩토링, 버그 수정, 테스트 작성 중 어느 것을 하든 Duo Quick Chat은 그 자리에서 제안과 설명을 제공하여 컨텍스트를 전환하지 않고 완전히 집중할 수 있게 합니다.

### GitLab Duo Code Suggestions를 위해 자체 호스팅 모델 사용 {#use-self-hosted-model-for-gitlab-duo-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/498114)

{{< /details >}}

이제 선택한 대규모 언어 모델(LLM)을 자체 인프라에서 호스팅하고 이러한 모델을 Code Suggestions의 소스로 구성할 수 있습니다. 이 기능은 베타 상태이며 자체 관리되는 GitLab 환경에서 Ultimate 및 Duo Enterprise 구독으로 사용할 수 있습니다.

자체 호스팅 모델을 사용하면 온프레미스 또는 프라이빗 클라우드에서 호스팅된 모델을 사용하여 GitLab Duo Code Suggestions을 활성화할 수 있습니다. 현재 vLLM 또는 AWS Bedrock에서 오픈소스 Mistral 모델을 지원합니다. 자체 호스팅 모델을 활성화하면 완전한 데이터 주권과 개인정보 보호를 유지하면서 생성형 AI의 강력한 기능을 활용할 수 있습니다.

[피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/498376)에 피드백을 남겨주세요.

### 코드 제안 사용량 이벤트 내보내기 {#export-code-suggestion-usage-events}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../api/graphql/reference/_index.md#codesuggestionevent) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/477231)

{{< /details >}}

이전에는 AI 영향 분석이 GitLab.com의 GitLab Duo Enterprise 고객과 ClickHouse 통합을 통한 GitLab Self-Managed에서만 사용 가능했습니다. 또한 기본 메트릭은 집계되었습니다.

이제 GraphQL API에서 원본 코드 제안 이벤트를 내보낼 수 있습니다. 이러한 방식으로 데이터를 데이터 분석 도구로 가져와 제안 크기, 언어 및 사용자와 같은 더 많은 차원에서 승인률에 대한 더 깊은 통찰력을 얻을 수 있습니다. 원본 이벤트는 ClickHouse에 저장되지 않으므로 일부 AI 영향 분석 메트릭이 GitLab Dedicated 및 자체 관리를 포함한 모든 GitLab 배포에서 사용 가능해집니다.

### GitLab Duo Chat으로 머지 리퀘스트에 대해 대화하기 {#have-a-conversation-with-gitlab-duo-chat-about-your-merge-request}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../user/gitlab_duo_chat/examples.md#ask-about-a-specific-merge-request) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/464587)

{{< /details >}}

사용자 피드백에 대응하여 GitLab Duo Chat은 이제 머지 리퀘스트를 인식합니다. 검토자이든 작성자이든 이제 Chat과 머지 리퀘스트에 대해 대화하여 빠르게 파고들거나 다음에 할 일을 배울 수 있습니다. 머지 리퀘스트를 열고 Duo Chat을 열어서 대화를 시작하세요.

이 새로운 기능은 GitLab Duo에 [코드 변경 사항을 요약](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)하도록 요청하여 머지 리퀘스트의 설명을 빠르게 채울 수 있는 기존 기능을 보완하므로 검토자는 머지 리퀘스트가 무엇인지에 대한 일반적인 이해를 얻을 수 있습니다.

### 향상된 브랜치 규칙 편집 기능 {#enhanced-branch-rules-editing-capabilities}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/branches/branch_rules.md#create-a-branch-rule)

{{< /details >}}

GitLab 15.10에서는 [브랜치 관련 설정 및 규칙의 통합 보기](https://about.gitlab.com/releases/2023/03/22/gitlab-15-10-released/#see-all-branch-related-settings-together)를 도입했습니다. 이 보기는 여러 설정에서 프로젝트 구성을 이해하는 쉬운 방법을 제공했습니다.

이 기능을 기반으로 이제 브랜치 보호, 승인 규칙 및 외부 상태 확인 구성을 포함하여 이 보기에서 특정 브랜치 규칙을 직접 수정할 수 있습니다. 이러한 새로운 기능은 향후 더 큰 유연성을 허용하는 브랜치 구성의 [지속적인 개선](https://gitlab.com/groups/gitlab-org/-/epics/12546)을 위한 기초를 제공합니다.

이러한 새로운 기능을 탐색하고 피드백을 제공하도록 권장합니다. 전용 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/486050)에 기여하여 이를 수행할 수 있습니다.

### Switchboard의 GitLab Dedicated 테넌트 개요 {#gitlab-dedicated-tenant-overview-in-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../administration/dedicated/tenant_overview.md)

{{< /details >}}

Switchboard의 새로운 테넌트 개요는 GitLab Dedicated 인스턴스에 대한 필수 정보에 빠르게 액세스할 수 있는 단일 위치를 제공합니다.

이 첫 번째 릴리스에서는 테넌트 개요 페이지에서 현재 GitLab 버전, 인스턴스 URL, 예정된 유지보수 윈도우 및 과거 유지보수 윈도우의 날짜 및 시간을 볼 수 있습니다.

### 비밀 푸시 보호가 일반적으로 사용 가능 {#secret-push-protection-is-generally-available}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/secret_detection/secret_push_protection/_index.md)

{{< /details >}}

모든 GitLab Ultimate 고객을 위해 비밀 푸시 보호가 이제 일반적으로 사용 가능하다는 것을 알리게 되어 기쁩니다.

키 또는 API 토큰과 같은 비밀이 실수로 Git 리포지토리에 커밋되면 리포지토리에 액세스할 수 있는 누구든 악의적 목적으로 비밀 사용자를 사칭할 수 있습니다. 유출된 비밀은 시간과 비용이 드는 비용이 들고 회사의 평판을 잠재적으로 손상시킵니다. 비밀 푸시 보호는 비밀이 처음부터 푸시되는 것을 방지하여 수정 시간을 줄이고 위험을 줄이는 데 도움이 됩니다.

비밀 푸시 보호는 베타 릴리스 이후 개선되었습니다. Git CLI를 사용하여 커밋을 푸시할 때 이제 변경 사항(diff)만 비밀에 대해 스캔됩니다. 거짓 양성을 방지하기 위해 경로, 규칙 또는 특정 값을 제외하기 위한 실험적 지원도 추가했습니다.

[블로그](https://about.gitlab.com/blog/prevent-secret-leaks-in-source-code-with-gitlab-secret-push-protection/)를 참조하세요.

### GitLab.com에서 사용 가능한 자격 증명 인벤토리 {#credentials-inventory-available-on-gitlabcom}

<!-- categories: System Access -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../administration/credentials_inventory.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/297441)

{{< /details >}}

자격 증명 인벤토리는 이제 GitLab.com의 최상위 그룹 소유자가 사용할 수 있습니다. 자격 증명 인벤토리에서 그룹 전체에서 [엔터프라이즈 사용자의](../../user/enterprise_user/_index.md) 개인 액세스 토큰 및 SSH 키를 볼 수 있습니다. 자격 증명을 해지, 삭제 및 추가 정보를 볼 수도 있습니다. 이전에는 GitLab 자체 관리의 관리자만 사용할 수 있었습니다.

그룹 소유자는 자격 증명 인벤토리를 사용하여 자신의 권한 내에 존재하는 자격 증명을 이해하고 가시성과 제어를 강화할 수 있습니다.

### 종속성 목록의 구성 요소 필터 {#component-filter-on-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_list/_index.md#filter-dependency-list) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12652)

{{< /details >}}

이제 GitLab에서 특정 종속성 구성 요소를 빠르게 필터링하여 그룹 또는 프로젝트에서 사용되는지 여부를 식별할 수 있습니다. 특정 패키지 및 버전이 있는지 확인하기 위해 전체 목록을 수동으로 검토하는 것은 시간이 많이 소요되고 불편합니다. 종속성 목록의 새로운 **filter by component**을 사용하면 취약한 종속성을 격리하여 애플리케이션의 개방형 위험을 평가할 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### GitLab 차트 개선 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/charts/)

{{< /details >}}

GitLab 17.5에는 NGINX Ingress Controller 버전이 업데이트되었습니다. `nginx-controller` 컨테이너 이미지는 이제 버전 1.11.2입니다. 새 컨트롤러는 이제 endpointslices를 사용하고 이에 액세스하기 위한 RBAC 규칙이 필요하므로 새로운 RBAC 요구 사항이 포함됩니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.5에는 단일 노드 설치를 위해 PostgreSQL을 버전 14.x에서 16.x로 업그레이드하는 지원이 포함됩니다. 자동 업그레이드는 활성화되지 않으므로 PostgreSQL 업그레이드는 수동으로 트리거해야 합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 코딩을 향상시키세요: Windows용 Visual Studio의 Duo Chat {#elevate-your-coding-duo-chat-now-in-visual-studio-for-windows}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-visual-studio-for-windows) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/77)

{{< /details >}}

이제 Windows용 Visual Studio에 완벽하게 통합된 Duo Chat으로 개발 워크플로우를 강화합니다. Duo Chat은 설명, 개선, 디버그 코드 또는 실시간으로 테스트를 작성하는 AI 기반 기능을 제공하여 코딩 경험을 향상시킵니다. 이 통합을 통해 친숙한 개발 환경 내에서 Duo Chat의 고급 AI 도구를 직접 활용할 수 있으므로 생산성이 향상되고 더 빠르고 효율적인 문제 해결이 가능합니다.

### REST API를 사용하여 에이전트 및 GitOps 환경 설정 구성 {#configure-agent-and-gitops-environment-settings-with-the-rest-api}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/environments.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/412677)

{{< /details >}}

GitLab 환경 UI에서 포드 및 Flux 조정 상태를 확인할 수 있습니다. 하지만 필수 설정이 GraphQL 또는 UI를 통해서만 노출되므로 이 접근 방식은 확장하기 어렵습니다. 이제 GitLab은 Kubernetes용 에이전트 구성뿐만 아니라 환경당 네임스페이스 및 Flux 리소스 설정을 위한 REST API 지원과 함께 제공됩니다. 동적 환경에 대한 지원을 더욱 개선하기 위해 [이슈 467912](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)는 CI/CD 파이프라인에서 이러한 설정 구성 지원을 추가할 것을 제안합니다.

### GitLab Kubernetes 통합의 쉬운 부트스트래핑 {#easy-bootstrapping-of-gitlab-kubernetes-integration}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/install/_index.md#bootstrap-the-agent-with-flux-support-recommended) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/473987)

{{< /details >}}

GitLab은 [Kubernetes용 에이전트](../../user/clusters/agent/_index.md) 및 [Flux 통합](../../user/clusters/agent/gitops.md)을 통해 유연하고 안정적이며 안전한 GitOps 지원을 제공합니다. 그러나 Flux를 GitLab과 부트스트래핑하고 Kubernetes용 에이전트를 설정하려면 많은 문서 읽기와 GitLab UI와 터미널 간의 전환이 필요했습니다. GitLab CLI는 이제 [`glab cluster agent bootstrap` 명령](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md)을 제공하여 기존 Flux 설치 위에 에이전트를 설치하는 것을 간단히 합니다. 이제 두 가지 간단한 명령으로 Flux와 에이전트를 구성할 수 있습니다.

### 방화벽이 있는 GitLab 설치를 위한 Kubernetes 통합 지원 {#kubernetes-integration-support-for-firewalled-gitlab-installations}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md#receptive-agents) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437014)

{{< /details >}}

지금까지 Kubernetes용 에이전트는 Kubernetes 클러스터가 GitLab 인스턴스에 연결할 수 있는 경우에만 사용할 수 있었습니다. 이 이슈는 예를 들어 GitLab을 프라이빗 네트워크에서 실행하거나 방화벽 뒤에 있는 경우 일부 고객이 에이전트를 사용할 수 없다는 의미였습니다. GitLab 17.5부터 제대로 구성된 `agentk` 인스턴스가 이미 연결 초기화를 기다리고 있다고 가정하고 GitLab에서 클러스터-GitLab 연결을 시작할 수 있습니다.

초기 연결이 설정되면 에이전트의 모든 기능을 사용할 수 있습니다. 클러스터에서 초기화하는 것은 이 개발으로 변경되지 않습니다.

### Stream Kubernetes 리소스 이벤트 {#stream-kubernetes-resource-events}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/470042)

{{< /details >}}

GitLab은 Kubernetes용 대시보드를 통해 포드의 실시간 보기 및 포드 로그 스트리밍을 제공합니다. GitLab 17.4에서는 UI의 리소스별 이벤트 정보의 정적 목록을 제공했습니다. 이 릴리스는 클러스터에서 나타나는 수신 이벤트를 스트리밍할 수 있도록 하여 Kubernetes 대시보드를 더욱 개선합니다.

### GitLab UI에서 GitOps 조정 일시 중지 또는 재개 {#suspend-or-resume-gitops-reconciliation-from-the-gitlab-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md#suspend-or-resume-flux-reconciliation) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/478380)

{{< /details >}}

Flux 사용자로서 자동 조정 또는 드리프트 수정을 빠르게 중지해야 한다고 생각한 적이 있습니까? `HelmRelease`을(를) 트리거하여 수동으로 제거된 리소스를 동기화하시겠습니까? 이러한 작업은 Flux 일시 중지 및 재개 함수로 가장 잘 달성됩니다. 지금까지 최선의 옵션은 Flux CLI를 사용하는 것이었으며, 올바른 리소스가 영향을 받도록 컨텍스트 전환 및 여러 명령이 필요했습니다. GitLab 17.5에서는 Kubernetes용 기본 제공 대시보드에서 조정을 일시 중지하거나 재개할 수 있습니다.

### 개선된 사용자 관리 요약 {#improved-user-management-summary}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/456332)

{{< /details >}}

관리자는 이제 인스턴스의 사용자에 대한 다음과 같은 중요한 정보의 향상되고 요약된 보기를 갖게 됩니다:

- 승인 대기 중입니다.
- 2단계 인증 없음.
- 관리자입니다.

이는 관리자가 요약 보기에서 이러한 상태의 사용자 수를 빠르게 확인하고 필터링할 수 있으므로 사용자 관리 효율성을 증가시킵니다.

### 보안 정책 범위에 그룹 추가 {#add-groups-to-security-policy-scope}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14149)

{{< /details >}}

이제 보안 정책 범위의 그룹/하위 그룹을 대상으로 지정할 수 있습니다. 이는 그룹/하위 그룹의 모든 프로젝트, 정의된 프로젝트 목록을 기반으로 한 프로젝트, 준수 프레임워크 레이블 목록과 일치하는 프로젝트를 대상으로 지정할 수 있도록 기존 옵션을 확장합니다.

이를 통해 그룹 전체에서 정책을 활성화할 수 있는 더 큰 유연성을 갖춘 동시에 필요한 경우 프로젝트를 적용 범위 밖으로 범위 지정할 예외를 적용할 수 있습니다.

이 개선 사항은 보안 정책 프로젝트 연결 프로세스를 단순화하고 정책 적용을 세분화된 범위로 지정할 [개선 사항](https://gitlab.com/groups/gitlab-org/-/epics/5446)의 수를 앞선다.

### 엔터프라이즈 사용자의 비밀번호 인증 비활성화 {#disable-password-authentication-for-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/373718)

{{< /details >}}

엔터프라이즈 사용자는 사용자 이름과 비밀번호를 사용하여 로컬 계정으로 인증할 수 있습니다. 이제 그룹 소유자는 그룹의 엔터프라이즈 사용자에 대한 비밀번호 인증을 비활성화할 수 있습니다. 비밀번호 인증이 비활성화되면 엔터프라이즈 사용자는 GitLab 웹 UI에 인증하기 위해 그룹의 SAML ID 공급자를 사용하거나 HTTP 기본 인증을 사용하여 GitLab API 및 Git에 인증하기 위해 개인 액세스 토큰을 사용할 수 있습니다.

### 프로젝트의 준수 센터 액세스 {#access-compliance-center-on-projects}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/compliance_center/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/441350)

{{< /details >}}

이전에는 준수 센터가 최상위 그룹 및 하위 그룹에만 사용할 수 있었습니다.

이 릴리스에서 프로젝트에 준수 센터를 추가했습니다. 이 수준에서 준수 센터는 특정 프로젝트와 관련된 검사 및 위반에 대해 보기 전용 기능을 제공합니다.

프레임워크를 추가하거나 편집하려면 대신 최상위 그룹의 준수 센터에 액세스해야 합니다.

### 준수 파이프라인에서 보안 정책으로의 마이그레이션 프로세스 {#migration-process-for-compliance-pipelines-to-security-policies}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/compliance_pipelines.md#pipeline-execution-policies-migration) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11275)

{{< /details >}}

GitLab 17.3에서는 준수 파이프라인의 사용 중단과 18.0 릴리스까지의 최종 제거를 발표했습니다. 준수 파이프라인 대신 GitLab 17.2에서 릴리스된 파이프라인 실행 정책 유형을 사용해야 합니다.

기존 준수 파이프라인을 파이프라인 실행 정책 유형으로 마이그레이션하는 데 도움이 되도록 이 릴리스에는 다음을 수행하는 경고 배너가 포함됩니다:

- 준수 파이프라인의 사용 중단에 대해 사용자에게 알립니다.
- 기존 준수 파이프라인을 파이프라인 실행 정책 유형으로 마이그레이션하기 위한 프롬프트 및 가이드 워크플로우를 제공합니다.

### API를 사용하여 토큰 연결 보기 {#view-token-associations-using-api}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/personal_access_tokens.md#list-all-token-associations) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/466046)

{{< /details >}}

이제 토큰이 연결된 그룹, 하위 그룹 및 프로젝트를 볼 수 있습니다. 이를 통해 토큰 만료 또는 해지의 영향을 결정하고 토큰을 사용할 수 있는 위치를 이해하기가 더 쉬워집니다.

### 선택적 SAML Single Sign-On 적용 {#selective-saml-single-sign-on-enforcement}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/sign_in_restrictions.md#disable-password-and-passkey-authentication-for-users-with-an-sso-identity) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/382917)

{{< /details >}}

이전에는 SAML SSO가 활성화되면 그룹은 SSO를 적용하도록 선택할 수 있었으며, 이는 모든 구성원이 그룹에 액세스하기 위해 SSO 인증을 사용해야 한다는 것을 의미했습니다. 그러나 일부 그룹은 직원이나 그룹 구성원의 SSO 적용 보안을 원하면서도 외부 협업자나 계약자가 SSO 없이 그룹에 액세스할 수 있도록 허용하고 싶어합니다.

이제 SAML SSO가 활성화된 그룹은 SAML ID를 가진 모든 구성원에 대해 SSO가 자동으로 적용됩니다. SAML ID가 없는 그룹 구성원은 SSO 적용이 명시적으로 활성화되지 않는 한 SSO를 사용해야 합니다.

다음 중 하나 또는 둘 다가 참인 경우 구성원에게 SAML ID가 있습니다:

- GitLab 그룹의 Single Sign-On URL을 사용하여 GitLab에 로그인했습니다.
- SCIM에 의해 프로비저닝되었습니다.

선택적 SSO 적용 기능이 원활하게 작동하도록 하려면 **이 그룹에 SAML 인증 활성화** 확인란을 선택하기 전에 SAML 구성이 제대로 작동하는지 확인하세요.

### 컨테이너 레지스트리 태그를 사용할 때 API 성능 향상 {#enhance-api-performance-when-working-with-container-registry-tags}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../api/container_registry.md#list-all-registry-repository-tags) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/482399)

{{< /details >}}

자체 관리 GitLab 인스턴스를 위한 컨테이너 레지스트리 API의 중요한 개선을 발표하게 되어 기쁩니다. GitLab 17.5 릴리스에서 `:id/registry/repositories/:repository_id/tags` 엔드포인트에 대해 키 세트 페이지 매김을 구현했으며, 이는 GitLab.com에서 이미 사용 가능한 기능과 일치합니다. 이 개선은 API 성능을 개선하고 모든 GitLab 배포에서 일관된 경험을 제공하기 위한 지속적인 노력의 일부입니다.

키 세트 페이지 매김은 대규모 데이터 세트를 처리하기 위한 더 효율적인 방법을 제공하여 성능 개선 및 더 나은 사용자 경험을 제공합니다. 이 업데이트는 특히 대규모 컨테이너 레지스트리를 관리할 때 유용하며 리포지토리 태그를 통해 더 부드러운 탐색을 허용합니다. 이 기능을 사용하려면 자체 관리 인스턴스를 [차세대 컨테이너 레지스트리](../../administration/packages/container_registry_metadata_database.md)로 업그레이드해야 합니다.

### 보호된 패키지로 종속성 보호 {#safeguard-your-dependencies-with-protected-packages}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/packages/package_registry/package_protection_rules.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)

{{< /details >}}

GitLab 패키지 레지스트리의 보안 및 안정성을 강화하도록 설계된 새로운 기능인 보호된 npm 패키지에 대한 지원을 소개하게 되어 기쁩니다. 빠르게 진행되는 소프트웨어 개발 세계에서 패키지의 실수로 인한 수정 또는 삭제는 전체 개발 프로세스를 방해할 수 있습니다. 보호된 패키지는 의도하지 않은 변경으로부터 가장 중요한 종속성을 보호할 수 있게 함으로써 이 이슈를 해결합니다.

GitLab 17.5부터 보호 규칙을 생성하여 npm 패키지를 보호할 수 있습니다. 패키지가 보호 규칙과 일치하면 지정된 사용자만 패키지를 업데이트하거나 삭제할 수 있습니다. 이 기능을 통해 실수로 인한 변경을 방지하고, 규제 요구 사항에 대한 규정 준수를 개선하며, 수동 감독의 필요성을 줄임으로써 워크플로우를 간소화할 수 있습니다.

### 고급 SAST에 대한 Ruby 지원 및 규칙 업데이트 {#ruby-support-and-rule-updates-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

GitLab Advanced SAST에 Ruby 지원을 추가했습니다. 이 새로운 크로스 파일, 크로스 함수 스캔 지원을 사용하려면 [Advanced SAST 활성화](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)를 수행하세요. Advanced SAST를 이미 활성화한 경우 Ruby 지원이 자동으로 활성화됩니다.

지난 달에는 다음을 통해 [Advanced SAST가 지원하는 다른 언어](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages)에 대한 탐지 규칙을 개선하기 위한 업데이트도 릴리스했습니다:

- 추가 Java 경로 순회, Java 명령 주입 및 JavaScript 경로 순회 취약성 탐지.
- CWE 매핑을 업데이트하여 취약성 유형을 더 구체적으로 일관되게 식별합니다.
- 경로 순회 취약성의 심각도 증가.

Advanced SAST가 각 언어에서 탐지하는 취약성 유형을 보려면 새로운 [Advanced SAST 적용 범위 페이지](../../user/application_security/sast/advanced_sast_coverage.md)를 참조하세요.

Advanced SAST에 대해 자세히 알아보려면 [지난달의 공지 블로그](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/)를 참조하세요.

### GitLab 러너 17.5 {#gitlab-runner-175}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab Runner 17.5도 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [범위가 지정된 임시 자격 증명으로 AWS S3 다중 파트 업로드 지원](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26921)

#### 버그 수정 {#bug-fixes}

- [서비스 컨테이너 중 하나가 실행 중이 아닌 경우 추가 서비스가 있는 작업이 완료되지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38035)
- [`gitlab-runner-fips-17.4.0-1` 패키지가 Amazon Linux 2에서 실행되지 않으며 glibc 오류를 반환함](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38034)
- [S3 Express One Zone 엔드포인트를 사용할 때 캐시가 Amazon S3에서 작동하지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37394)
- [`DOCKER_AUTH_CONFIG` 변수에 여러 레지스트리가 있는 경우 작업이 기본 이미지를 가져올 수 없음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28073)

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.5)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
