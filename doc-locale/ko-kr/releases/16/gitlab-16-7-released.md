---
stage: Release Notes
group: Monthly Release
date: 2023-12-21
title: "GitLab 16.7 릴리스 정보"
description: "GitLab Duo Code Suggestions이 이제 일반공개되었습니다. 함께 릴리스된 GitLab 16.7"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 12월 21일 GitLab 16.7이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

더 넓은 커뮤니티 성장에 계속 집중하면서, [Core 팀](https://about.gitlab.com/community/core-team/) 멤버들로부터 지명된 두 MVP를 보게 되어 정말 기쁩니다.

Muhammed는 [GitLab Runner에서 Docker 이미지를 사용할 때 플랫폼 지정을 지원](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112907)하는 것을 추가한 공로로 지명되었습니다. 이 기여는 9개월의 협업을 통해 이루어졌으며, 버그 수정이 필요한 [후속 작업](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137100)을 진행할 때 Muhammed의 노력과 끈기를 보여주었습니다. 이는 인기 있던 2년 전 [이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)를 해결했습니다. "GitLab Runner 팀에 큰 감사를 드립니다." Muhammed는 "오랫동안 기다려온 기능을 실현하도록 저를 지원해주셔서 감사합니다"라고 말했습니다. Muhammed는 [Airtime Rewards](https://www.airtimerewards.co.uk/)의 Automation Engineer이며, 주로 Terraform을 사용하며 엔지니어링 팀 내에서 CI/CD 및 자동화 실천을 추진합니다.

Niklas는 계속된 기여와 다양한 형태의 지원으로 지명되었습니다. 오늘은 마지막 MVP 상을 받은 지 정확히 1년이 되는 날입니다. Niklas는 GitLab 팀원들도 어려워하는 도전적인 작업을 해결하며 더 넓은 커뮤니티 기여자를 유지하는 데 큰 역할을 합니다. [지명 이슈](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34762#note_1681021745)에서 더 읽어보세요.

Muhammed와 Niklas, 감사합니다! 🙌

## 주요 기능 {#primary-features}

### GitLab Duo Code Suggestions이 이제 일반공개되었습니다 {#gitlab-duo-code-suggestions-is-generally-available}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/code_suggestions/_index.md)

{{< /details >}}

[GitLab Duo Code Suggestions](https://about.gitlab.com/solutions/code-suggestions/)이 이제 일반공개되었습니다!

GitLab Duo Code Suggestions는 코드의 라인을 완성하고 함수 로직을 정의 및 생성하여 팀이 더 빠르고 효율적으로 소프트웨어를 만들 수 있도록 도와줍니다.

Code Suggestions은 프라이버시를 핵심 기초로 하여 구축되었습니다. GitLab에 저장된 비공개 고객 코드는 학습 데이터로 사용되지 않습니다. Code Suggestions을 사용할 때 [데이터 사용](../../user/gitlab_duo/data_usage.md)에 대해 자세히 알아보세요.

[Code Suggestions을 여러 IDE에서 사용할 수 있습니다](../../user/project/repository/code_suggestions/_index.md). Code Suggestions은 이제 더 직관적이고 반응성이 뛰어납니다.

GitLab Duo Code Suggestions는 2024년 2월 15일까지 [무료로 사용할 수 있으며](../../user/project/repository/code_suggestions/_index.md) [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)을 따릅니다. 오늘부터 Code Suggestions을 GitLab 구독에 추가 기능으로 구매할 수 있으며, 초기 가격은 사용자당 월 $9 USD입니다. Code Suggestions을 시작하려면 [문의해 주세요](https://about.gitlab.com/sales/).

### GitLab Pages를 와일드카드 DNS 없이 사용 {#use-gitlab-pages-without-a-wildcard-dns}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/pages/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)

{{< /details >}}

이전에는 GitLab Pages 프로젝트를 만들려면 name.example.io 또는 name.pages.example.io와 같은 형식의 도메인이 필요했습니다. 이 요구 사항은 와일드카드 DNS 레코드 및 SSL/TLS 인증서를 설정해야 함을 의미했습니다. GitLab 16.7에서는 DNS 와일드카드 없이 GitLab Pages 프로젝트를 설정할 수 있습니다. 이 기능은 실험입니다.

와일드카드 인증서 요구 사항을 제거하면 GitLab Pages와 관련된 관리 오버헤드가 줄어듭니다. 일부 고객은 와일드카드 DNS 레코드 또는 인증서에 대한 조직 제한으로 인해 GitLab Pages를 사용할 수 없습니다.

[이슈 434372](https://gitlab.com/gitlab-org/gitlab/-/issues/434372)에서 이 기능과 관련된 피드백을 환영합니다.

### Insights 보고서 차트에서 새로운 드릴다운 보기 {#new-drill-down-view-from-insights-report-charts}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/insights/_index.md#drill-down-on-charts) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/372215)

{{< /details >}}

[Insights 보고서](https://www.youtube.com/watch?v=OMTfPsLa98I)를 통해 시간에 따른 패턴을 사용자 정의 가능한 차트로 분석할 수 있습니다. "우선 순위별로 작성된 버그" 및 "심각도별로 작성된 버그" Insights 보고서에 추가된 새로운 드릴다운 기능을 통해 더 심도 있는 분석을 위해 [이슈 분석](../../user/group/issues_analytics/_index.md) 보고서를 드릴다운할 수 있습니다.

이 기능을 다른 Insight 보고서에도 나중 버전에서 사용자 정의 옵션으로 포함할 계획입니다.

### MR 변경 보기의 SAST 결과 {#sast-results-in-mr-changes-view}

<!-- categories: SAST -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/application_security/sast/_index.md#merge-request-changes-view) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10959) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/432704)

{{< /details >}}

SAST 발견 사항은 이제 머지 리퀘스트 Changes 보기에 나타납니다. 이를 통해 코드 검토 프로세스 중에 잠재적 약점을 더 쉽게 보고 이해하며 수정할 수 있습니다.

SAST 이슈가 있는 줄은 거터 옆에 기호로 표시됩니다. 기호를 선택하여 이슈 목록을 확인한 후 이슈를 선택하여 세부 정보를 확인합니다.

GitLab.com에서 이 기능을 활성화했습니다. GitLab 16.8에서 Self-Managed 인스턴스를 위해 기본적으로 [기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/410191)를 활성화할 계획입니다.

### CI/CD Catalog - 베타 릴리스 {#cicd-catalog---beta-release}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

GitLab 16.7에서 CI/CD 카탈로그의 베타 릴리스를 제공합니다! 카탈로그는 당신, 당신의 조직 또는 공개 커뮤니티에서 유지 관리하는 [CI/CD 구성 요소](../../ci/components/_index.md)를 검색할 수 있는 곳입니다. 이는 DevOps 엔지니어들이 함께 모여 재사용 가능한 파이프라인 구성을 만들고 기여하며 공유하는 곳입니다.

CI/CD 구성을 재사용하는 다른 방법과 달리, 카탈로그에 게시된 CI/CD 구성 요소는 향상된 경험을 제공하며 파이프라인에 쉽게 추가됩니다. 이 새롭고 흥미로운 기능을 테스트하기 시작하도록 초대합니다! 다른 사람들이 만들고 카탈로그에 공유한 구성 요소를 시도해보거나 자신만의 구성 요소를 만들어 모두와 공유할 수 있습니다.

이것이 초기 베타 릴리스이지만, 경험을 더욱 향상시키기 위해 계속 작업하고 있습니다. 우리의 목표는 CI/CD 카탈로그를 GitLab CI/CD 경험의 기본 부분으로 만드는 것입니다.

## 규모 및 배포 {#scale-and-deployments}

### 사용자 프로필에 Mastodon 핸들 추가 {#add-a-mastodon-handle-to-your-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428442)

{{< /details >}}

이제 사용자 프로필에 Mastodon 핸들을 표시할 수 있습니다. 이 개선을 통해 우리는 이제 페디버스 소셜 네트워크를 지원하고 있으며, 이는 [GitLab용 ActivityPub](https://gitlab.com/groups/gitlab-org/-/epics/11247)을 발전시키는 데 도움이 될 것입니다.

### 그룹 설명을 500자까지 확장 {#group-descriptions-extended-to-500-characters}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416146)

{{< /details >}}

그룹 설명은 이제 최대 500자까지 포함할 수 있습니다. 500자 이상의 그룹 설명을 저장하려고 하면 설명이 너무 길다는 경고 메시지가 나타납니다. 이 커뮤니티 기여에 @freznicek에게 감사드립니다!

### 검색 결과 페이지에서 검색 창이 더 눈에 띄게 {#search-bar-more-prominent-on-the-search-results-page}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424619)

{{< /details >}}

검색 결과 페이지에서 검색 창이 이제 더 눈에 띕니다. 검색 창 표시를 높이기 위해 그룹 및 프로젝트 필터가 왼쪽 사이드바로 이동했습니다.

### 고급 검색에서 코드가 포함된 이슈가 더 잘 발견됨 {#issues-with-code-more-discoverable-in-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/advanced_search.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421012)

{{< /details >}}

GitLab 16.7에서 코드가 포함된 이슈가 더 잘 발견되도록 개선되었습니다. 고급 검색을 통해 이제 설명에 코드 스니펫과 로그가 포함된 이슈를 찾을 수 있습니다.

### 시간 형식 표시 사용자 정의 {#customize-time-format-for-display}

<!-- categories: User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/preferences.md#customize-time-format) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/15206)

{{< /details >}}

지금까지 GitLab은 12시간 형식으로만 시간을 표시했으며 변경할 수 없었습니다.

이 릴리스부터 커뮤니티 기여 덕분에 이슈 목록, 개요 페이지 또는 상태 설정 시와 같이 시간을 표시하는 데 사용되는 형식을 사용자 정의할 수 있습니다. 시간을 다음과 같이 표시할 수 있습니다:

- 12시간 형식 (예: `2:34 PM`).
- 24시간 형식 (예: `14:34`).

이 [Thorben Westerhuys](https://gitlab.com/n0rdlicht)의 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789)에 감사드립니다!

다음 마일스톤에서 GitLab 제품 전체에 표시되는 [모든 타임스탬프를 감사](https://gitlab.com/groups/gitlab-org/-/epics/12215)하여 설정을 존중하도록 만들 계획입니다.

### 왼쪽 사이드바에서 관리 영역 접근 {#access-the-admin-area-from-the-left-sidebar}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/admin_area.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415854)

{{< /details >}}

이제 관리자는 왼쪽 사이드바 하단의 링크를 사용하여 관리 영역에 한 번에 접근할 수 있습니다. 이전에는 **검색 또는 이동**을 선택한 다음 **Admin Area**을 선택해야 했습니다. 이 변경으로 관리 영역 접근 시 시간이 절약됩니다.

### 마이그레이션 완료를 위한 하드코딩된 시간 제한 제거 {#remove-hardcoded-time-limit-for-migrations-to-complete}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/_index.md#limits) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/429867)

{{< /details >}}

직접 전송으로 수행된 GitLab 그룹 및 프로젝트 마이그레이션은 다양한 이유로 인해 고착될 수 있습니다. 이전에는 이러한 마이그레이션이 불완전한 상태로 무한정 남지 않도록 하기 위해 GitLab은 정기적으로 워커를 실행하여 8시간 이내에 완료되지 않은 마이그레이션을 식별했습니다. GitLab은 이러한 마이그레이션을 시간 초과로 표시했습니다.

대규모 조직의 경우 마이그레이션 프로세스는 8시간보다 오래 걸릴 수 있으므로, 마이그레이션이 고착되었는지 올바르게 판단하기에 항상 충분한 시간이 아닙니다. 결과적으로 이 워커가 마이그레이션을 잘못 고착된 것으로 표시할 수 있었습니다.

이 마일스톤에서 8시간 시간 제한을 사용하는 대신 GitLab은 자식 워커가 24시간 동안 작동을 중지한 경우에만 마이그레이션을 고착된 것으로 표시합니다.

### 직접 전송으로 마이그레이션한 포괄적인 결과 {#comprehensive-results-of-imports-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)

{{< /details >}}

사용자가 가져오기 프로세스의 결과를 이해하는 것이 얼마나 중요한지 알고 있으므로, 이 마일스톤에서 직접 전송으로 가져올 때 표시되는 정보를 더욱 개선했습니다. 이제 다음 페이지에서 GitLab 그룹 및 프로젝트 옆에 가져오기 상태 배지를 표시합니다:

- [가져올 그룹 및 프로젝트를 선택할 수 있는 페이지](../../user/group/import/_index.md).
- [가져온 그룹 및 프로젝트를 나열하는 페이지](../../user/group/import/_index.md).

가져오기 상태 배지는 다음과 같습니다:

- **시작되지 않음**
- **대기중**
- **가져오는중**
- **실패함**
- **시간 초과**
- **취소됨**
- **완료**
- **부분적으로 완료됨**

**Partially completed badge**는 이 릴리스에서 추가되었으며 일부 항목(예: 머지 리퀘스트 또는 이슈)이 가져와지지 않은 완료된 가져오기 프로세스를 식별합니다.

가져오기 프로세스가 시작된 그룹에는 특정 그룹의 가져온 하위 그룹 및 프로젝트를 표시하는 **상세 보기** 링크가 있습니다. 거기에서 **See failures** 링크를 클릭하여 가져올 수 없었던 항목 목록을 볼 수 있습니다(있는 경우). **See failures**는 [지난 릴리스에서 릴리스되었습니다](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#comprehensive-list-of-items-that-failed-to-be-imported).

이 마일스톤에서 이러한 페이지 간의 이동 경로를 사용한 네비게이션도 개선했습니다.

### 외부 참가자가 댓글을 달 때 Service Desk 이슈 다시 열기 {#reopen-service-desk-issues-when-an-external-participant-comments}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/service_desk/configure.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/8549)

{{< /details >}}

이제 외부 참가자가 이메일로 이슈에 새로운 댓글을 추가할 때 종료된 이슈를 다시 열도록 GitLab을 설정할 수 있습니다. 이를 통해 이슈가 해결된 후에도 진행 중인 대화를 완전히 볼 수 있습니다.

또한 이슈 담당자를 언급하는 내부 댓글을 추가하고 그들을 위한 할 일 항목을 만듭니다. 이렇게 하면 후속 이메일을 놓치지 않을 수 있습니다.

### 백업이 대체 압축 라이브러리를 지원 {#backups-supports-alternate-compression-libraries}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/backup_restore/backup_gitlab.md#backup-compression)

{{< /details >}}

이제 `COMPRESS_CMD` 및 `DECOMPRESS_CMD` 명령을 사용하여 백업에 대해 기본 단일 스레드 gzip 압축 라이브러리를 선택한 대체 압축 라이브러리로 재정의할 수 있습니다. 이를 통해 최신 멀티코어 프로세서의 성능을 활용하여 백업의 압축 단계를 가속화할 수 있는 병렬 압축 라이브러리를 활용할 수 있습니다. 명령은 압축 라이브러리에 옵션을 전달하는 것을 지원하므로 압축 수준 및 속도와 같은 매개변수를 조정할 수 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 송신 규칙이 있는 네트워크 정책 정의 {#define-a-network-policy-with-egress-rules}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

GitLab 16.7에서는 이제 Workspaces를 지원하기 위해 Kubernetes용 GitLab 에이전트를 구성할 때 송신 규칙이 있는 네트워크 정책을 정의할 수 있습니다. GitLab 인스턴스가 프라이빗 IP로 해석되거나 워크스페이스가 프라이빗 IP 범위의 클라우드 리소스에 접근해야 하는 자체 호스팅 설치에 이 기능을 사용하세요.

### 그룹에 사용자 정의 이모지 추가 {#add-custom-emoji-to-groups}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/emoji_reactions.md)

{{< /details >}}

자신을 표현할 좋은 이모지를 싫어하는 사람이 있을까요? GitLab 전체에서 항목에 댓글을 달 때 기본 이모지 세트를 사용하여 반응을 추가했지만, 때로는 그 이모지만으로는 감정을 표현하기에 충분하지 않았습니다. 그룹은 이제 프로젝트 전체에서 사용할 사용자 정의 이모지를 추가할 수 있습니다. 사용자 정의 이모지를 사용하면 자신의 감정을 표현하고 팀의 나머지 사람들과 더 명확하게 소통할 수 있습니다. 다음에 어떻게 반응할지 정말 기대됩니다.

### 복잡한 머지 리퀘스트 종속성 체인이 이제 지원됨 {#complex-merge-request-dependency-chains-now-supported}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/dependencies.md#nested-dependencies)

{{< /details >}}

GitLab 머지 리퀘스트 종속성은 다른 변경 사항에 의존하는 코드 변경 사항이 코드베이스를 손상시킬 수 있는 방식으로 병합되지 않도록 하는 훌륭한 방법입니다. 이전에는 GitLab이 복잡한 종속성 체인을 허용하지 않았으며, 이는 순환 참조나 깊은 중첩을 야기할 수 있었습니다.

종속성 계층 및 체인의 항목 주변 제한 사항이 제거되었습니다. 머지 리퀘스트 종속성은 이제 더 복잡할 수 있습니다: 단일 머지 리퀘스트는 최대 10개의 머지 리퀘스트에 의해 차단될 수 있으며, 차례로 최대 10개의 다른 머지 리퀘스트를 차단할 수 있습니다. 더 깊은 종속성 체인을 통해 더 복잡한 워크플로우를 종속성을 통해 나타낼 수 있습니다. 이 기능의 사용을 계속 확장하는 방식을 보는 것에 기대가 됩니다.

### 머지 리퀘스트가 승인이 필요할 때 알림 받기 {#notify-me-when-any-merge-request-needs-approval}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/profile/notifications.md#edit-notification-settings)

{{< /details >}}

머지 리퀘스트에 대한 승인이 필요할 때, 조치를 취하도록 알림을 받아야 합니다. 일부 사용자는 승인이 필요할 때만 알림을 원하며, 이는 일반적으로 변경 사항을 검토하기 위해 사용자를 이름으로 추가하여 수행됩니다. 그러나 일부 사용자는 승인할 수 있는 모든 머지 리퀘스트에 대한 알림을 원하며, *검토자로 이름으로 추가되지 않은 경우에도 마찬가지입니다.*

**Added as approver** 사용자 정의 알림 수준을 활성화하여 승인할 수 있는 각 머지 리퀘스트에 대해 이메일과 할 일 항목을 트리거하세요. 이를 통해 머지 리퀘스트를 더 빨리 인식하고 제안을 병합하도록 조치를 취할 수 있습니다.

### OpenTofu에 대한 베타 지원 {#beta-support-for-opentofu}

<!-- categories: Infrastructure as Code -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/infrastructure/iac/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/terraform-images/-/issues/114)

{{< /details >}}

Terraform에서 OpenTofu로 전환하는 경우, 이 GitLab 릴리스는 OpenTofu에 대한 예비 지원을 추가합니다. OpenTofu는 Terraform의 포크이기 때문에 MR 위젯 통합, 모듈 레지스트리 및 GitLab 관리 Terraform 상태가 기본적으로 작동합니다. GitLab IaC 제공 사용을 단순화하기 위해 `gitlab-terraform` 헬퍼 이미지에서 OpenTofu 지원을 추가했습니다.

GitLab은 계속해서 MR 위젯, 모듈 레지스트리 및 GitLab 관리 Terraform 상태에 대해 Terraform을 지원합니다.

### 액세스 토큰 회전을 위한 사용자 정의 기간 {#custom-time-period-for-access-tokens-rotation}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/personal_access_tokens.md#rotate-a-personal-access-token) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)

{{< /details >}}

이제 액세스 토큰을 회전할 때 `expires_at` 매개변수를 선택적으로 입력할 수 있습니다. 이를 통해 토큰에 대한 사용자 정의 만료 날짜를 만들 수 있습니다. 이전에는 각 회전이 만료를 이전 만료 날짜에서 1주일 연장했습니다. 이 새로운 옵션은 회전 간격에 유연성을 제공합니다.

### UI를 사용하여 사용자를 사용자 지정 역할에 할당 {#use-the-ui-to-assign-users-to-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/393239)

{{< /details >}}

이제 UI를 사용하여 사용자 지정 역할을 새 사용자에게 할당하거나 기존 사용자의 역할을 사용자 지정 역할로 변경할 수 있습니다. 현재 사용자의 역할을 할당하거나 변경할 수 있는 UI의 모든 부분에서 이 작업을 수행할 수 있습니다. 이전에는 API를 통해서만 이 작업을 수행할 수 있었습니다.

### Scan Execution 정책에서 변수를 최고 우선순위로 적용 {#enforce-variables-in-scan-execution-policies-with-the-highest-precedence}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/variables/_index.md#cicd-variable-precedence) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)

{{< /details >}}

CI/CD 변수 우선순위가 개선되어 스캔 실행 정책에 정의된 변수를 먼저 우선시합니다.

조직이 규정 준수 요구 사항을 충족하기 위해 노력할 때, 비즈니스 중요 애플리케이션에서 보안 스캐너가 활성화되도록 하는 것이 일반적인 필요입니다.

스캔 실행 정책은 팀이 스캐너를 적용하고 기본 및 사용자 정의 CI/CD 변수를 정의할 수 있도록 합니다. 이 CI/CD 변수 우선순위 개선으로 팀은 파이프라인이 어떻게 트리거되든 규정 준수를 고려하여 정의된 변수가 손상되지 않음을 확신할 수 있습니다.

### SAML 특성 명령문이 Microsoft SAML 특성 형식을 지원 {#saml-attribute-statements-support-microsoft-saml-attribute-format}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/saml.md#configure-assertions) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/420766)

{{< /details >}}

SAML 특성 명령문은 이제 URL 형식의 Microsoft SAML 특성 형식을 지원합니다. 이전에는 자체 관리 인스턴스 관리자가 특성 명령문을 수동으로 구성해야 했으며, GitLab.com 그룹 소유자는 SAML 응답에 사용자 정의 특성을 추가해야 했습니다. 이 변경으로 자체 관리 GitLab과 GitLab.com 모두 수동 구성 없이 Microsoft와 함께 작동할 수 있습니다.

### 리치 텍스트 편집기의 개선 사항 {#improvements-to-rich-text-editor}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/rich_text_editor.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136437)

{{< /details >}}

GitLab 16.2에서 리치 텍스트 편집기를 기존 Markdown 편집 환경의 대안으로 릴리스했습니다. 리치 텍스트 편집기는 "보는 것이 얻는 것" 편집 경험과 다이어그램, 콘텐츠 임베드, 미디어 관리 등의 사용자 정의 편집 인터페이스를 구축할 수 있는 확장 가능한 기초를 제공합니다.

GitLab 16.7에서는 리치 텍스트 편집기를 Markdown 편집 경험과 일치하도록 변경하고 보고된 버그를 수정했습니다. Markdown과 리치 텍스트 편집기 간 일관성을 위해 [레이블 자동완성 모달의 정렬 순서를 변경하고](https://gitlab.com/gitlab-org/gitlab/-/issues/419097), [리치 텍스트 편집기의 할당 해제 빠른 작업에서 반환된 옵션의 버그를 해결하고](https://gitlab.com/gitlab-org/gitlab/-/issues/420344), [사용자 정의 이모지 지원을 추가](https://gitlab.com/gitlab-org/gitlab/-/issues/422958)하고, [두 편집 환경에서 일관성을 위해 빠른 작업 선택 드롭다운의 모양과 느낌을 업데이트](https://gitlab.com/gitlab-org/gitlab/-/issues/406714)했으며, 기타 개선 사항이 있습니다.

### 새로운 Container Registry API를 사용한 리포지토리 태그 나열 {#list-repository-tags-with-new-container-registry-api}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../api/container_registry.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/411387)

{{< /details >}}

이전에는 Container Registry가 GitLab에서 태그를 나열하고 표시하기 위해 Docker/OCI [이미지 태그 나열 레지스트리 API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags)에 의존했습니다. 이 API는 상당한 성능 및 검색 용이성 제한이 있었습니다.

이 API는 레지스트리에 대한 네트워크 요청 수가 태그 목록의 태그 수에 따라 확대되기 때문에 느리게 작동했습니다. 또한 API가 게시 시간을 추적하지 않았기 때문에 게시된 타임스탐프는 종종 잘못되었습니다. Docker 매니페스트 목록이나 OCI 인덱스(예: 다중 아키텍처 이미지)를 기반으로 이미지를 표시할 때도 제한이 있었습니다.

이러한 제한을 해결하기 위해 새로운 레지스트리 [리포지토리 태그 나열 API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags)를 도입했습니다. 새 API를 사용하도록 사용자 인터페이스를 업데이트하면 Container Registry에 대한 요청 수가 1개로만 줄어듭니다. 게시 타임스탬프도 정확하며 다중 아키텍처 이미지에 더 강력한 지원이 있습니다.

이 기능은 GitLab.com에서만 사용할 수 있습니다. 자체 관리 지원은 차세대 Container Registry가 일반 공개될 때까지 차단됩니다. 자세히 알아보려면 [이슈 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)를 참조하세요.

### GitLab.com의 Container Registry에서 컨테이너 이미지가 있는 프로젝트 이름 변경 {#rename-projects-with-container-images-in-the-container-registry-on-gitlabcom}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 링크: [설명서](../../user/project/working_with_projects.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10433)

{{< /details >}}

이 릴리스 이전에는 하나 이상의 태그가 있는 컨테이너 리포지토리가 있는 프로젝트의 이름을 변경할 수 없었습니다. 먼저 그 프로젝트와 연결된 모든 컨테이너 이미지를 삭제해야 했습니다.

이는 사용자가 다른 프로젝트 이름을 사용하기 전에 모든 태그를 수동으로 삭제/이동하기 위해 사용자 정의 스크립트에 의존하도록 강요하는 실제 문제였지만, 이제 GitLab.com에서 프로젝트의 이름을 변경할 수 있으며, 레지스트리에 컨테이너 이미지가 있더라도 마찬가지입니다!

### Value Stream Analytics에서 사전 정의된 날짜 범위로 필터링 {#filter-by-predefined-date-ranges-in-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/value_stream_analytics/_index.md#data-filters) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/408656)

{{< /details >}}

이제 Value Stream Analytics 보고서는 지난 30, 60, 90 또는 180일 동안의 데이터에 대한 필터 옵션 세트를 가지고 있습니다. 이러한 새로운 필터 옵션은 날짜 선택 프로세스를 단순화하여 [개발 수명 주기 중 시간이 어디에 소요되는지](https://about.gitlab.com/blog/value-stream-total-time-chart/) 이해하기 더 효율적이고 사용자 친화적으로 만듭니다.

### Dependency Scanning을 위한 Continuous Vulnerability Scanning 지원 {#support-for-continuous-vulnerability-scanning-for-dependency-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/continuous_vulnerability_scanning/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11474)

{{< /details >}}

Continuous Vulnerability Scanning은 이제 일반 공개되었습니다. CVS가 활성화되면 권고 사항이 GitLab 권고 데이터베이스에 추가될 때 프로젝트가 자동으로 검사됩니다. 새로운 종속성 관련 취약성이 식별되면 취약성이 자동으로 생성됩니다.

### DAST 취약성 검사 업데이트 {#dast-vulnerability-check-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

16.7 릴리스 마일스톤 동안 브라우저 기반 DAST에 대해 다음 활성 검사를 기본적으로 활성화했습니다:

- 검사 89.1은 ZAP 검사 40018, 40019, 40020, 40021, 40022, 40024, 40027, 40033 및 90018을 대체하며 SQL 삽입을 식별합니다.
- 검사 918.1은 ZAP 검사 40046을 대체하며 Server Side Request Forgery를 식별합니다.
- 검사 98.1은 ZAP 검사 7을 대체하며 PHP Remote File Inclusion을 식별합니다.
- 검사 917.1은 ZAP 검사 90025를 대체하며 Expression Language Injection을 식별합니다.
- 검사 1336.1은 ZAP 검사 90035를 대체하며 Server-Side Template Injection을 식별합니다.

### DAST 인증이 이제 다단계 로그인 양식을 지원 {#dast-authentication-now-supports-multi-step-login-forms}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/browser/configuration/authentication.md#configuration-for-a-multi-step-login-form) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11585)

{{< /details >}}

새로운 `DAST_AFTER_LOGIN_ACTIONS` 변수를 통해 로그인 후 실행할 작업 목록을 제공할 수 있습니다. 이를 통해 Azure AD의 "로그인 유지" 워크플로우와 같은 다단계 로그인 상호작용을 할 수 있습니다.

### 거짓 양성 결과를 줄이기 위해 SAST 규칙 업데이트 {#updated-sast-rules-to-reduce-false-positive-results}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/rules.md#important-rule-changes) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8170)

{{< /details >}}

GitLab SAST에서 사용되는 기본 규칙 집합을 업데이트하여 더 높은 품질의 결과를 제공합니다. 이전에 기본적으로 포함된 각 규칙을 분석한 다음 대부분의 코드베이스에서 충분한 값을 제공하지 않는 규칙을 제거했습니다.

규칙 변경 사항은 Semgrep 기반 GitLab SAST [분석기](../../user/application_security/sast/analyzers.md)의 업데이트된 버전에 포함됩니다. 이 업데이트는 SAST 분석기를 특정 버전으로 [고정](../../user/application_security/sast/_index.md)하지 않는 한 GitLab 16.0 이상에서 자동으로 적용됩니다.

제거된 규칙의 기존 검사 결과는 업데이트된 분석기로 검사를 실행한 후 [자동으로 해결](../../user/application_security/sast/_index.md#automatic-vulnerability-resolution)됩니다.

[에픽 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)에서 더 많은 SAST 규칙 개선을 진행 중입니다.

### `artifacts:public` CI/CD 키워드가 이제 일반공개됨 {#artifactspublic-cicd-keyword-now-generally-available}

<!-- categories: Job Artifacts -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#artifactspublic) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11667)

{{< /details >}}

이전에는 `artifacts:public` 키워드가 자체 관리 인스턴스에 대해서만 기본적으로 비활성화된 기능으로만 사용 가능했습니다. 이제 GitLab 16.7에서는 `artifacts:public` 키워드를 모든 사용자가 일반 공개적으로 사용할 수 있도록 했습니다. 이제 CI/CD 구성 파일에서 `artifacts:public` 키워드를 사용하여 작업 아티팩트를 공개적으로 액세스할 수 있는지 여부를 제어할 수 있습니다.

### 최신 작업 아티팩트를 유지하는 향상된 기능 {#improved-ability-to-keep-the-latest-job-artifacts}

<!-- categories: Job Artifacts -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428408)

{{< /details >}}

GitLab 13.0에서는 가장 최근의 성공한 파이프라인에서 작업 아티팩트를 유지하는 기능을 도입했습니다. 불행히도, 이 기능은 또한 모든 [실패한](https://gitlab.com/gitlab-org/gitlab/-/issues/266958) 및 [차단된](https://gitlab.com/gitlab-org/gitlab/-/issues/387087) 파이프라인을 가장 최근의 파이프라인이든 아니든 관계없이 최신 파이프라인으로 표시했습니다. 이로 인해 저장소의 아티팩트가 축적되어 수동으로 삭제해야 했습니다.

GitLab 16.7에서 이 의도하지 않은 동작을 유발하는 버그가 해결되었습니다. 실패한 파이프라인과 차단된 파이프라인의 작업 아티팩트는 가장 최근 파이프라인에서만 유지되며, 그렇지 않으면 `expire_in` 구성을 따릅니다. 영향을 받은 GitLab.com 고객은 의도하지 않게 유지되던 아티팩트가 이제 잠금이 해제되고 새 파이프라인 실행 후 제거되는 것을 볼 수 있습니다.

**가장 최근에 성공한 작업의 아티팩트 유지** 설정은 작업의 `artifacts: expire_in` 구성을 재정의하며 만료 없이 많은 아티팩트가 저장될 수 있습니다. 파이프라인이 많은 대용량 아티팩트를 생성하면 프로젝트 저장소 할당량을 빠르게 채울 수 있습니다. 이 기능이 필요하지 않은 경우 이 설정을 비활성화하는 것을 권장합니다.

### GitLab Runner 16.7 {#gitlab-runner-167}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

또한 오늘 GitLab Runner 16.7을 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [Docker executor를 위한 우아한 종료 구현](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Kubernetes를 위한 저장소 클래스를 사용하여 PVC 볼륨을 동적으로 생성](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)

#### 버그 수정 {#bug-fixes}

- [allow_failure:exit codes는 사용자 정의 executor와 함께 사용할 수 없음 (exit code는 항상 1)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28658)
- [Kubernetes executor를 위한 runner helper 및 빌드 컨테이너의 신호 처리 개선](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36996)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-7-stable/CHANGELOG.md)에 있습니다.

### GitLab Runner가 SLSA v1.0 명령문을 지원 {#gitlab-runner-supports-slsa-v10-statement}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/runners/configure_runners.md#artifact-provenance-metadata) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36869)

{{< /details >}}

이제 러너는 [SLSA 1.0](https://slsa.dev/spec/v1.0/)을 준수하는 명령문으로 provenance 메타데이터를 생성할 수 있습니다. SLSA 1.0을 활성화하려면 `SLSA_PROVENANCE_SCHEMA_VERSION=v1` 파일에서 `.gitlab-ci.yml` 변수를 설정하세요. SLSA 버전 1.0 명령문은 GitLab 17.0에서 기본 버전이 될 계획입니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.7)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
