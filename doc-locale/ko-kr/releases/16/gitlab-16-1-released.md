---
stage: Release Notes
group: Monthly Release
date: 2023-06-22
title: "GitLab 16.1 릴리스 정보"
description: "GitLab 16.1은 새로운 네비게이션 경험과 함께 출시되었습니다."
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 6월 22일에 GitLab 16.1이 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

Gerardo는 여러 릴리스에 걸쳐 지속적으로 반복하여 [작업 토큰 범위를 위한 REST API 엔드포인트](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)를 제공했습니다. 반복은 GitLab의 [핵심 가치](https://handbook.gitlab.com/handbook/values/#iteration) 중 하나이며, Gerardo는 기능을 제공하기 위한 여러 기여로 이를 본보기로 보여주었습니다.

[기본 `CI_JOB_TOKEN` 동작](../../update/deprecations.md) 변경으로 인해 프로젝트 생성을 자동화하는 사용자는 프로젝트에서 사용할 수 있는 프로젝트 추가를 자동화할 수 없습니다. 또한 `CI_JOB_TOKEN`를 함께 사용하면 됩니다. 이 REST API 엔드포인트를 통해 고객은 이 프로세스를 다시 자동화할 수 있으며, 더욱 안전한 `CI_JOB_TOKEN` 워크플로우의 채택을 증가시킬 수 있습니다.

Gerardo와 Siemens의 나머지 팀에게 감사합니다!

Yuri는 6년 전에 기록된 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)를 선택하고, [행동 편향](https://handbook.gitlab.com/handbook/values/#bias-for-action)(GitLab 가치 중 하나)을 취하여 수정을 기여했습니다.

이는 많은 고객들이 관심을 가진 인기 있는 기능이었습니다. 이 개선 사항을 통해 시스템 관리자는 쉼표로 구분된 그룹 또는 리포지토리 경로 목록을 기반으로 백업 및 복원 중에 특정 프로젝트를 건너뛸 수 있습니다. 이 기능을 통해 시스템 관리자는 백업 실행 중에 오래되었거나 보관된 프로젝트를 건너뛰고, 저장 공간을 절약하고 백업 속도를 높일 수 있습니다. 또한 동일한 옵션을 사용하여 백업에서 복원할 때 특정 프로젝트를 제외할 수 있습니다.

Yuri의 귀중한 기여에 감사합니다!

## 주요 기능 {#primary-features}

### 완전히 새로운 네비게이션 경험 {#all-new-navigation-experience}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

GitLab 16.1은 완전히 새로운 네비게이션 경험을 제공합니다! 이 경험은 모든 사용자에 대해 기본적으로 켜지도록 설정했습니다. 시작하려면 UI의 오른쪽 상단에 있는 아바타로 이동하여 **New navigation** 토글을 켭니다.

새로운 네비게이션은 세 가지 주요 피드백 영역을 해결하도록 설계되었습니다. GitLab 네비게이션이 압도적일 수 있고, 중단한 지점을 다시 시작하기 어려울 수 있으며, 네비게이션을 사용자 지정할 수 없습니다.

새로운 네비게이션에는 간소화되고 개선된 왼쪽 사이드바가 포함되어 있으며, 여기서 다음을 수행할 수 있습니다:

- 자주 사용하는 항목을 📌 고정합니다.
- 사이드바를 완전히 숨기고 다시 보기로 "엿보기" 할 수 있습니다.
- 새로운 **Your Work** 및 **탐색** 옵션을 사용하여 컨텍스트를 쉽게 전환하고, 검색하고, 데이터 하위 집합을 봅니다.
- 상위 수준 메뉴 항목이 적어 더 빠르게 스캔할 수 있습니다.

우리는 새로운 네비게이션이 자랑스럽고 당신의 생각을 보기를 기대할 수 없습니다. [변경된 항목 목록](https://gitlab.com/groups/gitlab-org/-/epics/9044#whats-different)을 검토하고 네비게이션 [비전](https://about.gitlab.com/blog/gitlab-product-navigation/) 및 [디자인](https://about.gitlab.com/blog/overhauling-the-navigation-is-like-building-a-dream-home/)에 대한 블로그 게시물을 읽어보세요.

새로운 네비게이션을 시도하고 [이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/409005)에서 경험에 대해 알려주세요. 이미 피드백을 [처리](https://gitlab.com/gitlab-org/gitlab/-/issues/409005#actions-we-are-taking-from-the-feedback)하고 있으며 결국 토글을 제거할 것입니다.

### GitLab에서 Kubernetes 리소스 시각화 {#visualize-kubernetes-resources-in-gitlab}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/390769)

{{< /details >}}

클러스터에서 실행 중인 애플리케이션의 상태를 어떻게 확인합니까? 파이프라인 상태 및 환경 페이지는 최신 배포 실행에 대한 인사이트를 제공합니다. 그러나 이전 버전의 GitLab은 배포 상태에 대한 인사이트가 부족했습니다. GitLab 16.1에서는 Kubernetes 배포에서 기본 리소스의 개요를 볼 수 있습니다.

이 기능은 연결된 모든 Kubernetes 클러스터에서 작동합니다. CI/CD 통합 또는 GitOps를 사용하여 워크로드를 배포하는지 여부는 중요하지 않습니다. Flux 사용자를 위한 기능을 추가로 개선하기 위해 환경의 동기화 상태를 표시하는 지원이 [이슈 391581](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)에서 제안됩니다.

### 서비스 계정으로 인증 {#authenticate-with-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/groups.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/6777)

{{< /details >}}

비인간 사용자가 인증해야 하는 많은 사용 사례가 있습니다. 이전에는 원하는 범위에 따라 사용자는 개인, 리포지토리 또는 그룹 액세스 토큰을 사용하여 이 요구 사항을 충족할 수 있었습니다. 이러한 토큰은 인간과 연결되거나(개인 액세스 토큰의 경우) 불필요하게 특권이 부여된 역할(그룹 및 리포지토리 액세스 토큰의 경우) 때문에 이상적이지 않았습니다.

서비스 계정은 인간 사용자와 연결되지 않으며 범위가 더 세밀합니다. 서비스 계정 생성 및 관리는 API 전용입니다. UI 옵션에 대한 지원이 [이슈 9965](https://gitlab.com/groups/gitlab-org/-/epics/9965)에서 제안됩니다.

### GitLab Dedicated는 이제 일반적으로 사용 가능합니다 {#gitlab-dedicated-is-now-generally-available}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../subscriptions/gitlab_dedicated/_index.md) \| [관련 이슈](https://about.gitlab.com/dedicated/)

{{< /details >}}

GitLab Dedicated는 엄격한 규정 준수 요구 사항이 있는 고객의 요구를 충족하도록 설계된 포괄적인 DevSecOps 플랫폼의 완전히 관리되는 단일 테넌트 SaaS 배포입니다.

높은 규제 산업의 고객은 데이터 격리와 같은 엄격한 규정 준수 요구 사항으로 인해 다중 테넌트 SaaS 제공을 채택할 수 없습니다. GitLab Dedicated를 사용하면 조직은 DevSecOps 플랫폼의 모든 이점(더 빠른 릴리스, 더 나은 보안, 더 생산적인 개발자)에 액세스할 수 있으면서도 데이터 거주지, 격리 및 프라이빗 네트워킹과 같은 규정 준수 요구 사항을 충족할 수 있습니다.

[자세히 알아보기](https://about.gitlab.com/dedicated/) GitLab Dedicated에 대해 지금 확인해보세요.

### 아티팩트 페이지를 통해 작업 아티팩트 관리 {#manage-job-artifacts-through-the-artifacts-page}

<!-- categories: Job Artifacts -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/jobs/job_artifacts.md#view-all-job-artifacts-in-a-project)

{{< /details >}}

이전에 작업 아티팩트를 보거나 관리하려면 각 작업의 세부 정보 페이지로 이동하거나 API를 사용해야 했습니다. 이제 **아티팩트** 페이지를 통해 작업 아티팩트를 보고 관리할 수 있으며, **빌드 > 아티팩트**에서 액세스할 수 있습니다.

Maintainer 역할 이상인 사용자는 이 새 인터페이스를 사용하여 아티팩트를 삭제할 수도 있습니다. 수동 선택이나 페이지 상단의 **모두 선택** 옵션을 확인하여 한 번에 최대 100개의 아티팩트를 개별적으로 삭제하거나 일괄 삭제할 수 있습니다.

아티팩트 페이지 상단의 설문 조사를 사용하여 이 새 기능에 대한 피드백을 공유하세요. 고려 중인 추가 UI 기능을 보려면 [빌드 아티팩트 페이지 개선 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8311)을 확인할 수 있습니다.

### 개선된 CI/CD 변수 목록 보기 {#improved-cicd-variables-list-view}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/410383)

{{< /details >}}

CI/CD 변수는 모든 파이프라인의 핵심 부분이며 프로젝트 및 그룹 설정을 포함한 여러 위치에서 정의할 수 있습니다. 사용자가 다양한 계층 구조의 변수 간 직관적으로 탐색하는 데 도움이 되는 더 큰 개선을 준비하기 위해 변수 목록의 사용성 및 레이아웃 개선을 시작하고 있습니다.

GitLab 16.1에서는 이러한 개선의 첫 번째 반복을 볼 수 있습니다. "유형" 및 "옵션" 열을 새로운 **속성** 열로 병합했으며, 이는 이러한 관련 속성을 더 잘 나타냅니다. CI/CD 변수 경험을 계속 개선할 수 있는 방법에 대한 피드백을 감사하며, [변수 개선 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10506)에 의견을 남길 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### GitLab 차트 개선 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/charts/)

{{< /details >}}

- GitLab 16.1은 `busybox` Docker 이미지를 `gitlab-base` Docker 이미지로 바꾸어 다른 GitLab Docker 이미지와 레이어를 공유합니다. 이 구현은 `gitlab-base`를 `kubectl` 및 `certificates`와 같은 도우미 이미지로 취급하며, 선택적인 로컬 오버라이드가 있습니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.1은 2023년 6월 10일에 출시된 [Debian 12 `Bookworm`](https://www.debian.org/releases/bookworm/)에서 패키지를 빌드하고 출시하기 위한 지원을 추가합니다.

### 개선된 도메인 검증 {#improved-domain-verification}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/enterprise_user/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/375492)

{{< /details >}}

도메인 검증은 GitLab 전체에서 여러 목적으로 사용됩니다. 이전에는 도메인을 검증하기 위해 GitLab Pages 외부의 목적으로 도메인을 검증하는 경우에도 [GitLab Pages](../../user/project/pages/_index.md) 마법사를 완료해야 했습니다.

이제 도메인 검증은 그룹 수준에서 수행되며 간소화되었습니다. 이를 통해 도메인을 더 쉽게 검증할 수 있습니다.

### 취약성 보고서를 사용자 지정 가능한 권한으로 보기 {#view-vulnerability-report-as-customizable-permission}

<!-- categories: System Access -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/permissions.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/10160)

{{< /details >}}

취약성 보고서를 볼 수 있는 기능이 이제 별도의 권한으로 분할되어 GitLab 관리자 및 그룹 소유자가 이 권한을 가진 사용자 지정 역할을 만들 수 있습니다. 이전에는 취약성 보고서를 보기가 Developer 역할 이상으로 제한되었습니다. 이제 모든 사용자는 권한이 있는 사용자 지정 역할이 할당되면 취약성 보고서를 볼 수 있습니다.

### 검증된 이메일 주소로 전송된 비밀번호 재설정 이메일 {#password-reset-email-sent-to-any-verified-email-address}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/user_passwords.md#change-your-password) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/16311)

{{< /details >}}

GitLab 비밀번호를 잊은 경우 이제 검증된 이메일 주소로 이메일을 통해 재설정할 수 있습니다. 이전에는 기본 이메일 주소만 재설정 요청에 사용되었습니다. 기본 이메일 받은편지함에 액세스할 수 없는 경우 비밀번호 재설정 프로세스를 완료하기 어려웠습니다.

### SCIM 신원이 사용자 API 응답에 포함됨 {#scim-identities-included-in-users-api-response}

<!-- categories: System Access, Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/users.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/324247)

{{< /details >}}

사용자 API는 이제 사용자에 대한 SCIM 신원을 반환합니다. 이전에는 이 정보가 UI에 포함되었지만 API에는 포함되지 않았습니다.

### OmniAuth Shibboleth 지원 재도입 {#reintroduction-of-omniauth-shibboleth-support}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../integration/shibboleth.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/393065)

{{< /details >}}

Shibboleth OmniAuth 지원이 GitLab에 다시 도입되었습니다. 업스트림 지원 부족으로 인해 이전에 GitLab 15.9에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/388959)되었습니다. 업스트림 지원을 담당한 [lukaskoenen](https://gitlab.com/lukaskoenen)의 관대한 커뮤니티 기여에 감사하며, `omniauth-shibboleth-redux`은 이제 자체 관리 GitLab에서 지원됩니다.

### Admin Mode에서 개인 액세스 토큰을 위한 관리자 액세스 선택 {#select-administrator-access-for-personal-access-tokens-in-admin-mode}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/42692)

{{< /details >}}

GitLab 관리자는 Admin Mode를 사용하여 비관리자 사용자로 작업하고 필요할 때 관리자 액세스를 켤 수 있습니다. 이전에는 관리자의 개인 액세스 토큰 (PAT)은 항상 관리자로 API 작업을 수행할 수 있는 권한이 있었습니다. 이제 PAT을 추가할 때 관리자는 Admin Mode 범위를 선택하여 해당 PAT이 API 작업을 수행할 관리자 액세스 권한이 있는지 여부를 결정할 수 있습니다. 관리자는 이 기능을 사용하려면 인스턴스에 대해 Admin Mode를 활성화해야 합니다.

기여해주신 [Jonas Wälter](https://gitlab.com/wwwjon), [Diego Louzán](https://gitlab.com/dlouzan), [Andreas Deicha](https://gitlab.com/TrueKalix)에게 감사합니다!

### 사용자가 계정 삭제 방지 {#prevent-user-from-deleting-account}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/26053)

{{< /details >}}

관리자는 새로운 사용자 제한 구성 설정으로 사용자가 자신의 계정을 삭제하지 못하도록 할 수 있습니다. 이 설정을 활성화하면 사용자는 더 이상 자신의 계정을 삭제할 수 없으며 감사 가능한 계정 정보가 보존됩니다.

### 개인 액세스 토큰 `last_used` 값이 더 자주 업데이트됨 {#personal-access-token-last_used-value-updated-more-frequently}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)

{{< /details >}}

개인 액세스 토큰 (PAT)의 `last_used` 값은 이전에 24시간마다 업데이트되었습니다. 이제 10분마다 업데이트됩니다. 이는 PAT 사용 가시성을 높이고, PAT 손상의 경우 악의적인 활동이 감지되기까지 걸리는 시간이 단축되므로 위험을 줄입니다.

기여해주신 [Jacob Torrey](https://thinkst.com/)에게 감사합니다!

### 완료된 GitHub 리포지토리 가져오기 요약에서 더 많은 세부 정보 {#more-detail-in-completed-github-project-import-summary}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/import/github.md#check-status-of-imports) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/386748)

{{< /details >}}

GitHub 리포지토리 가져오기가 완료되면 GitLab은 가져온 엔티티의 간단한 요약을 표시했습니다. 그러나 GitLab은 가져오기에 실패한 정확한 GitHub 엔티티나 가져오기 실패를 초래한 오류를 표시하지 않았습니다. 이로 인해 가져오기 결과가 만족스러운지 여부를 판단하기가 어려웠습니다.

이 릴리스에서는 가져오기 요약을 확장하여 가져오지 않은 GitHub 엔티티 목록을 포함하고, 가능한 경우 GitHub의 이러한 엔티티에 대한 직접 링크를 제공합니다. GitLab은 이제 각 실패에 대한 오류도 표시합니다. 이는 가져오기가 얼마나 잘 작동했는지 이해하는 데 도움이 되며 문제를 해결하는 데 도움이 됩니다.

### Service Desk 이슈에서 외부 사용자를 댓글 작성자로 표시 {#show-external-user-as-a-comment-author-in-service-desk-issues}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/service_desk/_index.md)

{{< /details >}}

요청자가 Service Desk 이메일에 응답하면 Service Desk 에이전트가 댓글을 작성한 사람을 아는 것이 유용합니다. 그러나 요청자는 GitLab 계정이 없거나 GitLab 리포지토리에 액세스할 수 없는 외부 사용자일 수 있으므로 이러한 댓글은 이전에 GitLab Support Bot에 귀속되었습니다. 이제부터 요청자로부터의 이메일 응답은 외부 사용자에게 귀속되어 GitLab 이슈에서 누가 댓글을 작성했는지 더 분명하게 합니다.

### Service Desk 이메일의 이슈 URL 자리 표시자 {#issue-url-placeholder-in-service-desk-emails}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/service_desk/_index.md)

{{< /details >}}

Service Desk 요청자의 경우 이메일을 통해서만 Service Desk 요청과 상호 작용하기보다는 Service Desk 이슈에 직접 액세스하는 것이 도움이 될 수 있습니다. 새로운 자리 표시자 `%{ISSUE_URL}`를 도입하고 있으며, 이를 이메일 템플릿(예: "감사합니다" 이메일)에서 사용하여 요청자를 Service Desk 이슈에 직접 연결할 수 있습니다.

### 백업은 프로젝트를 건너뛸 수 있는 기능을 추가합니다 {#backup-adds-the-ability-to-skip-projects}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

기본 제공 백업 및 복원 도구는 특정 리포지토리를 건너뛸 수 있는 기능을 추가합니다. Rake 작업은 이제 새 `SKIP_REPOSITORIES_PATHS` 환경 변수를 사용하여 백업 또는 복원 중에 건너뛸 쉼표로 구분된 그룹 또는 프로젝트 경로 목록을 허용합니다. 이를 통해 예를 들어 시간이 지남에 따라 변경되지 않는 오래된 또는 보관된 프로젝트를 건너뛸 수 있으므로 a) 백업 실행 속도를 높여 시간을 절약하고 b) 이 데이터를 백업 파일에 포함하지 않아 공간을 절약할 수 있습니다. 이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865)를 위해 [Yuri Konotopov](https://gitlab.com/nE0sIghT)님께 감사합니다!

### Geo는 모든 구성 요소에 복제 상태별 필터링 추가 {#geo-adds-filtering-by-replication-status-to-all-components}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/geo/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/411981)

{{< /details >}}

Geo는 [self-service framework](../../development/geo/framework.md)에서 관리하는 모든 구성 요소에 복제 상태별 필터링을 추가합니다. 이제 복제 세부 정보 보기에서 "진행 중", "실패" 및 "동기화됨" 상태별로 항목을 필터링하여 동기화 실패 데이터를 더 쉽고 빠르게 찾을 수 있습니다.

### Geo는 Design 리포지토리 검증 {#geo-verifies-design-repositories}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/geo/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)

{{< /details >}}

이슈에 디자인을 추가하면 디자인 Git 리포지토리가 생성되거나 업데이트되고, LFS 객체 및 업로드(썸네일용)가 생성됩니다. Geo는 이미 LFS 객체와 업로드를 검증하고 있으며 이제 design 리포지토리도 검증합니다. [Design Management](../../user/project/issues/design_management.md)의 모든 기본 데이터가 검증되었으므로 design 데이터가 전송 또는 저장 중에 손상되지 않도록 보장됩니다. Geo를 재해 복구 전략의 일부로 사용하면 데이터 손실로부터 보호됩니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 머지 리퀘스트에서 전체 파일에 대한 주석 {#comment-on-whole-file-in-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/changes.md#add-a-comment-to-a-merge-request-file)

{{< /details >}}

머지 리퀘스트는 이제 전체 파일에 대한 댓글 작성을 지원합니다. 모든 머지 리퀘스트 피드백이 라인별로 특정하지는 않기 때문입니다. 파일이 삭제되면 이유에 대해 자세히 알고 싶을 수 있습니다. 파일 이름에 대한 피드백이나 구조에 대한 일반적인 의견을 제공할 수도 있습니다.

### GitLab CLI에서 변경 로그 생성 {#create-a-changelog-from-the-gitlab-cli}

<!-- categories: GitLab CLI -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/changelogs.md#from-the-gitlab-cli)

{{< /details >}}

변경 로그는 리포지토리에 대한 커밋을 기반으로 변경 사항의 포괄적인 목록을 생성합니다. 자동화 또는 보기가 어려울 수 있으며 GitLab API와의 상호 작용이 필요합니다.

[GitLab CLI v1.30.0](https://gitlab.com/gitlab-org/cli/-/releases/v1.30.0) 릴리스를 통해 이제 셸에서 직접 프로젝트의 변경 로그를 생성할 수 있습니다. `glab changelog generate` 명령을 사용하면 변경 로그를 더 쉽게 검토하고, 자동화하고, 게시할 수 있습니다.

기여해주신 [Michael Mead](https://gitlab.com/michael-mead)에게 감사합니다!

### 잘못된 보안 정책 승인 확인에 대해 실패 폐쇄 {#fail-closed-for-invalid-security-policy-approval-checks}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/merge_requests/approvals/_index.md#invalid-rules) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/389905)

{{< /details >}}

보안 및 규정 준수 정책을 통해 조직은 여러 프로젝트 전체에서 확인 및 균형을 시행하여 보안 및 거버넌스 프로그램과 일치시킬 수 있습니다. 고객이 정책에 영향을 미치는 변경 사항으로 인해 보호 장치가 해제되지 않도록 보장하는 것이 중요합니다. 이 업데이트를 통해 잘못된 규칙은 "실패 폐쇄"되어 승인 스캔 결과 정책의 잘못된 규칙이 해결될 때까지 MRs를 차단합니다.

### 그룹 또는 하위 그룹에서 npm 패키지 설치 {#install-npm-packages-from-your-group-or-subgroup}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/npm_registry/_index.md#install-from-a-group) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)

{{< /details >}}

프로젝트의 Package Registry를 사용하여 npm 패키지를 게시하고 설치할 수 있습니다. 액세스 토큰(개인, 작업, 배포 또는 리포지토리)을 사용하여 인증하고 GitLab 프로젝트에 패키지를 게시하기 시작합니다.

프로젝트 수가 적으면 잘 작동합니다. 안타깝게도 프로젝트가 여러 개 있으면 수십 개 또는 수백 개의 다양한 소스를 빠르게 추가하게 될 수 있습니다. 대규모 조직의 팀이 소스 코드 및 파이프라인과 함께 프로젝트의 Package Registry에 패키지를 게시하는 것이 일반적입니다. 동시에 조직 내의 그룹 및 하위 그룹 내에서 다른 프로젝트의 종속성을 쉽게 설치할 수 있어야 합니다.

프로젝트 간 패키지 공유를 더 쉽게 하기 위해 이제 그룹에서 패키지를 설치할 수 있으므로 패키지가 어느 프로젝트에 있는지 기억할 필요가 없습니다. 선택한 인증 토큰을 사용하면 그룹을 npm 패키지의 소스로 추가한 후 그룹 npm 패키지를 설치할 수 있습니다.

### 디자인 업로드에 설명 추가 {#add-a-description-to-design-uploads}

<!-- categories: Portfolio Management, Design Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/issues/design_management.md#add-a-design-to-an-issue) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9694)

{{< /details >}}

현재 [Design 업로드](../../user/project/issues/design_management.md#add-a-design-to-an-issue)에는 목적을 설명하거나 업로드 이유를 설명하는 메타데이터가 없습니다. 설명으로 텍스트 상자를 추가했으므로 사용자가 이미지를 더 잘 이해할 수 있습니다.

### GitLab Pages에서 정적 파일 디렉터리 구성 {#configure-the-static-file-directory-in-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/pages/introduction.md#customize-the-default-folder) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/10126)

{{< /details >}}

이제 GitLab Pages에 대한 정적 파일 디렉터리를 모든 이름(기본적으로 `public`)으로 구성할 수 있습니다. 이를 통해 구성에서 출력 폴더를 변경할 필요 없이 Next.js, Astro 또는 Eleventy와 같은 인기 있는 정적 사이트 프레임워크와 함께 Pages를 사용하기 쉬워집니다.

### Code Quality 분석기 업데이트 {#code-quality-analyzer-updates}

<!-- categories: Code Quality -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/testing/code_quality.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/412459)

{{< /details >}}

GitLab Code Quality는 [이미 실행 중인 도구 통합](../../ci/testing/code_quality.md)을 지원하며 CodeClimate 스캔 시스템을 실행하는 [CI/CD 템플릿](../../ci/testing/code_quality.md)도 제공합니다. 16.1 릴리스 마일스톤 중에 CodeClimate 기반 분석기에 다음 업데이트를 게시했습니다:

- CodeClimate을 버전 0.96.0으로 업데이트했습니다. 이 버전에는 다음이 포함되어 있습니다:
  - `golangci-lint`에 대한 새로운 플러그인.
  - `bundler-audit` 플러그인에 대한 새로 사용 가능한 버전입니다.
- Docker API Socket에 대한 구성 가능한 경로에 대한 지원을 추가했습니다.
  - [`@tsjnsn`](https://gitlab.com/tsjnsn)에게 감사합니다. 이는 [커뮤니티 기여](https://gitlab.com/gitlab-org/ci-cd/codequality/-/merge_requests/73)입니다. CI/CD 템플릿에 이 변수를 포함하기 위한 업데이트는 [이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/409738)에서 추적됩니다.

자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/CHANGELOG.md?ref_type=heads#anchor-0960)를 참조하세요.

[GitLab 관리 Code Quality 템플릿을 포함](../../ci/testing/code_quality.md)하면 ([`Code-Quality.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)) 이러한 업데이트가 자동으로 수신됩니다.

이전 릴리스의 Code Quality 변경 사항을 보려면 [최근 업데이트](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates)를 참조하세요.

### SAST 분석기 업데이트 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/analyzers.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST는 [많은 보안 분석기](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)를 포함하며, GitLab Static Analysis 팀은 적극적으로 유지보수하고 업데이트하며 지원합니다. 16.1 릴리스 마일스톤 중에 다음 업데이트를 게시했습니다:

- Semgrep 기반 분석기는 Semgrep 엔진의 버전 1.23.0을 사용하도록 업데이트되었습니다. 또한 C, C#, Go 및 Java를 스캔하는 데 사용되는 GitLab 관리 규칙의 [설명을 명확히 하고 효능을 개선](https://docs.gitlab.com/#clearer-guidance-and-better-coverage-for-sast-rules)했습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v434)를 참조하세요.
- SpotBugs 기반 분석기는 이제 [`SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD 변수 설정](../../user/application_security/sast/_index.md#security-scanner-configuration)을 통해 "노력 수준"을 변경하도록 지원합니다. 이를 통해 스캔의 정밀도와 취약성 탐지 능력을 줄여 성능을 개선할 수 있습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/CHANGELOG.md#v420)를 참조하세요.

[GitLab 관리 SAST 템플릿을 포함](../../user/application_security/sast/_index.md)하고([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/sast/_index.md)할 수 있습니다.

이전 변경사항은 [지난 달 업데이트](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#sast-analyzer-updates)를 참조하세요.

### 유출된 Google Cloud 시크릿에 대한 자동 응답 {#automatic-response-to-leaked-google-cloud-secrets}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Gold
- 링크: [문서](../../user/application_security/secret_detection/automatic_response.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/8835)

{{< /details >}}

Google Cloud에서 애플리케이션을 개발하는 고객을 더 잘 보호하기 위해 Google Cloud와 Secret Detection을 통합했습니다. 이제 조직이 Google Cloud 자격 증명을 GitLab.com의 공개 프로젝트에 유출하면 GitLab은 Google Cloud와 함께 작업하여 계정을 보호함으로써 조직을 자동으로 보호할 수 있습니다.

Secret Detection은 Google Cloud에서 발행한 세 가지 유형의 시크릿을 검색합니다:

- [서비스 계정 키](https://docs.cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- [API 키](https://docs.cloud.google.com/docs/authentication/api-keys)
- [OAuth 클라이언트 시크릿](https://support.google.com/cloud/answer/6158849#rotate-client-secret)

공개적으로 유출된 시크릿은 발견 후 Google Cloud로 전송됩니다. Google Cloud는 유출을 확인한 다음 악용으로부터 고객 계정을 보호하기 위해 작동합니다.

이 통합은 GitLab.com에서 [Secret Detection을 활성화](../../user/application_security/secret_detection/_index.md)한 프로젝트에 대해 기본적으로 켜져 있습니다. Secret Detection 스캔은 모든 GitLab 티어에서 사용 가능하지만, 유출된 시크릿에 대한 자동 대응은 현재 Ultimate 프로젝트에서만 사용 가능합니다.

자세한 내용은 [이 통합에 대한 블로그 게시물](https://about.gitlab.com/blog/how-secret-detection-can-proactively-revoke-leaked-credentials/)을 참조하세요.

### SAST 규칙에 대한 명확한 지침 및 더 나은 범위 {#clearer-guidance-and-better-coverage-for-sast-rules}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/analyzers.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/382119)

{{< /details >}}

GitLab SAST 규칙을 업데이트했습니다:

- 각 규칙이 대상으로 하는 취약성의 유형과 이를 수정하는 방법을 더 명확하게 설명합니다. 지금까지 C, C#, Go 및 Java 규칙에 대한 설명 및 지침 텍스트를 업데이트했습니다. 나머지 언어는 [이슈 382119](https://gitlab.com/gitlab-org/gitlab/-/issues/382119)에서 추적됩니다.
- 기존 Java 규칙에서 추가 취약성을 포착합니다.

이러한 개선 사항은 [기본 Static Analysis 규칙 집합을 개선](https://gitlab.com/groups/gitlab-org/-/epics/8170)하기 위한 GitLab Static Analysis 및 Vulnerability Research 팀 간의 협업의 일부입니다. SAST, Secret Detection 및 IaC Scanning의 기본 규칙에 대한 피드백을 환영하며 [에픽 8170](https://gitlab.com/groups/gitlab-org/-/epics/8170)에 의견을 남겨주세요.

GitLab SAST 규칙 변경 사항에 대한 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md)를 참조하세요. GitLab 16.1 기준으로 [`sast-rules` 리포지토리](https://gitlab.com/gitlab-org/security-products/sast-rules)는 Semgrep 기반 SAST 분석기에서 사용하는 모든 GitLab 관리 기본 규칙의 단일 소스입니다.

### SAST, IaC Scanning 및 Secret Detection에서 공유되는 규칙 집합 사용자 지정 {#shared-ruleset-customizations-in-sast-iac-scanning-and-secret-detection}

<!-- categories: SAST, Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/customize_rulesets.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

이제 CI/CD 변수를 설정하여 [SAST](../../user/application_security/sast/customize_rulesets.md), [IaC Scanning](../../user/application_security/iac_scanning/_index.md) 또는 [Secret Detection](../../user/application_security/secret_detection/pipeline/_index.md)에 대한 규칙 집합 사용자 지정을 둘 이상의 프로젝트에서 공유할 수 있습니다.

규칙 집합을 공유하면 다음을 할 수 있습니다:

- [미리 정의된 규칙 비활성화](../../user/application_security/sast/customize_rulesets.md) \- 프로젝트에서 초점을 맞추고 싶지 않은 규칙입니다.
- [미리 정의된 규칙의 필드 변경](../../user/application_security/sast/customize_rulesets.md) \- 설명, 메시지, 이름 또는 심각도를 포함하여 조직 기본 설정을 반영합니다. 예를 들어 규칙의 기본 심각도를 조정하거나 결과를 재구성하는 방법에 대한 정보를 추가할 수 있습니다.
- [사용자 지정 규칙 집합 빌드](../../user/application_security/sast/customize_rulesets.md) \- 규칙을 추가하거나 바꿉니다. 이 옵션은 일부 분석기에서만 사용할 수 있습니다.

이 영역의 추가 개선 사항은 [이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/257928)에서 논의됩니다.

### CI/CD: `needs`를 `rules`에서 사용 {#cicd-use-needs-in-rules}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#rulesneeds) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)

{{< /details >}}

[needs:](../../ci/yaml/_index.md#needs) 키워드는 작업 간의 종속성 관계를 정의하며, 작업을 단계 순서로 실행되도록 설정할 수 있습니다. 이 릴리스에서는 특정 `rules` 조건에 대해 이 관계를 정의할 수 있는 기능을 추가했습니다. 조건이 규칙과 일치하면 작업의 `needs` 구성이 규칙의 `needs`로 완전히 바뀝니다. 정의된 조건을 기반으로 작업이 정상보다 더 일찍 시작될 수 있을 때 파이프라인을 가속화하는 데 도움이 될 수 있습니다. 이를 사용하여 시작하기 전에 작업이 이전 작업이 완료될 때까지 기다리도록 강제할 수도 있으며 이제 더 유연한 `needs` 옵션을 사용할 수 있습니다!

### CI/CD 파이프라인 및 작업의 UI 아름답게 꾸미기 {#beautify-the-ui-of-cicd-pipelines-and-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/pipelines/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/394768)

{{< /details >}}

GitLab에서 가장 많이 사용되는 기능 중 하나는 CI/CD입니다. 16.1에서는 CI/CD 파이프라인 및 작업 목록 보기의 사용성과 경험 개선, 그리고 파이프라인 세부 정보 페이지를 개선하는 데 중점을 두었습니다. 이제 찾고 있는 정보를 더 쉽게 찾을 수 있습니다! 변경 사항에 대해 의견이 있으면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/414756)에서 의견을 나누고 싶습니다.

### Linux의 GitLab SaaS 러너에 대한 스토리지 증가 {#increased-storage-for-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/384223)

{{< /details >}}

vCPU 및 RAM에서 [GitLab.com SaaS 러너](../../ci/runners/hosted_runners/linux.md)를 최근에 확대한 후, 이제 `medium` 및 `large` 머신 유형의 스토리지도 증가시켰습니다.

이제 GitLab CI/CD와 완전히 통합된 안전한 온디맨드 GitLab 러너 Linux 환경이 필요한 더 큰 애플리케이션을 원활하게 빌드, 테스트 및 배포할 수 있습니다.

### CI/CD 작업 토큰 범위 API 엔드포인트 {#cicd-job-token-scope-api-endpoint}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/ci_job_token.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)

{{< /details >}}

GitLab 16.0에서 [기본 CI/CD 작업 토큰(`CI_JOB_TOKEN`) 범위가 변경](../../ci/jobs/ci_job_token.md)되었습니다. 모든 새 프로젝트의 경우. 이는 새 프로젝트의 보안을 증가시켰지만 프로젝트 생성 자동화를 사용한 사용자에게 추가 단계를 추가했습니다. 작업 토큰 범위도 구성해야 할 수 있는 자동화는 GraphQL(또는 UI에서 수동)을 사용해서만 수행할 수 있었으며, REST API는 불가능했습니다.

REST API를 통해서도 이 설정을 구성할 수 있도록 [Gerardo Navarro](https://gitlab.com/gerardo-navarro)는 16.1에서 작업 토큰 범위를 제어할 새로운 엔드포인트를 추가했습니다. 프로젝트에서 Maintainer 이상의 역할이 있는 사용자가 사용할 수 있습니다. 이 훌륭한 기여에 감사합니다 Gerardo!

### 러너 세부 정보 - 구성을 공유하는 러너 통합 {#runner-details---consolidate-runners-sharing-a-configuration}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-runner-configuration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/409388/)

{{< /details >}}

새로운 러너 생성 방법을 통해 동일한 기능이 있는 여러 러너를 등록해야 할 수 있는 시나리오에 대해 러너 구성을 재사용할 수 있습니다. 동일한 인증 토큰으로 등록된 러너는 구성을 공유하고 새로운 세부 정보 보기에서 그룹화됩니다.

### GitLab 러너 16.1 {#gitlab-runner-161}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

또한 오늘 GitLab 러너 16.1을 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [Azure Virtual Machines용 GitLab 러너 Fleeting 플러그인 (실험용)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29410). 이 기여에 대해 [vincent_stchu](https://gitlab.com/vincent_stchu)에게 감사합니다!

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/-/blob/16-1-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.1)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
