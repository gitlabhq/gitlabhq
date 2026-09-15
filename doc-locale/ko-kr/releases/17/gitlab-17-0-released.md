---
stage: Release Notes
group: Monthly Release
date: 2024-05-16
title: "GitLab 17.0 릴리스 정보"
description: "CI/CD 구성 요소 및 입력이 이제 일반 공개되는 CI/CD 카탈로그와 함께 GitLab 17.0 출시"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 5월 16일, GitLab 17.0은 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자를 지원하거나 새로운 지명을 추가하세요 🙌

Niklas van Schrick는 이제 3개의 MVP로 모자 트릭을 가지고 있으며 GitLab 14.3 이후 마일스톤당 최소 하나의 머지 리퀘스트를 가진 GitLab의 가장 일관된 기여자 중 한 명이 되었습니다.

Niklas는 [Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz)에 의해 GitLab의 제품 관리자로서 사용자 지정 웹후크 페이로드 템플릿을 생성하는 기능에 기여한 후 [사용자 지정 웹후크 헤더를 지정할 수 있는 기능](https://gitlab.com/gitlab-org/gitlab/-/issues/17290)으로 이를 따라가도록 추천되었습니다. "이것은 65개의 업보트를 받은 매우 요구되는 7년 된 기능 요청을 해결했습니다"라고 Magdalena는 말합니다. "사용자는 이제 사용자 지정 웹후크를 완전히 설계할 수 있습니다!"

Niklas는 [GitLab Core Team](https://about.gitlab.com/community/core-team/)의 구성원이며 광범위한 커뮤니티와 GitLab이 모든 사람이 기여할 수 있도록 해야 한다는 우리의 사명을 실현하도록 도와줍니다.

"저의 여정 동안 많은 다양한 검토자, 유지 관리자, 디자이너, 기술 작성자, 제품 관리자 등과 상호 작용했습니다"라고 Niklas는 말합니다. "모든 사람이 도움이 되었고 이슈 및 머지 리퀘스트를 앞으로 나아가는 데 최선을 다했습니다."

Gerardo Navarro는 1년 이상 GitLab에 기여해왔으며 두 번째 GitLab MVP 상을 받습니다.

Gerardo는 [패키지 레지스트리 목록에서 보호된 패키지를 표시](https://gitlab.com/gitlab-org/gitlab/-/issues/437926)하는 기능에 대한 지속적인 기여를 만든 것으로 지명되었습니다. 이 기능은 [보호된 패키지 에픽](https://gitlab.com/groups/gitlab-org/-/epics/5574)과 관련된 일련의 기여의 일부이며, 패키지 레지스트리에서 패키지를 생성, 업데이트 및 삭제하기 위한 세분화된 권한을 활성화하여 보안을 높이는 것을 목표로 합니다.

Gerardo Navarro 및 Siemens의 나머지 팀이 GitLab을 공동으로 창조하는 것을 도와주신 것에 감사드립니다.

"이렇게 멋진 상으로 우리의 작업을 감사하셔서 정말 감사합니다"라고 Gerardo는 말합니다. "저는 영광입니다. 모든 기여에서 많은 것을 배우고 있습니다."

## 주요 기능 {#primary-features}

### CI/CD 카탈로그에 구성 요소 및 입력이 이제 일반 공개됨 {#cicd-catalog-with-components-and-inputs-now-generally-available}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

CI/CD 카탈로그는 이제 일반 공개되었습니다. 이 릴리스의 일부로 [CI/CD 구성 요소](../../ci/components/_index.md) 및 [입력](../../ci/yaml/_index.md#inputs)을 일반 공개하고 있습니다.

CI/CD 카탈로그를 사용하면 커뮤니티 및 업계 전문가가 만든 광범위한 구성 요소 배열에 액세스할 수 있습니다. 지속적 통합, 배포 파이프라인 또는 자동화 작업에 대한 솔루션을 찾고 있든 귀하의 요구 사항에 맞게 조정된 다양한 구성 요소 선택을 찾을 수 있습니다. 다음 [블로그 게시물](https://about.gitlab.com/blog/ci-cd-catalog-goes-ga-no-more-building-pipelines-from-scratch/)에서 카탈로그 및 해당 기능에 대해 자세히 읽을 수 있습니다.

CI/CD 구성 요소를 카탈로그에 기여하고 GitLab.com의 이 새롭고 성장하는 부분을 확장하는 것을 도와주도록 초대합니다!

### Value Streams Dashboard의 AI Impact 분석 {#ai-impact-analytics-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/duo_and_sdlc_trends.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/12978)

{{< /details >}}

AI Impact는 Value Streams Dashboard에서 사용 가능한 대시보드로, 조직이 [GitLab Duo의 생산성에 미치는 영향](https://about.gitlab.com/blog/measuring-ai-effectiveness-beyond-developer-productivity-metrics/)을 이해하는 데 도움을 줍니다. 이 새로운 월간 메트릭 보기는 AI 사용 추세를 리드 타임, 사이클 타임, DORA 및 취약성 같은 SDLC 메트릭과 비교합니다. 소프트웨어 리더는 AI Impact 대시보드를 사용하여 엔드투엔드 워크스트림에서 얼마나 많은 시간을 절약했는지 측정할 수 있으며, 개발자 활동보다는 비즈니스 결과에 집중할 수 있습니다.

이 첫 번째 릴리스에서 AI 사용은 월간 [코드 제안](../../user/project/repository/code_suggestions/_index.md) 사용률로 측정되며, 월간 고유 코드 제안 사용자 수를 총 월간 고유 [기여자](../../user/group/contribution_analytics/_index.md)로 나누어 계산됩니다.

AI Impact 대시보드는 제한된 시간 동안 Ultimate 티어의 사용자가 사용할 수 있습니다. 이후 대시보드를 사용하려면 GitLab Duo Enterprise 라이선스가 필요합니다.

### Linux Arm에서 호스팅된 러너 도입 {#introducing-hosted-runners-on-linux-arm}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/365300)

{{< /details >}}

GitLab.com을 위해 Linux Arm에서 호스팅된 러너를 도입하게 되어 기쁩니다. 이제 각각 4개 및 8개의 vCPU를 갖춘 `medium` 및 `large` Arm 머신 유형은 GitLab CI/CD와 완전히 통합되어 있으므로 애플리케이션을 이전보다 더 빠르고 비용 효율적으로 빌드하고 테스트할 수 있습니다.

업계에서 가장 빠른 CI/CD 빌드 속도를 제공하기로 결심했으며, 팀들이 더 짧은 피드백 사이클을 달성하고 궁극적으로 소프트웨어를 더 빠르게 제공하는 것을 기대합니다.

### 배포 세부 정보 페이지 도입 {#introducing-deployment-detail-pages}

<!-- categories: Release Orchestration, Environment Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/deployment_approvals.md#approve-or-reject-a-deployment) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/374538)

{{< /details >}}

이제 GitLab에서 배포에 직접 링크할 수 있습니다. 이전에는 배포에 대해 협업하고 있었다면 배포 목록에서 배포를 조회해야 했습니다. 나열된 배포의 수 때문에 올바른 배포를 찾기가 어려웠고 오류가 발생하기 쉬웠습니다.

17.0부터 GitLab은 직접 링크할 수 있는 배포 세부 정보 보기를 제공합니다. 이 첫 번째 버전에서 배포 세부 정보 페이지는 배포 작업의 개요를 제공하고 연속 제공 설정에서 배포를 승인, 거부 또는 주석 달기 가능성을 제공합니다. 배포 세부 정보 페이지를 개선하기 위한 추가 방법을 모색하고 있으며 관련 파이프라인 작업에서 이를 링크하는 것을 포함합니다. [이슈 450700](https://gitlab.com/gitlab-org/gitlab/-/issues/450700)에서 귀하의 피드백을 듣고 싶습니다.

### GitLab Duo Chat은 이제 Anthropic Claude 3 Sonnet 사용 {#gitlab-duo-chat-now-uses-anthropic-claude-3-sonnet}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13297)

{{< /details >}}

GitLab Duo Chat은 방금 훨씬 더 좋아졌습니다. 이제 Anthropic Claude 3 Sonnet을 기본 모델로 사용하여 대부분의 질문에 답변하기 위해 Claude 2.1을 대체합니다.

GitLab에서는 작업 세트에 대한 최고의 모델을 선택하고 잘 수행되는 프롬프트를 작성할 때 테스트 주도 접근 방식을 적용합니다. 최근 채팅 프롬프트 조정으로 Claude 2.1에 구축된 이전 채팅 버전과 비교하여 Claude 3 Sonnet을 기반으로 하는 채팅 답변의 정확성, 포괄성 및 가독성이 크게 개선되었습니다. 따라서 우리는 이제 이 새로운 모델 버전으로 전환했습니다.

### 자체 관리 배포에서 지원되는 GitLab Duo Chat의 방법 질문 {#how-to-questions-in-gitlab-duo-chat-supported-on-self-managed-deployments}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/gitlab_duo_chat/examples.md#ask-about-gitlab) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/451215)

{{< /details >}}

GitLab Duo Chat의 인기 있는 기능은 GitLab 사용 방법에 대한 질문에 답변하는 것입니다. Chat은 다양한 다른 기능을 제공하지만 이 특정 기능은 이전에 GitLab.com에서만 사용할 수 있었습니다. 이 릴리스를 통해 GitLab 자체 관리 배포에서도 접근 가능하게 하고 있으며, 모든 유형의 배포에서 즐거운 경험을 제공하려는 우리의 약속에 부합합니다.

새 사용자이든 전문가이든 "GitLab에서 비밀번호를 변경하는 방법은?" 또는 "Kubernetes 클러스터를 GitLab에 연결하는 방법은?"과 같은 쿼리에 대해 Chat의 도움을 받을 수 있습니다. Chat은 문제를 더 효율적으로 해결하기 위한 유용한 정보를 제공하는 것을 목표로 합니다.

### Value Streams Dashboard의 새로운 사용 개요 패널 {#new-usage-overview-panel-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md#overview) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438256)

{{< /details >}}

Value Streams Dashboard를 개요 패널로 향상시켰습니다. 이 새로운 시각화는 소프트웨어 제공 성능에 대한 경영진 수준의 통찰력에 대한 필요성을 해결하며 소프트웨어 개발 생명 주기(SDLC) 맥락에서 GitLab 사용의 명확한 그림을 제공합니다.

개요 패널은 그룹 수준의 메트릭(예: (하위)그룹, 프로젝트, 사용자, 이슈, 머지 리퀘스트, 파이프라인 수)을 표시합니다.

### CI/CD 작업 토큰 허용 목록에 그룹 추가 {#add-a-group-to-the-cicd-job-token-allowlist}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)

{{< /details >}}

GitLab 15.9에서 도입된 CI/CD 작업 토큰 허용 목록은 다른 프로젝트에서 프로젝트로의 무단 액세스를 방지합니다. 이전에는 최대 200개의 총 프로젝트 제한을 두고 다른 특정 프로젝트에서만 프로젝트 수준에서 액세스를 허용할 수 있었습니다.

GitLab 17.0에서는 이제 프로젝트의 CI/CD 작업 토큰 허용 목록에 그룹을 추가할 수 있습니다. 200의 최대 제한은 이제 프로젝트와 그룹 모두에 적용되므로 프로젝트 허용 목록은 이제 액세스가 승인된 최대 200개의 프로젝트 및 그룹을 가질 수 있습니다. 이 개선으로 그룹과 연결된 많은 프로젝트를 더 쉽게 추가할 수 있습니다.

### `rules:exists` CI/CD 키워드로 향상된 컨텍스트 제어 {#enhanced-context-control-with-the-rulesexists-cicd-keyword}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#rulesexistsproject) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)

{{< /details >}}

`rules:exists` CI/CD 키워드는 키워드가 정의된 위치에 따라 달라지는 기본 동작을 가지고 있으므로 더 복잡한 파이프라인에서 사용하기가 더 어려울 수 있습니다. 작업에서 정의될 때 `rules:exists`은 파이프라인을 실행하는 프로젝트에서 지정된 파일을 검색합니다. 그러나 `include` 섹션에서 정의될 때 `rules:exists`은 `include` 섹션을 포함하는 구성 파일을 호스팅하는 프로젝트에서 지정된 파일을 검색합니다. 구성이 여러 파일 및 프로젝트에 걸쳐 분할되면 어느 정확한 프로젝트가 정의된 파일을 검색할지 알기가 어려울 수 있습니다.

이 릴리스에서는 `project` 및 `ref` 하위 키를 `rules:exists`에 도입하여 이 키워드에 대한 검색 컨텍스트를 명시적으로 제어할 수 있는 방법을 제공합니다. 이러한 새로운 하위 키는 검색 컨텍스트를 정확히 지정하여 정확한 규칙 평가를 보장하고 불일치를 완화하며 파이프라인 규칙 정의의 명확성을 향상시킵니다.

### Switchboard를 사용하여 수행된 구성 변경에 대한 변경 로그 {#change-log-for-configuration-changes-made-using-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/dedicated/configure_instance/_index.md#view-the-change-log) \| [관련 이슈](https://about.gitlab.com/dedicated/)

{{< /details >}}

이제 Switchboard [구성 페이지](../../administration/dedicated/configure_instance/_index.md#configure-your-instance-using-switchboard)를 사용하여 GitLab Dedicated 인스턴스 인프라에 수행된 구성 변경 상태를 볼 수 있습니다.

Switchboard에서 테넌트를 보거나 편집할 수 있는 모든 사용자는 구성 변경 로그의 변경 사항을 보고 인스턴스에 적용되는 진행 상황을 추적할 수 있습니다.

현재 Switchboard 구성 페이지 및 변경 로그는 [허용 목록에 IP 추가](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist) 또는 인스턴스의 [SAML 설정](../../administration/dedicated/configure_instance/authentication/saml.md)을 구성하여 인스턴스에 대한 액세스를 관리하는 것과 같은 변경 사항에 사용할 수 있습니다.

[향후 분기](https://about.gitlab.com/releases/whats-new/#whats-coming)에서 추가 구성에 대한 셀프 서비스 업데이트를 활성화하도록 이 기능을 확장할 것입니다.

## 규모 및 배포 {#scale-and-deployments}

### GitLab 차트 개선 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/charts/)

{{< /details >}}

[GitLab Operator](https://docs.gitlab.com/operator/)는 이제 클라우드 네이티브 하이브리드 설치를 위해 프로덕션에서 사용할 수 있습니다. GitLab Operator를 채택하기 전에 [설치 설명서](https://docs.gitlab.com/operator/installation/)를 참조하세요.

사용자 지정 BusyBox 값을 지정할 때(`global.busybox`) BusyBox 이미지로 돌아가기 지원이 제거되었습니다. BusyBox 기반 init 컨테이너 지원은 일반적인 GitLab 기반 init 이미지를 선호하여 GitLab 16.2(Helm 차트 7.2)에서 더 이상 사용되지 않습니다.

`gitlab.kas.privateApi.tls.enabled` 및 `gitlab.kas.privateApi.tls.secretName`에 대한 지원도 제거되었습니다. 대신 `global.kas.tls.enabled` 및 `global.kas.tls.secretName`를 사용해야 합니다.

Sidekiq 차트에서 더 이상 사용되지 않는 큐 선택기 및 부정 옵션이 제거되었습니다.

### Linux 패키지 개선사항 {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

CentOS Linux 7은 2024년 6월 30일에 [지원 종료](https://www.redhat.com/en/topics/linux/centos-linux-eol)에 도달합니다. 이는 GitLab 17.6이 CentOS 7용 패키지를 제공할 수 있는 마지막 GitLab 버전입니다.

### 두 개의 데이터베이스 모드를 베타로 사용할 수 있음 {#two-database-mode-is-available-in-beta}

<!-- categories: Cell -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/postgresql/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/432391)

{{< /details >}}

현재 대부분의 자체 관리 고객은 단일 데이터베이스만 사용합니다. GitLab.com과 자체 관리 간의 설정이 동일한지 확인하기 위해 자체 관리 고객이 기본적으로 두 개의 데이터베이스로 마이그레이션하고 실행하도록 요청합니다. 16.0에서 두 개의 데이터베이스 연결이 자체 관리 설치의 기본값이 되었습니다. 17.0에서는 [제한된 베타로 두 개의 데이터베이스 모드를 출시](../../administration/postgresql/_index.md)하며, 목표는 19.0까지 분해 실행을 일반 공개하는 것입니다. 두 개의 데이터베이스로의 마이그레이션은 17.0에서 선택적이지만 19.0으로 업그레이드하기 전에 수행해야 합니다.

마이그레이션은 다운타임이 필요합니다. 자체 관리 고객은 이 마이그레이션을 약간의 다운타임으로 실행하는 [도구](https://gitlab.com/gitlab-org/gitlab/-/issues/368729)를 사용할 수 있습니다. 새로운 `gitlab-ctl` 명령을 도입하여 단일 데이터베이스 GitLab 인스턴스를 분해된 설정으로 업그레이드할 수 있습니다. 이 설정에는 Linux 패키지와 함께 작동할 명령이 포함되어 있습니다. [실제 마이그레이션](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135585)(데이터베이스 복사)은 GitLab 프로젝트의 rake 작업의 일부입니다.

### 개인 공유 그룹 구성원이 모든 구성원을 위해 구성원 탭에 나열됨 {#private-shared-group-members-are-listed-on-members-tab-for-all-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/members/sharing_projects_groups.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/418888)

{{< /details >}}

이전에 공개 그룹 또는 프로젝트가 개인 그룹을 초대할 때 개인 그룹은 구성원 페이지의 그룹 탭에만 나열되었으며 개인 구성원은 공개 그룹의 구성원에게 표시되지 않았습니다. 이러한 그룹의 구성원 간에 더 나은 협업을 가능하게 하기 위해 이제 구성원 탭에 모든 초대 그룹 구성원을 나열하고 있으며 개인 초대 그룹의 구성원도 포함됩니다. 멤버십의 출처는 개인 그룹에 액세스할 수 없는 구성원으로부터 마스킹됩니다. 그러나 멤버십의 출처는 프로젝트에서 최소한 유지 관리자 역할 또는 그룹에서 소유자 역할이 있는 사용자에게 표시되므로 프로젝트 또는 그룹에서 구성원을 관리할 수 있습니다. 구성원 탭을 보는 현재 사용자가 인증되지 않았거나 그룹 또는 프로젝트의 구성원이 아니면 개인 그룹 구성원이 표시되지 않습니다. 이 변경이 그룹 및 프로젝트 구성원이 누가 그룹 또는 프로젝트에 액세스할 수 있는지 한눈에 이해하기 더 쉬워질 것으로 예상합니다.

### 구성원 페이지는 초대 그룹의 구성원을 표시함 {#members-page-displays-members-from-invited-groups}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/members/_index.md#share-a-project-with-a-group) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)

{{< /details >}}

이전에 그룹 또는 프로젝트에 초대된 그룹의 구성원은 구성원 페이지의 그룹 탭에만 표시되었습니다. 이것은 사용자가 그룹 및 구성원 탭을 모두 확인하여 누가 특정 그룹 또는 프로젝트에 액세스할 수 있는지 이해해야 함을 의미합니다. 이제 공유 구성원도 구성원 탭에 나열되어 그룹 또는 프로젝트의 일부인 모든 구성원을 한눈에 완전히 볼 수 있습니다.

### REST API를 사용하여 Bitbucket Cloud에서 가져오기 {#import-from-bitbucket-cloud-by-using-rest-api}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/import.md#import-repository-from-bitbucket-cloud) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/215036)

{{< /details >}}

이번 마일스톤에서 REST API를 사용하여 Bitbucket Cloud 프로젝트를 가져올 수 있는 기능을 추가했습니다.

이는 UI를 사용하여 가져오는 것보다 많은 프로젝트를 가져오는 더 나은 솔루션이 될 수 있습니다.

### API를 사용하여 선택한 프로젝트 관계 다시 가져오기 {#re-import-a-chosen-project-relation-by-using-the-api}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/project_import_export.md#import-project-resources) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)

{{< /details >}}

많은 동일 유형의 항목이 있는 내보내기 파일에서 프로젝트를 가져올 때(예: 머지 리퀘스트 또는 파이프라인) 때때로 이러한 항목 중 일부를 가져오지 못했습니다.

이 릴리스에서는 이미 가져온 항목을 건너뛰고 명명된 관계를 다시 가져오는 API 엔드포인트를 추가했습니다. API는 다음을 모두 필요로 합니다:

- 프로젝트 내보내기 아카이브입니다.
- 유형(이슈, 머지 리퀘스트, 파이프라인 또는 마일스톤).

### GitLab에서 여러 Jira 프로젝트의 이슈 보기 {#view-issues-from-multiple-jira-projects-in-gitlab}

<!-- categories: Settings -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../integration/jira/configure.md#view-jira-issues) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12609)

{{< /details >}}

더 큰 리포지토리의 경우 Jira 이슈 통합을 설정할 때 GitLab에서 여러 Jira 프로젝트의 이슈를 볼 수 있습니다. 이 릴리스를 통해 다음을 수행할 수 있습니다:

- 최대 100개의 Jira 프로젝트 키를 쉼표로 구분하여 입력합니다.
- 모든 사용 가능한 키를 포함하려면 **Jira 프로젝트 키**를 비워 두세요.

GitLab에서 Jira 이슈를 볼 때 프로젝트별로 [이슈를 필터링](../../integration/jira/configure.md#filter-jira-issues)할 수 있습니다.

GitLab Ultimate에서 [취약성에 대한 Jira 이슈를 생성](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability)하려면 하나의 Jira 프로젝트만 지정할 수 있습니다.

### REST API를 사용하여 GitLab에서 Jira 이슈 보기 활성화 {#enable-viewing-jira-issues-in-gitlab-with-the-rest-api}

<!-- categories: Source Code Management, Settings -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/project_integrations.md#jira-issues) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)

{{< /details >}}

이 릴리스를 통해 REST API를 사용하여 GitLab에서 [Jira 이슈 보기](../../integration/jira/configure.md#view-jira-issues)를 활성화할 수 있습니다. 하나 이상의 Jira 프로젝트를 지정하여 이슈를 볼 수도 있습니다.

[Ivan](https://gitlab.com/ivantedja)에게 [이 커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150209)를 감사드립니다!

### Service Desk를 위한 여러 외부 참여자 {#multiple-external-participants-for-service-desk}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/service_desk/external_participants.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/3758)

{{< /details >}}

때때로 지원 티켓 해결에 여러 사람이 관여하거나 요청자가 티켓 상태에 대해 동료들을 최신 상태로 유지하려고 합니다.

이제 Service Desk 티켓 및 일반 이슈에 GitLab 계정이 없는 최대 10명의 외부 참여자를 가질 수 있습니다.

외부 참여자는 티켓의 각 공개 설명에 대해 Service Desk 알림 이메일을 받으며 해당 회신이 GitLab UI에 주석으로 표시됩니다.

빠른 작업 [`/add_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant) 및 [`remove_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant)를 사용하여 몇 번의 키 입력으로 외부 참여자를 추가하거나 제거하세요.

또한 초기 이메일의 [`Cc` 헤더에서 모든 이메일 주소를 추가](../../user/project/service_desk/external_participants.md#add-external-participants-from-the-cc-header)하도록 GitLab을 구성할 수 있습니다. Service Desk 티켓으로 변환됩니다.

[모든 Service Desk 이메일 템플릿을 원하는 대로 맞춤 설정](../../user/project/service_desk/configure.md#customize-emails-sent-to-external-participants)할 수 있으며 Markdown, HTML 및 동적 자리 표시자를 사용할 수 있습니다. 대화에서 탈퇴할 수 있도록 외부 참여자를 위해 [구독 취소 링크 자리 표시자](../../user/project/service_desk/external_participants.md#add-an-external-participant)를 사용할 수 있습니다.

### 직접 전송을 사용하여 가져온 항목 표시 {#indicate-that-items-were-imported-using-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/group/import/direct_transfer_migrations.md#review-results-of-the-import) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)

{{< /details >}}

GitLab [직접 전송을 사용하여](../../user/group/import/_index.md) GitLab 인스턴스 간에 그룹 및 프로젝트를 마이그레이션할 수 있습니다.

지금까지 가져온 항목을 쉽게 식별할 수 없었습니다. 이 릴리스를 통해 작성자가 특정 사용자로 식별되는 직접 전송으로 가져온 항목에 시각적 표시기를 추가했습니다:

- 주석(시스템 주석 및 사용자 댓글)
- 이슈
- 머지 리퀘스트
- 에픽
- 설계
- 스니펫
- 사용자 프로필 활동

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### JetBrains IDE용 GitLab Duo 플러그인의 1Password 시크릿 통합 {#1password-secrets-integration-in-gitlab-duo-plugin-for-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../editor_extensions/jetbrains_ide/_index.md#integrate-with-1password-cli) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291)

{{< /details >}}

이제 JetBrains용 GitLab Duo 플러그인과 1Password 시크릿 관리를 통합할 수 있습니다.

개발자는 JetBrains IDE 설정의 개인 액세스 토큰을 1Password 시크릿 참조로 바꿀 수 있습니다. 이는 시크릿 관리를 단순화하고 수동 토큰 업데이트 없이 원활한 시크릿 회전을 활성화합니다.

### 맞춤식 바로 가기로 GitLab Duo Chat에 더 빠르게 액세스 {#access-gitlab-duo-chat-faster-with-customizable-shortcuts}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../editor_extensions/jetbrains_ide/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/332)

{{< /details >}}

JetBrains의 편집기에서 직접 Duo Chat을 열 수 있습니다.

기본 Alt+D 키보드 바로 가기(또는 자신의 설정)를 사용하여 Duo Chat을 빠르게 열고 질문을 입력합니다. 동일한 키보드 바로 가기를 사용하여 창을 닫습니다.

### 프로젝트 주석 템플릿 {#project-comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/comment_templates.md#for-a-project) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/440818)

{{< /details >}}

[GitLab 16.11의 그룹 주석 템플릿 릴리스](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#group-comment-templates) 이후 이를 GitLab 17.0의 프로젝트로 가져오고 있습니다.

조직 전체에서 이슈, 에픽 및 머지 리퀘스트에 동일한 템플릿 응답을 갖는 것이 도움이 될 수 있습니다. 이러한 응답에는 답변해야 하는 표준 질문, 일반적인 문제에 대한 응답 또는 머지 리퀘스트 검토 설명을 위한 좋은 구조가 포함될 수 있습니다. 프로젝트 수준 주석 템플릿은 템플릿의 가용성 범위를 지정하는 추가 방법을 제공하여 조직에 사용자 간에 이를 공유할 수 있는 더 많은 제어 및 유연성을 제공합니다.

주석 템플릿을 만들려면 GitLab의 아무 주석 상자로 이동하여 **댓글 템플릿 삽입 > Manage project comment templates**를 선택하세요. 주석 템플릿을 만든 후 모든 프로젝트 구성원이 사용할 수 있습니다. 댓글을 작성할 때 **댓글 템플릿 삽입** 아이콘을 선택하면 저장된 응답이 적용됩니다.

이 주석 템플릿 반복에 대해 정말 흥분하고 있으며 피드백이 있으시면 [이슈 451520](https://gitlab.com/gitlab-org/gitlab/-/issues/451520)에 남겨주세요.

### GitLab UI 커밋에 대한 커밋 서명 {#commit-signing-for-gitlab-ui-commits}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits) \| [관련 이슈](https://gitlab.com/gitlab-org/gitaly/-/issues/5361)

{{< /details >}}

이전에는 GitLab이 수행한 웹 커밋 및 자동화된 커밋을 서명할 수 없었습니다. 이제 서명 키, 커미터 이름 및 이메일 주소로 자체 관리 인스턴스를 구성하여 웹 및 자동화된 커밋을 서명할 수 있습니다.

### Kubernetes 에이전트 인증 제한 증가 {#increase-kubernetes-agent-authorization-limit}

<!-- categories: Continuous Delivery -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431133)

{{< /details >}}

GitLab용 Kubernetes 에이전트를 사용하면 단일 에이전트 연결을 그룹과 공유할 수 있습니다. 대규모 멀티테넌트 클러스터에서 단일 에이전트를 지원하는 것을 목표로 합니다. 그러나 연결 공유 수에 제한이 있을 수 있습니다. 지금까지 에이전트는 [CI/CD](../../user/clusters/agent/ci_cd_workflow.md)를 사용하여 100개의 프로젝트 및 그룹과만 공유될 수 있으며 [`user_access`](../../user/clusters/agent/user_access.md) 키워드를 사용하여 100개의 프로젝트 및 그룹과 공유될 수 있습니다. GitLab 17.0에서는 공유할 수 있는 프로젝트 및 그룹의 수가 500으로 증가합니다.

클러스터에서 여러 에이전트를 실행해야 하는 경우 [이슈 454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110)에서 피드백을 듣고 싶습니다.

### FIPS 모드의 Kubernetes용 GitLab 에이전트 지원 {#support-for-gitlab-agent-for-kubernetes-in-fips-mode}

<!-- categories: Continuous Delivery -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/clusters/kas.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/375327)

{{< /details >}}

GitLab 17.0부터 Kubernetes 에이전트 구성 요소가 활성화된 FIPS 모드에서 GitLab을 설치할 수 있습니다. 이제 FIPS 준수 사용자는 모든 [Kubernetes와 GitLab의 통합](../../user/clusters/agent/_index.md)을 활용할 수 있습니다.

### 배포에서 빠른 전진 머지 리퀘스트 추적 {#track-fast-forward-merge-requests-in-deployments}

<!-- categories: Continuous Delivery -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/384104)

{{< /details >}}

과거 릴리스에서 머지 리퀘스트는 프로젝트의 병합 방법이 **머지 커밋** 또는 **준선형 이력으로 머지 커밋**인 경우에만 배포에 추적되었습니다. GitLab 17.0부터 머지 리퀘스트는 배포 방법 **패스트 포워드 머지**인 프로젝트를 포함하여 배포에 추적됩니다.

### 관리자 모드에서 시작된 세션 식별 {#identify-sessions-initiated-by-admin-mode}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/sign_in_restrictions.md#check-if-your-session-has-admin-mode-enabled) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438674)

{{< /details >}}

인스턴스 관리자로서 여러 브라우저 또는 다른 컴퓨터를 사용할 때 어느 세션이 관리 모드이고 어느 세션이 그렇지 않은지 알기가 어렵습니다. 이제 관리자는 **사용자 설정 > Active Sessions**으로 이동하여 관리 모드를 사용하는 세션을 식별할 수 있습니다.

기여해 주신 [Roger Meier](https://gitlab.com/bufferoverflow)님 감사합니다!

### 사용자 아바타 사용자 지정 {#customize-avatars-for-users}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../api/users.md#upload-an-avatar-for-yourself) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/356868)

{{< /details >}}

이제 API를 사용하여 봇 사용자를 포함한 모든 사용자 유형에 대한 사용자 정의 아바타를 업로드할 수 있습니다. 이는 그룹 및 프로젝트 액세스 토큰 또는 서비스 계정과 같은 봇 사용자를 UI의 인간 사용자와 시각적으로 구별하는 데 특히 도움이 될 수 있습니다. 기여해주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### 사용자 지정 역할 및 해당 권한 편집 {#edit-a-custom-role-and-its-permissions}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md#edit-a-custom-role) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437590)

{{< /details >}}

이전에는 기존 사용자 지정 역할 및 해당 권한을 편집할 수 없었습니다. 이제 역할을 다시 만들 필요 없이 사용자 지정 역할 및 해당 권한을 편집할 수 있습니다.

### 사용자 지정 역할을 위한 새로운 권한 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

사용자 지정 역할을 만드는 데 사용할 수 있는 새로운 권한이 있습니다:

- [보안 정책 링크 할당](../../user/custom_roles/abilities.md#security-policy-management)
- [규정 준수 프레임워크 관리 및 할당](../../user/custom_roles/abilities.md#compliance-management)
- [웹후크 관리](../../user/custom_roles/abilities.md#webhooks)
- [푸시 규칙 관리](../../user/custom_roles/abilities.md#source-code-management)

이러한 사용자 정의 권한의 릴리스를 통해 이러한 Owner 동등 권한을 가진 사용자 지정 역할을 생성하여 그룹에서 필요한 Owner의 수를 줄일 수 있습니다. 사용자 지정 역할을 통해 사용자에게 작업을 수행하는 데 필요한 권한만 제공하고 불필요한 권한 상승을 줄일 수 있는 세분화된 역할을 정의할 수 있습니다.

### 자체 관리 인스턴스 수준에서 사용자 지정 역할 관리 {#manage-custom-roles-at-self-managed-instance-level}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11851)

{{< /details >}}

이 릴리스 이전에 자체 관리 GitLab에서 사용자 지정 역할은 그룹 수준에서 만들어야 했습니다. 이는 관리자가 인스턴스에 대한 사용자 지정 역할을 중앙에서 관리할 수 없다는 것을 의미하므로 인스턴스 전체에 중복된 역할이 발생했습니다. 이제 사용자 지정 역할은 자체 관리 인스턴스 수준에서 관리됩니다. 관리자만 사용자 지정 역할을 만들 수 있지만 관리자와 그룹 소유자 모두 이러한 사용자 지정 역할을 할당할 수 있습니다.

기존 사용자 지정 역할, API 엔드포인트 및 워크플로우를 마이그레이션하는 방법에 대한 자세한 내용은 [에픽 11851](https://gitlab.com/groups/gitlab-org/-/epics/11851)을 참조하세요.

이 업데이트는 GitLab.com의 사용자 지정 역할 워크플로우에 영향을 주지 않습니다.

### 사용자 지정 역할에 대한 UX 개선 {#ux-improvements-to-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11947)

{{< /details >}}

사용자 지정 역할의 사용자 경험을 위해 일련의 개선이 이루어졌으며, 특히:

- [새 사용자 지정 역할을 만들 때 새 페이지가 열립니다](https://gitlab.com/gitlab-org/gitlab/-/issues/393238).
- [사용자 지정 역할 테이블의 개선된 디자인](https://gitlab.com/gitlab-org/gitlab/-/issues/437592).
- [사용자 지정 역할 삭제 대화의 개선된 디자인](https://gitlab.com/gitlab-org/gitlab/-/issues/434431).
- [기본 역할의 사전 검사 권한](https://gitlab.com/gitlab-org/gitlab/-/issues/430915).

### 관리자 및 그룹을 위한 향상된 브랜치 보호 설정 {#improved-branch-protection-settings-for-administrators-and-for-groups}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/branches/default.md#for-all-projects-in-an-instance)

{{< /details >}}

이전에는 기본 브랜치 보호 옵션을 설정해도 보호된 브랜치에 대한 설정과 동일한 수준의 구성이 허용되지 않았습니다.

이 릴리스에서 기본 브랜치 보호 설정을 업데이트하여 보호된 브랜치와 동일한 환경을 제공합니다. 이렇게 하면 기본 브랜치 보호에 더 많은 유연성이 생기고 보호된 브랜치 설정에 이미 있는 것과 일치하는 프로세스가 단순화됩니다.

### 정책 봇 주석에 대한 선택적 구성 {#optional-configuration-for-policy-bot-comment}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/scan_execution_policies.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438272)

{{< /details >}}

보안 정책 봇은 머지 리퀘스트가 정책을 위반할 때 주석을 게시하여 사용자가 정책이 프로젝트에 적용되는 시기, 평가가 완료되는 시기, MR을 차단하는 위반이 있는지 파악할 수 있도록 도와주며 해결하기 위한 지침을 제공합니다. 이제 이러한 주석은 선택 사항이며 각 정책 내에서 활성화 또는 비활성화할 수 있습니다. 이를 통해 조직은 이러한 정책에 대해 사용자와 통신하는 방법을 결정할 수 있는 유연성과 제어 기능을 갖게 됩니다.

### 취약성 보고서의 업데이트된 필터링 {#updated-filtering-on-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13339)

{{< /details >}}

취약성 보고서 필터의 이전 구현은 확장 가능하지 않았습니다. 페이지의 가로 공간에 의해 제한되었습니다. 이제 필터링된 검색 구성 요소를 사용하여 상태, 심각도, 도구 또는 활동의 모든 조합으로 취약성 보고서를 필터링할 수 있습니다. 이 변경을 통해 [식별자로 필터링](https://gitlab.com/groups/gitlab-org/-/epics/13340)하는 것과 같은 새로운 필터를 추가할 수 있습니다.

### 머지 리퀘스트 승인 정책을 열기 또는 닫기 실패로 전환 {#toggle-merge-request-approval-policies-to-fail-open-or-fail-closed}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10816)

{{< /details >}}

준수는 조직이 요구 사항을 충족하는 것과 개발자 속도에 영향을 주지 않는 것 사이의 균형을 맞추려고 하기 때문에 많은 조직에서 슬라이딩 척도로 작동합니다. 머지 리퀘스트 승인 정책은 DevSecOps 워크플로우(즉, 머지 리퀘스트)의 중심에서 보안 및 규정 준수를 운영하는 데 도움이 됩니다. 정책 집행에 대한 전환을 완화하려는 팀에 유연성을 제공하기 위해 머지 리퀘스트 승인 정책에 대한 새로운 `fail open` 옵션을 도입하고 있습니다.

머지 리퀘스트 승인 정책이 열기 실패로 구성되면 MR은 정책 규칙이 위반 **그리고** 해당 프로젝트에 보안 분석기가 제대로 구성된 경우에만 차단됩니다. 분석기가 프로젝트에 대해 활성화되지 않았거나 분석기가 결과를 성공적으로 생성하지 못하는 경우 정책은 더 이상 지정된 규칙 및 분석기에 대한 위반으로 간주되지 않습니다. 이 접근 방식은 팀이 적절한 스캔 실행 및 강제를 보장하기 위해 노력하면서 정책의 점진적 롤아웃을 허용합니다.

### 확인되지 않은 보조 이메일 주소 자동 삭제 {#automatic-deletion-of-unverified-secondary-email-addresses}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#delete-email-addresses-from-your-user-profile) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/367823)

{{< /details >}}

사용자 프로필에 보조 이메일 주소를 추가하고 확인하지 않으면 해당 이메일 주소는 이제 3일 후 자동으로 삭제됩니다. 이전에는 이러한 이메일 주소가 예약된 상태에 있었으며 수동 개입 없이 해제할 수 없었습니다. 이 자동 삭제는 관리자 오버헤드를 줄이고 사용자가 소유하지 않은 이메일 주소를 예약하는 것을 방지합니다.

### 오류가 있는 패키지에 대한 패키지 레지스트리 UI 필터링 {#filter-package-registry-ui-for-packages-with-errors}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/package_registry/_index.md#view-packages) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

GitLab 패키지 레지스트리를 사용하여 패키지를 게시하고 다운로드할 수 있습니다. 때때로 패키지가 오류로 인해 업로드에 실패합니다. 이전에는 업로드에 실패한 패키지를 빠르게 보는 방법이 없었습니다. 이로 인해 조직의 패키지 레지스트리의 전체 보기를 얻기가 어려워졌습니다.

이제 업로드에 실패한 패키지에 대해 패키지 레지스트리 UI를 필터링할 수 있습니다. 이 개선 기능은 발생하는 모든 이슈를 조사하고 해결하는 것을 더 쉽게 만듭니다.

### Value Streams Dashboard의 새로운 중앙값 병합 시간 메트릭 {#new-median-time-to-merge-metric-in-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435451)

{{< /details >}}

Value Streams Dashboard에 새로운 메트릭을 추가했습니다: 중앙값 병합 시간. GitLab에서 이 메트릭은 머지 리퀘스트가 생성되었을 때와 병합되었을 때 사이의 중앙값 시간을 나타냅니다. 이 새로운 메트릭은 머지 리퀘스트와 코드 검토 프로세스의 효율성과 생산성을 식별하여 DevOps 상태를 측정합니다.

[다른 SDLC 메트릭의 컨텍스트](https://www.youtube.com/watch?v=yNZRac7gyYo)에서 이 메트릭이 어떻게 발전하는지 분석함으로써 팀은 낮은 또는 높은 생산성 월을 식별하고, 개발 속도 및 제공 프로세스에 대한 새로운 DevOps 관행의 영향을 이해하고, 전체 리드 타임을 줄이고, 소프트웨어 제공의 속도를 높일 수 있습니다.

### 제품 팀으로 확장된 설계 관리 기능 {#design-management-features-extended-to-product-teams}

<!-- categories: Design Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/issues/design_management.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438829)

{{< /details >}}

GitLab은 권한을 업데이트하여 협업을 확대하고 있습니다. 이제 Reporter 역할을 가진 사용자가 설계 관리 기능에 액세스할 수 있으므로 제품 팀이 설계 프로세스에 더 직접 참여할 수 있습니다. 이 변경은 워크플로우를 단순화하고 조직 전체의 광범위한 참여를 초대하여 혁신을 가속화합니다.

### 향상된 에픽 삭제 보호 {#enhanced-epic-deletion-protection}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/manage_epics.md#delete-an-epic) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)

{{< /details >}}

에픽을 삭제할 때 발생하는 상황을 업데이트하여 프로젝트의 구조와 데이터를 더 잘 보호했습니다. 프로젝트를 관리하면서 더 많은 제어와 마음의 평안을 주는 것입니다.

이제 상위 에픽을 삭제할 때 모든 자식 레코드를 자동으로 삭제하는 대신 먼저 상위 관계를 분리하여 보존합니다. 이 변경은 에픽을 관리하는 더 안전한 방법을 제공하며 우발적인 삭제로 인해 귀중한 정보가 손실되지 않도록 합니다.

### 생성 날짜, 마지막 업데이트 날짜 및 제목별로 로드맵 정렬 {#sort-the-roadmap-by-created-date-last-updated-date-and-title}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/roadmap/_index.md#sort-and-filter-the-roadmap) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/460492)

{{< /details >}}

로드맵 보기에서 사용 가능한 에픽 정렬 옵션을 확대하여 프로젝트 정렬 및 우선 순위 지정에 더 많은 유연성을 제공합니다. 이제 에픽을 **created date**, **last updated date**, **title**로 정렬할 수 있습니다. 이 개선은 향후 에픽을 더 동적으로 관리하는 데 도움이 되는 더욱 고급 정렬 기능을 위한 토대를 마련합니다.

### Value Streams Dashboard의 단순화된 구성 파일 스키마 {#simplified-configuration-file-schema-for-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md#customize-dashboard-panels) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/432185)

{{< /details >}}

이제 단순화된 스키마 기반 사용자 지정 가능한 UI 프레임워크를 사용하여 Value Streams Dashboard 패널을 사용자 지정할 수 있습니다. 새로운 형식에서 필드는 데이터를 표시하고 대시보드 패널을 배치할 수 있는 더 많은 유연성을 제공합니다. 새 프레임워크를 사용하면 관리자는 대시보드의 변경 사항을 시간별로 추적할 수 있습니다. 이 버전 기록은 이전 버전으로 되돌리고 대시보드 버전 간의 변경 사항을 비교하는 데 도움이 될 수 있습니다.

이 사용자 지정을 사용하면 의사 결정권자는 비즈니스에 가장 관련 있는 정보에 집중할 수 있으며 팀은 주요 DevSecOps 메트릭을 더 잘 정렬하고 표시할 수 있습니다.

### 그룹의 게스트가 이슈 링크 가능 {#guests-in-groups-can-link-issues}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/permissions.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10267)

{{< /details >}}

Reporter에서 Guest로 이슈 및 작업과 관련시키기 위해 필요한 최소 역할을 줄였습니다. 이제 [권한](../../user/permissions.md)을 유지하면서 GitLab 인스턴스 전체에서 작업을 정렬할 수 있는 더 많은 유연성을 제공합니다.

### 이슈 보드에 표시되는 마일스톤 및 반복 {#milestones-and-iterations-visible-on-issue-boards}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/issue_board.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/25758)

{{< /details >}}

프로젝트의 타임라인 및 단계에 대한 더 명확한 통찰력을 제공하도록 이슈 보드를 개선했습니다. 이제 이슈 카드에 마일스톤 및 반복 세부 정보가 직접 표시되므로 진행 상황을 쉽게 추적하고 팀의 작업을 즉시 조정할 수 있습니다. 이 개선은 계획 및 실행을 더 효율적으로 만들기 위해 설계되었으며 루프에 머물러 있고 일정보다 앞서 있습니다.

### API 보안 테스팅 분석기 업데이트 {#api-security-testing-analyzer-updates}

<!-- categories: API Security -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/api_security_testing/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/13644)

{{< /details >}}

17.0 릴리스 마일스톤 동안 다음 API 보안 테스트 분석기 업데이트를 게시했습니다:

- 시스템 환경 변수는 이제 CI 러너에서 특정 고급 시나리오(예: 요청 서명)에 사용되는 사용자 지정 Python 스크립트로 전달됩니다. 이렇게 하면 이러한 시나리오를 구현하기가 더 쉬워집니다. 자세한 내용은 [이슈 457795](https://gitlab.com/gitlab-org/gitlab/-/issues/457795)를 참조하세요.
- API 보안 컨테이너는 이제 루트가 아닌 사용자로 실행되므로 유연성과 준수가 향상됩니다. 자세한 내용은 [이슈 287702](https://gitlab.com/gitlab-org/gitlab/-/issues/287702)를 참조하세요.
- TLSv1.3 암호만 제공하는 서버 지원으로 더 많은 고객이 API 보안 테스트를 채택할 수 있습니다. 자세한 내용은 [이슈 441470](https://gitlab.com/gitlab-org/gitlab/-/issues/441470)을 참조하세요.
- Alpine 3.19로 업그레이드하여 보안 취약성을 해결합니다. 자세한 내용은 [이슈 456572](https://gitlab.com/gitlab-org/gitlab/-/issues/456572)를 참조하세요.

[이전에 발표](../../update/deprecations.md#secure-analyzers-major-version-update)했듯이 [API 보안 테스트의 주요 버전 번호를 버전 5로 증가](https://gitlab.com/gitlab-org/gitlab/-/issues/456874)했습니다. GitLab 17.0에서.

### Android에 대한 종속성 검사 지원 {#dependency-scanning-support-for-android}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#use-cicd-components) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12968)

{{< /details >}}

종속성 검사 사용자는 이제 Android 프로젝트를 검사할 수 있습니다. Android 검사를 구성하려면 [CI/CD 카탈로그 구성 요소](https://gitlab.com/explore/catalog/components/android-dependency-scanning)를 사용하세요. Android 검사는 [CI/CD 템플릿](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#edit-the-gitlab-ciyml-file-manually)의 사용자도 지원됩니다.

### 종속성 검사 기본 Python 이미지 {#dependency-scanning-default-python-image}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/441491)

{{< /details >}}

Python 3.9가 기본 Python 이미지로 더 이상 사용되지 않으면서 Python 3.11이 이제 기본 이미지입니다.

[더 이상 사용되지 않는 공지](../../update/deprecations.md#deprecate-python-39-in-dependency-scanning-and-license-scanning)에 설명된 대로 새 기본 Python 버전의 대상은 3.10이었습니다. Python 3.11로의 직접 이동은 FIPS 준수를 보장하기 위해 필요했습니다.

### DAST는 이제 기본적으로 arm64 및 amd64 아키텍처를 모두 지원 {#dast-now-supports-both-arm64-and-amd64-architectures-by-default}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/13757)

{{< /details >}}

DAST 5는 기본적으로 arm64 및 amd64 아키텍처를 모두 지원합니다. 이를 통해 고객은 러너 호스트 아키텍처를 선택하고 비용 절감을 최적화할 수 있습니다.

### 더 많은 언어에 대한 간소화된 SAST 분석기 범위 {#streamlined-sast-analyzer-coverage-for-more-languages}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)

{{< /details >}}

GitLab Static Application Security Testing(SAST)는 이제 [언어](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)를 더 적은 [분석기](../../user/application_security/sast/analyzers.md)로 검사하여 더 단순하고 사용자 지정 가능한 검사 경험을 제공합니다.

GitLab 17.0에서 언어별 분석기를 다음 언어의 [GitLab 관리 규칙](../../user/application_security/sast/rules.md)으로 [Semgrep 기반 분석기](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)에 교체했습니다:

- Android
- C 및 C++
- iOS
- Kotlin
- Node.js
- PHP
- Ruby

[발표](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)했듯이 새로운 검사 범위를 반영하고 더 이상 사용하지 않는 언어별 분석기 작업을 제거하도록 [SAST CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)을 업데이트했습니다.

### 비밀 검사는 이제 규칙을 재정의하거나 비활성화할 때 원격 규칙 집합을 지원 {#secret-detection-now-supports-remote-rulesets-when-overriding-or-disabling-rules}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425251)

{{< /details >}}

원격 규칙 집합에 영향을 준 비밀 검사 버그를 해결했습니다. 이제 원격 규칙 집합을 통해 규칙을 재정의하거나 비활성화할 수 있습니다. 원격 규칙 집합은 한 곳에서 규칙을 구성하는 확장 가능한 방법을 제공하며 여러 프로젝트에 적용할 수 있습니다.

### 비밀 검사에 대한 고급 취약성 추적 도입 {#introducing-advanced-vulnerability-tracking-for-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/pipeline/_index.md#duplicate-vulnerability-tracking) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)

{{< /details >}}

비밀 검사는 이제 고급 취약성 추적 알고리즘을 사용하여 리팩토링 또는 관련 없는 변경으로 인해 동일한 비밀이 파일 내에서 이동한 시기를 더 정확하게 식별합니다. 새로운 결과는 다음의 경우 더 이상 생성되지 않습니다:

- 누수가 파일 내에서 이동합니다.
- 동일한 파일 내에 동일한 값의 새 누수가 나타납니다.

그렇지 않으면 기존 워크플로우(머지 리퀘스트 위젯, 파이프라인 보고서 및 취약성 보고서)는 이전과 동일한 결과를 처리합니다. 중복 취약성이 보고되지 않도록 보장함으로써 팀은 유출된 비밀을 더 쉽게 관리할 수 있습니다.

### 게시된 CI/CD 구성 요소의 의미 있는 버전 범위 {#semantic-version-ranges-for-published-cicd-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/components/_index.md#semantic-versioning) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/450835)

{{< /details >}}

CI/CD 카탈로그 구성 요소를 사용할 때 자동으로 최신 버전을 사용할 수 있습니다. 예를 들어 사용하는 모든 구성 요소를 수동으로 모니터링하고 사소한 업데이트 또는 보안 패치가 있을 때마다 다음 버전으로 수동으로 전환할 필요는 없습니다. 그러나 `~latest`을 사용하는 것은 약간의 위험이 있습니다. 사소한 버전 업데이트로 인해 원하지 않는 동작 변경이 발생할 수 있고 주요 버전 업데이트는 주요 변경으로 위험이 더 높기 때문입니다.

이 릴리스를 통해 CI/CD 구성 요소의 최신 주요 또는 부 버전을 사용할 수 있습니다. 예를 들어 구성 요소 버전에 `2`을 지정하면 `2.1.1`, `2.1.2`, `2.2.0`와 같은 해당 주요 버전의 모든 업데이트가 제공되지만 `3.0.0`은 제공되지 않습니다. `2.1`을 지정하면 `2.1.1`, `2.1.2`과 같은 해당 부 버전의 패치 업데이트만 받을 수 있지만 `2.2.0`은 받을 수 없습니다.

### 표준화된 CI/CD 카탈로그 구성 요소 게시 프로세스 {#standardized-cicd-catalog-component-publishing-process}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/components/_index.md#publish-a-new-release) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/442066)

{{< /details >}}

CI/CD 구성 요소에서 CI/CD 카탈로그로 구성 요소를 출시하는 프로세스를 일관된 경험으로 만드는 것을 포함하여 CI/CD 구성 요소에 힘을 쏟아왔습니다. 그 일의 일환으로 [`release` 키워드](../../ci/yaml/_index.md#release) 및 `release-cli` 이미지를 사용하여 CI/CD 작업에서 버전을 출시하는 유일한 방법으로 만들었습니다. 릴리스 프로세스의 모든 개선 사항은 이 방법에만 적용됩니다. 이 제한으로 인한 주요 변경 사항을 방지하려면 항상 이미지의 최신 버전(`release-cli:latest`)을 사용하거나 최소한 `v0.17`보다 큰 버전을 사용해야 합니다. UI의 [**릴리스** 옵션](../../user/project/releases/_index.md#create-a-release-in-the-releases-page)은 이제 CI/CD 구성 요소 프로젝트에 대해 비활성화됩니다.

### 취소된 작업에 대해 항상 `after_script` 명령 실행 {#always-run-after_script-commands-for-canceled-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/yaml/script.md#set-a-default-before_script-or-after_script-for-all-jobs) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10158)

{{< /details >}}

[`after_script`](../../ci/yaml/_index.md#after_script) CI/CD 키워드는 `script` 섹션의 기본 후 추가 명령을 실행하는 데 사용됩니다. 이는 종종 작업에 사용된 환경 또는 기타 리소스를 정리하는 데 사용됩니다. 그러나 `after_script` 명령은 작업이 취소되면 실행되지 않았습니다.

GitLab 17.0부터 `after_script` 명령은 작업이 취소될 때 항상 실행됩니다. 탈퇴하려면 [설명서](../../ci/yaml/script.md#skip-after_script-commands-if-a-job-is-canceled)를 참조하세요.

### GitLab Runner 17.0 {#gitlab-runner-170}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

GitLab Runner 17.0도 오늘 출시합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [분리된 네트워크 환경에서 Runner Operator 설치에 대한 설명서](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/123)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-0-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.0)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
