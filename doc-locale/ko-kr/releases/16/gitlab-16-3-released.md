---
stage: Release Notes
group: Monthly Release
date: 2023-08-22
title: "GitLab 16.3 릴리스 정보"
description: "GitLab 16.3이 Value Streams Dashboard의 새로운 속도 메트릭과 함께 출시되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 8월 22일에 GitLab 16.3이 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Thomas Spear {#this-months-notable-contributor-thomas-spear}

Thomas는 지난 달 [15개의 머지 리퀘스트](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/merge_requests?scope=all&state=merged&author_username=tspearconquest)를 [GitLab agent for Kubernetes Helm chart](https://gitlab.com/gitlab-org/charts/gitlab-agent)에 기여했습니다!

Thomas는 보안과 관찰성 측면에서 차트를 더욱 성숙하게 만들었고, agentk의 이슈 해결을 간단하게 했으며, 주요 변경 사항을 확인하기 위해 CI/CD 파이프라인을 개선했습니다.

보안 엔지니어로서 Thomas는 팀과 협력하여 GitLab agent의 보다 안전한 기본 배포를 제공하는 것을 즐깁니다. Thomas는 모든 적시의 검토와 피드백에 감사를 표현했으며, 팀 멤버들은 이를 기꺼이 제공했습니다.

Thomas님 감사합니다. 귀하의 기여는 정말 많이 감사합니다! 🙌

[Shane Maglangit](https://gitlab.com/ShaneMaglangit)와 [Batuhan Apaydın](https://gitlab.com/batuhan.apaydin)의 훌륭한 기여에도 감사의 말씀을 드립니다.

## 주요 기능 {#primary-features}

### Value Streams Dashboard의 새로운 속도 메트릭 {#new-velocity-metrics-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/383665)

{{< /details >}}

[Value Streams Dashboard](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/)가 새로운 메트릭으로 개선되었습니다: **Merge request (MR) throughput**과 **Total closed issues**(속도). GitLab에서 **MR throughput**은 월별로 머지된 머지 리퀘스트의 수이며, **Total closed issues**는 특정 시점에 종료된 플로우 항목의 수입니다.

이러한 메트릭으로 생산성이 낮거나 높은 달과 [머지 리퀘스트 및 코드 검토 프로세스](../../user/analytics/merge_request_analytics.md)의 효율성을 파악할 수 있습니다. [Value Stream 제공](../../user/group/value_stream_analytics/_index.md)이 가속화되고 있는지 여부를 판단할 수 있습니다.

시간이 지남에 따라 메트릭은 MR 및 이슈에서 과거 데이터를 누적합니다. 팀은 데이터를 사용하여 제공 속도가 가속화되고 있는지 또는 개선이 필요한지 판단하고, 제공할 수 있는 작업량에 대한 보다 정확한 추정치나 예측을 제공할 수 있습니다.

Value Streams Dashboard를 개선하는 데 도움을 주기 위해 이 [설문조사](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4)에서 경험에 대한 피드백을 공유해 주세요.

### SSH를 사용하여 Workspaces에 연결 {#connect-to-workspaces-with-ssh}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/configuration.md#connect-to-a-workspace-with-ssh)

{{< /details >}}

Workspaces를 사용하면 재현 가능한, 임시의 클라우드 기반 런타임 환경을 만들 수 있습니다. 이 기능이 GitLab 16.0에서 도입된 이후, 워크스페이스를 사용하는 유일한 방법은 환경에서 직접 실행되는 브라우저 기반 Web IDE였습니다. 그러나 Web IDE가 항상 적합한 도구가 되는 것은 아닙니다.

GitLab 16.3을 통해 SSH를 사용하여 데스크톱에서 워크스페이스에 안전하게 연결하고 로컬 도구 및 확장을 사용할 수 있습니다. 첫 번째 반복은 VS Code에서 직접 SSH 연결을 지원하거나 Vim 또는 Emacs와 같은 편집기를 사용한 명령줄에서 지원합니다. JetBrains IDE 및 JupyterLab과 같은 다른 편집기에 대한 지원은 향후 반복 계획입니다.

### Flux 동기화 상태 시각화 {#flux-sync-status-visualization}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md#flux-sync-status) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)

{{< /details >}}

이전 릴리스에서는 `kubectl` 또는 다른 타사 도구를 사용하여 Flux 배포 상태를 확인했을 것입니다. GitLab 16.3부터는 환경 UI를 사용하여 배포를 확인할 수 있습니다.

배포는 Flux `Kustomization` 및 `HelmRelease` 리소스에 의존하여 특정 환경의 상태를 수집하며, 환경에 대해 네임스페이스를 구성해야 합니다. 기본적으로 GitLab은 `Kustomization` 및 `HelmRelease` 리소스에서 프로젝트 슬러그의 이름을 검색합니다. 환경 설정에서 GitLab이 찾는 이름을 사용자 지정할 수 있습니다.

### 스캔 결과 정책을 위한 추가 필터링 {#additional-filtering-for-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/6826)

{{< /details >}}

보안 또는 규정 준수 스캔의 어떤 결과가 실행 가능한지 결정하는 것은 보안 및 규정 준수 팀에게 중요한 과제입니다. 스캔 결과 정책을 위한 세밀한 필터는 잡음을 제거하여 가장 주의가 필요한 취약성 또는 위반을 파악하는 데 도움이 됩니다. 이러한 새로운 필터 및 필터 업데이트는 워크플로우를 간소화합니다:

- 상태:  상태: 상태 규칙 변경은 "새로운" 대 "이전에 존재하던" 취약성의 보다 직관적인 적용을 소개합니다. 새로운 상태 필드 `new_needs_triage`을 사용하면 분류가 필요한 새로운 취약성만 필터링할 수 있습니다.
- 나이: 감지된 날짜를 기반으로 취약성이 SLA(일, 월 또는 연도) 외부에 있을 때 승인을 적용하는 정책을 만듭니다.
- 사용 가능한 수정: 수정 사항이 있는 종속성을 해결하기 위해 정책의 초점을 좁힙니다.
- 거짓 긍정: 취약성 추출 도구에 의해 감지된 거짓 긍정과 SAST 결과의 경우 Rezilion을 통한 컨테이너 스캔 및 종속성 스캔 결과를 필터링합니다.

### VS Code의 보안 결과 {#security-findings-in-vs-code}

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../editor_extensions/visual_studio_code/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10407)

{{< /details >}}

이제 Visual Studio Code(VS Code)에서 머지 리퀘스트와 마찬가지로 보안 결과를 직접 볼 수 있습니다.

이미 CI/CD 파이프라인의 상태를 모니터링하고, CI/CD 작업 로그를 보고, GitLab Workflow 패널에서 개발 워크플로우를 진행할 수 있었습니다. 이제 브랜치에 대한 머지 리퀘스트를 생성한 후에도 기본 브랜치에서 이전에 발견되지 않은 새로운 보안 결과 목록을 볼 수 있습니다.

이 새로운 기능은 VS Code용 [GitLab Workflow](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)의 일부입니다. 보안 스캔 결과는 API에서 가져오므로 이 기능은 GitLab.com을 사용하거나 GitLab 16.1 이상을 실행하는 자체 관리 인스턴스를 사용하는 개발자가 사용할 수 있습니다.

### `needs` 키워드를 병렬 작업과 함께 사용 {#use-the-needs-keyword-with-parallel-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#needsparallelmatrix) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)

{{< /details >}}

`needs` 키워드는 작업 간 종속성 관계를 정의하는 데 사용됩니다. 이 키워드를 사용하여 스테이지 순서를 따르는 대신 특정 이전 작업에 종속되도록 작업을 구성할 수 있습니다. 종속 작업이 완료되면 작업이 즉시 시작되어 파이프라인 속도가 빨라집니다.

이전에는 `needs` 키워드를 사용하여 [병렬 행렬](../../ci/yaml/_index.md#parallelmatrix) 작업을 종속으로 설정할 수 없었지만, 이 릴리스에서는 `needs`을 병렬 행렬 작업과도 함께 사용할 수 있도록 했습니다. 이제 병렬 행렬 작업에 대한 유연한 종속성 관계를 정의할 수 있으므로 파이프라인을 더욱 빠르게 할 수 있습니다! 작업을 더 일찍 시작할 수 있을수록 파이프라인을 더 빨리 완료할 수 있습니다!

### Linux에서 더 강력한 GitLab SaaS 러너 {#more-powerful-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/388165)

{{< /details >}}

최근 모든 Linux SaaS 러너를 업그레이드한 후, 이제 `xlarge` 및 `2xlarge`[Linux의 SaaS 러너](../../ci/runners/hosted_runners/linux.md)를 소개하고 있습니다. 각각 16개 및 32개의 vCPU를 갖추고 GitLab CI/CD와 완벽하게 통합된 이 러너들은 이전보다 훨씬 빠르게 애플리케이션을 빌드하고 테스트할 수 있습니다.

업계에서 가장 빠른 CI/CD 빌드 속도를 제공하기로 결심했으며, 팀들이 더 짧은 피드백 사이클을 달성하고 궁극적으로 소프트웨어를 더 빠르게 제공하는 것을 기대합니다.

### Azure Key Vault 시크릿 관리자 지원 {#azure-key-vault-secrets-manager-support}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/secrets/azure_key_vault.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)

{{< /details >}}

Azure Key Vault에 저장된 시크릿을 이제 쉽게 검색하고 CI/CD 작업에서 사용할 수 있습니다. 새로운 통합으로 GitLab CI/CD를 통해 Azure Key Vault와 상호 작용하는 프로세스를 단순화하여 빌드 및 배포 프로세스를 간소화하는 데 도움이 됩니다!

## 규모 및 배포 {#scale-and-deployments}

### 프로젝트 검색 결과에서 보관된 프로젝트 포함 또는 제외 {#include-or-exclude-archived-projects-from-project-search-results}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/_index.md#include-archived-projects-in-search-results) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/413237)

{{< /details >}}

이제 검색 결과에서 보관된 프로젝트를 포함하거나 제외하도록 선택할 수 있습니다. 기본적으로 보관된 프로젝트는 제외됩니다. 이 기능은 GitLab의 프로젝트 검색에서 사용할 수 있습니다. 다른 [전역 검색 범위](../../user/search/_index.md)에 대한 지원은 향후 릴리스에서 제안됩니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.3에는 [Mattermost 8.0](https://mattermost.com/blog/mattermost-v8-0-is-now-available/)이 포함되어 있습니다. 이 버전에는 [보안 업데이트](https://mattermost.com/security-updates/)가 포함되어 있으며 이전 버전에서 업그레이드하는 것이 권장됩니다.
- 당사의 Amazon Linux 빌드는 이제 [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)입니다. Amazon Linux 2022는 공식적으로 일반 공급되지 않았으며 Amazon Linux 2023으로 대체되었으므로 업데이트된 릴리스로 당사 서비스를 조정했습니다.

### 애플리케이션 설정 변경에 대한 감사 이벤트 기록 {#audit-event-recorded-for-applications-settings-change}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/compliance/audit_event_reports.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/282428)

{{< /details >}}

인스턴스, 프로젝트 및 그룹 수준의 애플리케이션 설정 변경 사항이 이제 변경한 사용자와 함께 감사 로그에 기록됩니다. 이는 자체 관리 및 SaaS 모두에 대한 애플리케이션 설정 감사를 개선합니다.

### BitBucket Server에서 가져올 때 풀 리퀘스트 검토자 유지 {#preserve-pull-request-reviewers-when-importing-from-bitbucket-server}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/bitbucket.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416611)

{{< /details >}}

지금까지 BitBucket Server 가져오기 도구는 풀 리퀘스트(PR) 검토자를 가져오지 않았으며 대신 참여자로 분류했습니다. PR 검토자에 대한 정보는 감사 및 규정 준수 관점에서 중요합니다.

GitLab 16.3에서 BitBucket에서 PR 검토자를 올바르게 가져오기 위한 지원을 추가했습니다. GitLab에서는 머지 리퀘스트 검토자가 됩니다.

### 애플리케이션 설정에서 사용 가능한 구성 가능한 가져오기 제한 {#configurable-import-limits-available-in-application-settings}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/group/import/_index.md#limits)

{{< /details >}}

직접 전송 및 내보내기 파일 가져오기를 통한 마이그레이션 모두에 대해 하드코딩된 제한이 있습니다.

이 릴리스에서는 애플리케이션 설정에서 일부 제한을 구성 가능하게 만들어 자체 관리 GitLab 관리자가 필요에 따라 조정할 수 있도록 했습니다:

- [직접 전송의 소스 인스턴스에서 다운로드할 수 있는 최대 관계 크기](../../administration/settings/account_and_limit_settings.md). 이전에는 5GB로 하드코딩되었습니다. GitLab.com에서는 이 제한을 5GB로 설정했습니다.
- [원격 Object Storages(예: AWS S3)에서 다운로드할 수 있는 원격 가져오기 파일의 최대 크기](../../administration/settings/account_and_limit_settings.md). 이전에는 10GB로 하드코딩되었습니다. GitLab.com에서는 이 제한을 10GB로 설정했습니다.

또한 [가져온 보관 파일의 최대 압축 해제 파일 크기](../../administration/settings/account_and_limit_settings.md) 애플리케이션 설정을 새로 추가했으며, 이는 `validate_import_decompressed_archive_size` 기능 플래그를 대체합니다. 이 제한은 10GB로 하드코딩되었습니다. GitLab.com에서는 이 제한을 25GB로 설정했습니다.

이러한 새로운 애플리케이션 설정으로 자체 관리 GitLab 및 GitLab.com 관리자가 필요에 따라 이러한 제한을 조정할 수 있습니다.

### 새 네비게이션에서 사용 가능한 색상 테마 {#new-navigation-has-color-themes-available}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/profile/preferences.md)

{{< /details >}}

새 네비게이션을 활성화하면 5가지 색상 테마 중 하나를 선택할 수 있으며, 각각 밝은 색이나 어두운 색을 선택할 수 있습니다. 다양한 환경을 식별하거나 좋아하는 색상을 선택하려면 테마를 사용합니다.

### 직접 전송 마이그레이션을 위한 엔티티 내보내기 타임아웃 없음 {#no-entity-export-timeout-for-migrations-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/_index.md#limits) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/392725)

{{< /details >}}

지금까지 직접 전송으로 그룹 및 프로젝트를 마이그레이션할 때 90분의 내보내기 타임아웃이 있었습니다. 이 제한은 90분 이내에 마이그레이션할 수 있는 프로젝트만 허용되었기 때문에 대규모 프로젝트의 마이그레이션을 효과적으로 제외했습니다.

전체 마이그레이션 타임아웃의 상한선은 4시간이므로 90분의 내보내기 타임아웃은 필요하지 않았습니다. 이 마일스톤에서 제한이 제거되어 대규모 프로젝트의 마이그레이션이 가능합니다.

### Azure AD 초과 청구 지원 {#support-for-azure-ad-overage-claim}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/saml_sso/group_sync.md#microsoft-azure-active-directory-integration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/414875)

{{< /details >}}

GitLab SAML Group Sync는 이제 Azure AD(현재 Entra ID로 알려짐) 초과 청구를 지원하여 사용자가 150개 이상의 그룹을 연결할 수 있습니다. 이전 최대값은 150개 그룹이었습니다. 자세한 내용은 [Microsoft 그룹 초과 청구](https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles#group-overages)를 참조하세요.

### Geo가 그룹 wiki 검증 {#geo-verifies-group-wikis}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/geo/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)

{{< /details >}}

Geo는 이제 [그룹 wiki](../../user/project/wiki/group.md)의 데이터 손상을 감지하고 수정할 수 있으며, 저장 중 및 전송 중 손상을 감지합니다. Geo를 재해 복구 전략의 일부로 사용하는 경우 장애 조치 시 데이터 손실로부터 보호하는 데 도움이 됩니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### CODEOWNERS 파일 구문 및 형식 검증 {#codeowners-file-syntax-and-format-validation}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/codeowners/reference.md)

{{< /details >}}

이제 UI에서 `CODEOWNERS` 파일에 구문이나 형식 오류가 있는지 확인할 수 있습니다. 코드 소유자를 지정할 수 있으면 여러 파일 위치, 섹션 및 사용자가 구성할 수 있는 규칙을 허용하여 뛰어난 유연성을 제공합니다. 이 새로운 구문 검증을 통해 `CODEOWNERS` 파일의 오류가 GitLab UI에 표시되어 이슈를 쉽게 발견하고 수정할 수 있습니다. 다음 오류가 표시됩니다:

- 공백이 있는 항목.
- 파싱할 수 없는 섹션.
- 형식이 잘못된 소유자.
- 접근할 수 없는 소유자.
- 소유자 없음.
- 1개 미만의 필수 승인.

이전에는 `CODEOWNERS` 파일이 파일에 입력된 정보를 검증하지 않았습니다. 이로 인해 다음을 만들 수 있습니다:

- 존재하지 않는 파일/경로에 대한 규칙.
- 다른 기존 규칙과 충돌하는 규칙.
- 구문이 잘못되어 적용되지 않는 규칙.

### Kubernetes 1.27 지원 {#kubernetes-127-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/420859)

{{< /details >}}

이 릴리스는 2023년 4월에 출시된 Kubernetes 버전 1.27에 대한 완벽한 지원을 추가합니다. Kubernetes를 사용하는 경우 이제 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

[당사의 Kubernetes 지원 정책](../../user/clusters/agent/_index.md) 및 기타 지원되는 Kubernetes 버전에 대해 자세히 알아볼 수 있습니다.

### 기능 플래그 이름을 자르는 대신 줄바꿈 {#wrap-feature-flag-names-instead-of-truncating}

<!-- categories: Feature Flags -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../operations/feature_flags.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/418147)

{{< /details >}}

이전 버전의 GitLab에서 기능 플래그를 사용했다면 긴 기능 플래그 이름이 잘렸을 수도 있습니다. 이로 인해 유사한 기능 플래그 이름을 빠르게 구분하기 어려웠습니다.

GitLab 16.3에서는 전체 기능 플래그 이름이 표시됩니다. 필요한 경우 긴 이름이 여러 줄에 걸쳐 래핑됩니다.

### 감사 이벤트 스트림의 이름 {#names-for-audit-event-streams}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

이전에는 감사 이벤트 스트리밍 대상이 대상 URL에 의해 할당되었습니다. 하나의 그룹 또는 인스턴스에 대해 여러 스트림을 설정할 때 UI에서 대상을 확장하여 적용된 필터와 사용자 지정 헤더를 확인해야 했기 때문에 혼동이 발생할 수 있었습니다.

GitLab 16.3을 통해 이제 감사 이벤트 스트리밍 대상의 이름을 지정하여 여러 스트리밍 대상을 정의할 때 구분하고 식별할 수 있습니다.

### 이 취약성 설명 {#explain-this-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/application_security/vulnerabilities/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10368)

{{< /details >}}

GitLab은 관련 정보를 포함하는 취약성을 표시하지만, 어디서 시작해야 할지 명확하지 않을 수도 있습니다. 취약성 기록 내에서 표시되는 정보를 조사하고 종합하는 데 시간이 걸립니다. 또한 특정 취약성을 수정하는 방법을 파악하기 어려울 수 있습니다. 이 베타 릴리스에서는 단추를 클릭하여 AI로 생성된 취약성 완화 방법에 대한 설명 및 권장 사항을 얻을 수 있습니다.

### 규정 준수 보고서를 규정 준수 센터로 이름 변경 {#compliance-reports-renamed-to-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

규정 준수 관련 기능의 성장을 보고를 넘어 관리로 촉진하기 위해 GitLab의 규정 준수 보고서 섹션의 이름을 변경하여 해당 영역의 확장된 범위를 반영했습니다.

GitLab 16.3부터 규정 준수 보고서를 규정 준수 센터로 알려져 있습니다.

### 스캔 결과 정책의 정확성 개선 {#improve-accuracy-of-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)

{{< /details >}}

스캔 결과 정책은 특정 규칙이 위반된 경우 머지 리퀘스트를 평가하고 차단하는 데 사용하는 보안 정책의 유형입니다. 승인자는 변경 사항을 검토 및 승인하거나 개발 팀과 함께 이슈(예: 중요한 보안 취약성 해결)를 해결할 수 있습니다.

이전에는 최신 소스 및 대상 브랜치의 취약성을 비교하여 정책 규칙의 새로운 위반을 감지했습니다. 하지만 이는 다양한 파이프라인 소스의 결과로 실행되는 스캔에서 감지된 취약성을 캡처하지 못할 수 있습니다. 정확성을 높이기 위해 이제 각 파이프라인 소스(상위-하위 파이프라인 제외)에 대해 최근에 완료된 파이프라인을 비교합니다. 이는 보다 포괄적인 평가를 보장하고 예상치 못한 경우 승인이 필요한 경우를 줄입니다.

### 인스턴스 수준의 스트리밍 감사 이벤트 필터 {#instance-level-streaming-audit-event-filters}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

GitLab 16.2에서는 인스턴스 수준의 감사 이벤트 스트리밍을 도입했습니다. 하지만 이러한 스트림에 적용할 수 있는 필터가 없었습니다.

GitLab 16.3에서는 이제 인스턴스 수준의 감사 이벤트 스트림에 감사 이벤트 유형별로 필터를 적용할 수 있습니다. UI에서 이러한 필터를 추가하면 각 스트리밍 위치로 보낼 감사 이벤트의 부분 집합을 캡처하여 사용자와 관련된 이벤트만 초점을 맞출 수 있습니다.

### 보안 봇으로 스캔 실행 정책 파이프라인 트리거 {#security-bot-to-trigger-scan-execution-policies-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/scan_execution_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10756)

{{< /details >}}

보안 봇 사용자는 배경 작업 관리를 지원하고 새로 생성되거나 업데이트된 보안 정책 프로젝트 링크에 대한 보안 정책을 적용하기 위해 생성됩니다. 이는 보안 및 규정 준수 팀 멤버가 정책을 구성하고 적용하는 프로세스를 간소화하며, 특히 보안 정책 프로젝트 유지 보수자가 개발 프로젝트에서 `Developer` 액세스를 유지할 필요를 제거합니다. 보안 정책 봇 사용자는 또한 이 봇 사용자가 파이프라인 작성자이므로 보안 정책을 대신하여 파이프라인이 실행될 때 적용된 프로젝트 내의 사용자에게 훨씬 더 명확하게 합니다.

보안 정책 프로젝트가 그룹 또는 하위 그룹에 연결되면 그룹 또는 하위 그룹의 각 프로젝트에 보안 정책 봇이 생성됩니다. 그룹, 하위 그룹 또는 개별 프로젝트에 링크가 만들어지면 지정된 프로젝트 또는 그룹 또는 하위 그룹의 모든 프로젝트에 대해 보안 봇 사용자가 생성됩니다. 이미 보안 정책 프로젝트에 링크된 모든 그룹, 하위 그룹 또는 프로젝트는 현재 영향을 받지 않지만 사용자는 이 기능을 활용하기 위해 기존 링크를 다시 설정할 수 있습니다. GitLab 16.4에서는 보안 정책 프로젝트 링크가 있는 GitLab.com에서 호스팅하는 모든 프로젝트에서 [보안 봇을 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/414376)할 계획입니다.

### SAST 분석기 업데이트 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/analyzers.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST는 [많은 보안 분석기](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)를 포함하며, GitLab Static Analysis 팀은 적극적으로 유지보수하고 업데이트하며 지원합니다. 16.3 릴리스 마일스톤 기간 동안 다음 업데이트를 게시했습니다:

- Kics 기반 분석기가 Kics 엔진의 버전 1.7.5를 사용하도록 업데이트되었습니다. 이 업데이트에는 다양한 버그 수정과 JSON 및 YAML의 자체 참조에 대한 오류 처리 개선이 포함됩니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v414)를 참조하세요.
- Semgrep 기반 분석기가 통과 사용자 지정 구성 중에 모호한 참조 지정에 대한 지원을 추가하도록 업데이트되었습니다. 또한 SARIF 파서를 업데이트하여 제목보다 이름을 사용하고 더 이상 SARIF `toolExecutionNotifications`의 오류 수준에서 스캔에 실패하지 않도록 했습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v446)를 참조하세요.

[GitLab 관리 SAST 템플릿을 포함](../../user/application_security/sast/_index.md)하고([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/sast/_index.md)할 수 있습니다.

이전 변경사항은 [지난 달 업데이트](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#sast-analyzer-updates)를 참조하세요.

### Java v21에 대한 종속성 및 라이선스 스캔 지원 {#dependency-and-license-scanning-support-for-java-v21}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/387307)

{{< /details >}}

GitLab 종속성 및 라이선스 스캔은 이제 Java v21 Maven 잠금 파일 분석을 지원합니다.

### 실행기 태그는 온디맨드 DAST 스캔의 UI 기반 구성을 활성화합니다 {#runner-tags-enable-ui-based-configuration-of-on-demand-dast-scans}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/on-demand_scan.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/345430)

{{< /details >}}

이제 태그를 사용하여 온디맨드 DAST 스캔에 사용할 실행기를 지정할 수 있습니다. 16.3 이전에는 CI 구성 파일을 통해 프라이빗 실행기를 사용하여 DAST 스캔을 구성할 수 있었습니다. 이 UI 기반 구성은 DAST 스캔 관리를 위한 효율적인 UI 구성을 활성화합니다.

### 개선된 SAST 취약성 추적 {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

GitLab SAST [고급 취약성 추적](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)은 코드가 이동함에 따라 결과를 추적하여 심사를 더 효율적으로 만듭니다. GitLab 16.3에서 두 가지 개선을 출시했습니다:

1. 확장된 언어 지원: [기존 범위](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)외에도 다음을 위해 Advanced Vulnerability Tracking을 활성화했습니다:
  - Flawfinder 기반 분석기에서 C 및 C++.
  - MobSF 기반 분석기의 Java.
  - NodeJS-Scan 기반 분석기의 JavaScript.
1. 더 나은 추적: JavaScript의 익명 함수를 처리하기 위해 추적 알고리즘을 개선했습니다.

이는 이전 확장 및 개선 [GitLab 16.2에서 출시](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#improved-sast-vulnerability-tracking)를 기반으로 합니다. 더 많은 언어로의 확장, 더 많은 언어 구성의 더 나은 처리, 그리고 Python 및 Ruby에 대한 개선된 추적을 포함하여 [에픽 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)에서 추가 개선 사항을 추적하고 있습니다.

이 변경 사항은 GitLab SAST의 [업데이트된 버전](https://docs.gitlab.com/#sast-analyzer-updates) [분석기](../../user/application_security/sast/analyzers.md)에 포함됩니다. 프로젝트가 업데이트된 분석기로 스캔된 후 프로젝트의 취약성 결과는 새로운 추적 서명으로 업데이트됩니다. [SAST 분석기를 특정 버전으로 고정](../../user/application_security/sast/_index.md)하지 않은 한 이 업데이트를 받기 위해 조치를 취할 필요가 없습니다.

### 유출된 Postman API 키에 대한 자동 대응 {#automatic-response-to-leaked-postman-api-keys}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Gold
- 링크: [문서](../../user/application_security/secret_detection/automatic_response.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/403825)

{{< /details >}}

Postman을 사용하는 고객을 더 잘 보호하기 위해 Postman과 Secret Detection을 통합했습니다.

Secret Detection은 [Postman API 키](https://learning.postman.com/docs/developer/postman-api/authentication/)를 검색합니다. GitLab.com의 공개 프로젝트에서 키가 노출되면 GitLab은 유출된 키를 Postman으로 보냅니다. Postman이 키를 확인한 후 [Postman API 키의 소유자에게 알림](https://learning.postman.com/docs/administration/token-scanner/#protecting-postman-api-keys-in-gitlab).

이 통합은 GitLab.com에서 [Secret Detection을 활성화](../../user/application_security/secret_detection/_index.md)한 프로젝트에 대해 기본적으로 켜져 있습니다. Secret Detection 스캔은 모든 GitLab 티어에서 사용 가능하지만, 유출된 시크릿에 대한 자동 대응은 현재 Ultimate 프로젝트에서만 사용 가능합니다.

자세한 내용은 [이 통합에 대한 Postman 블로그 게시물](https://blog.postman.com/protecting-your-postman-api-keys-in-gitlab/)을 참조하세요.

### 사전 정의된 CI/CD 변수로 파이프라인 이름 노출 {#expose-pipeline-name-as-a-predefined-cicd-variable}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/variables/predefined_variables.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/420002)

{{< /details >}}

[`workflow:name`](../../ci/yaml/_index.md#workflowname) 키워드로 정의된 파이프라인 이름은 이제 사전 정의된 변수 `$CI_PIPELINE_NAME`을 통해 액세스할 수 있습니다.

### GitLab Runner 16.3 {#gitlab-runner-163}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

GitLab Runner 16.3도 오늘 출시됩니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [기본값으로 프로젝트 복제 디렉토리를 안전으로 구성](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29022)

#### 버그 수정 {#bug-fixes}

- [Runner v16.2.0은 Debian/RHEL 저장소에서 사용할 수 없습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36048)
- [GitLab-runner는 shell 실행기를 사용할 때 때때로 하위 모듈을 가져오지 못합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26993)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-3-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.3)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
