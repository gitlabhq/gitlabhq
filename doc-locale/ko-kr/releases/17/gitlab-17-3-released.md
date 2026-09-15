---
stage: Release Notes
group: Monthly Release
date: 2024-08-15
title: "GitLab 17.3 릴리스 정보"
description: "GitLab 17.3이 근본 원인 분석으로 실패한 작업 문제 해결 기능과 함께 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 8월 15일에 GitLab 17.3이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Anton Kalmykov {#this-months-notable-contributor-anton-kalmykov}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Anton Kalmykov은 2월 이후 37개의 [머지된 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&author_username=antonkalmykov)로 올해 GitLab 상위 기여자 중 한 명이며 더 많은 기여가 진행 중입니다. Anton은 [Yolo group (Bombay Games)](https://yolo.com/)의 선임 프론트엔드 엔지니어입니다.

"GitLab에 기여하는 것은 가장 도전적이고 야심 차고 흥미로운 이니셔티브 중 하나입니다"라고 Anton은 말합니다. "이렇게 훌륭한 제품을 만들고 개선하는 데 참여할 수 있는 기회를 감사합니다. 이 기회 덕분에 많은 새로운 것을 배웠고, 여전히 해야 할 일이 많습니다. 특히 내 머지 리퀘스트를 검토해주고 지도해주며 올바르게 처리하도록 도와주신 GitLab 팀에 정말 감사합니다."

Anton은 GitLab의 선임 제품 관리자인 [Christina Lohr](https://gitlab.com/lohrc)에 의해 Tenant Scale 그룹의 여러 프론트엔드 이슈를 도와준 것으로 추천되었습니다.

"기본 워크플로우를 위해 더 많은 작은 UX 개선이 필요하며, 커뮤니티의 도움을 받아 이러한 이니셔티브를 더 빠르게 완료할 수 있어서 좋습니다"라고 Christina는 말합니다. "이러한 모든 개선 사항은 그룹과 프로젝트 간의 더욱 응집력 있는 사용자 경험을 만드는 데 도움이 됩니다. 감사합니다 Anton."

Anton과 GitLab의 오픈 소스 기여자 여러분께 GitLab을 함께 만들어주셔서 감사합니다!

## 주요 기능 {#primary-features}

### 근본 원인 분석으로 실패한 작업 문제 해결 {#troubleshoot-failed-jobs-with-root-cause-analysis}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13080)

{{< /details >}}

근본 원인 분석은 이제 일반적으로 사용할 수 있습니다. 근본 원인 분석을 사용하면 CI/CD 파이프라인에서 실패한 작업을 더 빠르게 문제 해결할 수 있습니다. 이 AI 기반 기능은 실패한 작업 로그를 분석하고 작업 실패의 근본 원인을 신속하게 파악하며 해결 방법을 제안합니다.

### GitLab Duo 헬스 체크 베타 {#health-check-for-gitlab-duo-in-beta}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/14518)

{{< /details >}}

이제 자체 관리 인스턴스에서 GitLab Duo의 설정을 문제 해결할 수 있습니다. **운영자** 영역의 GitLab Duo 페이지에서 **헬스 체크 실행**을 선택합니다. 이 헬스 체크는 일련의 유효성 검사를 수행하고 GitLab Duo가 작동 중인지 확인하기 위한 적절한 수정 조치를 제안합니다.

GitLab Duo의 헬스 체크는 자체 관리 및 GitLab Dedicated에서 베타 기능으로 제공됩니다.

### GitLab UI에서 pod 삭제 {#delete-a-pod-from-the-gitlab-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md#delete-a-pod) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467653)

{{< /details >}}

Kubernetes에서 실패한 pod을 다시 시작하거나 삭제해야 한 적이 있습니까? 지금까지는 GitLab을 떠나 다른 도구를 사용하여 클러스터에 연결한 후 pod을 중지하고 새 pod이 시작될 때까지 기다려야 했습니다. 이제 GitLab은 pod 삭제를 위한 기본 제공 지원을 제공하므로 Kubernetes 클러스터를 원활하게 문제 해결할 수 있습니다.

클러스터 또는 네임스페이스 전체의 모든 pod을 나열하는 [Kubernetes 대시보드](../../ci/environments/kubernetes_dashboard.md)에서 pod을 중지할 수 있습니다.

### 로컬 터미널에서 클러스터로 쉽게 연결 {#easily-connect-to-a-cluster-from-your-local-terminal}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/user_access.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/463769)

{{< /details >}}

로컬 터미널에서 또는 데스크톱 Kubernetes GUI 도구 중 하나를 사용하여 Kubernetes 클러스터에 연결하시겠습니까? GitLab을 사용하면 [Kubernetes 에이전트의 사용자 액세스 기능](../../user/clusters/agent/user_access.md)을 사용하여 터미널에 연결할 수 있습니다. 이전에는 명령을 찾기 위해 GitLab을 벗어나 설명서를 탐색해야 했습니다. 이제 GitLab은 UI에서 연결 명령을 제공합니다. GitLab은 사용자 액세스를 구성하는 데도 도움을 줄 수 있습니다!

연결 명령을 검색하려면 [Kubernetes 대시보드](../../ci/environments/kubernetes_dashboard.md)로 이동하거나 [에이전트 목록](../../user/clusters/agent/work_with_agent.md#view-your-agents)으로 이동합니다.

### AI를 사용하여 취약성 해결 {#resolve-a-vulnerability-with-ai}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10783)

{{< /details >}}

취약성 해결은 AI를 사용하여 사용자가 취약성을 수정할 수 있도록 특정 코드 제안을 제공합니다. 버튼 클릭으로 [지원되는 CWE 식별자 목록](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution)에서 SAST 취약성을 해결하기 위한 머지 리퀘스트를 열 수 있습니다.

### 단일 프로젝트에 여러 규정 준수 프레임워크 추가 {#add-multiple-compliance-frameworks-to-a-single-project}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/working_with_projects.md#add-a-compliance-framework-to-a-project) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13294)

{{< /details >}}

규정 준수 프레임워크를 만들어 프로젝트에 특정 규정 준수 요구 사항이 있거나 추가 감시가 필요함을 식별할 수 있습니다. 규정 준수 프레임워크는 선택적으로 규정 준수 파이프라인 구성을 적용되는 프로젝트에 적용할 수 있습니다.

이전에는 사용자가 프로젝트에 규정 준수 프레임워크 하나만 적용할 수 있었으므로 프로젝트에 설정할 수 있는 규정 준수 요구 사항의 수가 제한되었습니다. 이제 사용자가 프로젝트당 여러 규정 준수 프레임워크를 적용할 수 있는 기능을 제공했습니다. 이를 통해 사용자는 주어진 시간에 단일 프로젝트에 여러 개의 서로 다른 규정 준수 프레임워크를 적용할 수 있습니다. 이 릴리스에서는 여러 규정 준수 프레임워크를 프로젝트에 적용할 수 있습니다. 그러면 프로젝트가 각 프레임워크의 규정 준수 요구 사항으로 설정됩니다.

### AI 영향 분석: 코드 제안 수락 비율 및 GitLab Duo 사용자 수 {#ai-impact-analytics-code-suggestions-acceptance-rate-and-gitlab-duo-seats-usage}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/471168)

{{< /details >}}

이 두 개의 새로운 메트릭은 GitLab Duo의 효과와 활용도를 강조하며, 이제 [값 흐름 대시보드의 AI 영향 분석](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)에 포함되어 조직이 비즈니스 가치 제공에서 GitLab Duo의 영향을 이해하는 데 도움이 됩니다.

**코드 제안 수락 비율** 메트릭은 개발자가 GitLab Duo에서 제공한 코드 제안을 수락하는 빈도를 나타냅니다. 이 메트릭은 이러한 제안의 효과와 기여자가 AI 기능에 대해 갖고 있는 신뢰 수준을 모두 반영합니다. 구체적으로, 이 메트릭은 GitLab Duo가 제공하고 지난 30일 동안 코드 기여자가 수락한 코드 제안의 비율을 나타냅니다.

**GitLab Duo seats assigned and used** 메트릭은 소비된 라이선스 사용자의 백분율을 표시하여 조직이 라이선스 활용, 리소스 할당 및 사용 패턴 이해를 효과적으로 계획할 수 있도록 도와줍니다. 이 메트릭은 지난 30일 동안 최소 하나의 AI 기능을 사용한 할당된 사용자의 비율을 추적합니다.

이러한 새로운 메트릭 추가와 함께 새로운 개요 타일(메트릭에 대한 명확한 요약을 제공하는 새로운 시각화)도 도입했으며, 이는 AI 기능의 현재 상태를 빠르게 평가하는 데 도움이 됩니다.

## 규모 및 배포 {#scale-and-deployments}

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.3은 [Raspberry Pi OS 12](https://www.raspberrypi.com/news/bookworm-the-new-version-of-raspberry-pi-os/)를 지원하기 위한 패키지를 포함합니다.

Debian 10은 [2024년 6월 30일에 EOL에 도달](https://www.debian.org/releases/buster/)했습니다. GitLab은 GitLab 17.6에서 Debian 10에 대한 지원을 제거합니다.

### 내 작업의 프로젝트 및 그룹에 대한 정렬 및 필터링 개선 {#improved-sorting-and-filtering-for-projects-and-groups-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/25368)

{{< /details >}}

**Your Work**에서 프로젝트 및 그룹 개요의 정렬 및 필터링 기능을 업데이트했습니다. 이전에는 **Your Work** 프로젝트 페이지에서 이름 및 언어별로 필터링하고 사전 정의된 정렬 옵션 세트를 사용할 수 있었습니다. 정렬 옵션을 **이름**, **만든 날짜**, **업데이트 날짜** 및 **별점**을 포함하도록 표준화했습니다. 오름차순 또는 내림차순으로 정렬할 수 있는 탐색 요소를 추가하고 언어 필터를 필터 메뉴로 옮겼습니다. 이제 새 **비활성** 탭에서 보관된 프로젝트를 찾을 수 있습니다. 또한 소유자인 프로젝트를 검색할 수 있는 **역할** 필터를 추가했습니다.

내 작업 그룹 페이지에서 정렬 옵션을 **이름**, **만든 날짜**, **업데이트 날짜**를 포함하도록 표준화했고, 오름차순 또는 내림차순으로 정렬할 수 있는 탐색 요소를 추가했습니다.

[\#438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322)에서 이러한 변경 사항에 대한 피드백을 환영합니다.

### 고급 검색을 위한 종단 간 인스턴스 인덱싱 {#end-to-end-instance-indexing-for-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/advanced_search/elasticsearch.md#index-the-instance) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/271532)

{{< /details >}}

GitLab에서 고급 검색을 활성화하면 이제 **인스턴스 인덱싱**을 선택하여 초기 인덱싱을 수행하거나 처음부터 인덱스를 다시 만들 수 있습니다. 이 설정은 `gitlab:elastic:index` rake 작업과 기능적 패리티를 달성하여 모든 지원되는 데이터 유형을 통합 Elasticsearch 또는 OpenSearch 클러스터로 인덱싱합니다.

**인스턴스 인덱싱**은 초기 인덱싱만으로 제한되던 모든 프로젝트를 인덱싱하는 설정을 대체합니다.

### API를 사용하여 통합을 위한 설정 상속 토글 {#toggle-inheriting-settings-for-integrations-by-using-the-api}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)

{{< /details >}}

지금까지 UI를 사용하여 프로젝트가 통합 설정을 상속했는지 또는 자체 설정을 사용했는지 제어할 수만 있었습니다.

이 마일스톤에서 REST API의 모든 통합에 새로운 `use_inherited_settings` 매개 변수를 도입합니다. 이 매개 변수를 통해 API를 사용하여 프로젝트가 통합 설정을 상속하는지 여부를 설정할 수 있습니다. 설정되지 않은 경우 기본 동작은 `false`(프로젝트의 자체 설정 사용)입니다.

### API를 사용하여 그룹 또는 프로젝트 웹후크 이벤트 나열 {#list-group-or-project-webhook-events-with-the-api}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/project_webhooks.md#list-project-webhook-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437188)

{{< /details >}}

GitLab 9.3 이후로 UI에서 프로젝트 웹후크 요청 기록을 볼 수 있으며, GitLab 15.3 이후로 [UI에서 그룹 웹후크 요청 기록을 볼 수](../../user/project/integrations/webhooks.md#view-webhook-request-history) 있습니다.

이 릴리스에서 해당 데이터는 이제 REST API에 노출되어 웹후크 오류를 발견하고 대응하는 프로세스를 자동화하는 데 도움이 될 수 있습니다. 지난 7일 동안 특정 [프로젝트 훅](../../api/project_webhooks.md#list-project-webhook-events) 및 [그룹 훅](../../api/group_webhooks.md#list-all-group-hook-events)의 이벤트 목록을 가져올 수 있습니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048)를 주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### 명령어 팔레트를 사용하여 그룹 설정 찾기 {#find-group-settings-by-using-the-command-palette}

<!-- categories: Settings, Global Search -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/command_palette.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/448646)

{{< /details >}}

17.2에서 [명령어 팔레트를 사용하여 프로젝트 설정 검색](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#find-project-settings-by-using-the-command-palette)하는 기능을 추가했습니다. 이 변경 사항으로 필요한 설정을 빠르게 찾을 수 있게 되었습니다.

17.3에서는 명령어 팔레트에서 그룹 설정도 검색할 수 있습니다. 그룹을 방문하여 **검색 또는 이동**을 선택하고, `>`으로 명령 모드를 입력한 후 **머지 리퀘스트 승인** 같은 설정 섹션의 이름을 입력하여 시도해보세요. 결과를 선택하여 설정 자체로 바로 이동합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### VS Code에서 언어별 코드 제안의 세분화된 제어 {#granular-control-of-code-suggestions-by-language-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/project/repository/code_suggestions/supported_extensions.md#manage-languages-for-code-suggestions) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1388)

{{< /details >}}

VS Code에서 특정 프로그래밍 언어에 대해 코드 제안을 활성화하거나 비활성화하여 코딩 환경을 더 제어할 수 있습니다. 이 세분화된 제어를 통해 워크플로우를 사용자 지정하고, 관련 없거나 방해가 되는 제안을 줄이면서 선호하는 언어에 대한 코드 제안의 이점을 유지할 수 있습니다.

### JetBrains IDE의 개선된 TLS 지원 {#improved-tls-support-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md#certificate-errors) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/371)

{{< /details >}}

민감한 환경에서 더 강력한 보안을 위해 클라이언트 인증서 및 인증서 기관을 포함한 사용자 지정 HTTP 에이전트 옵션을 JetBrains IDE 설정에서 직접 구성할 수 있습니다.

### 리포지토리에서 더 쉽게 콘텐츠 제거 {#more-easily-remove-content-from-repositories}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/repository_size.md#remove-blobs)

{{< /details >}}

현재 리포지토리에서 콘텐츠를 제거하는 프로세스는 복잡하며 프로젝트를 GitLab으로 강제 푸시해야 할 수도 있습니다. 이는 오류가 발생하기 쉬우며 푸시를 활성화하기 위해 임시로 보호를 해제해야 할 수 있습니다. 리포지토리 내에서 너무 많은 공간을 차지하는 파일을 삭제하기가 더 어려울 수 있습니다.

이제 프로젝트 설정에서 새 리포지토리 유지 관리 옵션을 사용하여 개체 ID 목록을 기반으로 Blob을 제거할 수 있습니다. 이 새로운 방법을 사용하면 프로젝트를 GitLab으로 다시 강제 푸시할 필요 없이 콘텐츠를 선택적으로 제거할 수 있습니다.

시크릿 또는 기타 콘텐츠가 프로젝트에서 수정되어야 하는 경우, 텍스트를 수정하는 새로운 옵션도 도입합니다. GitLab이 `***REMOVED***`로 바꿀 문자열을 제공하여 프로젝트 전체 파일에서 제공합니다. 텍스트가 수정된 후 하우스키핑을 실행하여 문자열의 이전 버전을 제거합니다.

이 새로운 UI는 콘텐츠를 제거해야 할 때 리포지토리를 관리하는 방법을 간소화합니다.

### Kubernetes 에이전트를 만들고 삭제할 때 감사 이벤트 {#audit-event-when-agent-for-kubernetes-is-created-and-deleted}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/audit_event_types.md#deployment-management) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/462749)

{{< /details >}}

Kubernetes 에이전트는 Kubernetes 클러스터와 GitLab 간의 양방향 데이터 흐름을 허용하므로 시스템에 액세스할 수 있는 구성 요소가 추가되거나 제거될 때 알아야 합니다. 이전 릴리스에서는 규정 준수 팀이 사용자 지정 도구를 사용하거나 GitLab에서 직접 이 데이터를 검색해야 했습니다. GitLab은 이제 다음 감사 이벤트를 제공합니다:

- `cluster_agent_created`는 Kubernetes용 새 에이전트를 등록한 사용자를 기록합니다.
- `cluster_agent_create_failed`는 Kubernetes용 새 에이전트를 등록하려고 했지만 실패한 사용자를 기록합니다.
- `cluster_agent_deleted`는 Kubernetes 에이전트 등록을 제거한 사용자를 기록합니다.
- `cluster_agent_delete_failed`는 Kubernetes 에이전트 등록을 제거하려고 했지만 실패한 사용자를 기록합니다.

이러한 감사 이벤트는 `cluster_agent_token_created` 및 `cluster_agent_token_revoked` 감사 이벤트를 확장하여 GitLab 인스턴스를 감사할 수 있는 능력을 추가로 개선합니다.

### Kubernetes 1.30 지원 {#kubernetes-130-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/456929)

{{< /details >}}

이 릴리스는 2024년 4월에 릴리스된 Kubernetes 버전 1.30에 대한 완벽한 지원을 추가합니다. 앱을 Kubernetes에 배포하는 경우 이제 연결된 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

[저희의 Kubernetes 지원 정책 및 기타 지원되는 Kubernetes 버전](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)에 대해 자세히 알아볼 수 있습니다.

### 머지 리퀘스트 외부 상태 확인에 인증 추가 {#add-authentication-to-merge-request-external-status-checks}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/merge_requests/status_checks.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/433035)

{{< /details >}}

외부 상태 확인은 이제 HMAC(해시 기반 메시지 인증 코드) 인증으로 구성할 수 있습니다. 이는 GitLab에서 외부 서비스로의 요청 진정성을 확인하는 더 안전한 방법을 제공합니다.

상태 확인에 대해 활성화되면 공유 시크릿이 각 요청에 대한 고유한 서명을 생성하는 데 사용됩니다. 서명은 `X-Gitlab-Signature` 헤더로 전송되며 SHA256을 해시 알고리즘으로 사용합니다.

- 개선된 보안: HMAC 인증은 요청 변조를 방지하고 요청이 합법적인 소스에서 오도록 합니다.
- 규정 준수: 이 기능은 보안이 중요한 은행과 같은 규제 산업에 특히 유용합니다.
- 하위 호환성: 이 기능은 선택 사항이며 하위 호환성이 있습니다. 사용자는 새 확인이나 기존 확인에 대해 HMAC 인증을 활성화할 수 있지만, 기존 외부 상태 확인은 변경 없이 계속 작동합니다.

[향후 반복](https://gitlab.com/gitlab-org/gitlab/-/issues/476163)에서 GitLab은 HTTP 요청을 확인하고 차단하는 옵션을 추가할 계획입니다.

### 그룹 또는 프로젝트의 멤버 목록을 역할별로 필터링 {#filter-the-member-list-in-a-group-or-project-by-role}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/members/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431397)

{{< /details >}}

사용자는 이제 멤버 페이지를 역할별로 필터링할 수 있습니다. 필터를 사용하여 특정 역할을 가진 멤버를 찾습니다.

### 오른쪽 드로어에서 역할 세부 정보 보기 {#view-role-details-in-the-right-drawer}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/13061)

{{< /details >}}

이전에는 사용자의 사용자 지정 역할 권한을 보려면 그룹에서 소유자 역할을 가져야 했습니다. 이 요구 사항으로 인해 사용자 지정 역할이 할당되었을 때 사용자가 수행할 수 있는 작업을 문제 해결하고 이해하기가 어려웠습니다. 이제 모든 사용자는 멤버 페이지에서 사용자 지정 역할이 할당된 사용자의 권한을 볼 수 있습니다.

### 사용자 지정 역할에 대한 LDAP 그룹 링크 지원 {#ldap-group-link-support-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435229)

{{< /details >}}

LDAP 그룹 링크를 사용하여 그룹의 사용자 권한을 관리하는 조직은 이미 멤버십에 기본 역할을 사용할 수 있습니다.

이 릴리스에서는 [사용자 지정 역할](../../user/custom_roles/_index.md)에 대한 지원을 확장합니다. 이 구성을 통해 많은 수의 사용자에게 액세스를 쉽게 매핑할 수 있습니다.

### 사용자 지정 역할에 대한 새로운 권한 {#new-permission-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

다음 새로운 권한으로 사용자 지정 역할을 만들 수 있습니다:

- [러너 읽기](../../user/custom_roles/abilities.md#runner)

사용자 지정 역할을 사용하면 동등한 권한을 가진 사용자를 만들어 소유자 역할을 가진 사용자 수를 줄일 수 있습니다. 이를 통해 그룹의 필요에 맞게 조정된 역할을 정의하고 사용자에게 필요 이상의 권한을 부여하는 것을 방지할 수 있습니다.

### Admin UI를 사용하여 개인 액세스 토큰 비활성화 {#disable-personal-access-tokens-using-admin-ui}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md#view-token-usage-information) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/436991)

{{< /details >}}

관리자는 이제 Admin UI를 통해 인스턴스 개인 액세스 토큰을 비활성화하거나 다시 활성화할 수 있습니다. 이전에는 관리자가 이를 수행하기 위해 응용 프로그램 설정 API 또는 GitLab Rails 콘솔을 사용해야 했습니다.

### 사용자 프로필의 Bluesky 식별자 {#bluesky-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/451690)

{{< /details >}}

이제 GitLab 프로필에 Bluesky did:plc 식별자를 추가할 수 있습니다.

[Dominique](https://domi.zip/)님의 기여에 감사합니다!

### 로그아웃 시 서브도메인 쿠키 유지 {#subdomain-cookies-preserved-on-sign-out}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/active_sessions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/471097)

{{< /details >}}

GitLab의 로그아웃 프로세스가 개선되어 로그아웃 시 형제 서브도메인의 쿠키가 삭제되지 않습니다. 이전에는 이러한 쿠키가 삭제되어 사용자가 GitLab과 동일한 최상위 도메인의 다른 서브도메인 서비스에서 로그아웃되었습니다. 예를 들어 사용자가 `kibana.example.com`에 Kibana가 설정되어 있고 `gitlab.example.com`에 GitLab이 설정되어 있는 경우 GitLab에서 로그아웃하면 더 이상 Kibana에서 로그아웃되지 않습니다.

[Guilherme C. Souza](https://gitlab.com/GCSBOSS)님의 기여에 감사합니다!

### 향상된 스파클라인 추세 시각화가 있는 AI 영향 분석 {#ai-impact-analytics-with-enhanced-sparklines-trend-visualization}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../user/analytics/duo_and_sdlc_trends.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/464692)

{{< /details >}}

[AI 영향 분석](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/) 도입으로 상당한 개선을 발표하게 되어 기쁩니다. 데이터 테이블에 포함된 이러한 작은 간단한 그래프는 AI 영향 데이터의 가독성과 접근성을 향상합니다. 수치 값을 시각적 표현으로 변환하면 새로운 스파클라인을 사용하여 시간 경과에 따른 추세를 더 쉽게 식별할 수 있으므로 상향 또는 하향 이동을 감지할 수 있습니다. 이 새로운 시각적 접근 방식은 여러 메트릭 간의 추세를 비교하는 프로세스를 간소화하여 숫자에만 의존할 때 필요한 시간과 노력을 줄입니다.

### 작업에 머지 리퀘스트 추가 {#add-merge-requests-to-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/tasks.md#add-a-merge-request-and-automatically-close-tasks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/440851)

{{< /details >}}

작업은 이슈를 엔지니어링 구현 단계로 분해하는 데 자주 사용됩니다. 이 릴리스 이전에는 머지 리퀘스트를 구현하는 작업에 연결할 수 없었습니다. 이제 머지 리퀘스트 설명에서 이슈를 참조할 때 사용하는 것과 동일한 [종료 패턴](../../user/project/issues/managing_issues.md#closing-issues-automatically)을 사용하여 머지 리퀘스트를 작업에 연결할 수 있습니다. 작업 보기에서 연결된 머지 리퀘스트는 사이드바에서 볼 수 있습니다. 프로젝트에 [자동 닫기 설정이 활성화](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing)되어 있으면, 연결된 머지 리퀘스트가 기본 브랜치에 병합될 때 작업이 자동으로 닫힙니다.

### OKR 및 작업에 대한 상위 항목 설정 {#set-parent-items-for-okrs-and-tasks}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/okrs.md#set-an-objective-as-a-parent) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11198)

{{< /details >}}

[OKR](../../user/okrs.md#set-an-objective-as-a-parent) 및 [작업](../../user/tasks.md#set-an-issue-as-a-parent)에 대한 상위 할당을 하위 레코드에서 직접 업데이트할 수 있으므로 왕복할 필요가 없습니다. 이는 [워크플로우의 효율성 개선](https://gitlab.com/groups/gitlab-org/-/epics/10501)이라는 목표를 향한 훌륭한 진전입니다.

### 작업, OKR 항목에 대해 학대 신고 {#report-abuse-for-task-objective-and-key-result-items}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/report_abuse.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)

{{< /details >}}

이제 **조치** 메뉴에서 직접 작업 항목에 대해 쉽게 학대를 신고할 수 있으며 이는 레거시 이슈와 마찬가지입니다. 이 새로운 기능은 부적절한 콘텐츠를 빠르게 표시할 수 있도록 하여 워크스페이스를 깨끗하고 안전하게 유지하는 데 도움이 되므로 팀을 위한 더 나은 협업 환경을 보장합니다.

### 작업, OKR의 스레드 해결 {#resolve-threads-in-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/discussions/_index.md#resolve-a-thread) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)

{{< /details >}}

이제 작업, OKR에서 스레드를 해결할 수 있으므로 중요한 대화를 더 쉽게 관리하고 추적할 수 있습니다. 해결된 스레드는 기본적으로 축소되어 활성 토론에 집중하고 협업 워크플로우를 간소화하는 데 도움이 됩니다.

### 주기 시간 단축을 위한 새로운 값 흐름 분석 스테이지 이벤트 {#new-value-stream-analytics-stage-events-for-cycle-time-reduction}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/466383)

{{< /details >}}

GitLab의 머지 리퀘스트 검토 시간 추적을 개선하기 위해 [값 흐름 분석](https://about.gitlab.com/solutions/value-stream-management/)에 새로운 스테이지 이벤트를 추가했습니다: **MR first reviewer assigned**. 이 새로운 이벤트를 통해 팀은 검토 프로세스에서 지연이 발생하는 위치를 식별하고, 협업을 개선할 수 있는 기회를 찾으며, 팀원 간의 대응성과 책임 문화를 장려할 수 있습니다. 검토 시간 단축은 개발의 전체 주기 시간에 직접적인 영향을 미치며, [더 빠른 소프트웨어 제공으로 이어집니다](https://about.gitlab.com/blog/three-steps-to-optimize-software-value-streams/). 예를 들어 이제 **Review Time to Merge (RTTM)**으로 시작하는 새로운 사용자 지정 **MR first reviewer assigned** 스테이지를 추가하고 **MR merged**으로 끝낼 수 있습니다.

### 종속성 및 라이선스 검사의 Rust 지원 {#rust-support-for-dependency-and-license-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/13093)

{{< /details >}}

구성 분석이 종속성 및 라이선스 검사를 위한 Rust 지원을 제공했습니다. Rust 검사는 `Cargo.lock` 파일 유형을 지원합니다.

프로젝트에 대해 Rust 검사를 활성화하려면 [종속성 검사 CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/dependency-scanning)에서 `cargo` 템플릿을 사용합니다.

### GitLab UI에 SBOM 수집 오류 표시 {#display-sbom-ingestion-errors-in-gitlab-ui}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_list/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/14408)

{{< /details >}}

GitLab 15.3은 [CycloneDX SBOM 수집](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)에 대한 지원을 추가했습니다. SBOM 보고서는 CycloneDX 스키마에 대해 검증되지만 검증의 일부로 생성된 경고 및 오류는 사용자에게 표시되지 않았습니다.

GitLab 17.3에서 이러한 검증 메시지는 프로젝트 수준 취약성 보고서 및 종속성 목록 페이지의 GitLab UI에 나타납니다.

사용자는 GitLab UI의 다음 영역에서 SBOM 수집 오류를 볼 수 있습니다: 프로젝트 수준 취약성 보고서 및 종속성 목록 페이지, 파이프라인 페이지의 라이선스 및 보안 탭.

### SAST, IaC 검사 및 시크릿 검색에 사용된 규칙 집합 적용 {#enforce-the-ruleset-used-in-sast-iac-scanning-and-secret-detection}

<!-- categories: SAST, Secret Detection, Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/customize_rulesets.md#use-a-remote-ruleset-file)

{{< /details >}}

[SAST](../../user/application_security/sast/customize_rulesets.md), [IaC 검사](../../user/application_security/iac_scanning/_index.md#optimize-iac-scanning) 및 [시크릿 검색](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-behavior)에 사용된 규칙을 사용자 지정할 수 있습니다. 리포지토리에 커밋한 로컬 구성 파일을 만들거나 여러 프로젝트에 걸쳐 공유 구성을 적용하기 위해 CI/CD 변수를 설정하여 규칙을 사용자 지정합니다.

이전에는 공유 규칙 집합 참조를 설정한 경우에도 스캐너가 로컬 구성 파일을 선호했습니다. 이 우선 순위 순서는 스캔이 알려지고 신뢰할 수 있는 규칙 집합을 사용하도록 보장하기가 어려웠습니다.

이제 새로운 CI/CD 변수인 `SECURE_ENABLE_LOCAL_CONFIGURATION`을(를) 추가하여 로컬 구성 파일 허용 여부를 제어합니다. 기본값은 `true`이며 기존 동작을 유지합니다. 로컬 구성 파일이 허용되고 공유 구성보다 선호됩니다. [검사 실행을 적용](../../user/application_security/policies/scan_execution_policies.md)할 때 값을 `false`으로 설정하면 프로젝트 개발자가 로컬 구성 파일을 추가하더라도 스캔이 공유 규칙 집합 또는 기본 규칙 집합을 사용하도록 할 수 있습니다.

### 작업 이름별로 작업 필터링 {#filter-jobs-by-job-name}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/387547)

{{< /details >}}

이제 작업 이름을 검색하여 특정 작업을 빠르게 찾을 수 있습니다.

이전에는 상태별로만 작업 목록을 필터링할 수 있었으므로 특정 작업을 찾기 위해 수동으로 스크롤해야 했습니다. 이 릴리스에서는 이제 작업 이름을 입력하여 결과를 필터링할 수 있습니다. 결과에는 GitLab 17.3 릴리스 후 실행된 파이프라인의 작업만 포함됩니다.

### 머지 트레인 시각화 {#merge-train-visualization}

<!-- categories: Merge Trains -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/pipelines/merge_trains.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13705)

{{< /details >}}

이제 머지 트레인을 시각화하여 파이프라인의 머지 리퀘스트 상태 및 순서에 대한 더 나은 통찰력을 얻을 수 있습니다. 머지 트레인 시각화를 사용하면 충돌을 더 일찍 식별하고, 머지 트레인에서 직접 머지 리퀘스트에 대해 작업을 수행하며, 기본 브랜치를 깨뜨릴 위험을 최소화할 수 있습니다.

### GitLab 러너 17.3 {#gitlab-runner-173}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 17.3을 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 경량의 확장성 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [Kubernetes 러너에서 취소되면 작업이 정지된 것으로 보임](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37780)
- [지정되지 않으면 로그 레벨이 업데이트되지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37490)
- [러너 Kubernetes 실행기 사용 시 작업 로그에서 추가 줄 바꿈 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27099)

모든 변경 사항 목록은 GitLab 러너 [변경 로그](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-3-stable/CHANGELOG.md)를 참조하세요.

### macOS의 호스팅된 러너 성능 개선 {#improved-performance-for-hosted-runners-on-macos}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/macos.md) \| [관련 이슈](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/issues/6)

{{< /details >}}

macOS 14.5 및 Xcode 15.4로 최근 업그레이드하면서 성능 개선 사항을 제공했습니다. 이 변경으로 Xcode 빌드 작업은 이전 작업 실행에 비해 훨씬 빠릅니다.

### CI/CD 카탈로그 구성 요소 입력 세부 정보에 설명 및 유형 추가 {#description-and-type-added-to-cicd-catalog-component-input-details}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/components/_index.md#cicd-catalog) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/426870)

{{< /details >}}

카탈로그의 CI/CD 구성 요소에 대한 세부 정보 페이지는 구성 요소에 대한 유용한 정보를 제공합니다. 이 릴리스에서 사용 가능한 입력에 대한 정보를 표시하는 테이블에 두 개의 새로운 열을 추가했습니다. 새 **설명** 및 **유형** 열은 입력이 사용되는 용도와 예상되는 값의 유형을 더 쉽게 이해할 수 있게 합니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.3)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
