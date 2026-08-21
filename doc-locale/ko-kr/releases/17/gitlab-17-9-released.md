---
stage: Release Notes
group: Monthly Release
date: 2025-02-20
title: "GitLab 17.9 릴리스 정보"
description: "GitLab 17.9이 GitLab Duo Self-Hosted 일반 공급 시작과 함께 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 2월 20일에 GitLab 17.9가 다음 기능과 함께 릴리스되었습니다.

또한 이번 달의 주목할 만한 기여자를 포함하여 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

[Salihu Dickson](https://gitlab.com/salihudickson)을(를) [Wiki 페이지 댓글](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764) 기능 개발에 대한 뛰어난 기여를 인정하며 MVP로 선정하게 되어 기쁩니다. 이 기능은 커뮤니티에서 [200개 이상의 긍정적인 반응](https://gitlab.com/groups/gitlab-org/-/epics/14062)을(를) 얻었습니다!

그의 노력은 6개월 이상 지속되었으며, 거의 4,000줄의 코드로 [Wiki 최상위 수준 토론](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764)의 구현을 제공했습니다. Salihu는 또한 여러 개념 증명 구현을 만들었고 추가 기능과 버그 수정으로 Wiki 환경을 개선했습니다.

"Salihu는 Wiki 페이지 댓글을 개발하는 데 뛰어난 커뮤니티 기여자였습니다!" GitLab의 Product Manager, Plan:Knowledge인 [Matthew Macfarlane](https://gitlab.com/mmacfarlane)이(가) 공유했습니다. "Salihu의 광범위한 제품 지식으로 인해 이 핵심 기능을 더욱 효율적으로 제공할 수 있었습니다. Product Manager로서 Salihu 같은 기여자와 함께 일하는 것은 즐거움입니다!"

"놀라운 성과입니다!" GitLab의 Senior Product Designer, Plan:Knowledge인 [Alex Fracazo](https://gitlab.com/afracazo)이(가) 공유했습니다. "Salihu는 기본 기능만 구축한 것이 아니라 Wiki 페이지의 최상위 수준 토론에서 오류 처리 및 테스트 범위까지 포괄적인 엔드 투 엔드 기능을 제공했습니다." GitLab 팀의 많은 구성원들이 Salihu의 작업에 대해 강한 감사를 표현했으며, Vue.js 핵심 팀 구성원인 Principal Engineer Natalia Tepluhina와 GitLab의 Engineering Manager, Plan:Knowledge인 [Vladimir Shushlin](https://gitlab.com/vshushlin)을(를) 포함하여 그의 기술 능력과 협업을 강조했습니다.

Elixir Cloud의 프론트엔드 엔지니어이자 두 번의 GSoC 멘토인 Salihu는 이렇게 말했습니다 - "이것을 가능하게 하기 위해 나와 긴밀히 협력한 모든 사람에게 감사하고 싶습니다. [Himanshu Kapoor](https://gitlab.com/himkp)(GitLab의 Staff Frontend Engineer, Plan:Knowledge) 특별히 감사드립니다 - 지난 몇 개월 동안의 당신의 멘토십은 제가 여기서 한 모든 작업에 필수적이었고, 당신이 제공한 모든 지도와 지원에 진심으로 감사드립니다. 이 기능을 만드는 것은 정말로 팀 노력이었습니다 - 수백 줄의 코드를 꼼꼼히 검토한 리뷰어들부터 이것을 가능하게 한 [Piotr Skorupa](https://gitlab.com/pskorupa)(GitLab의 Backend Engineer, Plan:Knowledge)와 같은 백엔드 개발자까지입니다." 그는 팀과의 협업에 대한 열정을 표현했으며 "앞으로 더 많은 영향력 있는 기능에 기여하고 싶습니다!"

우리는 Salihu의 모든 기여에 대해 그리고 GitLab에 기여한 모든 오픈 소스 커뮤니티에 매우 감사합니다!

## 주요 기능 {#primary-features}

### GitLab Duo Self-Hosted 일반 공급 {#gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Model Selection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/517102)

{{< /details >}}

이제 선택된 대규모 언어 모델(LLM)을 자신의 인프라에서 호스트하고 이러한 모델을 GitLab Duo Code Suggestions 및 Chat의 소스로 구성할 수 있습니다. 이 기능은 이제 적용 가능한 라이센싱을 갖춘 자체 관리 GitLab 환경에서 일반적으로 사용 가능합니다.

GitLab Duo Self-Hosted를 사용하면 온프레미스 또는 프라이빗 클라우드에서 호스트된 모델을 GitLab Duo Chat 또는 Code Suggestions의 소스로 사용할 수 있습니다. 현재 vLLM 또는 AWS Bedrock의 오픈소스 Mistral 모델, AWS Bedrock의 Claude 3.5 Sonnet, Azure OpenAI의 OpenAI 모델을 지원합니다. 자체 호스팅 모델을 사용하면 완전한 데이터 주권과 개인 정보를 유지하면서 생성 AI의 힘을 활용할 수 있습니다.

[이슈 512753](https://gitlab.com/gitlab-org/gitlab/-/issues/512753)에서 피드백을 남겨주세요.

### 여러 Pages 사이트를 병렬 배포로 실행 {#run-multiple-pages-sites-with-parallel-deployments}

<!-- categories: Pages -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/_index.md#parallel-deployments) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14434)

{{< /details >}}

이제 병렬 배포를 통해 GitLab Pages 사이트의 여러 버전을 동시에 만들 수 있습니다. 각 배포는 구성된 접두사를 기반으로 고유한 URL을 가집니다. 예를 들어 고유 도메인을 사용하면 사이트는 `project-123456.gitlab.io/prefix`에서 액세스할 수 있으며, 고유 도메인이 없으면 `namespace.gitlab.io/project/prefix`에서 액세스할 수 있습니다.

이 기능은 다음이 필요할 때 특히 도움이 됩니다:

- 디자인 변경 또는 콘텐츠 업데이트를 미리 봅니다.
- 개발에서 사이트 변경 사항을 테스트합니다.
- 머지 리퀘스트의 변경 사항을 검토합니다.
- 여러 사이트 버전 유지(예: 현지화된 콘텐츠 포함).

병렬 배포는 기본적으로 24시간 후에 만료되어 저장 공간을 관리하는 데 도움이 되지만 이 기간을 사용자 정의하거나 배포를 절대 만료되지 않도록 설정할 수 있습니다. 자동 정리의 경우, 머지 리퀘스트에서 생성된 병렬 배포는 머지 리퀘스트이 병합되거나 닫힐 때 삭제됩니다.

### VS Code 및 JetBrains IDE에서 Duo Chat에 프로젝트 파일 추가 {#add-project-files-to-duo-chat-in-vs-code-and-jetbrains-ides}

<!-- categories: VS Code, JetBrains, Web Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/examples.md#ask-about-specific-files-in-the-ide) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15183)

{{< /details >}}

VS Code 및 JetBrains에서 Duo Chat에 프로젝트 파일을 직접 추가하여 더 강력하고 컨텍스트 인식 AI 지원을 잠금 해제합니다.

프로젝트 파일을 추가하면 Duo Chat은 특정 코드베이스에 대한 깊은 이해를 얻어 매우 상황에 맞는 정확한 응답을 제공할 수 있습니다. 이 컨텍스트 인식 기능을 통해 더 관련성 있는 코드 설명, 정밀한 디버깅 도움, 기존 코드베이스와 원활하게 통합되는 제안을 얻을 수 있습니다. 이 새롭고 흥미로운 기능에 대한 피드백을 환영합니다. 당신의 생각을 우리의 [피드백](https://gitlab.com/gitlab-org/gitlab/-/issues/492443) 이슈에서 공유해주세요.

### Sysbox를 사용한 Workspaces 컨테이너 지원 {#workspaces-container-support-with-sysbox}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/configuration.md#build-and-run-containers-in-a-workspace)

{{< /details >}}

GitLab Workspaces는 이제 개발 환경에서 직접 컨테이너를 빌드하고 실행하는 것을 지원합니다. Workspace가 [Sysbox로 구성된](../../user/workspace/configuration.md#with-sysbox) Kubernetes 클러스터에서 실행되면 추가 구성 없이 컨테이너를 빌드하고 실행할 수 있습니다.

GitLab 17.4에서 우리의 [sudo 액세스 기능](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#secure-sudo-access-for-workspaces)의 일부로 소개된 이 기능을 통해 GitLab Workspace 환경에서 전체 컨테이너 워크플로우를 유지할 수 있습니다.

### 사용자 정의 devfile 없이 Workspaces 만들기 {#create-workspaces-without-a-custom-devfile}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/_index.md#gitlab-default-devfile)

{{< /details >}}

이전에는 Workspace를 설정하려면 `devfile.yaml` 구성 파일을 만들어야 했습니다. GitLab은 이제 일반적인 개발 도구를 포함하는 기본 파일을 제공합니다. 이 향상 사항:

- 구성 장벽을 제거합니다.
- 모든 프로젝트에서 빠르게 Workspace를 만들 수 있습니다.
- 미리 구성되고 사용할 준비가 된 일반적인 개발 도구를 포함합니다.
- 구성 대신 개발에 집중할 수 있습니다.

추가 설정 또는 구성 단계 없이 즉시 개발을 시작하고 Workspace를 만듭니다.

### GitLab 관리 Kubernetes 리소스 {#gitlab-managed-kubernetes-resources}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/clusters/agent/managed_kubernetes_resources.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16130)

{{< /details >}}

[GitLab 관리 Kubernetes 리소스](../../user/clusters/agent/managed_kubernetes_resources.md)를 사용하여 Kubernetes에 더 많은 제어와 자동화로 애플리케이션을 배포합니다. 이전에는 각 환경에 대해 Kubernetes 리소스를 수동으로 구성해야 했습니다. 이제 GitLab 관리 Kubernetes 리소스를 사용하여 이러한 리소스를 자동으로 프로비저닝하고 관리할 수 있습니다.

GitLab 관리 Kubernetes 리소스를 사용하면 다음을 할 수 있습니다:

- 새 환경에 대한 네임스페이스 및 서비스 계정 자동 생성
- 역할 바인딩을 통한 액세스 권한 관리
- 필요한 다른 Kubernetes 리소스 구성

개발자가 애플리케이션을 배포할 때 GitLab은 제공된 리소스 템플릿을 기반으로 필요한 Kubernetes 리소스를 자동으로 생성하여 배포 프로세스를 간소화하고 환경 전체에서 일관성을 유지합니다.

### 프로젝트 환경 내의 배포에 대한 간소화된 액세스 {#simplified-access-to-deployments-within-project-environments}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/environments/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/505770)

{{< /details >}}

프로젝트 내 배포에 대한 개요를 얻기 위해 고생한 적이 있습니까? 이제 각 환경을 확장하지 않고도 환경 목록에서 최근 배포 세부 정보를 볼 수 있습니다. 각 환경에 대해 목록에 최신 성공 배포와 다른 경우 가장 최근 배포 시도가 표시됩니다.

### Wiki 페이지 댓글 {#wiki-page-comments}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/discussions/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14062)

{{< /details >}}

이제 Wiki 페이지에 직접 댓글을 추가하여 설명서를 대화형 협업 공간으로 변환할 수 있습니다.

Wiki 페이지의 댓글과 스레드는 팀을 돕습니다:

- 컨텍스트에서 콘텐츠를 직접 논의합니다.
- 개선 사항과 수정 사항을 제안합니다.
- 설명서를 정확하고 최신 상태로 유지합니다.
- 지식과 전문 지식을 공유합니다.

Wiki 댓글을 사용하면 팀은 직접 피드백과 토론을 통해 프로젝트와 함께 진화하는 생활하는 설명서를 유지할 수 있습니다.

### 워크플로 표시 향상: 머지 리퀘스트 검토 시간에 대한 새로운 통찰력 {#enhancing-workflow-visibility-new-insights-into-merge-request-review-time}

<!-- categories: Value Stream Management, Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/503754)

{{< /details >}}

개발 워크플로우 추적을 개선하기 위해 [Value Stream Analytics](https://about.gitlab.com/solutions/value-stream-management/)(VSA)가 새로운 이벤트로 확장되었습니다 - *Merge request last approved at*. [머지 리퀘스트 승인](../../user/project/merge_requests/approvals/_index.md) 이벤트는 검토 단계의 끝과 최종 파이프라인 실행 또는 병합 단계의 시작을 표시합니다. 예를 들어, 총 머지 리퀘스트 검토 시간을 계산하려면 시작 이벤트로 *Merge request reviewer first assigned*를 사용하고 종료 이벤트로 *Merge request last approved at*을(를) 사용하여 VSA 단계를 만들 수 있습니다.

이 향상 사항을 통해 팀은 검토 시간을 최적화할 수 있는 기회에 대한 더 깊은 통찰력을 얻어 개발의 전체 주기 시간을 줄이고 더 빠른 소프트웨어 배포로 이어집니다.

### 취약성 위험 우선 순위 지정을 위한 EPSS, KEV 및 CVSS 데이터 {#epss-kev-and-cvss-data-for-vulnerability-risk-prioritization}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerabilities/risk_assessment_data.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

다음 취약성 위험 데이터에 대한 지원을 추가했습니다:

- EPSS(Exploit Prediction Scoring System)
- KEV(Known Exploited Vulnerabilities)
- CVE(Common Vulnerabilities and Exposures)

이제 이 데이터를 사용하여 종속성 및 컨테이너 이미지 취약성 전체의 위험을 효율적으로 우선 순위를 지정할 수 있습니다. Vulnerability Report 및 Vulnerability Details 페이지에서 데이터를 찾을 수 있습니다.

### UI를 통해 전체 제어로 DAST 스캔 구성 {#configure-dast-scans-through-the-ui-with-full-control}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/on-demand_scan.md)

{{< /details >}}

복잡한 애플리케이션을 효과적으로 테스트하려면 보안 팀은 DAST 스캔을 구성할 때 유연성이 필요합니다. 이전에는 UI를 통해 구성된 DAST 스캔의 구성 옵션이 제한되어 있어 특정 보안 요구 사항이 있는 애플리케이션의 성공적인 스캔을 방지했습니다. 이는 빠른 보안 평가에도 파이프라인 기반 스캔을 사용해야 함을 의미했습니다.

이제 UI를 통해 파이프라인 기반 스캔에서 사용 가능한 것과 동일한 세분화된 제어로 DAST 스캔을 구성할 수 있습니다. 여기에는 다음이 포함됩니다:

- 사용자 정의 헤더 및 쿠키를 포함한 완전한 인증 구성
- 최대 페이지, 최대 깊이 및 제외된 URL과 같은 정확한 크롤 설정
- 고급 스캔 시간 초과 및 재시도 시도
- 최대 크롤링할 링크 및 DOM 깊이와 같은 사용자 정의 스캐너 동작
- 특정 취약성 유형에 대한 대상 스캔 모드

이러한 구성을 재사용 가능한 프로필로 저장하여 애플리케이션 전체에서 일관된 보안 테스트를 유지합니다. 모든 구성 변경은 감사 이벤트로 추적되므로 스캔 설정을 추가, 편집 또는 제거한 시기를 알 수 있습니다.

이 향상된 제어를 통해 자세한 감사 추적을 사용하여 규정을 준수하면서 더 효과적인 보안 스캔을 실행할 수 있습니다. 파이프라인 구성 관리에 시간을 소비하는 대신 각 애플리케이션에 맞는 스캔을 빠르게 시작하여 취약성을 더 빠르게 찾고 수정할 수 있습니다.

### 자동 CI/CD 파이프라인 정리 {#automatic-cicd-pipeline-cleanup}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/pipelines/settings.md#automatic-pipeline-cleanup) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/338480)

{{< /details >}}

과거에는 이전 CI/CD 파이프라인을 삭제하려면 API를 통해서만 할 수 있었습니다.

GitLab 17.9에서 CI/CD 파이프라인 만료 시간을 설정할 수 있는 프로젝트 설정을 도입했습니다. 정의된 보존 기간보다 오래된 파이프라인 및 관련 아티팩트는 삭제됩니다. 이는 많은 파이프라인을 실행하는 프로젝트의 디스크 사용량을 줄이고 전체 성능을 향상시키는 데 도움이 될 수 있습니다.

## 에이전틱 코어 {#agentic-core}

### 더 안전한 AI 연결을 위한 복합 ID {#composite-identity-for-more-secure-ai-connections}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../development/ai_features/composite_identity.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/506641)

{{< /details >}}

이전에는 GitLab 요청만 단일 사용자로 인증할 수 있었습니다. 복합 ID를 사용하면 요청을 서비스 계정과 사용자로 동시에 인증할 수 있게 되었습니다. AI 에이전트 사용 사례는 종종 시스템에서 작업을 시작한 사용자를 기반으로 권한을 요구하면서 동시에 시작 사용자와 별개의 별개 ID를 표시합니다. 복합 ID는 AI 에이전트의 ID를 나타내는 새로운 ID 주체입니다. 이 ID는 에이전트에 작업을 요청하는 인간 사용자의 ID와 연결됩니다. AI 에이전트 작업이 리소스에 액세스하려고 할 때마다 복합 ID 토큰이 사용됩니다. 이 토큰은 서비스 계정에 속하며 에이전트에 지시하는 인간 사용자와도 연결됩니다. 토큰에서 실행되는 인증 검사는 리소스에 대한 액세스를 부여하기 전에 두 주체를 모두 고려합니다. 두 ID 모두 리소스에 액세스해야 하며, 그렇지 않으면 액세스가 거부됩니다. 이 새로운 기능은 GitLab에 저장된 리소스를 보호하는 능력을 향상시킵니다. 서비스 계정의 복합 ID를 사용할 수 있는 방법에 대한 자세한 내용은 [설명서](../../development/ai_features/composite_identity.md)를 참조하세요.

## 규모 및 배포 {#scale-and-deployments}

### 사용자가 자신의 프로필을 비공개로 설정하는 것 제한 {#restrict-users-from-making-their-profile-private}

<!-- categories: User Management, User Profile -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/settings/account_and_limit_settings.md#prevent-users-from-making-their-profiles-private) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421310)

{{< /details >}}

사용자는 자신의 사용자 프로필을 공개 또는 비공개로 선택할 수 있습니다. 이제 관리자는 GitLab 인스턴스 전체에서 사용자가 프로필을 비공개로 설정할 수 있는 옵션을 가질 수 있는지 여부를 제어할 수 있습니다. Admin Area에서 "사용자가 자신의 프로필을 비공개로 만들 수 있도록 허용"은 이 설정을 제어합니다. 이 설정은 기본적으로 사용하도록 설정되어 사용자가 비공개 프로필을 선택할 수 있습니다.

### REST API를 사용하여 그룹에서 프로젝트 통합 관리 {#manage-project-integrations-from-a-group-with-the-rest-api}

<!-- categories: Source Code Management, Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/group_integrations.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/328496)

{{< /details >}}

이전에는 GitLab UI에서만 그룹으로부터 프로젝트 통합을 관리할 수 있었습니다. 이 릴리스에서는 REST API를 사용하여 이러한 통합을 관리할 수도 있습니다.

[Van](https://gitlab.com/van.m.anderson)에게 [초기 커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148283)에 감사드리며, 이는 나중에 GitLab에 의해 진행되고 완료되었습니다.

### 그룹 공유 가시성 향상 {#group-sharing-visibility-enhancement}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/members/sharing_projects_groups.md#view-shared-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/378629)

{{< /details >}}

GitLab 전체의 그룹 공유에 대한 확장된 가시성을 발표하게 되어 기쁩니다. 이전에는 그룹의 개요 페이지에서 공유 프로젝트를 볼 수 있었지만 그룹이 참가하도록 초대된 그룹을 볼 수 없었습니다. 이제 그룹 개요 페이지에서 **공유된 프로젝트** 및 **공유된 그룹** 탭을 모두 보고 조직 전체에서 그룹이 어떻게 연결되고 공유되는지 완전히 볼 수 있습니다. 이를 통해 조직 전체에서 그룹 액세스를 감사하고 관리하기가 더 쉬워집니다.

[에픽 16777](https://gitlab.com/groups/gitlab-org/-/epics/16777)에서 이 변경 사항에 대한 피드백을 환영합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Cargo, Conda, Cocoapods 및 Swift 프로젝트를 위해 SBOM을 사용하는 종속성 검사 활성화 {#enable-dependency-scanning-using-sbom-for-cargo-conda-cocoapods-and-swift-projects}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/519597)

{{< /details >}}

GitLab 17.9에서 Composition Analysis 팀은 새로운 Dependency Scanning 분석기를 사용하여 SBOM을 사용하는 Dependency Scanning으로의 전환을 시작합니다. 이 분석기는 Gemnasium의 교체가 되며, 18.0에서 지원이 종료되고 GitLab 19.0을 통해 사용 가능하게 유지됩니다.

SBOM을 사용하는 Dependency Scanning 접근 방식은 언어 지원의 확장, GitLab 플랫폼 내의 더 긴밀한 통합 및 경험, 그리고 산업 표준 보고서 유형(SBOM 기반 스캔 및 보고)으로의 전환을 통해 고객을 더 잘 지원합니다. GitLab 17.9 기준으로 새로운 Dependency Scanning 분석기는 `latest` Dependency Scanning CI/CD 템플릿(`Dependency-Scanning.latest.gitlab-ci.yml`)에서 기본적으로 활성화되며 다음 프로젝트 및 파일 유형에 대해:

- `conda-lock.yml` 파일을 사용하는 conda를 사용하는 C/C++/Fortran/Go/Python/R 프로젝트.
- `podfile.lock` 파일을 사용하는 Cocoapods를 사용하는 Objective-C 프로젝트.
- `cargo.lock` 파일을 사용하는 Cargo를 사용하는 Rust 프로젝트.
- `package.resolved` 파일을 사용하는 Swift를 사용하는 Swift 프로젝트.

이 변경으로 새로운 CI/CD 변수를 도입합니다: `DS_ENFORCE_NEW_ANALYZER` 기본적으로 `false`로 설정됩니다.

이 접근 방식을 통해 `latest` 템플릿의 모든 기존 고객이 기본적으로 Gemnasium 분석기를 계속 사용하고 위에 나열된 파일 유형에 대해 새로운 Dependency Scanning 분석기를 자동으로 활성화합니다.

새로운 Dependency Scanning 분석기로 마이그레이션하려는 기존 고객은 `DS_ENFORCE_NEW_ANALYZER`를 `true`(프로젝트, 그룹 또는 인스턴스 수준)로 설정할 수 있습니다. 이 변경 사항에 대한 자세한 내용은 [deprecation announcement](../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner) 및 관련 [migration guide](../../user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans.md)에서 읽을 수 있습니다.

새로운 Dependency Scanning 분석기의 사용을 완전히 방지하려는 고객은 CI/CD 변수 `DS_EXCLUDED_ANALYZERS`를 `dependency-scanning`로 설정해야 합니다.

### Swift 패키지에 대한 라이센스 스캔 지원 {#license-scanning-support-for-swift-packages}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/506730)

{{< /details >}}

GitLab 17.9에서 Swift 패키지에 대한 라이센스 스캔 지원을 추가했습니다. 이를 통해 프로젝트 내에서 Swift를 사용하는 사용자는 Swift 패키지의 라이센싱을 더 잘 이해할 수 있습니다.

이 데이터는 Dependency List, SBOM 보고서 및 GraphQL API를 통해 Composition Analysis 사용자가 사용할 수 있습니다.

### 멀티코어 Advanced SAST는 더 빠른 스캔을 제공합니다 {#multi-core-advanced-sast-offers-faster-scans}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/_index.md#security-scanner-configuration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/514156)

{{< /details >}}

GitLab Advanced SAST는 이제 성능을 향상시키기 위한 옵트인 기능으로 멀티코어 스캔을 제공합니다. 특히 더 큰 코드베이스의 경우 스캔 기간을 크게 줄일 수 있습니다.

활성화하려면 `SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD 변수를 `--multi-core N`로 설정합니다. 여기서 `N`은(는) 사용할 원하는 코어 수입니다. 다른 작업이 아닌 `gitlab-advanced-sast` 작업에서만 이 변수를 설정해야 합니다. 올바른 값을 선택하는 방법에 대한 중요한 지침은 [설명서](../../user/application_security/sast/_index.md#security-scanner-configuration)를 확인하세요.

이 성능 개선을 기본적으로 활성화하기 위해 작업 중입니다. 이는 [이슈 517409](https://gitlab.com/gitlab-org/gitlab/-/issues/517409)에서 추적됩니다.

### 프로젝트의 규정 준수 센터를 사용하여 규정 준수 프레임워크 적용 {#apply-a-compliance-framework-by-using-a-projects-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_projects_report.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/507986)

{{< /details >}}

GitLab 17.2에서 그룹 소유자가 그룹의 규정 준수 센터를 사용하여 그룹의 모든 프로젝트에 규정 준수 프레임워크를 적용하고 제거할 수 있는 기능을 출시했습니다.

이제 이를 확장하여 그룹 소유자가 프로젝트 수준에서 규정 준수 프레임워크를 적용하고 제거할 수도 있도록 했습니다. 이를 통해 그룹 소유자가 프로젝트 수준에서 규정 준수 프레임워크를 적용하고 모니터링하기가 더 쉬워집니다.

프로젝트 수준에서 규정 준수 프레임워크를 적용하고 제거하는 기능은 프로젝트 소유자가 아닌 그룹 소유자만 사용할 수 있습니다.

### Workspace 확장이 이제 제안된 API를 지원합니다 {#workspace-extensions-now-support-proposed-apis}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/_index.md#extension-marketplace)

{{< /details >}}

Workspace 확장이 이제 제안된 API 활성화를 지원하여 프로덕션 환경에서 호환성과 안정성을 개선합니다. 이 업데이트를 통해 Python Debugger와 같은 중요한 개발 도구를 포함하여 제안된 API에 의존하는 확장이 오류 없이 실행될 수 있습니다. 이 변경은 안정성을 유지하면서 API 액세스를 확대합니다.

### FluxCD CI/CD 구성 요소로 OCI 기반 GitOps 구현 {#implement-oci-based-gitops-with-the-fluxcd-cicd-component}

<!-- categories: Container Registry, Deployment Management, Component Catalog -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](https://gitlab.com/components/fluxcd/) \| [관련 이슈](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/experiments/fluxcd-ci-cd-component/-/issues/1)

{{< /details >}}

GitLab을 사용하여 GitOps 모범 사례를 구현하는 방법에 대해 궁금해한 적이 있습니까? 새로운 [FluxCD 구성 요소](https://gitlab.com/components/fluxcd/)를 사용하면 쉽습니다. FluxCD 구성 요소를 사용하여 Kubernetes 매니페스트를 OCI 이미지로 패키지화하고 이미지를 OCI 호환 컨테이너 레지스트리에 저장합니다. 선택적으로 이미지에 서명하고 즉시 FluxCD 조정을 트리거할 수 있습니다.

### Kubernetes와 GitLab 통합 시작하기 {#get-started-with-the-gitlab-integration-with-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/clusters/agent/getting_started.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/505216)

{{< /details >}}

이 릴리스에서는 GitLab을 사용하여 Kubernetes에 직접 및 FluxCD로 애플리케이션을 배포하는 방법을 보여주는 새로운 Kubernetes Getting started 가이드를 추가했습니다. 이러한 따라하기 쉬운 자습서는 완료하기 위해 깊이 있는 Kubernetes 지식이 필요하지 않으므로 초보자와 경험이 풍부한 사용자 모두 GitLab과 Kubernetes를 통합하는 방법을 배울 수 있습니다.

Kubernetes Getting started 가이드를 보충하기 위해 GitLab을 Kubernetes 환경으로 통합하기 위한 일련의 권장사항을 포함했습니다.

### 인증서 기반 Kubernetes 클러스터 발견 및 마이그레이션 {#discover-and-migrate-certificate-based-kubernetes-clusters}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/cluster_discovery.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/512420)

{{< /details >}}

인증서 기반 Kubernetes 통합은 2025년 5월 6일 9:00 AM UTC와 2025년 5월 8일 22:00 PM UTC 사이에 모든 사용자의 GitLab.com에서 비활성화되며 GitLab 19.0(2026년 5월 예상)의 GitLab Self-Managed 인스턴스에서 제거됩니다.

사용자 마이그레이션을 지원하기 위해 그룹 소유자가 쿼리할 수 있는 새 클러스터 API 엔드포인트를 추가하여 그룹, 하위 그룹 또는 프로젝트에 등록된 [인증서 기반 클러스터를 발견](../../api/cluster_discovery.md)할 수 있습니다. 또한 [마이그레이션 설명서](../../user/infrastructure/clusters/migrate_to_gitlab_agent.md)를 업데이트하여 다양한 사용 사례에 대한 지침을 제공합니다.

모든 GitLab.com 사용자가 영향을 받는지 확인하고 가능한 한 빨리 마이그레이션을 계획하시기를 권장합니다.

### 파이프라인 실행 정책에서 사용자 정의 단계 강제 적용 {#enforce-custom-stages-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/pipeline_execution_policies.md#inject_policy-type) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/475152)

{{< /details >}}

파이프라인 실행 정책에 대한 새로운 기능을 소개하게 되어 기쁩니다. **custom stages**를 CI/CD 파이프라인에 `Inject` 모드로 강제 적용할 수 있습니다. 이 기능은 보안 및 규정 준수 요구사항을 유지하면서 파이프라인 구조에 대한 더 큰 유연성과 제어를 제공하며 다음을 제공합니다:

- **Enhanced pipeline customization**: 파이프라인의 특정 지점에서 사용자 정의 단계를 정의하고 주입하여 작업 실행 순서에 대한 더욱 세분화된 제어를 허용합니다.
- **Improved security and compliance**: 빌드 후 배포 전과 같이 파이프라인의 가장 적절한 시점에서 보안 스캔 및 규정 준수 검사가 실행되도록 합니다.
- **Flexible policy management**: 중앙 집중식 정책 제어를 유지하면서 개발 팀이 정의된 보호 내에서 파이프라인을 사용자 정의할 수 있습니다.
- **Seamless integration**: 사용자 정의 단계는 기존 프로젝트 단계 및 기타 정책 유형과 함께 작동하여 CI/CD 워크플로를 향상시키는 방식을 방해하지 않습니다.

**How does it work?**

파이프라인 실행 정책을 위한 새로운 개선된 `inject_policy` 전략을 사용하면 정책 구성에서 사용자 정의 단계를 정의할 수 있습니다. 이러한 단계는 Directed Acyclic Graph(DAG) 알고리즘을 사용하여 프로젝트의 기존 단계와 지능적으로 병합되어 적절한 순서를 보장하고 충돌을 방지합니다.

예를 들어 빌드와 배포 단계 사이에 사용자 정의 보안 스캔 단계를 쉽게 주입할 수 있습니다.

`inject_policy` 단계는 `inject_ci`(더 이상 사용되지 않음)를 대체하여 `inject_policy` 모드를 선택하여 이점을 얻을 수 있습니다. `inject_policy` 모드는 정책 편집기에서 `Inject`를(을) 사용하여 정책을 구성할 때 기본값이 됩니다.

### `self_rotate` 범위로 액세스 토큰 회전 {#rotate-access-tokens-with-self_rotate-scope}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/430748)

{{< /details >}}

이제 `self_rotate` 범위를 사용하여 액세스 토큰을 회전할 수 있습니다. 이 범위는 개인, 프로젝트 또는 그룹 액세스 토큰에 사용할 수 있습니다. 이전에는 두 가지 요청이 필요했습니다: 하나는 새 토큰을 얻기 위한 요청, 다른 하나는 토큰 회전을 수행하기 위한 요청입니다.

기여해주신 [Stéphane Talbot](https://gitlab.com/stalb)님과 [Anthony Juckel](https://gitlab.com/ajuckel)님께 감사드립니다!

### 비활성 프로젝트 및 그룹 액세스 토큰 보기 {#view-inactive-project-and-group-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate, Silver, Gold
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/settings/project_access_tokens.md#view-your-access-tokens) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)

{{< /details >}}

이제 UI에서 비활성 그룹 및 프로젝트 액세스 토큰을 볼 수 있습니다. 이전에는 GitLab이 만료되거나 취소된 후 프로젝트 및 그룹 액세스 토큰을 즉시 삭제했습니다. 비활성 토큰 기록이 부족하면 감시 및 보안 검토가 어려워졌습니다. GitLab은 이제 비활성 그룹 및 프로젝트 액세스 토큰 레코드를 30일 동안 보유하므로 팀이 규정 준수 및 모니터링 목적으로 토큰 사용 및 만료를 추적할 수 있습니다.

### 액세스 토큰 IP 주소 보기 {#view-access-token-ip-addresses}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/profile/personal_access_tokens.md#view-token-usage-information) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)

{{< /details >}}

이전에는 개인 액세스 토큰을 볼 때 볼 수 있는 유일한 사용 정보는 토큰이 사용된 지 몇 분 전이었습니다. 이제 토큰이 사용된 마지막 7개 IP 주소까지 볼 수 있습니다. 이 결합된 정보는 토큰이 어디에서 사용되고 있는지 추적하는 데 도움이 될 수 있습니다.

기여해주신 [Jayce Martin](https://jrm2k.us)님, [Avinash Koganti](http://www.linkedin.com/in/avinash-koganti-38b511162)님, [Austin Dixon](https://austindixon.net/)님, [Rohit Kala](https://www.linkedin.com/in/rohit-kala-1b891a179)님께 감사드립니다!

### 그룹에 대한 GitLab Pages 액세스 제어 {#control-access-to-gitlab-pages-for-groups}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/pages_access_control.md#remove-public-access-for-group-pages)

{{< /details >}}

이제 그룹 수준에서 GitLab Pages 액세스를 제한할 수 있습니다. 그룹 소유자는 단일 설정을 활성화하여 그룹 및 해당 하위 그룹의 모든 Pages 사이트를 프로젝트 멤버에게만 표시할 수 있습니다. 이 중앙 집중식 제어는 개별 프로젝트 설정을 수정하지 않고도 보안 관리를 간소화합니다.

### 작업 항목 유형을 다른 유형으로 변경 {#change-work-item-type-to-another}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/tasks.md#convert-a-task-into-another-item-type) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)

{{< /details >}}

이제 작업 항목의 유형을 쉽게 변경할 수 있으므로 프로젝트를 더 효율적으로 관리할 수 있는 유연성을 제공합니다.

### 양식을 열어 두어 새 하위 항목 추가 속도 향상 {#speed-up-adding-new-child-items-by-keeping-the-form-open}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/work_items/child_items.md#work-with-multi-level-hierarchies) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/497767)

{{< /details >}}

각 제출 후 양식을 열어 두어 여러 하위 항목을 만드는 프로세스를 간소화했으므로 추가 클릭 없이 여러 항목을 더 쉽게 추가할 수 있습니다. 이 업데이트는 시간을 절약하고 작업을 관리할 때 더 부드러운 워크플로를 보장합니다.

### 작업 항목 GraphQL API - 추가 쿼리 필터 {#work-items-graphql-api---additional-query-filters}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/graphql/reference/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/513308)

{{< /details >}}

Work Items GraphQL API는 이제 다음으로 필터링할 수 있는 추가 쿼리 필터를 포함합니다:

- 작성, 업데이트, 종료 및 기한
- 건강 상태
- 가중치

이러한 새 필터를 통해 API를 통해 작업 항목을 쿼리하고 구성할 때 더 많은 제어가 가능합니다.

### 활성 보안 정책 프로젝트 삭제 차단 {#block-deletion-of-active-security-policy-projects}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/_index.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/482967)

{{< /details >}}

보안 정책의 안전한 관리를 보장하고 활성화되고 적용된 정책의 중단을 방지하기 위해 활성 사용 중인 보안 정책 프로젝트의 삭제를 방지하도록 보호를 추가했습니다.

보안 정책 프로젝트가 그룹 또는 프로젝트에 연결되어 있으면 보안 정책 프로젝트를 삭제하기 전에 링크를 제거해야 합니다.

### 프로젝트의 구성 요소별 종속성 목록 필터 {#dependency-list-filter-by-component-in-projects}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_list/_index.md#filter-dependency-list) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16490)

{{< /details >}}

프로젝트의 종속성 목록에서 구성 요소 필터를 사용하여 패키지 이름으로 필터링할 수 있습니다.

이전에는 프로젝트 수준의 종속성 목록에서 패키지를 검색할 수 없었습니다. 이제 구성 요소 필터를 설정하면 지정된 문자열을 포함하는 패키지를 찾을 수 있습니다.

### 프로젝트 취약성 보고서에서 식별자로 필터링 {#filter-by-identifier-in-the-project-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13340)

{{< /details >}}

프로젝트의 취약성 보고서에서 취약성 식별자로 필터링하여 프로젝트에 있는 특정 취약성(예: CVE 또는 CWE)을 찾을 수 있습니다. 심각도, 상태 또는 도구 필터와 같은 다른 필터와 함께 식별자를 사용할 수 있습니다. 취약성 식별자 필터는 20,000개 이하의 취약성이 있는 보고서로 제한됩니다.

### 머지 리퀘스트 승인 정책에서 사용자 지정 역할 지원 {#support-custom-roles-in-merge-request-approval-policies}

<!-- categories: Permissions, Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13550)

{{< /details >}}

승인자로 사용자 지정 역할을 할당할 수 있도록 추가하여 머지 리퀘스트 승인 정책을 더욱 유연하게 만들었습니다.

이제 조직의 고유한 팀 구조 및 책임과 일치하도록 승인 요구사항을 조정하여 정책을 기반으로 검토 프로세스에 올바른 역할이 참여하도록 할 수 있습니다. 예를 들어 보안 검토를 위해 AppSec Engineering 역할의 승인이 필요하고 라이센스 승인을 위해 Compliance 역할의 승인을 요구합니다.

### 자격 증명 인벤토리 검색 및 필터링 {#search-and-filter-the-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/credentials_inventory.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/345734)

{{< /details >}}

이제 자격 증명 인벤토리에서 검색 및 필터 기능을 사용할 수 있습니다. 이를 통해 특정 만료 기간 내에 만료되는 토큰을 포함하여 특정 사용자 정의 매개변수 내에 속하는 토큰 및 키를 더 쉽게 식별할 수 있습니다. 이전에는 자격 증명 인벤토리의 항목이 정적 목록으로 제시되었습니다.

### OAuth 애플리케이션 인증 감사 이벤트 {#oauth-application-authorization-audit-event}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/audit_event_types.md#authorization) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/514152)

{{< /details >}}

이전에는 사용자가 OAuth 애플리케이션을 인증할 때 감사 이벤트가 생성되지 않았습니다. 그러나 이 이벤트는 보안 팀이 특정 GitLab 인스턴스의 사용자가 인증한 OAuth 애플리케이션을 모니터링하는 데 중요합니다.

이 릴리스에서 GitLab은 이제 사용자가 OAuth 애플리케이션을 성공적으로 인증할 때를 추적하는 **User authorized an OAuth application** 감사 이벤트를 제공합니다. 이 새로운 감사 이벤트는 GitLab 인스턴스를 감시하는 능력을 더욱 향상시킵니다.

### API를 사용하여 개별 엔터프라이즈 사용자를 위해 2FA 비활성화 {#use-api-to-disable-2fa-for-individual-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/383319)

{{< /details >}}

이제 API를 사용하여 개별 엔터프라이즈 사용자의 모든 2단계 인증(2FA) 등록을 지울 수 있습니다. 이전에는 UI에서만 가능했습니다. API를 사용하면 자동 및 일괄 작업이 가능하여 2FA 재설정을 규모에 맞게 수행해야 할 때 시간을 절약합니다.

### 서비스 계정에 대한 이메일 알림 {#email-notifications-for-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/profile/service_accounts.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428750)

{{< /details >}}

이제 서비스 계정에 대한 이메일 알림을 받을 사용자 정의 이메일 주소를 설정할 수 있습니다. 서비스 계정을 만들 때 사용자 정의 이메일 주소를 지정하면 GitLab은 해당 주소로 알림을 보냅니다. 각 서비스 계정은 고유한 이메일 주소를 사용해야 합니다. 이를 통해 프로세스 및 이벤트를 더 효과적으로 모니터링할 수 있습니다.

[Gilles Dehaudt](https://gitlab.com/tonton1728)님, [Étienne Girondel](https://gitlab.com/lenaing)님, [Kevin Caborderie](https://gitlab.com/Densett)님, [Geoffrey McQuat](https://gitlab.com/gmcquat)님, [Raphaël Bihore](https://gitlab.com/rbihore)님 그리고 [SNCF Connect & Tech 팀](https://www.sncf-connect-tech.fr/)에서 기여해주셔서 감사드립니다!

### 여러 OIDC 공급자에 대한 추가 그룹 멤버십 지원 {#support-for-additional-group-memberships-with-multiple-oidc-providers}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/auth/oidc.md#configure-multiple-openid-connect-providers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/408248)

{{< /details >}}

이제 여러 OIDC 공급자를 사용할 때 추가 그룹 멤버십을 구성할 수 있습니다. 이전에는 여러 OIDC 공급자를 구성한 경우 단일 그룹 멤버십으로 제한되었습니다.

### 회전된 서비스 계정 토큰의 사용자 정의 만료 날짜 {#custom-expiration-date-for-rotated-service-account-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/service_accounts.md#rotate-a-personal-access-token-for-a-group-service-account) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)

{{< /details >}}

서비스 계정의 액세스 토큰을 회전할 때 이제 `expires_at` 속성을 사용하여 사용자 정의 만료 날짜를 설정할 수 있습니다. 이전에는 토큰이 회전 후 7일 후에 자동으로 만료되었습니다. 이를 통해 토큰 수명을 더욱 세분화되게 관리할 수 있으므로 안전한 액세스 제어를 유지하는 능력을 향상시킵니다.

### 파이프라인 실행 정책에서 머지 리퀘스트 변수 지원 {#support-merge-request-variables-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/pipeline_execution_policies.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/512916)

{{< /details >}}

파이프라인 실행 정책은 이제 추가 머지 리퀘스트 변수를 지원하므로 머지 리퀘스트과 관련된 정보를 고려하는 더 정교한 정책을 만들 수 있습니다. 이는 CI/CD 강제 적용에 대한 더 많은 대상 및 효율적인 제어를 제공합니다. 다음 변수가 이제 지원됩니다:

- `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`
- `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`
- `CI_MERGE_REQUEST_DIFF_BASE_SHA`

이 향상 사항을 사용하면 다음을 할 수 있습니다:

- 소스와 대상 브랜치 간의 변경 사항을 비교하는 고급 보안 스캔을 구현하여 철저한 코드 검토 및 취약성 탐지를 보장합니다.
- 각 머지 리퀘스트의 특성에 따라 조정되는 동적 파이프라인 구성을 만들어 개발 프로세스를 간소화합니다.

### 사용자 지정 역할을 위한 새로운 권한 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/custom_roles/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

[규정 준수 대시보드 읽기](https://gitlab.com/gitlab-org/gitlab/-/issues/465324) 권한으로 사용자 지정 역할을 만들 수 있습니다. 사용자 지정 역할을 통해 사용자가 작업을 완료하는 데 필요한 특정 권한만 부여할 수 있습니다. 이를 통해 그룹의 요구사항에 맞춤화된 역할을 정의할 수 있으며, Maintainer 또는 Owner 역할이 필요한 사용자 수를 줄일 수 있습니다.

### GitLab Runner 17.9 {#gitlab-runner-179}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

또한 오늘 GitLab Runner 17.9를 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [러너 자동 스케일러 인스턴스에 대한 헬스 체크 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [러너 준비 단계 기간에 대한 히스토그램 메트릭 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37471)
- [Kubernetes 실행기에 대한 사용자 정의 서비스 컨테이너 이름 지원 추가](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)

#### 버그 수정 {#bug-fixes}

- [GitLab Runner는 S3 Express One Zone에서 캐시를 검색할 수 없습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38484)
- [GitLab Runner는 AWS Spot 인스턴스에 대해 'script_failure' 대신 'runner_system_failure'을(를) 보고합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37911)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-9-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.9)
- [지원 중단 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
