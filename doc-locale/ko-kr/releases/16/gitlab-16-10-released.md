---
stage: Release Notes
group: Monthly Release
date: 2024-03-21
title: "GitLab 16.10 릴리스 정보"
description: "GitLab 16.10이 CI/CD 카탈로그의 시멘틱 버전 관리와 함께 릴리스되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 3월 21일에 GitLab 16.10이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

[Lennard Sprong](https://gitlab.com/X_Sheep)은 이전에 15.4에서 GitLab MVP 상을 수상했으며 16.9에서도 지명되었습니다. 그는 GitLab Workflow for VS Code에 계속 기여하고 있으며 지난 두 달 동안 8개의 기여를 병합했습니다. 그의 과거 기여 중 일부에는 [실행 중인 CI 작업의 추적 보기](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/674), [다운스트림 파이프라인 보기](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1336), [머지 리퀘스트에서 이미지 비교](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319) 기능이 포함됩니다. Lennard는 또한 [GitLab-vscode-extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension) 프로젝트 내의 이슈에 적극적으로 참여하고 있습니다.

GitLab의 직원 엔지니어인 [Erran Carey](https://gitlab.com/erran)는 Lennard를 지명했으며 "Lennard가 GitLab Community Edition 사용자에게 영향을 주는 [파이프라인 보기 이슈](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1000)를 해결했습니다. 그는 영향을 받은 사용자에게 기존 해결 방법을 안내한 후 이 이슈를 해결하기 위해 [머지 리퀘스트를 생성](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1417)했습니다."

GitLab의 직원 엔지니어인 [Tomas Vik](https://gitlab.com/viktomas)는 추가로 Lennard를 지원했으며 [이미지 diff 지원 추가](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319)에 대한 기여를 강조했습니다. 이를 통해 사람들은 머지 리퀘스트 검토 중에 이미지 변경 사항을 볼 수 있습니다.

[Marco Zille](https://gitlab.com/zillemarco)은 두 번째 GitLab MVP 상을 수상했으며, 이전에 15.3에서 수상했습니다. Marco는 이번 릴리스의 코드 기여뿐만 아니라 GitLab의 광범위한 기여자 커뮤니티를 지원하고, 커뮤니티 페어링 세션을 운영하고, GitLab 팀원들과 협업하며, 머지 리퀘스트를 검토하는 지속적인 노력으로 인정받았습니다.

Marco는 [하나의 작업이 실패한 직후 파이프라인을 즉시 취소](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)하는 기능을 추가했습니다. 이 기능은 GitLab.com에서 활성화되어 있고 사용 가능하지만 자체 호스팅 인스턴스의 경우 아직 기능 플래그 뒤에 있습니다. 이 기능은 16.11에서 모든 사람을 위해 사용 가능하게 될 것입니다.

GitLab의 선임 백엔드 엔지니어인 [Allison Browne](https://gitlab.com/allison.browne)은 파이프라인 실행에서 이 오래되고 매우 요청된 기능을 처리한 Marco를 지명했습니다. GitLab의 주요 엔지니어인 [Fabio Pitino](https://gitlab.com/fabiopitino)는 "Marco는 수정 사항을 구현했을 뿐만 아니라 기능 설계에 중요한 역할을 했으며, 사용 사례를 제시하고 기능에 관심 있는 고객들과 이에 대해 논의했습니다."라고 덧붙였습니다.

[Peter Leitzen](https://gitlab.com/splattael)은 추가로 Marco의 지명을 지지했으며 Marco가 Sentry에서 스택 추적을 로딩하기 위한 [수정 검토 후 완료](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112813#note_1737719869)하는 데 어떻게 도움을 주었는지 강조했습니다.

GitLab을 개선하고 오픈 소스 커뮤니티를 지원하기 위한 Lennard와 Marco의 지속적인 지원에 매우 감사드립니다! 🙌

## 주요 기능 {#primary-features}

### CI/CD 카탈로그의 시멘틱 버전 관리 {#semantic-versioning-in-the-cicd-catalog}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/components/_index.md#component-versions) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/442238)

{{< /details >}}

일관된 동작을 강제하기 위해 GitLab 16.10에서는 CI/CD 카탈로그에 게시되는 컴포넌트에 대해 시멘틱 버전 관리를 강제합니다. 컴포넌트를 게시할 때 태그는 3자리 시멘틱 버전 관리 표준을 따라야 합니다(예: `1.0.0`).

`include: component` 구문으로 컴포넌트를 사용할 때는 게시된 시멘틱 버전을 사용해야 합니다. `~latest`를 사용하는 것은 계속 지원되지만 항상 최신 게시 버전을 반환하므로 주요 변경 사항이 포함될 수 있으므로 주의하여 사용해야 합니다. 단축 구문은 지원되지 않지만 향후 마일스톤에서 지원될 예정입니다.

### GitLab Duo 액세스 거버넌스 제어 {#gitlab-duo-access-governance-control}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/gitlab_duo/turn_on_off.md)

{{< /details >}}

생성형 AI는 업무 프로세스를 혁신하고 있으며, 이제 개인 정보 보호, 규정 준수 또는 지적 재산(IP) 보호를 훼손하지 않으면서 이러한 기술의 채택을 촉진할 수 있습니다.

이제 API를 사용하여 프로젝트, 그룹 또는 인스턴스에 대해 GitLab Duo AI 기능을 비활성화할 수 있습니다. 그 후 준비가 되면 특정 프로젝트 또는 그룹에 대해 GitLab Duo를 활성화할 수 있습니다. 이러한 변경 사항은 AI 기능을 더 세밀하게 제어할 수 있도록 하기 위한 일련의 예상 작업의 일부입니다.

### Wiki 템플릿 {#wiki-templates}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md#wiki-page-templates) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/16608)

{{< /details >}}

이 버전의 GitLab은 Wiki에 완전히 새로운 템플릿을 소개합니다. 이제 새 페이지 생성이나 기존 페이지 수정을 간소화하기 위한 템플릿을 생성할 수 있습니다. 템플릿은 Wiki 리포지토리의 템플릿 디렉터리에 저장된 Wiki 페이지입니다.

이 개선 사항을 통해 Wiki 페이지 레이아웃을 더 일관되게 만들고, 페이지를 더 빠르게 생성하거나 재구성하며, 정보가 지식 기반에 명확하고 일관되게 표시되도록 할 수 있습니다.

### 고성능 DevOps 분석을 위한 새로운 ClickHouse 통합 {#new-clickhouse-integration-for-high-performance-devops-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/group/contribution_analytics/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428260)

{{< /details >}}

[Contribution Analytics 보고서](../../user/group/contribution_analytics/_index.md)는 이제 더 성능이 우수하며 GitLab.com에서 ClickHouse를 사용하는 고급 분석 데이터베이스로 지원됩니다. 이 업그레이드는 새로운 광범위한 분석 및 보고 기능의 기초를 마련했으며, 여러 차원에 걸쳐 고성능 분석 집계, 필터링 및 슬라이싱을 제공할 수 있습니다. 자체 관리 고객이 이 기능을 추가할 수 있도록 하는 지원은 [이슈 441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626)에서 제안되고 있습니다.

ClickHouse가 GitLab의 분석 기능을 향상시키지만 PostgreSQL이나 Redis를 대체하려는 것이 아니며, 기존 기능은 변경되지 않습니다.

### GitLab Pages 및 고급 검색이 GitLab Dedicated에서 사용 가능 {#gitlab-pages-and-advanced-search-available-on-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- 티어: Gold
- 링크: [문서](../../subscriptions/gitlab_dedicated/_index.md#available-features) \| [관련 이슈](https://about.gitlab.com/dedicated/)

{{< /details >}}

[GitLab Pages](../../user/project/pages/_index.md) 및 [고급 검색](../../user/search/advanced_search.md)이 모든 [GitLab Dedicated 인스턴스](https://about.gitlab.com/dedicated/)에서 활성화되었습니다. 이 기능들은 GitLab Dedicated 구독에 포함되어 있습니다.

고급 검색을 통해 전체 GitLab Dedicated 인스턴스에서 더 빠르고 효율적인 검색을 수행할 수 있습니다. 고급 검색의 모든 기능을 GitLab Dedicated 인스턴스와 함께 사용할 수 있습니다.

GitLab Pages를 사용하면 GitLab Dedicated의 리포지토리에서 직접 정적 웹 사이트를 게시할 수 있습니다. Pages의 일부 기능은 GitLab Dedicated 인스턴스에서 [아직 사용할 수 없습니다](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages).

### CI 트래픽을 Geo 보조 사이트로 오프로드 {#offload-ci-traffic-to-geo-secondaries}

<!-- categories: Geo Replication -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/geo/secondary_proxy/runners.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9779)

{{< /details >}}

이제 CI 러너 트래픽을 Geo 보조 사이트로 오프로드할 수 있습니다. 지역 간 트래픽을 줄이면서 러너 플릿을 운영하고 관리하기에 더 편리하고 경제적인 위치에 배치합니다. 여러 보조 Geo 사이트에 걸쳐 부하를 분산합니다. 주 사이트의 부하를 줄이고 개발자 트래픽 서빙을 위한 리소스를 예약합니다. 이 설정 후 개발자 경험은 투명하고 seamless합니다. 작업의 설정 및 구성을 위한 개발자 워크플로우는 변경되지 않습니다.

## 규모 및 배포 {#scale-and-deployments}

### GitLab 차트 개선 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/charts/)

{{< /details >}}

GitLab 16.10에서는 Kubernetes 1.24 이상에서의 GitLab 설치 지원을 제거했습니다. Kubernetes 1.24의 Kubernetes 유지 관리 지원은 2023년 7월에 종료되었습니다.

GitLab 16.10은 Kubernetes 1.27에서의 GitLab 설치 지원을 포함합니다. 자세한 내용은 새로운 [Kubernetes 버전 지원 정책](https://handbook.gitlab.com/handbook/engineering/careers/matrix/infrastructure/core-platform/distribution/)을 참조하세요. 우리의 목표는 공식 릴리스에 더 가까운 시간에 더 새로운 버전의 Kubernetes를 지원하는 것입니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 16.10은 Patroni의 새로운 주요 버전인 버전 3.0.1을 도입합니다. 이 버전 업그레이드에는 다운타임이 필요합니다. 자세한 내용 및 지침은 [GitLab 16 변경 페이지의 16.10 섹션](../../update/versions/gitlab_16_changes.md#16100)을 참조하세요.

GitLab 16.10은 또한 새로운 버전의 Alertmanager, 즉 버전 0.27을 포함합니다. 특히 이 버전에는 API v1의 제거가 포함됩니다. 이 릴리스에 대한 자세한 내용은 [Alertmanager 변경 로그](https://github.com/prometheus/alertmanager/blob/v0.27.0/CHANGELOG.md#0270--2024-02-28)를 참조하세요.

GitLab 16.10은 또한 [Mattermost 9.5](https://docs.mattermost.com/deploy/mattermost-changelog.html#release-v9-5-extended-support-release)를 포함합니다. Mattermost 9.5에는 다양한 보안 업데이트와 MySQL 5.7에 대한 지원 중단이 포함됩니다. 이 버전의 MySQL을 사용 중인 사용자는 업데이트해야 합니다.

### GraphQL API로 엔터프라이즈 사용자별로 멤버 필터링 {#filter-members-by-enterprise-users-with-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../api/graphql/reference/_index.md#groupgroupmembers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/356062)

{{< /details >}}

GraphQL API를 사용하면 엔터프라이즈 사용자별로 그룹 멤버를 필터링할 수 있습니다.

### 차단된 사용자는 팔로워 목록에서 제외됩니다 {#blocked-users-are-excluded-from-the-followers-list}

<!-- categories: User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#follow-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/441774)

{{< /details >}}

이전에는 당신을 팔로우한 사용자가 차단되었을 때 사용자 프로필의 팔로워 목록에 여전히 나타났습니다. GitLab 16.10부터는 차단된 사용자가 팔로워 목록에서 숨겨집니다. 사용자가 차단 해제되면 팔로워 목록에 다시 나타납니다.

이 커뮤니티 기여를 위해 @SethFalco에게 감사합니다!

### REST API에서 표시 여부별로 그룹 필터링 {#filter-groups-by-visibility-in-the-rest-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/groups.md#list-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/429314)

{{< /details >}}

[Groups API](../../api/groups.md)에서 표시 여부별로 그룹을 필터링할 수 있습니다. 필터링을 사용하여 특정 표시 여부 수준의 그룹에 집중할 수 있으므로 GitLab 구현을 더 쉽게 감시할 수 있습니다.

이 커뮤니티 기여를 위해 @imskr에게 감사합니다!

### 업데이트된 프로젝트 삭제 기능 {#updated-project-deletion-functionality}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/working_with_projects.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/443682)

{{< /details >}}

이제 프로젝트 목록에서 삭제된 프로젝트를 더 쉽게 식별할 수 있습니다. GitLab 16.10부터는 삭제된 프로젝트가 프로젝트 개요 페이지의 프로젝트 제목 옆에 `Pending deletion` 배지를 표시합니다. 경고 메시지는 삭제된 프로젝트가 읽기 전용임을 명확히 합니다. 이 메시지는 삭제된 프로젝트의 하위 페이지에서 작업할 때에도 이 컨텍스트가 손실되지 않도록 모든 프로젝트 페이지에서 볼 수 있습니다.

### Google Chat에서 지원되는 스레드 알림 {#threaded-notifications-supported-in-google-chat}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/hangouts_chat.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438452)

{{< /details >}}

이전에는 GitLab에서 Google Chat의 공간으로 전송된 알림을 지정된 스레드에 대한 응답으로 생성할 수 없었습니다. 이 릴리스를 통해 스레드 알림이 동일한 GitLab 객체(예: 이슈 또는 머지 리퀘스트)에 대해 Google Chat에서 기본적으로 활성화됩니다.

[Robbie Demuth](https://gitlab.com/robbie-demuth)에게 [이 커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145187)를 감사드립니다!

### 웹후크를 위한 사용자 정의 페이로드 템플릿 {#custom-payload-template-for-webhooks}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhooks.md#custom-webhook-template) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/362504)

{{< /details >}}

이전에는 GitLab 웹후크가 특정 JSON 페이로드만 전송할 수 있었으므로 수신 끝점이 웹후크 형식을 이해해야 했습니다. 이러한 웹후크를 사용하려면 GitLab을 특별히 지원하는 앱을 사용하거나 자체 끝점을 작성해야 했습니다.

이 릴리스를 통해 웹후크 구성에서 사용자 정의 페이로드 템플릿을 설정할 수 있습니다. 요청 본문은 현재 이벤트의 데이터로 템플릿에서 렌더링됩니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738)를 주신 [Niklas](https://gitlab.com/Taucher2003)에게 감사합니다!

### UI 및 API에서 Service Desk 티켓 생성 {#create-service-desk-tickets-from-the-ui-and-api}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/service_desk/using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)

{{< /details >}}

이제 `/convert_to_ticket user@example.com` 빠른 작업을 사용하여 UI 및 API에서 Service Desk 티켓을 생성할 수 있습니다.

정기적인 이슈를 생성하고 `/convert_to_ticket user@example.com` 빠른 작업으로 설명을 추가합니다. 제공된 이메일 주소는 티켓의 외부 작성자가 됩니다. GitLab은 [기본 감사의 말 이메일](../../user/project/service_desk/configure.md)을 보내지 않습니다. 티켓에 공개 설명을 추가하여 외부 참여자에게 티켓이 생성되었음을 알릴 수 있습니다.

API를 사용하여 Service Desk 티켓을 추가하는 것은 동일한 개념을 따릅니다: [Issues API](../../api/issues.md)를 사용하여 이슈를 생성하고 `issue_iid`를 사용하여 [Notes API](../../api/notes.md)를 사용한 빠른 작업으로 메모를 추가합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 머지 리퀘스트에서 자동으로 생성된 파일 축소 {#automatically-collapse-generated-files-in-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/changes.md#collapse-generated-files)

{{< /details >}}

머지 리퀘스트는 사용자 및 자동화 프로세스 또는 컴파일러의 변경 사항을 포함할 수 있습니다. `package-lock.json`, `Gopkg.lock`, 축소된 `js` 및 `css` 파일과 같은 파일은 머지 리퀘스트 검토에 표시되는 파일 수를 증가시키고 검토자의 주의를 사람이 생성한 변경 사항에서 멀어지게 합니다. 머지 리퀘스트는 이제 이러한 파일을 기본적으로 축소하여 표시하여 다음을 돕습니다:

- 중요한 변경 사항에 검토자의 주의를 집중시키지만 원하는 경우 전체 검토를 활성화합니다.
- 머지 리퀘스트를 로드하는 데 필요한 데이터 양을 줄입니다. 이는 더 큰 머지 리퀘스트의 성능을 향상시킬 수 있습니다.

기본적으로 축소되는 파일 유형의 예를 보려면 [문서](../../user/project/merge_requests/changes.md#collapse-generated-files)를 참조하세요. 머지 리퀘스트에서 더 많은 파일 및 파일 유형을 축소하려면 프로젝트의 `.gitattributes` 파일에서 `gitlab-generated`로 지정합니다.

이 변경 사항에 대한 피드백을 [이슈 438727](https://gitlab.com/gitlab-org/gitlab/-/issues/438727)에 남길 수 있습니다.

### 머지 위젯의 확장된 검사 {#expanded-checks-in-merge-widget}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

머지 위젯은 머지 리퀘스트를 병합할 수 없는 경우와 그 이유를 명확히 설명합니다. 이전에는 한 번에 하나의 머지 차단만 표시되었습니다. 이로 인해 검토 주기가 증가했으며 더 많은 차단이 남아 있는지 알 수 없이 문제를 개별적으로 해결하도록 강요했습니다.

머지 리퀘스트를 볼 때 머지 위젯은 이제 남은 문제와 해결된 문제 모두에 대한 포괄적인 보기를 제공합니다. 이제 한 눈에 여러 차단이 존재하는지 이해하고, 한 번의 반복에서 모두 수정하며, 숨겨진 차단이 놓쳤을 가능성이 없다는 확신을 높일 수 있습니다.

### Kubernetes용 대시보드 수동 새로 고침 {#manually-refresh-the-dashboard-for-kubernetes}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/429531)

{{< /details >}}

GitLab 16.10은 Kubernetes용 대시보드에 전용 새로 고침 기능을 추가합니다. 이제 Kubernetes 리소스 데이터를 수동으로 가져오고 클러스터에 대한 최신 정보에 액세스할 수 있는지 확인할 수 있습니다.

### 개선된 환경 세부 정보 페이지 {#improved-environment-details-page}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431746)

{{< /details >}}

환경 세부 정보 페이지는 GitLab 16.10에서 개선되었습니다. 환경 목록에서 환경을 선택하면 배포 및 연결된 Kubernetes 클러스터에 대한 최신 정보를 한 곳의 편리한 레이아웃으로 검토할 수 있습니다.

### 인증 속도 제한에 대한 개선된 오류 메시지 {#improved-error-message-for-authentication-rate-limit}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/22787)

{{< /details >}}

GitLab을 사용하여 인증할 때 스크립트를 사용할 때처럼 인증 시도 속도 제한에 도달할 수 있습니다. 이전에 인증 속도 제한에 도달하면 `403 Forbidden` 메시지가 반환되었으므로 이 오류가 발생한 이유를 설명하지 않았습니다. 이제 인증 속도 제한에 도달했음을 알려주는 더 설명적인 오류 메시지를 반환합니다.

### 감사 이벤트 `scope` 속성 {#audit-event-scope-attribute}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

감사 이벤트는 이제 이벤트가 전체 인스턴스, 그룹, 프로젝트 또는 사용자와 연결되어 있는지를 나타내는 `scope` 속성을 포함합니다.

이 새로운 속성은 사용자가 감사 이벤트 페이로드에서 이벤트가 시작된 위치를 결정하는 데 도움이 됩니다. 또한 [감사 이벤트 유형 문서](../../administration/compliance/audit_event_reports.md)에서 감사 이벤트 유형에 대해 사용 가능한 모든 범위를 나열할 수 있습니다.

이 새로운 속성을 사용하여 외부 스트리밍 대상을 통해 구문 분석하거나 이벤트 주위의 컨텍스트를 더 잘 이해할 수 있습니다.

### 서비스 계정의 사용자 정의 이름 {#custom-names-for-service-accounts}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/service_accounts.md#create-a-service-account) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415973)

{{< /details >}}

이제 서비스 계정의 사용자 이름 및 표시 이름을 사용자 정의할 수 있습니다. 이전에는 이들이 GitLab에 의해 자동 생성되었습니다. 사용자 정의 이름을 사용하면 서비스 계정의 목적을 더 쉽게 이해할 수 있고 사용자 목록의 다른 계정과 구별할 수 있습니다.

### 사용자 지정 역할 할당을 위한 감사 이벤트 {#audit-event-for-assigning-a-custom-role}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/compliance/audit_event_reports.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/427954)

{{< /details >}}

GitLab은 이제 기본 역할이든 사용자 지정 역할이든 상관없이 사용자에게 다른 역할을 할당할 때 감사 이벤트를 기록합니다. 이 이벤트는 권한 에스컬레이션의 경우 사용자 권한이 추가되거나 변경되었는지 여부를 식별하는 데 중요합니다.

### 사용자 지정 역할을 위한 새로운 권한 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

사용자 지정 역할을 생성하기 위해 이제 두 가지 새로운 권한을 선택할 수 있습니다:

- CI/CD 변수 관리
- 그룹을 삭제할 수 있는 능력

이러한 사용자 정의 권한의 릴리스를 통해 이러한 Owner 동등 권한을 가진 사용자 지정 역할을 생성하여 그룹에서 필요한 Owner의 수를 줄일 수 있습니다. 사용자 지정 역할을 사용하면 사용자가 작업을 수행하는 데 필요한 권한만을 제공하고 불필요한 권한 에스컬레이션을 줄이는 세밀한 역할을 정의할 수 있습니다.

### 스캔 결과 정책은 이제 "머지 리퀘스트 승인 정책"입니다 {#scan-result-policies-are-now-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9850)

{{< /details >}}

정책 유형의 기능을 프로젝트 설정 재정의 및 승인 요구 사항 강제 적용을 지원하도록 확장했으므로 정책 이름을 더 적절한 "머지 리퀘스트 승인 정책"으로 업데이트했습니다.

머지 리퀘스트 승인 정책은 기존 머지 리퀘스트 승인 규칙을 대체하거나 충돌하지 않습니다. 대신 이들은 Ultimate 티어 고객에게 중앙 보안 및 규정 준수 팀이 관리하는 정책을 통해 프로젝트 전체에 걸쳐 전역 강제를 만드는 기능을 제공합니다. 이는 대규모 조직에서 점점 더 어려운 작업입니다.

### 웹후크는 상호 TLS를 지원합니다 {#webhooks-support-mutual-tls}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhooks.md#configure-webhooks-to-support-mutual-tls) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/27450)

{{< /details >}}

이제 웹후크를 구성하여 상호 TLS를 지원할 수 있습니다. 이 구성은 웹후크 소스의 진정성을 확립하고 보안을 강화합니다. TLS 핸드셰이크 중에 서버에 제시되는 PEM 형식의 클라이언트 인증서를 구성합니다. PEM 암호로 인증서를 보호할 수도 있습니다.

### 로그인 페이지 개선 사항 {#sign-in-page-improvements}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](https://gitlab.com/gitlab-org/gitlab/-/issues/412845) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/412845)

{{< /details >}}

GitLab 로그인 페이지는 간격 문제, 끊어진 요소 및 정렬을 해결하는 개선 사항으로 새로워졌습니다. 어두운 모드에 대한 추가 지원과 쿠키 선호도를 관리하는 버튼도 있습니다. 이러한 개선 사항의 조합은 로그인 페이지에 신선한 모양과 개선된 기능을 제공합니다.

### Active Directory LDAP에 대한 스마트 카드 지원 {#smart-card-support-for-active-directory-ldap}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/auth/smartcard.md#authentication-against-an-active-directory-ldap-server) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)

{{< /details >}}

LDAP 서버에 대한 스마트 카드 인증은 이제 Entra ID(이전에는 Azure Active Directory로 알려짐)를 지원합니다. 이를 통해 Entra ID에서 사용자 ID 데이터를 동기화하고 스마트 카드로 LDAP에 대해 인증하기가 쉬워집니다.

### 머지 요청 승인 정책 비교를 위해 병합 베이스 파이프라인 사용 {#use-merge-base-pipeline-for-merge-request-approval-policy-comparison}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/merge_request_approval_policies.md#understanding-merge-request-approval-policy-approvals) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)

{{< /details >}}

이 개선 사항은 머지 리퀘스트 승인 정책 평가의 논리를 보안 MR 위젯과 정렬하여 머지 리퀘스트 승인 정책을 위반하는 발견 사항이 위젯에 표시된 결과와 일치하도록 합니다. 논리를 정렬함으로써 보안, 규정 준수 및 개발 팀은 정책을 위반하고 승인이 필요한 발견 사항을 더 일관되게 식별할 수 있습니다. 대상 브랜치의 최신 완료된 `HEAD` 파이프라인과 비교하는 대신 스캔 결과 정책은 이제 일반적인 부모의 최신 완료된 파이프라인인 "병합 베이스"와 비교합니다.

### GitLab Pages에 대한 도메인 수준 리다이렉트 지원 {#support-domain-level-redirects-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/pages/redirects.md#domain-level-redirects) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601)

{{< /details >}}

이전에 GitLab은 간단한 리다이렉트 규칙 지원에 중점을 두었습니다. GitLab 14.3에서는 splat 및 자리 표시자 리다이렉트에 대한 지원을 [도입](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/458)했습니다.

GitLab 16.10부터 GitLab Pages는 도메인 수준 리다이렉트를 지원합니다. 도메인 수준 리다이렉트를 [splat 규칙](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601)과 결합하여 URL 경로를 동적으로 다시 작성할 수 있습니다. 이 개선 사항은 혼란을 방지하고 도메인 변경 후에도 이전 도메인을 사용하는 경우에도 정보를 계속 찾을 수 있도록 합니다.

### 새로운 컨테이너 레지스트리 API로 리포지토리 태그 나열 {#list-repository-tags-with-the-new-container-registry-api}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 링크: [설명서](../../api/container_registry.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10208)

{{< /details >}}

이전에 컨테이너 레지스트리는 GitLab에서 태그를 표시하기 위해 Docker/OCI [이미지 태그 나열 레지스트리 API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags)에 의존했습니다. 이 API는 상당한 성능 및 검색 용이성 제한이 있었습니다.

이 API는 레지스트리에 대한 네트워크 요청 수가 태그 목록의 태그 수에 따라 확대되기 때문에 느리게 작동했습니다. 또한 API가 게시 시간을 추적하지 않았기 때문에 게시된 타임스탐프는 종종 잘못되었습니다. Docker 매니페스트 목록이나 OCI 인덱스(예: 다중 아키텍처 이미지)를 기반으로 이미지를 표시할 때도 제한이 있었습니다.

이러한 제한을 해결하기 위해 새로운 레지스트리 [리포지토리 태그 나열 API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags)를 도입했습니다. GitLab 16.10에서는 새 API로의 마이그레이션을 완료했습니다. 이제 UI를 사용하든 REST API를 사용하든 상관없이 개선된 성능, 정확한 게시 타임스탐프 및 다중 아키텍처 이미지에 대한 강력한 지원을 기대할 수 있습니다.

이 개선 사항은 GitLab.com에서만 사용 가능합니다. 자체 관리 지원은 다음 세대 컨테이너 레지스트리가 일반적으로 사용 가능해질 때까지 차단됩니다. 자세히 알아보려면 [이슈 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)를 참조하세요.

### Value Streams Dashboard의 새로운 기여자 수 메트릭 {#new-contributor-count-metric-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/analytics/value_streams_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/433353)

{{< /details >}}

소프트웨어 리더가 팀 속도, 소프트웨어 안정성, 보안 노출 및 팀 생산성 간의 관계에 대한 통찰력을 얻을 수 있도록 하기 위해 Value Streams Dashboard의 새로운 [**기여자 수** 메트릭](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)을 도입했습니다. 기여자 수는 그룹의 기여가 있는 월간 고유 사용자 수를 나타냅니다. 이 메트릭은 시간에 따른 채택 추세를 추적하도록 설계되었으며 [기여 달력 이벤트](../../user/profile/contributions_calendar.md#user-contribution-events)를 기반으로 합니다.

**기여자 수** 메트릭은 GitLab.com에서만 사용 가능하며 [ClickHouse를 통해 실행되도록 구성된 기여 분석 보고서](../../user/group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse)가 필요합니다. [이슈 441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626)은 이 기능을 자체 관리 고객에게도 사용 가능하도록 하려는 노력을 추적합니다.

### seamless하고 정확한 워크플로우 분석을 위한 Value Stream Analytics의 상속된 필터 {#inherited-filters-in-value-stream-analytics-for-seamless-and-accurate-workflow-analysis}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/issues_analytics/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/439615)

{{< /details >}}

[Value stream analytics](../../user/group/value_stream_analytics/_index.md)는 이제 **리드 타임** 타일에서 [**이슈 분석** 보고서](../../user/group/issues_analytics/_index.md)로 드릴다운할 때 동일한 필터를 적용합니다. 필터 상속은 분석 보기 간에 전환하면서 데이터를 더 깊게 그리고 seamlessly 살펴볼 수 있도록 도와줍니다.

### 빠른 작업으로 현재 또는 다음 반복에 이슈 추가 {#add-an-issue-to-the-current-or-next-iteration-with-a-quick-action}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/quick_actions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)

{{< /details >}}

`/iteration` 빠른 작업은 이제 `--current` 또는 `--next` 인수를 사용하여 반복 주기 참조를 허용합니다. 그룹에 단일 반복 주기가 있는 경우 `/iteration --current|next`를 사용하여 현재 또는 다음 반복에 이슈를 빠르게 할당할 수 있습니다. 그룹에 많은 반복 주기가 포함되어 있는 경우 반복 주기 이름이나 ID를 참조하여 빠른 작업에서 원하는 주기를 지정할 수 있습니다. 예를 들어, `/iteration [cadence:"<cadence name>"|<cadence ID>] --next|current`입니다.

### 컨테이너 스캔을 위해 기본적으로 사용 가능한 지속적 취약성 스캔 {#continuous-vulnerability-scanning-available-by-default-for-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/continuous_vulnerability_scanning/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

컨테이너 스캔을 위한 지속적 취약성 스캔은 이제 기본적으로 사용 가능합니다. 기본 가용성은 기능 플래그를 통해 이 기능을 선택해야 할 필요가 없습니다. 지속적 취약성 스캔의 이점에 대해 자세히 알아보려면 문서 링크를 참조하세요.

### sbt에 대한 개선된 종속성 스캔 지원 {#improved-dependency-scanning-support-for-sbt}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/390287)

{{< /details >}}

sbt를 사용하는 프로젝트의 종속성 목록을 생성하기 위해 사용하는 메커니즘을 업데이트했습니다. 이 변경 사항은 sbt 버전 1.7.2 이상을 사용하는 프로젝트에만 적용됩니다. sbt 프로젝트에 대해 종속성 스캔을 완전히 활용하려면 sbt 버전 1.7.2 이상으로 업그레이드해야 합니다.

### DAST 분석기 성능 업데이트 {#dast-analyzer-performance-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/browser/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

16.10 릴리스 마일스톤 동안 프록시 기반 DAST는:

- ZAP을 버전 2.14.0으로 업그레이드했습니다. 자세한 내용은 [이슈 442056](https://gitlab.com/gitlab-org/gitlab/-/issues/442056)을 참조하세요.

또한 다음의 브라우저 기반 DAST 크롤러 성능 개선 사항을 완료했습니다:

- 크롤링할 때 생성되는 고루틴의 수를 제한합니다. 자세한 내용은 [이슈 440151](https://gitlab.com/gitlab-org/gitlab/-/issues/440151)을 참조하세요.
- 상호 작용할 요소를 찾는 것을 최적화합니다. 이렇게 하면 스캔 시간이 6% 단축됩니다. 자세한 내용은 [이슈 440295](https://gitlab.com/gitlab-org/gitlab/-/issues/440295)를 참조하세요.
- DevTools 메시지의 JSON 언마샬링을 최적화합니다. 이렇게 하면 스캔 시간이 7% 단축됩니다. 자세한 내용은 [이슈 439726](https://gitlab.com/gitlab-org/gitlab/-/issues/439726)을 참조하세요.

### GitLab Runner 16.10 {#gitlab-runner-1610}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘도 GitLab Runner 16.10을 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

버그 수정:

- [Runner Kubernetes 실행기에서 작업이 취소될 때 메모리 누수](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27857)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-10-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.10)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
