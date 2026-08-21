---
stage: Release Notes
group: Monthly Release
date: 2026-04-16
title: "GitLab 18.11 릴리스 정보"
description: "GitLab 18.11이 GitLab Duo Agent Platform에서 일반적으로 사용 가능한 취약성 해결과 함께 출시되었습니다."
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026년 4월 16일에 GitLab 18.11이 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Rinku C {#this-months-notable-contributor-rinku-c}

우리는 [Rinku C](https://gitlab.com/therealrinku)를 인정하게 되어 기쁩니다. 2025년 9월부터 GitLab에 참여한 이후 80개 이상의 병합된 개선 사항이 있는 레벨 4 기여자입니다.

[Arianna Haradon](https://gitlab.com/aharadon)(Developer Relations 팀의 선임 풀스택 엔지니어)이 추천했으며, 이 상은 시간 경과에 따른 그의 지속적이고 의미 있는 영향을 기립니다. Rinku는 [프로젝트 및 그룹 액세스 토큰 생성 양식에서 범위 요청](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219236)으로 보안에 민감한 플로우를 강화했으며, [작업 로그의 이전/다음 탐색](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217618), [최근에서 빈 검색 제외](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223570), [파일 트리 정리 감소](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224628) 등 많은 업데이트로 일상적인 GitLab 경험을 개선했습니다. 이러한 사려 깊은 UI 개선을 통해 일반적인 워크플로우를 더 명확하고 탐색하기 쉽게 만들었습니다. Rinku는 종종 요청이 없는 작업을 처리하여 코드베이스를 건강하게 유지하고 의미 있고 지속적인 가치를 창출합니다. 기여해 주셔서 감사합니다!

## 주요 기능 {#primary-features}

### GitLab Duo Agent Platform에서 일반적으로 사용 가능한 취약성 해결 {#vulnerability-resolution-generally-available-on-gitlab-duo-agent-platform}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)

{{< /details >}}

Agentic SAST 취약성 해결은 이제 GitLab 18.11에서 GitLab Duo Agent Platform에서 일반적으로 사용 가능합니다. 이는 SAST 스캔의 일부로 실행되거나, SAST 거짓 양성 감지가 실행된 후 또는 개별 SAST 취약성에 대해 수동으로 트리거될 때 실행됩니다.

Agentic SAST 취약성 해결:

- 발견 사항을 자율적으로 분석하고 주변 코드 컨텍스트를 통해 추론합니다.
- 심각도가 높은 SAST 취약성에 대해 제안된 코드 수정 사항이 포함된 검토 준비가 된 머지 리퀘스트를 자동으로 생성합니다.
- 검토자가 제안된 수정에 대한 신뢰도를 빠르게 측정할 수 있도록 품질 평가를 제공합니다.
- 취약성 세부 사항 페이지에서 직접 해결 방안을 적용할 수 있습니다.

우리는 [이슈 585626](https://gitlab.com/gitlab-org/gitlab/-/issues/585626)에서 피드백을 환영합니다.

### 이제 일반적으로 사용 가능한 GitLab Data Analyst 기본 에이전트 {#gitlab-data-analyst-foundational-agent-now-generally-available}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20337)

{{< /details >}}

Data Analyst 에이전트는 GitLab 플랫폼 전반에서 데이터를 쿼리, 시각화 및 표시하는 데 도움이 되는 전문화된 AI 채팅 보조자입니다.

[GitLab Query Language (GLQL)](../../user/glql/_index.md)에 의해 지원되는 Data Analyst는 지원되는 각 [데이터 소스](../../user/glql/data_sources/_index.md)에 대한 데이터를 검색하고 분석할 수 있으며, 소프트웨어 개발 상태 및 엔지니어링 효율성에 대한 명확하고 실행 가능한 인사이트를 제공합니다.

이러한 인사이트는 에이전트 출력에서 직접 시각화될 수 있으며, 추가 평가를 위해 이슈 및 에픽에 직접 포함될 수 있습니다.

### CI Expert Agent가 베타에서 출시됨 {#ci-expert-agent-launches-in-beta}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/duo_agent_platform/agents/foundational_agents/ci_expert_agent.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/587460)

{{< /details >}}

AI 기반의 CI Expert Agent는 이제 베타에서 사용 가능합니다. 이 에이전트는 팀이 빈 `.gitlab-ci.yml`에서 시작하지 않고 GitLab 코드에서 첫 번째 작동 파이프라인으로 이동하는 데 도움을 줍니다.

GitLab Duo Agent Platform을 사용하여 에이전트가 리포지토리를 검사하고 빌드 및 테스트 프로세스에 대해 몇 가지 안내된 질문을 제시한 다음 검토, 편집 및 커밋할 수 있는 즉시 실행 가능한 파이프라인을 생성합니다.

이는 파이프라인 생성을 대화형, 컨텍스트 인식 경험으로 바꾸면서도 구성을 발전시키고 최적화할 준비가 되었을 때 YAML에 대한 완벽한 제어를 유지할 수 있습니다.

### 자동화된 취약성 심각도 재정의 {#automated-vulnerability-severity-overrides}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/policies/vulnerability_management_policy.md#severity-override-policies) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15839)

{{< /details >}}

기본 취약성 심각도가 항상 조직의 실제 위험을 반영하지는 않습니다. 내부 전용 서비스의 심각한 CVE는 공개 웹사이트 애플리케이션의 것과 같은 긴급성을 보장하지 않을 수 있지만, 팀은 위험 모델과 일치하지 않는 발견 사항을 분류하는 데 상당한 시간을 소비합니다.

취약성 관리 정책은 이제 CVE ID, CWE ID, 파일 경로 및 디렉토리와 같은 조건을 기반으로 취약성의 심각도를 자동으로 조정할 수 있습니다. 적용되면, 정책은 기본 브랜치의 조건과 일치하는 모든 취약성의 심각도를 업데이트합니다. 수동 재정의는 여전히 우선순위가 있으며 모든 변경 사항은 취약성의 이력 및 감사 이벤트에 기록됩니다.

이는 분류 작업을 줄이고 개발자가 비즈니스에 가장 중요한 발견 사항에 집중하도록 합니다.

### 서브그룹 및 프로젝트에서 서비스 계정 생성 {#create-service-account-in-subgroups-and-projects}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/profile/service_accounts.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

팀은 이제 서브그룹 및 프로젝트에서 서비스 계정을 생성할 수 있습니다. 광범위한 최상위 그룹 봇 대신, 전용 서비스 계정을 단일 서브그룹 또는 프로젝트에 연결하고 해당 네임스페이스의 다른 멤버처럼 액세스를 관리할 수 있습니다. 그룹 및 서브그룹 서비스 계정은 생성된 그룹 또는 모든 하위 서브그룹 및 프로젝트에 초대될 수 있습니다. 프로젝트 서비스 계정은 자신의 프로젝트로만 제한됩니다.

### GitLab Free에서 사용 가능한 서비스 계정 {#service-accounts-available-on-gitlab-free}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/profile/service_accounts.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20439)

{{< /details >}}

서비스 계정은 이제 모든 티어에서 GitLab.com에서 사용 가능합니다. 이전에 Premium 및 Ultimate로 제한되었던 서비스 계정을 통해 개별 팀 멤버에게 자격 증명을 연결하지 않고 자동화된 작업을 수행하거나, 데이터에 액세스하거나, 예약된 프로세스를 실행할 수 있습니다. 이들은 팀 변경과 관계없이 자격 증명이 안정적으로 유지되어야 하는 파이프라인 및 타사 통합에서 일반적으로 사용됩니다. GitLab Free에서는 서브그룹 또는 프로젝트에서 생성된 서비스 계정을 포함하여 최상위 그룹당 최대 100개의 서비스 계정을 생성할 수 있습니다.

### 개인 액세스 토큰에 대한 세분화된 권한을 이제 사용할 수 있음(베타) {#fine-grained-permissions-for-personal-access-tokens-now-available-beta}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../auth/tokens/fine_grained_access_tokens.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/18555)

{{< /details >}}

세분화된 개인 액세스 토큰(PAT)은 이제 베타에서 사용 가능합니다. 속하는 모든 프로젝트 및 그룹에 액세스 권한을 부여하는 기존 PAT와 달리, 세분화된 PAT를 사용하면 각 토큰을 특정 리소스 및 작업으로 제한할 수 있습니다. 이는 유출되거나 손상된 토큰의 잠재적 영향을 줄입니다.

기존 PAT는 이전처럼 계속 작동하며, 세분화된 권한 없이 기존 PAT를 계속 생성할 수 있습니다.

이 베타 릴리스는 GitLab REST API의 약 75%를 포함합니다. 완전한 REST API 적용 범위, GraphQL 적용 및 관리자 정책 제어는 GA 릴리스를 위해 계획되어 있습니다.

피드백을 공유하려면 [에픽 18555](https://gitlab.com/groups/gitlab-org/-/epics/18555)를 참조하세요.

### 보안 대시보드의 상위 CWE 차트 {#top-cwe-chart-in-security-dashboards}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md#top-10-cwes) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17422)

{{< /details >}}

상위 CWE 차트는 이제 새로운 보안 대시보드에서 사용 가능합니다. 프로젝트 또는 인스턴스 전체에서 가장 일반적인 CWE를 식별하여 교육, 개선 또는 프로그램 최적화의 기회를 찾습니다. 사용자는 대시보드 데이터를 심각도별로 그룹화하고 심각도, 프로젝트 및 보고서 유형별로 대시보드를 필터링할 수 있습니다.

### Kubernetes에 Gitaly 배포 {#deploy-gitaly-on-kubernetes}

<!-- categories: Gitaly -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../administration/gitaly/kubernetes.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/6127)

{{< /details >}}

이제 Kubernetes에 Gitaly를 완벽하게 지원되는 배포 방법으로 배포할 수 있습니다. 이는 Kubernetes 오케스트레이션 기능을 사용하여 확장, 고가용성 및 리소스 관리를 위한 GitLab 인프라를 관리하는 데 더 큰 유연성을 제공합니다. 이전에는 Kubernetes 배포에 사용자 지정 구성이 필요했으며 공식적으로 지원되지 않아 컨테이너화된 환경에서 안정적인 Gitaly 배포를 유지하기 어려웠습니다.

### MR 파이프라인을 수동으로 실행할 때 입력 재구성 {#reconfigure-inputs-when-manually-running-mr-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../ci/pipelines/merge_request_pipelines.md#run-a-merge-request-pipeline-with-custom-inputs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/547861)

{{< /details >}}

CI/CD 입력의 강력한 측면은 런타임 사용자 지정을 위해 새로운 값으로 새 파이프라인을 수동으로 실행할 수 있다는 것입니다. 이는 이전에 머지 리퀘스트(MR) 파이프라인에서 사용할 수 없었지만, 이 릴리스에서는 MR 파이프라인에서도 입력을 사용자 지정할 수 있습니다.

MR 파이프라인에 대한 입력을 구성한 후, 머지 리퀘스트에 대한 새 파이프라인을 실행할 때마다 이러한 입력을 선택적으로 수정하고 파이프라인 동작을 변경할 수 있습니다.

## 에이전틱 코어 {#agentic-core}

### GitLab Duo Agentic Chat의 기본 모델이 Haiku 4.5에서 Sonnet 4.6으로 업데이트됨 {#default-model-for-gitlab-duo-agentic-chat-updated-from-haiku-45-to-sonnet-46}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/duo_agent_platform/model_selection.md#default-models) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/595042)

{{< /details >}}

GitLab에서 Agentic Chat 경험을 개선하기 위해 업데이트했습니다. Agentic Chat의 기본 모델이 Claude Haiku 4.5에서 Claude Sonnet 4.6(Vertex AI에서 호스팅)으로 업그레이드되었습니다. Claude Sonnet 4.6은 향상된 추론 및 응답 품질을 제공하지만 Haiku 4.5보다 더 높은 GitLab Credit 승수를 사용합니다.

[모델 선택](../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature) 설정을 사용하여 Haiku를 포함한 대체 모델을 선택할 수 있습니다. 이미 특정 모델을 선택한 경우 선택 사항이 유지됩니다. 이 업데이트는 기본값에만 영향을 주며 기존 선택 사항을 재정의하지 않습니다. 모델별 크레딧 승수에 대한 정보는 [GitLab Credits 설명서](../../subscriptions/gitlab_credits.md)를 참조하세요.

### 사용자 지정 플로우 정의에서 도구 구성 {#configure-tools-in-custom-flow-definitions}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/duo_agent_platform/flows/custom.md#create-a-flow) \| [관련 이슈](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2147)

{{< /details >}}

이제 사용자 지정 플로우 정의에서 도구 옵션 및 매개 변수 값을 직접 구성하여 LLM 기본값을 재정의할 수 있습니다. 이를 통해 사용자 지정 플로우 내에서 도구의 동작 방식을 더 정확하고 일관되게 제어할 수 있으므로 해당 플로우 전반에서 가드레일 및 특정 매개 변수 값을 적용하기가 더 쉬워집니다.

### Mistral AI는 이제 GitLab Duo Agent Platform에서 자체 호스팅 모델로 지원됨 {#mistral-ai-now-supported-as-a-self-hosted-model-in-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#cloud-hosted-model-deployments) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/587872)

{{< /details >}}

GitLab Duo Agent Platform은 이제 자체 호스팅 모델 배포를 위해 Mistral AI를 LLM 플랫폼으로 지원합니다. GitLab Self-Managed 고객은 AWS Bedrock, Google Vertex AI, Azure OpenAI, Anthropic 및 OpenAI를 포함한 기존 지원 플랫폼과 함께 Mistral AI를 구성할 수 있습니다. 이를 통해 팀은 AI 기반 기능을 실행하는 방식을 더 자유롭게 선택할 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### GitLab Credits 대시보드의 과거 월별 보기 {#view-historical-months-in-gitlab-credits-dashboard}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) \| [관련 이슈](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910)

{{< /details >}}

고객 포털의 GitLab Credits 대시보드는 이제 과거 월별 탐색을 지원합니다. 청구 관리자는 과거 청구 월을 검색하여 일일 사용 추세를 검토하고, 기간별 소비 패턴을 비교하고, 청구서와 사용량을 조정할 수 있습니다. 이전에는 대시보드에 현재 청구 월만 표시되었습니다. 이 개선을 통해 관리자는 크레딧 할당에 대해 더 정보에 입각한 결정을 내릴 수 있으며 과거 데이터를 기반으로 향후 필요를 예측할 수 있습니다.

### GitLab Credits의 구독 수준 사용 한도 설정 {#set-subscription-level-usage-cap-for-gitlab-credits}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

관리자는 이제 구독 수준에서 온디맨드 크레딧의 월별 사용 한도를 설정할 수 있습니다. 총 온디맨드 크레딧 소비가 구성된 한도에 도달하면, GitLab Duo Agent Platform 액세스는 다음 청구 기간이 시작될 때까지 또는 관리자가 한도를 조정할 때까지 해당 구독의 모든 사용자에게 자동으로 일시 중단됩니다. 이 설정은 조직에 예상치 못한 초과 청구에 대한 강력한 가드레일을 제공하여 더 광범위한 Agent Platform 롤아웃의 핵심 장벽을 제거합니다. 한도는 각 청구 기간마다 자동으로 재설정되며, 한도에 도달하면 관리자가 이메일 알림을 받습니다.

### 사용자별 GitLab Credits 한도 설정 {#set-per-user-gitlab-credits-cap}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

관리자는 이제 청구 기간당 GitLab Credits의 선택적 사용자별 사용 한도를 설정할 수 있습니다. 개별 사용자의 총 크레딧 소비가 구성된 한도에 도달하면, GitLab Duo Agent Platform 액세스는 해당 사용자에게만 일시 중단되는 반면 다른 사용자는 영향을 받지 않습니다. 이는 단일 사용자가 조직의 크레딧 풀의 불균형한 공유를 소비하는 것을 방지하며, 관리자에게 사용 배포에 대한 세분화된 제어를 제공합니다. 사용자별 사용 한도는 구독 수준 사용 한도와 함께 작동하여 먼저 도달한 한도를 적용합니다.

### Linux 패키지 개선사항 {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) \| [관련 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9734)

{{< /details >}}

GitLab 19.0에서 PostgreSQL의 최소 지원 버전은 버전 17입니다. 이 변경을 준비하기 위해 [PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md)를 사용하지 않는 인스턴스에서 GitLab 18.11으로의 업그레이드는 PostgreSQL을 버전 17로 자동으로 업그레이드하려고 시도합니다.

[PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md)를 사용하거나 [자동 업그레이드를 거부](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)하는 경우, GitLab 19.0으로 업그레이드할 수 있으려면 [PostgreSQL 17로 수동으로 업그레이드](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)해야 합니다.

### 컨테이너 레지스트리 메타데이터 데이터베이스에 대한 백업 및 복원 지원 {#backup-and-restore-support-for-container-registry-metadata-database}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/backup_restore/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/durability/-/work_items/45)

{{< /details >}}

Linux 패키지 설치를 위한 GitLab `backup` Rake 작업 및 Cloud Native(Helm) 설치를 위한 `[backup-utility](https://docs.gitlab.com/charts/backup-restore/)`는 이제 [컨테이너 레지스트리 메타데이터 데이터베이스](../../administration/packages/container_registry_metadata_database.md)를 지원합니다. 이제 메타데이터 데이터베이스에 저장된 blob, 매니페스트, 태그 및 기타 데이터에 대한 참조를 백업할 수 있으므로 악의적이거나 우발적인 데이터 손상 발생 시 복구가 가능합니다.

### 탐색에서 그룹을 위한 새로운 탐색 환경 {#new-navigation-experience-for-groups-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/group/_index.md#explore-groups) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/13791)

{{< /details >}}

우리는 **탐색**의 그룹 목록 개선을 발표하게 되어 기쁩니다. GitLab 인스턴스 전체에서 그룹을 더 쉽게 발견할 수 있습니다. 다시 설계된 인터페이스는 두 가지 보기가 있는 탭 레이아웃을 도입합니다:

- **활성** 탭: 모든 액세스 가능한 그룹을 검색하여 관련 커뮤니티 및 프로젝트를 발견할 수 있습니다.
- **비활성** 탭: 보관된 그룹 및 삭제 대기 중인 그룹을 보아 그룹 수명 주기 상태에 대한 가시성을 확보합니다.

이러한 변경은 그룹 검색을 간소화하고 어떤 그룹을 가입할 수 있는지에 대한 더 명확한 가시성을 제공합니다.

### 프로젝트의 비동기 이전 {#asynchronous-transfer-of-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/group/manage.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20521)

{{< /details >}}

GitLab의 이전 버전에서는 대규모 그룹 및 프로젝트의 이전이 시간 초과될 수 있었습니다. 그룹 및 프로젝트를 이전, 보관 및 삭제와 같은 작업을 위한 통합 상태 모델을 사용하도록 이동할 때, 더 일관된 동작, 상태 이력 및 감사 세부 정보에 대한 더 나은 가시성, 특히 비동기 처리를 통한 장시간 이전 작업의 시간 초과 감소를 얻습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### ClickHouse는 Self-Managed 배포를 위해 일반적으로 사용 가능합니다 {#clickhouse-is-generally-available-for-self-managed-deployments}

<!-- categories: DevOps Reports -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../integration/clickhouse.md#set-up-clickhouse) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/work_items/51)

{{< /details >}}

GitLab Self-Managed 인스턴스의 경우, GitLab [ClickHouse 통합](../../integration/clickhouse.md)에 대한 개선된 권장 사항 및 구성 지침을 제공합니다. 고객은 자신의 클러스터를 가져오거나 ClickHouse Cloud(권장) 설정 옵션을 사용할 수 있습니다. 이 통합은 여러 대시보드를 강화하고 분석 공간 내의 다양한 API 엔드포인트에 대한 액세스를 잠금 해제합니다.

이 확장 가능하고 고성능 데이터베이스는 GitLab 분석 인프라를 위해 계획된 더 큰 아키텍처 개선의 일부입니다.

### Duo 및 SDLC 추세 대시보드의 향상된 GitLab Duo Agent Platform 분석 {#enhanced-gitlab-duo-agent-platform-analytics-on-duo-and-sdlc-trends-dashboard}

<!-- categories: DevOps Reports -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/analytics/duo_and_sdlc_trends.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20540)

{{< /details >}}

GitLab Duo 및 SDLC 추세 대시보드는 GitLab Duo가 소프트웨어 전달에 미치는 영향을 측정하기 위한 분석 기능을 개선합니다. 대시보드에는 이제 월별 Agent Platform 고유 사용자 및 Agentic Chat 세션의 새로운 단일 통계 패널이 포함됩니다. 또한 이전에 사용 현황 %로 표시되었던 메트릭은 사용자 할당과 비교하여 엄격하게 사용 현황 수를 보고하도록 업데이트되었습니다. 이 변경은 새로운 사용량 청구 모델에서 제어되는 Agent Platform 사용량이 누락된 [이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590326)를 해결합니다.

### GLQL은 이제 프로젝트, 파이프라인 및 작업 데이터 소스에 액세스할 수 있습니다 {#glql-now-has-access-to-projects-pipelines-and-jobs-data-sources}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/glql/data_sources/_index.md)

{{< /details >}}

[GitLab Query Language (GLQL)](../../user/glql/_index.md)은 이제 프로젝트, 파이프라인 및 작업의 세 가지 새로운 데이터 소스에 액세스할 수 있습니다. 이러한 새로운 데이터 소스는 포함된 보기로도 사용 가능하여 팀이 파이프라인 결과, 작업 상태 및 프로젝트 개요를 wiki, 이슈 및 머지 리퀘스트 설명 및 리포지토리 Markdown 파일에 직접 표시할 수 있습니다. GLQL은 또한 [Data Analyst 에이전트](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)를 강화합니다.

이러한 새로운 유형을 사용하면 에이전트는 CI/CD 작업 결과를 검사하고, 오류를 디버그하고, 파이프라인 실행의 상세한 개요를 제공할 수 있으며, 네임스페이스의 프로젝트에 대한 정확한 개요를 제공할 수 있습니다.

### Maven 및 Python SBOM 검사를 위한 종속성 해결 {#dependency-resolution-for-maven-and-python-sbom-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20461)

{{< /details >}}

SBOM을 사용한 GitLab 종속성 검사는 이제 Maven 및 Python 프로젝트에 대해 자동으로 종속성 그래프 생성을 지원합니다. 이전에는 종속성 검사에서 정확한 종속성 분석을 위해 lock 파일 또는 그래프 파일을 제공해야 했습니다. 이제 lock 파일 또는 그래프 파일을 사용할 수 없을 때 분석기는 자동으로 하나를 생성하려고 시도합니다. 이 개선을 통해 Maven 및 Python 프로젝트가 lock 파일을 요구하지 않고도 종속성 검사를 더 쉽게 활성화할 수 있습니다.

### Advanced SAST를 위한 증분 검사 {#incremental-scanning-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md#incremental-scanning) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20508)

{{< /details >}}

이제 GitLab Advanced SAST로 코드베이스의 변경된 부분만 분석하는 증분 스캔을 수행할 수 있으므로, 전체 리포지토리 스캔에 비해 스캔 시간을 크게 줄일 수 있습니다. 이 기능은 diff 기반 검사의 추가 반복이지만 코드베이스에 대한 전체 결과를 생성합니다.

전체 코드베이스가 아닌 변경된 코드만 스캔하면, 팀이 속도를 희생하거나 마찰을 추가하지 않고도 개발 워크플로우에 보안 테스트를 더 원활하게 통합할 수 있습니다.

### 미확인 취약성(베타) {#unverified-vulnerabilities-beta}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md#report-unverified-vulnerabilities) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/15649)

{{< /details >}}

Advanced SAST는 이제 미확인 취약성(소스에서 싱크까지 완전히 추적할 수 없는 발견 사항)을 취약성 보고서에 직접 표시할 수 있습니다. 거짓 부정에 대한 거짓 긍정에 대한 더 높은 허용 범위가 있는 경우 이 기능을 활성화하세요.

이 기능은 베타 상태입니다. [이슈 596512](https://gitlab.com/gitlab-org/gitlab/-/work_items/596512)에서 피드백을 제공하세요.

### Kubernetes 1.35 지원 {#kubernetes-135-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/584225)

{{< /details >}}

GitLab은 이제 Kubernetes 버전 1.35를 완벽하게 지원합니다. 애플리케이션을 Kubernetes에 배포하고 모든 기능에 액세스하려면 연결된 클러스터를 최신 버전으로 업그레이드하세요. 자세한 내용은 [GitLab 기능을 위해 지원되는 Kubernetes 버전](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)을 참조하세요.

### 컨테이너 레지스트리 메타데이터 데이터베이스의 선호 모드 {#prefer-mode-for-the-container-registry-metadata-database}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/packages/container_registry_metadata_database.md#prefer-mode) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/595480)

{{< /details >}}

이제 컨테이너 레지스트리 메타데이터 데이터베이스를 `prefer` 모드로 설정할 수 있습니다. 이는 기존 `true` 및 `false` 값과 함께 새로운 구성 옵션입니다. 선호 모드에서 레지스트리는 현재 설치 상태를 기반으로 메타데이터 데이터베이스를 사용할지 또는 레거시 스토리지로 대체할지 자동으로 감지합니다.

레지스트리에 데이터베이스로 가져오지 않은 기존 파일 시스템 메타데이터가 있는 경우, 메타데이터 가져오기를 완료할 때까지 레지스트리는 계속 레거시 스토리지를 사용합니다. 데이터베이스가 이미 사용 중이거나 새로 설치되면 레지스트리는 데이터베이스를 직접 사용합니다.

이후 릴리스에서 `prefer` 모드는 새 Linux 패키지 설치의 기본값이 됩니다. 기존 설치는 영향을 받지 않습니다. 자세한 내용은 [이슈 595480](https://gitlab.com/gitlab-org/gitlab/-/work_items/595480)을 참조하세요.

### 패키지 보호 규칙이 이제 Terraform 모듈을 지원합니다 {#package-protection-rules-now-support-terraform-modules}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/packages/package_registry/package_protection_rules.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/592761)

{{< /details >}}

내장 GitLab Terraform 모듈 레지스트리를 통해 Terraform 모듈을 게시하는 팀은 누가 새 모듈 버전을 푸시할 수 있는지 제한할 방법이 없었습니다. 패키지 보호 규칙은 여러 패키지 형식을 지원했지만 `terraform_module`를 포함하지 않아 인프라 팀이 프로젝트 수준 푸시 제어 없이 남겨졌습니다.

이제 `terraform_module`로 범위가 지정된 패키지 보호 규칙을 생성하여 최소 역할을 기반으로 푸시 액세스를 제한할 수 있습니다. 지원은 UI 패키지 유형 드롭다운, REST API, GraphQL API 및 GitLab Terraform 공급자 리소스에서 사용 가능합니다.

### 릴리스 증거가 이제 패키지를 포함합니다 {#release-evidence-now-includes-packages}

<!-- categories: Package Registry, Release Evidence -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/project/releases/release_evidence.md#include-packages-as-release-evidence) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/283995)

{{< /details >}}

GitLab 릴리스를 생성할 때, 패키지 레지스트리에 게시된 패키지는 자동으로 연결되지 않습니다. 팀은 API 또는 파이프라인 스크립트를 통해 패키지 URL을 수동으로 구성하고 릴리스 링크로 첨부해야 하므로 마찰과 불완전한 릴리스 레코드의 위험이 추가됩니다.

GitLab은 이제 패키지 버전이 릴리스 태그와 일치할 때 릴리스 증거에 자동으로 패키지를 포함합니다. 이는 릴리스와 연결된 패키지 간에 검증 가능하고 감사 가능한 링크를 만들어 수동 단계 없이 소스 코드, 아티팩트 및 패키지를 하나의 완전한 릴리스 스냅샷으로 유지합니다.

### 더 쉬운 액세스를 위해 Wiki 사이드바 토글 위치 변경 {#wiki-sidebar-toggle-repositioned-for-easier-access}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/project/wiki/_index.md#sidebar) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/580569)

{{< /details >}}

Wiki 사이드바 토글은 이제 왼쪽에 위치하며, 제어하는 사이드바 바로 옆에 있습니다.

사이드바가 축소되면 토글은 플로팅 컨트롤로 표시되어 페이지 상단으로 다시 스크롤하지 않고도 다시 열 수 있습니다.

### Wiki 페이지에 스티커 동작 표시줄 {#sticky-action-bar-on-wiki-pages}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/project/wiki/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255)

{{< /details >}}

Wiki 페이지의 동작 표시줄은 이제 스티커이므로 페이지를 스크롤할 때 표시 상태로 유지됩니다. 이전에는 편집, 페이지 이력 보기 또는 템플릿 관리와 같은 작업에 액세스하려면 페이지 상단으로 다시 스크롤해야 했습니다. 이제 페이지 제목과 편집, 새 페이지, 템플릿, 페이지 이력 등을 포함한 주요 작업은 페이지 아래쪽이 얼마나 떨어져 있든 상관없이 손이 닿는 범위 내에 있습니다.

### 에픽 가중치 {#epic-weights}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/work_items/weight.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/12273)

{{< /details >}}

에픽은 이제 가중치를 지원하여 계획 중에 대규모 이니셔티브를 추정하고 우선순위를 지정하기가 더 쉬워집니다.

에픽을 자식 이슈로 분해하기 전에, 초기 추정을 나타내기 위해 예비 가중치를 할당할 수 있습니다. 에픽을 분해할 때, 가중치는 모든 자식 이슈로부터의 롤업 합계를 반영하도록 자동으로 업데이트됩니다. 이는 이슈 및 작업에 대한 가중치 롤업의 작동 방식과 일치합니다.

에픽 세부 정보 페이지에서 예비 가중치와 자식 이슈로부터의 롤업 가중치를 모두 볼 수 있어 시간 경과에 따라 추정을 개선하는 데 필요한 인사이트를 제공합니다.

### 높은 악용 위험으로 머지 리퀘스트 차단 {#block-merge-requests-with-high-exploitability-risk}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#vulnerability_attributes-object) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16311)

{{< /details >}}

이전에는 머지 리퀘스트(MR) 승인 정책이 취약성 심각도를 기반으로 MR을 차단할 수 있었지만, 모든 취약성이 동일한 위험을 갖지는 않습니다. CVSS 심각도만으로는 CVE가 악용되고 있는지 또는 악용 가능성이 얼마나 되는지를 알 수 없습니다. 이는 시끄러운 승인 정책 및 개발자와 보안 팀의 낭비된 시간으로 이어집니다.

이제 알려진 악용 취약성(KEV) 및 악용 예측 점수 시스템(EPSS) 데이터를 사용하여 MR 승인 정책을 구성할 수 있습니다. 발견 사항이 KEV 카탈로그에 있을 때(와일드에서 적극적으로 악용 중) 또는 EPSS 점수가 임계값 이상일 때 승인을 차단하거나 요구합니다. MR의 정책 위반에는 KEV 및 EPSS 컨텍스트가 포함되므로 개발자는 보안 게이트가 트리거된 이유를 이해할 수 있습니다.

이는 보안 팀이 어떤 발견 사항을 차단하거나 경고할지에 대한 정확한 제어를 제공하고, 경고 피로를 줄이며, 적용을 현재 위협 환경과 일치시킵니다.

### 취약성에 CVSS 4.0 점수 할당 {#assign-cvss-40-scores-to-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/vulnerabilities/severities.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18697)

{{< /details >}}

CVSS 4.0은 취약성의 심각도를 평가하고 평가하는 데 사용되는 업계 표준의 최신 버전입니다. 이제 취약성 세부 정보 페이지 및 취약성 보고서를 포함하여 UI에서 CVSS 4.0 점수를 보고 액세스할 수 있습니다. API를 사용하여 점수를 쿼리할 수도 있습니다.

### 취약성 보고서의 향상된 행 상호 작용 {#improved-row-interaction-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/561414)

{{< /details >}}

이전에는 취약성 보고서에서 취약성 세부 정보 페이지로 이동하기 위해 행 설명을 선택해야 했습니다.

이제 행의 아무 곳이나 선택하여 세부 정보로 직접 이동할 수 있습니다. 취약성 설명 및 파일 위치의 링크 스타일은 각 링크에 마우스를 올렸을 때만 나타나며 키보드 탐색이 개선되었습니다.

이러한 변경으로 인해 취약성 보고서가 더 직관적이고 접근 가능합니다.

### 보안 대시보드를 PDF로 내보내기 {#export-a-security-dashboard-as-a-pdf}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md#export-as-pdf) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18203)

{{< /details >}}

보안 대시보드를 보고서 및 프레젠테이션용 PDF로 내보낼 수 있습니다. 내보내기는 모든 활성 필터를 포함하여 대시보드의 모든 차트 및 패널의 현재 상태를 캡처합니다.

### 보안 구성 프로필의 SAST 검사 {#sast-scanning-in-security-configuration-profiles}

<!-- categories: Security Testing Configuration -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/configuration/security_configuration_profiles.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/19951)

{{< /details >}}

GitLab 18.9에서는 **Secret Detection - Default** 프로필을 사용하여 보안 구성 프로필을 도입했습니다. GitLab 18.11에서 프로필은 이제 **Static Application Security Testing (SAST) - Default** 프로필로 SAST로 확장되어 단일 CI/CD 구성 파일을 건드리지 않고도 모든 프로젝트에서 표준화된 정적 분석 적용 범위를 적용할 수 있는 통합 제어 표면을 제공합니다.

프로파일은 두 가지 검사 트리거를 활성화합니다.

- **머지 리퀘스트 파이프라인**: 열려 있는 머지 리퀘스트가 있는 브랜치에 새 커밋이 푸시될 때마다 SAST 스캔을 자동으로 실행합니다. 결과는 머지 리퀘스트에 의해 도입된 새로운 취약성만 포함합니다.
- **브랜치 파이프라인(기본값만)**: 기본 브랜치에 변경 사항이 병합되거나 푸시될 때 자동으로 실행되어 기본 브랜치의 완전한 SAST 포스처를 보여줍니다.

### 그룹 보안 대시보드의 보안 속성 필터 {#security-attribute-filters-in-group-security-dashboards}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md#filter-the-entire-dashboard) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18201)

{{< /details >}}

이제 해당 그룹의 프로젝트에 적용한 보안 속성을 기반으로 그룹 보안 대시보드의 결과를 필터링할 수 있습니다.

사용 가능한 보안 속성은 다음과 같습니다:

- 비즈니스 영향
- 애플리케이션
- 비즈니스 단위
- 인터넷 노출
- 위치

### 보안 관리자 역할(베타) {#security-manager-role-beta}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/permissions.md)

{{< /details >}}

보안 관리자 역할은 이제 보안 전문가를 위해 특별히 설계된 새로운 기본 권한 집합을 제공하는 베타 기능으로 사용 가능합니다. 보안 팀은 더 이상 보안 기능에 액세스하기 위해 Developer 또는 Maintainer 역할이 필요하지 않으므로, 과도한 권한 부여 문제를 제거하면서 의무 분리를 유지합니다.

보안 관리자 역할이 있는 사용자는 다음과 같은 액세스 권한을 가집니다:

- **취약성 관리**: 취약성 보고서 및 보안 대시보드를 포함하여 그룹 및 프로젝트 전체에서 취약성을 보고, 분류하고, 관리합니다.
- **보안 인벤토리**: 그룹의 보안 인벤토리를 보아 모든 프로젝트의 스캐너 커버리지를 파악합니다.
- **Security configuration profiles**: 그룹의 보안 구성 프로필을 봅니다.
- **Compliance tools**: 그룹 또는 프로젝트의 감사 이벤트, 규정 준수 센터, 규정 준수 프레임워크 및 종속성 목록을 봅니다.
- **비밀 푸시 방지**: 그룹에 대한 비밀 푸시 방지를 활성화합니다.
- **On-demand DAST**: 그룹에 대한 온디맨드 DAST 검사를 만들고 실행합니다.

시작하려면 그룹으로 이동하여 **관리** > **멤버**를 선택하여 보안 관리자 역할에 멤버를 초대하고 할당합니다.

### 취약성 보고서의 식별자 목록 팝오버 {#identifier-list-popover-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/564939)

{{< /details >}}

취약성 보고서는 이제 각 행에서 기본 CVE 식별자를 클릭 가능한 링크로 표시합니다. 여러 식별자가 있으면 `"+N more"` 팝오버에 모든 식별자가 나열됩니다. 목록의 각 식별자는 외부 참조(예: CVE, CWE 또는 WASC 데이터베이스)로 연결되어 보고서를 떠나지 않고도 빠르게 자세한 내용에 액세스할 수 있습니다.

### GitLab Runner 18.11 {#gitlab-runner-1811}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

우리는 또한 오늘 GitLab Runner 18.11을 출시하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [`concrete` 헬퍼 이미지를 번들된 종속성으로 생성](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39286)
- [환경 변수 대신 러너 구성에서 작업 라우터 기능 플래그를 읽습니다.](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39280)

#### 버그 수정 {#bug-fixes}

- [리팩토링 후 잘못된 러너 바이너리 경로](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39329)
- [캐시 작업에 파이프라인이 중단됨](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39279)
- [`docker-machine` GitLab Runner 18.9.0의 바이너리가 CVE-2025-68121을 참조합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39276)
- [러너가 `DOCKER_AUTH_CONFIG`에서 자격 증명 헬퍼 바이너리가 누락될 때 작업 페이로드 자격 증명으로 자동으로 폴백됨](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39201)
- [`CONCURRENT_PROJECT_ID `서로 다른 작업에서 고유하지 않으므로 빌드 디렉토리에 충돌 발생](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38307)
- [응답 헤더 대기 시간 초과로 아티팩트 업로드 실패](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37220)
- [사용자 정의 `after_script`은 실패한 `pre_build_script` 이후에 실행되고 `post_build_script`를 바이패스합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/3116)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.11)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
