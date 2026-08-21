---
stage: Release Notes
group: Monthly Release
date: 2025-09-18
title: "GitLab 18.4 릴리스 정보"
description: "GitLab 18.4 릴리스 - GitLab Duo 모델 선택 일반 공급 시작"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 9월 18일에 GitLab 18.4가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Patrick Rice {#this-months-notable-contributor-patrick-rice}

Patrick Rice는 기여자, 유지보수자, 멘토로서 GitLab의 오픈소스 커뮤니티에 헌신하고 있습니다. 지난 1년간 [상위 5명 기여자](https://contributors.gitlab.com/leaderboard?fromDate=2025-01-01&toDate=2025-09-18&search=&communityOnly=true)인 Patrick은 [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab)와 [client-go](https://gitlab.com/gitlab-org/api/client-go) 프로젝트를 유지보수하고 있으며, 기능 추가, 릴리스, 이슈 분류, 커뮤니티 온보딩을 담당하고 있습니다. 그는 기여자에서 프로젝트 유지보수자로 성장해나감으로써 누구나 기여할 수 있다는 GitLab의 미션을 구현하고 있습니다.

Patrick의 영향력은 코드 기여를 넘어 커뮤니티 구축과 코칭으로 확장되어, 새로운 기여자들이 시작하고 프로젝트에서 성장하도록 돕고 있습니다. Patrick은 이전에 [17.11 주목할 만한 기여자 상](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#notable-contributor)을 수상한 Heidi Berry를 지명하고 지원했습니다. 또한 [GitLab for Education](https://about.gitlab.com/solutions/education/) 팀과 GitLab을 배우는 학생들과 협력하는 방법에 대해 인사이트를 공유하여 다음 세대 개발자 양성에 도움을 주고 있습니다.

"Terraform Provider와 client-go 프로젝트에서 협력할 새로운 기여자들을 격려하고 싶습니다."라고 Patrick은 말합니다. "우리 커뮤니티에 더 많은 친근한 얼굴이 필요합니다."

"Patrick은 GitLab 팀과 고객을 지원하는 데 있어 끊임없이 헌신해왔습니다."라고 Patrick을 상으로 지명한 GitLab의 Staff Fullstack Engineer인 [Lee Tickett](https://gitlab.com/leetickett-gitlab)은 말합니다. GitLab의 Senior Backend Engineer인 [Timo Furrer](https://gitlab.com/timofurrer)가 지명을 지원했습니다. "Terraform Provider와 client-go에 대한 일일 기여 외에도," Timo가 덧붙이며, "GitLab Terraform Provider로 가능한 것을 보여줌으로써 GitLab 고객들의 IaC 여정을 직접 지원하고 있습니다."

Patrick은 Kingland의 Enterprise Architect이자 [GitLab Community Core Team](https://about.gitlab.com/community/core-team/)의 멤버입니다. 이는 그의 두 번째 주목할 만한 기여자 상이며, 2023년 1월에 [이전에 GitLab 15.8에서 수상](https://about.gitlab.com/releases/2023/01/22/gitlab-15-8-released/#mvp)한 경력이 있습니다.

지속적인 기여와 GitLab 고객 지원 및 오픈소스 커뮤니티 성장에 헌신해주신 Patrick에게 감사드립니다!

## 주요 기능 {#primary-features}

### GitLab Duo 모델 선택 일반 공급 시작 {#gitlab-duo-model-selection-now-generally-available}

<!-- categories: Model Personalization -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18818)

{{< /details >}}

GitLab Duo 모델 선택이 일반 공급을 시작하여 개발 워크플로우를 지원하는 AI 모델을 선택할 수 있는 더 큰 제어 권한을 조직에 제공합니다.

GitLab.com의 최상위 그룹 소유자와 Self-Managed 및 Dedicated의 관리자는 이제 GitLab 호스팅 AI 게이트웨이를 통해 접근하는 GitLab Duo 기능에 사용할 다양한 GitLab AI 모델 공급자 중에서 특정 모델을 선택할 수 있습니다.

GitLab.com의 여러 네임스페이스에 속한 GitLab 사용자는 이제 모든 개발 환경에서 일관된 AI 모델 기본 설정을 보장하기 위해 기본 네임스페이스를 설정할 수 있습니다. GitLab Duo 모델 선택에 대한 자세한 내용은 [블로그 읽기](https://about.gitlab.com/blog/speed-meets-governance-model-selection-comes-to-gitlab-duo/)를 참조하세요.

### GitLab 지식 그래프 {#gitlab-knowledge-graph}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](https://gitlab-org.gitlab.io/rust/knowledge-graph/) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17514)

{{< /details >}}

GitLab 지식 그래프는 코드베이스 전체에 걸쳐 풍부한 코드 인텔리전스를 제공합니다. 개발자는 더 많은 컨텍스트로 프로젝트를 이해하고 탐색할 수 있으며, 변경 계획, 영향 분석 수행, GitLab Duo AI 에이전트와 협력하여 개발 작업을 가속화하기가 더 쉬워집니다.

GitLab Duo AI 에이전트 플랫폼은 지식 그래프를 활용하여 AI 에이전트의 정확도를 향상시킵니다. 코드베이스 전체에서 파일과 정의를 매핑함으로써, 지식 그래프는 Duo AI 에이전트가 전체 로컬 워크스페이스의 관계를 이해할 수 있도록 향상된 컨텍스트를 제공하며, 복잡한 질문에 대한 더 빠르고 정확한 응답을 가능하게 합니다.

이번 지식 그래프 릴리스는 로컬 코드 인덱싱에 중점을 두고 있으며, CLI가 코드베이스를 RAG용 라이브 내장형 그래프 데이터베이스로 전환합니다. 간단한 한 줄 스크립트로 설치하고, 로컬 리포지토리를 분석하고, MCP를 통해 연결하여 워크스페이스를 쿼리할 수 있습니다.

지식 그래프 프로젝트에 대한 우리의 비전은 두 가지입니다. 개발자들이 현재 로컬로 실행할 수 있는 활기찬 커뮤니티 에디션을 구축하는 것이며, 이는 향후 GitLab.com 및 self-managed 인스턴스 내의 완전히 통합된 지식 그래프 서비스의 기초가 될 것입니다.

이 기능은 베타 상태입니다. [이슈 160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160)에서 피드백을 제공하세요.

### 엔드 사용자 모델 선택 이제 GitLab Duo에서 사용 가능 {#end-user-model-selection-now-available-with-gitlab-duo}

<!-- categories: Model Personalization -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19251)

{{< /details >}}

GitLab.com에서 엔드 사용자용 GitLab Duo 모델 선택이 공개 베타 상태로 제공됩니다. 이제 사용자는 GitLab UI에서 직접 GitLab Duo Agentic Chat에 선호하는 모델을 선택할 수 있으며, 개발자에게 AI 지원 경험에 대한 개인화된 제어 권한을 제공합니다.

GitLab.com의 네임스페이스 소유자가 허용하는 경우, 엔드 사용자는 GitLab Duo Agentic Chat에 사용할 수 있는 GitLab AI 공급자 모델 중에서 선택할 수 있습니다. 네임스페이스 소유자는 네임스페이스 설정을 통해 조직 전체의 모델 기본 설정을 계속 설정하거나 엔드 사용자 모델 선택을 허용할 수 있습니다.

시작하려면 GitLab Duo Agentic Chat에서 모델 드롭다운을 찾아 선호하는 모델을 선택하세요. 모델을 변경하면 새로운 대화가 시작되고, 향후 세션을 위해 기본 설정이 저장됨을 참고하세요.

### CI/CD 작업 토큰은 Git 푸시 요청을 인증할 수 있음 {#cicd-job-tokens-can-authenticate-git-push-requests}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../ci/jobs/ci_job_token.md#allow-git-push-requests-to-your-project-repository) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)

{{< /details >}}

이제 프로젝트에서 생성된 CI/CD 작업 토큰이 프로젝트 리포지토리에 대한 Git 푸시 요청을 인증하도록 허용할 수 있습니다. UI에서 작업 토큰 권한 설정으로 이를 활성화하거나, 또는 프로젝트의 REST API 엔드포인트에서 `[ci_push_repository_for_job_token_allowed](../../api/projects.md#edit-a-project)` 매개변수로 활성화할 수 있습니다.

### GitLab Duo 컨텍스트 제외 {#gitlab-duo-context-exclusion}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/context.md#exclude-context-from-code-review) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17124)

{{< /details >}}

GitLab Duo 컨텍스트 제외를 통해 GitLab Duo의 컨텍스트로 제외되는 프로젝트 콘텐츠를 제어할 수 있습니다. 이는 비밀번호 파일 및 구성 파일과 같은 민감한 정보를 보호하는 데 도움이 됩니다. 개별 파일, 특정 디렉터리, 특정 파일 유형 또는 이들의 조합을 제외할 수 있습니다.

이 기능은 현재 베타 상태입니다. GitLab Duo 컨텍스트 제외에 대한 피드백을 [이슈 566244](https://gitlab.com/gitlab-org/gitlab/-/issues/566244)에서 제공하세요.

### GitLab Dedicated를 위한 확대된 AWS 지역 지원 {#expanded-aws-region-support-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)

{{< /details >}}

GitLab Dedicated는 이제 모든 AWS 지역에서의 배포를 지원하여 기본, 보조 및 백업 배포 위치에 [확대된 지역 목록](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)에서 선택할 수 있습니다.

이 확대는 AWS가 모든 지역에 io2 디스크를 배포하여 GitLab Dedicated의 고가용성 및 재해 복구 표준을 충족하므로 가능합니다.

Switchboard에서 GitLab Dedicated 인스턴스를 프로비저닝할 때 새로 사용 가능한 모든 지역을 선택할 수 있습니다.

### 다른 브랜치에 대해 CI/CD 파이프라인 시뮬레이션 {#simulate-cicd-pipelines-against-different-branch}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../ci/pipeline_editor/_index.md#validate-cicd-configuration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)

{{< /details >}}

이전에는 파이프라인 편집기를 사용하여 Validate 탭을 이용해 변경 사항을 검증할 때, 기본 브랜치에 대한 시뮬레이션만 실행할 수 있었습니다. 이번 릴리스에서 이 기능을 확대했습니다. 이제 모든 브랜치를 선택하여 파이프라인을 시뮬레이션할 수 있습니다. 이 개선 사항은 파이프라인을 테스트하고 검증하는 데 더 큰 유연성을 제공합니다. 안정적인 브랜치 또는 기능 브랜치를 포함한 다양한 경우에서 예상대로 수행되는지 확인할 수 있습니다.

## 에이전틱 코어 {#agentic-core}

### 그룹 및 애플리케이션을 위한 자동 Duo 코드 검토 {#automatic-duo-code-review-for-groups-and-applications}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com
- 추가 기능: Duo Enterprise
- 링크: [문서](../../user/project/merge_requests/duo_in_merge_requests.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)

{{< /details >}}

이제 그룹 또는 애플리케이션 설정을 사용하여 여러 프로젝트에 대해 자동 Duo 코드 검토를 활성화할 수 있습니다. 이는 개별 프로젝트를 활성화하는 대신 그룹의 모든 프로젝트에 대해 Duo 코드 검토를 빠르게 활성화하는 데 도움이 될 수 있습니다.

이 기능은 현재 GitLab.com에서 사용 가능하며, 향후 릴리스에서 GitLab Self-Managed에서도 사용 가능하게 할 계획입니다. [이슈 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)에서 피드백을 제공하세요.

### GitLab Duo Self-Hosted를 위한 추가 지원 모델 {#additional-supported-models-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enteprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16742)

{{< /details >}}

GitLab Duo Enterprise를 포함한 GitLab Self-Managed 고객은 이제 GitLab Duo에서 추가 지원 모델을 사용할 수 있습니다. OpenAI GPT-5는 이제 Azure OpenAI에서 지원됩니다. 오픈소스 OpenAI GPT OSS 20B 및 120B도 vLLM 및 Azure OpenAI에서 지원됩니다. GitLab Duo Self-Hosted에서 이러한 모델 사용에 대한 피드백을 남기려면 [이슈 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)을 참조하세요.

### GitLab Duo Self-Hosted의 Duo 코드 검토 일반 공급 시작 {#duo-code-review-on-gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/_index.md#gitlab-duo) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)

{{< /details >}}

GitLab Duo Self-Hosted의 GitLab Duo 코드 검토가 이제 일반 공급을 시작합니다. GitLab Duo Self-Hosted의 코드 검토를 사용하여 데이터 주권을 손상시키지 않으면서 개발 프로세스를 가속화합니다. 코드 검토가 머지 리퀘스트를 검토하면 잠재적인 버그를 식별하고 직접 적용할 수 있는 개선 사항을 제안합니다. 코드 검토를 사용하여 변경 사항을 반복하고 개선한 후 사람이 검토하도록 요청합니다. 이 기능은 Mistral, Meta Llama, Anthropic Claude 및 OpenAI GPT 모델 제품군에 대한 지원을 포함합니다.

코드 검토에 대한 피드백을 [이슈 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)에서 제공하세요.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 시크릿 검색 파이프라인이 기본적으로 특정 파일 및 디렉터리를 제외 {#pipeline-secret-detection-now-excludes-certain-files-and-directories-by-default}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/560147)

{{< /details >}}

시크릿 검색 파이프라인은 이제 자동으로 [특정 파일 유형 및 디렉터리](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items)를 제외하여 스캔 성능을 개선합니다 (시크릿이 포함될 가능성이 낮은 경우). 이 변경 사항은 분석기 [버전 7.11.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.11.0)에서 릴리스됩니다.

### 시크릿 검색 분석기 Git 페칭 개선 사항 {#secret-detection-analyzer-git-fetching-improvements}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/secret_detection/pipeline/_index.md#how-the-analyzer-fetches-commits) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17315)

{{< /details >}}

시크릿 검색 분석기의 [버전 7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.12.0))은 Git 커밋을 페칭하는 방식에 대한 상당한 개선 사항을 추가합니다. 분석기는 이제 `--depth` 및 `--since` 옵션을 `SECRET_DETECTION_LOG_OPTIONS`에서 전달된 것으로 분석하므로, 스캔하려는 커밋의 수를 추가로 지정할 수 있습니다. 분석기는 컨텍스트를 기반으로 적절한 페칭 전략을 선택하여, 얕은 깊이 구성에서도 불필요하게 수백만 개의 커밋이 페칭되는 알려진 이슈를 방지합니다.

이 향상 사항은 작업 시간 초과를 줄이고, 리소스 소비를 감소시키며, 더 예측 가능한 스캔 성능을 제공합니다. 시크릿 검색 스캔 속도를 경험해보세요. 특히 대규모 리포지토리에서 더 빠르고, 실제 페칭 동작과 일치하는 더 명확한 로깅을 제공합니다.

### 상당히 빠른 Advanced SAST 스캔 {#significantly-faster-advanced-sast-scanning}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16561)

{{< /details >}}

머지 리퀘스트와 파이프라인에서 보안 스캔을 활성화할 때 모든 순간이 중요합니다. Advanced SAST에 대한 성능 개선 사항을 정기적으로 배포하여 엔진과 탐지 규칙 모두를 대상으로 합니다.

이번 릴리스에서는 벤치마크 및 실제 테스트에서 스캔 런타임을 최대 78%까지 단축하는 특정 개선 사항을 강조합니다. 스캔 프로세스의 성능에 민감한 부분에 캐싱을 추가하여 대규모 리포지토리에서 스캔 속도가 훨씬 빨라집니다.

이 개선 사항은 Advanced SAST 분석기 버전 2.9.6 이상에서 자동으로 활성화됩니다. [작업 로그 스캔 확인](../../user/application_security/sast/gitlab_advanced_sast.md)을 통해 사용 중인 분석기 버전을 확인할 수 있습니다.

### Operational Container Scanning 심각도 임계값 구성 {#operational-container-scanning-severity-threshold-configuration}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)

{{< /details >}}

이제 Operational Container Scanning (OCS)을 구성하여 특정 심각도 수준 이상의 취약성만 반환할 수 있습니다. 심각도 임계값을 설정한 후, 선택한 심각도 이하의 취약성은 더 이상 취약성 보고서, API 페이로드 및 기타 보고 메커니즘에서 반환되지 않습니다. 이는 해결하려는 취약성에 집중하는 데 도움이 될 수 있습니다.

이 필터링을 활성화하려면 OCS 구성에 [`severity_threshold`를 설정](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter)하세요.

[John Walsh](https://gitlab.com/mjohnw)의 커뮤니티 기여에 감사드립니다. GitLab에 기여하는 방법에 대한 자세한 내용은 [커뮤니티 기여 프로그램](https://about.gitlab.com/community/contribute/)을 확인하세요.

### OpenTofu 모듈 및 공급자를 CI/CD 템플릿을 사용하여 GitLab 컨테이너 레지스트리에 게시 {#publish-opentofu-modules-and-providers-to-the-gitlab-container-registry-with-cicd-templates}

<!-- categories: Infrastructure as Code -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](https://gitlab.com/components/opentofu#publish-providers-to-the-gitlab-oci-registry) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/562715)

{{< /details >}}

GitLab 컨테이너 레지스트리는 이제 OpenTofu 모듈 및 공급자를 호스팅할 미디어 유형을 지원합니다.

CI/CD 구성 요소인 [3.1.0](https://gitlab.com/components/opentofu/-/releases/[3.1.0](https://gitlab.com/components/opentofu/-/releases/3.1.0))의 [OpenTofu CI/CD Component](https://gitlab.com/components/opentofu)는 OCI 형식을 사용하여 OpenTofu 공급자를 GitLab 레지스트리에 배포하는 새로운 `provider-release` 템플릿을 지원합니다. 이제 GitLab에서 직접 OpenTofu 공급자를 호스팅할 수 있습니다.

또한 `module-release` 템플릿은 이제 `type` 입력을 지원하며, `oci`로 설정하여 OCI 형식을 사용하여 GitLab 레지스트리에 OpenTofu 모듈을 배포할 수 있습니다.

### 엔터프라이즈 사용자에게 자리 표시자를 다시 할당할 때 확인 바이패스 {#bypass-confirmation-for-enterprise-users-when-reassigning-placeholders}

<!-- categories: Importers -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/import/mapping/reassignment.md#bypass-confirmation-when-reassigning-placeholder-users) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17871)

{{< /details >}}

그룹의 Owner 역할을 가진 사용자는 이제 해당 그룹의 활성 엔터프라이즈 사용자에게 자리 표시자를 다시 할당할 때 사용자 확인을 바이패스할 수 있습니다. 이렇게 하면 엔터프라이즈 사용자가 재할당을 확인하기 위해 계속 이메일을 확인할 필요가 없습니다. 설정의 시간 제한에 도달한 후, 모든 새로운 재할당에 대해 이메일 확인 요청이 다시 전송됩니다.

엔터프라이즈 사용자는 재할당이 완료된 후에도 여전히 알림 이메일을 받아 프로세스 전체에서 투명성을 보장합니다.

### 이슈 페이지에서 이슈를 보는 방식 구성 {#configure-how-to-view-issues-from-the-issues-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/project/issues/managing_issues.md#open-issues-in-a-panel) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/570776)

{{< /details >}}

이제 목록 페이지 보기를 완전히 제어할 수 있으며, 표시할 메타데이터를 선택하고 작업 항목을 서랍에서 열지 여부를 선택하여 중요한 정보에 더 쉽게 집중할 수 있습니다.

이전에는 모든 메타데이터 필드가 항상 표시되어 작업 항목을 스캔하는 것이 압도적일 수 있었습니다. 이제 담당자, 레이블, 날짜, 마일스톤과 같은 특정 필드를 켜거나 꺼서 보기를 사용자 지정할 수 있습니다.

서랍 보기와 전체 페이지 네비게이션 사이를 전환하는 새로운 토글로 목록의 컨텍스트를 유지하면서 세부 정보를 빠르게 검토하거나, 자세한 편집 및 포괄적인 네비게이션을 위해 더 많은 화면 공간이 필요할 때 전체 페이지를 열 수 있습니다.

### 에픽 및 이슈 목록을 위한 향상된 부모 필터링 {#enhanced-parent-filtering-for-epic-and-issue-lists}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/project/issues/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/556200)

{{< /details >}}

이슈 및 에픽 페이지의 "에픽" 필터를 보다 유연한 "부모" 필터로 바꿨습니다. 이 변경으로 에픽뿐만 아니라 모든 부모 작업 항목으로 필터링할 수 있습니다. 이제 부모 이슈로 필터링하여 자식 작업을 쉽게 찾거나 부모 에픽으로 필터링하여 이슈를 찾을 수 있으며, 이슈 및 에픽 목록 전체에서 작업 계층 구조에 대한 더 나은 가시성을 제공합니다.

### 이슈 보드는 이제 완전한 에픽 계층 구조를 표시 {#issue-boards-now-show-complete-epic-hierarchies}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/project/issue_board.md#filter-issues) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/358416)

{{< /details >}}

이제 이슈 보드에서 부모 에픽으로 필터링할 때 자식 에픽의 모든 이슈를 볼 수 있으며, 이슈 페이지와의 일관성을 제공합니다. 이 개선 사항은 완전한 에픽 계층 구조를 더 잘 추적하고 시각화하는 데 도움이 되며, 자식 에픽에 중첩된 이슈를 놓치지 않아 프로젝트 관리 워크플로우를 더 효율적이고 신뢰할 수 있게 만듭니다.

### 텍스트 편집기 툴바 동등성 {#text-editors-toolbar-parity}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/rich_text_editor.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/507377)

{{< /details >}}

GitLab 일반 텍스트 편집기는 이제 리치 텍스트 편집기와 동일한 형식 지정 옵션을 포함합니다. 일반 텍스트 편집기 툴바가 "추가 옵션" 메뉴로 업데이트되어 다음과 같은 고급 형식 지정 도구에 접근할 수 있습니다:

- 코드 블록
- 세부 정보 블록
- 수평선
- Mermaid 다이어그램
- PlantUML 다이어그램
- 목차

두 편집기 모두 이제 일관된 버튼 배치와 구분 기호를 가지고 있어 편집 모드 간 전환을 더 쉽게 하면서 친숙한 형식 지정 옵션에 대한 접근을 유지합니다.

### 취약성 세부 정보는 자동 해결 파이프라인 ID 표시 {#vulnerability-details-shows-the-auto-resolve-pipeline-id}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/policies/vulnerability_management_policy.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/566392)

{{< /details >}}

자동으로 해결되었다가 나중에 다시 감지된 취약성을 문제 해결할 때, 현재 파이프라인을 취약성이 해결된 파이프라인과 비교하는 것이 도움이 될 수 있습니다.

취약성이 자동으로 해결되면, 취약성 세부 정보 페이지의 취약성 주석에 발생한 파이프라인 ID가 포함됩니다.

### 작업 아티팩트를 다운로드할 수 있는 사용자를 위한 향상된 제어 {#enhanced-controls-for-who-can-download-job-artifacts}

<!-- categories: Artifact Security -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../ci/yaml/_index.md#artifactsaccess) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/454398)

{{< /details >}}

GitLab 16.11에서는 `artifacts:access` 키워드를 추가하여 파이프라인에 접근 가능한 모든 사용자, Developer 역할 이상의 사용자만, 또는 모든 사용자가 아티팩트를 다운로드할 수 있는지를 제어할 수 있습니다.

이번 릴리스에서는 아티팩트를 다운로드할 수 있는 사용자를 Maintainer 역할 이상으로만 제한할 수 있으므로, 작업 아티팩트를 다운로드할 수 있는 사용자를 제어하는 데 하나의 옵션이 더 추가되었습니다.

### GitLab 러너 18.4 {#gitlab-runner-184}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 18.4도 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [FIPS 러너가 GitLab Runner 18.2.1에서 작업 시작 실패](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38963)
- [`chown` 명령어가 사용자 정의 ConfigMap & 보안 컨텍스트 제약 (SCC)이 있는 러너에 대해 OpenShift 4.16.27의 Operator v1.37.0 업그레이드 후 실패](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/246)
- [17.2에서의 조기 제거로 인해 GitLab 17.x.x 릴리스에 `FF_RETRIEVE_POD_WARNING_EVENTS` 복구](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38851)
- [모든 GitLab 러너 작업이 파일 시스템 권한 오류로 인해 실패](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/214)
- [빌드 작업이 권한 거부 오류로 간헐적으로 실패](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37464)
- [GitLab 러너 Helm 차트 업그레이드로 인해 변수가 손상됨](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30851)
- [`FF_USE_FASTZIP`를 활성화하면 fastzip이 활성화되지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28989)
- [GitLab 러너가 일회성 요청으로 생성된 Spot 인스턴스를 중지하려고 할 때 `UnsupportedOperation` 오류 발생](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28865)
- [GitLab 러너의 장기 폴링이 Kubernetes 배포 환경에서 제대로 작동하지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/331460)
- [관리자가 image:Kubernetes:user 값을 재정의하도록 허용](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38894)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.4)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
