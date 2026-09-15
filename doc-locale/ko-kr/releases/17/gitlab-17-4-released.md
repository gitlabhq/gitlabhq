---
stage: Release Notes
group: Monthly Release
date: 2024-09-19
title: "GitLab 17.4 릴리스 정보"
description: "더 많은 컨텍스트를 인식하는 GitLab Duo 코드 제안으로 GitLab 17.4 릴리스됨(오픈 탭 사용)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 9월 19일에 GitLab 17.4가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Archish Thakkar {#this-months-notable-contributor-archish-thakkar}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Archish Thakkar는 올해 GitLab의 최고 기여자 중 한 명으로 [종료된 46개 이슈](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_date&state=closed&assignee_username%5B%5D=archish27&first_page_size=100) 및 [병합된 119개의 MR](https://gitlab.com/groups/gitlab-org/-/merge_requests?assignee_username%5B%5D=archish27&first_page_size=100&sort=created_date&state=merged)을 보유하고 있습니다. 이러한 기여로 Archish는 지난 두 번의 [GitLab 해커톤](https://gitlab-community.gitlab.io/community-projects/merge-request-leaderboard/?&createdAfter=2024-08-26&createdBefore=2024-09-02&mergedBefore=2024-10-03&label=Hackathon)에서 최고의 자리를 차지했습니다. 그는 [Middleware](https://middleware.io/)에서 선임 소프트웨어 엔지니어이며 열정적인 오픈 소스 기여자입니다.

Archish는 [Peter Leitzen](https://gitlab.com/splattael)(GitLab 엔지니어링 생산성 담당 직원 백엔드 엔지니어)에 의해 추천되었습니다. 추천은 [Max Woolf](https://gitlab.com/mwoolf)(GitLab 직원 백엔드 엔지니어) 및 [James Nutt](https://gitlab.com/jnutt)(GitLab 선임 백엔드 엔지니어)의 지지를 받았습니다. Archish의 기여는 지난 2개월 동안 증가했으며, GitLab의 코드베이스를 개선하기 위한 탁월한 헌신을 지속적으로 보여주었고, 여러 QoL(품질 향상) 수정사항을 제공하고 기술 부채를 줄였습니다.

GitLab을 함께 만들어주신 Archish와 GitLab의 다른 모든 오픈 소스 기여자에게 많은 감사를 드립니다!

## 주요 기능 {#primary-features}

### 더 많은 컨텍스트를 인식하는 GitLab Duo 코드 제안(오픈 탭 사용) {#more-context-aware-gitlab-duo-code-suggestions-using-open-tabs}

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/project/repository/code_suggestions/context.md) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/206)

{{< /details >}}

다른 열린 탭의 내용을 사용하여 더 많은 컨텍스트를 인식하는 코드 제안을 받아 코딩 워크플로우를 향상시킵니다.

코드 제안에 대한 이 개선사항은 이제 열린 편집기 탭의 내용을 사용하여 더 관련성 높고 정확한 코드 권장사항을 제공합니다.

### 모든 검사를 통과할 때 자동 병합 {#auto-merge-when-all-checks-pass}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

머지 리퀘스트는 병합되기 전에 통과해야 하는 많은 필수 검사를 포함합니다. 이러한 검사에는 승인, 미해결 스레드, 파이프라인, 및 충족해야 할 다른 항목이 포함될 수 있습니다. 코드 병합을 담당할 때 이러한 모든 이벤트를 추적하고 머지 리퀘스트를 병합할 수 있는지 확인하기 위해 다시 확인해야 할 시점을 파악하기 어려울 수 있습니다.

GitLab은 이제 머지 리퀘스트의 모든 검사에 대해 **Auto-merge**을 지원합니다. 자동 병합을 사용하면 병합할 수 있는 자격이 있는 모든 사용자가 필수 검사를 모두 통과하기 전에도 머지 리퀘스트를 **Auto-merge**으로 설정할 수 있습니다. 머지 리퀘스트가 수명 주기를 거치면서 마지막 실패한 검사를 통과한 후 머지 리퀘스트가 자동으로 병합됩니다.

이러한 개선사항으로 머지 리퀘스트 워크플로우를 가속화할 수 있어 정말 기쁩니다. 이 기능에 대한 피드백은 [이슈 438395](https://gitlab.com/gitlab-org/gitlab/-/issues/438395)에서 남길 수 있습니다.

### Web IDE에서 확장 프로그램 마켓플레이스 사용 가능 {#extension-marketplace-now-available-in-the-web-ide}

<!-- categories: Web IDE -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

GitLab.com의 Web IDE에서 확장 프로그램 마켓플레이스 출시를 발표하게 되어 기쁩니다. 확장 프로그램 마켓플레이스를 통해 타사 확장 프로그램을 검색, 설치 및 관리하고 개발 환경을 향상시킬 수 있습니다. 일부 확장 프로그램은 로컬 런타임 환경이 필요하므로 웹 전용 버전과 호환되지 않습니다. 하지만 수천 개의 확장 프로그램 중에서 선택하여 생산성을 높이거나 워크플로우를 사용자 정의할 수 있습니다.

확장 마켓플레이스는 기본적으로 비활성화됩니다. 시작하려면 **연동** 섹션에서 확장 프로그램 마켓플레이스를 활성화할 수 있습니다. [사용자 기본 설정](https://gitlab.com/-/profile/preferences). [엔터프라이즈 사용자](../../user/enterprise_user/_index.md)의 경우, 최상위 그룹에 대한 소유자 역할을 가진 사용자만 확장 프로그램 마켓플레이스를 활성화할 수 있습니다.

### 워크스페이스를 위한 보안 sudo 액세스 {#secure-sudo-access-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/configuration.md#configure-sudo-access-for-a-workspace)

{{< /details >}}

이제 워크스페이스에 대해 sudo 액세스를 구성할 수 있어 개발 환경에 직접 종속성을 설치, 구성 및 실행하기가 더 쉬워졌습니다. 원활한 개발 환경을 보장하기 위해 세 가지 보안 방법을 구현했습니다:

- Sysbox
- Kata 컨테이너
- 사용자 네임스페이스

이 기능을 사용하면 워크플로우 및 프로젝트 요구 사항에 맞게 환경을 완전히 사용자 정의할 수 있습니다.

### Kubernetes 리소스 이벤트 나열 {#list-kubernetes-resource-events}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/470041)

{{< /details >}}

GitLab은 포드에 대한 실시간 뷰 및 스트리밍 포드 로그를 제공합니다. 그러나 지금까지 UI에서 리소스별 이벤트 정보를 표시하지 않았으므로 여전히 타사 도구를 사용하여 Kubernetes 배포를 디버깅해야 했습니다. 이 릴리스는 [Kubernetes 대시보드](../../ci/environments/kubernetes_dashboard.md)의 리소스 세부정보 뷰에 이벤트를 추가합니다.

이는 UI에 이벤트를 추가한 첫 번째 경우입니다. 현재 리소스 세부정보 뷰를 열 때마다 이벤트가 새로 고쳐집니다. [이슈 470042](https://gitlab.com/gitlab-org/gitlab/-/issues/470042)에서 실시간 이벤트 스트리밍 개발을 추적할 수 있습니다.

### 와일드카드 DNS 없는 GitLab Pages는 일반적으로 사용 가능 {#gitlab-pages-without-wildcard-dns-is-generally-available}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/pages/_index.md#dns-configuration-for-single-domain-sites) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13404)

{{< /details >}}

이전에는 GitLab Pages 프로젝트를 만들려면 `name.example.io` 또는 `name.pages.example.io` 형식의 도메인이 필요했습니다. 이 요구 사항은 와일드카드 DNS 레코드 및 TLS 인증서를 설정해야 한다는 의미였습니다. 이 릴리스에서는 DNS 와일드카드 없이 GitLab Pages 프로젝트를 설정하는 것이 베타에서 일반적으로 사용 가능으로 이동했습니다.

와일드카드 인증서 요구 사항을 제거하면 GitLab Pages와 관련된 관리 오버헤드가 줄어듭니다. 일부 고객은 와일드카드 DNS 레코드 또는 인증서에 대한 조직 제한으로 인해 GitLab Pages를 사용할 수 없습니다.

### GitLab Pages 병렬 배포(베타) {#gitlab-pages-parallel-deployments-in-beta}

<!-- categories: Pages -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/_index.md#parallel-deployments) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10914)

{{< /details >}}

이 릴리스는 Pages 병렬 배포를 베타 단계에서 소개합니다. 이제 GitLab Pages 사이트에 대한 변경 사항을 쉽게 미리 보고 병렬 배포를 관리할 수 있습니다. 이 개선사항을 통해 새로운 아이디어를 원활하게 시도할 수 있으므로 자신감을 가지고 사이트를 테스트하고 개선할 수 있습니다. 조기에 이슈를 파악함으로써 라이브 사이트가 안정적이고 세련되게 유지되도록 할 수 있으며, GitLab Pages의 이미 훌륭한 기반을 바탕으로 합니다.

또한 애플리케이션 또는 웹사이트의 다양한 언어 버전을 배포할 때 병렬 배포가 지역화에 유용할 수 있습니다.

### GitLab Duo Chat로 이슈 토론 요약 {#summarize-issue-discussions-with-gitlab-duo-chat}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)

{{< /details >}}

길이가 긴 이슈 토론의 내용을 파악하는 것은 상당한 시간 투자가 될 수 있습니다. 이 릴리스에서는 AI 생성 이슈 토론 요약이 Duo Chat과 통합되었으며 이제 GitLab.com, 자체 관리 및 전용 고객에게 일반적으로 사용 가능합니다.

### Advanced SAST는 일반적으로 사용 가능 {#advanced-sast-is-generally-available}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

Advanced Static Application Security Testing(SAST) 스캐너가 이제 모든 GitLab Ultimate 고객에게 일반적으로 사용 가능합니다.

Advanced SAST는 올해 초 [Oxeye에서 인수한](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/) 기술로 구동되는 새로운 스캐너입니다. 자체 소유 코드의 악용 가능한 취약성을 식별하기 위해 사내 보안 연구로 정보를 얻은 규칙이 있는 독점 감지 엔진을 사용합니다. 개발자와 보안 팀이 거짓 양성 결과의 소음을 정렬할 필요가 없도록 더 정확한 결과를 제공합니다.

새로운 스캔 엔진과 함께 GitLab 17.4에는 다음이 포함됩니다:

- 파일 및 함수 전체에서 취약성의 경로를 추적하는 새로운 [코드 흐름 뷰](../../user/application_security/vulnerabilities/_index.md#vulnerability-code-flow).
- Advanced SAST가 이전 GitLab SAST 스캐너에서 기존 결과를 "인수"할 수 있는 자동 마이그레이션.

자세히 알아보려면 [공지 블로그](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/)를 참조하세요.

### UI에서 CI/CD 변수 값 숨기기 {#hide-cicd-variable-values-in-the-ui}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](https://new.docs.gitlab.com/ci/variables/#define-a-cicd-variable-in-the-ui) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)

{{< /details >}}

프로젝트 설정에 저장된 후에 변수 값을 아무도 볼 수 없도록 하려고 할 수 있습니다. CI/CD 변수를 만들 때 새로운 **마스킹 및 숨김** 표시 여부 옵션을 선택할 수 있습니다. 이 옵션을 선택하면 CI/CD 설정 UI에서 변수 값을 영구적으로 마스킹하여 향후 누구에게도 표시되지 않도록 제한하고 데이터의 표시 여부를 줄입니다.

## 규모 및 배포 {#scale-and-deployments}

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.4는 GitLab의 새로운 설치에 대해 기본적으로 PostgreSQL 16을 포함합니다.

GitLab 17.7에는 OpenSSL V3가 포함될 예정입니다. 이는 아웃바운드 연결에 대해 TLS 1.2 이상의 최소 요구 사항을 충족하지 않고 TLS 인증서에 대해 최소 112비트 암호화를 사용하지 않는 외부 통합 설정이 있는 Omnibus 인스턴스에 영향을 미칩니다. 자세한 정보를 위해 [OpenSSL 업그레이드 설명서](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3/)를 검토하거나 인스턴스가 영향을 받을지 확실하지 않은 경우 검토하세요.

### Groups 또는 Projects API를 사용하여 그룹 또는 프로젝트에 초대된 그룹 나열 {#list-groups-invited-to-a-group-or-project-using-the-groups-or-projects-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/groups.md#list-invited-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/465207)

{{< /details >}}

그룹 또는 프로젝트에 초대된 그룹을 검색하기 위해 Groups API 및 Projects API에 새 엔드포인트를 추가했습니다. 이 기능은 그룹 또는 프로젝트의 멤버 페이지에서만 사용할 수 있습니다. 이 추가 기능이 그룹 및 프로젝트에 대한 멤버십 관리를 자동화하기 쉽게 해주기를 바랍니다. 엔드포인트는 사용자당 분당 60개 요청으로 속도 제한됩니다.

### Groups API를 사용하여 도메인으로 그룹 액세스 제한 {#restrict-group-access-by-domain-with-the-groups-api}

<!-- categories: Source Code Management, Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/groups.md#update-group-attributes) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/351494)

{{< /details >}}

이전에는 UI의 그룹 수준에서만 도메인 제한을 추가할 수 있었습니다. 이제 Groups API에서 새로운 `allowed_email_domains_list` 속성을 사용하여 이 작업을 수행할 수도 있습니다.

### 그룹 및 프로젝트 멤버에 대한 향상된 소스 표시 {#improved-source-display-for-group-and-project-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/members/_index.md#membership-types) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431066)

{{< /details >}}

그룹 및 프로젝트에 대한 멤버 페이지의 소스 열 표시를 단순화했습니다. 직접 멤버는 여전히 `Direct member`로 표시됩니다. 상속된 멤버는 이제 `Inherited from` 다음에 그룹 이름으로 나열됩니다. 그룹을 그룹 또는 프로젝트에 초대하여 추가된 멤버는 `Invited group` 다음에 그룹 이름으로 나열됩니다. 상위 그룹에 추가된 초대된 그룹에서 상속된 멤버의 경우 멤버십을 관리하는 사용자에게 표시를 실행 가능하게 유지하기 위해 마지막 단계를 표시합니다.

### GitLab Duo 사용자 할당 이메일 {#gitlab-duo-seat-assignment-email}

<!-- categories: Seat Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Pro
- 링크: [문서](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164104)

{{< /details >}}

자체 관리 인스턴스의 사용자는 이제 GitLab Duo 사용자가 할당될 때 이메일을 받습니다. 이전에는 누군가가 당신에게 알려주지 않거나 GitLab UI에서 새로운 기능을 발견하지 않는 한 사용자가 할당되었다는 것을 알 수 없었습니다.

이 이메일을 비활성화하려면 관리자는 `duo_seat_assignment_email_for_sm` 기능 플래그를 비활성화할 수 있습니다.

### API를 사용하여 실패한 웹후크 요청 다시 보내기 {#resend-failed-webhook-requests-with-the-api}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/project_webhooks.md#resend-a-project-webhook-event) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/372826)

{{< /details >}}

이전에는 GitLab은 UI에서만 웹후크 요청을 다시 보낼 수 있는 기능을 제공했으며, 많은 요청이 실패한 경우 비효율적이었습니다.

실패한 웹후크 요청을 프로그래밍 방식으로 처리할 수 있도록 이 릴리스에서는 커뮤니티 기여 덕분에 이를 다시 보내기 위한 API 엔드포인트를 추가했습니다:

- [프로젝트 웹후크 요청](../../api/project_webhooks.md#resend-a-project-webhook-event)
- [그룹 웹후크 요청](../../api/group_webhooks.md#resend-group-hook-event)(Premium 및 Ultimate 티어만 해당)

이제 다음을 수행할 수 있습니다:

1. [프로젝트 훅](../../api/project_webhooks.md#list-project-webhook-events) 또는 [그룹 훅](../../api/group_webhooks.md#list-all-group-hook-events) 이벤트 목록을 가져옵니다.
1. 목록을 필터링하여 실패를 확인합니다.
1. 모든 이벤트의 `id`을(를) 사용하여 다시 보냅니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)를 주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### 웹후크 요청에 대한 Idempotency 키 {#idempotency-keys-for-webhook-requests}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhooks.md#delivery-headers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/388692)

{{< /details >}}

이 릴리스에서는 웹후크 요청의 헤더에서 idempotency 키를 지원합니다. Idempotency 키는 웹후크 재시도 전반에서 일관되게 유지되는 고유 ID이며, 웹후크 클라이언트가 재시도를 감지할 수 있도록 합니다. `Idempotency-Key` 헤더를 사용하여 통합에 대한 웹후크 효과의 idempotency를 보장합니다.

[Van](https://gitlab.com/van.m.anderson)에게 [이 커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160952)에 감사드립니다!

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 코드 인텔리전스를 위한 CI/CD 구성 요소 {#cicd-component-for-code-intelligence}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/code_intelligence.md#with-the-cicd-component)

{{< /details >}}

GitLab의 코드 인텔리전스는 리포지토리를 검색할 때 코드 네비게이션 기능을 제공합니다. 코드 네비게이션을 시작하는 것은 CI/CD 작업을 구성해야 하므로 종종 복잡합니다. 이 작업은 올바른 출력 및 아티팩트를 제공하기 위해 사용자 정의 스크립팅이 필요할 수 있습니다.

GitLab은 이제 쉬운 설정을 위해 공식적인 [코드 인텔리전스 CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-intelligence)를 지원합니다. [구성 요소 사용](../../ci/components/_index.md#use-a-component) 지침을 따라 프로젝트에 이 구성 요소를 추가하세요. 이는 GitLab에서 코드 인텔리전스를 채택하는 것을 크게 단순화합니다.

현재 구성 요소는 이러한 언어를 지원합니다:

- Go 버전 1.21 이상
- TypeScript 또는 JavaScript.

구성 요소에 대한 언어 지원을 확대하려고 노력하면서 [사용 가능한 SCIP 인덱서](https://github.com/sourcegraph/scip?tab=readme-ov-file#tools-using-scip)를 계속 평가할 것입니다. 언어에 대한 지원 추가에 관심이 있다면 [코드 인텔리전스 구성 요소](https://gitlab.com/components/code-intelligence) 프로젝트에서 머지 리퀘스트를 열어주세요.

### 머지 리퀘스트에 연결된 파일을 먼저 표시 {#linked-files-in-merge-request-show-first}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/changes.md#show-a-linked-file-first)

{{< /details >}}

머지 리퀘스트의 특정 파일에 대한 링크를 공유할 때 종종 해당 파일 내의 항목을 확인하려는 의도입니다. 머지 리퀘스트는 이전에 참조한 특정 위치로 스크롤하기 전에 모든 파일을 로드해야 했습니다. 파일에 직접 연결하는 것은 머지 리퀘스트에서 협업 속도를 개선하는 좋은 방법입니다:

1. 먼저 표시할 파일을 찾습니다. 파일 이름을 마우스 오른쪽 버튼으로 클릭하여 해당 링크를 복사합니다.
1. 해당 링크를 방문하면 선택한 파일이 목록 맨 위에 표시됩니다. 파일 브라우저는 파일 이름 옆에 링크 아이콘을 표시합니다.

연결된 파일에 대한 피드백은 [이슈 439582](https://gitlab.com/gitlab-org/gitlab/-/issues/439582)에 남길 수 있습니다.

### JetBrains IDE에서 GitLab Duo에 대해 OAuth로 인증 {#authenticate-with-oauth-for-gitlab-duo-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../editor_extensions/jetbrains_ide/setup.md#configure-gitlab-duo) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/70)

{{< /details >}}

JetBrains용 GitLab Duo 플러그인은 이제 더 안전하고 효율적인 온보딩 프로세스를 제공합니다. OAuth로 빠르고 안전하게 로그인하세요. 개인 액세스 토큰이 필요 없이 기존 워크플로우와 완벽하게 통합됩니다!

### 보호 환경에 대한 비배포 작업이 수동 작업으로 변환되지 않음 {#non-deployment-jobs-to-protected-environments-arent-turned-into-manual-jobs}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/job_control.md#types-of-manual-jobs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/390025)

{{< /details >}}

구현 이슈로 인해 `action: prepare`, `action: verify` 및 `action: access` 작업은 보호 환경에 대해 실행될 때 수동 작업이 됩니다. 이러한 작업은 추가 승인이 필요하지 않지만 수동 상호 작용이 필요합니다.

[이슈 390025](https://gitlab.com/gitlab-org/gitlab/-/issues/390025)는 구현을 수정하여 이러한 작업이 수동 작업으로 변환되지 않도록 제안합니다. 이 제안된 변경 후 현재 동작을 유지하려면 [작업을 수동으로 명시적으로 설정](../../ci/jobs/job_control.md#types-of-manual-jobs)해야 합니다.

현재 `prevent_blocking_non_deployment_jobs` 기능 플래그를 활성화하여 새 구현으로 변경할 수 있습니다.

모든 제안된 주요 변경 사항은 `environment.action: prepare | verify | access` 값의 동작을 구별하기 위한 것입니다. `environment.action: access` 키워드는 현재 동작에 가장 가깝게 유지됩니다.

향후 호환성 이슈를 방지하려면 지금 이러한 키워드 사용을 검토해야 합니다. 다음 이슈에서 이러한 제안된 변경 사항에 대해 자세히 알아볼 수 있습니다:

- [이슈 437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [이슈 437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [이슈 437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### 클러스터 UI에서 Flux 조정 트리거 {#trigger-a-flux-reconciliation-from-the-cluster-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/434248)

{{< /details >}}

지정된 간격에서 조정을 트리거하도록 Flux를 구성할 수 있지만 즉시 조정을 원하는 경우가 있습니다. 이전 릴리스에서는 CI/CD 파이프라인 또는 명령줄에서 조정을 트리거할 수 있었습니다. GitLab 17.4에서는 이제 추가 구성 없이 Kubernetes 대시보드에서 조정을 트리거할 수 있습니다.

조정을 트리거하려면 구성된 대시보드로 이동하여 Flux 상태 배지를 선택합니다.

### 선택적 토큰 만료 {#optional-token-expiration}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)

{{< /details >}}

관리자는 이제 개인, 프로젝트 및 그룹 액세스 토큰에 대해 필수 만료 날짜를 적용할지 결정할 수 있습니다. 관리자가 이 설정을 비활성화하면 생성된 새 액세스 토큰은 만료 날짜를 가질 필요가 없습니다. 기본적으로 이 설정은 활성화되어 있으며 최대 허용 수명보다 작은 만료가 필요합니다. 이 설정은 GitLab 16.11 이상에서 사용할 수 있습니다.

### 여러 규정 준수 프레임워크로 검색 {#search-by-multiple-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/compliance_center/compliance_projects_report.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/462943)

{{< /details >}}

GitLab 17.3에서 사용자에게 프로젝트에 여러 규정 준수 프레임워크를 추가할 수 있는 기능을 제공했습니다.

이제 여러 규정 준수 프레임워크로 검색할 수 있으므로 여러 규정 준수 프레임워크가 연결된 프로젝트를 더 쉽게 검색할 수 있습니다.

### 보안 정책에 연결된 프로젝트의 파이프라인 실행 YAML 파일에 대한 읽기 액세스 권한 부여 {#grant-read-access-to-pipeline-execution-yaml-files-in-projects-linked-to-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/469439)

{{< /details >}}

GitLab 17.4에서는 모든 연결된 프로젝트에 대해 `pipeline-execution.yml` 파일에 대한 읽기 액세스 권한을 부여하는 데 사용할 수 있는 보안 정책에 설정을 추가했습니다. 이 설정을 사용하면 프로젝트 전체에서 파이프라인 실행을 적용하는 사용자, 봇 또는 토큰을 활성화할 수 있는 유연성이 더 많습니다. 예를 들어, 그룹 또는 프로젝트 액세스 토큰이 파이프라인 실행 중에 파이프라인을 트리거하기 위해 보안 정책 구성을 읽을 수 있도록 할 수 있습니다. 여전히 보안 정책 프로젝트 리포지토리 또는 YAML을 직접 볼 수 없습니다. 구성은 파이프라인 생성 중에만 사용됩니다.

설정을 구성하려면 공유할 보안 정책 프로젝트로 이동합니다. **설정 > 일반 > 표시 여부, 프로젝트 기능, 권한**을 선택하고 **파이프라인 실행 정책**으로 스크롤한 후 **Grant access to this repository for projects linked to it as the security policy project source for security policies** 토글을 활성화합니다.

### 파이프라인 실행 정책 파이프라인에서 이름 충돌이 있는 작업에 대한 접미사 지원 {#support-suffix-for-jobs-with-name-collisions-in-pipeline-execution-policy-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/473189)

{{< /details >}}

[파이프라인 실행 정책의 17.2 릴리스](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#pipeline-execution-policy-type)에 대한 향상사항이 있으므로 정책 작성자는 이제 작업 이름의 충돌을 우아하게 처리하도록 파이프라인 실행 정책을 구성할 수 있습니다. 파이프라인 실행 정책의 `policy.yml`를 사용하여 이제 다음 옵션을 구성할 수 있습니다:

- `suffix: on_conflict`은 정책이 작업 이름 충돌을 우아하게 처리하도록 구성하며, 이는 새로운 기본 동작입니다.
- `suffix: never`은 모든 작업 이름이 고유한지 확인하고 충돌이 발생하면 파이프라인이 실패하도록 하며, 17.2 이후 기본 동작이었습니다.

이 개선사항을 통해 파이프라인 실행 정책 내에서 실행되는 보안 및 규정 준수 작업이 항상 실행되도록 할 수 있으며 다운스트림 개발자에게 불필요한 영향을 방지합니다.

후속 개선사항에서는 정책 편집기 내에 구성 옵션을 도입할 것입니다.

### 크기 조정 가능한 위키 사이드바 {#resizable-wiki-sidebar}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154167)

{{< /details >}}

이제 위키 사이드바를 조정하여 더 긴 페이지 제목을 확인할 수 있으며 전체 콘텐츠 검색 가능성을 개선합니다. 위키 콘텐츠가 증가하면서 크기 조정 가능한 사이드바는 복잡한 계층 구조 또는 광범위한 페이지 목록을 보다 효율적으로 관리하고 검색할 수 있습니다.

### CycloneDX 1.6 SBOM 수집 지원 {#support-for-ingesting-cyclonedx-16-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/472837)

{{< /details >}}

GitLab 15.3은 [CycloneDX SBOM 수집](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)에 대한 지원을 추가했습니다.

GitLab 17.4에서는 CycloneDX 버전 1.6 SBOM 수집에 대한 지원을 추가했습니다.

하드웨어(HBOM), 서비스(SaaSBOM) 및 AI/ML 모델(AI/ML-BOM)과 관련된 필드는 현재 지원되지 않습니다. 이러한 BOM과 관련된 데이터를 포함하는 SBOM이 처리되지만 데이터는 분석되거나 사용자에게 제시되지 않습니다. 이러한 다른 BOM 유형에 대한 지원은 이 [에픽](https://gitlab.com/groups/gitlab-org/-/epics/14989)에서 추적됩니다.

### 제거된 SAST 분석기에 대한 자동 정리 {#automatic-cleanup-for-removed-sast-analyzers}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support)

{{< /details >}}

[GitLab 17.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170), [16.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-160) 및 [15.4](../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes)에서 코드의 취약성을 스캔하기 위해 더 적은 수의 별도 분석기를 사용하도록 GitLab SAST를 간소화했습니다.

이제 GitLab 17.3.1 이상으로 업그레이드한 후 일회성 데이터 마이그레이션이 [지원 종료에 도달한 분석기](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support)의 남은 취약성을 자동으로 해결합니다. 이는 취약성 보고서를 정리하여 최신 분석기에서 여전히 감지된 취약성에 집중할 수 있도록 도와줍니다.

마이그레이션은 확인하거나 해제하지 않은 취약성만 해결하며, [Semgrep 기반 스캔으로 자동 변환된](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning) 취약성에는 영향을 주지 않습니다.

### Anthropic API 키에 대한 시크릿 검색 지원 {#secret-detection-support-for-anthropic-api-keys}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/secret_detection/detected_secrets.md)

{{< /details >}}

파이프라인 및 클라이언트 측 시크릿 검색은 이제 [Anthropic](https://www.anthropic.com/) API 키 감지를 지원합니다.

### JaCoCo 테스트 커버리지 시각화 지원(베타) {#jacoco-support-for-test-coverage-visualization-available-in-beta}

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/testing/code_coverage/jacoco.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

이제 인기 있는 커버리지 계산 표준인 JaCoCo 커버리지 보고서를 머지 리퀘스트 내에서 사용할 수 있습니다. 이 기능은 베타로 제공되지만 JaCoCo 커버리지 보고서를 즉시 사용하려는 모든 사람이 테스트할 준비가 되어 있습니다. 피드백이 있으면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/479804)에 기여하세요.

### GitLab 러너 17.4 {#gitlab-runner-174}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 17.4도 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [Azure 컴퓨팅용 GitLab 러너 fleeting 플러그인(GA)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29223)

#### 버그 수정 {#bug-fixes}

- [Kubernetes 실행기 작업이 완료되기 전에 취소되면 전체 `step_script`내용이 작업 로그의 `after_script` 섹션에 나타남](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37952)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-4-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.4)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
