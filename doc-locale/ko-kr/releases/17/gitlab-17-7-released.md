---
stage: Release Notes
group: Monthly Release
date: 2024-12-19
title: "GitLab 17.7 릴리스 정보"
description: "새로운 플래너 사용자 역할과 함께 GitLab 17.7 릴리스"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 12월 19일, GitLab 17.7이 다음의 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Vedant Jain {#this-months-notable-contributor-vedant-jain}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Vedant는 능동적인 기여 접근법, 전달에 대한 의지, 협업 능력으로 알려진 뛰어난 커뮤니티 기여자입니다. 그는 피드백을 수용하고 이를 자신의 작업에 반영하며, 필요할 때 도움을 구하는 데 능숙하여 기여가 완료될 뿐만 아니라 GitLab의 표준을 충족하도록 보장합니다.

그의 기여에는 [작업 항목 속성을 단일 목록/보드로 추상화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172191), [작업 항목의 메타데이터 정렬](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173033), 그리고 [작업 항목 위젯의 축소된 상태 기억](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171228)으로 프로젝트 관리 프로세스를 간소화하는 것이 포함됩니다. Vedant는 또한 문서로의 UI 링크를 수정하여([1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170633), [2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170534)) 제품 전체의 사용자 경험을 개선하기 위한 중요한 노력의 일부로 기술 문서 작성 팀을 도왔습니다.

[Amanda Rueda](https://gitlab.com/amandarueda), Sr. GitLab의 제품 관리자, 제품 계획담당자가 Vedant를 추천했으며 그의 능동적이고 커뮤니티 중심의 사고방식을 강조했습니다. "Vedant의 작업은 사용자 요구를 해결할 뿐만 아니라 그의 기여를 통해 보다 안정적이고 신뢰할 수 있는 GitLab 환경을 공동으로 만들고 있습니다. 버그 수정, 사용성 개선, 유지보수 노력에 기여함으로써 제품의 전반적인 품질을 향상시키는 데 중요한 역할을 했습니다. 그의 능동적인 접근 방식과 교차 그룹 기여는 반복, 고객 협업, 지속적인 개선이라는 GitLab의 핵심 가치를 체현하며 그를 커뮤니티의 뛰어난 기여자로 만듭니다."

"제 기여를 성취하는 데 도움을 주신 모든 분께 감사드립니다"라고 Vedant는 말합니다. "좋은 영향을 미칠 수 있어서 정말 감사하고 더 많은 기여를 기대합니다."

Vedant는 현대적 데이터 팀을 위한 활동 메타데이터 플랫폼인 Atlan의 프론트엔드 엔지니어이자 2024 Google Summer of Code 멘토입니다.

Vedant의 모든 기여와 GitLab에 기여한 모든 오픈 소스 커뮤니티에 정말 감사합니다!

## 주요 기능 {#primary-features}

### 새로운 플래너 사용자 역할 {#new-planner-user-role}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/permissions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/482733)

{{< /details >}}

새로운 플래너 역할을 도입하여 [권한](../../user/permissions.md)을 과도하게 할당하지 않으면서 에픽, 로드맵, 칸반 보드 같은 민첩한 계획 도구에 대한 맞춤형 액세스를 제공합니다. 이 변경은 워크플로우를 보안 상태로 유지하고 최소 권한 원칙에 맞춰 더 효과적으로 협업하도록 도와줍니다.

### 인스턴스 관리자가 활성화할 수 있는 통합 제어 {#instance-administrators-can-control-which-integrations-can-be-enabled}

<!-- categories: Settings -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/project_integration_management.md#integration-allowlist) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)

{{< /details >}}

인스턴스 관리자는 이제 GitLab 인스턴스에서 활성화할 수 있는 통합을 제어하기 위해 허용 목록을 구성할 수 있습니다. 빈 허용 목록이 구성되면 인스턴스에서 통합이 허용되지 않습니다. 허용 목록이 구성되면 새로운 GitLab 통합은 기본적으로 허용 목록에 없습니다.

이전에 활성화된 통합이 나중에 허용 목록 설정으로 차단되면 비활성화됩니다. 이러한 통합이 다시 허용되면 기존 구성과 함께 다시 활성화됩니다.

### 직접 전송에서 사용 가능한 새로운 사용자 기여 및 멤버십 매핑 {#new-user-contribution-and-membership-mapping-available-in-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/group/import/direct_transfer_migrations.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)

{{< /details >}}

[직접 전송](../../user/group/import/_index.md)으로 GitLab 인스턴스 간에 마이그레이션할 때 새로운 사용자 기여 및 멤버십 매핑 방법을 사용할 수 있습니다. 이 기능은 가져오기 프로세스를 관리하는 사용자와 기여 재할당을 받는 사용자 모두에게 유연성과 제어를 제공합니다. 새로운 방법을 사용하면 다음을 수행할 수 있습니다:

- 가져오기가 완료된 후 대상 인스턴스의 기존 사용자에게 멤버십 및 기여를 재할당합니다. 가져오는 모든 멤버십 및 기여는 먼저 자리 표시자 사용자에게 매핑됩니다. 모든 기여는 대상 인스턴스에서 재할당할 때까지 자리 표시자와 연결된 것으로 표시됩니다.
- 원본 및 대상 인스턴스에서 다른 이메일 주소를 가진 사용자에 대한 멤버십 및 기여를 매핑합니다.

대상 인스턴스의 사용자에게 기여를 재할당하면 사용자는 재할당을 수락하거나 거부할 수 있습니다.

더 많은 정보를 보려면 [사용자 기여 및 멤버십 매핑으로 마이그레이션 간소화](https://about.gitlab.com/blog/streamline-migrations-with-user-contribution-and-membership-mapping/)를 참조하세요. 피드백을 남기려면 [이슈 502565](https://gitlab.com/gitlab-org/gitlab/-/issues/502565)에 댓글을 추가하세요.

### 후속 스캔에서 발견되지 않은 취약성 자동 해결 {#auto-resolve-vulnerabilities-when-not-found-in-subsequent-scans}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/vulnerability_management_policy.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/5708)

{{< /details >}}

GitLab의 [보안 스캔 도구](../../user/application_security/_index.md)는 애플리케이션 코드에서 알려진 취약성과 잠재적 약점을 식별하는 데 도움이 됩니다. 기능 브랜치의 스캔은 머지 전에 수정할 수 있도록 새로운 약점이나 취약성을 표시합니다. 프로젝트의 기본 브랜치에 이미 있는 취약성의 경우, 기능 브랜치에서 이를 수정하면 다음 기본 브랜치 스캔이 실행될 때 취약성을 더 이상 감지되지 않은 것으로 표시합니다. 더 이상 감지되지 않는 취약성을 아는 것이 유용하지만, 각각을 수동으로 해결된 것으로 표시하여 닫아야 합니다. 새로운 [활동 필터](../../user/application_security/vulnerability_report/_index.md#activity-filter)와 [상태 일괄 변경](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities)을 사용하더라도 해결할 것이 많으면 시간이 많이 걸릴 수 있습니다.

더 이상 자동화된 스캔으로 감지되지 않을 때 취약성을 자동으로 해결됨으로 설정하려는 사용자를 위해 새로운 정책 유형인 *취약성 관리 정책*을 소개합니다. 새로운 Auto-resolve 옵션으로 새로운 정책을 구성하고 적절한 프로젝트에 적용하기만 하면 됩니다. 특정 심각도의 취약성이나 특정 보안 스캐너에서의 취약성만 Auto-resolve하도록 정책을 구성할 수 있습니다. 적용되면 다음 프로젝트 기본 브랜치 스캔이 실행될 때 더 이상 발견되지 않는 기존 취약성은 해결됨으로 표시됩니다. 이 작업은 활동 메모, 작업이 발생한 타임스탬프, 그리고 취약성이 제거된 것으로 결정된 파이프라인으로 취약성 기록을 업데이트합니다.

### UI에서 개인, 프로젝트, 그룹 액세스 토큰 회전 {#rotate-personal-project-and-group-access-tokens-in-the-ui}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md#rotate-a-personal-access-token) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)

{{< /details >}}

이제 UI를 사용하여 개인, 프로젝트, 그룹 액세스 토큰을 회전할 수 있습니다. 이전에는 API를 사용하여 이를 수행해야 했습니다.

기여해주신 [shangsuru](https://gitlab.com/shangsuru)님께 감사드립니다!

### 프로젝트 전체에서 CI/CD 구성 요소 사용 추적 {#track-cicd-component-usage-across-projects}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../api/graphql/reference/_index.md#cicatalogresourcecomponentusage) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/466575)

{{< /details >}}

중앙 DevOps 팀은 파이프라인 전체에서 CI/CD 구성 요소가 어디에 사용되는지 추적하여 이를 더 잘 관리하고 최적화해야 하는 경우가 많습니다. 가시성이 없으면 오래된 구성 요소 사용을 식별하고, 채택률을 이해하거나, 구성 요소 수명 주기를 지원하기가 어렵습니다.

이를 해결하기 위해 DevOps 팀이 조직의 파이프라인 전체에서 구성 요소가 사용되는 프로젝트 목록을 볼 수 있도록 하는 새로운 GraphQL 쿼리를 추가했습니다. 이 기능은 중요한 인사이트를 제공함으로써 DevOps 팀이 생산성을 향상하고 더 나은 결정을 내릴 수 있도록 지원합니다.

### Linux Arm의 소규모 호스팅 러너를 모든 티어에 제공 {#small-hosted-runner-on-linux-arm-available-to-all-tiers}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501423)

{{< /details >}}

GitLab.com의 Linux Arm에 대한 소규모 호스팅 러너를 도입할 수 있어 기쁩니다. 모든 티어에서 사용 가능합니다. 이 2vCPU Arm 러너는 GitLab CI/CD와 완전히 통합되어 있으며 Arm 아키텍처에서 애플리케이션을 기본적으로 빌드하고 테스트할 수 있습니다.

업계에서 가장 빠른 CI/CD 빌드 속도를 제공하기로 결심했으며, 팀들이 더 짧은 피드백 사이클을 달성하고 궁극적으로 소프트웨어를 더 빠르게 제공하는 것을 기대합니다.

## 규모 및 배포 {#scale-and-deployments}

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

버그로 인해 GitLab 17.6 이전 버전의 FIPS Linux 패키지는 시스템 Libgcrypt를 사용하지 않았지만 일반 Linux 패키지와 함께 제공되는 동일한 Libgcrypt를 사용했습니다.

이 이슈는 AmazonLinux 2를 제외한 GitLab 17.7의 모든 FIPS Linux 패키지에 대해 수정되었습니다. AmazonLinux 2의 Libgcrypt 버전은 FIPS Linux 패키지와 함께 제공되는 GPGME 및 GnuPG 버전과 호환되지 않습니다.

AmazonLinux 2의 FIPS Linux 패키지는 일반 Linux 패키지와 함께 제공되는 동일한 Libgcrypt를 계속 사용합니다. 그렇지 않으면 GPGME 및 GnuPG를 다운그레이드해야 합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Advanced SAST에서 감지 정확도 개선 {#improved-detection-accuracy-in-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14685)

{{< /details >}}

Advanced SAST를 업데이트하여 다음 취약성 클래스를 더 정확하게 감지합니다:

- C#: OS 명령 삽입 및 SQL 삽입.
- Go: 경로 순회.
- Java: 커밋 삽입, 헤더 또는 로그의 CRLF 삽입, 교차 사이트 요청 위조(CSRF), 부적절한 인증서 검증, 안전하지 않은 역직렬화, 안전하지 않은 리플렉션, 및 XML 외부 엔티티(XXE) 삽입.
- JavaScript: 코드 삽입.

또한 C#(ASP.NET) 및 Java(JSF, HttpServlet)의 사용자 입력 소스 감지를 개선하고 일관성을 위해 심각도 수준을 업데이트했습니다.

Advanced SAST가 각 언어에서 감지하는 취약성 유형을 확인하려면 [Advanced SAST 범위](../../user/application_security/sast/advanced_sast_coverage.md)를 참조하세요. 이 개선된 교차 파일, 교차 함수 스캔을 사용하려면 [Advanced SAST 활성화](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)를 참조하세요. 이미 Advanced SAST를 활성화한 경우 새 규칙은 [자동으로 활성화됩니다](../../user/application_security/sast/rules.md#how-rule-updates-are-released).

### KEV로 효율적인 위험 우선 순위 지정 {#efficient-risk-prioritization-with-kev}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/graphql/reference/_index.md#cveenrichmenttype) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11912)

{{< /details >}}

GitLab 17.7에서 알려진 악용된 취약성 카탈로그(KEV) 지원을 추가했습니다. [KEV 카탈로그](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)는 CISA에서 유지 관리하며 실제로 악용된 CVE의 목록을 선별합니다. KEV를 활용하여 스캔 결과의 우선 순위를 더 잘 정하고 취약성이 사용자 환경에 미칠 수 있는 잠재적 영향을 평가할 수 있습니다.

이 데이터는 GraphQL을 통해 구성 분석 사용자가 사용할 수 있습니다. GitLab UI에서 이 데이터를 표시하기 위한 [계획된 작업](https://gitlab.com/gitlab-org/gitlab/-/issues/427441)이 있습니다.

### Advanced SAST에 대해 확장된 코드 흐름 보기 {#expanded-code-flow-view-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)

{{< /details >}}

Advanced SAST [코드 흐름 보기](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)는 이제 취약성이 표시되는 모든 위치에서 사용할 수 있으며 다음을 포함합니다:

- [취약성 보고서](../../user/application_security/vulnerability_report/_index.md).
- [머지 리퀘스트 보안 위젯](../../user/application_security/sast/_index.md).
- [파이프라인 보안 보고서](../../user/application_security/detect/security_scanning_results.md).
- [머지 리퀘스트 변경 사항 보기](../../user/application_security/sast/_index.md#merge-request-changes-view).

새로운 보기는 GitLab.com에서 활성화됩니다. GitLab Self-Managed에서 새 보기는 GitLab 17.7(MR 변경 사항 보기) 및 GitLab 17.6(기타 모든 보기)부터 기본적으로 활성화됩니다. 지원되는 버전 및 기능 플래그에 대한 자세한 내용은 [코드 흐름 기능 가용성](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)을 참조하세요.

Advanced SAST에 대해 자세히 알아보려면 [공지 블로그](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/)를 참조하세요.

### GitLab Duo Chat의 새로운 `/help` 명령 {#new-help-command-in-gitlab-duo-chat}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/462122)

{{< /details >}}

GitLab Duo Chat의 강력한 기능을 알아보세요! 채팅 메시지 필드에 `/help`을 입력하여 할 수 있는 모든 것을 살펴보세요.

시도해보고 GitLab Duo Chat이 작업을 더 순조롭고 효율적으로 만들 수 있는 방법을 확인하세요.

### `environment.action: access` 및 `prepare` 설정이 `auto_stop_in` 타이머를 재설정 {#setting-environmentaction-access-and-prepare-resets-the-auto_stop_in-timer}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#environmentauto_stop_in) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)

{{< /details >}}

이전에 `action: prepare`, `action: verify`, `action: access` 작업을 `auto_stop_in` 설정과 함께 사용할 때 타이머가 재설정되지 않았습니다. 18.0부터 `action: prepare`와 `action: access`은 타이머를 재설정하는 반면 `action: verify`은 그대로 둡니다.

현재 `prevent_blocking_non_deployment_jobs` 기능 플래그를 활성화하여 새로운 구현으로 변경할 수 있습니다.

여러 breaking 변경은 `environment.action: prepare | verify | access` 값의 동작을 구분하기 위해 의도된 것입니다. `environment.action: access` 키워드는 타이머 재설정을 제외하고 현재 동작에 가장 가깝게 유지됩니다.

향후 호환성 이슈를 방지하려면 이러한 키워드의 사용을 검토해야 합니다. 이러한 제안된 변경 사항에 대해 자세히 알아보려면 다음 이슈를 참조하세요:

- [이슈 437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [이슈 437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [이슈 437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### Kubernetes 1.31 지원 {#kubernetes-131-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501390)

{{< /details >}}

이 릴리스는 2024년 8월에 릴리스된 Kubernetes 버전 1.31에 대한 전체 지원을 추가합니다. 앱을 Kubernetes에 배포하는 경우 이제 연결된 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

더 많은 정보를 보려면 [Kubernetes 지원 정책 및 지원되는 기타 Kubernetes 버전](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)을 참조하세요.

### CI/CD 작업에서 네임스페이스 및 Flux 리소스 경로 설정 {#set-namespace-and-flux-resource-path-from-cicd-job}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)

{{< /details >}}

Kubernetes 대시보드를 사용하려면 환경 설정에서 Kubernetes 연결을 위한 에이전트를 선택하고 선택적으로 네임스페이스와 조정 상태를 추적할 Flux 리소스를 구성해야 합니다. GitLab 17.6에서 CI/CD 구성으로 에이전트를 선택하기 위한 지원을 추가했습니다. 그러나 네임스페이스와 Flux 리소스를 구성하려면 여전히 UI를 사용하거나 API를 호출해야 했습니다. 17.7에서는 `environment.kubernetes.namespace`과 `environment.kubernetes.flux_resource_path` 속성과 함께 CI/CD 구문을 사용하여 대시보드를 완전히 구성할 수 있습니다.

### 자격 증명 인벤토리의 그룹 및 프로젝트 액세스 토큰 {#group-and-project-access-tokens-in-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../administration/credentials_inventory.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/498333)

{{< /details >}}

그룹 및 프로젝트 액세스 토큰은 이제 GitLab.com의 자격 증명 인벤토리에서 볼 수 있습니다. 이전에는 개인 액세스 토큰과 SSH 키만 표시되었습니다. 인벤토리의 추가 토큰 유형은 그룹 전체의 자격 증명에 대한 더 완전한 그림을 제공합니다.

### 확장된 토큰 만료 알림 {#extended-token-expiration-notifications}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../security/tokens/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)

{{< /details >}}

이전에는 토큰 만료 이메일 알림이 만료 7일 전에만 전송되었습니다. 이제 이러한 알림이 만료 30일 및 60일 전에도 전송됩니다. 증가된 빈도와 알림의 날짜 범위는 사용자가 곧 만료될 수 있는 토큰을 더 잘 인식하도록 합니다.

### Unicode 15.1 이모지 지원 🦖🍋‍🟩🐦‍🔥 {#unicode-151-emoji-support-}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](https://gitlab-org.gitlab.io/ruby/gems/tanuki_emoji/) \| [관련 이슈](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji/-/issues/28)

{{< /details >}}

이전 버전의 GitLab에서는 이모지 지원이 이전 Unicode 표준으로 제한되어 일부 최신 이모지를 사용할 수 없었습니다.

GitLab 17.7은 Unicode 15.1에 대한 지원을 제공하여 최신 이모지 추가를 가져옵니다. 이는 t-렉스 🦖, 라임 🍋‍🟩, 피닉스 🐦‍🔥 같은 흥미로운 새로운 옵션을 포함하여 최신 기호로 자신을 표현할 수 있습니다.

또한 이 업데이트는 이모지 다양성을 향상시켜 문화, 언어, 정체성 전반에서 더 큰 표현을 보장하며 플랫폼에서 소통할 때 모두가 포함된 것으로 느껴지도록 도와줍니다.

### 원하는 텍스트 편집기를 기본값으로 설정 {#set-your-preferred-text-editor-as-default}

<!-- categories: Text Editors -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/preferences.md#set-the-default-text-editor) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/423104)

{{< /details >}}

이 버전에서는 더 개인화된 편집 경험을 위해 기본 텍스트 편집기를 설정할 수 있는 기능을 도입합니다. 이 변경을 통해 리치 텍스트 편집기, 일반 텍스트 편집기 중에서 선택하거나 기본값을 선택하지 않아 콘텐츠를 만들고 편집하는 방식에 유연성을 제공할 수 있습니다.

이 업데이트는 편집기 인터페이스를 개별 기본 설정이나 팀 표준과 맞춰 더 원활한 워크플로우를 보장합니다. 이 개선을 통해 GitLab은 모든 사용자에 대한 사용자 지정 및 사용성을 우선시합니다.

### 액세스 토큰에 대한 새로운 설명 필드 {#new-description-field-for-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)

{{< /details >}}

개인, 프로젝트, 그룹 또는 사칭 액세스 토큰을 만들 때 이제 선택적으로 해당 토큰에 대한 설명을 입력할 수 있습니다. 이는 토큰이 어디서 어떻게 사용되는지 등 토큰에 대한 추가 컨텍스트를 제공하는 데 도움이 됩니다.

### API로 그룹에서 보안 푸시 보호 활성화 {#enable-secret-push-protection-in-your-groups-with-apis}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/group_security_settings.md)

{{< /details >}}

이 릴리스를 통해 [REST API](../../api/group_security_settings.md) 및 [GraphQL API](../../api/graphql/reference/_index.md#mutationsetgroupsecretpushprotection)를 통해 그룹의 모든 프로젝트에서 보안 푸시 보호를 활성화할 수 있습니다. 이를 통해 프로젝트별 대신 그룹별로 보안 푸시 보호를 효율적으로 활성화할 수 있습니다. 푸시 보호가 활성화되거나 비활성화될 때마다 감사 이벤트가 기록됩니다.

### 엔터프라이즈 사용자를 나열하는 새로운 API 끝점 {#new-api-endpoint-to-list-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../api/group_enterprise_users.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438366)

{{< /details >}}

그룹 소유자는 이제 전용 API 끝점을 사용하여 엔터프라이즈 사용자 및 관련된 모든 속성을 나열할 수 있습니다.

### 사용자 지정 역할에서 소유자 기본 역할 제거 {#remove-owner-base-role-from-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md#create-a-custom-member-role) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/474273)

{{< /details >}}

권한이 가산이기 때문에 추가 가치를 제공하지 않으므로 사용자 지정 역할을 만들 때 소유자 기본 역할을 더 이상 사용할 수 없습니다. 소유자 기본 역할이 있는 기존 사용자 지정 역할은 이 변경의 영향을 받지 않습니다.

### 준수 센터를 위한 네비게이션 및 사용성 개선 {#navigation-and-usability-improvements-for-the-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_frameworks_report.md)

{{< /details >}}

그룹과 프로젝트 모두에 대한 준수 센터의 사용자 경험을 반복적이고 중요한 개선 사항을 계속 제공합니다.

GitLab 17.7에서는 두 가지 핵심 개선 사항을 제공했습니다:

- 사용자는 이제 준수 센터의 **프로젝트** 탭에서 그룹별로 필터링할 수 있으며, 이는 사용자에게 적절한 프로젝트와 해당 프로젝트에 첨부된 준수 프레임워크를 적용, 필터링 및 검색할 수 있는 다른 옵션을 제공합니다.
- 프로젝트의 준수 센터는 이제 **프레임워크** 탭을 가지고 있으며, 이를 통해 사용자는 해당 특정 프로젝트에 첨부된 준수 프레임워크를 검색할 수 있습니다.

프레임워크를 추가하거나 편집하는 것은 여전히 프로젝트가 아닌 그룹에서 수행됩니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.7)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
