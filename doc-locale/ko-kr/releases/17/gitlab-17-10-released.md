---
stage: Release Notes
group: Monthly Release
date: 2025-03-20
title: "GitLab 17.10 릴리스 정보"
description: "베타로 제공되는 Duo Code Review가 포함된 GitLab 17.10 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 3월 20일, GitLab 17.10이 다음 기능과 함께 릴리스되었습니다.

또한 이번 달의 주목할 만한 기여자를 포함하여 모든 기여자에게 감사드립니다.

## 이번 달 주목할 만한 기여자: Alexey Butkeev {#this-months-notable-contributor-alexey-butkeev}

모든 사용자가 [GitLab의 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동 중인 후보자에 대한 지지를 보여주거나 새로운 추천을 추가하세요! 🙌

[Alexey Butkeev](https://gitlab.com/abutkeev)는 글로벌 도달 범위와 사용자 경험을 향상시키는 기여로 귀중한 커뮤니티 기여자입니다. 그의 영향력 있는 지역화 및 번역 기여는 저희의 다양성, 포용성, 소속감 가치를 대표합니다.

"17.10 MVP로 선정된 것을 영광스럽게 생각하며 GitLab을 더욱 접근 가능하고 포용적으로 만드는 데 기여할 수 있어 기쁩니다."라고 Alexey가 말했습니다. "지역화는 팀 활동이며, 이러한 지지하는 커뮤니티의 일부가 될 수 있어 감사합니다."

코드 기여 외에도 Alexey는 GitLab과 Crowdin을 통해 번역 오류를 찾고, 문서화하고, 수정하는 주도권을 가졌습니다. 그의 철저한 연구와 문제 해결 능력으로 그는 저희의 17.10 MVP가 되었습니다.

Alexey는 GitLab의 글로벌화 기술 시니어 매니저인 [Oleksandr Pysaryuk](https://gitlab.com/opysaryuk)에 의해 추천되었으며, GitLab의 글로벌화 및 지역화 담당 이사인 [Daniel Sullivan](https://gitlab.com/djsulliv)에 의해 지지받았습니다. "GitLab에서 당신의 일과 지지를 매우 감사합니다."라고 Daniel이 말했습니다. "글로벌적으로 지지받는 회사가 되도록 도움을 주신 점에 감사합니다!"

GitLab을 더욱 포용적이고 투명하게 만들어주신 Alexey에게 감사합니다!

## 주요 기능 {#primary-features}

### 베타로 사용 가능한 Duo Code Review {#duo-code-review-available-in-beta}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)

{{< /details >}}

코드 검토는 소프트웨어 개발의 필수 활동입니다. 이는 프로젝트에 대한 기여가 코드 품질과 보안을 유지하고 개선하도록 하며, 엔지니어를 위한 멘토십 및 피드백의 통로입니다. 또한 소프트웨어 개발 프로세스에서 가장 시간이 많이 소요되는 활동 중 하나입니다.

Duo Code Review는 코드 검토 프로세스의 다음 진화입니다.

Duo Code Review는 개발 프로세스를 가속화할 수 있습니다. 머지 리퀘스트에 대해 초기 검토를 수행할 때, 잠재적 버그를 식별하고 추가 개선 사항을 제안할 수 있습니다. 일부는 브라우저에서 직접 적용할 수 있습니다. 다른 사람을 추가하기 전에 이를 사용하여 변경 사항을 반복하고 개선합니다.

**Try it out:**

- 코드 검토를 즉시 시작하려면 `@GitLabDuo`을 머지 리퀘스트의 검토자로 추가합니다.
- 변경 사항에 대한 피드백을 개선하려면 댓글에서 `@GitLabDuo`을 언급합니다.

Duo Code Review의 향후 진행 상황을 에픽 [13008](https://gitlab.com/groups/gitlab-org/-/epics/13008) 및 관련 자식 에픽에서 추적할 수 있습니다. 피드백은 [517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386) 이슈에서 제공할 수 있습니다.

### GitLab Duo Self-Hosted에서 사용 가능한 Root Cause Analysis {#root-cause-analysis-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13759)

{{< /details >}}

이제 GitLab Duo Self-Hosted에서 [GitLab Duo Root Cause Analysis](https://about.gitlab.com/blog/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/)를 사용할 수 있습니다. 이 기능은 GitLab Duo Self-Hosted를 사용하는 GitLab Self-Managed 인스턴스에서 베타 단계이며, Mistral, Anthropic, OpenAI GPT 모델 제품군을 지원합니다.

GitLab Duo Self-Hosted의 Root Cause Analysis를 사용하면 데이터 주권을 손상시키지 않으면서 CI/CD 파이프라인에서 실패한 작업을 더 빠르게 문제 해결할 수 있습니다. Root Cause Analysis는 실패한 작업 로그를 분석하고, 작업 실패의 근본 원인을 빠르게 결정하고, 수정 방법을 제안합니다.

참고: 이 기능은 현재 제한된 기능을 가지고 있으며, 전체 기능은 17.11에서 계획되어 있습니다. [이슈 해결 설명서](../../administration/gitlab_duo_self_hosted/troubleshooting.md#feature-not-accessible-or-feature-button-not-visible) 및 [527128](https://gitlab.com/gitlab-org/gitlab/-/issues/527128) 이슈에서 추가 정보를 확인할 수 있습니다.

GitLab Duo Self-Hosted의 Root Cause Analysis에 대한 피드백을 [이슈 523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523912)에서 제공해주세요.

### GitLab Dedicated 장애 조치 인스턴스에서 사용 가능한 확대된 AWS 리전 {#expanded-aws-regions-available-for-gitlab-dedicated-failover-instances}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Gold
- 링크: [설명서](../../administration/dedicated/create_instance/data_residency_high_availability.md)

{{< /details >}}

GitLab Dedicated 고객은 이제 [재해 복구](../../administration/dedicated/disaster_recovery.md)를 위해 장애 조치 인스턴스를 호스팅할 위치를 선택할 때 확대된 AWS 리전 목록에서 선택할 수 있습니다.

추가 리전으로의 장애 조치 지원 확대는 GitLab Dedicated 고객이 데이터 거주권 요구를 충족시키기 위해 사용해야 하는 AWS 리전에 관계없이 GitLab Dedicated의 재해 복구 기능을 완전히 사용할 수 있도록 합니다.

이 새로 사용 가능한 리전은 GitLab Dedicated가 의존하는 특정 AWS 기능을 완전히 지원하지 않기 때문에 장애 조치 인스턴스 호스팅에만 사용할 수 있습니다.

### GitLab Query Language views 베타 {#gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/glql/_index.md#embedded-views) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14938)

{{< /details >}}

GitLab 전체에서 진행 중인 작업을 추적하고 이해하려면 이전에 여러 위치를 탐색해야 했으며, 이는 팀 효율성을 감소시키고 소중한 시간을 소비했습니다.

이 릴리스는 GitLab Query Language (GLQL) views 베타를 도입하여 기존 워크플로우에서 동적이고 실시간의 작업 추적을 직접 만들 수 있습니다.

GLQL views는 Wiki 페이지, 에픽 설명, 이슈 댓글, 머지 리퀘스트 전체에서 Markdown 코드 블록에 라이브 데이터 쿼리를 포함합니다.

이전에 실험으로 사용 가능했던 GLQL views는 이제 할당자, 작성자, 레이블, 마일스톤을 포함한 주요 필드 전반에서 논리 표현식 및 연산자를 사용한 정교한 필터링을 지원하여 베타에 진입합니다. 테이블 또는 목록으로 뷰의 프레젠테이션을 사용자 지정하고, 표시되는 필드를 제어하고, 결과 제한을 설정하여 팀을 위한 집중되고 실행 가능한 인사이트를 만들 수 있습니다.

이제 팀은 필요한 정보에 액세스하면서 컨텍스트를 유지하고, 공유된 이해를 만들고, 협업을 개선할 수 있습니다. 모두 현재 워크플로우를 떠나지 않고도 가능합니다.

[피드백을 환영합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/509791). 계속해서 이 기능을 향상시키고 있습니다.

### 향상된 Markdown 환경 {#enhanced-markdown-experience}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/markdown.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

GitLab Flavored Markdown은 여러 강력한 개선 사항으로 향상되었습니다:

- **Improved math and image handling**:
  - 더 복잡한 수식을 처리하기 위해 그룹 또는 자체 호스팅 인스턴스에서 [수학 렌더링](../../user/markdown.md#math-equations) 제한을 비활성화합니다.
  - 픽셀 값 또는 백분율을 사용하여 [이미지 크기](../../user/markdown.md#change-image-or-video-dimensions)를 정확하게 제어하여 콘텐츠 레이아웃을 더 잘 관리합니다.
- **Enhanced editor experience**:
  - Enter/Return을 누를 때 목록을 자동으로 계속합니다.
  - 키보드 단축키를 사용하여 텍스트를 왼쪽 또는 오른쪽으로 이동합니다.
  - 설명 목록 구문을 사용하여 명확한 용어-정의 쌍을 만듭니다.
  - 비디오 너비를 유연하게 조정합니다.
- **Better content organization**:
  - 자동 확장 [요약 빠른 보기](../../user/markdown.md#show-item-summary)를 사용하여 콘텐츠를 더 쉽게 탐색합니다 (URL에 `+s`를 추가).
  - 참조된 [이슈 제목](../../user/markdown.md#show-item-title)을 자동으로 렌더링합니다 (URL에 `+`를 추가).
  - [`include` 구문](../../user/markdown.md#includes)을 사용하여 모듈식으로 콘텐츠를 조직합니다.
  - [alert boxes](../../user/markdown.md#alerts)를 사용하여 시각적으로 뚜렷한 콜아웃 및 경고를 만듭니다.

이러한 개선 사항은 GitLab Flavored Markdown을 설명서를 만들고 유지하는 팀을 위해 더욱 강력하게 만들면서 콘텐츠가 어떻게 제공되고 조직되는지에 대한 더 큰 유연성을 제공합니다.

### 프로젝트 전체 DORA 메트릭을 사용한 DevOps 성능의 새로운 시각화 {#new-visualization-of-devops-performance-with-dora-metrics-across-projects}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/analytics/value_streams_dashboard.md#projects-by-dora-metric) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/408516)

{{< /details >}}

저희는 **Projects by DORA metric** 패널을 도입하게 되어 기쁩니다. 이는 [Value Streams Dashboard](https://www.youtube.com/watch?v=EA9Sbks27g4)에 새로 추가되었습니다. 이 표는 최상위 그룹의 모든 프로젝트를 나열하며, [네 가지 DORA 메트릭](https://about.gitlab.com/solutions/value-stream-management/dora/#overview)으로 분류됩니다. 관리자는 이 표를 사용하여 성능이 높고, 중간이며, 낮은 프로젝트를 식별할 수 있습니다. 이 정보는 데이터 기반 의사 결정을 내리고, 리소스를 효과적으로 할당하고, 소프트웨어 배포 속도, 안정성 및 신뢰성을 향상시키는 이니셔티브에 초점을 맞추는 데도 도움이 될 수 있습니다.

[DORA 메트릭](../../user/analytics/dora_metrics.md)은 GitLab에서 기본적으로 사용할 수 있으며, 이제 [**DORA Performers score** 패널](https://about.gitlab.com/blog/inside-dora-performers-score-in-gitlab-value-streams-dashboard/)과 함께 임원진은 조직의 DevOps 상태를 위에서 아래까지 완벽하게 볼 수 있습니다.

### 이제 베타 단계인 새로운 이슈 모양 {#new-issues-look-now-in-beta}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/issues/_index.md)

{{< /details >}}

이제 이슈는 에픽 및 작업과 공통 프레임워크를 공유하며, 실시간 업데이트 및 워크플로우 개선을 제공합니다:

- **Drawer view:** 현재 컨텍스트를 떠나지 않고 빠르게 보기 위해 목록 또는 보드에서 항목을 드로어로 엽니다. 상단의 버튼을 사용하면 전체 페이지 보기로 확장할 수 있습니다.
- **Change type:** "Change type" 작업을 사용하여 에픽, 이슈, 작업 간 유형을 변환합니다 ("Promote to epic" 대체)
- **시작일:** 이제 이슈는 시작 날짜를 지원하며, 에픽 및 작업과의 기능을 정렬합니다.
- **Ancestry:** 완전한 계층 구조는 제목 위와 사이드바의 Parent 필드에 있습니다. 관계를 관리하려면 새로운 [quick action](../../user/project/quick_actions.md) 명령 `/set_parent`, `/remove_parent`, `/add_child`, `/remove_child`을 사용합니다.
- **Controls:** 모든 작업을 이제 상단 메뉴(세로 줄임표)에서 액세스할 수 있으며, 스크롤할 때 고정 헤더에 표시됩니다.
- **Development:** 이제 이슈 또는 작업과 관련된 모든 개발 항목(머지 리퀘스트, 브랜치, 기능 플래그)이 하나의 편리한 목록으로 통합됩니다.
- **Layout:** UI 개선은 이슈, 에픽, 작업, 머지 리퀘스트 간의 더욱 원활한 경험을 만들어 워크플로우를 더 효율적으로 탐색할 수 있도록 도와줍니다.
- **Linked items:** 개선된 링크 옵션으로 작업, 이슈, 에픽 간의 관계를 만듭니다. 드래그 앤 드롭으로 링크 유형을 변경하고 레이블 및 종료된 항목의 가시성을 전환합니다.

### 에픽, 이슈, 작업, OKR에 대한 설명 템플릿 {#description-templates-for-epics-issues-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/description_templates.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16088)

{{< /details >}}

이제 작업 항목(에픽, 작업, OKR)에 대한 설명 템플릿으로 워크플로우를 간소화하고 프로젝트 전체에서 일관성을 유지할 수 있습니다.

이 강력한 추가 사항을 사용하면 표준화된 템플릿을 만들어 시간을 절약하고 새 작업 항목을 만들 때마다 모든 중요한 정보가 포함되도록 할 수 있습니다.

### 취약성의 심각도 변경 {#change-the-severity-of-a-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#change-or-override-vulnerability-severity) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/16157)

{{< /details >}}

취약성을 분류할 때 조직의 고유한 보안 컨텍스트 및 위험 허용 범위에 따라 심각도 수준을 조정할 수 있는 유연성이 필요합니다. 지금까지는 보안 스캐너에 의해 할당된 기본 심각도 수준에 의존해야 했으며, 이는 특정 환경의 위험 수준을 정확하게 반영하지 못할 수 있습니다.

이제 특정 취약성 발생의 심각도를 수동으로 변경하여 조직의 보안 요구를 더 잘 맞출 수 있습니다. 이를 통해 다음을 수행할 수 있습니다:

- 모든 취약성의 심각도 수준을 **치명적**, **높음**, **중간**, **낮음**, **정보**, 또는 **알 수 없음**으로 조정합니다.
- 취약성 보고서에서 한 번에 여러 취약성의 심각도를 변경합니다.
- 시각적 표시기를 통해 사용자 지정 심각도 수준을 가진 취약성을 쉽게 식별합니다.

모든 심각도 변경은 취약성 이력 및 감사 이벤트에 추적되며, 프로젝트에 대해 최소한 Maintainer 역할이 있거나 `admin_vulnerability` 권한을 가진 사용자 지정 역할을 가진 팀 멤버만 이를 재정의할 수 있습니다. 이 기능은 보안 팀에 취약성 우선순위 지정에 대한 더 많은 유연성과 제어를 제공합니다.

## 에이전틱 코어 {#agentic-core}

### 이제 크기 조정 가능한 GitLab Duo Chat {#gitlab-duo-chat-is-now-resizable}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-gitlab-ui) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/499849)

{{< /details >}}

이제 GitLab UI에서 Duo Chat 드로어의 크기를 조정할 수 있습니다. 이를 통해 코드 출력을 더 쉽게 보거나, 백그라운드에서 GitLab으로 작업하면서 Chat을 열어 둘 수 있습니다.

### GitLab Duo Chat에서 여러 대화 관리 {#manage-multiple-conversations-in-gitlab-duo-chat}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

이제 여러 대화로 GitLab Duo Chat에서 다양한 주제 전반에 걸쳐 컨텍스트를 유지하기가 더 쉬워졌습니다. 새로운 대화를 만들고, 대화 이력을 검색하고, 대화 간을 전환할 수 있습니다.

이전에는 새로운 대화를 시작하는 것이 기존 채팅의 컨텍스트를 잃는 것을 의미했습니다. 이제 다른 주제에 대한 여러 대화를 관리할 수 있습니다. 각 대화는 자체 컨텍스트를 유지하므로, 예를 들어 한 대화에서 코드 설명에 대한 후속 질문을 물어볼 수 있고, 다른 대화에서 작업 계획을 준비할 수 있습니다.

이전 논의를 다시 방문해야 할 때, 새로운 채팅 이력 아이콘을 선택하여 최근의 모든 대화를 봅니다. 대화는 가장 최근의 활동 순서로 자동으로 조직되어 중단한 위치를 쉽게 선택할 수 있습니다.

개인정보 보호를 위해 30일 동안 활동이 없는 대화는 자동으로 삭제되며, 언제든지 모든 대화를 수동으로 삭제할 수 있습니다.

이 기능은 현재 GitLab.com의 웹 UI에서만 사용할 수 있습니다. GitLab Self-Managed 인스턴스 또는 IDE 통합에서는 사용할 수 없습니다.

[이슈 526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013)에서 경험을 공유해주세요.

### GitLab Duo Self-Hosted에서 AI 기반 기능에 대한 모델 선택 {#select-models-for-ai-powered-features-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/524174)

{{< /details >}}

이제 GitLab Duo Self-Hosted에서 자체 관리 인스턴스의 각 GitLab Duo Chat 하위 기능에 대해 개별 지원되는 모델을 선택할 수 있습니다. Chat 하위 기능에 대한 모델 선택 및 구성은 이제 베타 단계입니다.

피드백을 남기려면 [이슈 524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175)로 이동하세요.

### GitLab Duo Self-Hosted Code Suggestions에서 사용 가능한 AI Impact Dashboard {#ai-impact-dashboard-available-on-gitlab-duo-self-hosted-code-suggestions}

<!-- categories: Self-Hosted Models, Value Stream Management, DORA Metrics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/analytics/duo_and_sdlc_trends.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523807)

{{< /details >}}

이제 자체 관리 인스턴스에서 GitLab Duo Self-Hosted Code Suggestions를 사용하여 AI Impact Dashboard를 사용하여 GitLab Duo가 생산성에 미치는 영향을 이해할 수 있습니다. AI Impact Dashboard는 GitLab Duo Self-Hosted와 함께 베타 단계이며, 자체 관리 인스턴스 및 Visual Studio Code, Microsoft Visual Studio, JetBrains, Neovim IDE와 함께 이 기능을 사용할 수 있습니다.

AI Impact Dashboard를 사용하여 리드 타임, 사이클 타임, DORA, 취약성과 같은 메트릭과 AI 사용 추세를 비교합니다. 이를 통해 GitLab Duo Self-Hosted를 사용한 엔드 투 엔드 워크스트림에서 절약된 시간을 측정할 수 있으며, 개발자 활동이 아닌 비즈니스 결과에 집중할 수 있습니다.

AI Impact Dashboard에 대한 피드백을 [이슈 456105](https://gitlab.com/gitlab-org/gitlab/-/issues/456105)에서 남겨주세요.

### GitLab Duo Self-Hosted Code Suggestions 및 Chat에 사용 가능한 Meta Llama 3 모델 {#meta-llama-3-models-available-for-gitlab-duo-self-hosted-code-suggestions-and-chat}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523917)

{{< /details >}}

이제 GitLab Duo Self-Hosted에서 선택 Meta Llama 3 모델을 사용할 수 있습니다. 이 모델들은 GitLab Duo Chat 및 Code Suggestions을 지원하기 위해 GitLab Duo Self-Hosted에 대한 베타 단계입니다.

GitLab Duo Self-Hosted를 사용하는 이 모델들에 대한 피드백을 [이슈 523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523917)에서 남겨주세요.

## 규모 및 배포 {#scale-and-deployments}

### 플레이스홀더 사용자가 생성된 시간의 타임스탬프 {#timestamps-of-when-placeholder-users-were-created}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/import/mapping/post_migration_mapping.md#placeholder-user-attributes) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/507297)

{{< /details >}}

이전에는 그룹 또는 프로젝트를 가져올 때 [플레이스홀더 사용자](../../user/import/mapping/post_migration_mapping.md#placeholder-users)가 생성된 시점을 볼 수 없었습니다. 이 릴리스에서는 타임스탬프를 추가하여 마이그레이션 진행 상황을 추적하고 발생하는 이슈를 해결할 수 있습니다.

### 할 일 항목 대량 편집 {#bulk-edit-to-do-items}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/todos.md#bulk-edit-to-do-items) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/16564)

{{< /details >}}

이제 향상된 대량 편집 기능으로 할 일 목록을 효율적으로 관리할 수 있습니다. 여러 할 일 항목을 선택하고 한 번에 완료 표시하거나 미루어, 작업에 대한 더 많은 제어를 제공하고 적은 노력으로 정리된 상태를 유지하도록 도와줍니다.

### 할 일 항목 미루기 {#snooze-to-do-items}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/todos.md#snooze-to-do-items) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/17712)

{{< /details >}}

이제 할 일 목록의 알림을 미룰 수 있으므로 항목을 일시적으로 숨기고 지금 가장 중요한 것에 집중할 수 있습니다. 집중하기 위해 한 시간이 필요하든 내일 작업을 다시 방문하고 싶든, 알림이 다시 나타날 시점을 세밀하게 제어할 수 있으므로 워크플로우를 더 효과적으로 관리할 수 있습니다.

### CSV 파일을 사용하여 재할당 요청 {#request-reassignment-by-using-a-csv-file}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16765)

{{< /details >}}

이 릴리스에서 사용자 기여도 매핑은 이제 CSV 파일을 사용한 대량 재할당을 지원합니다. 많은 플레이스홀더 사용자가 있는 큰 사용자 기반이 있는 경우 Owner 역할이 있는 그룹 멤버는 다음을 수행할 수 있습니다:

1. 미리 채워진 CSV 템플릿을 다운로드합니다.
1. 대상 인스턴스에서 GitLab 사용자명 또는 공개 이메일을 추가합니다.
1. 완성된 파일을 업로드하여 한 번에 모든 기여를 재할당합니다.

이 방법은 UI를 통한 번거로운 수동 재할당을 제거합니다. 대규모 마이그레이션을 더욱 간소화하기 위해 CSV 기반 재할당에 대한 API 지원이 이제도 사용할 수 있습니다.

### Your Work에서 프로젝트의 새로운 탐색 경험 {#new-navigation-experience-for-projects-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/working_with_projects.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/465889)

{{< /details >}}

프로젝트를 발견하고 액세스하는 방식을 간소화하도록 설계된 **Your Work**의 프로젝트 개요에 대한 중요한 개선을 발표하게 되어 기쁩니다. 이 업데이트는 사용자가 프로젝트와 상호 작용하는 방식을 더 잘 반영하는 더 직관적인 탭 기반 탐색 시스템을 도입합니다.

- 새로운 **기여함** 탭(이전 **Yours**)은 이제 개인 프로젝트를 포함하여 기여한 모든 프로젝트를 표시하여 개발 활동을 더 쉽게 추적할 수 있습니다.
- **개인** 탭으로 개별 프로젝트를 더 빠르게 찾을 수 있으며, 이제 주 탐색에서 눈에 띄게 표시됩니다.
- **멤버** 탭(이전 **전체**)을 통해 팀 프로젝트에 액세스하여 멤버십이 있는 모든 프로젝트를 표시합니다.
- **비활성** 탭(이전 **삭제 대기 중**)은 이제 보관된 프로젝트와 삭제 대기 중인 프로젝트를 모두 포괄적으로 볼 수 있습니다.

또한 적절한 권한이 있으면 **Your Work** 프로젝트 개요에서 직접 프로젝트를 편집하거나 삭제할 수 있습니다. 이러한 변경 사항은 더 효율적이고 사용자 친화적인 GitLab 환경을 만들려는 저희의 약속을 반영합니다. 새로운 레이아웃은 작업에 가장 중요한 프로젝트에 집중하도록 도와주므로 다양한 프로젝트 카테고리 간의 탐색에 소요되는 시간을 줄입니다.

이 업데이트에 대한 피드백을 소중히 여깁니다! [에픽 16662](https://gitlab.com/groups/gitlab-org/-/epics/16662)의 논의에 참여하여 새로운 탐색 시스템에 대한 경험을 공유하세요.

### 개선된 프로젝트 생성 권한 설정 {#improved-project-creation-permission-settings}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/507410)

{{< /details >}}

프로젝트 생성 권한 설정을 더 명확하고 직관적이며 보안 원칙에 맞게 개선했습니다. 개선된 설정에는 다음이 포함됩니다:

- "Default project creation protection" 드롭다운을 "Minimum role required for project creation"으로 이름을 바꿔 설정의 목적을 명확하게 반영합니다.
- "Developers + Maintainers" 드롭다운 옵션을 "Developers"로 이름을 바꿔 플랫폼 전체에서 일관성을 유지합니다.
- 드롭다운 옵션을 가장 제한적에서 가장 덜 제한적인 액세스 수준으로 재정렬합니다.

이러한 변경 사항은 그룹 내에서 어떤 역할이 프로젝트를 만들 수 있는지 이해하고 구성하기가 더 쉬워지므로 관리자가 적절한 액세스 제어를 더 자신감있게 적용할 수 있도록 도와줍니다.

이 커뮤니티 기여를 위해 [@yasuk](https://gitlab.com/yasuk)에 감사드립니다!

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### pub (Dart) package manager에 대한 Dependency Scanning 지원 {#dependency-scanning-support-for-pub-dart-package-manager}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/342468)

{{< /details >}}

Dependency Scanning은 Dart의 공식 package manager인 pub에 대한 지원을 추가했습니다. Dependency Scanning [최신 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml) 및 [CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/dependency-scanning)에 이 지원이 추가되었습니다.

이 추가는 저희 사용자 중 한 명인 Alexandre Laroche의 커뮤니티 기여입니다. GitLab Composition Analysis 팀은 제품을 개선하기 위한 이 기여를 감사하며, Alexandre에게 감사드립니다. GitLab에 기여하는 것에 대해 더 알고 싶으시면 저희의 [Community Contribution program](https://about.gitlab.com/community/contribute/)을 확인해주세요.

### Frameworks 페이지의 드롭다운 목록에서 compliance framework을 기본값으로 선택 {#select-a-compliance-framework-as-default-from-the-dropdown-list-on-the-frameworks-page}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_frameworks_report.md#set-and-remove-a-compliance-framework-as-default) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181500)

{{< /details >}}

사용자는 GitLab compliance centre에서 기본 compliance framework을 설정할 수 있으며, 이는 해당 그룹에서 생성된 모든 새로운 및 가져온 프로젝트에 적용됩니다. 기본 compliance framework에는 **기본값** 레이블이 있어 사용자가 이를 식별할 수 있도록 도와줍니다.

compliance framework을 기본값으로 설정하기가 더 쉽도록 하기 위해, 최상위 그룹의 compliance center에서 list frameworks 페이지의 framework 드롭다운 목록을 사용하여 framework을 기본값으로 설정할 수 있는 기능을 도입합니다. 이 기능은 하위 그룹 또는 프로젝트의 compliance center에서는 사용할 수 없습니다.

### Git blame에서 특정 리뷰 무시 {#ignore-specific-revisions-in-git-blame}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/files/git_blame.md#ignore-specific-revisions)

{{< /details >}}

리포지토리 이력을 검색할 때 프로젝트의 다른 의미 있는 변경과 무관한 커밋이 있을 수 있습니다. 이는 다음 중에 발생할 수 있습니다:

- 기능을 변경하지 않고 한 라이브러리에서 다른 라이브러리로 변경하는 리팩터링.
- 전체 코드베이스를 표준화해야 하는 코드 포매터 또는 린터의 구현.

`blame`을 사용하여 프로젝트의 이력을 살펴볼 때, 이러한 종류의 커밋은 발생한 변경 사항을 이해하기 어렵게 만듭니다. Git은 프로젝트에서 `.git-blame-ignore-revs` 파일을 사용하여 이러한 커밋을 식별하도록 지원합니다. GitLab은 이제 "Blame preferences" 드롭다운 목록에서 blame 보기를 전환하여 이러한 특정 리뷰을 표시하거나 숨길 수 있으므로 프로젝트의 이력을 더 쉽게 이해할 수 있습니다.

### CODEOWNERS에 대한 경로 제외 {#path-exclusions-for-codeowners}

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/codeowners/reference.md#exclusion-patterns)

{{< /details >}}

팀이 `CODEOWNERS` 파일을 구성할 때 경로 및 파일 유형에 대해 광범위한 일치 패턴을 포함하는 것이 일반적입니다. 이러한 광범위한 구성은 설명서, 자동화된 빌드 파일 또는 기타 패턴이 지정된 Code Owner를 요구하지 않는 경우 문제가 될 수 있습니다.

이제 `CODEOWNERS` 파일을 경로 제외로 구성하여 특정 경로를 무시할 수 있습니다. 이는 Code Owner 승인을 요구하는 특정 파일 또는 경로를 제외하고자 할 때 유용합니다.

### 브랜치 규칙에서 구성 가능한 squash 설정 {#configurable-squash-settings-in-branch-rules}

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/branches/branch_rules.md#edit-squash-commits-option)

{{< /details >}}

다양한 Git 워크플로우는 브랜치 간의 병합 시 커밋을 처리하기 위한 다양한 전략이 필요합니다. 이전 GitLab 버전에서는 커밋이 병합될 때 squash되어야 하는지 여부와 얼마나 강력하게 적용되어야 하는지에 대한 단일 전략만 설정할 수 있었습니다. 이 설정은 오류가 발생하기 쉽거나 개발자가 다양한 브랜치 대상에 대한 프로젝트 규칙을 따르기 위해 특정 선택을 해야 할 수 있습니다.

이제 브랜치 규칙을 통해 각 보호된 브랜치에 대한 squash 설정을 구성할 수 있습니다. 예를 들어 다음을 수행할 수 있습니다:

- `feature` 브랜치에서 `develop` 브랜치로 병합할 때 squashing을 요구하여 이력을 깔끔하게 유지합니다.
- `develop` 브랜치에서 `main` 브랜치로 병합할 때 squashing을 비활성화하여 커밋 이력을 그대로 유지하고자 할 때입니다.

이러한 유연성은 프로젝트 전체에서 일관된 커밋 이력을 보장하면서 워크플로우의 각 브랜치의 고유한 요구를 존중하므로, 수동 개발자 개입이 필요하지 않습니다.

### 토큰 만료 알림의 더 광범위한 배포 {#wider-distribution-for-token-expiration-notifications}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/group/manage.md#expiry-emails-for-group-and-project-access-tokens) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)

{{< /details >}}

이전에는 액세스 토큰 만료 알림 이메일이 토큰이 만료되는 그룹 및 프로젝트의 직접 멤버에게만 전송되었습니다. 이제 이러한 알림은 설정이 활성화된 경우 상속된 그룹 및 프로젝트 멤버에게도 전송됩니다. 이러한 더 광범위한 배포는 만료 전에 토큰을 관리하기가 더 쉬워집니다.

### compliance를 위한 파이프라인 실행 정책의 `needs` 문 처리 {#handling-of-needs-statements-in-pipeline-execution-policies-for-compliance}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/469256)

{{< /details >}}

파이프라인 실행을 강화하려면 `.pipeline-policy-pre` 예약된 스테이지에서 적용된 작업이 `needs` 문을 정의하는지 여부에 관계없이 후속 스테이지의 작업을 시작할 수 있기 전에 완료되어야 합니다. 이전에는 `.pipeline-policy-pre` 스테이지에서 정의된 작업과 `needs` 문이 있는 후속 파이프라인의 작업이 파이프라인이 실행되자마자 시작되었습니다. 이 향상으로 후속 스테이지의 작업은 `.pipeline-policy-pre`가 완료될 때까지 대기해야 종속성이 없는 다른 작업을 시작할 수 있으므로 정렬된 실행을 적용하고 보안 정책 내에서 규정 준수를 보장할 수 있습니다.

저희 고객들은 개발자 작업이 실행되기 전에 규정 준수 및 보안 검사를 적용하기 위해 예약된 스테이지에 의존합니다. 일반적인 사용 사례는 검사가 통과하지 못할 경우 전체 파이프라인을 실패하게 하는 보안 또는 규정 준수 검사를 적용하는 것입니다. 작업을 순서 없이 실행하도록 허용하면 이러한 적용을 우회하고 정책 의도를 약하게 할 수 있습니다. 이 개선은 규정 준수 적용에 대한 더욱 일관된 접근 방식을 제공합니다.

`needs` 동작을 무시하지 않으면서 파이프라인의 시작 부분에 작업을 주입하려면 사용자 지정 스테이지가 17.9에서 도입한 새로운 사용자 지정 스테이지 기능을 사용하도록 작업을 구성합니다.

### 액세스 토큰을 사용하여 비공개 Pages에 인증 {#authenticate-to-private-pages-with-an-access-token}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/pages_access_control.md#authenticate-with-an-access-token)

{{< /details >}}

이제 액세스 토큰을 사용하여 비공개 GitLab Pages 사이트에 프로그래밍 방식으로 인증할 수 있으므로 Pages 콘텐츠와의 상호 작용을 자동화하기가 더 쉬워집니다. 이전에는 제한된 Pages 사이트에 액세스하려면 GitLab UI를 통한 대화형 인증이 필요했습니다.

이 강력한 향상은 보안을 유지하면서 생산성을 높이므로, 개발자는 비공개 Pages 콘텐츠와 상호 작용하고 배포하는 방식에 더 많은 유연성을 갖습니다.

### GitLab Duo Code Suggestions 및 GitLab Duo Chat 추세에 대한 새로운 인사이트 {#new-insights-into-gitlab-duo-code-suggestions-and-gitlab-duo-chat-trends}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/analytics/duo_and_sdlc_trends.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/477246)

{{< /details >}}

AI Impact Dashboard의 AI 비교 메트릭 패널은 이제 GitLab Duo Code Suggestions 수용률 및 GitLab Duo Chat 사용(MoM%)에 대한 월별(MoM) 추적을 제공합니다. 이러한 새로운 추세 기반 인사이트는 30일 스냅샷을 제공하는 기존 Duo Code Suggestions 및 Duo Chat 타일을 보완합니다. 이러한 추가 메트릭을 사용하여 관리자는 시간이 지남에 따라 Code Suggestions 수용률 및 Duo Chat 사용과 다른 SDLC 메트릭을 비교하여 소프트웨어 개발 프로세스에 대한 AI 영향을 더 잘 측정하고 패턴을 식별할 수 있습니다.

### 종속성 프록시에 대한 Docker Hub 인증 {#docker-hub-authentication-for-the-dependency-proxy}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/331741)

{{< /details >}}

컨테이너 이미지에 대한 GitLab Dependency Proxy는 이제 Docker Hub 인증을 지원하므로 속도 제한으로 인한 파이프라인 장애를 방지하고 비공개 이미지에 액세스할 수 있습니다.

2025년 4월 1일부터 Docker Hub는 인증되지 않은 사용자에 대해 더 엄격한 풀 제한(IPv4 주소 또는 IPv6 /64 서브넷당 6시간 창당 100)을 적용할 것입니다. 인증이 없으면 이러한 제한에 도달하면 파이프라인이 실패할 수 있습니다.

이 릴리스에서는 GraphQL API를 통해 Docker Hub 자격 증명, [personal access token](https://docs.docker.com/security/access-tokens/), 또는 [organization access tokens](https://docs.docker.com/enterprise/security/access-tokens/)을 사용하여 Docker Hub 인증을 구성할 수 있습니다. UI 구성에 대한 지원은 GitLab 17.11에서 사용할 수 있습니다.

### 패키지 레지스트리가 감사 이벤트 추가 {#package-registry-adds-audit-events}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/audit_event_types.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/329588)

{{< /details >}}

패키지 레지스트리 작업은 이제 감사 이벤트로 로깅되므로 팀은 패키지가 규정 준수 요구를 충족시키기 위해 발행되거나 삭제되는 시점을 추적할 수 있습니다.

이 릴리스 이전에는 누가 패키지를 발행했거나 변경했는지 추적할 수 있는 기본 제공 방법이 없었습니다. 팀은 이러한 활동의 로그를 유지하기 위해 자신의 추적 시스템을 만들거나 수동으로 패키지 변경을 문서화해야 했습니다. 이제 각 감사 이벤트는 누가 변경했는지, 언제 발생했는지, 어떻게 인증했는지, 그리고 패키지에서 정확히 무엇이 변경되었는지를 보여줍니다.

프로젝트에 대한 감사 이벤트는 개별 프로젝트 Owner에 대해 그룹 네임스페이스 또는 프로젝트 자체에 저장됩니다. 그룹은 저장 필요를 관리하기 위해 감사 이벤트를 끌 수 있습니다.

### Credentials Inventory에서 액세스 토큰 정렬 {#sort-access-tokens-in-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/credentials_inventory.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/513181)

{{< /details >}}

이제 Credentials Inventory에서 개인, 프로젝트, 그룹 액세스 토큰을 소유자, 생성 날짜, 마지막 사용 날짜로 정렬할 수 있습니다. 이를 통해 액세스 토큰을 더 빠르게 찾고 식별할 수 있습니다. 기여해주신 [Chaitanya Sonwane](https://gitlab.com/chaitanyason9)에게 감사드립니다!

### 토큰 정보 API를 사용하여 토큰 식별 및 취소 {#identify-and-revoke-tokens-with-token-information-api}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../api/admin/token.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15777)

{{< /details >}}

GitLab 관리자는 이제 통합 API를 사용하여 토큰을 식별하고 취소할 수 있습니다. 이전에는 관리자가 특정 토큰 유형과 관련된 엔드포인트를 사용해야 했습니다. 이 API는 유형에 관계없이 취소를 허용합니다. 지원되는 토큰 유형의 목록은 [Token information API](../../api/admin/token.md)를 참조하세요.

기여해주신 [Nicholas Wittstruck](https://gitlab.com/nwittstruck)과 Siemens 팀에게 감사드립니다!

### GitLab OIDC 공급자를 사용한 구성 가능한 토큰 기간 {#configurable-token-duration-with-gitlab-oidc-provider}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/auth/oidc.md#configure-a-custom-duration-for-id-tokens) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/377654)

{{< /details >}}

GitLab을 OpenID Connect (OIDC) 공급자로 사용할 때, `id_token_expiration` 속성을 사용하여 ID 토큰의 기간을 구성할 수 있습니다. 이전에는 ID 토큰의 만료 시간이 120초로 고정되었습니다.

기여해주신 [Henry Sachs](https://gitlab.com/DerAstronaut)에게 감사드립니다!

### OmniAuth 프로필 속성을 사용자에게 매핑 {#map-omniauth-profile-attributes-to-user}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../integration/omniauth.md#keep-omniauth-user-profiles-up-to-date) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)

{{< /details >}}

이제 OmniAuth 신원 공급자(IdP)에서 Organization 및 Title 프로필 속성을 사용자의 GitLab 프로필에 매핑할 수 있습니다. 이를 통해 IdP는 이러한 속성의 단일 소스가 되며, 사용자는 더 이상 이를 변경할 수 없습니다.

### 만료되는 토큰에 대한 확장된 웹후크 트리거 {#extended-webhook-triggers-for-expiring-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/group/manage.md#add-additional-webhook-triggers-for-group-access-token-expiration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/499732)

{{< /details >}}

이제 프로젝트 또는 그룹 액세스 토큰이 만료되기 60일 및 30일 전에 웹후크 이벤트를 트리거할 수 있습니다. 이전에는 이러한 웹후크 이벤트만 만료 7일 전에 트리거되었습니다. 이는 만료되는 토큰에 대한 기존 이메일 알림 일정과 일치하는 선택적 설정입니다.

### GitLab Runner 17.10 {#gitlab-runner-1710}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

또한 오늘 GitLab Runner 17.10을 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [인스턴스 사용 전 Autoscaler executor 상태 확인 수행](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Docker executor 볼륨 확장](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38249)
- [서비스에 대한 디바이스 추가를 위한 Docker executor 구성 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6208)

#### 버그 수정 {#bug-fixes}

- [Windows `gitlab-runner-helper` 이미지가 `/opt/step-runner' 경로에 대한 잘못된 볼륨 사양으로 인해 실패함](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38632)
- [GitLab Runner 17.7.0 이상에서 RPM 패키지 리포지토리 미러링이 제대로 작동하지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38409)
- [GitLab CI/CD에서 `git submodule update --remote`을 실행하면 오류가 반환됨](https://gitlab.com/gitlab-org/gitlab/-/issues/359825)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-10-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.10)
- [지원 중단 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
