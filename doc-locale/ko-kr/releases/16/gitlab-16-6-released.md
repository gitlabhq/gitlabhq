---
stage: Release Notes
group: Monthly Release
date: 2023-11-16
title: "GitLab 16.6 릴리스 정보"
description: "GitLab 16.6이 출시되었으며 GitLab Duo Chat이 베타로 제공됩니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 11월 16일에 GitLab 16.6이 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Joe Snyder {#this-months-notable-contributor-joe-snyder}

Joe Snyder는 GitLab 전반에 걸친 일관된 기여로 GitLab의 16.6 MVP로 선정되었으며, [관리자가 버전별로 러너를 필터링할 수 있도록 허용](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135025)하는 최근 머지 리퀘스트가 포함되어 있습니다.

Joe는 GitLab의 선임 프론트엔드 엔지니어인 [Miguel Rincon](https://gitlab.com/mrincon)에 의해 지명되었습니다. Miguel은 GitLab의 진화하는 아키텍처로 인한 여러 필수 재작성을 통해 Joe의 노력을 인정했으며, Joe의 "성능 및 사용성에 대한 신중한 고려"에 대해 언급했습니다.

GitLab의 선임 백엔드 엔지니어인 [Pedro Pombeiro](https://gitlab.com/pedropombeiro)는 "Joe Snyder는 이전 동료로부터 인수한 후 문제에 대한 모든 맥락을 학습해야 하면서 이 변경을 결승선을 넘겼습니다. 그는 또한 연속적인 리뷰에서 당사의 피드백에 매우 반응성 있고 인내심 있게 대응했습니다."라고 덧붙였습니다.

GitLab의 선임 백엔드 엔지니어인 [Terri Chu](https://gitlab.com/terrichu)는 "Joe는 함께 일하기 정말 좋은 사람이었습니다"라고 말했습니다. Terri는 지난 마일스톤(및 이전 마일스톤) 동안 [`emails_enabled` 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)에 대한 Joe의 진행 중인 작업을 강조했습니다.

Joe Snyder는 [Kitware](https://www.kitware.com/)의 선임 R&D 엔지니어이며 2021년부터 GitLab에 기여해 왔습니다. GitLab을 지속적으로 개선하기 위해 노고를 아끼지 않은 Joe에게 많은 감사를 드립니다!

## 주요 기능 {#primary-features}

### GitLab Duo Chat이 베타로 제공됨 {#gitlab-duo-chat-available-in-beta}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10550)

{{< /details >}}

소프트웨어 개발 프로세스에 관여하는 모든 사람들은 코드, 에픽, 이슈, 그리고 긴 논의 스레드에 익숙해지는 데 상당한 시간을 소비할 수 있습니다. 요약, 문서, 테스트 또는 코드 작성과 같은 일상적인 작업으로 인해 속도가 느려질 수 있습니다. 판단 없이 DevSecOps 질문에 답하고 후속 조치를 처리할 수 있는 전문가가 옆에 있으면 소프트웨어 개발 프로세스를 가속화하는 데 도움이 될 수 있습니다.

GitLab Duo Chat은 이러한 문제점들을 적극적으로 해결하고 워크플로우를 가속화하는 것을 목표로 합니다. 해당 기능은 다음을 포함합니다:

- 이슈, 에픽 및 코드를 설명하거나 요약합니다.
- "이 이슈에서 제안된 솔루션과 관련하여 댓글에서 제기된 모든 논거를 수집하세요"와 같은 이러한 아티팩트에 대한 구체적인 질문에 답변합니다.
- 이러한 아티팩트의 정보를 기반으로 코드 또는 콘텐츠를 생성합니다. 예를 들어, "이 코드에 대한 문서를 작성할 수 있습니까?"라고 물어볼 수 있습니다.
- 또는 "GitLab CI/CD 에서 Ruby on Rails 애플리케이션을 테스트하고 구축하기 위한 .GitLab-ci.yml 구성 파일을 만듭니다"처럼 처음부터 시작하도록 도와줍니다.
- 초보자이든 전문가이든 모든 DevSecOps 관련 질문에 답합니다. 예를 들어 "REST API에 대한 Dynamic Application Security Testing을 설정하려면 어떻게 해야 하나요?"
- 후속 질문에 답하여 위의 모든 시나리오를 반복적으로 진행할 수 있습니다.

GitLab Duo Chat은 GitLab.com에서 베타 기능으로 제공됩니다. VS Code용 Web IDE 및 GitLab Workflow 확장에도 실험 기능으로 통합되어 있습니다.

제품 내에서 또는 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)를 통해 Duo Chat 경험에 대한 피드백을 제공하여 이러한 기능을 개선하는 데 도움을 주실 수 있습니다.

### 엔터프라이즈 사용자의 자동 청구 {#automatic-claims-of-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/enterprise_user/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9675)

{{< /details >}}

GitLab.com 사용자의 기본 이메일 주소가 기존의 검증된 도메인과 일치하면 사용자가 엔터프라이즈 사용자로 자동 청구됩니다. 이것은 그룹 Owner에게 더 많은 사용자 관리 제어 권한과 사용자 계정에 대한 가시성을 제공합니다. 사용자가 엔터프라이즈 사용자가 된 후 기본 이메일을 자신의 조직이 소유한 이메일로만 변경할 수 있으며, 이는 검증된 도메인에 따릅니다.

### 최소 포킹 - 기본 브랜치만 포함 {#minimal-forking---only-include-the-default-branch}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/forking_workflow.md#create-a-fork)

{{< /details >}}

GitLab의 이전 버전에서는 리포지토리를 포크할 때 포크에는 항상 리포지토리 내의 모든 브랜치가 포함되었습니다. 이제 기본 브랜치만 포함하는 포크를 만들어 복잡성과 스토리지 공간을 줄일 수 있습니다. 다른 브랜치에서 현재 진행 중인 변경 사항이 필요하지 않으면 최소 포크를 만듭니다.

포킹의 기본 방법은 변경되지 않으며 리포지토리 내의 모든 브랜치를 계속 포함합니다. 새로운 옵션은 어느 브랜치가 기본인지 표시하므로 새 포크에 정확히 어떤 브랜치가 포함될지 알 수 있습니다.

### 사용자가 머지 리퀘스트 승인을 컴플라이언스 정책으로 적용하도록 허용 {#allow-users-to-enforce-mr-approvals-as-a-compliance-policy}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#any_merge_request-rule-type) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9696)

{{< /details >}}

프로덕션 애플리케이션에 도입될 수 있는 코드 변경 사항에 대한 조사가 증가하고 있으며, 이는 기업이 컴플라이언스 위험 및 보안 취약성에 노출될 수 있습니다. 스캔 결과 정책을 사용하면 모든 머지 리퀘스트에 대해 2명의 승인을 적용하여 일방적인 변경을 할 수 없도록 할 수 있습니다.

스캔 결과 정책에는 `Any merge request`을 대상으로 하는 새로운 옵션이 있으며, 이를 [역할 기반 승인자](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) 정의와 함께 사용하여 정의된 브랜치에 대한 각 머지 리퀘스트가 지정된 역할(Owner, Maintainer 또는 Developer)을 가진 2명 이상의 사용자로부터 승인을 요구하도록 할 수 있습니다.

SaaS에서 16.6으로 사용 가능합니다. 기능 플래그 `scan_result_any_merge_request` 뒤의 Self-managed에서 사용 가능하며 16.7에서 기본적으로 활성화됩니다.

### GitLab Dedicated용 Switchboard 포털이 이제 일반적으로 출시됨 {#switchboard-portal-for-gitlab-dedicated-is-now-generally-available}

<!-- categories: Switchboard, GitLab Dedicated -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/dedicated/_index.md) \| [관련 이슈](https://about.gitlab.com/dedicated/)

{{< /details >}}

새로운 셀프서비스 포털인 Switchboard는 이제 고객 및 팀 멤버가 [GitLab Dedicated](https://about.gitlab.com/dedicated/) 인스턴스를 온보드, 구성 및 유지할 수 있도록 제공됩니다.

Switchboard를 사용하면 이제 GitLab Dedicated 인스턴스에 [구성 변경](../../administration/dedicated/_index.md)을 적용할 수 있습니다. 이 기능은 향후 릴리스에서 확장될 예정입니다.

### CI/CD 구성 요소 베타 릴리스 {#cicd-components-beta-release}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/components/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/9897)

{{< /details >}}

GitLab 16.1에서 [발표](https://about.gitlab.com/blog/introducing-ci-components/)한 CI/CD 구성 요소라는 흥미로운 실험적 기능의 릴리스입니다. 은 CI/CD 카탈로그에 나열될 수 있는 구성 블록입니다.

오늘 우리는 CI/CD 구성 요소의 베타 가용성을 발표하게 되어 기쁩니다. 이 릴리스를 통해 초기 실험 버전의 구성 요소 폴더 구조도 개선했습니다. CI/CD 구성 요소의 실험 버전을 이미 테스트 중이라면 [새로운 폴더 구조](../../ci/components/_index.md#directory-structure)로 마이그레이션하는 것이 필수입니다. [여기](https://gitlab.com/gitlab-components/)에서 몇 가지 예를 볼 수 있습니다. 이전 폴더 구조는 더 이상 사용되지 않으며 향후 몇 개의 릴리스 내에 제거할 예정입니다.

CI/CD 구성 요소를 시도해보는 경우 현재 실험적 기능으로 제공되는 새로운 CI/CD 카탈로그도 시도해보시기 바랍니다. [글로벌 CI/CD 카탈로그](../../ci/components/_index.md)에서 다른 사람들이 만들고 공개용으로 게시한 구성 요소를 검색할 수 있습니다. 또한 자신의 구성 요소를 만든 경우 카탈로그에 게시하도록 선택할 수 있습니다!

### CI/CD 변수 관리를 위한 개선된 UI {#improved-ui-for-cicd-variable-management}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/418005)

{{< /details >}}

는 GitLab CI/CD의 기본 부분이며, 설정 UI에서 변수로 작업할 수 있는 더 나은 환경을 제공할 수 있다고 생각했습니다. 따라서 이번 릴리스에서 를 추가하고 편집하는 흐름을 개선하는 새로운 드로어를 사용하도록 UI를 업데이트했습니다.

예를 들어, 마스킹 검증은 이전에 를 저장하려고 할 때만 발생했으며, 실패한 경우 처음부터 다시 시작해야 했습니다. 하지만 이제 새로운 드로어를 사용하면 실시간 검증을 받을 수 있으므로 다시 수행할 필요 없이 움직이면서 조정할 수 있습니다!

이 변경에 대한 [피드백](https://gitlab.com/gitlab-org/gitlab/-/issues/428807)은 항상 소중하게 여겨집니다.

### 러너 플릿 대시보드 - 시작 메트릭 (베타) {#runner-fleet-dashboard---starter-metrics-beta}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/runners/runner_fleet_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424495)

{{< /details >}}

Self-managed 러너 플릿의 운영자는 러너 플릿 인프라에 대한 중요한 질문에 빠르게 답할 수 있는 가시성과 능력이 필요합니다. 이제 러너 플릿 대시보드 - 관리자 보기(베타)를 사용하면 인스턴스 러너부터 시작하여 중요한 플릿 관리 및 개발자 경험 질문에 빠르게 답할 수 있는 실행 가능한 통찰력을 얻을 수 있습니다. 여기에는 어느 러너에 오류가 있는지, CI 작업 실행을 위한 러너 큐의 성능, 그리고 어느 러너가 가장 활발히 사용되는지와 같은 질문에 대한 답변이 포함됩니다. Ultimate 고객은 이 기능을 독립적으로 활성화할 수 있지만, [조기 채택자 프로그램](https://gitlab.com/groups/gitlab-org/-/epics/11180)에 참여하도록 권장됩니다.

## 규모 및 배포 {#scale-and-deployments}

### 검색 결과에서 아카이빙된 프로젝트 숨기기(기본값) {#hide-archived-projects-in-search-results-by-default}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/search/_index.md#include-archived-projects-in-search-results) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10957)

{{< /details >}}

이전에는 사용자가 프로젝트 검색 결과에서 많은 아카이빙된 프로젝트를 보았습니다. 이는 특히 아카이빙된 프로젝트가 상위 결과의 대부분을 차지했을 때 문제가 있었습니다. 이제 기본적으로 아카이빙된 프로젝트를 필터링하고, 사용자는 **아카이빙된 항목 포함**을 선택하여 모든 프로젝트를 볼 수 있습니다.

### 비공개 그룹 이름이 권한이 없는 사용자로부터 숨겨짐 {#private-group-names-are-hidden-from-unauthorized-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/manage.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415165)

{{< /details >}}

이전에는 프로젝트 또는 그룹의 멤버 페이지의 **그룹** 탭에 액세스할 때 비공개 그룹의 이름이 모든 사용자에게 표시되었습니다. 보안을 강화하기 위해 이제 공유 그룹, 공유 프로젝트 또는 초대된 그룹의 멤버가 아닌 사용자로부터 비공개 그룹의 이름과 출처를 마스킹하고 있습니다. 대신 이 정보는 **비공개**로 표시됩니다.

### 가져오기에 실패한 항목의 포괄적인 목록 {#comprehensive-list-of-items-that-failed-to-be-imported}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/386138)

{{< /details >}}

이전에 GitLab 프로젝트 및 그룹을 직접 전송으로 마이그레이션했을 때 일부 항목(머지 리퀘스트 또는 이슈)이 성공적으로 가져오지 못한 경우, [가져온 그룹 및 프로젝트를 나열하는 페이지](../../user/group/import/_index.md)에서 **상세정보** 버튼을 선택하고 해당 오류를 볼 수 있었습니다.

그러나 오류 목록은 총 몇 개의 항목이 가져오지 못했는지, 그리고 특히 어떤 항목이 가져오지 못했는지 이해하는 데 도움이 되지 않습니다. 이 정보는 가져오기 프로세스의 결과를 이해하는 데 중요합니다.

이 릴리스에서 **상세정보** 버튼을 **See failures** 링크로 바꿨습니다. **See failures** 링크를 선택하면 주어진 그룹 또는 프로젝트에 대해 가져오기에 실패한 모든 항목을 나열하는 새 페이지로 이동합니다. 가져오지 못한 각 항목에 대해 다음을 볼 수 있습니다:

- 항목의 유형입니다. 예를 들어, 머지 리퀘스트 또는 이슈.
- 발생한 오류의 종류입니다.
- 디버깅 목적으로 유용한 상관 ID입니다.
- 소스 인스턴스의 항목 URL(있는 경우 `iid`이 있는 항목)입니다.
- 소스 인스턴스의 항목 제목(있는 경우)입니다. 예를 들어, 머지 리퀘스트 제목 또는 이슈 제목입니다.

### 모든 사용자를 위한 일관된 네비게이션 경험 {#consistent-navigation-experience-for-all-users}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

16.0 릴리스는 새로운 네비게이션 경험을 도입했으며, 2023년 6월 2일부터 모든 사용자를 위한 기본값이 되었습니다. 후속 마일스톤에서는 풍부한 사용자 피드백을 기반으로 많은 개선 사항이 이루어졌습니다. 이전 네비게이션으로 돌아갈 수 있는 기능이 이제 제거되었습니다. 더 많은 흥미로운 변경 사항이 네비게이션을 위해 계획되어 있지만, 지금은 모든 사용자가 일관된 네비게이션 경험을 갖습니다.

요약하면 새로운 GitLab 네비게이션을 사용하면 다음을 수행할 수 있습니다:

- 자주 사용되는 프로젝트 또는 그룹 항목을 상단에 저장하도록 메뉴 항목 고정
- 네비게이션을 숨기고 "엿보기"하여 더 넓은 화면 노출
- 키보드 단축키를 사용하여 메뉴 항목을 쉽게 검색
- 이전 네비게이션에서 사용하던 모든 테마를 계속 사용
- DevOps 워크플로우와 일치하는 더 잘 구성된 섹션 사용

### GitLab 무음 모드 {#gitlab-silent-mode}

<!-- categories: Disaster Recovery -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/silent_mode/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9826)

{{< /details >}}

GitLab 무음 모드가 활성화되면 알림 이메일, 통합, 웹후크, 미러링 등 GitLab 인스턴스의 모든 주요 아웃바운드 트래픽을 차단합니다. 이를 통해 사용자 및 기타 통합으로의 트래픽을 생성하지 않고 GitLab 사이트에 대해 테스트를 수행할 수 있습니다. 무음 모드를 사용하여 주요 GitLab 사이트나 최종 사용자에게 영향을 주지 않으면서 복원된 백업 또는 승격된 Geo DR 사이트를 테스트할 수 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### GitLab UI에서의 실시간 Kubernetes 상태 업데이트 {#real-time-kubernetes-status-updates-in-the-gitlab-ui}

<!-- categories: Deployment Management, Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/422945)

{{< /details >}}

GitLab 16.6에서는 환경 페이지의 클러스터 UI 통합을 사용하여 GitLab을 떠나지 않고 현재 실행 중인 애플리케이션의 상태를 파악할 수 있습니다. 이전에는 UI가 로드될 때 일회성 요청으로 상태가 업데이트되어 배포 진행 상황을 추적하기가 어려웠습니다. 현재 버전의 GitLab은 기본 연결을 업그레이드하여 Flux 조정 및 Pod 상태에 대해 Kubernetes watch API를 사용하며, GitLab UI에서 클러스터 상태를 거의 실시간으로 업데이트합니다.

### GitLab CLI로 Kubernetes 클러스터에 연결 {#connect-to-kubernetes-clusters-with-the-gitlab-cli}

<!-- categories: GitLab CLI, Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11455)

{{< /details >}}

GitLab 버전 16.4부터는 Kubernetes용 에이전트 및 개인 액세스 토큰을 사용하여 로컬 터미널에서 Kubernetes 클러스터에 연결할 수 있습니다. 초기 버전에서는 로컬 클러스터 구성을 설정하려면 여러 명령과 장기 액세스 토큰이 필요했습니다. 지난 달에 GitLab CLI를 확장하여 설정 프로세스를 간소화하고 보안을 개선하기 위해 노력했습니다.

이제 GitLab CLI는 GitLab 프로젝트 체크아웃 디렉토리 또는 지정된 프로젝트에서 사용 가능한 에이전트 연결을 나열할 수 있습니다. 전용 명령을 사용하여 선택한 에이전트를 통해 연결을 설정할 수 있습니다. `kubectl` 또는 다른 도구가 클러스터로 인증해야 할 때, GitLab CLI는 로그인한 사용자를 위해 임시의 제한된 토큰을 생성합니다.

### 컴플라이언스 팀이 보호된 브랜치로의 푸시 및 강제 푸시를 방지하도록 허용 {#allow-compliance-teams-to-prevent-pushing-and-force-pushing-into-protected-branches}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9706)

{{< /details >}}

[보안 정책 컴플라이언스 적용](https://gitlab.com/groups/gitlab-org/-/epics/9704)을 돕기 위해 스캔 결과 정책에 추가되는 여러 새로운 설정 중 하나인 이 제어는 정책을 우회하기 위해 프로젝트 수준 설정을 활용하는 기능을 제한합니다.

각 기존 또는 새로운 스캔 결과 정책에 대해 `Prevent pushing and force pushing`을 활성화하여 정책 내에 정의된 브랜치에 효과를 발휘하고 사용자가 머지 리퀘스트 흐름을 우회하여 브랜치로 직접 변경 사항을 푸시하는 것을 방지할 수 있습니다.

SaaS에서 16.6으로 사용 가능합니다. 기능 플래그 `scan_result_policies_block_force_push` 뒤의 Self-managed에서 사용 가능하며 16.7에서 기본적으로 활성화됩니다.

### AWS S3에 대한 그룹 수준 감사 이벤트 스트리밍 {#group-level-audit-event-streaming-to-aws-s3}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

외부 로깅 또는 데이터 수집 도구와의 통합을 기반으로 이제 AWS S3를 최상위 그룹의 감사 이벤트 스트림 대상으로 선택할 수 있습니다. 이 기능은 더 쉽고 문제 없는 통합을 위한 관련 정보를 제공합니다.

이전에는 AWS S3가 수락할 요청을 작성하기 위해 사용자 정의 HTTP 헤더를 사용해야 했습니다. 이 방법은 오류가 발생하기 쉬웠으며 문제를 해결하기 어려웠습니다.

### 응답하지 않는 외부 상태 검사의 개선된 처리 {#improved-handling-of-unresponsive-external-status-checks}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/status_checks.md#status-checks-widget)

{{< /details >}}

이전에 머지 리퀘스트의 외부 상태 검사는 성공적인 또는 실패한 응답을 받을 때까지 외부 URL을 계속 폴링했습니다. 이로 인해 일부 상태 검사가 응답하지 않는 상태에서 정지된 것처럼 보일 수 있었습니다.

이제 2분 타임아웃이 포함되어 있으므로 외부 시스템에서 응답을 받지 못한 경우 2분 후 상태 검사를 수동으로 다시 시도할 수 있습니다.

### 취약성 보고서의 도구 필터 변경 {#changes-to-the-vulnerability-reports-tool-filter}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11237)

{{< /details >}}

이전에 취약성 보고서를 사용하면 GitLab이 지원하는 도구 유형의 정적 목록을 필터링한 다음 사용자 정의 스캐너의 동적 목록을 필터링할 수 있었습니다. 이 릴리스를 통해 이제 분석기별로 그룹화된 도구 유형을 선택할 수 있습니다.

### 서비스 계정의 선택적 만료 날짜 {#service-accounts-have-optional-expiry-dates}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421420)

{{< /details >}}

GitLab 관리자 및 그룹 Owner는 서비스 계정에 대한 만료 날짜를 적용할지 여부를 선택할 수 있습니다. 이전에는 서비스 계정 토큰이 개인, 프로젝트 및 그룹 액세스 토큰 만료 한도에 따라 1년 이내에 만료되어야 했습니다. 이를 통해 관리자와 그룹 Owner는 자신의 목표와 가장 잘 맞는 보안과 사용 편의성 간의 균형을 선택할 수 있습니다.

### 중복 NuGet 패키지 방지 {#prevent-duplicate-nuget-packages}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/nuget_repository/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/293748)

{{< /details >}}

GitLab 패키지 레지스트리를 사용하여 프로젝트의 NuGet 패키지를 게시하고 다운로드할 수 있습니다. 기본적으로 동일한 패키지 이름과 버전을 여러 번 게시할 수 있습니다.

그러나 특히 릴리스의 경우 중복 업로드를 방지할 수 있습니다. 이 릴리스에서 GitLab은 패키지 레지스트리에 대한 그룹 설정을 확장하여 중복 패키지 업로드를 허용하거나 거부할 수 있습니다.

[GitLab API](../../api/graphql/reference/_index.md#packagesettings)를 사용하거나 UI에서 이 설정을 조정할 수 있습니다.

### 기본 HTTP 인증으로 Maven 리포지토리에 패키지 업로드 {#upload-packages-to-the-maven-repository-with-basic-http-authentication}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/packages/maven_repository/_index.md#basic-http-authentication) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/277385)

{{< /details >}}

GitLab 패키지 레지스트리는 이제 기본 HTTP 인증으로 Maven 패키지를 업로드하는 것을 지원합니다. 이전에는 기본 HTTP 인증을 사용하여 Maven 패키지를 다운로드할 수만 있었습니다. 이 불일치로 인해 개발자가 프로젝트에 대한 인증을 구성하고 유지하기 어려웠습니다.

`sbt`을 사용하여 아티팩트를 게시하는 것은 지원되지 않지만, [이슈 408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479)는 이 기능을 추가하도록 제안합니다.

### 컨테이너 스캔: 수정되지 않을 결과 제외 {#container-scanning-exclude-findings-which-wont-be-fixed}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/container_scanning/_index.md#available-cicd-variables) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/6846)

{{< /details >}}

컨테이너 스캔 결과에는 공급업체가 평가하고 수정하지 않기로 결정한 결과가 포함될 수 있습니다. 실행 가능한 결과에 집중할 수 있도록 이제 이러한 결과를 제외할 수 있습니다. 구성 옵션은 GitLab 문서를 참조하십시오.

### 취약성 보고서 내보내기에 CVSS 벡터 포함 {#include-cvss-vectors-in-the-vulnerability-report-export}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11213)

{{< /details >}}

취약성 보고서에서 정보를 내보낼 때 CVSS 벡터 정보가 이제 포함됩니다. 이 추가 데이터는 GitLab 외부에서 취약성을 분석하고 분류하는 데 도움이 됩니다.

### Java 21을 사용하는 SBT 프로젝트 지원 추가 {#added-support-for-sbt-projects-using-java-21}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421174)

{{< /details >}}

종속성 검사 및 라이선스 검사는 이제 Java 21을 사용하는 SBT 프로젝트를 지원합니다.

### DAST 분석기 업데이트 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

16.6 릴리스 마일스톤 동안 브라우저 기반 DAST에 대해 기본적으로 다음 활성 검사를 활성화했습니다:

- 검사 94.1은 ZAP 검사 90019를 대체하고 서버 측 코드 주입(PHP)을 식별합니다.
- 검사 94.2는 ZAP 검사 90019를 대체하고 서버 측 코드 주입(Ruby)을 식별합니다.
- 검사 94.3은 ZAP 검사 90019를 대체하고 서버 측 코드 주입(Python)을 식별합니다.
- 검사 943.1은 ZAP 검사 40033을 대체하고 데이터 쿼리 로직의 특수 요소의 부적절한 중립화를 식별합니다.
- 검사 74.1은 ZAP 검사 90017을 대체하고 XSLT 주입을 식별합니다.

### macOS 14(Sonoma) 및 Xcode 15 이미지 지원 {#macos-14-sonoma-and-xcode-15-image-support}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/macos.md#supported-macos-images) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431424)

{{< /details >}}

이제 팀은 macOS 14 및 Xcode 15에서 Apple 생태계를 위한 애플리케이션을 원활하게 만들고, 테스트하고, 배포할 수 있습니다.

macOS의 SaaS 러너를 사용하면 GitLab CI/CD와 통합된 안전한 온디맨드 GitLab 러너 빌드 환경에서 macOS가 필요한 애플리케이션을 빌드하고 배포할 때 개발 팀의 속도를 높일 수 있습니다.

오늘 `macos-14-xcode-15`을 .GitLab-ci.yml 파일의 이미지로 사용하여 시도해보세요.

### GitLab 러너 16.6 {#gitlab-runner-166}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 16.6을 출시합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [GCP Compute Engine용 GitLab 러너 Fleeting 플러그인 - 베타](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29409)
- [Docker executor를 위한 우아한 종료 구현](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Kubernetes를 위한 저장소 클래스를 사용하여 PVC 볼륨을 동적으로 생성](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)
- [Kubernetes 실행기에서 `image.entrypoint`을 통해 컨테이너 진입점 재정의](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30713)

#### 버그 수정 {#bug-fixes}

- [GitLab 러너 16.5.0으로 업그레이드 후 Pod이 Liveness probe failed 오류로 계속 재시작](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36959)
- [디버그 터미널 - 변수가 파일 경로 대신 파일 내용 포함](https://gitlab.com/gitlab-org/gitlab/-/issues/399770)
- [Kubernetes의 작업 실행 Pod이 신호를 처리하지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28162)
- [GitLab 러너 Docker 실행기에서 Podman을 사용하는 서비스가 시작되지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29480)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-6-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.6)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
