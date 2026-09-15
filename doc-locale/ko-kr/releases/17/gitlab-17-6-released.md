---
stage: Release Notes
group: Monthly Release
date: 2024-11-21
title: "GitLab 17.6 릴리스 정보"
description: "GitLab 17.6이 GitLab Duo Chat용 자체 호스팅 모델 사용 기능과 함께 릴리스되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 11월 21일에 GitLab 17.6이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Joel Gerber {#this-months-notable-contributor-joel-gerber}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Joel은 CI 컴포넌트에 대한 귀중한 기여자로 인정받았으며, 머지 리퀘스트에 대한 통찰력 있는 피드백을 제공했고 복잡한 토론에서 사려 깊은 의견을 남겼습니다. 그의 기여에는 [CI/CD 카탈로그를 위한 UI 개선](https://gitlab.com/gitlab-org/gitlab/-/issues/464703), GitLab Terraform Provider에 대한 많이 요청된 문서 개선, [작업 로그 타임스탬프](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164595), 그리고 [UI/UX 팀에 피드백 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/482524#note_2089551197)이 포함됩니다.

Joel은 [HackerOne](https://www.hackerone.com/)의 Staff Software Engineer이며 GitLab의 Contributor Success 담당 Staff FullStack Engineer인 [Lee Tickett](https://gitlab.com/leetickett-gitlab)에 의해 그의 기여와 귀중한 피드백 제공으로 추천되었습니다.

GitLab의 Senior Product Designer인 [Gina Doyle](https://gitlab.com/gdoyle)이 추천에 추가되었습니다. "내부에서 많은 논의가 있었고 그 결과 MR 프로세스가 더 복잡해졌습니다"라고 Gina는 말했습니다. "하지만 Joel은 토론 내에서 강하고 활동적으로 남아 기여를 완료했습니다."

"Joel은 또한 CI/CD 카탈로그 이슈에 대한 UI 개선에 기여했습니다"라고 GitLab의 Staff Product Designer인 [Sunjung Park](https://gitlab.com/sunjungp)는 말했습니다. "사용자 인터페이스를 아름답고 다른 영역과 일관되게 만듭니다."

Joel의 모든 기여와 GitLab에 기여한 모든 오픈 소스 커뮤니티에 감사합니다!

## 주요 기능 {#primary-features}

### GitLab Duo Chat용 자체 호스팅 모델 사용 {#use-self-hosted-model-for-gitlab-duo-chat}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501267)

{{< /details >}}

이제 선택한 대형 언어 모델(LLM)을 자신의 인프라에서 호스팅하고 해당 모델을 GitLab Duo Chat의 소스로 구성할 수 있습니다. 이 기능은 베타 상태이며 자체 관리되는 GitLab 환경에서 Ultimate 및 Duo Enterprise 구독으로 사용할 수 있습니다.

자체 호스팅 모델을 사용하면 온프레미스 또는 프라이빗 클라우드에서 호스팅되는 모델을 GitLab Duo Chat 또는 Code Suggestions(GitLab 17.5에서 베타 기능으로 도입됨)의 소스로 사용할 수 있습니다. Code Suggestions의 경우 현재 vLLM 또는 AWS Bedrock의 오픈소스 Mistral 모델, AWS Bedrock의 Claude 3.5 Sonnet, Azure OpenAI의 OpenAI 모델을 지원합니다. Chat의 경우 현재 vLLM 또는 AWS Bedrock의 오픈소스 Mistral 모델과 AWS Bedrock의 Claude 3.5 Sonnet을 지원합니다. 자체 호스팅 모델을 활성화하면 완전한 데이터 주권과 개인정보 보호를 유지하면서 생성형 AI의 강력한 기능을 활용할 수 있습니다.

[이슈 501268](https://gitlab.com/gitlab-org/gitlab/-/issues/501268)에서 피드백을 남겨주세요.

### 향상된 머지 리퀘스트 검토자 할당 {#enhanced-merge-request-reviewer-assignments}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/reviews/_index.md#request-a-review)

{{< /details >}}

변경 사항을 신중하게 준비하고 머지 리퀘스트를 작성한 후, 다음 단계는 이를 앞으로 나아가게 할 수 있는 검토자를 식별하는 것입니다. 머지 리퀘스트에 적합한 검토자를 식별하려면 적절한 승인자가 누구이고 제안하는 변경 사항에 대해 주제 전문가(CODEOWNER)가 될 수 있는 사람이 누구인지 이해해야 합니다.

이제 검토자를 할당할 때 사이드바는 머지 리퀘스트의 승인 요구 사항과 검토자 간의 연결을 만듭니다. 각 승인 규칙을 보고 해당 승인 규칙을 만족할 수 있는 승인자를 선택하여 머지 리퀘스트를 앞으로 나아가게 합니다. [선택적 CODEOWNER 섹션](../../user/project/codeowners/reference.md#optional-sections)을 사용하면 해당 규칙도 사이드바에 표시되어 변경 사항에 적합한 주제 전문가를 식별하는 데 도움이 됩니다.

향상된 검토자 할당은 GitLab에서 할당된 검토자에 지능을 적용하는 다음 단계의 진화입니다. 이 반복은 제안된 검토자로부터 학습한 내용과 머지 리퀘스트를 앞으로 나아가게 할 최고의 검토자를 효과적으로 식별하는 방법을 바탕으로 합니다. 검토자 할당의 [향후 반복](https://gitlab.com/groups/gitlab-org/-/epics/14808)에서 권장할 가능한 검토자를 추천하고 순위를 지정하는 데 사용되는 지능을 계속 개선할 것입니다.

### 워크스페이스에서 프라이빗 컨테이너 레지스트리 지원 {#support-for-private-container-registries-in-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/configuration.md#configure-support-for-private-container-registries)

{{< /details >}}

GitLab 워크스페이스는 이제 프라이빗 컨테이너 레지스트리 지원을 제공합니다. 이 설정을 사용하면 선택한 모든 프라이빗 레지스트리에서 컨테이너 이미지를 가져올 수 있습니다. Kubernetes 클러스터에 유효한 이미지 풀 시크릿이 있는 한, [GitLab 에이전트 구성](../../user/workspace/gitlab_agent_configuration.md)에서 시크릿을 참조할 수 있습니다.

이 기능은 특히 사용자 지정 또는 타사 컨테이너 레지스트리를 사용하는 팀의 워크플로를 간소화하고 컨테이너화된 개발 환경의 유연성과 보안을 개선합니다.

### 워크스페이스에서 사용 가능한 확장 마켓플레이스 {#extension-marketplace-now-available-in-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

확장 마켓플레이스를 이제 워크스페이스에서 사용할 수 있습니다. 확장 마켓플레이스를 통해 타사 확장을 발견, 설치 및 관리하여 개발 경험을 향상시킬 수 있습니다. 수천 개의 확장에서 선택하여 생산성을 높이거나 워크플로를 사용자 지정하세요.

확장 마켓플레이스는 기본적으로 비활성화됩니다. 시작하려면 사용자 기본 설정으로 이동하여 [확장 마켓플레이스를 활성화](../../user/profile/preferences.md#integrate-with-the-extension-marketplace)합니다. 엔터프라이즈 사용자의 경우 최상위 그룹의 소유자 역할을 가진 사용자만 [확장 마켓플레이스를 활성화](../../user/enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users)할 수 있습니다.

### 지연된 종료를 통한 향상된 워크스페이스 수명 주기 {#improved-workspace-lifecycle-with-delayed-termination}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/_index.md#automatic-workspace-stop-and-termination)

{{< /details >}}

이 릴리스에서 워크스페이스는 구성된 시간 초과가 경과한 후 종료되지 않고 중지됩니다. 이 기능은 항상 워크스페이스를 다시 시작하고 중단한 위치에서 계속할 수 있음을 의미합니다.

기본적으로 워크스페이스는 자동으로:

- 워크스페이스가 마지막으로 시작되거나 다시 시작된 후 36시간 후에 중지
- 워크스페이스가 마지막으로 중지된 후 722시간 후에 종료

[GitLab 에이전트 구성](../../user/workspace/gitlab_agent_configuration.md)에서 이러한 설정을 구성할 수 있습니다.

이 기능을 사용하면 워크스페이스가 중지된 후 약 1개월 동안 사용 가능한 상태로 유지됩니다. 이 방법으로 워크스페이스 리소스를 최적화하면서 진행 상황을 유지할 수 있습니다.

### 배포 세부 정보 페이지에 릴리스 정보 표시 {#display-release-notes-on-deployment-details-page}

<!-- categories: Continuous Delivery -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/deployment_approvals.md#view-blocked-deployments) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/493260)

{{< /details >}}

승인하도록 요청받은 배포에 무엇이 포함될 수 있는지 궁금하신 적이 있으신가요? 이전 버전에서는 내용에 대한 상세 설명과 테스트 지침을 포함한 릴리스를 생성할 수 있었지만, 관련된 환경 특정 배포에는 이 데이터가 표시되지 않았습니다. 이제 GitLab이 관련 배포 세부 정보 페이지 아래에 릴리스 정보를 표시하는 것을 기쁘게 알려드립니다.

GitLab 릴리스는 항상 Git 태그에서 생성되므로, 릴리스 정보는 태그로 트리거된 파이프라인과 관련된 배포에만 표시됩니다.

이 기능은 [Anton Kalmykov](https://gitlab.com/antonkalmykov)에 의해 GitLab에 기여했습니다. 감사합니다!

### CI/CD 작업 토큰 허용 목록을 적용하기 위한 관리자 설정 {#admin-setting-to-enforce-cicd-job-token-allowlist}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../administration/settings/continuous_integration.md#access-job-token-permission-settings) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)

{{< /details >}}

이전에 기본 CI/CD 작업 토큰(`CI_JOB_TOKEN`) 동작이 [GitLab 18.0에서 변경될 것](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement)이라고 발표했으며, 이를 통해 프로젝트에 계속 액세스할 수 있으려면 명시적으로 [프로젝트 또는 그룹을 프로젝트의 작업 토큰 허용 목록에 추가](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)해야 합니다.

이제 자체 관리 및 Dedicated 인스턴스 관리자에게 인스턴스의 모든 프로젝트에 이 더 안전한 설정을 적용할 수 있는 기능을 제공합니다. 이 설정을 활성화한 후, 모든 프로젝트가 CI/CD 작업 토큰을 인증에 사용하려면 해당 허용 목록을 사용해야 합니다. *참고: 강력한 보안 정책의 일부로 이 설정을 활성화할 것을 권장합니다.*

### CI/CD 작업 토큰 인증 추적 {#track-cicd-job-token-authentications}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/ci_job_token.md#job-token-authentication-log) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467292)

{{< /details >}}

이전에는 CI/CD 작업 토큰으로 인증하여 프로젝트에 액세스하는 다른 프로젝트가 어떤 것인지 추적하기 어려웠습니다. 프로젝트에 대한 액세스를 감사하고 제어하기 쉽게 하기 위해 인증 로그를 추가했습니다.

이 인증 로그를 사용하면 작업 토큰으로 프로젝트를 인증한 다른 프로젝트의 목록을 UI와 다운로드 가능한 CSV 파일로 볼 수 있습니다. 이 데이터는 프로젝트 액세스를 감사하고 작업 토큰 허용 목록을 채우는 데 도움이 되어 더 강력한 [프로젝트에 액세스할 수 있는 프로젝트 제어](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)를 활성화할 수 있습니다.

### 취약성 보고서 그룹화 {#vulnerability-report-grouping}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

사용자는 그룹에서 취약성을 볼 수 있는 능력이 필요합니다. 이는 보안 분석가가 대량 작업을 활용하여 분류 작업을 최적화하는 데 도움이 됩니다. 또한 사용자는 그룹과 일치하는 취약성이 몇 개인지 볼 수 있습니다. 즉, OWASP Top 10 취약성이 몇 개인가요?

### 모델 레지스트리가 일반적으로 사용 가능 {#model-registry-now-generally-available}

<!-- categories: MLOps -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/ml/model_registry/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14998)

{{< /details >}}

GitLab의 모델 레지스트리는 이제 일반적으로 사용 가능하며 기존 GitLab 워크플로의 일부로 머신 러닝 모델을 관리하기 위한 중앙 집중식 허브입니다. 모델 버전을 추적하고, 아티팩트 및 메타데이터를 저장하고, 모델 카드에서 포괄적인 문서를 유지할 수 있습니다.

원활한 통합을 위해 구축된 모델 레지스트리는 [MLflow 클라이언트](../../user/project/ml/experiment_tracking/mlflow_client.md)와 기본적으로 작동하며 CI/CD 파이프라인에 직접 연결되어 자동화된 모델 배포 및 테스트를 활성화합니다. 데이터 과학자는 직관적인 UI 또는 기존 MLflow 워크플로를 통해 모델을 관리할 수 있으며, MLOps 팀은 [GitLab API](../../api/model_registry.md) 내에서 모든 간소화된 프로덕션 배포를 위해 시멘틱 버전 관리 및 CI/CD 통합을 활용할 수 있습니다.

우리의 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/504458)에 의견을 남겨주시면 연락드리겠습니다! 오늘 GitLab 인스턴스에서 **배포 > 모델 레지스트리**로 이동하여 시작하세요.

### GitLab Dedicated를 위한 새로운 테넌트 네트워킹 구성 {#new-tenant-networking-configurations-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../administration/dedicated/configure_instance/network_security.md#outbound-privatelink-connections)

{{< /details >}}

GitLab Dedicated 테넌트 관리자는 이제 Switchboard를 사용하여 아웃바운드 프라이빗 링크 및 프라이빗 호스팅 영역을 설정할 수 있습니다. 또한 Switchboard에서 주기적 스냅샷을 보고 네트워크 연결을 모니터링할 수 있습니다.

아웃바운드 프라이빗 링크 및 프라이빗 호스팅 영역은 AWS 계정의 리소스와 GitLab Dedicated 간의 안전한 네트워크 연결을 설정합니다.

### SAST 및 DAST 보안 스캐너에 대한 새로운 준수 점검 {#new-adherence-checks-for-sast-and-dast-security-scanners}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_status_report.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12661)

{{< /details >}}

GitLab은 SAST, 시크릿 검색, 종속성 검사, 컨테이너 검사 등 광범위한 보안 스캐너를 제공하므로 애플리케이션의 보안 취약성을 확인할 수 있습니다.

감사자 및 관련 규정 준수 당국에 애플리케이션이 리포지토리에 보안 스캐너 설정을 요구하는 규제 표준을 준수했음을 보여줄 수 있는 방법이 필요합니다.

이러한 표준 준수를 입증하는 데 도움이 되도록 이 릴리스에는 규정 준수 센터의 표준 준수 보고서의 일부로 두 가지 새로운 점검이 포함됩니다. 이러한 새로운 점검은 SAST 및 DAST가 그룹 내 프로젝트에 대해 활성화되었는지 확인합니다. 점검은 SAST 및 DAST 보안 스캐너가 프로젝트에서 올바르게 실행되었고 파이프라인 결과에 올바른 결과 아티팩트가 있는지 확인합니다.

## 규모 및 배포 {#scale-and-deployments}

### 그룹 웹후크에 대한 프로젝트 이벤트 {#project-events-for-group-webhooks}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md#project-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/359044)

{{< /details >}}

이 릴리스에서 그룹 웹후크에 프로젝트 이벤트를 추가했습니다. 프로젝트 이벤트는 다음과 같이 트리거됩니다:

- 프로젝트가 그룹에서 생성됩니다.
- 프로젝트가 그룹에서 삭제됩니다.

이러한 이벤트는 [그룹 웹후크](../../user/project/integrations/webhooks.md#group-webhooks)에만 트리거됩니다.

### 할당된 사용자 기준으로 GitLab Duo 사용자 필터링 {#filter-gitlab-duo-users-by-assigned-seat}

<!-- categories: Add-on Provisioning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: GitLab Duo Pro, GitLab Duo Enterprise
- 링크: [설명서](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14683)

{{< /details >}}

GitLab의 이전 버전에서는 GitLab Duo 사용자 기준 할당 페이지에 표시된 사용자 목록을 필터링할 수 없어 이전에 GitLab Duo 사용자 기준이 할당된 사용자를 보기 어려웠습니다. 이제 사용자 목록을 할당된 사용자 기준 = 예 또는 할당된 사용자 기준 = 아니오로 필터링하여 현재 할당되거나 할당되지 않은 GitLab Duo 사용자 기준을 볼 수 있으므로 사용자 기준 할당을 쉽게 조정할 수 있습니다.

### GitLab Duo 사용자 기준 할당 이메일 업데이트 {#gitlab-duo-seat-assignment-email-update}

<!-- categories: Seat Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170507)

{{< /details >}}

자체 관리 인스턴스의 모든 사용자는 GitLab Duo 사용자 기준이 할당될 때 이메일을 받습니다.

이전에는 Duo Enterprise 사용자 기준이 할당되었거나 대량 할당으로 액세스 권한이 부여된 사용자는 알림을 받지 않았습니다. 누군가 알려주거나 GitLab UI에서 새로운 기능을 발견하지 않는 한 사용자 기준이 할당되었다는 것을 알 수 없었습니다.

이 이메일을 비활성화하려면 관리자는 `duo_seat_assignment_email_for_sm` 기능 플래그를 비활성화할 수 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### EPSS를 사용한 효율적인 위험 우선순위 지정 {#efficient-risk-prioritization-with-epss}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/graphql/reference/_index.md#cveenrichmenttype) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

GitLab 17.6에서는 Exploit Prediction Scoring System(EPSS) 지원을 추가했습니다. EPSS는 향후 30일 내에 CVE가 악용될 확률을 나타내는 0과 1 사이의 점수를 각 CVE에 제공합니다. EPSS를 활용하여 스캔 결과의 우선순위를 더 잘 지정하고 취약성이 환경에 미칠 수 있는 잠재적 영향을 평가하는 데 도움을 줄 수 있습니다.

이 데이터는 GraphQL을 통해 구성 분석 사용자가 사용할 수 있습니다.

### API를 통해 프로젝트에서 시크릿 푸시 보호 활성화 {#enable-secret-push-protection-in-your-projects-via-api}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/projects.md)

{{< /details >}}

이제 시크릿 푸시 보호를 프로그래밍 방식으로 활성화하기가 더 쉬워졌습니다. 애플리케이션 설정 REST API를 업데이트하여 다음을 수행할 수 있습니다:

1. 자체 관리 인스턴스에서 기능을 활성화하면 프로젝트 기준으로 활성화할 수 있습니다.
1. 기능이 프로젝트에서 활성화되었는지 확인합니다.
1. 지정된 프로젝트에 대해 기능을 활성화합니다.

### 적용된 제외에 대한 시크릿 푸시 보호 감사 이벤트 {#secret-push-protection-audit-events-for-applied-exclusions}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/secret_detection/exclusions.md)

{{< /details >}}

시크릿 푸시 보호 제외가 적용될 때 감사 이벤트가 이제 기록됩니다. 이는 보안 팀이 프로젝트의 제외 목록에 있는 시크릿을 푸시할 수 있는 경우를 감사하고 추적할 수 있도록 합니다.

### 자동화된 리포지토리 X-Ray {#automated-repository-x-ray}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/project/repository/code_suggestions/repository_xray.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/14100)

{{< /details >}}

Repository X-Ray는 프로젝트의 종속성에 대한 추가 컨텍스트를 제공하여 코드 생성 요청의 정확성과 관련성을 개선하기 위해 GitLab Duo Code Suggestions에 대한 코드 생성 요청을 보강합니다. 이는 코드 생성의 품질을 개선합니다. 이전에는 Repository X-Ray가 구성하고 관리해야 하는 CI 작업을 사용했습니다.

이제 새로운 커밋이 프로젝트의 기본 브랜치로 푸시될 때 Repository X-Ray는 리포지토리의 적용 가능한 구성 파일을 스캔하고 구문 분석하는 백그라운드 작업을 자동으로 트리거합니다.

### GitLab Duo에 대한 회사 네트워크 지원 {#corporate-network-support-for-gitlab-duo}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../editor_extensions/language_server/_index.md#enable-proxy-authentication) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/159)

{{< /details >}}

GitLab Duo 플러그인의 최신 업데이트는 고급 프록시 인증을 도입합니다. 이를 통해 개발자는 엄격한 회사 방화벽이 있는 환경에서 원활하게 연결할 수 있습니다. 기존 HTTP 프록시 지원을 바탕으로 이 개선 사항은 인증된 연결을 허용합니다. 이는 VS Code 및 JetBrains IDE의 Duo 기능에 안전하고 중단 없는 액세스를 보장합니다.

이 업데이트는 제한된 네트워크 환경에서 안전한 인증 연결이 필요한 개발자에게 매우 중요합니다. 이는 보안을 훼손하지 않으면서 모든 Duo 기능을 사용 가능하게 유지합니다.

### 예약된 날짜 및 시간에 병합 {#merge-at-a-scheduled-date-and-time}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/auto_merge.md#prevent-merge-before-a-specific-date)

{{< /details >}}

일부 머지 리퀘스트는 특정 날짜 또는 시간 이후에 병합할 때까지 보류해야 할 수 있습니다. 해당 날짜 및 시간이 경과하면 병합 권한이 있는 사람을 찾아야 하고 그들이 이를 처리할 수 있기를 바랍니다. 업무 시간 이후이거나 일정이 긴급하면 미리 사람들을 준비해야 할 수 있습니다.

이제 머지 리퀘스트를 생성하거나 편집할 때 `merge after` 날짜를 지정할 수 있습니다. 이 날짜는 경과할 때까지 머지 리퀘스트가 병합되지 않도록 하는 데 사용됩니다. 이전에 릴리스된 [자동 병합 개선 사항](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#auto-merge-when-all-checks-pass)과 함께 이 새로운 기능을 사용하면 향후 머지 리퀘스트를 병합하도록 예약할 수 있는 유연성을 얻을 수 있습니다.

놀라운 기여를 해주신 [Niklas van Schrick](https://gitlab.com/Taucher2003)에게 큰 감사를 드립니다!

### `glab agent bootstrap` 명령에 값 지원 추가 {#add-support-for-values-to-the-glab-agent-bootstrap-command}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md#options) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/482844)

{{< /details >}}

마지막 릴리스에서 GitLab CLI 도구에 쉬운 에이전트 부트스트래핑 지원을 도입했습니다. GitLab 17.6은 `glab cluster agent bootstrap` 명령을 사용자 지정 Helm 값 지원으로 추가로 개선합니다. `--helm-release-values` 및 `--helm-release-values-from` 플래그를 사용하여 생성된 `HelmRelease` 리소스를 사용자 지정할 수 있습니다.

### CI/CD 작업에서 환경에 대한 GitLab 에이전트 선택 {#select-a-gitlab-agent-for-an-environment-in-a-cicd-job}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard-for-a-dynamic-environment) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)

{{< /details >}}

Kubernetes용 대시보드를 사용하려면 환경 설정에서 Kubernetes 연결용 에이전트를 선택해야 합니다. 지금까지는 UI 또는(GitLab 17.5부터) API에서만 에이전트를 선택할 수 있었으므로 CI/CD에서 대시보드를 구성하기 어려웠습니다. GitLab 17.6에서는 `environment.kubernetes.agent` 구문으로 에이전트 연결을 구성할 수 있습니다. 또한 [이슈 500164](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)는 CI/CD 구성에서 네임스페이스 및 Flux 리소스 선택 지원을 추가하도록 제안합니다.

### 권한 있는 작업에 대한 감사 이벤트 {#audit-events-for-privileged-actions}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/compliance/audit_event_types.md#groups-and-projects) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/486532)

{{< /details >}}

이제 권한 있는 설정 관련 관리자 작업에 대한 추가 감사 이벤트가 있습니다. 이러한 설정이 변경된 시기에 대한 기록은 감사 추적을 제공하여 보안을 개선하는 데 도움이 됩니다.

### 머지 리퀘스트가 병합될 때의 새로운 감사 이벤트 {#new-audit-event-when-merge-requests-are-merged}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/audit_event_types.md#compliance-management) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/442279)

{{< /details >}}

이 릴리스에서 머지 리퀘스트가 병합될 때 `merge_request_merged`이라는 새로운 감사 이벤트 유형이 트리거되며 머지 리퀘스트에 대한 주요 정보를 포함합니다:

- 머지 리퀘스트의 제목
- 머지 리퀘스트의 설명 또는 요약
- 병합에 필요한 승인 수
- 병합에 부여된 승인 수
- 머지 리퀘스트를 승인한 사용자
- 커미터가 머지 리퀘스트를 승인하는지 여부
- 작성자가 머지 리퀘스트를 승인했는지 여부
- 병합의 날짜/시간
- 커밋 기록의 SHA 목록

### OTP 인증기 및 WebAuthn 장치를 독립적으로 비활성화 {#disable-otp-authenticator-and-webauthn-devices-independently}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/account/two_factor_authentication.md#disable-two-factor-authentication) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/393419)

{{< /details >}}

이제 OTP 인증기 및 WebAuthn 장치를 개별적으로 또는 동시에 비활성화할 수 있습니다. 이전에는 OTP 인증기를 비활성화하면 WebAuthn 장치도 비활성화되었습니다. 이제 두 가지가 독립적으로 작동하므로 이러한 인증 방법에 대한 더 세밀한 제어가 가능합니다.

### API를 사용하여 토큰 정보 가져오기 {#use-api-to-get-information-about-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../api/admin/token.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/443597)

{{< /details >}}

관리자는 새로운 토큰 정보 API를 사용하여 개인 액세스 토큰, 배포 토큰 및 피드 토큰에 대한 정보를 얻을 수 있습니다. 토큰 정보를 노출하는 다른 API 엔드포인트와 달리 이 엔드포인트를 통해 관리자는 토큰 유형을 알지 못해도 토큰 정보를 검색할 수 있습니다.

[Nicholas Wittstruck](https://gitlab.com/nwittstruck)와 Siemens의 나머지 팀원들께 감사합니다!

### 새 위치의 로그인 이메일에 더 많은 정보 {#more-information-in-sign-in-emails-from-new-locations}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/profile/notifications.md#notifications-for-unknown-sign-ins) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/296128)

{{< /details >}}

GitLab은 새로운 위치에서 로그인이 감지될 때 선택적으로 이메일을 전송합니다. 이전에는 이 이메일에 IP 주소만 포함되어 있어서 위치와의 관계를 파악하기 어려웠습니다. 이 이메일에는 이제 도시 및 국가 위치 정보도 포함됩니다.

[Henry Helm](https://gitlab.com/shangsuru)님의 기여에 감사드립니다!

### 그룹 보호 브랜치의 수정 방지 {#prevent-modification-of-group-protected-branches}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13776)

{{< /details >}}

머지 리퀘스트 승인 정책이 그룹 브랜치 수정을 방지하도록 구성되면 정책은 이제 그룹에 대해 구성된 보호 브랜치를 고려합니다. 이 설정은 그룹 수준에서 보호된 브랜치를 보호 해제할 수 없음을 보장합니다. 보호된 브랜치는 브랜치 삭제 및 브랜치에 대한 강제 푸시와 같은 특정 작업을 제한합니다. 특정 최상위 그룹의 예외를 선언하고 새로운 `approval_settings.block_group_branch_modification` 속성을 사용하여 이 동작을 재정의하여 필요할 때 그룹 소유자가 보호된 브랜치를 임시로 수정할 수 있도록 할 수 있습니다.

이 새로운 프로젝트 재정의 설정은 그룹 보호 브랜치 설정을 수정하여 보안 및 규정 준수 요구 사항을 회피할 수 없도록 하여 보호된 브랜치의 더 안정적인 적용을 보장합니다.

### 최상위 그룹 소유자가 서비스 계정을 만들 수 있음 {#top-level-group-owners-can-create-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/468806)

{{< /details >}}

현재는 관리자만 GitLab Self-Managed에서 서비스 계정을 만들 수 있습니다. 이제 최상위 그룹 소유자가 서비스 계정을 만들 수 있도록 하는 선택적 설정이 있습니다. 이를 통해 관리자는 서비스 계정을 만들 수 있는 더 넓은 범위의 역할을 원하는지, 아니면 관리자만 수행하는 작업으로 유지하는지 선택할 수 있습니다.

### 서비스 계정 배지 {#service-accounts-badge}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/service_accounts.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/439768)

{{< /details >}}

서비스 계정은 이제 지정된 배지를 가지고 있으며 사용자 목록에서 쉽게 식별할 수 있습니다. 이전에는 이러한 계정에만 `bot` 배지가 있어서 그룹 및 프로젝트 액세스 토큰과 구별하기 어려웠습니다.

### 모든 CI/CD 작업으로 Pages 사이트 배포 {#deploy-your-pages-site-with-any-cicd-job}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/_index.md#user-defined-job-names)

{{< /details >}}

파이프라인 설계의 유연성을 높이기 위해 Pages 배포 작업에 `pages` 이름을 지정할 필요가 없습니다. 이제 모든 CI/CD 작업에서 `pages` 속성을 사용하여 Pages 배포를 트리거할 수 있습니다.

### GitLab Duo Pro를 위한 AI 영향 분석 API {#ai-impact-analytics-api-for-gitlab-duo-pro}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../api/graphql/reference/_index.md#aimetrics)

{{< /details >}}

GitLab Duo Pro 고객은 이제 `aiMetrics` GraphQL API를 사용하여 프로그래밍 방식으로 AI 영향 분석 메트릭에 액세스할 수 있습니다. 메트릭에는 할당된 GitLab Duo 사용자, Duo Chat 사용자 및 Code Suggestion 사용자의 수가 포함됩니다. API는 또한 표시되고 수락되는 코드 제안에 대한 세분화된 수를 제공합니다. 이 데이터를 사용하면 Code Suggestions의 수용률을 계산하고 Duo Pro 사용자의 Duo Chat 및 Code Suggestions 채택을 더 잘 이해할 수 있습니다. AI 영향 분석 메트릭을 Value Stream Analytics 및 DORA 메트릭과 결합하여 Duo Chat 및 Code Suggestions 채택이 팀의 생산성에 미치는 영향에 대해 더 깊은 통찰력을 얻을 수도 있습니다.

### 보기에서 닫힌 항목을 쉽게 제거 {#easily-remove-closed-items-from-your-view}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/manage_epics.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/456941)

{{< /details >}}

이제 **닫힌 항목 표시** 토글을 끔으로써 연결된 항목 및 하위 항목 목록에서 닫힌 항목을 숨길 수 있습니다. 이 추가로 보기를 더 잘 제어할 수 있으며 복잡한 프로젝트에서 시각적 혼란을 줄이면서 활동적인 작업에 집중할 수 있습니다.

### 사용자 수준 GitLab Duo Enterprise 사용 메트릭 쿼리 {#query-user-level-gitlab-duo-enterprise-usage-metrics}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../api/graphql/reference/_index.md#aiusermetrics) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)

{{< /details >}}

이 릴리스 이전에는 Duo Enterprise 사용자당 GitLab Duo Chat 및 Code Suggestions 사용 데이터를 얻을 수 없었습니다. 17.6에서는 각 활성 Duo Enterprise 사용자에 대해 수락된 코드 제안의 수와 Duo Chat 상호작용에 대한 가시성을 제공하는 GraphQL API를 추가했습니다. API는 어떤 Duo Enterprise 기능을 사용하는지, 그리고 얼마나 자주 사용하는지에 대해 더 세분화된 통찰력을 얻을 수 있도록 도와줍니다. 이는 GitLab 내에서 [더 포괄적인 Duo Enterprise 사용 데이터를 제공](https://gitlab.com/groups/gitlab-org/-/epics/15026)하기 위한 우리의 목표 달성을 향한 첫 번째 반복입니다.

### CycloneDX SBOM의 라이선스 데이터 지원 {#support-for-license-data-from-cyclonedx-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415935)

{{< /details >}}

License Scanner는 이제 [지원되는 패키지 유형](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers)을 포함하는 CycloneDX SBOM에서 종속성의 라이선스를 사용할 수 있습니다.

CycloneDX SBOM의 `licenses` 필드를 사용할 수 있는 경우 사용자는 SBOM에서 라이선스 데이터를 볼 수 있습니다. SBOM에 라이선스 정보가 부족한 경우 License 데이터베이스에서 계속해서 이 데이터를 제공합니다.

### macOS Sequoia 15 및 Xcode 16 작업 이미지 {#macos-sequoia-15-and-xcode-16-job-image}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/macos.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/502852)

{{< /details >}}

이제 macOS Sequoia 15 및 Xcode 16을 사용하여 최신 세대 Apple 장치용 애플리케이션을 만들고, 테스트하고, 배포할 수 있습니다.

GitLab의 [macOS에서 호스팅되는 러너](../../ci/runners/hosted_runners/macos.md)는 GitLab CI/CD와 통합된 안전하고 온디맨드 빌드 환경에서 개발 팀이 macOS 애플리케이션을 더 빠르게 빌드하고 배포하도록 도와줍니다.

`macos-15-xcode-16` 이미지를 `.gitlab-ci.yml` 파일에서 사용하여 오늘 시도해 보세요.

### JaCoCo 테스트 커버리지 시각화가 이제 일반적으로 사용 가능 {#jacoco-test-coverage-visualization-now-generally-available}

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/testing/code_coverage/jacoco.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

이제 머지 리퀘스트 diff 보기에서 직접 JaCoCo 테스트 커버리지 결과를 볼 수 있습니다. 이 시각화를 통해 테스트로 제외된 라인과 병합 전에 추가 커버리지가 필요한 라인을 빠르게 식별할 수 있습니다.

### GitLab 러너 17.6 {#gitlab-runner-176}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 17.6도 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [GitLab 러너 17.5.0에서 Pod가 연결 가능한 상태가 되지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38260)
- [Fleeting 플러그인을 설치할 때 러너가 `exec format error`로 인해 충돌](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38247)
- [cgroup v2가 활성화된 Kubernetes 실행기 Pod가 OOMKilled될 때 중단됨](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38244)
- [구성 템플릿을 사용하여 러너를 등록할 때 러너 기본값을 준수하지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38231)
- [Exec 모드를 사용할 때 폴링 기간 동안 GitLab 러너가 Kubernetes Pod가 연결 가능한 상태가 될 때까지 대기](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37244)
- [기능 플래그 `FF_GIT_URLS_WITHOUT_TOKENS`이 활성화될 때 인증 이슈 발생](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38268)

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.6)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
