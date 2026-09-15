---
stage: Release Notes
group: Monthly Release
date: 2023-05-22
title: "GitLab 16.0 릴리스 정보"
description: "Value Streams Dashboard가 일반 공급되는 GitLab 16.0 릴리스"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 5월 22일에 GitLab 16.0이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Jimmy Berry {#this-months-notable-contributor-jimmy-berry}

Jimmy가 [머지 리퀘스트 보안 위젯을 개선했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117594). 완료된 파이프라인의 머지 리퀘스트에서 브랜치를 비교할 때 사용되는 머지 베이스를 수정했습니다. 이전에는 머지 리퀘스트 보안 위젯이 리포지토리의 메인 브랜치에서 완료된 파이프라인의 가장 최근 보안 스캔을 비교하고 있었습니다. 머지 리퀘스트 보안 위젯의 취약성 결과를 정확하게 하려면 로직을 조정하고 기능이 메인에서 브랜치된 시점의 기능 브랜치를 메인 브랜치와 비교해야 했습니다. 이 변경 없이 사용자가 오해의 소지가 있는 결과를 볼 수 있었습니다. 이는 이미 저희 로드맵에 있는 [이슈](https://gitlab.com/groups/gitlab-org/-/epics/10092)였으며, Jimmy는 이 개선 사항에 기여하고 가속화했을 뿐만 아니라 모든 GitLab 사용자를 위해 기여했습니다.

Jimmy가 [말했습니다](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34100#note_1395183419):

> 다양한 오픈 소스 프로젝트에 기여했지만 이렇게 도움이 되는 검토 프로세스를 경험한 적은 없습니다.

취약성 결과의 로직을 반복하도록 도와주고 GitLab의 보안 기능을 개선해주신 Jimmy, 감사합니다!

## 주요 기능 {#primary-features}

### Value Streams Dashboard가 이제 일반 공급됩니다 {#value-streams-dashboard-is-now-generally-available}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/403304)

{{< /details >}}

이 [새 대시보드](https://youtu.be/EA9Sbks27g4)는 의사 결정자가 소프트웨어 배포를 최적화하기 위해 추세와 패턴을 식별하는 데 도움이 되는 메트릭에 대한 전략적 인사이트를 제공합니다. GitLab Value Streams Dashboard의 첫 번째 반복은 value stream [value stream analytics](../../user/group/value_stream_analytics/_index.md), [DORA4](../../user/analytics/dora_metrics.md)), 및 [취약성](../../user/application_security/vulnerability_report/_index.md) 메트릭을 벤치마킹하여 소프트웨어 배포 워크플로우를 지속적으로 개선할 수 있도록 팀을 지원하는 데 중점을 두고 있습니다.

조직은 [Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md)를 사용하여 일정 기간 동안 이러한 메트릭을 추적하고 비교하고, 하향 추세를 조기에 식별하고, 보안 노출을 파악하고, 개별 프로젝트 또는 메트릭을 드릴다운하여 개선 조치를 취할 수 있습니다.

단일 애플리케이션으로 구축되고 통합된 데이터 저장소를 갖춘 이 포괄적인 뷰를 통해 임원부터 개별 기여자까지 모든 이해관계자가 타사 도구를 구매하거나 유지할 필요 없이 소프트웨어 개발 생명 주기에 대한 가시성을 확보할 수 있습니다.

### Linux에서 GitLab SaaS 러너 업사이징 {#upsizing-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/388162)

{{< /details >}}

요청해주셨고, 저희가 귀 기울었습니다! CI/CD 빌드 속도에서 최고 수준이 되기 위한 노력으로, Linux의 모든 GitLab SaaS 러너에 대해 vCPU 및 RAM을 두 배로 늘렸습니다. [비용 요소](../../ci/pipelines/compute_minutes.md)에 증가는 없습니다.

파이프라인이 더 빠르게 실행되고 생산성이 향상되는 것을 기대합니다.

### Linux에서 GPU 지원 SaaS 러너 {#gpu-enabled-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 링크: [문서](../../ci/runners/hosted_runners/linux.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/358026)

{{< /details >}}

데이터 과학에 DevSecOps의 모범 사례를 제공하기 위해 GitLab 러너 내에서 더 강력한 컴퓨팅 하드웨어를 제공하는 것을 목표로 하고 있습니다. 이전에는 데이터 과학자가 계산 집약적인 워크로드를 가지고 있었으며 그 결과 작업이 GitLab에서 빠르게 실행되지 않을 수 있었습니다.

이제 Linux에서 GPU 지원 SaaS 러너를 사용하면 이러한 워크로드를 GitLab.com을 사용하여 원활하게 지원할 수 있습니다.

왜 기다리나요? 새 러너를 지금 시도해보고 이 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/403008)에서 생각을 알려주세요. 여러분의 피드백을 기다릴 수 없습니다!

### macOS의 Apple silicon(M1) GitLab SaaS 러너 - Beta {#apple-silicon-m1-gitlab-saas-runners-on-macos---beta}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/macos.md#example-gitlab-ciyml-file) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/342848)

{{< /details >}}

모바일 DevOps 팀은 이제 Apple silicon(M1) [macOS의 GitLab SaaS 러너](../../ci/runners/hosted_runners/macos.md)에서 전체 CI/CD 워크플로우를 실행하여 Apple 생태계용 애플리케이션을 원활하게 생성, 테스트 및 배포할 수 있습니다.

호스팅되는 x86-64 macOS 러너의 성능의 최대 **three times**로, GitLab CI/CD와 통합된 안전한 온디맨드 GitLab 러너 빌드 환경에서 macOS가 필요한 애플리케이션을 빌드하고 배포하는 데 개발 팀의 속도를 높입니다.

### 댓글 템플릿 {#comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/profile/comment_templates.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/7565)

{{< /details >}}

이슈, 에픽 또는 머지 리퀘스트에서 댓글을 달 때 자신을 반복하고 동일한 댓글을 계속 작성해야 할 수도 있습니다. 버그 보고에 대해 항상 더 많은 정보를 요청해야 할 수도 있습니다. 트리아지 프로세스의 일부로 빠른 작업을 통해 레이블을 적용할 수도 있습니다. 또는 재미있는 gif나 적절한 이모지로 모든 코드 검토를 마치고 싶을 수도 있습니다. 🎉

댓글 템플릿을 사용하면 저장된 응답을 만들 수 있으며, GitLab 전체의 댓글 상자에 적용하여 워크플로우 속도를 높일 수 있습니다. 댓글 템플릿을 만들려면 **사용자 설정 > 댓글 템플릿**으로 이동한 후 템플릿을 채웁니다. 저장한 후 텍스트 영역의 **댓글 템플릿 삽입** 아이콘을 선택하면 저장된 응답이 적용됩니다.

이는 응답을 표준화하고 시간을 절약하는 좋은 방법입니다!

### GitLab UI에서 포크 업데이트 {#update-your-fork-from-the-gitlab-ui}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/repository/forking_workflow.md#update-your-fork) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/330243)

{{< /details >}}

포크 관리가 훨씬 쉬워졌습니다. 포크가 뒤쳐져 있을 때 GitLab UI에서 **포크 업데이트**를 선택하여 업스트림 변경 사항으로 추적합니다. 포크가 앞서 있을 때 **머지 리퀘스트 생성**을 선택하여 변경 사항을 업스트림 프로젝트에 다시 기여합니다. 두 작업 모두 이전에는 명령줄을 사용해야 했습니다.

포크가 프로젝트의 메인 페이지 및 **리포지토리 > 파일**에서 얼마나 많은 커밋이 앞선지 또는 뒤떨어져 있는지 확인하세요. 머지 충돌이 있으면 UI에서 명령줄에서 Git을 사용하여 해결하는 방법에 대한 지침을 제공합니다.

### 특정 브랜치만 미러 {#mirror-specific-branches-only}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/repository/mirror/_index.md#mirror-specific-branches) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/1893)

{{< /details >}}

많은 브랜치가 있는 바쁜 리포지토리를 미러해야 하지만 일부만 필요한가요? 필요한 브랜치만 일치하는 정규 표현식을 만들어 미러할 브랜치 수를 제한하세요.

이전에는 미러가 전체 리포지토리 또는 모든 보호된 브랜치를 미러하도록 요구했습니다. 이 새로운 유연성은 미러가 푸시하거나 풀하는 데이터 양을 줄일 수 있으며 공개 미러에서 민감한 브랜치를 제외합니다.

### 새 Web IDE 환경이 이제 일반 공급됩니다 {#new-web-ide-experience-now-generally-available}

<!-- categories: Web IDE -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/web_ide/_index.md)

{{< /details >}}

소개 이후 Web IDE의 사용성, 성능 및 안정성을 반복하고 있으며, 이를 통해 원격 개발 워크스페이스 및 코드 제안과 같은 기능을 강력한 기반 위에 구축할 수 있었습니다.

Web IDE 베타에 대해 압도적으로 긍정적인 피드백을 받았으며, GitLab 16.0부터 GitLab 전체에서 기본 다중 파일 코드 편집기로 설정하고 있습니다.

### 공개 프로젝트에 대해 워크스페이스를 베타로 사용 가능 {#workspaces-available-in-beta-for-public-projects}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10122)

{{< /details >}}

로컬 개발 환경 및 이해할 수 없는 패키지 설치 오류를 해결하는 데 몇 시간 또는 심지어 며칠을 소비하는 것을 중단하세요. 이제 일관되고 안정적이며 안전한 개발 환경을 코드로 정의하고 온디맨드로 만들 수 있으며, 모두 워크스페이스 내에서 가능합니다.

워크스페이스는 클라우드의 개인 임시 개발 환경으로 제공됩니다. 로컬 개발 환경의 필요성을 제거함으로써 코드에 더 집중하고 종속성에 덜 신경 쓸 수 있습니다. 새 프로젝트에 온보딩하는 프로세스를 가속화하고 며칠 대신 몇 분 내에 실행 및 실행할 수 있습니다.

GitLab Agent for Kubernetes를 구성하고 선택한 자체 호스팅 클러스터 또는 클라우드 플랫폼에서 [종속성을 설치한](../../user/workspace/_index.md) 후 `.devfile.yaml` 파일에서 개발 환경을 정의하고 공개 프로젝트에 저장할 수 있습니다. 그러면 에이전트에 액세스할 수 있는 개발자는 `.devfile.yaml` 파일을 기반으로 워크스페이스를 만들고 포함된 Web IDE에서 직접 편집할 수 있습니다. 컨테이너에 대한 전체 터미널 액세스 권한이 있으므로 더 효율적으로 작업할 수 있습니다. 작업이 완료되거나 문제가 발생하면 워크스페이스를 종료하고 다음 개발 작업을 위해 새 워크스페이스를 시작할 수 있습니다.

이 짧은 비디오는 현재 베타의 워크스페이스 수명 주기를 안내합니다. [문서](../../user/workspace/_index.md)에서 워크스페이스에 대해 자세히 알아보고 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/410031)에서 생각을 알려주세요.

### SecureFlag를 사용한 보안 교육 {#security-training-with-secureflag}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/vulnerabilities/_index.md#enable-security-training-for-vulnerabilities) \| [관련 이슈](https://gitlab.com/gitlab-com/alliances/alliances/-/issues/297)

{{< /details >}}

보안이 좌측으로 이동함에 따라 지침 없이 보안 결과를 수정하기가 어려울 수 있습니다. 개발자는 취약성을 해결하고 기능을 계속 구축할 수 있도록 실행 가능한 조언이 필요합니다. 탐지된 특정 취약성과 관련된 상황별 교육은 GitLab 14.9에서 릴리스되었습니다.

이 릴리스에서는 취약성의 CWE를 기반으로 SecureFlag와의 통합을 추가하고 있습니다. SecureFlag의 교육 솔루션은 라이브 환경에서 취약성을 수정하고 실제 환경으로 전송할 수 있는 랩을 포함한다는 점에서 고유합니다.

### 토큰 회전 API {#token-rotation-api}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../security/tokens/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)

{{< /details >}}

이전에는 토큰을 회전하기 위해 토큰 소유자가 수동으로 새 토큰을 만들고 기존 토큰을 교체해야 했습니다.

이제 토큰 소유자는 `:rotate` API 엔드포인트를 사용하여 개인, 그룹 및 프로젝트 액세스 토큰을 프로그래밍 방식으로 회전할 수 있습니다.

### AI 기반 워크플로우 기능 {#ai-powered-workflow-features}

<!-- categories: Code Suggestions, Duo Agent Platform, SAST -->

{{< details >}}

- 티어: Gold
- 링크: [문서](../../development/ai_features/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/10524)

{{< /details >}}

GitLab은 AI 기반 DevSecOps 플랫폼으로 진화하고 있습니다. 지난 한 달 동안 AI를 활용하여 다양한 GitLab 기능 전체의 효율성과 생산성을 개선하기 위해 10개의 새로운 실험을 도입했습니다.

이러한 AI 기반 워크플로우는 소프트웨어 개발 수명 주기의 모든 단계에서 효율성을 높이고 주기 시간을 단축합니다.

[AI 기반 워크플로우](https://about.gitlab.com/gitlab-duo-agent-platform/)에 대해 자세히 알아보세요

### 코드 제안 개선 {#code-suggestions-improvements}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Gold, Silver, Free
- 링크: [문서](../../user/project/repository/code_suggestions/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

코드 제안은 이제 기능이 베타인 동안 GitLab.com의 모든 사용자에게 무료로 제공됩니다. 팀은 개발하는 동안 코드를 제안하는 생성 AI의 도움으로 효율성을 높일 수 있습니다.

초기 6개 언어에서 13개 언어로 언어 지원을 확장했습니다: C/C++, C#, Go, Java, JavaScript, Python, PHP, Ruby, Rust, Scala, Kotlin 및 TypeScript.

제안의 품질을 개선하기 위해 매주 코드 제안의 기본 AI 모델을 개선하고 있습니다. AI는 비결정적이므로 주마다 동일한 제안을 받지 못할 수 있습니다.

이러한 [개선 사항 및 다음 단계](https://about.gitlab.com/blog/code-suggestions-for-all-during-beta/)에 대해 자세히 알아보세요.

### 오류 추적이 이제 일반 공급됩니다 {#error-tracking-is-now-generally-available}

<!-- categories: Observability -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../operations/error_tracking.md)

{{< /details >}}

개발자가 애플리케이션에서 생성된 오류를 발견하고 볼 수 있는 GitLab 오류 추적이 이제 GitLab.com에서 일반 공급됩니다! GitLab 오류 추적은 코드가 개발되고 빌드되며 배포되고 릴리스되는 동일한 인터페이스에서 직접 오류 정보를 표시하여 효율성과 인식을 높입니다.

이 릴리스에서는 [GitLab 통합 오류 추적](../../operations/error_tracking.md) 및 [Sentry 기반](../../operations/error_tracking.md) 백엔드를 모두 지원합니다.

### 프로젝트 수준 value stream analytics의 사용자 지정 value stream {#custom-value-streams-for-project-level-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/value_stream_analytics/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/382496)

{{< /details >}}

전체 워크스트림의 가시성을 개선하기 위해 프로젝트 수준의 Value Stream Analytics(VSA)에 [Overview stage](../../user/group/value_stream_analytics/_index.md) 및 [사용자 지정 value stream 만들기](../../user/group/value_stream_analytics/_index.md) 옵션을 추가하고 있습니다.

지금까지 이러한 기능은 그룹 수준 VSA에서만 사용할 수 있었습니다.

## 규모 및 배포 {#scale-and-deployments}

### Projects List API의 인증되지 않은 사용자에 대한 속도 제한 {#rate-limit-for-unauthenticated-users-of-the-projects-list-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/settings/rate_limit_on_projects_api.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/388435)

{{< /details >}}

Projects List API의 인증되지 않은 사용자는 앞으로 속도 제한의 대상이 됩니다.

GitLab.com에서 제한은 고유 IP 주소당 10분마다 400개 요청으로 설정됩니다.

자체 관리 GitLab 인스턴스의 사용자는 기본적으로 동일한 속도 제한을 갖지만 관리자는 적절하다고 판단되는 대로 속도 제한을 변경할 수 있습니다. Projects List API에 대해 10분마다 400개 이상의 요청을 해야 하는 사용자는 [GitLab 계정에 가입하도록](https://about.gitlab.com/pricing/) 권장합니다.

### 자체 관리 GitLab이 두 개의 데이터베이스 연결을 사용합니다 {#self-managed-gitlab-uses-two-database-connections}

<!-- categories: Cell -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9627)

{{< /details >}}

16.0부터 GitLab의 자체 관리 설치는 기본적으로 하나 대신 두 개의 데이터베이스 연결을 갖습니다. 이 변경으로 GitLab의 자체 관리 버전이 GitLab.com과 유사하게 작동하며, GitLab의 자체 관리 버전에 대해 [CI 기능을 위한 별도의 데이터베이스](https://gitlab.com/groups/gitlab-org/-/epics/7509)를 활성화하기 위한 한 단계입니다.

이 변경은 Omnibus GitLab, GitLab Helm 차트, GitLab Operator, GitLab Docker 이미지 및 소스에서의 설치 방법에 적용됩니다.

### 팔로워 비활성화 옵션 {#option-to-disable-followers}

<!-- categories: System Access, User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#disable-following-and-being-followed-by-other-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/325558)

{{< /details >}}

사용자 프로필의 원치 않는 팔로워를 방지하고자 하는 사용자의 피드백을 받았습니다. 여러분의 우려를 경청했으므로 이제 사용자 프로필 설정의 기본 설정에서 팔로우를 비활성화할 수 있습니다.

이 기능을 비활성화하면 아무도 사용자를 팔로우할 수 없고 사용자는 누구도 팔로우할 수 없습니다. 기존의 모든 팔로우 및 팔로워 관계가 제거되고 개수가 0으로 설정됩니다.

### 지연된 그룹 및 프로젝트 삭제가 기본값으로 설정됨 {#delayed-group-and-project-deletion-set-as-default}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/gitlab_com/_index.md#delayed-project-deletion) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)

{{< /details >}}

프로젝트 및 그룹의 실수로 인한 삭제를 방지하기 위해 GitLab 16.0부터 지연된 삭제 기능이 모든 GitLab Ultimate 및 Premium 고객에 대해 기본적으로 켜집니다.

자체 관리 사용자는 여전히 1~90일 사이의 삭제 지연 기간을 정의할 수 있으며, SaaS 사용자는 조정할 수 없는 기본 보존 기간 7일을 갖습니다.

Ultimate 및 Premium 그룹의 사용자는 2단계 삭제 프로세스를 통해 그룹 또는 프로젝트 설정에서 그룹 또는 프로젝트를 즉시 삭제할 수 있습니다.

이 변경이 더 안전한 삭제 프로세스에 기여하고 의도하지 않은 삭제를 방지하는 데 도움이 될 것으로 믿습니다. 이슈 [\#396996](https://gitlab.com/gitlab-org/gitlab/-/issues/396996)에서 피드백을 주시기 바랍니다.

### GitLab 차트 개선 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/charts/)

{{< /details >}}

- GitLab 16.0으로의 업데이트는 cert-manager도 버전 1.11.x로 업데이트합니다. 이 cert-manager 업데이트에는 [업그레이드하기 전에 읽어야 하는](https://cert-manager.io/docs/release-notes/release-notes-1.10/#breaking-changes-you-must-read-this-before-you-upgrade) 획기적인 변경사항이 포함됩니다. 이러한 변경사항에는 GitLab의 주요 릴리스 중에 가장 잘 수행된 컨테이너 이름의 변경이 포함됩니다. 업데이트된 기능의 세부 정보를 보려면 [cert-manager 1.11의 릴리스 정보](https://cert-manager.io/docs/release-notes/release-notes-1.11)를 참조하세요.
- PostgreSQL 12는 더 이상 지원되지 않습니다. 최소 필수 버전은 PostgreSQL 13이며, PostgreSQL 14에 대한 지원이 추가됩니다. GitLab의 새 차트 설치에는 기본적으로 PostgreSQL 14가 포함되며, 업그레이드는 [번들된 PostgreSQL 버전을 업그레이드](https://docs.gitlab.com/charts/installation/database_upgrade/)하는 단계를 따라야 합니다.
- GitLab 16.0으로의 업데이트는 Redis 서브차트를 버전 16.13.2(Redis 6.2.7 포함)로 업데이트하는 것을 포함합니다.
- 번들된 Grafana 차트를 제거했습니다. 번들된 Grafana를 사용하는 경우 [Grafana Labs의 최신 차트 버전](https://artifacthub.io/packages/helm/grafana/grafana) 또는 신뢰할 수 있는 공급자의 Grafana Operator로 전환해야 합니다.
- GitLab 16.0에는 [웹서비스 및 Sidekiq의 레지스트리 서비스 세부 정보](https://docs.gitlab.com/charts/charts/globals.html#configure-registry-settings)가 `global.registry.*` 구성에 포함되어 있으므로 값이 둘 다에 있기 때문에 단순화됩니다. 오버라이드를 사용하여 이전 동작을 유지할 수 있습니다.
- [지원되는 최소 Helm 버전](https://docs.gitlab.com/charts/installation/tools.html#helm)은 3.5.2입니다.
- GitLab 러너 기본 버전은 이제 Ubuntu 22.04입니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- PostgreSQL 12는 더 이상 지원되지 않습니다. 최소 필수 버전은 PostgreSQL 13입니다. 패키지된 PostgreSQL 12의 사용자는 GitLab 16.0을 설치하기 전에 [데이터베이스 업그레이드를 수행](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)해야 합니다.
- Omnibus GitLab 도커 이미지의 새로운 기본 OS는 Ubuntu 22.04입니다.
- GitLab 16.0은 Consul 1.9에서 더 이상 사용되지 않는 Consul의 이전 텔레메트리 엔드포인트를 비활성화합니다. 이를 통해 [Consul을 최신 버전으로 업데이트](https://developer.hashicorp.com/consul/docs/v1.12.x/agent/config/config-files#telemetry-parameters)할 수 있습니다.
- GitLab 16.0에는 Red Hat Enterprise Linux(RHEL) 9 및 호환되는 배포판의 패키지가 포함됩니다.
- GitLab 16.0에는 [Mattermost 7.10](https://mattermost.com/) [보안 업데이트](https://mattermost.com/security-updates/)가 포함됩니다. 이전 버전에서의 업그레이드가 권장됩니다.

### Free 사용자가 사용할 수 있는 추가 등록 기능 {#additional-registration-features-available-to-free-users}

<!-- categories: Product Analytics -->

{{< details >}}

- 티어: Free
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/settings/usage_statistics.md#registration-features-program) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10508)

{{< /details >}}

GitLab Enterprise Edition을 실행하는 자체 관리 인스턴스를 보유한 GitLab Free 고객은 이제 [Registration Features](../../administration/settings/usage_statistics.md#registration-features-program) 프로그램에서 5가지 더 많은 유료 기능에 액세스할 수 있습니다:

- [비밀번호 복잡성 정책](../../administration/settings/sign_up_restrictions.md)
- [설명 변경 기록](../../user/discussions/_index.md#view-description-change-history)
- [이슈 보드 구성](../../user/project/issue_board.md#configurable-issue-boards)
- [유지보수 모드](../../administration/maintenance_mode/_index.md)
- [적용 범위 가이드 퍼징 테스트](../../user/application_security/coverage_fuzzing/_index.md)

이러한 기능에 액세스하려면 GitLab에 등록하고 [Service Ping](../../administration/settings/usage_statistics.md#enable-registration-features)을 통해 활동 데이터를 보냅니다.

### 협력자를 가져올 추가 항목으로 {#import-collaborators-as-an-additional-item-to-import}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/import/github.md#select-additional-items-to-import) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)

{{< /details >}}

GitLab 15.10에서 GitHub 프로젝트 가져오기 중에 GitHub 리포지토리 협력자를 GitLab 프로젝트 멤버로 매핑하기 시작했습니다. 이로 인해 혼동이 야기되고 일부 GitHub 협력자가 예기치 않게 추가되고 좌석을 소비했다는 [피드백](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)을 받았습니다.

GitLab 16.0에서는 GitHub 리포지토리 협력자를 [가져올 추가 항목](../../user/project/import/github.md#select-additional-items-to-import) 목록에 추가하여 반복했습니다. 이를 통해 사용자는 이러한 사용자를 가져오지 않고 가져올 경우의 가능한 의미를 이해할 수 있습니다.

이 옵션은 기본적으로 선택됩니다. 선택 상태로 두면 새 사용자가 그룹 또는 네임스페이스의 좌석을 사용하고 [프로젝트 소유자만큼 높은](../../user/project/import/github.md#collaborators-members) 권한을 부여받을 수 있습니다. 직접 협력자만 가져옵니다. 외부 협력자는 절대 가져오지 않습니다.

### 가져올 GitHub 리포지토리 필터링 {#filter-github-repositories-to-import}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/import/github.md#filter-repositories-list) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/385113)

{{< /details >}}

GitHub에서 많은 리포지토리를 소유하거나 협력하는 경우, 현재 필터링 옵션을 사용하여 GitLab으로 가져오려는 리포지토리를 찾는 데 문제가 있을 수 있습니다.

올바른 리포지토리를 더 쉽게 찾기 위해 추가 필터를 추가했습니다. 이제 세 개의 탭을 사용하여 가져올 수 있는 리포지토리의 부분집합을 나열할 수 있습니다:

- **소유자** \- 소유한 리포지토리를 나열합니다.
- **Collaborator** \- 협력하는 리포지토리를 나열합니다.
- **GitHub organization** \- GitHub 조직에 속한 리포지토리를 나열합니다.

**조직** 탭에서 검색을 더 좁혀서 특정 조직을 선택하고 해당 조직에만 속한 리포지토리를 나열할 수 있습니다.

### 다른 그룹 또는 프로젝트 소유자가 완료한 할 일 항목 표시 {#mark-to-do-items-completed-by-other-group-or-project-owners-done}

<!-- categories: Groups & Projects, User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/todos.md#actions-that-mark-a-to-do-item-as-done) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/374726)

{{< /details >}}

사용자가 그룹 또는 프로젝트에 대한 액세스 요청을 제출하면 요청이 그룹 또는 프로젝트 소유자의 할 일 목록에 표시됩니다. 여러 소유자가 있는 그룹 및 프로젝트의 경우 요청이 각 소유자의 할 일 목록에 표시됩니다.

이 새로운 기능을 통해 다른 소유자가 이미 완료한 할 일 항목이 다른 항목의 할 일 목록에서 완료됨으로 표시됩니다.

### 새 탐색 환경에 옵트인 {#opt-in-to-a-new-navigation-experience}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../tutorials/left_sidebar/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9044)

{{< /details >}}

GitLab 16.0은 완전히 새로운 탐색 환경을 갖추고 있습니다! 시작하려면 UI의 오른쪽 상단에 있는 아바타로 이동하여 **New navigation** 토글을 켭니다. 왼쪽 사이드바가 지난 1년간 받은 사용자 피드백을 기반으로 새로운 개선된 디자인으로 변경됩니다.

[이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/409005)에서 경험을 알려주세요. 피드백에 따라 저희는 사용자 기반 전체에서 새 탐색을 점진적으로 활성화할 것이며, 마지막 단계는 이전 탐색을 제거하는 것입니다.

### 사용자의 세션 길이 제한 {#limit-session-length-for-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#session-duration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/30819)

{{< /details >}}

관리자는 사용자가 로그인할 때 "내 정보 기억" 옵션을 제거하여 세션을 연장할 수 없고 사용자가 재인증하도록 강제할 수 있습니다. 세션 지속 시간을 제한하면 인스턴스 보안이 개선될 수 있습니다.

### Jira 개인 액세스 토큰으로 인증 {#authenticate-with-jira-personal-access-tokens}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../integration/jira/configure.md#configure-the-integration) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8222)

{{< /details >}}

이전에는 [Jira 이슈 통합](../../integration/jira/configure.md)만 Jira 사용자 이름과 암호로 인증할 수 있었습니다.

이제 Jira Data Center 및 Jira 8.14 이상을 사용 중인 경우 [Jira 개인 액세스 토큰](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html)을 사용하여 인증할 수 있습니다. Jira 개인 액세스 토큰은 사용자 이름과 암호보다 더 안전한 대안입니다.

### Service Desk 자동화된 응답의 이슈 설명에 대한 자리 표시자 {#placeholder-for-issue-description-in-service-desk-automated-replies}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/service_desk/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/223751)

{{< /details >}}

Service Desk 요청자가 자동 감사의 말 이메일 응답에서 원래 요청을 보는 것이 유용합니다.

이 릴리스에서는 Service Desk 관리자가 감사의 말 이메일에 원래 요청을 포함할 수 있도록 `%{ISSUE_DESCRIPTION}` 자리 표시자를 추가합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 실시간 머지 리퀘스트 업데이트 {#real-time-merge-request-updates}

<!-- categories: Web IDE -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/_index.md)

{{< /details >}}

머지 리퀘스트에서 작업할 때, 승인, 파이프라인 또는 변경을 병합할 수 있는 능력에 영향을 미칠 수 있는 기타 정보에 대한 최신 정보를 보고 있는지 확인하는 것이 중요합니다. 역사적으로 이는 머지 리퀘스트를 새로 고치거나 폴링 업데이트가 들어올 때까지 기다리는 것을 의미했습니다.

머지 리퀘스트 내의 병합 버튼 위젯 및 승인 위젯의 경험을 개선했으므로 이제 머지 리퀘스트에서 실시간으로 업데이트됩니다. 이는 변경을 제공할 수 있는 속도를 개선하고 최신 정보를 보고 있음을 알면서 머지 리퀘스트를 앞으로 이동할 수 있는 자신감을 높이기 위한 훌륭한 개선사항입니다.

머지 리퀘스트에서 [실시간 개선](https://gitlab.com/groups/gitlab-org/-/epics/1812)을 위한 더 많은 영역을 살펴보고 있으므로 업데이트를 계속 지켜봐 주세요.

### 취약성을 일괄 해제할 때 이유 제공 {#provide-a-reason-when-dismissing-vulnerabilities-in-bulk}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/408366)

{{< /details >}}

취약성 보고서에서 하나 이상의 취약성을 선택할 때 상태를 일괄적으로 변경할 수 있습니다.

이 릴리스에서는 해제 상태를 선택할 때 해제 이유를 선택하고 취약성의 상태를 변경할 때 댓글을 추가할 수 있습니다."

### 일괄 작업을 사용하지 않고 규정 준수 프레임워크 추가 및 제거 {#add-and-remove-compliance-frameworks-without-using-bulk-actions}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group)

{{< /details >}}

GitLab 15.11에서 규정 준수 프레임워크 보고서에 규정 준수 프레임워크의 일괄 [추가](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group) 및 [제거](../../user/compliance/compliance_center/compliance_projects_report.md#remove-a-compliance-framework-from-projects-in-a-group)를 추가했습니다.

이제 GitLab 16.0에서는 보고서 테이블 행에서 직접 프로젝트에 대한 규정 준수 프레임워크를 추가하고 제거할 수 있습니다.

GitLab 16.0 이전에는 그룹의 설정에서 프레임워크를 만들고 편집해야 했습니다.

이제 GitLab 16.0에서는 규정 준수 프레임워크 보고서에서 규정 준수 프레임워크를 만들거나 편집할 수 있습니다. 이는 프레임워크 생성 워크플로우를 단순화하고 프레임워크를 관리하는 동안 컨텍스트를 전환할 필요를 줄입니다.

### 대상 브랜치 이름으로 규정 준수 위반 필터링 {#filter-compliance-violations-by-target-branch-name}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_projects_report.md)

{{< /details >}}

GitLab 16.0 이전에는 규정 준수 위반 보고서가 모든 브랜치에서 모든 위반을 표시했습니다.

이제 새로운 **대상 브랜치 검색** 필드를 사용하여 위반을 필터링할 수 있으므로 가장 관심 있는 브랜치에 집중할 수 있습니다.

### 스캔 결과 정책을 위한 역할 기반 승인 작업 지원 {#support-role-based-approval-action-for-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8018)

{{< /details >}}

역할 기반 승인 작업을 사용하면 스캔 결과 정책을 구성하여 소유자, 유지보수자 및 개발자를 포함한 GitLab 지원 역할로부터의 승인을 요구할 수 있습니다.

이는 개별 승인자 또는 정의된 사용자 그룹을 요구하는 것보다 추가 유연성을 제공하므로 특히 대규모 조직 전체에서 GitLab에서 이미 활용 중인 역할을 기반으로 정책을 시행하기가 더 쉬워집니다.

### 브라우저 기반 DAST를 통한 비트 애플리케이션 보안 테스트 도입 {#introducing-out-of-band-application-security-testing-through-browser-based-dast}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/browser/_index.md)

{{< /details >}}

이전에는 GitLab의 DAST 분석기가 활성 확인을 수행하는 동안 콜백 공격을 지원하지 않았습니다. 이는 Out-of-band Application Security Testing(OAST)을 DAST 스캔과 별도로 구성해야 했다는 의미입니다.

이제 [브라우저 기반 DAST 분석기 확장](../../user/application_security/dast/browser/_index.md) 구성을 통해 OAST를 실행하여 콜백 공격을 활성화할 수 있습니다.

이 릴리스에서는 [BAS.latest.GitLab-ci.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/BAS.latest.gitlab-ci.yml) 템플릿을 도입합니다. Breach and Attack Simulation CI/CD 템플릿은 브라우저 기반 DAST 분석기의 작업 구성을 제공하고 컨테이너 간 네트워킹을 활성화하여 CI/CD 파이프라인에 서비스 컨테이너에 대한 확장 DAST 스캔을 추가합니다.

새로운 Breach and Attack Simulation 기능을 개발하기 위해 지속적으로 반복하고 있습니다. 브라우저 기반 DAST에 콜백 공격을 추가하는 것에 대해 [피드백을 듣고 싶습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/404809).

### CI/CD 파이프라인을 사용하여 Maven/Gradle 패키지 가져오기 {#import-mavengradle-packages-by-using-cicd-pipelines}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/package_registry/_index.md#to-import-packages) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/389338)

{{< /details >}}

Maven 또는 Gradle 리포지토리를 GitLab으로 옮기고 싶지만 마이그레이션을 계획할 시간을 투자하지 못했나요? GitLab은 Maven/Gradle 패키지 가져오기의 MVC 출시를 발표하게 되어 자랑스럽습니다.

이제 Packages Importer 도구를 사용하여 Artifactory와 같은 Maven/Gradle 호환 레지스트리에서 패키지를 가져올 수 있습니다.

도구를 사용하려면 GitLab으로 가져오려는 패키지의 세부 정보를 포함하는 `config.yml` 파일을 만듭니다. 그런 다음 가져오기를 `.gitlab-ci.yml` 파이프라인 구성 파일에 추가하면 가져오기가 나머지 작업을 수행합니다. 파이프라인에서 실행되고 모든 패키지를 GitLab 패키지 레지스트리로 가져오는 작업으로 자식 파이프라인을 동적으로 생성합니다.

### Scala를 사용하여 Maven Registry에서 패키지 다운로드 {#download-packages-from-the-maven-registry-with-scala}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/maven_repository/_index.md#install-a-package) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/212854)

{{< /details >}}

GitLab Package Registry는 이제 Scala 빌드 도구(`sbt`)를 사용하여 Maven 패키지를 다운로드하는 것을 지원합니다. 이전에는 Scala 사용자가 기본 인증이 지원되지 않았기 때문에 레지스트리에서 Maven 패키지를 다운로드할 수 없었습니다. 결과적으로 Scala 사용자는 레지스트리 사용이 차단되었거나 Maven(`mvn`) 또는 Gradle을 대신 사용해야 했습니다.

Scala에 대한 지원을 추가하면 더 데이터 집약적인 프로젝트에서 Package Registry를 사용하는 데 도움이 될 것입니다.

`sbt`을 사용한 아티팩트 게시는 아직 지원되지 않지만, 게시 지원 추가에 관심이 있는 경우 [이슈 408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479)를 따를 수 있습니다.

### 작업, OKR에서 할 일 항목 추가 또는 해결 {#add-or-resolve-to-do-items-on-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/todos.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9750)

{{< /details >}}

GitLab [할 일 목록](../../user/todos.md)은 널리 채택되는 기능이지만 작업, OKR에서는 사용할 수 없습니다.

이 릴리스에서는 작업 항목 기록에서 할 일 항목을 토글할 수 있는 기능을 소개합니다.

### GitLab Pages 고유 서브도메인 {#gitlab-pages-unique-subdomains}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9347)

{{< /details >}}

이전 버전의 GitLab에서는 동일한 최상위 그룹 아래의 서로 다른 GitLab Pages 사이트의 쿠키가 GitLab Pages 기본 URL 형식 때문에 동일한 최상위 아래의 다른 프로젝트에 표시되었습니다.

이제 각 GitLab Pages 프로젝트에 고유 서브도메인을 할당하여 사이트를 보호할 수 있습니다.

### 작업, OKR에 이모지 반응 추가 {#add-emoji-reactions-on-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/emoji_reactions.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9987)

{{< /details >}}

이제 작업 항목에 대한 이모지 반응의 추가로 작업, OKR에 기여할 수 있습니다.

이 릴리스 이전에는 이슈, 머지 리퀘스트, 스니펫 및 에픽에만 반응을 추가할 수 있었습니다.

### 빠른 작업에서 작업 항목 유형 변경 {#change-work-item-type-from-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/quick_actions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/385227)

{{< /details >}}

이 추가 빠른 작업을 사용하면 핵심 결과를 목표로 변환할 수 있습니다.

### 레이블에 대한 사용자 지정 색상 선택 {#pick-custom-colors-for-labels}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/project/labels.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/361846)

{{< /details >}}

지금까지 레이블에 대해 고정된 수의 색상만 지정할 수 있었습니다.

이 릴리스는 레이블 관리에 색상 선택기를 도입하여 레이블의 색상 범위를 선택할 수 있습니다.

### 작업, OKR에 대한 자식 기록 재정렬 {#reorder-child-records-for-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/okrs.md#reorder-objective-and-key-result-children) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9548)

{{< /details >}}

[작업](../../user/tasks.md) 또는 OKR의 사용자라면 위젯 내에서 자식 기록을 재정렬할 수 있기를 여러 번 바랐을 것입니다!

이 작업을 통해 사용자는 이제 작업 항목 위젯 내에서 자식 기록을 재정렬할 수 있으므로 상대적 우선 순위를 나타내거나 다음 항목을 신호할 수 있습니다.

### 사용자 지정 Value Stream Analytics를 위한 새 단계 이벤트 {#new-stage-events-for-custom-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/value_stream_analytics/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/361983)

{{< /details >}}

Value Stream Analytics는 두 가지 새로운 단계 이벤트로 확장되었습니다. 이슈 처음 할당 및 머지 리퀘스트 처음 할당. 이러한 이벤트는 항목이 사용자에게 처음 할당될 때까지의 시간을 측정하는 데 유용할 수 있습니다.

이 기능을 구현하기 위해 GitLab은 GitLab 16.0에서 할당 이벤트의 기록 저장을 시작했습니다. 이는 GitLab 16.0 이전의 이슈 및 MR 할당 이벤트를 사용할 수 없음을 의미합니다.

### 배포 동결이 활성일 때 메시지 표시 {#display-message-when-deploy-freeze-is-active}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/212460)

{{< /details >}}

GitLab은 이제 배포 동결이 진행 중일 때 Environments 페이지에 메시지를 표시합니다. 이는 팀이 동결이 발생하는 시기 및 배포가 허용되지 않는 시기를 인식하도록 하는 데 도움이 됩니다.

### SAST 분석기 업데이트 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/analyzers.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST는 [많은 보안 분석기](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)를 포함하며, GitLab Static Analysis 팀은 적극적으로 유지보수하고 업데이트하며 지원합니다. 16.0 릴리스 마일스톤 중에 다음 업데이트를 게시했습니다:

- Semgrep 기반 분석기는 업데이트된 [GitLab 관리 스캔 규칙](https://gitlab.com/gitlab-org/security-products/sast-rules)을 포함합니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v423)를 참조하세요. 규칙을 다음과 같이 업데이트했습니다:
  - OWASP 매핑을 업데이트하여 2017년 OWASP Top Ten을 기반으로 함을 표시합니다. [`@artem-fedorov`](https://gitlab.com/artem-fedorov)에게 감사합니다. 이는 [커뮤니티 기여](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196)입니다.
  - `PyYAML.load` 규칙의 추가 경우를 처리합니다. [`@stevep-arm`](https://gitlab.com/stevep-arm)에게 감사합니다. 이는 [커뮤니티 기여](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/237)입니다.
  - GitLab Vulnerability Research 팀의 수정사항을 기반으로 C 규칙의 설명과 지침을 상당히 개선합니다.
  - [Scala 코드 스캔](https://docs.gitlab.com/#faster-easier-scala-scanning-in-sast)에 대한 지원을 추가합니다.
- Flawfinder 기반 분석기는 이제 [`--neverignore` 플래그 전달](../../user/application_security/sast/_index.md#security-scanner-configuration)을 지원하여 주석의 "무시" 지시문을 무시합니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/blob/master/CHANGELOG.md#v401)를 참조하세요.
- KICS 기반 분석기가 KICS 버전 1.7.0으로 업데이트됩니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401)를 참조하세요.
- MobSF 기반 분석기는 이제 여러 모듈 및 프로젝트를 지원하므로 여러 버그 보고서가 해결됩니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401)를 참조하세요.

또한 [이전에 발표된 대로](../../update/deprecations.md#secure-analyzers-major-version-update), GitLab 16.0의 일부로 각 분석기의 주요 버전 번호를 증가시켰습니다.

[GitLab 관리 SAST 템플릿을 포함](../../user/application_security/sast/_index.md)하고([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/sast/_index.md)할 수 있습니다.

이전 변경사항은 [지난 달 업데이트](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates)를 참조하세요.

### Secret Detection 업데이트 {#secret-detection-updates}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/_index.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab Secret Detection 분석기에 대한 업데이트를 정기적으로 릴리스합니다. GitLab 16.0 마일스톤 중에 다음을 수행했습니다:

- 다음에 대해 [GitLab 관리 검탐 규칙](../../user/application_security/secret_detection/_index.md)을 추가했습니다:
  - Meta, Oculus 및 Instagram API의 액세스 토큰.
  - Segment Public API의 토큰.
- Gitleaks 스캔 엔진을 버전 8.16.3으로 업데이트했습니다.
- [버그 수정](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/merge_requests/212)으로 리포지토리에 단일 커밋만 있을 때 스캔을 방지했습니다.
- 분석기 주요 버전을 `5`로 증가했으며 [이전에 발표된 대로](../../update/deprecations.md#secure-analyzers-major-version-update)입니다.

자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v501)를 참조하세요.

[GitLab 관리 Secret Detection 템플릿을 사용](../../user/application_security/secret_detection/_index.md)하고([`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/secret_detection/_index.md)할 수 있습니다.

이전 변경사항은 [지난 달 업데이트](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates)를 참조하세요.

### 브라우저 기반 DAST 성능 개선 {#browser-based-dast-performance-improvements}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/browser/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

브라우저 기반 DAST 분석기가 스캔을 수행하는 방식을 최적화했습니다. 이러한 개선사항은 브라우저 기반 분석기로 DAST 스캔을 실행하는 데 걸리는 시간을 크게 줄였습니다. 다음 개선사항이 이루어졌습니다:

- 스캔 중에 시간이 소비되는 위치를 확인하는 데 도움이 되는 로그 요약 통계를 추가했습니다. 이는 환경 변수 `DAST_BROWSER_LOG="stat:debug"`을 포함하여 활성화할 수 있습니다.
- 패시브 확인을 병렬로 실행하여 최적화했습니다.
- HTTP 응답 본문의 콘텐츠를 일치시킬 때 사용하는 정규 표현식을 캐싱하여 패시브 확인을 최적화했습니다.
- DAST가 페이지 로딩을 마쳤는지 여부를 결정하는 방식을 최적화했습니다. 이제 제외된 문서 유형 또는 범위 외 URL을 기다리지 않습니다.
- DOM이 페이지 로드 후 빠르게 안정화되는 페이지의 대기 시간이 줄어들었습니다.

이러한 개선사항으로 스캔되는 애플리케이션의 복잡성과 크기에 따라 브라우저 기반 DAST 스캔 시간이 50%-80% 감소했습니다. 이 백분율 감소가 모든 스캔에서 보일 수는 없지만 브라우저 기반 DAST 스캔을 훨씬 더 빠르게 완료할 수 있어야 합니다.

### SAST에서 더 빠르고 쉬운 Scala 스캔 {#faster-easier-scala-scanning-in-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

GitLab Static Application Security Testing(SAST)은 이제 Scala 코드에 대한 Semgrep 기반 스캔을 제공합니다. 이 작업은 [GitLab 14.10](https://about.gitlab.com/releases/2022/04/22/gitlab-14-10-released/#faster-easier-java-scanning-in-sast)에서의 Semgrep 기반 Java 스캔 소개를 기반으로 합니다. [Semgrep 기반 스캔으로 전환](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning)한 다른 언어와 마찬가지로, Scala 스캔 범위는 GitLab 관리 검탐 규칙을 사용하여 다양한 보안 이슈를 검탐합니다.

새로운 Semgrep 기반 스캔은 SpotBugs 기반의 기존 분석기보다 훨씬 빠르게 실행됩니다. 또한 스캔하기 전에 코드를 컴파일할 필요가 없으므로 더 간단하게 사용할 수 있습니다.

GitLab의 Static Analysis 및 Vulnerability Research 팀이 함께 작업하여 규칙을 Semgrep 형식으로 번역하고 기존 규칙의 대부분을 보존했습니다. 또한 규칙을 변환할 때 규칙을 업데이트하고, 개선하고, 테스트했습니다.

[GitLab 관리 SAST 템플릿](../../user/application_security/sast/_index.md)을 사용하는 경우([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)), Scala 코드가 발견될 때마다 Semgrep 기반 및 SpotBugs 기반 분석기가 모두 실행됩니다. GitLab Ultimate에서는 Security Dashboard가 두 분석기의 결과를 결합하므로 중복 취약성 보고서가 표시되지 않습니다.

향후 릴리스에서는 [GitLab 관리 SAST 템플릿](../../user/application_security/sast/_index.md)([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml))을 변경하여 Scala 코드에 대해서만 Semgrep 기반 분석기를 실행합니다. SpotBugs 기반 분석기는 계속해서 Groovy 및 Kotlin을 포함한 다른 언어의 코드를 스캔합니다. Semgrep 기반 스캔만 사용하려는 경우 [SpotBugs를 조기에 비활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)할 수 있습니다.

새로운 Semgrep 기반 Scala 스캔에 대해 질문, 피드백 또는 이슈가 있는 경우 [이슈를 작성](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Bug&add_related_issue=362958&issue[title]=Feedback%20on%20SAST%20Semgrep%20Scala%20support&issue[description]=%2Flabel%20~%22group%3A%3Astatic%20analysis%22)하세요. 기꺼이 도와드리겠습니다.

### Admin Area에서 사용자로 인스턴스 러너 만들기 {#create-an-instance-runner-in-the-admin-area-as-a-user}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/runner/register/) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/383139/)

{{< /details >}}

이 새로운 워크플로우에서 GitLab 인스턴스에 새 러너를 추가하려면 승인된 사용자가 GitLab UI에서 러너를 생성하고 필수 구성 메타데이터를 포함해야 합니다. 이 방법을 사용하면 러너를 쉽게 사용자에게 추적할 수 있으므로 관리자가 빌드 이슈를 해결하거나 보안 사고에 대응할 수 있습니다.

### 취소되면 다운스트림 파이프라인의 트리거 작업 미러 상태 {#trigger-job-mirror-status-of-downstream-pipeline-when-cancelled}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#triggerstrategy) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/220794)

{{< /details >}}

이전에는 `strategy: depends`으로 구성된 트리거 작업이 다운스트림 파이프라인의 작업 상태를 미러링했습니다. 다운스트림 파이프라인이 `running` 상태에 있으면 트리거 작업도 `running`로 표시되었습니다. 안타깝게도 다운스트림 작업이 완료되지 않고 상태 `canceled`를 가진 경우 트리거 작업의 상태는 부정확하게 `failed`입니다.

이 릴리스에서는 `strategy: depend`를 사용하는 트리거 작업을 업데이트하여 다운스트림의 파이프라인 상태를 정확하게 반영했습니다. 다운스트림 파이프라인이 취소되면 트리거도 취소됨을 표시합니다.

이 변경은 기존 파이프라인에 영향을 미칠 수 있으며, 특히 트리거 작업의 상태가 실패로 표시되는 것에 의존하는 작업이 있는 경우입니다. 파이프라인 구성을 검토하고 이 동작 변경을 수용하기 위해 필요한 조정을 하는 것이 좋습니다.

### CI/CD 구성 요소 {#cicd-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../ci/components/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

이 릴리스에서는 실험 기능으로 CI/CD 구성 요소의 가용성을 발표하게 되어 기쁩니다. CI/CD 구성 요소는 프로젝트의 CI/CD 구성의 일부 또는 전체 파이프라인을 구성하는 데 사용할 수 있는 재사용 가능한 단일 목적 구성 요소입니다.

[`inputs`](../../ci/yaml/includes.md) 키워드와 결합하면 CI/CD 구성 요소를 훨씬 더 유연하게 만들 수 있습니다. 작업 이름, 변수, 자격 증명 등에 사용할 수 있는 값을 입력하여 구성 요소를 정확한 요구사항에 맞게 구성할 수 있습니다.

### 러너를 생성하기 위한 REST API 엔드포인트 {#rest-api-endpoint-to-create-a-runner}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../api/users.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/390427)

{{< /details >}}

사용자는 이제 새로운 REST API 엔드포인트인 `POST /user/runners`을 사용하여 사용자와 연결된 러너 만들기를 자동화할 수 있습니다. 러너를 생성하면 인증 토큰이 생성됩니다. 이 새로운 엔드포인트는 Next GitLab Runner Token Architecture 워크플로우를 지원합니다.

### CI/CD 파이프라인에서 캐시별 대체 캐시 키 {#per-cache-fallback-cache-keys-in-cicd-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/caching/_index.md#per-cache-fallback-keys) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/22213)

{{< /details >}}

캐시를 사용하는 것은 이전 작업 또는 파이프라인에서 이미 가져온 종속성을 재사용하여 파이프라인 속도를 높이는 좋은 방법입니다. 하지만 아직 캐시가 없으면 작업이 처음부터 시작해야 하고 모든 종속성을 가져와야 하기 때문에 캐싱의 이점이 손실됩니다.

이전에 캐시를 찾을 수 없을 때 사용할 수 있는 단일 대체 캐시를 도입했으며, 이를 전역으로 정의할 수 있습니다. 이는 모든 작업에 유사한 캐시를 사용하는 프로젝트에 유용했습니다. 이제 16.0에서는 캐시별 대체 키로 해당 기능을 개선했습니다. 모든 작업의 캐시에 대해 최대 5개의 대체 키를 정의할 수 있으므로 작업이 유용한 캐시 없이 실행될 위험이 크게 줄어듭니다. 캐시가 다양한 경우 필요에 따라 적절한 대체 캐시를 사용할 수 있습니다.

### 사용자로 그룹 러너 만들기 {#create-a-group-runner-as-a-user}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/383143/)

{{< /details >}}

이 새로운 워크플로우에서 GitLab 그룹에 새 러너를 추가하려면 승인된 사용자가 GitLab UI에서 러너를 생성하고 필수 구성 메타데이터를 포함해야 합니다. 이 방법을 사용하면 러너를 쉽게 사용자에게 추적할 수 있으므로 관리자가 빌드 이슈를 해결하거나 보안 사고에 대응할 수 있습니다.

### 포함된 CI/CD 구성 파일의 구성 가능한 최대 수 {#configurable-maximum-number-of-included-cicd-configuration-files}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/continuous_integration.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)

{{< /details >}}

`include` 키워드를 사용하면 여러 파일에서 CI/CD 구성을 구성할 수 있습니다. 예를 들어, 하나의 긴 `.gitlab-ci.yml` 파일을 여러 파일로 분할하여 가독성을 높이거나 여러 프로젝트에서 하나의 CI/CD 구성 파일을 재사용할 수 있습니다.

이전에는 단일 CI/CD 구성이 최대 150개 파일을 포함할 수 있었지만, GitLab 16.0에서는 관리자가 인스턴스 설정에서 이 제한을 다른 값으로 수정할 수 있습니다.

### 사용자로 프로젝트 러너 만들기 {#create-project-runners-as-a-user}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/383144)

{{< /details >}}

이 새로운 워크플로우에서 프로젝트에 새 러너를 추가하려면 승인된 사용자가 GitLab UI에서 러너를 생성하고 필수 구성 메타데이터를 포함해야 합니다.

이 방법을 사용하면 러너를 쉽게 사용자에게 추적할 수 있으므로 관리자가 빌드 이슈를 해결하거나 보안 사고에 대응할 수 있습니다.

### `projects/:id/jobs` API 엔드포인트의 속도 제한 감소 {#rate-limit-for-the-projectsidjobs-api-endpoint-reduced}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../security/rate_limits.md#project-jobs-api-endpoint) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)

{{< /details >}}

이전에는 `GET /api/:version/projects/:id/jobs`이 분당 2000개의 인증된 요청으로 제한되었습니다.

다른 속도 제한과 일치시키고 효율성과 안정성을 향상시키기 위해 제한을 분당 600개의 인증된 요청으로 낮추었습니다.

### GitLab Runner 16.0 {#gitlab-runner-160}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

또한 오늘 GitLab Runner 16.0을 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [Google Compute Engine용 GitLab Runner 자동 크기 조정 플러그인 - 실험](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29217)

모든 변경사항의 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-0-stable/CHANGELOG.md)에 있습니다

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.0)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
