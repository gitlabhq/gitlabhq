---
stage: Release Notes
group: Monthly Release
date: 2023-07-22
title: "GitLab 16.2 릴리스 정보"
description: "GitLab 16.2는 새로운 리치 텍스트 에디터 경험과 함께 릴리스되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 7월 22일, GitLab 16.2가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

Xing Xin은 [격리된 리포지토리를 충돌 감지에 사용](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6008)하는 최근 머지 리퀘스트로 인정받았습니다. GitLab의 시니어 백엔드 엔지니어인 Karthik Nayak이 언급했습니다: GitLab의 시니어 백엔드 엔지니어인 Karthik Nayak이 언급했습니다: "격리된 리포지토리를 사용하면 작업이 중간에 실패할 경우 Git 리포지토리의 오래된 객체를 피할 수 있습니다. Xing은 격리 리포지토리를 도입할 수 있는 RPC를 인식할 수 있었고 피드백에 좋은 포인터로 응답했으며 코드베이스에 대한 좋은 지식으로 우리를 설득할 수 있었습니다."

Xing은 2020년부터 GitLab 및 Gitaly 프로젝트에 기여하고 있습니다. ByteDance의 바이트댄서인 Xing은 또한 Alibaba Cloud와 AntGroup에서 시간을 보내며 코드 호스팅과 엔지니어 효율성에 중점을 두고 있습니다. Xing은 "GitLab 커뮤니티는 코드 관리의 모범 사례와 모든 친절한 검토자의 댓글 모두에 대해 많은 영감을 주었습니다. 커뮤니티와 함께 성장하기를 바랍니다."라고 덧붙였습니다.

Missy Davies는 [GitLab 히어로즈](https://contributors.gitlab.com/docs/previous-heroes) 프로그램의 최신 회원 중 한 명입니다. 그녀는 [최근 여러 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&assignee_username=missy-davies)로 인정받았으며 GitLab 프로젝트 전반에 걸쳐 [파이프라인 실행](https://handbook.gitlab.com/handbook/engineering/development/ops/verify/pipeline-execution/) 및 [환경](https://handbook.gitlab.com/handbook/engineering/development/ops/deploy/environments/) 그룹을 위한 몇 가지 머지 리퀘스트를 포함합니다.

Missy는 GitLab 기여자 커뮤니티의 활동적인 회원이기도 하며 정기적으로 커뮤니티 이벤트, 오피스 아워 및 Discord 서버에 참여합니다. GitLab 커뮤니티 핵심 팀의 회원인 Lee Tickett과 Marco Zille 모두 Missy의 더 넓은 커뮤니티 참여를 강조했습니다. Lee는 Missy가 "우리의 가치를 실현하고 있다"고 덧붙였습니다.

Missy는 GitLab에서 오픈 소스의 세계에 대한 자신의 역할이 점점 커지면서 큰 즐거움을 얻었다고 말했습니다. 그녀는 강한 커뮤니티 의식, 지속적인 학습 기회, 오픈 소스 원칙에 대한 공유된 열정을 소중히 여깁니다. Ruby on Rails 및 Python으로 작업한 경험이 있는 백엔드 개발자로서 Missy는 2022년 이후 영향력 있는 GitLab 기여자였습니다.

이번 릴리스의 모든 커뮤니티 기여자에게 감사합니다 🙌

## 주요 기능 {#primary-features}

### 새로운 리치 텍스트 에디터 경험 {#all-new-rich-text-editor-experience}

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/rich_text_editor.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10378)

{{< /details >}}

GitLab 16.2는 완전히 새로운 리치 텍스트 편집 경험을 제공합니다! 이 새로운 기능은 기존 마크다운 편집 경험의 대안으로 모든 사람이 사용할 수 있습니다.

많은 사람들에게 댓글이나 설명을 위해 일반 텍스트 편집기를 사용하는 것은 협업의 장벽입니다. 이미지 참조의 구문을 기억하거나 긴 표로 작업하는 것은 구문에 상대적으로 능숙한 사람들에게도 지루할 수 있습니다. 리치 텍스트 에디터는 "보이는 것이 얻는 것"의 편집 경험과 다이어그램, 콘텐츠 임베드, 미디어 관리 등과 같은 사용자 지정 편집 인터페이스를 구축할 수 있는 확장 가능한 기반을 제공하여 이러한 장벽을 없애는 것을 목표로 합니다.

리치 텍스트 에디터는 이제 모든 이슈, 에픽 및 머지 리퀘스트에서 사용할 수 있습니다. 우리는 곧 GitLab 전체에서 더 많은 장소에서 이를 사용할 수 있도록 계획하고 있습니다. 우리의 진행 상황을 [여기](https://gitlab.com/groups/gitlab-org/-/epics/10378)에서 따를 수 있습니다.

우리는 새로운 편집 경험을 자랑스러워하며 당신의 생각을 보기를 기대할 수 없습니다. 새로운 리치 텍스트 에디터를 시도하고 [이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416293)에서 당신의 경험에 대해 알려주세요.

### GitLab은 구성 없이 Flux 동기화를 트리거합니다 {#gitlab-triggers-a-flux-synchronization-without-any-configuration}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/gitops.md#immediate-git-repository-reconciliation) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/392852)

{{< /details >}}

기본적으로 Flux는 정기적인 간격으로 Kubernetes 매니페스트를 동기화합니다. 매니페스트가 변경될 때 즉시 조정을 트리거하려면 기본적으로 추가 구성이 필요합니다. GitLab의 Kubernetes 에이전트를 사용하면 매니페스트에 변경 사항을 푸시하고 Flux 동기화를 자동으로 트리거할 수 있습니다.

### Cosign을 이용한 키리스 서명 지원 {#support-for-keyless-signing-with-cosign}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Silver, Gold
- 링크: [문서](../../ci/yaml/signing_examples.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/10254)

{{< /details >}}

서명 키를 적절히 저장, 회전 및 관리하기는 어려울 수 있으며 일반적으로 별도의 키 관리 시스템(KMS)을 관리하는 오버헤드가 필요합니다. GitLab은 이제 Sigstore Cosign 도구와의 기본 통합을 통해 키리스 서명을 지원하며, GitLab CI/CD 파이프라인 내에서 쉽고 편리하며 안전한 서명을 허용합니다. 서명은 수명이 매우 짧은 서명 키를 사용하여 수행됩니다. 키는 파이프라인을 실행한 사용자의 OIDC ID를 사용하여 GitLab 서버에서 얻은 토큰을 통해 생성됩니다. 이 토큰에는 토큰이 CI/CD 파이프라인에 의해 생성되었음을 인증하는 고유한 클레임이 포함됩니다.

빌드 아티팩트, 컨테이너 이미지 및 패키지에 대한 키리스 서명을 사용하기 시작하려면 사용자는 [문서에 표시된 대로](../../ci/yaml/signing_examples.md) CI/CD 파일에 몇 줄만 추가하면 됩니다.

### 명령 팔레트 {#command-palette}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/search/command_palette.md)

{{< /details >}}

고급 사용자라면 키보드를 사용하여 탐색하고 작업을 수행하는 것이 답답할 수 있습니다. 이제 새로운 명령 팔레트가 키보드를 사용하여 더 많은 작업을 수행할 수 있도록 도와줍니다.

명령 팔레트를 활성화하려면 왼쪽 사이드바를 열고 **Search GitLab**(🔍)을 클릭하거나 / 키를 사용하세요.

다음 특수 문자 중 하나를 입력하세요:

- > - 새 개체를 만들거나 메뉴 항목 찾기
- @ - 사용자 검색
- : - 프로젝트 검색
- / - 기본 리포지토리 브랜치에서 프로젝트 파일 검색

### Google AI가 제공하는 GitLab Duo Code Suggestions 개선 사항 {#gitlab-duo-code-suggestions-improvements-powered-by-google-ai}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Gold, Silver, Free
- 링크: [문서](../../user/project/repository/code_suggestions/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

Code Suggestions은 이제 Google Cloud의 사용자 지정 가능한 기초 모델 및 오픈 생성형 AI 인프라를 사용하며, Vertex AI에서 생성형 AI 지원을 포함합니다.

GitLab Code Suggestions는 Google Vertex AI Codey API의 [데이터 거버넌스](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/zero-data-retention) 및 [책임 있는 AI](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/responsible-ai)를 통해 라우팅됩니다. 2023년 7월 22일 현재, Code Suggestions는 현재 열려 있는 파일에 대해 추론하며 2,048개의 토큰과 8,192개 문자 제한의 컨텍스트 윈도우를 가집니다. 이 제한에는 커서 전후의 콘텐츠, 파일 이름 및 확장자 유형이 포함됩니다.

[Google Vertex AI Codey API](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_coding_languages)는 직접 지원합니다: C++, C#, Go, Google SQL, Java, JavaScript, Kotlin, PHP, Python, Ruby, Rust, Scala, Swift, TypeScript. 인프라 파일의 경우 지원: Google Cloud CLI, Kubernetes Resource Model(KRM) 및 Terraform.

우리는 Code Suggestions을 개선하기 위해 지속적으로 반복하고 있습니다. 시도해보고 [피드백을 공유](https://gitlab.com/gitlab-org/gitlab/-/issues/405152)하세요.

### 머신 러닝 모델 실험 추적 {#track-your-machine-learning-model-experiments}

<!-- categories: MLOps -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/project/ml/experiment_tracking/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125758)

{{< /details >}}

데이터 과학자가 작업 러닝(ML) 모델을 만들 때, 모델의 성능을 개선할 수 있도록 다양한 매개변수, 구성 및 기능 엔지니어링을 실험하는 경우가 많습니다. 데이터 과학자는 이 모든 메타데이터 및 관련 아티팩트를 추적하여 나중에 실험을 복제할 수 있어야 합니다. 이 작업은 사소한 것이 아니며 기존 솔루션은 복잡한 설정이 필요합니다.

머신 러닝 모델 실험을 사용하면 데이터 과학자는 매개변수, 메트릭 및 아티팩트를 GitLab에 직접 기록하여 가장 성능이 좋은 모델에 쉽게 액세스할 수 있습니다. 이 기능은 실험입니다.

### Value Streams Dashboard를 위한 새로운 사용자 지정 계층 {#new-customization-layer-for-the-value-streams-dashboard}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/388890)

{{< /details >}}

우리는 대시보드의 데이터와 모양을 더 쉽게 사용자 지정할 수 있도록 [Value Streams Dashboard](https://youtu.be/EA9Sbks27g4)에 새로운 구성 파일을 추가했습니다. 이 파일에서 제목, 설명 및 패널 및 필터 수와 같은 다양한 설정과 매개변수를 정의할 수 있습니다. 파일은 스키마 기반이며 Git와 같은 버전 관리 시스템으로 관리됩니다. 이를 통해 구성 변경의 기록을 추적 및 유지하고, 필요한 경우 이전 버전으로 돌아가고, 팀원들과 효과적으로 협력할 수 있습니다.

새로운 구성에는 메트릭을 레이블로 필터링하는 옵션도 포함됩니다. 관심 분야를 기반으로 [메트릭 비교 패널](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/)을 조정하고, 관련 없는 정보를 필터링하고, 분석 또는 의사 결정 프로세스와 가장 관련이 있는 데이터에 집중할 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### 고급 검색에서 이제 사용할 수 있는 그룹 수준 위키 {#group-level-wiki-now-available-in-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/advanced_search.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/336100)

{{< /details >}}

이번 릴리스를 통해 우리는 [그룹 수준 위키](../../user/project/wiki/group.md)를 포함하도록 고급 검색을 확장했습니다. 사용자는 이제 이러한 위키의 콘텐츠를 이전보다 더 쉽고 빠르게 찾을 수 있습니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- 우리의 Redis 버전은 최신 안정 버전인 [`7.0.12`](https://raw.githubusercontent.com/redis/redis/7.0/00-RELEASENOTES)로 업데이트되었습니다.
- GitLab의 새로운 설치의 경우 이제 [PostgreSQL 14](https://www.postgresql.org/docs/14/release-14.html#id-1.11.6.12.4) 사용을 선택할 수 있습니다.

### GitLab 커밋에서 언급된 Jira 이슈에서 배포 보기 {#view-deployments-from-jira-issues-mentioned-in-gitlab-commits}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)

{{< /details >}}

이전에는 GitLab 배포가 배포와 관련된 브랜치 또는 머지 리퀘스트에 Jira 이슈가 언급되었을 때만 Jira 개발 패널에서 연결되었습니다. 이는 사용자가 머지 리퀘스트에서 배포하도록 요구하기 때문에 사용자에게 불편한 경우가 많으며, 이는 일반적인 워크플로우가 아닙니다.

이번 릴리스를 통해 GitLab 배포는 마지막 성공한 배포 후 브랜치에 이루어진 마지막 5,000개 커밋의 메시지에서 Jira 이슈 언급을 검사합니다. GitLab 배포는 언급된 모든 Jira 이슈와 연결됩니다.

### 미확인 사용자 자동 삭제 {#automatic-deletion-of-unconfirmed-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/moderate_users.md#automatically-delete-unconfirmed-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)

{{< /details >}}

초대장이 잘못된 이메일 주소로 전송되면 확인할 수 없습니다. 이전에는 관리자가 이러한 계정을 수동으로 삭제해야 했습니다. 이제 관리자는 지정된 일수 후 미확인 사용자의 자동 삭제를 활성화할 수 있습니다. 마찬가지로 GitLab.com에서 미확인 계정은 [지정된 일수](../../user/gitlab_com/_index.md) 후에 자동으로 삭제됩니다.

### 피드 토큰의 보안 개선 {#improved-security-for-feed-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../security/tokens/_index.md#feed-token) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/414257)

{{< /details >}}

피드 토큰은 생성된 URL에만 대해 작동함으로써 더욱 안전해졌습니다. 이는 토큰이 유출된 경우 읽을 수 있는 피드의 범위를 좁혀줍니다.

### 자체 관리 GitLab에서 사용 가능한 Slack 앱용 GitLab {#gitlab-for-slack-app-available-on-self-managed-gitlab}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/slack_app.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)

{{< /details >}}

이번 릴리스를 통해 GitLab for Slack 앱이 자체 관리 인스턴스에서 사용 가능합니다. 자체 관리 GitLab에서 [매니페스트 파일](https://api.slack.com/reference/manifests#creating_apps)에서 GitLab for Slack 앱의 복사본을 만들고 해당 복사본을 Slack 워크스페이스에 설치할 수 있습니다. 각 복사본은 개인이며 공개적으로 배포할 수 없습니다.

앱을 만들고 구성하려면 [GitLab for Slack 앱 관리](../../administration/settings/slack_app.md)를 참조하세요.

### 여러 액세스 토큰을 사용하여 GitHub에서 가져오기 속도 향상 {#speed-up-imports-from-github-using-multiple-access-tokens}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/import.md#import-repository-from-github) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/337232)

{{< /details >}}

기본적으로 GitHub importer는 GitHub에서 GitLab으로 프로젝트를 가져올 때 단일 액세스 토큰을 사용합니다. 사용자 계정의 액세스 토큰은 일반적으로 시간당 5000개의 요청으로 속도 제한됩니다. 이는 다음의 경우에 importer의 속도를 크게 줄일 수 있습니다:

- 여러 개의 중소 프로젝트를 가져오기.
- 많은 데이터를 포함한 단일 대규모 프로젝트를 가져오기.

이번 릴리스를 통해 GitHub importer API에 액세스 토큰 목록을 전달하여 API가 속도 제한 시 그들을 순환할 수 있습니다. 여러 액세스 토큰을 사용할 때:

- 토큰은 모두 동일한 속도 제한을 공유하기 때문에 같은 계정에서 올 수 없습니다.
- 토큰은 동일한 권한을 가져야 하며 가져올 리포지토리에 대한 충분한 권한을 가져야 합니다.

### OIDC 공급자와 감시자 역할 동기화 {#sync-auditor-role-with-oidc-provider}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/auth/oidc.md#auditor-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/389321)

{{< /details >}}

이제 OIDC 그룹을 GitLab의 `auditor` 역할로 동기화할 수 있습니다. 이를 통해 OIDC가 용이하게 하는 자동화된 사용자 수명 주기 관리가 `auditor` 역할을 사용할 수 있으며, 이는 이전에 역할 매핑에서 지원되지 않았습니다.

기여해주신 [Marin Hannache](https://gitlab.com/mareo)님 감사합니다!

### 개선된 로그인 및 가입 페이지 {#improved-sign-in-and-sign-up-pages}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/settings/sign_up_restrictions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/385651)

{{< /details >}}

GitLab 로그인 및 가입 페이지가 개선되었습니다:

- 사용자 지정 텍스트가 있을 때 두 개의 열 레이아웃.
- 여러 LDAP이 있는 `Remember me` 체크박스와의 이슈 해결.
- 개선된 다크 모드 경험.
- 더 큰 single sign-on 버튼.
- 페이지 요소를 숨기지 않도록 바닥글을 페이지 하단으로 이동.
- SAML 로그인 페이지에 언어 전환기 추가.
- 등록 체험판 페이지에서 비밀번호 확인 활성화.

### 백업은 프로젝트를 건너뛸 수 있는 기능을 추가합니다 {#backup-adds-the-ability-to-skip-projects}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

기본 제공 백업 및 복원 도구는 특정 리포지토리를 건너뛸 수 있는 기능을 추가합니다. Rake 작업은 이제 새 `SKIP_REPOSITORIES_PATHS` 환경 변수를 사용하여 백업 또는 복원 중에 건너뛸 쉼표로 구분된 그룹 또는 프로젝트 경로 목록을 허용합니다. 이를 통해 예를 들어 시간이 지남에 따라 변경되지 않는 오래된 또는 보관된 프로젝트를 건너뛸 수 있으므로 a) 백업 실행 속도를 높여 시간을 절약하고 b) 이 데이터를 백업 파일에 포함하지 않아 공간을 절약할 수 있습니다. 이 [커뮤니티 기여](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196)를 위해 [Yuri Konotopov](https://gitlab.com/nE0sIghT)님께 감사합니다!

### Geo는 모든 구성 요소에 대한 개별 재동기화 및 재검증 추가 {#geo-add-individual-resync-and-reverification-for-all-components}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/geo/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/364727)

{{< /details >}}

Geo는 [자체 서비스 프레임워크](../../development/geo/framework.md)로 관리되는 모든 구성 요소 유형에 대해 개별 항목을 재동기화하고 재검증할 수 있는 기능을 추가합니다. 이제 UI를 사용하여 Geo로 관리되는 개별 항목에 대해 재동기화 또는 재검증 작업을 강제로 수행할 수 있습니다. 이는 실패한 항목에 대한 재동기화 또는 재검증 작업을 가속화하거나 동기화 또는 검증 오류를 해결하기 위해 변경 사항을 적용한 후에 도움이 될 수 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Git LFS 다운로드 성능 개선 {#improve-git-lfs-download-performance}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../topics/git/lfs/_index.md)

{{< /details >}}

LFS 객체를 [프록시 다운로드가 활성화된](../../administration/object_storage.md#proxy-download) 객체 저장소에 저장하지 않는 인스턴스의 경우 GitLab은 이제 LFS 요청을 대량으로 처리합니다. 이는 많은 수의 LFS 객체를 다운로드하는 성능을 극적으로 개선합니다.

이전에는 LFS 객체를 가져오는 방식으로 인해 GitLab은 사용자 권한을 확인하고 외부에 저장된 객체로 리디렉션하는 매우 작은 요청을 많이 생성했습니다. 이는 상당한 로드를 유발하고 성능을 저하시킬 가능성이 있었습니다. 이 수정으로 우리는 기본 GitLab 인스턴스의 로드를 줄이고 사용자에게 더 빠른 다운로드 경험을 제공했습니다.

### Helm 차트에서 추가 볼륨을 사용하여 Kubernetes용 에이전트 설치 {#install-the-agent-for-kubernetes-using-extra-volumes-in-the-helm-chart}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/install/_index.md#customize-the-helm-installation) \| [관련 이슈](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/33)

{{< /details >}}

Kubernetes 에이전트의 `agentk` 구성 요소에는 GitLab으로 인증하기 위한 토큰이 필요합니다. 이전에는 토큰을 그대로 제공하거나 토큰을 포함하는 Kubernetes 보안 암호에 대한 참조로 제공할 수 있었습니다. 그러나 보안 암호가 이미 볼륨에서 사용 가능한 환경에서 작동할 수 있으며 별도의 보안 암호를 만드는 대신 해당 볼륨을 탑재하는 것을 선호할 수 있습니다. GitLab 16.2부터 GitLab 에이전트 Helm 차트는 [Thomas Spear](https://gitlab.com/tspearconquest)의 커뮤니티 기여 덕분에 이 추가 기능과 함께 제공됩니다.

### 검사 실행 정책 편집기에서 사용자 지정 CI 변수 지원 {#support-for-custom-ci-variables-in-the-scan-execution-policies-editor}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/scan_execution_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9566)

{{< /details >}}

이제 검사 실행 정책 편집기에서 사용자 지정 CI 변수(값 포함)를 정의할 수 있습니다. 정책에 정의된 CI 변수는 정책으로 적용되는 프로젝트에 정의된 일치하는 변수를 재정의합니다. 예를 들어, 정책은 CI 변수 `SAST_EXCLUDED_ANALYZERS`를 `brakeman`로 정의할 수 있습니다. 스캐너가 프로젝트에서 적용될 때, 스캐너는 프로젝트의 CI 구성에 정의된 변수에 관계없이 변수가 `brakeman`로 설정된 상태로 실행됩니다. 각 스캔 유형에 대해 기본 변수의 값을 정의할 수 있으며, 사용자 지정 CI 변수를 위한 사용자 지정 키-값 쌍을 만들 수도 있습니다. 이는 검사 실행 정책을 사용자 지정하는 것을 더 빠르고 쉽게 만듭니다.

### 검사 실행 정책이 개발 프로젝트에서 CI/CD 파이프라인을 활성화할 수 있도록 허용 {#allow-scan-execution-policies-to-enable-cicd-pipelines-in-development-projects}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/scan_execution_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/6880)

{{< /details >}}

이전 GitLab 버전에서는 `.gitlab-ci.yml` 파일이 없거나 AutoDevOps가 비활성화된 프로젝트에서 보안 정책이 적용되지 않았습니다. GitLab 16.2에서는 보안 정책이 `.gitlab-ci.yml` 파일을 포함하지 않는 프로젝트에서 CI/CD 파이프라인을 암시적으로 활성화합니다. 이는 보안 정책의 규정 준수를 보장하는 또 다른 단계이며 빌드가 필요하지 않은 시크릿 검색, 정적 분석 또는 기타 작업을 적용할 수 있습니다.

### 보안 정책에서 "기본" 또는 "보호된" 브랜치 대상화 {#target-default-or-protected-branches-in-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9468)

{{< /details >}}

검사 실행 및 검사 결과 정책은 정책이 적용되는 많은 프로젝트 전반에서 "기본" 브랜치 또는 "보호된 브랜치"인 브랜치에 대한 적용을 범위화할 수 있도록 허용합니다. 정책이 브랜치 이름을 명시적으로 지정하도록 요구하는 대신, 정책을 더 광범위하게 적용할 수 있으며 비정상적인 이름의 브랜치가 규정 준수에서 제외되지 않도록 할 수 있습니다.

브랜치 규칙은 `branch_type` 필드를 사용하여 다양한 보안 정책 규칙 유형에서 구성할 수 있습니다:

- [검사 결과 정책을 위한 Scan_finding 규칙 유형](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type)
- [검사 결과 정책을 위한 License_finding 규칙 유형](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type)
- [검사 실행 정책을 위한 파이프라인 규칙 유형](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type)
- [검사 실행 정책을 위한 일정 규칙 유형](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type)

### Google Cloud Logging으로 감시 이벤트 스트리밍 {#audit-event-streaming-to-google-cloud-logging}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

이제 Google Cloud Logging을 감시 이벤트 스트림의 대상으로 선택할 수 있습니다.

이전에는 Google Cloud Logging이 수락할 요청을 만들기 위해 헤더를 사용해야 했습니다. 이 방법은 오류가 발생하기 쉬웠으며 문제를 해결하기 어려웠습니다.

이제 Google Cloud Logging을 스트림의 대상으로 선택하고 프로젝트 ID, 클라이언트 이메일, 로그 ID 및 개인 키를 제공하여 더 원활한 통합을 허용할 수 있습니다.

### 규정 준수 프레임워크 보고서 내보내기 {#compliance-frameworks-report-export}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_projects_report.md#export-a-report-of-compliance-frameworks-on-projects-in-a-group)

{{< /details >}}

이제 규정 준수 프레임워크 및 관련 프로젝트의 보고서를 CSV 파일로 내보낼 수 있습니다.

그룹 수준의 규정 준수 프레임워크 보고서가 추가되면서 규정 준수 프레임워크가 적용되는 프로젝트를 보고 관리할 수 있었습니다.

새로운 내보내기를 통해 참조용으로 해당 파일의 복사본을 유지할 수 있습니다. 프로젝트 및 규정 준수 프레임워크 관계의 이상적인 상태에 대한 단일 출처로 파일을 유지할 수 있습니다. 또는 GitLab에서 작업하지 않지만 어느 프로젝트가 어느 프레임워크로 태그되어 있는지 보는 데 관심이 있는 조직의 사람들에게 파일을 보낼 수 있습니다.

### 그룹/서브그룹 수준 종속성 목록 {#groupsub-group-level-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_list/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

종속성 목록을 검토할 때 전체 보기를 갖는 것이 중요합니다. 모든 프로젝트에서 종속성을 감시하려는 대규모 조직의 경우 프로젝트 수준에서 종속성을 관리하는 것이 문제가 됩니다. 이번 릴리스를 통해 프로젝트 또는 그룹 수준에서 서브그룹을 포함한 모든 종속성을 볼 수 있습니다. 이 기능은 기능 플래그 `group_level_dependencies` 뒤에서 기본적으로 꺼져 있습니다.

### 보호된 브랜치에 대한 초기 푸시 허용 {#allow-initial-push-to-protected-branches}

<!-- categories: Compliance Management, Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/branches/default.md#protect-initial-default-branches)

{{< /details >}}

GitLab의 이전 버전에서는 기본 브랜치가 완전히 보호될 때 프로젝트 유지 관리자와 소유자만 기본 브랜치에 초기 커밋을 푸시할 수 있었습니다.

이는 새 프로젝트를 만들었지만 기본 브랜치만 존재했기 때문에 초기 커밋을 푸시할 수 없었던 개발자에게 문제를 야기했습니다.

**초기 푸시 후 완전히 보호됨** 설정으로, 개발자는 리포지토리의 기본 브랜치에 초기 커밋을 푸시할 수 있지만 그 후 기본 브랜치에 커밋을 푸시할 수 없습니다. 브랜치가 완전히 보호될 때와 유사하게, 프로젝트 유지 관리자는 항상 기본 브랜치에 푸시할 수 있지만 아무도 강제 푸시할 수 없습니다.

### 인스턴스 수준 스트리밍 감사 이벤트 {#instance-level-streaming-audit-events}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

GitLab 16.1 이전에는 최상위 그룹의 감사 이벤트만 외부 대상으로 스트리밍할 수 있었습니다.

이제 인스턴스 관리자는 인스턴스 수준에서 생성된 감사 이벤트의 스트리밍 대상을 추가할 수 있습니다.

### 스트리밍 감사 이벤트 필터링 UI {#streaming-audit-event-filtering-ui}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

GitLab의 이전 버전에서는 감사 이벤트 스트림에 감사 이벤트 유형 필터를 추가하기 위해 GraphQL API를 사용해야 했습니다.

이제 GitLab UI의 필터 드롭다운을 사용하여 모든 사용 가능한 감사 이벤트 유형을 보고, GitLab의 관련 영역별로 그룹화하고, 스트림에서 보낼 정확한 유형을 검색할 수 있습니다.

이제 더 이상 API를 사용하여 전체 목록을 가져오거나 목록을 수동으로 검색할 필요가 없으므로 감사 이벤트 스트림에 필터링을 추가하는 데 필요한 시간이 크게 줄어듭니다.

### 머지 리퀘스트의 대화형 diff 제안 {#interactive-diff-suggestions-in-merge-requests}

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/project/merge_requests/reviews/suggestions.md#using-the-rich-text-editor) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/406726)

{{< /details >}}

머지 리퀘스트에서 변경 사항을 제안할 때 이제 제안을 더 빠르게 편집할 수 있습니다. 댓글에서 리치 텍스트 편집기로 전환하고 UI를 사용하여 텍스트 줄을 위아래로 이동합니다. 이 변경으로 댓글이 게시될 때 제안이 정확히 어떻게 나타날지 볼 수 있습니다.

리치 텍스트 에디터는 GitLab에서 편집하는 새로운 방법입니다. 머지 리퀘스트에서 사용 가능하지만 이슈 및 에픽의 일반 텍스트 편집기와 함께 사용할 수 있습니다.

우리는 곧 GitLab의 더 많은 영역에서 리치 텍스트 에디터를 사용할 수 있도록 계획하고 있으며 적극적으로 작업하고 있습니다. 우리의 진행 상황을 [여기](https://gitlab.com/groups/gitlab-org/-/epics/10378)에서 따를 수 있습니다.

### CI/CD 파이프라인으로 PyPI 패키지 가져오기 {#import-pypi-packages-with-cicd-pipelines}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/package_registry/_index.md#to-import-packages) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/389339)

{{< /details >}}

PyPI 리포지토리를 GitLab으로 이동하고 싶었지만 마이그레이션에 투자할 시간을 찾을 수 없었습니까? 이번 릴리스에서 GitLab은 PyPI 패키지 importer의 첫 번째 버전을 출시합니다.

이제 Packages Importer 도구를 사용하여 Artifactory와 같은 모든 PyPI 호환 레지스트리에서 패키지를 가져올 수 있습니다.

### 업로드된 디자인의 댓글에 이모지 반응 추가 {#add-emoji-reactions-to-comments-on-uploaded-designs}

<!-- categories: Design Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/emoji_reactions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/29756)

{{< /details >}}

이제 [디자인 관리](../../user/project/issues/design_management.md)의 댓글에 이모지 반응을 추가하여 더 창의적으로 생각을 표현할 수 있습니다. 이 기능은 협업에 재미와 편의성을 더하며, 더 나은 커뮤니케이션을 증진하고 팀이 보다 표현적인 방식으로 빠른 피드백을 제공할 수 있도록 합니다.

### SAST 분석기 업데이트 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/analyzers.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST는 [많은 보안 분석기](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)를 포함하며, GitLab Static Analysis 팀은 적극적으로 유지보수하고 업데이트하며 지원합니다.

16.2 릴리스 마일스톤 동안 우리의 변경 사항은 Semgrep 기반 분석기 및 스캔에 사용하는 GitLab 유지 관리 규칙에 중점을 두었습니다. 우리는 다음과 같은 변경 사항을 릴리스했습니다:

- JavaScript 규칙에 대한 설명 및 지침을 명확히 하였으며, [GitLab 16.1에서 릴리스된 다른 언어의 개선](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#clearer-guidance-and-better-coverage-for-sast-rules)을 기반으로 합니다.
- Java 및 JavaScript의 추가 취약성을 찾기 위해 규칙을 업데이트했습니다.
- 스캔에서 무시되는 파일에 대한 기본 구성을 변경했습니다:
  - `.gitignore` 제외를 제거합니다. 이 커뮤니티 기여를 위해 [`@SimonGurney`](https://gitlab.com/SimonGurney)님께 감사합니다.
  - 로컬에서 정의된 `.semgrepignore` 파일을 준수합니다. 이 커뮤니티 기여를 위해 [`@hmrc.colinameigh`](https://gitlab.com/hmrc.colinameigh)님께 감사합니다.
- Go 메모리 별칭과 관련된 규칙을 개선했습니다. 이 커뮤니티 기여를 위해 [`@tyage`](https://gitlab.com/tyage)님께 감사합니다.
- JavaScript 규칙에 대한 Semgrep 규칙 ID에 추가된 `-1` 접미사를 제거했습니다. 이는 GitLab 16.0에서 관련 없는 변경의 부작용으로 추가되었지만 고객의 기존 `semgrepignore` 댓글에 방해가 되었습니다.

[`semgrep` CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v440) 및 [`sast-rules` CHANGELOG](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blame/main/CHANGELOG.md)를 자세한 내용은 참고하세요. 우리는 [에픽 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)에서 GitLab 관리 규칙 집합의 추가 개선을 추적하고 있습니다.

[GitLab 관리 SAST 템플릿을 포함](../../user/application_security/sast/_index.md)하고([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/sast/_index.md)할 수 있습니다.

이전 변경사항은 [지난 달 업데이트](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#sast-analyzer-updates)를 참조하세요.

### Secret Detection 업데이트 {#secret-detection-updates}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/_index.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab Secret Detection 분석기에 대한 업데이트를 정기적으로 릴리스합니다. GitLab 16.2 마일스톤 동안 우리는:

- 다음에 대해 [GitLab 관리 검탐 규칙](../../user/application_security/secret_detection/_index.md)을 추가했습니다:
  - OpenAI API 키.
  - CircleCI 개인 및 프로젝트 액세스 토큰. 이 커뮤니티 기여를 위해 [`@nathanwfish`](https://gitlab.com/nathanwfish)님께 감사합니다.
- `keywords` 최적화를 사용하는 규칙의 성능을 개선했습니다.
- [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/358073)를 수정했습니다. 여기서 시크릿 검색 결과는 리포지토리의 잘못된 위치에 대한 퍼머링크를 생성했습니다.

자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v514)를 참조하세요.

[GitLab 관리 Secret Detection 템플릿을 사용](../../user/application_security/secret_detection/_index.md)하고([`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/secret_detection/_index.md)할 수 있습니다.

이전 변경 사항은 [가장 최근의 시크릿 검색 업데이트](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#secret-detection-updates)를 참고하세요.

### 종속성 및 라이선스 스캔에서 NuGet v2 지원 {#support-for-nuget-v2-in-dependency-and-license-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/398680)

{{< /details >}}

NuGet `v1` 잠금 파일 외에도 GitLab 종속성 및 라이선스 스캔은 이제 NuGet `v2` 잠금 파일에 정의된 종속성 분석을 지원합니다.

### 개선된 SAST 취약성 추적 {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

GitLab SAST [고급 취약성 추적](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)은 코드가 이동함에 따라 결과를 추적하여 심사를 더 효율적으로 만듭니다. GitLab 16.2에서 두 가지 개선 사항을 릴리스했습니다:

1. 확장된 언어 지원: 고급 취약성 추적이 이제 C#에 대해 활성화됩니다.
1. 더 나은 추적: C, C#, Go, Java, JavaScript 및 Python에서 공백과 댓글을 더 잘 처리하기 위해 추적 알고리즘을 개선했습니다. 또한 특정 Go 함수 추적 이슈를 수정했습니다.

더 많은 언어로의 확장, 더 많은 언어 구성의 더 나은 처리, 그리고 Python 및 Ruby에 대한 개선된 추적을 포함하여 [에픽 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)에서 추가 개선 사항을 추적하고 있습니다.

이 변경 사항은 GitLab SAST의 [업데이트된 버전](https://docs.gitlab.com/#sast-analyzer-updates) [분석기](../../user/application_security/sast/analyzers.md)에 포함됩니다. 프로젝트가 업데이트된 분석기로 스캔된 후 프로젝트의 취약성 결과는 새로운 추적 서명으로 업데이트됩니다. [SAST 분석기를 특정 버전으로 고정](../../user/application_security/sast/_index.md)하지 않은 한 이 업데이트를 받기 위해 조치를 취할 필요가 없습니다.

### CI/CD: 조건부 포함에서 `when: never`에 대한 지원 {#cicd-support-for-when-never-on-conditional-includes}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/includes.md#include-with-rulesif) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)

{{< /details >}}

[`include`](../../ci/yaml/_index.md#include)는 전체 CI/CD 파이프라인을 작성할 때 사용하는 가장 인기 있는 키워드 중 하나입니다. 더 큰 파이프라인을 구축하고 있다면 `include` 키워드를 사용하여 외부 YAML 구성을 파이프라인으로 가져올 것입니다.

이번 릴리스에서 우리는 `when: never`을 사용할 수 있도록 키워드의 기능을 확장하고 있습니다[`rules` with `include`](../../ci/yaml/includes.md#use-rules-with-include)를 사용할 때. 이제 특정 규칙이 만족될 때 외부 CI/CD 구성을 제외할 시기를 결정할 수 있습니다. 이는 선택한 조건을 기반으로 자신을 동적으로 수정할 수 있는 더 나은 능력으로 표준화된 파이프라인을 작성하는 데 도움이 됩니다.

### 모든 티어에서 사용 가능한 Linux의 미디엄 SaaS 러너 {#medium-saas-runners-on-linux-available-to-all-tiers}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/418124)

{{< /details >}}

우리는 이제 4개의 vCPU와 16GB RAM을 가진 미디엄 [Linux의 GitLab SaaS 러너](../../ci/runners/hosted_runners/linux.md)를 모든 티어에서 사용할 수 있도록 만들었습니다.

이전에는 무료 티어의 사용자가 우리의 소형 Linux 러너만 사용할 수 있었으며, 때때로 더 긴 CI/CD 실행 시간을 유발했습니다. 우리는 우리의 무료 사용자가 파이프라인 속도를 가속화하기를 기대합니다.

### GitLab Runner 16.2 {#gitlab-runner-162}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

우리는 또한 오늘 GitLab Runner 16.2를 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [runner Kubernetes executor에서 모든 k8s API 호출 재시도](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4143)

#### 버그 수정 {#bug-fixes}

- [dockerd 또는 다른 프로세스가 백그라운드에서 실행될 때 CI 작업 스크립트가 완료되지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2880)
- [v16.1.0에서 GitLab-runner-helper servercore 이미지 누락](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/33918)
- [오류: 캐시 어댑터를 만들 수 없음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3802)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-2-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.2)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
