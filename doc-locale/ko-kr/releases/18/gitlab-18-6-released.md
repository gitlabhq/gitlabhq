---
stage: Release Notes
group: Monthly Release
date: 2025-11-20
title: "GitLab 18.6 릴리스 정보"
description: "GitLab 18.6이 새로운 GitLab UI와 함께 릴리스되었습니다: 생산성을 위해 설계됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 11월 20일, GitLab 18.6이 다음 기능과 함께 릴리스되었습니다.

또한 이번 달의 주목할 만한 기여자를 포함하여 모든 기여자에게 감사드립니다.

## 이번 달 주목할 만한 기여자: Samaksh Agarwal {#this-months-notable-contributor-samaksh-agarwal}

GitLab Development Kit(GDK)를 사용하는 모든 개발자는 Samaksh의 [`gdk status`의 가독성을 향상시키기 위한 기여](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/5227)로부터 이점을 얻습니다. 이 개선 사항은 표면적으로는 단순해 보이지만, 개발자 경험에 대한 뛰어난 주의력과 작은 개선이 광범위한 영향을 미칠 수 있다는 이해를 보여줍니다.

`gdk status`의 향상된 가독성은 GDK를 사용하는 모든 개발자의 시간을 절약하고 개발 환경의 핵심 부분 중 하나의 접근성을 상당히 향상시킵니다. 이러한 유형의 기여는 개발자 워크플로우에 의미 있는 개선을 하는 방법을 이해하는 성숙도를 보여줍니다.

자신의 기여에 대해 생각해보면서 Samaksh는 다음과 같이 말합니다: "GitLab Development Kit(또는 GDK)는 지금 제 적극적인 기여의 선택이 되었습니다. 왜냐하면 저는 다른 기여자들의 경험을 쉽고 편리하게 만드는 쪽에서 일하는 것을 개인적으로 좋아하기 때문입니다. 그리고 그것이 제가 되고 싶은 개발자의 종류입니다. 자신의 기술을 사용하여 다른 사람들의 삶을 더 쉽게 만들 수 있는 개발자 말입니다."

GitLab에 기여한 경험에 대해 물었을 때, Samaksh는 다음과 같이 말합니다: "저는 신선하고 품질 좋은 오픈소스 경험을 시도하고 싶은 모든 사람에게 GitLab을 추천하고 싶습니다. 처음 GitLab에 기여하기 시작했을 때는 좀 압도당했지만, 커뮤니티의 모든 사람이 매우 도움이 되고 친절하며 환영해주어서 그 모든 것이 사라졌습니다. 저는 커뮤니티와 이곳에서 일하는 방식에 절대 반하는 마음이 듭니다. 훌륭한 문서 작성에서부터 최고 수준의 코드 품질 유지, 기여자들을 진심으로 감사하는 것까지, GitLab 커뮤니티는 정말 훌륭합니다."

## 주요 기능 {#primary-features}

### 새로운 GitLab UI: 생산성을 위해 설계됨 {#the-new-gitlab-ui-designed-for-productivity}

<!-- categories: Design Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../tutorials/gitlab_navigation.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17279)

{{< /details >}}

개발자 생산성을 우선시하는 더욱 똑똑하고 직관적인 GitLab UI를 소개합니다.

새로운 나란히 배치된 디자인은 상황별 패널을 사용하여 워크플로우를 유지하고, 불필요한 클릭을 줄이며, 팀이 더 빠르게 작업할 수 있도록 도와줍니다. 워크스페이스를 사용자 지정하고, 화면 공간을 최대화하며, 워크플로우에 맞게 조정되는 더욱 깔끔하고 동적인 경험을 즐기세요.

GitLab은 지속적인 개선을 약속하고 있으므로, [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/577554)에서 의견을 공유하고 GitLab의 미래를 형성하는 데 도움을 주세요.

### 제한적 출시의 정확한 코드 검색 {#exact-code-search-in-limited-availability}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/search/exact_code_search.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17918)

{{< /details >}}

이 릴리스를 통해 정확한 코드 검색이 이제 제한적 출시 상태입니다. 정확한 일치 및 정규식 모드를 사용하여 전체 인스턴스, 그룹 또는 프로젝트에서 코드를 검색할 수 있습니다. 정확한 코드 검색은 오픈소스 검색 엔진 Zoekt 위에 구축되었습니다.

GitLab.com의 경우 정확한 코드 검색이 기본적으로 활성화됩니다. GitLab Self-Managed의 경우 관리자가 [Zoekt를 설치](../../integration/zoekt/_index.md#install-zoekt)하고 [정확한 코드 검색을 활성화](../../integration/zoekt/_index.md#enable-exact-code-search)해야 합니다.

이 기능은 활발한 개발 중입니다. [이슈 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)에서 피드백을 환영합니다!

### CI/CD 구성 요소는 자신의 메타데이터를 참조할 수 있습니다 {#cicd-components-can-reference-their-own-metadata}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../ci/yaml/expressions.md#component-context) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)

{{< /details >}}

이전에는 CI/CD 구성 요소가 자신의 메타데이터(예: 버전 번호 또는 커밋 SHA)를 구성 내에서 참조할 수 없었습니다. 이러한 정보 부족으로 인해 하드코딩된 값이나 복잡한 해결 방법이 있는 구성을 사용하게 될 수 있습니다. 이러한 방식으로 구성을 작성하면 구성 요소가 Docker 이미지와 같은 리소스를 빌드할 때 버전 불일치가 발생할 수 있습니다. 구성 요소의 호환 버전으로 이러한 리소스에 자동으로 태그를 지정할 방법이 없기 때문입니다.

이 릴리스에서는 `spec:component` 키워드를 사용하여 구성 요소 컨텍스트에 액세스하는 기능을 도입했습니다. 이제 구성 요소 버전을 릴리스할 때 Docker 이미지와 같은 버전이 지정된 리소스를 빌드하고 게시할 수 있으므로, 모든 것이 동기화되고, 수동 버전 관리가 제거되며, 버전 불일치가 방지됩니다.

### `needs:[parallel:matrix](../../ci/yaml.md#parallelmatrix)`에서 동적 작업 종속성 지원 {#support-dynamic-job-dependencies-in-needsparallelmatrixciyamlmdparallelmatrix}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../ci/yaml/matrix_expressions.md#matrix-expressions-in-needsparallelmatrix) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)

{{< /details >}}

[`parallel:matrix`](../../ci/yaml/_index.md#parallelmatrix)는 다양한 요구 사항으로 여러 작업을 병렬로 쉽게 실행할 수 있게 해줍니다. 예를 들어, 동시에 여러 플랫폼에 대해 코드를 테스트할 수 있습니다. 그러나 나중의 작업이 `needs:parallel:matrix`을 사용하여 특정 병렬 작업에 종속되기를 원했다면, 구성이 복잡하고 유연하지 않았습니다.

이제 `$[[matrix.VARIABLE]]` 식이 베타 기능으로 도입되어, 사용자는 동적 1-1 종속성을 만들 수 있으므로 복잡한 `parallel:matrix` 구성을 훨씬 더 쉽게 관리할 수 있습니다. 이를 통해 더 빠른 파이프라인을 만들고, 효율적인 아티팩트 처리, 더 나은 확장성, 더욱 깔끔한 구성을 얻을 수 있습니다. 이 기능은 멀티 플랫폼 빌드, 여러 환경에 걸친 Terraform 배포, 그리고 여러 차원에 걸친 병렬 처리가 필요한 모든 워크플로우에 특히 유용합니다.

### GitLab Security Analyst 에이전트를 기본 에이전트로 사용 가능 {#gitlab-security-analyst-agent-available-as-a-foundational-agent}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLab Security Analyst 에이전트는 이제 GitLab Duo Agentic Chat의 기본 에이전트입니다. 이는 사용자가 AI 카탈로그에서 GitLab Security Analyst 에이전트를 수동으로 추가할 필요가 없으며, 이 에이전트는 GitLab Self-Managed 및 GitLab Dedicated에서도 기본적으로 사용 가능함을 의미합니다. 이 전문화된 어시스턴트는 AI 기반 취약성 관리 및 보안 분석을 제공하여 결과를 조사하고, 취약성을 분류하며, 설정 없이 규정 준수 요구 사항을 탐색할 수 있도록 도와줍니다.

이 기능은 베타 상태이며 [이슈 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916)에서 피드백을 환영합니다.

### VS Code 및 JetBrains IDE에서 GitLab Duo Agentic Chat 모델 선택 {#model-selection-for-gitlab-duo-agentic-chat-in-vs-code-and-jetbrains-ides}

<!-- categories: Editor Extensions, Model Personalization -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19345)

{{< /details >}}

GitLab Duo Chat에서 바로 선호하는 AI 모델을 쉽게 선택하세요. 이제 VS Code 및 JetBrains IDE에서 사용할 수 있습니다. GitLab Duo Chat 패널의 드롭다운 목록을 사용하여 Claude, GPT 및 기타 지원되는 모델 중에서 선택하세요. 모델 가용성은 조직의 관리자가 관리하므로, 워크플로우에 맞는 올바른 모델에 액세스할 수 있습니다.

### 보안 대시보드 업그레이드 (GitLab.com에서 베타) {#security-dashboard-upgrade-beta-on-gitlabcom}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18509)

{{< /details >}}

새로운 보안 대시보드가 업데이트되고 현대화되었습니다. 베타 릴리스의 초기 기능에는 다음이 포함됩니다:

- 시간 경과에 따른 취약성 차트 지원:
  - 프로젝트 또는 보고서 유형을 기반으로 필터링합니다.
  - 보고서 유형 및 심각도별로 그룹화합니다.
  - 취약성 보고서의 취약성에 대한 직접 링크입니다.
- GitLab 알고리즘을 기반으로 그룹 또는 프로젝트의 예상 위험을 계산하는 위험 점수 모듈입니다.

18.6에서 릴리스된 새로운 보안 대시보드는 현재 GitLab.com에서만 사용할 수 있습니다.

## 에이전틱 코어 {#agentic-core}

### GitLab MCP 서버를 [베타](../../policy/development_stages_support.md#beta)에서 사용 가능 {#gitlab-mcp-server-available-in-beta}

<!-- categories: MCP Server -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/model_context_protocol/mcp_server.md)

{{< /details >}}

GitLab MCP 서버는 [베타](../../policy/development_stages_support.md#beta)에서 사용 가능합니다. GitLab MCP 서버를 사용하면 Claude Code, Cursor 및 기타 MCP 호환 도구와 같은 AI 어시스턴트를 사용하여 GitLab 프로젝트, 이슈, 머지 리퀘스트 및 파이프라인과 상호 작용할 수 있으며, 각 도구에 대해 사용자 지정 통합을 구축할 필요가 없습니다.

시작하려면 GitLab Duo 설정에서 [베타 및 실험적 기능 활성화](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)하세요.

GitLab MCP 서버는 이슈, 머지 리퀘스트 및 파이프라인을 다루는 핵심 도구를 제공하며, 사용자 피드백을 기반으로 계속 개선합니다. 이 기능에는 기능이 불완전하거나 버그가 있을 수 있습니다. [이슈 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)에서 시도하고 피드백을 공유하세요.

### 이슈 설명 및 댓글 모두에 사용 가능한 고급 검색 {#advanced-search-available-for-both-issue-descriptions-and-comments}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/search/advanced_search.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/513146)

{{< /details >}}

고급 검색이 이제 이슈 설명과 댓글 모두에서 일치하는 결과를 반환합니다. 이전에는 사용자가 이슈 설명과 댓글을 별도로 검색해야 했습니다. 이 개선은 GitLab 이슈에 대해 더욱 효율적이고 포괄적인 검색 워크플로우를 제공합니다.

### [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models)와 호환되는 Gemini 2.5 Flash 모델 {#gemini-25-flash-model-compatible-with-gitlab-duo-agent-platform-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/572353)

{{< /details >}}

이제 GitLab Duo Self-Hosted를 사용하여 GitLab Duo Agent Platform에서 Gemini 2.5 Flash 모델을 사용할 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### 프로젝트 및 그룹 구성원 나열을 위한 속도 제한 {#rate-limit-for-listing-project-and-group-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../administration/settings/rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/580116)

{{< /details >}}

우리는 `/api/v4/projects/:id/members/all` 및 `/api/v4/groups/:id/members/all` 엔드포인트에 대한 속도 제한을 도입하여 API 안정성을 개선하고 모든 사용자가 공정하게 리소스를 사용할 수 있도록 했습니다. `GET /api/v4/projects/:id/members/all` 및 `GET /api/v4/groups/:id/members/all` 엔드포인트는 이제 사용자당 분당 200개 요청의 속도 제한이 있습니다.

이 변경은 과도한 API 사용으로부터 GitLab 인스턴스를 보호하는 데 도움이 됩니다. 이는 모든 사용자의 성능에 영향을 미칠 수 있습니다. 분당 200개 요청의 제한은 정상적인 사용 패턴에 충분한 용량을 제공하면서 잠재적인 남용이나 의도하지 않은 리소스 고갈을 방지합니다. 통합 또는 스크립트가 이 엔드포인트를 사용하는 경우, 속도 제한 응답(HTTP 429)을 적절히 처리하고 필요에 따라 백오프를 사용하는 재시도 로직을 구현하세요. 대부분의 사용자는 정상적인 사용 패턴에서 이 변경의 영향을 받지 않아야 합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 보안 푸시 보호 및 파이프라인 시크릿 검색에 대한 증가된 규칙 커버리지 {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/secret_detection/detected_secrets.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/576279)

{{< /details >}}

GitLab의 파이프라인 시크릿 검색에 40개의 새로운 규칙에 대한 지원을 추가했습니다. 기존 규칙 중 일부도 품질을 개선하고 거짓 양성을 줄이기 위해 업데이트되었습니다. 이러한 변경 사항은 시크릿 분석기의 [버전 7.20.1](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.20.1)에서 릴리스됩니다.

### 코드 소유자는 이제 상속된 그룹 구성원을 지원합니다 {#code-owners-now-supports-inherited-group-memberships}

<!-- categories: Code Review Workflow, Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/codeowners/advanced.md#group-inheritance-and-eligibility)

{{< /details >}}

코드 소유권은 코드 품질을 유지하고 코드베이스의 민감한 부분에 대한 변경을 올바른 사람이 검토하도록 하는 데 필수적입니다. 그러나 복잡한 그룹 구조를 가진 조직에서 코드 소유자를 관리하기는 어려웠습니다. 이전에는 `CODEOWNERS` 파일에서 그룹을 참조하기 위해, 부모 그룹의 구성원이 이미 있었더라도 각 특정 프로젝트에 직접 초대되어야 했습니다.

코드 소유자는 이제 적격 승인자로서 상속된 구성원을 가진 그룹을 지원합니다:

- 부모 그룹 구성원을 통해 상속된 액세스를 가진 그룹은 코드 소유자 승인이 활성화되었을 때 유효한 코드 소유자로 인식됩니다.
- 모든 프로젝트에 그룹을 직접 초대할 필요가 없습니다.
- 기존 `CODEOWNERS` 파일은 변경 없이 계속 작동합니다.
- 중요한 코드 경로에 대한 변경을 승인할 수 있는 사람을 제어하는 동일한 수준의 제어입니다.

이 변경은 관리 오버헤드를 줄이면서 코드 소유자가 제공하는 보안 및 승인 요구 사항을 유지합니다.

### 홈페이지에서 초안 머지 리퀘스트 가시성 토글 {#toggle-draft-merge-request-visibility-on-your-homepage}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/merge_requests/homepage.md#set-your-display-preferences) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/551475)

{{< /details >}}

홈페이지에서 초안 머지 리퀘스트는 머지 리퀘스트 보기를 어지럽히고 작업 준비가 된 것에서 산만해질 수 있습니다. 이전에는 필터링할 수 없었습니다.

이제 표시 기본 설정을 사용하여 홈페이지의 **당신의 머지 리퀘스트** 섹션에서 초안 머지 리퀘스트를 숨길 수 있습니다. 초안 머지 리퀘스트를 숨기면:

- 활성 개수에서 제외됩니다.
- 바닥글에 필터링된 초안 머지 리퀘스트의 수가 표시됩니다.
- 기본 설정이 자동으로 저장됩니다.

이 변경은 즉시 주의가 필요한 머지 리퀘스트에 집중할 수 있도록 도와줍니다.

### 새로운 GitLab CLI 기능 및 개선 사항 {#new-gitlab-cli-features-and-improvements}

<!-- categories: GitLab CLI -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](https://docs.gitlab.com/cli/) \| [관련 이슈](https://gitlab.com/gitlab-org/cli/-/releases)

{{< /details >}}

GitLab CLI(glab)는 명령행에서 GitLab 워크플로우를 향상시키기 위한 새로운 기능 및 개선 사항을 제공합니다:

- **Enhanced authentication**: 로그인 중에 git 리모트에서 GitLab URL을 자동 감지하여 올바른 GitLab 인스턴스에 대해 더 쉽게 인증할 수 있습니다.
- **Flexible pipeline monitoring**: `ci-view` 명령으로 ID별로 파이프라인을 봅니다.
- **GPG key management**: CLI에서 새로운 명령으로 GPG 키를 직접 관리합니다.
- **Project member management**: 명령행에서 프로젝트 구성원을 추가, 제거 및 업데이트합니다.
- **Improved Git integration**: 모든 토큰 유형에 대한 지원이 있는 개선된 git-credential 플러그인입니다.
- **Modern user interface**: 더 나은 확인 대화 상자 및 UI 구성 요소 전반에 걸친 일관된 GitLab 테마에 대한 업데이트된 프롬프트 라이브러리입니다.

전체 변경 사항 및 업데이트 목록은 [CLI 릴리스](https://gitlab.com/gitlab-org/cli/-/releases)를 참조하세요. GitLab CLI를 시작하거나 최신 버전으로 업데이트하려면 [설치 가이드](https://gitlab.com/gitlab-org/cli/#installation)를 참조하세요.

### 머지 리퀘스트 검토 재요청 웹후크 알림 {#webhook-notifications-for-merge-request-review-re-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/integrations/webhook_events.md#re-request-review-events)

{{< /details >}}

웹후크 통합은 워크플로우를 자동화하고 외부 시스템을 GitLab 머지 리퀘스트 활동과 동기화된 상태로 유지하는 데 필수적입니다. 그러나 검토자가 머지 리퀘스트에 대해 재요청되었을 때, 웹후크 사용자는 어느 특정 검토자가 재요청되고 있는지 식별할 방법이 없었으므로, 적절한 알림이나 자동화를 트리거하기가 어려웠습니다.

머지 리퀘스트에 대한 웹후크 페이로드는 이제 검토자 데이터에 `re_requested` 속성을 포함하여 어느 검토자가 재요청되었는지를 명확히 나타냅니다:

- `true`로 재요청되는 특정 검토자에 대해 설정합니다.
- 다른 모든 검토자에 대해 `false`로 설정합니다.

이 개선은 머지 리퀘스트 검토 프로세스 주변의 더 정확한 자동화를 가능하게 합니다. 웹후크 사용자는 대상 알림을 보내고, 외부 추적 시스템을 업데이트하며, 검토가 재요청될 때 적절한 워크플로우를 트리거할 수 있습니다.

### 오프라인 GitLab Self-Managed 환경을 위한 Web IDE 지원 {#web-ide-support-for-offline-gitlab-self-managed-environments}

<!-- categories: Web IDE, Editor Extensions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/settings/web_ide.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/15146)

{{< /details >}}

오프라인 또는 긴밀하게 제어되는 네트워크 환경의 GitLab Self-Managed 관리자는 이제 사용자 지정 Web IDE 확장 호스트 도메인을 구성할 수 있으므로, 외부 인터넷 액세스 없이 전체 Web IDE 기능을 사용할 수 있습니다.

이전에는 Web IDE가 `.cdn.web-ide.gitlab-static.net`에 연결하여 VS Code 확장 및 기능을 로드해야 했습니다. 이 요구 사항은 보안에 민감한 조직, 정부 및 공공 부문 고객, 그리고 엄격한 네트워크 정책을 가진 기업에 대한 Web IDE 채택을 차단했습니다.

이 업데이트를 통해 관리자는 Web IDE 자산을 직접 제공하도록 GitLab 인스턴스를 구성할 수 있으므로, 외부 도메인에 대한 종속성이 제거됩니다. 이제 다음을 수행할 수 있습니다:

- 완전히 오프라인 환경에서 전체 Web IDE 기능 세트를 사용합니다.
- 사용자 지정 확장 레지스트리 서비스를 사용하여 확장 마켓플레이스를 활성화합니다.
- 격리된 네트워크에서 Web IDE 내에서 Markdown 미리보기, 코드 편집 및 GitLab Duo Chat을 활성화합니다.

### 시스템에서 시작한 승인 재설정을 위한 웹후크 트리거 {#webhook-triggers-for-system-initiated-approval-resets}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/integrations/webhook_events.md#system-initiated-merge-request-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/553070)

{{< /details >}}

GitLab을 외부 시스템과 웹후크를 통해 통합하는 것은 자동화된 워크플로우를 위해 중요하며, 팀에 머지 리퀘스트 상태 변경에 대해 알리는 것입니다. 그러나 GitLab이 자동으로 승인을 재설정할 때(예: "푸시에 대한 승인 재설정"이 활성화된 머지 리퀘스트에 새 커밋이 푸시되었을 때), 외부 시스템은 이러한 시스템에서 시작한 이벤트를 수동 사용자 작업과 구별할 수 없었습니다.

GitLab은 이제 시스템에서 시작한 승인 재설정을 명확히 식별하는 향상된 웹후크 페이로드를 포함합니다. 승인이 자동으로 재설정되면, 웹후크는 이제 다음을 포함합니다:

- `system` 필드를 `true`로 설정합니다.
- 재설정이 발생한 이유에 대한 구체적인 컨텍스트를 제공하는 `system_action` 필드(예: `approvals_reset_on_push` 또는 `code_owner_approvals_reset_on_push`)입니다.

이는 웹후크 통합이 이제 수동 승인 변경과 자동 시스템 재설정을 구별할 수 있으므로, 각 승인 변경의 특정 컨텍스트에 적절히 대응하는 더욱 정교한 자동화 워크플로우를 활성화할 수 있음을 의미합니다.

### GitLab Duo Planner 에이전트를 이제 기본적으로 사용 가능 {#gitlab-duo-planner-agent-now-available-by-default}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/580924)

{{< /details >}}

GitLab Duo Planner 에이전트는 이제 GitLab Duo Chat의 에이전트 드롭다운에서 기본적으로 사용 가능하므로, AI 카탈로그에서 수동으로 추가할 필요가 없습니다. 작업 항목, 에픽, 이슈 및 작업의 전체 컨텍스트를 통해 Planner 에이전트는 이제 그룹 및 프로젝트 수준 모두에서 도움을 줄 수 있습니다.

[**[예제 프롬프트](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)**\](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)로 시작하여 Planner 에이전트가 복잡한 작업을 분해하고, 구현 계획을 만들고, 팀의 목표를 구성하는 데 어떻게 도움이 되는지 확인하세요.

이 기능은 베타 상태이며, [이슈 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)에서 피드백을 환영합니다.

### Helm 차트 레지스트리: 더 이상 1,000개 차트 제한 없음 {#helm-chart-registry-no-more-1000-chart-limit}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/packages/helm_repository/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/545919)

{{< /details >}}

GitLab의 Helm 차트 레지스트리는 이전에 메타데이터 응답을 즉시 생성했으므로, 리포지토리에 많은 수의 차트가 포함되어 있을 때 성능 병목 현상을 만들었습니다. 시스템 안정성을 유지하기 위해 우리는 1,000개의 가장 최근 차트의 하드 제한을 적용했습니다. 이 제한은 플랫폼 팀이 이전 차트 버전에 액세스하려고 할 때 답답한 404 오류를 야기했습니다.

플랫폼 엔지니어는 차트를 여러 리포지토리에 걸쳐 분할하고, 차트 보유 정책을 수동으로 관리하거나, 별도의 차트 저장소 솔루션을 유지 관리하는 등 복잡한 해결 방법을 구현해야 했습니다. 이러한 해결 방법은 운영 오버헤드를 추가했으며 배포 워크플로우를 분산시켜 중앙화된 차트 거버넌스를 유지하기가 더 어려워졌습니다.

GitLab 18.6에서는 메타데이터 응답을 사전 계산하고 객체 저장소에 저장하여 1,000개 차트 제한을 제거했습니다. 이 아키텍처 변경은 무제한 차트 액세스와 개선된 성능을 모두 제공합니다. 메타데이터는 모든 요청에서가 아니라 백그라운드 작업에서 한 번 생성되기 때문입니다.

### 머지 리퀘스트 승인 정책에서 경고 모드(베타) {#warn-mode-in-merge-request-approval-policies-beta}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

보안 팀은 이제 경고 모드를 사용하여 시행을 적용하기 전에 보안 정책의 영향을 테스트하고 검증하여 보안 정책 출시 중에 개발자 마찰을 줄일 수 있습니다.

[머지 리퀘스트 승인 정책](../../user/application_security/policies/merge_request_approval_policies.md)을 만들거나 편집할 때 이제 `warn` 또는 `enforce` 시행 옵션 중에서 선택할 수 있습니다.

경고 모드의 정책은 머지 리퀘스트를 차단하지 않으면서 정보성 봇 의견을 생성합니다. 선택적 승인자는 정책 질문에 대한 연락처 지점으로 지정될 수 있습니다. 이 접근 방식은 보안 팀이 정책 영향을 평가하고 투명한 점진적 정책 채택을 통해 개발자 신뢰를 구축할 수 있도록 합니다.

머지 리퀘스트의 명확한 표시기는 정책이 `warn` 또는 `enforce` 모드일 때 사용자에게 알려주며, 감사 이벤트는 규정 준수 보고를 위해 정책 위반 및 기각을 추적합니다. 개발자는 기각에 대한 이유를 제공하면서 취약성을 기각할 수 있으므로, 보안 정책 관리에 대한 협력적 접근 방식을 만듭니다.

### 보안 특성(베타) {#security-attributes-beta}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/attributes/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19597)

{{< /details >}}

보안 팀은 이제 보안 특성을 활용하여 프로젝트에 비즈니스 컨텍스트를 적용할 수 있습니다.

보안 특성은 비즈니스 영향(미리 정의된 선택 구조화 포함), 애플리케이션, 비즈니스 단위, 인터넷 노출 및 위치를 포함한 범주별로 구성됩니다. 또는 자신의 특성 범주를 만들고 해당 범주 내에서 레이블을 정의할 수 있습니다.

프로젝트 전반에 이러한 특성을 적용하면, 위험 상황 및 조직 컨텍스트를 기반으로 작업이 필요한 보안 인벤토리 내 프로젝트를 훨씬 더 빠르게 검색, 필터링 및 식별할 수 있습니다. 이제 다음을 수행할 수 있습니다:

- 미션 크리티컬이며 더 나은 스캔 범위가 필요한 프로젝트를 식별합니다.
- 애플리케이션 또는 비즈니스 단위별 스캔 범위를 검토합니다.
- 프로젝트에 적용된 특성을 기반으로 검색하고 필터링합니다.
- 공개적으로 액세스 가능/노출된 애플리케이션에 기여하는 프로젝트를 빠르게 찾습니다.

### 머지 리퀘스트 승인 정책을 우회하기 위한 예외 {#exceptions-to-bypass-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

조직은 이제 머지 리퀘스트 승인 정책을 우회할 수 있는 특정 사용자, 그룹, 역할 또는 사용자 지정 역할을 지정할 수 있습니다. 이 기능은 포괄적인 감사 추적 및 거버넌스 제어를 유지하면서 긴급 대응 유연성을 제공합니다.

**Emergency bypass with accountability**: 지정된 사용자는 중요 인시던트, 보안 핫픽스 또는 긴급 프로덕션 이슈 중에 승인 요구사항을 우회할 수 있습니다. 긴급 상황이 발생하면 권한이 있는 담당자는 시스템이 규정 준수 검토를 위해 자세한 정당성 및 감사 정보를 캡처하는 동안 즉시 변경 사항을 병합하거나 푸시할 수 있습니다.

**주요 기능:**

- **Documented bypass process**: 권한이 있는 사용자가 정책 우회를 호출할 때 직관적인 모달 인터페이스를 사용하여 자세한 이유를 제공해야 하므로 모든 예외가 적절히 문서화되고 컨텍스트와 함께 기록됩니다.
- **Comprehensive audit integration**: 모든 우회는 사용자 ID, 정책 컨텍스트, 이유 및 타임스탬프를 포함하는 자세한 감사 이벤트를 생성하므로 예외 사용 패턴을 완전히 가시화합니다.
- **Flexible configuration**: 개별 사용자, GitLab 그룹, 표준 역할 및 사용자 지정 역할을 지원하는 YAML 또는 UI 구성을 사용하여 정책에 대한 예외 권한을 정의합니다.
- **Git-based push exceptions**: 사전 승인된 정책 예외가 있는 사용자는 푸시 우회 옵션 `security_policy.bypass_reason`을 호출할 때 직접 푸시할 수 있습니다.

이 기능을 통해 긴급 상황 중에 보안 정책을 완전히 비활성화할 필요가 없으므로 조직의 거버넌스 및 감사 요구사항을 유지하면서 긴급 변경에 대한 제어된 경로를 제공합니다.

### 계정 승계 수혜자 지정 {#designate-an-account-succession-beneficiary}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/profile/account/account_succession.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/330669)

{{< /details >}}

이제 귀하가 무능력하거나 사용할 수 없는 경우 GitLab 계정을 관리할 계정 수혜자 권한을 지정할 수 있습니다. 계정에 액세스하려면 수혜자가 적절한 법적 문서를 제공해야 합니다. 이 기능은 무단 액세스를 방지하면서 작업 및 프로젝트의 연속성을 보장합니다.

### 그룹 소유자는 엔터프라이즈 사용자의 기본 이메일을 업데이트할 수 있습니다 {#group-owners-can-update-primary-emails-for-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/enterprise_user/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425837)

{{< /details >}}

그룹 소유자는 이제 자신의 그룹의 엔터프라이즈 사용자의 기본 이메일 주소를 업데이트할 수 있습니다. 업데이트는 사용자 API를 통해 수행할 수 있습니다. 이전에는 각 엔터프라이즈 사용자가 자신의 이메일 주소를 수동으로 업데이트해야 했습니다. 이 변경은 규모에서 엔터프라이즈 사용자를 관리하기가 더 쉽습니다.

### GitLab Runner 18.6 {#gitlab-runner-186}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

우리는 또한 오늘 GitLab Runner 18.6을 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [최소 작업 확인 API 구현](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39013)

#### 버그 수정 {#bug-fixes}

- [GitLab Runner는 Docker 이미지 플랫폼 옵션에서 변수를 확장하지 않습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38488)
- [Helper 사이드카 컨테이너가 다른 계정의 S3 버킷에 캐시를 업로드하지 못합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37879)
- [자동으로 취소된 작업이 계속 실행되고 실패합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37878)
- [생성된 PowerShell 스크립트의 UTF8 BOM이 누락되어 있으므로 문자 Ä가 포함된 머지 리퀘스트 제목을 사용하여 원격 코드 실행이 가능합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36060)
- [Kubernetes 실행기의 간헐적인 Kubernetes API 서버 요청 실패](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30109)
- [Kubernetes 실행기를 사용할 때 큰 커밋 메시지가 있는 작업이 실패합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26624)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.6)
- [지원 중단 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
