---
stage: Release Notes
group: Monthly Release
date: 2025-07-17
title: "GitLab 18.2 릴리스 정보"
description: "GitLab 18.2가 IDE의 Duo Agent Platform(베타)과 함께 출시되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 7월 17일에 GitLab 18.2가 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Markus Siebert {#this-months-notable-contributor-markus-siebert}

[Markus Siebert](https://gitlab.com/m-s-db)는 DB Systel GmbH의 플랫폼 엔지니어로, GitLab CI/CD에 네이티브 AWS Secrets Manager 지원을 가져오는 커뮤니티 노력을 주도하고 있으며, 파이프라인에서 안전한 시크릿 관리를 위한 중요한 엔터프라이즈 요구사항을 해결합니다. 단 6주 동안 인상적인 172개의 문서화된 활동을 수행한 Markus는 [AWS Secrets Manager에서 시크릿 검색 기능 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5587), [AWS SSM ParameterStore에 대한 GitLab CI 구성 항목 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191803), [AWS Secrets Manager 설명서](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192378)를 포함한 여러 머지 리퀘스트를 통해 AWS Secrets Manager 및 AWS Systems Manager Parameter Store 지원을 모두 구현하기 위해 부지런히 작업하고 있습니다.

"Markus의 작업은 GitLab 사용자가 AWS 환경에서 CI/CD 시크릿을 서드파티 도구나 커스텀 스크립트에 의존하지 않고 안전하게 관리할 수 있도록 합니다. 이는 AWS 서비스를 표준화한 엔터프라이즈 사용자에게 특히 중요합니다."라고 Markus를 추천한 GitLab의 시니어 백엔드 엔지니어 Secure인 [Aditya Tiwari](https://gitlab.com/atiwari71)가 말합니다.

초기 구현부터 설명서까지 이 기능을 완성하고자 하는 Markus의 헌신과 피드백에 따라 머지 리퀘스트를 적극적으로 유지 및 개선하는 모습은 커뮤니티 기여의 최고를 보여주며, AWS 사용자를 위해 GitLab을 더 좋게 만드는 커뮤니티 주도 개발의 힘을 입증합니다.

이 기여는 [GitLab Co-Create Program](https://about.gitlab.com/community/co-create/)을 통해 제공되었습니다.

Markus님의 귀중한 GitLab 기여에 감사드립니다!

## 주요 기능 {#primary-features}

### IDE의 Duo Agent Platform (베타) {#duo-agent-platform-in-the-ide-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [문서](../../user/duo_agent_platform/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/556038)

{{< /details >}}

Duo Agent Platform은 에이전트 대화와 에이전트 플로우를 VS Code 및 JetBrains IDE에 직접 제공하여 코드베이스 및 GitLab 프로젝트와의 자연스러운 대화 기반 상호 작용을 가능하게 합니다.

에이전트 대화는 파일 생성 및 편집, 패턴 매칭 및 grep을 사용한 코드베이스 검색, 코드에 대한 즉시 답변 등 빠른 대화식 작업을 위해 설계되었습니다. 에이전트 플로우는 더 큰 구현과 포괄적인 계획을 처리하며, 이슈, 머지 리퀘스트, 커밋, CI/CD 파이프라인 및 보안 취약성을 포함한 GitLab 리소스에 액세스하면서 개념에서 아키텍처로 고수준 아이디어를 가져갑니다. 둘 다 설명서, 코드 패턴 및 프로젝트 검색에 대한 지능형 검색 기능을 제공하여 빠른 편집에서 복잡한 프로젝트 분석까지 모든 것을 수행할 수 있도록 합니다.

플랫폼은 또한 외부 데이터 소스 및 도구 연결을 위한 Model Context Protocol(MCP)을 지원하여 AI 기능이 GitLab 외부 컨텍스트를 활용할 수 있도록 합니다.

자세한 내용은 블로그 [GitLab Duo Agent Platform 공개 베타: 차세대 AI 오케스트레이션 등](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/)에서 확인하세요.

시작하려면 [Duo Agent Platform 설명서](../../user/duo_agent_platform/_index.md), [VS Code 설정 가이드](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code), [JetBrains 설정 가이드](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides)를 참조하세요.

### 이슈 및 작업을 위한 커스텀 워크플로우 상태 {#custom-workflow-statuses-for-issues-and-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/work_items/status.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14794)

{{< /details >}}

기본 열림/닫힘 시스템을 넘어 작업 항목을 팀의 실제 워크플로우 단계를 통해 추적할 수 있도록 하는 구성 가능한 상태로 이동합니다.

레이블에 의존하는 대신 이제 프로세스를 정확하게 반영하는 커스텀 상태를 정의할 수 있습니다. 구성 가능한 상태를 사용하면 다음을 수행할 수 있습니다:

- **Define custom workflows** \- 팀의 실제 프로세스와 일치합니다.
- **Replace workflow labels** \- 적절한 상태로 더 쉽게 찾고, 업데이트하고, 보고할 수 있습니다.
- **Clarify completion outcomes** \- "완료" 또는 "취소"를 사용하여 이슈를 닫는 것 이상으로.
- **Filter and report accurately** \- 더 나은 프로젝트 인사이트를 위해 작업 항목 상태에서.
- **Use status in issue boards** \- 이슈가 열 사이를 이동할 때 자동 업데이트.
- **Bulk update status** \- 효율적인 워크플로우 관리를 위해 여러 작업 항목에 걸쳐.
- **Track dependencies** \- 연결된 작업 항목에 대한 상태 가시성.

커스텀 워크플로우 상태는 또한 **quick actions in comments**을 지원하고 GitLab의 열림/닫힘 시스템과 자동으로 동기화됩니다.

[피드백 이슈](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235)에서 의견과 제안을 공유하여 이 기능을 개선하도록 도와주세요.

### 새 머지 리퀘스트 홈페이지 {#new-merge-request-homepage}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/project/merge_requests/homepage.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13448)

{{< /details >}}

저자이자 검토자로 수십 개의 머지 리퀘스트를 처리할 때 여러 프로젝트에 걸쳐 코드 검토를 관리하는 것이 부담스러울 수 있습니다.

새로운 머지 리퀘스트 홈페이지는 지금 바로 주의가 필요한 항목을 지능적으로 우선순위 지정하여 검토 워크로드를 탐색하는 방식을 변환하며, 강력한 두 가지 보기 모드를 제공합니다:

- **Workflow view** \- 코드 검토 워크플로우의 단계별로 작업을 그룹화하여 머지 리퀘스트를 검토 상태별로 구성합니다.
- **Role view** \- 저자 또는 검토자 여부에 따라 머지 리퀘스트를 그룹화하여 명확한 책임 분리를 제공합니다.

**활성** 탭은 주의가 필요한 머지 리퀘스트를 표시하고, **머지됨**은 최근에 완료된 작업을 표시하며, **검색**은 포괄적인 필터링 기능을 제공합니다.

새 홈페이지는 또한 저자 작성 및 할당된 머지 리퀘스트를 모두 결합하여 가시성을 확장하여 위임된 작업을 절대 놓치지 않도록 합니다.

### 불변 컨테이너 태그로 보안 개선(베타) {#improve-security-with-immutable-container-tags-beta}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../user/packages/container_registry/immutable_container_tags.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15139)

{{< /details >}}

컨테이너 레지스트리는 최신 DevSecOps 팀의 중요한 인프라입니다. 그러나 보호된 컨테이너 태그가 있어도 조직은 여전히 과제에 직면합니다: 태그가 생성되면 충분한 권한을 가진 사용자가 이를 변경할 수 있습니다. 이는 프로덕션 안정성을 위해 특정 태그가 지정된 버전의 컨테이너 이미지에 의존하는 팀에 위험을 초래합니다. 권한이 있는 사용자라도 수정하면 의도하지 않은 변경을 초래하거나 배포 무결성을 손상시킬 수 있습니다.

불변 컨테이너 태그를 사용하면 컨테이너 이미지를 의도하지 않은 변경으로부터 보호할 수 있습니다. 불변 규칙과 일치하는 태그가 생성된 후에는 아무도 컨테이너 이미지를 수정할 수 없습니다. 이제 다음을 수행할 수 있습니다:

- RE2 정규식 패턴을 사용하여 프로젝트당 최대 5개의 전체 보호 규칙(보호 및 불변 규칙 결합)을 생성합니다.
- latest, 의미론적 버전(예: v1.0.0) 또는 릴리스 후보와 같은 중요한 태그를 모든 수정으로부터 보호합니다.
- 불변 태그가 정리 정책에서 자동으로 제외되도록 합니다.

불변 컨테이너 태그는 GitLab.com에서 기본적으로 활성화되는 차세대 컨테이너 레지스트리가 필요합니다. GitLab Self-Managed 인스턴스의 경우 불변 컨테이너 태그를 사용하려면 [메타데이터 데이터베이스](../../administration/packages/container_registry_metadata_database.md)를 활성화해야 합니다.

### GitLab Duo를 사용한 Premium 및 Ultimate에 대한 그룹 및 프로젝트 제어 {#group-and-project-controls-for-premium-and-ultimate-with-gitlab-duo}

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/gitlab_duo/turn_on_off.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)

{{< /details >}}

GitLab Premium 및 Ultimate 사용자는 이제 그룹 및 프로젝트에 대해 IDE에서 Code Suggestions 및 GitLab Duo Chat의 가용성을 변경할 수 있습니다. 이전에는 인스턴스 또는 최상위 그룹에 대해서만 가용성을 변경할 수 있었습니다.

### 새 그룹 개요 규정 준수 대시보드 {#new-group-overview-compliance-dashboard}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/compliance/compliance_center/compliance_overview_dashboard.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13909)

{{< /details >}}

규정 준수 센터는 규정 준수 팀이 규정 준수 상태 보고, 위반 보고 및 그룹에 대한 규정 준수 프레임워크를 관리하기 위한 중앙 위치입니다.

새 그룹 개요 규정 준수 대시보드는 규정 준수 관리자에게 그룹의 모든 프로젝트에 걸쳐 규정 준수 정보에 대한 집계된 보기를 제공합니다. 이 첫 번째 반복은 다음 정보를 표시합니다:

- 특정 규정 준수 프레임워크로 적용되는 프로젝트의 %.
- 그룹의 모든 프로젝트에 대한 실패한 요구사항의 %.
- 그룹의 모든 프로젝트에 대한 실패한 제어의 %.
- '주의'가 필요한 특정 프레임워크.

이 새로운 그룹 개요를 통해 규정 준수 관리자는 규정 준수 태세의 명확한 고수준 그림을 제공하는 단일 통합 보기를 갖게 되었습니다.

### 인스턴스에 대한 워크스페이스 Kubernetes 에이전트 매핑 {#map-workspace-kubernetes-agents-for-the-instance}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../user/workspace/gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-on-the-instance) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16485)

{{< /details >}}

GitLab 관리자는 이제 인스턴스에 대해 활성화된 워크스페이스 Kubernetes 에이전트를 매핑할 수 있습니다. 그러면 사용자는 해당 인스턴스의 모든 그룹 또는 프로젝트에서 워크스페이스를 생성할 수 있습니다.

이는 조직이 워크스페이스 Kubernetes 에이전트를 한 번에 프로비저닝하고 이러한 에이전트를 전체 인스턴스의 모든 현재 및 향후 프로젝트에 액세스할 수 있도록 함으로써 워크스페이스 확장성을 크게 증가시킵니다.

### 보안 보고서의 PDF 내보내기 다운로드 {#download-a-pdf-export-of-security-reports}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md#export-as-pdf) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16989)

{{< /details >}}

취약성 관리 노력의 상태와 진행 상황을 다른 이해 관계자에게 전달하기 위해 이제 각 프로젝트 또는 그룹의 보안 대시보드를 PDF 문서로 내보낼 수 있습니다.

### 중앙 집중식 보안 정책 관리(베타) {#centralized-security-policy-management-beta}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md#set-up-centralized-security-policy-management) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17392)

{{< /details >}}

규정 준수가 중요한 대규모 조직에서 팀은 종종 여러 프로젝트 및 그룹에 산재한 단편화된 정책으로 어려움을 겪습니다. 중앙 집중식 가시성이 없으면 일관된 시행을 보장하기가 시간 소비적인 과제가 되면서 규정 준수 위험이 증가합니다.

중앙 집중식 보안 정책 관리는 단일 지정된 규정 준수 및 보안 정책(CSP) 그룹을 통해 전체 GitLab 조직에서 보안 정책을 작성, 관리 및 시행하기 위한 통합 접근 방식을 소개합니다. 이를 통해 보안 팀은 다음을 수행할 수 있습니다:

- **Define policies once and apply everywhere**: CSP를 통해 한 번에 인스턴스 전체 보안 정책을 생성하고 모든 그룹 및 프로젝트에서 정책을 자동으로 시행합니다.
- **Configure business unit policies**: 최상위 그룹은 CSP 그룹에서 조직 정책을 상속하면서 자신의 고유한 정책 세트를 구성할 수 있습니다.
- **Ensure adherence to principle of least privilege**: 인스턴스에 대해 시행되는 중앙 정책 관리 계층을 설정합니다.

이 베타 릴리스는 중앙 집중식 정책 관리를 위한 기초 프레임워크를 설정하며, 모든 기존 보안 정책 유형에 대한 지원을 통해 그룹, 프로젝트 또는 인스턴스에 대해 구성할 수 있습니다.

## 에이전틱 코어 {#agentic-core}

### GitLab Duo Self-Hosted에서 Mistral Small을 이제 사용 가능 {#mistral-small-now-available-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18202)

{{< /details >}}

GitLab Duo Self-Hosted에서 Mistral Small을 사용할 수 있습니다. 이 모델은 GitLab Self-Managed 인스턴스에서 사용할 수 있으며, GitLab Duo Self-Hosted의 GitLab Duo Chat 및 Code Suggestions을 위한 첫 번째 완벽하게 호환되는 오픈 소스 모델입니다.

## 규모 및 배포 {#scale-and-deployments}

### 관리자는 사용자 확인 없이 기여를 재할당할 수 있습니다 {#administrators-can-reassign-contributions-without-user-confirmation}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523259)

{{< /details >}}

관리자는 이제 사용자 확인 없이 자리 표시자 사용자에서 활성 사용자로 기여를 재할당할 수 있습니다. 이 기능은 사용자가 재할당을 승인하기 위해 이메일을 확인하지 않을 때 프로세스가 중단된 더 큰 조직의 주요 과제를 해결합니다.

사용자 가장이 활성화된 GitLab 인스턴스에서 관리자는 데이터 무결성을 유지하면서 사용자 관리 워크플로우를 간소화할 수 있습니다. 재할당이 완료된 후 사용자는 여전히 알림 이메일을 받아 전 과정을 통해 투명성을 보장합니다.

### 자리 표시자 사용자에서 비활성 사용자로 재할당 {#reassign-from-placeholder-users-to-inactive-users}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523260)

{{< /details >}}

이전에는 관리자가 자리 표시자 사용자에서 활성 사용자로만 기여 및 멤버십을 재할당할 수 있었습니다.

GitLab Self-Managed에서는 관리자가 자리 표시자 사용자에서 비활성 사용자로 기여 및 멤버십을 재할당할 수도 있습니다. 이 기능을 사용하면 GitLab 인스턴스에서 차단, 금지 또는 비활성화된 사용자의 기여 이력 및 멤버십 정보를 보존할 수 있습니다.

관리자는 먼저 이 설정을 활성화해야 하며, 활성화되면 이 설정은 재할당 중에 사용자 확인을 건너뛰면서 안전한 액세스 제어를 유지함으로써 사용자 관리를 간소화합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 다중 아키텍처 컨테이너 이미지에 대한 컨테이너 스캔 지원 {#container-scanning-support-for-multi-architecture-container-images}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/container_scanning/_index.md#available-cicd-variables) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/543144)

{{< /details >}}

컨테이너 스캔은 이제 Linux Arm64 컨테이너 이미지 변형과 함께 제공됩니다. Linux Arm64 러너에서 실행할 때 분석기는 더 이상 에뮬레이션을 필요로 하지 않으므로 더 빠른 분석이 가능합니다. 또한 `TRIVY_PLATFORM` 환경 변수를 스캔하려는 플랫폼으로 설정하여 다중 아키텍처 이미지를 스캔할 수 있습니다.

### 컨테이너 스캔을 위한 개선된 아카이브 파일 지원 {#improved-archive-file-support-for-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/container_scanning/_index.md#scanning-archive-formats) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501077)

{{< /details >}}

GitLab 18.2는 컨테이너 스캔에 개선된 아카이브 파일 스캔 지원을 제공합니다. 특정 패키지의 취약성이 여러 이미지에서 발견되면 이제 스캔된 각 이미지에 귀속된 취약성을 볼 수 있습니다.

### JavaScript에 대한 정적 도달성 지원 {#static-reachability-support-for-javascript}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/dependency_scanning/static_reachability.md#supported-languages-and-package-managers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)

{{< /details >}}

Composition Analysis는 이제 JavaScript 라이브러리에 대한 정적 도달성을 지원합니다. 정적 도달성에서 생성된 데이터를 분류 및 개선 의사 결정의 일부로 사용할 수 있습니다. 정적 도달성 데이터는 또한 EPSS, KEV 및 CVSS 점수와 함께 사용하여 취약성의 더 집중된 보기를 제공할 수 있습니다.

### 성공적인 DAST 로그인 확인을 위한 개선된 지원 {#improved-support-for-verifying-successful-dast-login}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/dast/browser/configuration/variables.md#authentication) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435942)

{{< /details >}}

이전에는 `DAST_AUTH_SUCCESS_IF_AT_URL` 변수가 성공적인 인증을 확인하기 위해 정확한 URL 일치를 필요로 했습니다. 이는 정적 방문 페이지가 있는 애플리케이션에는 잘 작동했지만 로그인 후 URL이 각 로그인에 대한 동적 요소를 포함하는 애플리케이션의 경우 어려움을 야기했습니다.

이제 `DAST_AUTH_SUCCESS_IF_AT_URL` 변수에서 와일드카드 패턴을 사용하여 동적 URL 패턴을 일치시킬 수 있습니다. 이 개선은 세션 간에 정확한 URL이 변경되어도 인증 성공을 확인하는 데 필요한 유연성을 제공합니다.

### 시간 기반 일회용 암호 MFA에 대한 DAST 지원 {#dast-support-for-time-based-one-time-password-mfa}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dast/browser/configuration/authentication.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13633)

{{< /details >}}

동적 분석은 이제 시간 기반 일회용 암호(TOTP) 다중 인증을 지원합니다.

포괄적인 보안 테스트를 보장하기 위해 TOTP MFA가 활성화된 프로젝트에 대해 DAST 스캔을 실행할 수 있습니다. 이 개선은 MFA가 배포된 프로덕션 환경을 미러링하는 구성에서 애플리케이션을 테스트하여 더 정확한 스캔 결과를 제공합니다.

### 감사 스트리밍 대상으로 스트리밍 비활성화 {#deactivate-streaming-to-an-audit-streaming-destination}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../administration/compliance/audit_event_streaming.md#activate-or-deactivate-streaming-destinations) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)

{{< /details >}}

이전에는 감사 스트리밍 대상으로의 스트리밍을 일시적으로 비활성화할 방법이 없었습니다. 스트림 연결 문제를 해결하거나 설정을 삭제하고 다시 시작하지 않고도 구성을 변경하기 위해 이 작업을 수행할 수 있습니다.

GitLab 18.2에서는 감사 스트림을 활성 또는 비활성으로 전환할 수 있는 기능을 추가했습니다. 감사 스트림이 비활성일 때 감사 이벤트는 더 이상 선택한 대상으로 스트리밍되지 않습니다. 다시 활성화하면 감사 이벤트가 다시 선택한 대상으로 스트리밍됩니다.

### 모든 감사 스트리밍 대상에 대한 필터 기능 {#filter-functionality-for-all-audit-streaming-destinations}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/compliance/audit_event_streaming.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/524939)

{{< /details >}}

이전에는 특정 감사 스트리밍 대상에 사용 가능한 모든 필터링 기능이 없었습니다.

이제 UI를 통해 모든 대상에 대해 필터 기능을 지원합니다. 다음을 필터링할 수 있는 기능을 포함합니다:

- 감사 이벤트 유형별.
- 그룹 또는 프로젝트별.

이 변경은 또한 AWS 및 GCP와 같은 감사 이벤트 대상이 감사 이벤트를 필터링할 수 있음을 의미합니다.

### 에픽 표시 기본 설정 구성 {#configure-epic-display-preferences}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/group/epics/manage_epics.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/393559)

{{< /details >}}

작업 항목의 목록을 볼 때 표시되는 메타데이터를 완벽하게 제어할 수 있어 자신에게 가장 중요한 정보에 집중할 수 있습니다.

이전에는 모든 메타데이터 필드가 항상 표시되어 작업 항목을 스캔하는 것이 압도적일 수 있었습니다. 이제 담당자, 레이블, 날짜, 마일스톤과 같은 특정 필드를 켜거나 꺼서 보기를 사용자 지정할 수 있습니다.

### 에픽 페이지에서 서랍 또는 전체 페이지에서 에픽 열기 {#open-epics-in-a-drawer-or-the-full-page-on-the-epics-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/group/epics/manage_epics.md#open-epics-in-a-drawer) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/536620)

{{< /details >}}

서랍 보기와 전체 페이지 탐색 사이를 전환하는 새 토글을 통해 목록 페이지에서 에픽을 여는 방법을 선택할 수 있습니다.

서랍을 사용하여 에픽 목록의 컨텍스트를 유지하면서 에픽 세부 정보를 빠르게 검토하거나, 상세한 편집 및 포괄적인 탐색을 위해 더 많은 화면 공간이 필요할 때 전체 페이지를 열 수 있습니다.

### [마일스톤](../../user/project/milestones/_index.md)을 에픽에 할당하여 장기 계획 향상 {#assign-milestones-to-epics-for-enhanced-long-term-planning}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/project/milestones/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/329)

{{< /details >}}

이제 [마일스톤](../../user/project/milestones/_index.md)을 에픽에 직접 할당할 수 있으며, 전략적 이니셔티브에서 실행으로의 자연스러운 계획 흐름을 만듭니다. 이 개선은 분기별 계획 또는 SAFe 프로그램 증분과 같은 장기 계획 케이던스를 에픽과 정렬하는 데 도움이 됩니다. 동시에 반복을 개발 스프린트에 집중할 수 있습니다.

이 명확한 계층 구조가 제자리에 있으면 행정 오버헤드를 줄이고 전략적 이니셔티브가 조직의 시간 프레임과 어떻게 진행되는지 더 잘 파악할 수 있습니다.

### 에픽을 팀 구성원에게 할당 {#assign-epics-to-team-members}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/group/epics/manage_epics.md#assignees) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/4231)

{{< /details >}}

이제 에픽을 개인에게 할당할 수 있으므로 전략적 이니셔티브를 감시할 책임이 있는 사람을 명확하게 할 수 있습니다. 에픽 담당자는 포트폴리오 수준에서 소유권을 파악하여 더 빠른 의사 결정 및 장기 목표에 대한 더 명확한 책임을 가능하게 합니다. 팀은 에픽 진행 상황, 의존성 또는 범위 변경에 대해 연락할 사람을 빠르게 볼 수 있습니다.

### GLQL 보기의 정렬 및 페이지 매김 {#sorting-and-pagination-for-glql-views}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/glql/_index.md#presentation-syntax) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)

{{< /details >}}

이 릴리스는 GLQL 보기에 대한 개선된 정렬 및 페이지 매김을 도입하여 큰 데이터 세트로 작업하기가 더 쉬워집니다.

이제 마감일, 건강 상태 및 인기도를 포함한 주요 필드로 정렬하여 가장 관련성 높은 항목을 빠르게 찾을 수 있습니다. 새로운 "더 로드" 페이지 매김 시스템은 데이터 로딩에 대한 더 나은 제어를 제공하여 압도적인 전체 페이지 결과를 필요에 따라 로드되는 관리 가능한 청크로 대체합니다.

이러한 개선은 팀이 복잡한 프로젝트 데이터를 효율적으로 탐색하고 주어진 순간에 가장 중요한 사항에 집중할 수 있도록 도와줍니다.

### GitLab Flavored Markdown에 대한 작업 항목 참조 및 편집기 개선 {#work-item-references-and-editor-improvements-for-gitlab-flavored-markdown}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/markdown.md#gitlab-specific-references) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

GitLab Flavored Markdown에서 통합 `[work_item:123]` 구문을 사용하여 이슈, 에픽 및 작업 항목을 참조할 수 있습니다. 이 새 구문은 이슈의 경우 `#123`, 에픽의 경우 `&123`과 같은 기존 참조 형식과 함께 작동하며, `[work_item:namespace/project/123]`를 사용한 프로젝트 간 참조를 지원합니다.

일반 텍스트 편집기는 또한 Enter를 누를 때 [커서 들여쓰기를 유지하기 위한 새로운 기본 설정](../../user/profile/preferences.md#maintain-cursor-indentation)을 포함하므로 중첩된 목록 및 코드 블록과 같은 구조화된 콘텐츠를 작성하기가 더 쉬워집니다.

### 취약성 ID가 취약성 보고서 CSV 내보내기에 추가됨 {#vulnerability-id-added-to-vulnerability-report-csv-export}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#exporting) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18033)

{{< /details >}}

이전에는 취약성 보고서의 CSV 내보내기에 취약성 ID가 포함되지 않았습니다. 이제 CSV 내보내기에 나열된 각 취약성의 ID를 찾을 수 있습니다.

### 취약성 보고서의 도달성 필터 {#reachability-filter-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/543346)

{{< /details >}}

사용자는 이제 취약성 보고서의 데이터를 필터링하여 도달 가능한 취약성만 포함할 수 있습니다. 도달 가능한 취약성은 다음 두 가지 취약성을 나타냅니다:

- 공통 취약성 및 노출(CVE) 목록에 있습니다.
- 명시적으로 가져온 라이브러리의 일부입니다.

### 취약성 GraphQL API는 추가 정보를 반환합니다 {#vulnerability-graphql-api-returns-additional-information}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../api/graphql/reference/_index.md#vulnerability) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/468913)

{{< /details >}}

GraphQL API를 사용하여 취약성이 도입된 시점과 마지막으로 감지된 시점의 파이프라인을 확인할 수 있습니다. 취약성 GraphQL API는 이제 다음을 포함합니다:

- `initialDetectedPipeline`: 취약성이 도입된 시점(예: 작성자의 사용자 이름)에 대한 추가 커밋 정보를 검색하는 데 사용합니다.
- `latestDetectedPipeline`: 취약성이 제거된 시점(예: 커밋 SHA)에 대한 추가 커밋 정보를 검색하는 데 사용합니다.

### 승인 정책에 대한 소스 브랜치 패턴 예외 {#source-branch-pattern-exceptions-for-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#source-branch-exceptions) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18113)

{{< /details >}}

이전에는 GitFlow를 사용하는 팀은 `release/*` 브랜치를 `main`로 병합할 때 승인 교착 상태에 자주 직면했으며, 대부분의 기여자가 릴리스 개발에 이미 참여했으므로 승인자로 역할을 할 수 없었습니다.

머지 리퀘스트 승인 정책의 브랜치 패턴 예외는 특정 소스 대상 브랜치 조합에 대해 승인 요구사항을 자동으로 우회하여 이 문제를 해결합니다. 기능-메인 병합에 대해 엄격한 승인을 구성하면서 간소화된 릴리스-메인 워크플로우를 허용합니다.

**Key capabilities:**

- **Pattern-based configuration:** `release/*` 또는 `hotfix/*`과 같은 소스 브랜치 패턴을 정의하여 승인 요구사항을 우회합니다
- **Seamless integration:** 브랜치 예외는 기존 머지 리퀘스트 승인 정책에 직접 통합되며 UI 또는 `policy.yml` 파일을 통해 구성할 수 있습니다.

이는 표준 개발 워크플로우에 대한 머지 리퀘스트 승인 정책의 보안 이점을 유지하면서 복잡한 해결 방법의 필요성을 제거합니다.

### 의존성 경로 표시 {#display-dependency-paths}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dependency_list/_index.md#dependency-paths) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16815)

{{< /details >}}

이전에는 의존성이 직접 의존성인지 또는 의존성의 후손에 의해 가져온 일시적 의존성인지 결정하기가 어려웠습니다.

이제 새로운 의존성 경로 기능을 사용하여 라이브러리가 주로 또는 이행적으로 가져오는지 결정할 수 있습니다. 프로젝트 및 그룹 의존성 목록과 취약성 세부 정보에서 의존성 경로를 찾을 수 있습니다. 이 기능을 사용하면 개발자는 라이브러리를 가져오는 방법에 따라 가장 효율적인 수정 경로를 결정할 수 있습니다.

### 자격 증명 인벤토리에 서비스 계정 토큰이 포함됨 {#credentials-inventory-now-includes-service-account-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../administration/credentials_inventory.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421954)

{{< /details >}}

GitLab은 이제 자격 증명 인벤토리에서 서비스 계정 토큰을 지원하여 소프트웨어 공급망 전체에서 사용되는 다양한 인증 방법에 대한 더 나은 가시성과 제어를 제공합니다. 자격 증명 인벤토리는 조직 전체에서 사용되는 자격 증명의 완전한 그림을 제공합니다.

### 포괄적인 자산 가시성을 위한 보안 인벤토리(베타) {#security-inventory-for-comprehensive-asset-visibility-now-in-beta}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/security_inventory/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16484)

{{< /details >}}

AppSec 팀은 모든 자산에 걸쳐 조직의 보안 태세를 완벽하게 파악해야 합니다. 이전에는 GitLab의 보안 워크플로우가 주로 프로젝트 수준의 스캐너 구성 및 프로젝트 수준의 취약성에 초점을 맞추었으므로 적용 범위 격차를 이해하고 효율적인 위험 기반 우선순위 결정을 내리기가 어려웠습니다.

보안 인벤토리는 GitLab 인스턴스에서 보안 태세에 대한 중앙 집중식 보기를 제공하여 AppSec 팀이 다음을 수행할 수 있도록 합니다:

- 프로젝트 및 그룹 전체에서 보안 적용 범위를 완벽하게 파악
- 보안 스캔이 없거나 구성 격차가 있는 자산 식별
- 보안 노력에 집중할 위치에 대해 정보에 입각한 위험 기반 의사 결정
- 시간 경과에 따른 보안 태세 개선 추적

이 기능은 개별 프로젝트 보안과 조직 전체 보안 전략 사이의 격차를 해소하여 효과적인 보안 프로그램 관리에 필요한 자산 인벤토리 기초를 제공합니다.

### 커스텀 관리자 역할(베타) {#custom-admin-role-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/custom_roles/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

커스텀 관리자 역할은 GitLab Self-Managed 및 GitLab Dedicated 인스턴스의 관리 영역에 세분화된 권한을 제공합니다. 전체 액세스를 부여하는 대신 관리자는 이제 사용자가 필요한 특정 기능에만 액세스할 수 있는 특화된 역할을 생성할 수 있습니다. 이 기능은 조직이 관리 기능에 대해 최소 권한 원칙을 구현하고, 과권한 액세스로 인한 보안 위험을 줄이며, 운영 효율성을 개선하도록 도와줍니다.

이 기능에 대한 커뮤니티 피드백을 적극적으로 찾고 있습니다. 질문이 있거나 구현 경험을 공유하거나 잠재적 개선에 대해 당사 팀과 직접 상담하고 싶다면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509376)를 방문하세요.

### 트리거 작업은 다운스트림 파이프라인 상태를 미러링할 수 있습니다 {#trigger-jobs-can-mirror-the-downstream-pipeline-status}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../ci/yaml/_index.md#triggerstrategy) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)

{{< /details >}}

이전에는 `strategy:depend`를 사용하는 트리거 작업은 수동 작업, 차단된 파이프라인 또는 실행 중 상태 변경이 있는 재시도된 파이프라인과 같은 복잡한 파이프라인 상태를 처리할 때 제한 사항이 있었습니다. 이로 인해 다운스트림 파이프라인이 적극적으로 실행 중인 것처럼 보일 수 있지만 실제로는 수동 작업에서 차단되었습니다.

새로운 `strategy:mirror` 키워드는 다운스트림 파이프라인의 정확한 실시간 상태를 미러링하여 더욱 세분화된 상태 보고를 제공합니다. 상태는 `running`, `manual`, `blocked` 및 `canceled`와 같은 중간 상태를 포함합니다. 이는 팀에 기존 워크플로우를 깨지 않고도 다운스트림 파이프라인의 현재 상태를 완벽하게 파악할 수 있습니다.

### GitLab 러너 18.2 {#gitlab-runner-182}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

GitLab 러너 18.2도 오늘 출시됩니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [GitLab 러너 18.1.0으로 업그레이드한 후 러너가 FIPS 모드에서 실패](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38890)
- [`FF_USE_DUMB_INIT_WITH_KUBERNETES_EXECUTOR`로 작업 포드를 시작할 수 없음](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/241)
- [`ubi-fips` 이미지가 GitLab 러너 FIPS의 기본 도우미 이미지 플레이버가 아님](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38273)
- [GitLab 유지보수 모드를 비활성화한 후 러너가 오랜 기간 오프라인 상태로 유지](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29181)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.2)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
