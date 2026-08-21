---
stage: Release Notes
group: Monthly Release
date: 2025-06-19
title: "GitLab 18.1 릴리스 정보"
description: "GitLab 18.1이 Maven 가상 레지스트리 베타 버전과 함께 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 6월 19일, GitLab 18.1이 다음과 같은 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Chaitanya Sonwane {#this-months-notable-contributor-chaitanya-sonwane}

Chaitanya Sonwane은 지속적인 인증 개선을 통해 GitLab의 보안 기능을 강화합니다. [2025년에 13개의 병합된 기여](https://contributors.gitlab.com/users/chaitanyason9?fromDate=2025-01-01&toDate=2025-12-31)를 통해 자격증 인벤토리 필터링, 서비스 계정 관리, 작업 항목 유용성을 개선했습니다. 이전에 [GitLab 17.11에서 주요 기능](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#token-statistics-for-service-account-management)을 제공했으며, 서비스 계정의 토큰 통계로 "한눈에 보기" 정보를 제공하여 서비스 계정을 더 쉽게 관리할 수 있게 했습니다. 현재 [작업 항목 목록 정렬 설정을 컨텍스트별로 개선](https://gitlab.com/gitlab-org/gitlab/-/issues/503587)하고 있으며, GitLab의 제품 계획에서 사용자 경험을 더욱 향상시키고 있습니다.

Chaitanya의 작업은 GitLab 조직의 보안을 직접 강화하고 프로젝트 전반에서 서비스 계정 사용에 대한 더 나은 가시성을 제공합니다. 이제 팀이 자격증을 더 효과적으로 추적하고 순환할 수 있습니다. 이는 보안 취약성을 야기하는 고아 또는 잊혀진 자격증의 위험을 줄입니다.

"Chaitanya의 자격증 인벤토리 및 서비스 계정에 대한 기여는 보안 분야의 매우 소중한 기여입니다"라고 [Eduardo Sanz-Garcia](https://gitlab.com/eduardosanz), 인증 그룹의 수석 프론트엔드 엔지니어, 소프트웨어 공급망 보안 스테이지가 말했습니다. Eduardo는 GitLab 인증 팀의 추천을 지원했습니다.

"Chaitanya는 토큰 통계 개념 구현에 중요한 역할을 했습니다"라고 Eduardo는 덧붙였습니다. "자격증 인벤토리 작업은 자격증의 추적성과 모니터링을 향상시키기 위해 크게 요청된 기능을 제공했습니다. 이는 훌륭한 기여였습니다!"

Chaitanya는 TATA AIG의 소프트웨어 엔지니어입니다. 자신의 기여에 대한 개선을 적극적으로 처리하고 일관되게 후속 조치합니다.

GitLab의 보안 기초와 나머지 제품에 기여해 주신 Chaitanya에게 감사드립니다!

## 주요 기능 {#primary-features}

### 이제 Maven 가상 레지스트리를 베타에서 사용할 수 있습니다 {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/packages/virtual_registry/maven/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

Maven 가상 레지스트리는 GitLab에서 Maven 종속성 관리를 단순화합니다. Maven 가상 레지스트리 없이는 Maven Central, 프라이빗 리포지토리 또는 GitLab 패키지 레지스트리에서 종속성에 액세스하도록 각 프로젝트를 구성해야 합니다. 이 방식은 순차적 리포지토리 쿼리로 빌드를 느리게 하고 보안 감사 및 규정 준수 보고를 복잡하게 합니다.

Maven 가상 레지스트리는 여러 업스트림 리포지토리를 단일 엔드포인트 뒤에 집계하여 이러한 이슈를 해결합니다. 플랫폼 엔지니어는 한 개의 URL을 통해 Maven Central, 프라이빗 레지스트리 및 GitLab 패키지 레지스트리를 구성할 수 있습니다. 지능형 캐싱은 빌드 성능을 개선하고 GitLab의 인증 시스템과 통합됩니다. 조직은 구성 오버헤드 감소, 빠른 빌드, 향상된 보안 및 규정 준수를 위한 중앙 집중식 액세스 제어를 누립니다.

Maven 가상 레지스트리는 현재 GitLab.com과 GitLab Self-Managed 모두에서 GitLab Premium 및 Ultimate 고객을 위해 베타에서 사용할 수 있습니다. GA 릴리스에는 레지스트리 구성을 위한 웹 기반 사용자 인터페이스, 공유 가능한 업스트림 기능, 캐시 관리를 위한 수명 주기 정책 및 향상된 분석과 같은 추가 기능이 포함됩니다. 현재 베타 제한 사항에는 최상위 그룹당 최대 20개의 가상 레지스트리와 가상 레지스트리당 20개의 업스트림이 포함되며, 베타 기간 동안 API 전용 구성을 사용할 수 있습니다.

최종 릴리스를 형성하는 데 도움이 되도록 Maven 가상 레지스트리 베타 프로그램에 참여할 엔터프라이즈 고객을 초대합니다. 베타 참가자는 기능에 조기에 액세스하고, GitLab 제품 팀과의 직접 참여, 평가 중 우선 지원을 받을 것입니다. 베타 프로그램에 참여하려면 [이슈 498139](https://gitlab.com/gitlab-org/gitlab/-/issues/498139)에서 관심을 표시하고 사용 사례 세부 정보를 제공하고, [이슈 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045)에서 피드백과 제안을 공유하세요.

### Duo Code Review는 이제 일반적으로 사용 가능합니다 {#duo-code-review-is-now-generally-available}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review는 이제 일반적으로 사용 가능하며 프로덕션 사용 준비가 완료되었습니다. 이 AI 기반 코드 검토 어시스턴트는 머지 리퀘스트에 대한 지능형 자동화된 피드백을 제공하여 기존의 코드 검토 프로세스를 변환합니다. 인간 검토자가 참여하기 전에 잠재적 버그, 보안 취약성 및 코드 품질 이슈를 식별하여 전체 검토 프로세스를 더 효율적이고 철저하게 만듭니다. 포함 사항:

- **Automated initial review**: Duo Code Review는 코드 변경 사항을 분석하고 잠재적 이슈, 개선 사항 및 모범 사례에 대한 포괄적인 피드백을 제공합니다.
- **Interactive refinement**: 머지 리퀘스트 댓글에서 `@GitLabDuo`를 언급하여 특정 변경 사항이나 질문에 대한 대상 피드백을 받으세요.
- **Actionable suggestions**: 많은 제안을 브라우저에서 직접 적용하여 개선 프로세스를 간소화할 수 있습니다.
- **Context-aware analysis**: 변경된 파일에 대한 이해를 활용하여 관련성 있고 프로젝트별 권장 사항을 제공합니다.

코드 검토를 요청하려면:

- 머지 리퀘스트에서 `@GitLabDuo`을 `/assign_reviewer @GitLabDuo` 빠른 작업을 사용하여 검토자로 추가하거나, GitLab Duo를 검토자로 직접 할당합니다.
- 댓글에서 `@GitLabDuo`을 언급하여 특정 질문을 하거나 모든 토론 스레드에서 집중된 피드백을 요청하세요.
- 프로젝트 설정에서 자동 검토를 활성화하여 GitLab Duo가 모든 새 머지 리퀘스트를 자동으로 검토하도록 합니다.

Duo Code Review는 팀이 더 높은 코드 품질 표준을 유지하면서 수동 검토 사이클에 소요되는 시간을 줄이는 데 도움이 됩니다. 이슈를 조기에 포착하고 교육 피드백을 제공함으로써 개발 팀을 위한 품질 게이트와 학습 도구 모두로 작용합니다.

\*\*[개요 보기](https://www.youtube.com/watch?v=FlHqfMMfbzQ) \- 베타 릴리스에서 작동하는 Duo Code Review.

[이슈 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)에서 경험과 피드백을 공유하여 이 기능을 계속 개선하는 데 도움을 주세요.

### 기본 GitLab 자격증에 대한 손상된 비밀번호 검색 {#compromised-password-detection-for-native-gitlab-credentials}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/profile/user_passwords.md#compromised-password-detection) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/549865)

{{< /details >}}

GitLab.com은 이제 GitLab.com에 로그인할 때 계정 자격증을 안전하게 확인합니다. 비밀번호가 알려진 유출에 포함된 경우 GitLab은 배너를 표시하고 이메일 알림을 보냅니다. 이러한 알림에는 자격증을 업데이트하는 방법에 대한 지침이 포함됩니다.

최대 보안을 위해 GitLab은 GitLab에 고유한 강력한 비밀번호를 사용하고, 2단계 인증을 활성화하고, 계정 활동을 정기적으로 검토할 것을 권장합니다.

참고: 이 기능은 기본 GitLab 사용자명 및 비밀번호에만 사용할 수 있습니다. SSO 자격증은 확인되지 않습니다.

### [SLSA](https://slsa.dev/) Level 1 규정 준수 달성 (CI/CD 구성 요소 포함) {#achieve-slsa-level-1-compliance-with-cicd-components}

<!-- categories: Artifact Security -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../ci/pipeline_security/slsa/_index.md#sign-and-verify-slsa-provenance-with-a-cicd-component) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15859)

{{< /details >}}

이제 GitLab Runner에서 생성한 SLSA 규정 준수 [아티팩트 프로비너스 메타데이터](../../ci/runners/configure_runners.md#artifact-provenance-metadata)에 서명하고 검증하기 위한 GitLab의 새로운 CI/CD 구성 요소를 사용하여 SLSA Level 1 규정 준수를 달성할 수 있습니다. 구성 요소는 [Sigstore Cosign 기능](../../ci/yaml/signing_examples.md)을 CI/CD 워크플로우에 쉽게 통합할 수 있는 재사용 가능한 모듈로 래핑합니다.

## 규모 및 배포 {#scale-and-deployments}

### 코드 검색에서 파일당 여러 일치 {#multiple-matches-per-file-in-code-search}

<!-- categories: Code Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../integration/zoekt/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13127)

{{< /details >}}

정확한 코드 검색(베타)은 이제 동일한 파일의 여러 검색 결과를 단일 보기로 통합합니다. 이 개선 사항:

- 분리된 행을 표시하는 대신 인접한 일치 간의 컨텍스트를 유지합니다.
- 일치가 서로 가까울 때 중복 콘텐츠를 제거하여 시각적 혼란을 줄입니다.
- 파일당 일치 수를 명확하게 표시하여 탐색을 향상합니다.
- 편집기에서 보는 것처럼 코드를 표시하여 가독성을 개선합니다.

이 변경으로 리포지토리 전체에서 코드 패턴을 찾고 이해하는 것이 더욱 효율적입니다.

### GraphQL API에서 `accessLevels` 인수에 대한 새로운 `projectMembers` {#new-accesslevels-argument-for-projectmembers-in-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../api/graphql/reference/_index.md#projectprojectmembers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/541386)

{{< /details >}}

GraphQL API에 `accessLevels` 인수가 `projectMembers` 필드에 추가되었음을 발표하게 되어 기쁩니다. 이 인수를 사용하여 API 호출에서 직접 액세스 수준별로 프로젝트 멤버를 필터링합니다. 이전에는 프로젝트 멤버의 전체 목록을 가져와서 로컬로 필터를 적용해야 했으며, 이는 상당한 계산 오버헤드를 추가했습니다. 이제 프로젝트 권한을 분석하고 소유권 그래프를 생성하는 것이 더 빠르고 리소스 효율적입니다. 이 개선 사항은 복잡한 권한 구조로 대규모 배포를 관리하는 조직에 특히 가치가 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### DAST 검색 패리티 (시크릿 검색 기본 규칙 포함) {#dast-detection-parity-with-secret-detection-default-rules}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/dast/browser/checks/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/549990)

{{< /details >}}

DAST 분석기는 이제 GitLab의 시크릿 검색 분석기에서 사용하는 동일한 기본 시크릿 검색 규칙을 자동으로 수집합니다. 이 개선 사항은 양쪽에서 검색된 시크릿 유형의 일관성을 보장합니다.

### 외부 사용자 지정 컨트롤에 대한 `Name` 정의 {#define-a-name-for-external-custom-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/compliance/compliance_frameworks/_index.md#external-controls) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/527007)

{{< /details >}}

이전에는 사용자 지정 규정 준수 프레임워크를 만들 때 외부 사용자 지정 컨트롤의 이름을 정의할 수 없었으며, 이로 인해 GitLab 컨트롤 옆에 나열된 경우 외부 컨트롤을 식별하기 어려웠습니다.

이제 외부 사용자 지정 컨트롤을 정의할 때 워크플로우의 일부로 `Name` 필드를 추가했으므로, 여러 외부 사용자 지정 컨트롤을 만들고 각각을 고유한 이름으로 명확하게 정의할 수 있습니다.

### 규정 준수 프레임워크 UI에서 요구 사항에 대한 페이지네이션 {#pagination-for-requirements-in-compliance-frameworks-ui}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/compliance/compliance_frameworks/_index.md#add-requirements) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/531039)

{{< /details >}}

규정 준수 프레임워크를 만들 때 최대 50개의 요구 사항을 지정할 수 있습니다.

그러나 이 많은 요구 사항이 사용자 인터페이스에서 많은 공간을 차지하기 때문에 이 많은 요구 사항으로 규정 준수 프레임워크를 탐색하기가 매우 어려워집니다.

이 릴리스에서는 규정 준수 프레임워크에 많은 수의 요구 사항이 연결되어 있을 때 사용자가 더 쉽게 탐색하고, 찾고, 요구 사항을 선택할 수 있도록 요구 사항에 대한 페이지네이션을 도입했습니다.

### 규정 준수 센터의 UI 성능 및 필터링 개선 사항 {#ui-performance-and-filtering-improvements-for-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

규정 준수 센터에서 제공하는 UI 성능 및 필터링 옵션을 계속 개선했습니다. 이 릴리스에서 다음을 수행했습니다:

- **Edit Framework** 페이지의 UI 속도 및 성능을 개선했습니다. 특히 페이지에 많은 요구 사항과 프로젝트가 있는 경우입니다.
- 규정 준수 센터의 **Compliance status report** 탭에서 요구 사항, 프로젝트 또는 프레임워크별로 그룹화할 수 있도록 새로운 필터링 옵션을 도입했습니다.

이러한 개선 사항을 제공함으로써 규정 준수 센터 및 관련 기능이 규정 준수 센터를 정기적으로 사용하는 고객을 위해 계속해서 규모에 맞춰 성능을 발휘할 수 있도록 합니다.

### 규정 준수 상태 보고서의 컨트롤 상태 팝업 {#control-status-pop-up-in-the-compliance-status-report}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/compliance/compliance_center/compliance_status_report.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

규정 준수 상태 보고서의 컨트롤에는 세 가지 다른 상태가 있습니다:

- 통과
- 실패
- 대기중

요구 사항에 첨부된 컨트롤 수에 관계없이, 적어도 하나의 컨트롤이 '대기 중'이면 전체 요구 사항 행이 '대기 중'으로도 표시되었습니다. 이는 실패한 컨트롤을 시각화하기 위한 설정된 UX 패턴에서 벗어났으며, 요구 사항은 실패하는 컨트롤이 하나 이상 있어도 요구 사항과 연결된 컨트롤 수를 표시합니다.

"대기 중" 컨트롤에 대한 추가 컨텍스트 및 정보를 제공하기 위해 이제 요구 사항 행 상태에 마우스를 올렸을 때 팝업을 제공하며, 각 컨트롤의 상태가 나열됩니다. 이제 "대기 중"의 단일 상태만 표시하는 대신 어떤 컨트롤이 대기 중이고 어떤 컨트롤이 잠재적으로 성공하고 실패하는지 이해할 수 있습니다.

### 검토 패널을 통한 향상된 머지 리퀘스트 검토 경험 {#enhanced-merge-request-review-experience-with-review-panel}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../user/project/merge_requests/reviews/_index.md#submit-a-review) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/525841)

{{< /details >}}

머지 리퀘스트를 검토할 때, 검토를 제출하기 전에 제공한 모든 댓글과 피드백을 보는 것이 가치가 있을 수 있습니다. 이전에는 이 경험이 최종 댓글과 대기 중인 댓글을 보기 위한 추가 팝업 사이에 나뉘어 있었으므로 전체 개요를 얻기가 어려웠습니다.

코드 검토를 수행할 때, 이제 모든 대기 중인 초안 댓글을 하나의 조직화된 보기에 통합하는 전용 드로어에 액세스할 수 있습니다. 향상된 검토 패널은 검토 제출 인터페이스를 더 접근하기 쉬운 위치로 이동하고 대기 중인 댓글 수를 표시하는 번호가 매겨진 배지를 제공합니다. 패널을 열면 모든 초안 댓글이 스크롤 가능한 목록으로 정렬되어 제출하기 전에 피드백을 더 쉽게 검토하고 관리할 수 있습니다.

### 권한 확인을 통한 향상된 CODEOWNERS 파일 검증 {#enhanced-codeowners-file-validation-with-permission-checks}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../user/project/codeowners/troubleshooting.md#validate-your-codeowners-file) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15598)

{{< /details >}}

GitLab은 이제 기본 문법 검사를 넘어서는 CODEOWNERS 파일에 대한 향상된 검증을 제공합니다. CODEOWNERS 파일을 볼 때 GitLab은 자동으로 포괄적인 검증을 실행하여 머지 리퀘스트 워크플로우에 영향을 미치기 전에 문법 및 권한 이슈를 식별하는 데 도움을 줍니다.

향상된 검증은 CODEOWNERS 파일의 처음 200개의 고유한 사용자 및 그룹 참조를 확인하고 다음을 검증합니다:

- 참조된 모든 사용자 및 그룹이 프로젝트에 액세스할 수 있습니다.
- 사용자에게 머지 리퀘스트를 승인하는 데 필요한 권한이 있습니다.
- 그룹에는 최소 개발자 수준 액세스 권한 이상이 있습니다.
- 그룹에는 머지 리퀘스트 승인 권한이 있는 사용자가 최소 1명 포함되어 있습니다.

이 사전 검증은 구성 이슈를 조기에 포착하여 승인 워크플로우 중단을 방지하고, 코드 소유자가 머지 리퀘스트를 만들 때 실제로 검토 책임을 이행할 수 있는지 확인합니다.

### `postStart` 이벤트를 통한 사용자 지정 워크스페이스 초기화 {#custom-workspace-initialization-with-poststart-events}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/workspace/_index.md#user-defined-poststart-events)

{{< /details >}}

GitLab 워크스페이스는 이제 devfile의 사용자 지정 `postStart` 이벤트를 지원하여 워크스페이스 시작 후 자동으로 실행되는 명령을 정의할 수 있습니다. 이러한 이벤트를 사용하여:

- 개발 종속성을 설정합니다.
- 환경을 구성합니다.
- 수동 개입 없이 즉시 생산성을 위해 프로젝트를 준비하는 초기화 스크립트를 실행합니다.

### VS Code에서 다운스트림 파이프라인 작업 로그 보기 {#view-downstream-pipeline-job-logs-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](https://docs.gitlab.com/editor_extensions/visual_studio_code/cicd/) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)

{{< /details >}}

GitLab Workflow 확장 프로그램(VS Code)은 이제 편집기에서 직접 다운스트림 파이프라인의 작업 로그를 표시합니다. 이전에는 자식 파이프라인의 로그를 보기 위해 GitLab 웹 인터페이스로 전환해야 했습니다.

이 기능은 [GitLab Co-create 프로그램](https://about.gitlab.com/community/co-create/)을 통해 개발되었습니다. 이 기여를 해주신 Tim Ryan에게 특별히 감사드립니다!

### 비활성 개인 액세스 토큰 보기 {#view-inactive-personal-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/profile/personal_access_tokens.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425053)

{{< /details >}}

GitLab은 만료되거나 취소된 후 액세스 토큰을 자동으로 비활성화합니다. 이제 이러한 비활성 토큰을 검토할 수 있습니다. 이전에는 액세스 토큰이 비활성 상태가 된 후 더 이상 보이지 않았습니다. 이 변경은 이러한 토큰 유형의 추적성과 보안을 향상시킵니다.

### GitLab Query Language 보기의 에픽 지원 베타 {#epic-support-for-gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/glql/fields.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)

{{< /details >}}

GitLab Query Language (GLQL) 보기를 크게 개선했습니다. 이제 에픽을 쿼리의 유형으로 사용하여 그룹 전체에서 에픽을 검색하고 상위 에픽으로 쿼리할 수 있습니다!

이는 계획 및 추적 기능의 큰 진전이며, 에픽 수준에서 쿼리하고 구성하는 것이 그 어느 때보다 쉬워졌습니다.

### Advanced SAST를 위한 PHP 지원 {#php-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14273)

{{< /details >}}

GitLab Advanced SAST에 PHP 지원을 추가했습니다. 이 새로운 크로스 파일, 크로스 함수 스캔 지원을 사용하려면 [Advanced SAST 활성화](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)를 수행하세요. Advanced SAST를 이미 활성화한 경우 PHP 지원이 자동으로 활성화됩니다.

Advanced SAST가 각 언어에서 검색하는 취약성 유형을 보려면 [Advanced SAST 적용 범위 페이지](../../user/application_security/sast/advanced_sast_coverage.md)를 참조하세요.

### 종속성 목록에서 구성 요소 버전으로 필터링 {#filter-by-component-version-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dependency_list/_index.md#filter-dependency-list) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16431)

{{< /details >}}

종속성 목록은 이제 구성 요소의 버전 번호로 필터링을 지원합니다. 여러 버전을 선택할 수 있습니다 (예: `version=1.1,1.2,1.4`) 하지만 범위는 지원되지 않습니다. 이 기능은 그룹과 프로젝트 모두에서 사용할 수 있습니다.

### 파이프라인 실행 정책의 변수 우선 순위 컨트롤 {#variable-precedence-controls-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/policies/pipeline_execution_policies.md#variables_override-type) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16430)

{{< /details >}}

보안 팀은 보안 보증과 개발자 경험 간의 섬세한 균형을 유지합니다. 보안 스캔이 제대로 적용되도록 하는 것이 중요하지만, 보안 분석기는 개발 팀의 특정 입력이 필요하여 올바르게 실행될 수 있습니다. 변수 우선 순위 컨트롤을 사용하여 보안 팀은 이제 새로운 `variables_override` 구성 옵션을 통해 파이프라인 실행 정책에서 변수를 처리하는 방식에 대한 세분화된 제어를 가집니다.

이 새로운 구성을 사용하여 이제 다음을 수행할 수 있습니다:

- 프로젝트별 컨테이너 이미지 경로를 허용하는 컨테이너 스캔 정책을 적용합니다 (`CS_IMAGE`).
- `SAST_EXCLUDED_PATHS`와 같은 낮은 위험 변수를 허용하면서 `SAST_DISABLED`와 같은 높은 위험 변수를 차단합니다.
- 전역 CI/CD 변수를 사용하여 보호되는 (마스킹되거나 숨겨진) 전역 공유 자격증을 정의합니다 (예: `AWS_CREDENTIALS`). 프로젝트 수준 CI/CD 변수를 통해 적절한 프로젝트별 재정의를 허용합니다.

이 강력한 기능은 두 가지 접근 방식을 지원합니다:

- **Lock variables by default** (`allow: false`): 예외로 나열한 특정 변수를 제외한 모든 변수를 잠급니다.
- **Allow variables by default** (`allow: true`): 변수를 사용자 지정할 수 있도록 허용하지만 예외로 나열하여 중요한 위험을 제한합니다.

파이프라인 실행 정책이 CI/CD 작업의 소스일 때 추적성과 문제 해결을 개선하기 위해 정책에서 실행된 작업을 식별하기 위해 작업 로그도 도입하고 있습니다. 작업 로그는 변수 재정의의 영향에 대한 세부 정보를 제공하여 변수가 정책에 의해 재정의되거나 잠겨 있는지 이해하도록 도와줍니다.

**Real-world impact**

이 개선 사항은 보안 요구 사항과 개발자의 유연성 간의 격차를 해소합니다:

- 보안 팀은 프로젝트별 사용자 지정을 허용하면서 표준화된 스캔을 적용할 수 있습니다.
- 개발자는 정책 예외를 요청하지 않고 프로젝트별 변수에 대한 제어를 유지합니다.
- 조직은 개발 워크플로우를 방해하지 않고 일관된 보안 정책을 구현할 수 있습니다.

이 중요한 변수 제어 문제를 해결함으로써 GitLab은 조직이 소프트웨어를 효율적으로 전달하기 위해 팀이 필요한 유연성을 희생하지 않고 강력한 보안 정책을 구현할 수 있게 합니다.

### 봇 및 인간 사용자 필터링 {#filter-for-bot-and-human-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/moderate_users.md#view-users-by-type) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)

{{< /details >}}

설정된 GitLab 인스턴스는 종종 많은 수의 인간 및 봇 사용자가 있습니다. 이제 관리 영역의 사용자 목록을 사용자 유형별로 필터링할 수 있습니다. 사용자를 필터링하면 다음을 수행할 수 있습니다:

- 자동화된 계정과 별개로 인간 사용자를 빠르게 식별하고 관리합니다.
- 특정 사용자 유형에 대해 대상화된 관리 조치를 수행합니다.
- 사용자 감사 및 관리 워크플로우를 단순화합니다.

### 사용자 프로필의 [ORCID](https://orcid.org/) 식별자 {#orcid-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/profile/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/23543)

{{< /details >}}

GitLab은 이제 사용자 프로필의 ORCID 식별자를 지원하므로 GitLab이 연구자와 학계에 더욱 접근 가능하고 가치 있게 됩니다. [ORCID](https://orcid.org/) (Open Researcher and Contributor ID)는 연구자에게 다른 연구자와 구별되는 영구적인 디지털 식별자를 제공하고 연구자와 전문적 활동 간의 자동화된 연결을 지원하여 작업이 제대로 인정받도록 합니다.

이 기능은 [Daniel Le Berre](https://www.ouvrirlascience.fr/appointment-of-daniel-le-berre-as-the-national-coordinator-for-higher-education-and-research-software-forges-in-france/)의 감독 하에 Artois University의 대학원생 Thomas Labalette와 Erwan Hivin의 커뮤니티 기여로 개발되었으며, 학계의 오래된 요청을 해결합니다.

### 서비스 계정 파이프라인 알림 구독 {#subscribe-to-service-account-pipeline-notifications}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/profile/notifications.md#notifications-about-failed-pipeline-that-doesnt-exist) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/515629)

{{< /details >}}

이제 서비스 계정에서 트리거한 파이프라인 이벤트에 대한 알림을 구독할 수 있습니다. 파이프라인이 통과하거나 실패하거나 수정되면 알림이 전송됩니다. 이전에는 서비스 계정에 유효한 사용자 지정 이메일 주소가 있는 경우에만 알림이 서비스 계정의 이메일 주소로 전송되었습니다.

기여해 주신 [Densett](https://gitlab.com/[Densett](https://gitlab.com/Densett)), [Gilles Dehaudt](https://gitlab.com/tonton1728), [Lenain](https://gitlab.com/lenaing), [Geoffrey McQuat](https://gitlab.com/gmcquat), [Raphaël Bihoré](https://gitlab.com/rbihore)에게 감사합니다!

### Duo 취약성 해결을 위한 SAST 범위 증가 {#increased-sast-coverage-for-duo-vulnerability-resolution}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/534307)

{{< /details >}}

이전에는 다음 CWE (Common Weakness Enumeration) 식별자로 검색된 취약성을 수동으로 해결해야 했습니다:

- CWE-78 (명령 주입)
- CWE-89 (SQL 주입)

이제 Duo 취약성 해결이 이러한 취약성을 자동으로 수정할 수 있습니다.

### GitLab 러너 18.1 {#gitlab-runner-181}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 18.1도 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [GitLab 17.10 또는 17.11로 업그레이드하면 러너가 작업을 요청할 때 `404` 응답을 받을 수 있습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/543351).

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.1)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
