---
stage: Release Notes
group: Monthly Release
date: 2024-01-18
title: "GitLab 16.8 릴리스 정보"
description: "GitLab 16.8이 머지 리퀘스트 변경 사항 뷰의 정적 분석 결과와 함께 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 1월 18일, GitLab 16.8이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

Ted는 [오래되고 사용하지 않는 코드를 제거하여](https://gitlab.com/gitlab-org/gitlab/-/issues/420057) 저희의 헬퍼 파일에 상당한 기여를 했으며 다른 유지보수 작업을 처리했습니다. GitLab의 직원인 [Kerri Miller](https://gitlab.com/kerrizor)로부터 추천받았으며, "항상 화려하지는 않지만 중요한 일입니다"라고 말했습니다.

Ted는 Orange County를 기반으로 하는 프리랜서 소프트웨어 엔지니어이자 열성적인 등반가이며 고양이 애호가입니다.

GitLab의 제품 관리자인 [Viktor Nagy](https://gitlab.com/nagyv-gitlab)로부터 추천받았으며, "그는 Auto Deploy 작업 템플릿에 많은 누락된 테스트를 추가했으며 [agentk Helm 차트 문서](../../user/clusters/agent/install/_index.md#customize-the-helm-installation)를 개선했습니다"라고 말했습니다.

GitLab의 엔지니어인 [Lee Tickett](https://gitlab.com/leetickett-gitlab)은 "[Discord](https://discord.gg/gitlab)에서 커뮤니티 페어링 세션에 참여하고 있으며 팀 멤버들과 긴밀히 협력하여 머지 리퀘스트를 위해 크게 요청된 [검색 기능 개선](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)에 기여했습니다"라고 덧붙였습니다.

Martin은 독일 드레스덴을 기반으로 Deutsche Telekom MMS GmbH의 IT 아키텍트입니다.

GitLab의 주요 제품 관리자인 [Hannah Sutor](https://gitlab.com/hsutor)로부터 추천받았으며, "그는 [패스키를 사용하여 로그인할 수 있는 기능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135324)을 제안함으로써 저희의 전체 팀을 진전시켰습니다. Helio의 머지 리퀘스트는 종료되었지만 그의 기여는 깊이 있었으며 생각을 자극했으며, 그의 질문과 개방적인 논의는 저희의 비밀번호 없는 구현을 더욱 향상시킬 것입니다".

Helio는 Ruby와 오픈소스 소프트웨어에 대한 열정을 가진 소프트웨어 엔지니어입니다.

Ted, Martin, Helio에게 감사합니다! 🙌

## 주요 기능 {#primary-features}

### 머지 리퀘스트 변경 사항 뷰의 정적 분석 결과 {#static-analysis-findings-in-merge-request-changes-view}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/_index.md#merge-request-changes-view) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10959)

{{< /details >}}

정적 분석은 이제 머지 리퀘스트 변경 사항 뷰에서 결과를 표시하도록 지원합니다. 다른 곳으로 이동할 필요가 없습니다. 모두 한 곳에 통합되어 있습니다. UI는 더 간단한 경험을 위해 개선되었습니다. 세부 사항을 보려면 서랍을 열면 됩니다. 연결된 문서, 데모 비디오 및 롤아웃 이슈에서 자세히 알아보세요.

### Google Cloud Secret Manager 지원 {#google-cloud-secret-manager-support}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/secrets/gcp_secret_manager.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11739)

{{< /details >}}

Google Cloud Secret Manager에 저장된 보안 항목을 이제 쉽게 검색하고 CI/CD 작업에서 사용할 수 있습니다. 저희의 새로운 통합은 GitLab CI/CD를 통해 Google Cloud Secret Manager와 상호 작용하는 프로세스를 간소화하여 빌드 및 배포 프로세스를 효율화하는 데 도움이 됩니다! 이는 [GitLab과 Google Cloud가 더 잘 함께 작동하는](https://about.gitlab.com/blog/gitlab-google-partnership-s3c/) 여러 방법 중 하나일 뿐입니다!

### 워크스페이스는 이제 일반 공급 중입니다 {#workspaces-are-now-generally-available}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/_index.md)

{{< /details >}}

워크스페이스가 이제 일반 공급 중이며 개발자 효율성을 개선할 준비가 되어 있음을 알려드리게 되어 기쁩니다!

안전하고 온디맨드 원격 개발 환경을 만들어 종속성 관리 및 새 개발자 온보딩에 소요되는 시간을 줄이고 더 빠르게 가치를 전달하는 데 집중할 수 있습니다. 플랫폼에 구애받지 않는 접근 방식을 통해 기존 클라우드 인프라를 사용하여 워크스페이스를 호스트하고 데이터를 비공개로 안전하게 유지할 수 있습니다.

GitLab 16.0에서 도입된 이후 워크스페이스는 오류 처리 및 조정 개선, 비공개 프로젝트 및 SSH 연결 지원, 추가 구성 옵션 및 새로운 관리자 인터페이스를 받았습니다. 이러한 개선 사항은 워크스페이스가 이제 더 유연하고, 더 탄력적이며, 대규모로 더 쉽게 관리된다는 의미입니다.

### GitLab 관리자를 위해 2단계 인증 적용 {#enforce-2fa-for-gitlab-administrators}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../security/two_factor_authentication.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)

{{< /details >}}

자체 관리 인스턴스에서 GitLab 관리자가 2단계 인증(2FA)을 사용하도록 요구할지 여부를 이제 적용할 수 있습니다. 2FA를 모든 계정, 특히 관리자와 같은 권한 있는 계정에 사용하는 것이 좋은 보안 관행입니다. 이 설정이 적용되고 관리자가 이미 2FA를 사용하지 않는 경우, 다음 로그인 시 2FA를 설정해야 합니다.

### Maven 종속성 프록시로 빌드 속도 향상 {#speed-up-your-builds-with-the-maven-dependency-proxy}

<!-- categories: Dependency Management, Package Registry -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/packages/package_registry/dependency_proxy/_index.md)

{{< /details >}}

일반적인 소프트웨어 프로젝트는 패키지라고 부르는 다양한 종속성에 의존합니다. 패키지는 내부적으로 빌드 및 유지하거나 공개 리포지토리에서 소싱할 수 있습니다. 저희의 사용자 조사를 바탕으로 대부분의 프로젝트가 공개 및 비공개 패키지를 50/50 혼합으로 사용한다는 것을 알게 되었습니다. 패키지 설치 순서는 매우 중요합니다. 잘못된 패키지 버전을 사용하면 파이프라인에 주요 변경 사항 및 보안 취약성이 발생할 수 있기 때문입니다.

이제 GitLab 프로젝트에 하나의 외부 Java 리포지토리를 추가할 수 있습니다. 추가한 후 종속성 프록시를 사용하여 패키지를 설치할 때 GitLab은 먼저 프로젝트에서 패키지를 확인합니다. 찾지 못하면 GitLab은 외부 리포지토리에서 패키지를 가져오려고 시도합니다.

외부 리포지토리에서 패키지를 가져오면 GitLab 프로젝트로 가져옵니다. 다음에 해당 특정 패키지를 가져올 때는 외부 리포지토리가 아닌 GitLab에서 가져옵니다. 외부 리포지토리가 연결성 이슈가 있더라도 패키지가 종속성 프록시에 있으면 패키지를 가져오는 것이 계속 작동하여 파이프라인을 더 빠르고 안정적으로 만듭니다.

외부 리포지토리에서 패키지가 변경되면(예: 사용자가 버전을 삭제하고 다른 파일로 새 버전을 게시함) 종속성 프록시가 이를 감지합니다. 패키지를 무효화하므로 GitLab이 최신 버전을 가져옵니다. 이렇게 하면 올바른 패키지가 다운로드되고 보안 취약성을 줄이는 데 도움이 됩니다.

### 이슈 분석 보고서의 속도에 대한 더 깊은 인사이트 {#deeper-insights-into-velocity-in-the-issue-analytics-report}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/issues_analytics/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/233905)

{{< /details >}}

**이슈 분석** 보고서는 이제 한 달 동안 종료된 이슈의 수에 대한 정보를 포함하여 상세한 속도 분석을 허용합니다. 이러한 귀중한 추가로 GitLab 사용자는 이제 프로젝트와 관련된 동향에 대한 인사이트를 얻을 수 있으며 전체 소요 시간과 고객에게 제공하는 가치를 개선할 수 있습니다. **이슈 분석** 시각화는 매월 이슈 수가 있는 막대 차트를 포함하며 기본 기간은 13개월입니다. [Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)의 드릴다운에서 이 차트에 액세스할 수 있습니다.

### DORA 기반 산업 벤치마크를 사용한 새로운 조직 수준의 DevOps 뷰 {#new-organization-level-devops-view-with-dora-based-industry-benchmarks}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/426516)

{{< /details >}}

**DORA Performers score** 패널을 [Value Streams Dashboard](https://www.youtube.com/watch?v=EA9Sbks27g4)에 추가하여 다양한 프로젝트 전반에 걸친 조직의 DevOps 성능 상태를 시각화합니다. 이 새로운 시각화는 DORA 스코어(높음, 중간, 낮음)의 분석을 표시하므로 경영진은 조직의 DevOps 상태를 상향식으로 이해할 수 있습니다.

[4개의 DORA 지표](https://about.gitlab.com/solutions/value-stream-management/dora/#overview)는 GitLab에서 즉시 사용 가능하며, 이제 새로운 DORA 스코어를 사용하면 조직은 자신의 DevOps 성능을 [산업 벤치마크](https://dora.dev/) 또는 동료와 비교할 수 있습니다. 이러한 벤치마킹은 경영진이 다른 기업과의 관계에서 자신의 위치를 파악하고 모범 사례 또는 뒤처지고 있는 영역을 파악하는 데 도움이 됩니다.

Value Streams Dashboard를 개선하는 데 도움을 주기 위해 이 [설문조사](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4)에서 경험에 대한 피드백을 공유해 주세요.

## 규모 및 배포 {#scale-and-deployments}

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 16.8부터 `gitlab.rb` 파일에서 다음 서비스에 대한 구성을 생성하는 명령을 지정할 수 있으므로 일반 텍스트 암호가 노출되지 않습니다:

- GitLab Kubernetes Agent Server
- GitLab Workhorse
- GitLab Exporter

이는 Redis의 일반 텍스트 암호를 더 이상 `gitlab.rb`에 저장할 필요가 없다는 의미입니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### `patch-id` 지원으로 더 똑똑한 승인 재설정 {#smarter-approval-resets-with-patch-id-support}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)

{{< /details >}}

모든 변경 사항이 검토되고 승인되도록 하기 위해 머지 리퀘스트에 새 커밋이 추가될 때 모든 승인을 제거하는 것이 일반적입니다. 그러나 리베이스는 또한 리베이스가 새로운 변경 사항을 도입하지 않았더라도 기존 승인을 불필요하게 무효화하여 작성자가 재승인을 요청하도록 요구합니다.

머지 리퀘스트 승인은 이제 [`git-patch-id`](https://git-scm.com/docs/git-patch-id)에 맞춥니다. 이는 합리적으로 안정적이고 합리적으로 고유한 식별자로, 승인 재설정에 대한 더 똑똑한 결정을 가능하게 합니다. 리베이스 전후의 `patch-id`을 비교하여 승인을 재설정하고 검토가 필요한 새로운 변경 사항이 도입되었는지 확인할 수 있습니다.

재설정에 대한 경험에 대해 피드백이 있으면 [이슈 #435870](https://gitlab.com/gitlab-org/gitlab/-/issues/435870)에서 알려주세요.

### 파일 페이지에서 직접 blame 정보 보기 {#view-blame-information-directly-in-the-file-page}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/files/git_blame.md#view-blame-for-a-file)

{{< /details >}}

GitLab의 이전 버전에서 파일 blame을 보려면 다른 페이지에 액세스해야 했습니다. 이제 파일 페이지에서 직접 파일 blame 정보를 볼 수 있습니다.

### 워크스페이스당 CPU 및 메모리 사용량 설정 {#set-cpu-and-memory-usage-per-workspace}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

향상된 개발자 경험, 온보딩 및 보안은 클라우드 IDE 및 온디맨드 개발 환경으로의 더 많은 개발을 추진하고 있습니다. 그러나 이러한 환경은 증가된 인프라 비용에 기여할 수 있습니다. [devfile](../../user/workspace/_index.md#devfile)에서 프로젝트당 CPU 및 메모리 사용량을 이미 구성할 수 있습니다.

이제 워크스페이스당 CPU 및 메모리 사용량을 설정할 수도 있습니다. GitLab 에이전트 수준에서 요청 및 제한을 구성하여 개별 개발자가 과도한 양의 클라우드 리소스를 사용하는 것을 방지할 수 있습니다.

### Kubernetes 1.28 지원 {#kubernetes-128-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/432070)

{{< /details >}}

이 릴리스는 2023년 8월에 릴리스된 Kubernetes 버전 1.28에 대한 전체 지원을 추가합니다. 앱을 Kubernetes에 배포하는 경우 이제 연결된 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

Kubernetes 지원 정책 및 기타 지원되는 Kubernetes 버전에 대해 자세히 알아볼 수 있습니다.

### 새로운 사용자 지정 가능한 권한 {#new-customizable-permissions}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

사용자 지정 역할을 만드는 데 사용할 수 있는 5개의 새로운 기능이 있습니다:

- 프로젝트 액세스 토큰을 관리합니다.
- 그룹 액세스 토큰을 관리합니다.
- 그룹 멤버를 관리합니다.
- 프로젝트를 보관하는 기능입니다.
- 프로젝트를 삭제하는 기능입니다.

이러한 기능을 다른 기존 사용자 지정 기능과 함께 기본 역할에 추가하여 사용자 지정 역할을 만듭니다. 사용자 지정 역할을 사용하면 사용자가 작업을 수행하는 데 필요한 기능만 제공하고 불필요한 권한 상승을 줄이는 세분화된 역할을 정의할 수 있습니다.

### SAML SSO로 사용자 지정 역할 할당 {#assign-a-custom-role-with-saml-sso}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/saml_sso/_index.md#configure-gitlab) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/417285)

{{< /details >}}

SAML SSO로 프로비저닝될 때 만든 기본 역할로 사용자에게 사용자 지정 역할을 할당할 수 있습니다. 이전에는 기본값으로만 정적 역할을 선택할 수 있었습니다. 이렇게 하면 자동으로 프로비저닝된 사용자에게 최소 권한 원칙과 가장 잘 맞는 역할을 할당할 수 있습니다.

### 그룹 수준에서 하위 그룹/프로젝트별로 스트리밍 감사 이벤트 필터링 {#filter-streaming-audit-events-by-sub-groupproject-at-group-level}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11384)

{{< /details >}}

스트리밍 감사 이벤트는 기존 이벤트 유형 필터링 지원 외에도 그룹 수준에서 하위 그룹 또는 프로젝트별로 필터링을 지원하도록 확장되었습니다.

이 추가 필터를 통해 스트림의 이벤트를 분리하여 다양한 목적지로 전송하거나 관련 없는 하위 그룹/프로젝트를 제외하여 팀이 모니터링할 수 있는 가장 실행 가능한 이벤트를 확보할 수 있습니다.

### 컴플라이언스 프레임워크 관리 개선 사항 {#compliance-framework-management-improvements}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_frameworks/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11240)

{{< /details >}}

저희의 컴플라이언스 센터는 컴플라이언스 태세를 이해하고 컴플라이언스 프레임워크를 관리하기 위한 중앙 대상이 되고 있습니다. 저희는 프레임워크 관리를 컴플라이언스 센터의 새 탭으로 이동하고 있으며 더 많은 흥미로운 기능을 추가하고 있습니다:

- **프레임워크** 탭의 목록 뷰에서 프레임워크를 봅니다.
- 검색 및 필터를 통해 특정 프레임워크를 찾습니다.
- 새로운 컴플라이언스 프레임워크 사이드바를 사용하여 각 프레임워크에 대한 자세한 정보를 살펴봅니다.
- 프레임워크를 편집하여 이름, 설명, 연결된 프로젝트 관리 등을 포함한 모든 설정을 봅니다.
- CSV로 내보내기를 사용하여 프레임워크의 빠른 보고서를 만듭니다.

### AWS S3에 대한 인스턴스 수준의 감사 이벤트 스트리밍 {#instance-level-audit-event-streaming-to-aws-s3}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

이전에는 AWS S3에 대한 최상위 그룹 스트리밍 감사 이벤트만 구성할 수 있었습니다.

GitLab 16.8을 사용하면 AWS S3에 대한 지원을 인스턴스 수준의 스트리밍 목적지로 확장했습니다.

### 브랜치 삭제 또는 보호 해제를 방지하기 위한 정책 적용 {#enforce-policy-to-prevent-branches-being-deleted-or-unprotected}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9705)

{{< /details >}}

스캔 결과 정책에 추가된 여러 새로운 설정 중 하나로 [보안 정책 컴플라이언스 적용](https://gitlab.com/groups/gitlab-org/-/epics/9704)에 도움이 되므로 브랜치 수정 제어는 프로젝트 수준 설정을 변경하여 정책을 우회하는 능력을 제한합니다.

각 기존 또는 새로운 스캔 결과 정책에 대해 `Prevent branch modification`을 활성화하여 정책 내에서 정의된 브랜치에 효과를 발휘하여 사용자가 해당 브랜치를 삭제하거나 보호 해제하는 것을 방지할 수 있습니다.

### 사용자 지정 역할을 위한 SAML Group Sync {#saml-group-sync-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/saml_sso/group_sync.md#configure-saml-group-links) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)

{{< /details >}}

이제 SAML Group Sync를 사용하여 사용자 지정 역할을 사용자 그룹에 매핑할 수 있습니다. 이전에는 SAML 그룹을 GitLab의 정적 역할에만 매핑할 수 있었습니다. 이렇게 하면 SAML Group Links를 사용하여 그룹 멤버십 및 멤버 역할을 관리하는 고객에게 더 많은 유연성을 제공합니다.

### 머지 리퀘스트 승인을 위한 SAML SSO 인증 {#saml-sso-authentication-for-merge-request-approval}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11084)

{{< /details >}}

GitLab에서 SAML SSO 및 SCIM을 사용하는 경우 이제 SSO를 사용하여 머지 리퀘스트를 승인하기 위해 비밀번호 기반 인증을 통한 머지 리퀘스트 인증 요구 사항을 충족할 수 있습니다.

이 방법은 보안 및 컴플라이언스를 위해 인증된 사용자만 머지 리퀘스트를 승인할 수 있도록 보장하며, 별도의 비밀번호 기반 솔루션을 사용할 필요가 없습니다.

### 분석 대시보드를 위한 그룹 수준의 방문 페이지 소개 {#introduce-group-level-landing-page-for-analytics-dashboards}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/433420)

{{< /details >}}

저희는 그룹 수준의 분석 대시보드를 위한 새로운 방문 페이지를 소개하고 있습니다. 이 개선 사항은 더 일관되고 사용자 친화적인 탐색 환경을 보장합니다. 이 첫 번째 단계에서 이 페이지에는 [Value Streams Dashboard](https://www.youtube.com/watch?v=8pLEucNUlWI)가 포함되어 있지만, 향후 기능의 기초를 마련하여 대시보드를 개인화할 수 있도록 합니다. 이러한 개선 사항은 경험을 효율화하고 데이터 관리 및 해석에서 더 많은 유연성을 제공하는 것을 목표로 합니다.

### 작업 또는 OKR의 모든 상위 항목 보기 {#view-all-ancestor-items-of-a-task-or-okr}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/tasks.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11197)

{{< /details >}}

이 릴리스에서는 즉시 상위 항목만 보는 것이 아니라 작업 항목의 전체 계층 구조 계보를 볼 수 있습니다.

작업 항목은 다음을 포함합니다:

- 모든 티어의 작업입니다.
- [Objectives and Key Results](../../user/okrs.md) (Ultimate 티어 및 기능 플래그 뒤에 있음)입니다.

### Runner Fleet Dashboard: 인스턴스 러너가 사용한 컴퓨팅 분의 CSV 내보내기 {#runner-fleet-dashboard-csv-export-of-compute-minutes-used-by-instance-runners}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/runners/runner_fleet_dashboard.md#export-compute-minutes-used-by-instance-runners) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425853)

{{< /details >}}

인스턴스 러너의 프로젝트에서 사용하는 CI/CD 컴퓨팅 분에 대한 보고서를 실행해야 할 수 있습니다. 그러나 GitLab에서 CI/CD 컴퓨팅 분 사용 보고서를 생성할 수 있는 간단한 메커니즘이 없었습니다. 이 기능을 통해 공유 러너의 각 프로젝트에서 사용하는 CI/CD 컴퓨팅 분의 보고서를 CSV 파일로 내보낼 수 있습니다.

### GitLab Runner 16.8 {#gitlab-runner-168}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

저희는 또한 오늘 GitLab Runner 16.8을 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [생성된 Kubernetes Pod 규격 덮어쓰기 - Beta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29659)

#### 버그 수정 {#bug-fixes}

- [GitLab Runner 인증 토큰이 러너 로그 파일에 노출됨](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37224)
- [여러 자동 크기 조정 러너를 등록하면 부분적인 config.toml 파일이 발생함](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37197)
- [restore_cache 헬퍼 작업 중단이 캐시를 손상시킴](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36988)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-8-stable/CHANGELOG.md)에 있습니다.

### 머지 리퀘스트 설명을 위한 미리 정의된 변수 {#predefined-variables-for-merge-request-description}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/432846)

{{< /details >}}

CI/CD 파이프라인에서 머지 리퀘스트를 작업하기 위해 자동화를 사용하는 경우 API 호출 없이 머지 리퀘스트 설명을 가져올 수 있는 더 쉬운 방법을 원했을 수 있습니다. GitLab 16.7에서 저희는 `CI_MERGE_REQUEST_DESCRIPTION` 미리 정의된 변수를 소개했으며, 설명을 모든 작업에서 쉽게 액세스할 수 있게 했습니다. GitLab 16.8에서 저희는 동작을 조정하여 `CI_MERGE_REQUEST_DESCRIPTION`를 2700자로 잘라내도록 했습니다. 매우 큰 설명은 러너 오류를 발생시킬 수 있기 때문입니다. 새로 도입된 `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` 미리 정의된 변수를 사용하여 설명이 잘렸는지 확인할 수 있으며, 설명이 잘렸을 때 `true`로 설정됩니다.

### Windows의 SaaS 러너를 위한 Windows 2022 지원 {#windows-2022-support-for-saas-runners-on-windows}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/windows.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438554)

{{< /details >}}

이제 팀은 Windows Server 2022에서 애플리케이션을 빌드, 테스트 및 배포할 수 있습니다.

Windows의 SaaS 러너를 사용하면 GitLab CI/CD와 통합된 안전한 온디맨드 GitLab Runner 빌드 환경에서 Windows가 필요한 애플리케이션을 빌드하고 배포하는 개발 팀의 속도를 높일 수 있습니다.

.GitLab-ci.yml 파일의 태그로 `saas-windows-medium-amd64`을 사용하여 오늘 시도해 보세요.

### 내부 구성 요소를 위한 CI/CD Components Catalog 섹션 {#cicd-components-catalog-section-for-your-internal-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/components/_index.md#cicd-catalog) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437768)

{{< /details >}}

CI/CD 카탈로그의 항목 수가 계속 증가함에 따라 팀에서 릴리스하고 사용할 수 있는 CI/CD 구성 요소를 찾기가 점점 어려워지고 있습니다. 이 릴리스에서 저희는 전용 **귀하의 그룹** 탭을 소개하여 조직과 관련된 구성 요소를 손쉽게 필터링하고 식별할 수 있도록 합니다. 이 단순화된 검색 프로세스는 릴리스된 CI/CD 구성 요소를 더 빠르게 찾고 사용할 수 있으므로 효율성을 향상시킵니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.8)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
