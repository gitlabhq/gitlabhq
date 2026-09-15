---
stage: Release Notes
group: Monthly Release
date: 2024-07-18
title: "GitLab 17.2 릴리스 정보"
description: "GitLab 17.2가 Kubernetes 포드 및 컨테이너용 로그 스트리밍과 함께 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 7월 18일에 GitLab 17.2가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Phawin Khongkhasawan {#this-months-notable-contributor-phawin-khongkhasawan}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Phawin Khongkhasawan은 [Jitta](https://www.jitta.com/)의 테크 리드이며 2024년 2월부터 GitLab에 기여하기 시작했습니다. 불과 몇 달 만에 Phawin은 20개 이상의 기여를 병합했으며 그의 기여는 [16.11](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#test-project-hooks-with-the-rest-api), [17.0](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#customize-avatars-for-users), 그리고 [17.1](https://about.gitlab.com/releases/2024/06/20/gitlab-17-1-released/#require-confirmation-for-manual-jobs)에도 소개되었습니다.

Phawin은 먼저 GitLab의 Product Manager인 [Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz)에 의해 [API를 통해 프로젝트 테스트 웹후크 트리거링 허용](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)과 같은 웹후크 관련 기능을 개선한 것으로 추천받았습니다. GitLab 엔지니어 [Marc Shaw](https://gitlab.com/marc_shaw)와 [Jose Ivan Vargas](https://gitlab.com/jivanvl), 그리고 GitLab Product Manager [Rutvik Shah](https://gitlab.com/rutshah)는 Phawin의 협업과 반복에 대한 인내심, 즉 [GitLab의 핵심 가치](https://handbook.gitlab.com/handbook/values/) 중 두 가지를 강조했습니다.

GitLab의 Staff Backend Engineer인 [Patrick Bajao](https://gitlab.com/patrickbajao)는 "[병합된 순서 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) 기능을 완성선까지 밀어붙이는 Phawin의 작업, 인내심, 그리고 끈기에 정말 감사합니다"라고 말합니다. "병합되고 배포되기까지 몇 가지 마일스톤이 필요했지만 그는 포기하지 않았고 계속 우리와 협력했습니다."

새로운 기여자가 즉시 영향을 미치고 GitLab 공동 창작을 도울 수 있는 방법을 보여주신 Phawin에게 큰 감사의 말씀을 드립니다.

## 주요 기능 {#primary-features}

### Kubernetes 포드 및 컨테이너용 로그 스트리밍 {#log-streaming-for-kubernetes-pods-and-containers}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/environments/kubernetes_dashboard.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13793)

{{< /details >}}

GitLab 16.1에서 Kubernetes 포드 목록 및 상세 보기를 소개했습니다. 그러나 워크로드에 대한 심층 분석을 위해서는 여전히 타사 도구를 사용해야 했습니다. 이제 GitLab은 포드 및 컨테이너용 로그 스트리밍 보기를 제공하므로 애플리케이션 배송 도구를 떠나지 않고도 환경 전반에 걸쳐 이슈를 빠르게 확인하고 이슈를 해결할 수 있습니다.

### GitLab Duo는 기본적으로 입력 및 출력 로깅을 비활성화합니다. {#gitlab-duo-disabling-input-and-output-logging-by-default}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: GitLab Duo Pro, GitLab Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/data_usage.md#data-retention) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13401)

{{< /details >}}

GitLab은 이제 기본적으로 GitLab Duo에 대한 AI 입력 및 출력 로깅을 비활성화합니다.

GitLab에서는 고객이 자신의 데이터에 대한 주권을 갖도록 보장하는 것을 목표로 합니다. 이제 입력 및 출력 로깅을 기본적으로 비활성화했으며 GitLab 지원 티켓을 통해 고객의 명시적 동의가 있는 경우에만 입력 및 출력을 기록합니다.

### 머지 리퀘스트를 요청 변경으로 차단 {#block-a-merge-request-by-requesting-changes}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/reviews/_index.md#prevent-merge-when-you-request-changes)

{{< /details >}}

검토를 수행할 때 `approve`, `comment`, 또는 `request changes`을(를) 선택하여 완료할 수 있습니다 ([GitLab 16.9에서 릴리스됨](https://about.gitlab.com/releases/2024/02/15/gitlab-16-9-released/#request-changes-on-merge-requests)). 검토 중에 머지될 때까지 머지 리퀘스트가 병합되는 것을 방지해야 하는 변경 사항을 찾을 수 있으므로 `request changes`로 검토를 완료합니다.

변경을 요청할 때 GitLab은 이제 변경 요청이 해결될 때까지 병합을 방지하는 병합 확인을 추가합니다. 변경 요청은 변경을 요청한 원래 사용자가 머지 리퀘스트를 다시 검토하고 그 후 머지 리퀘스트를 승인할 때 해결할 수 있습니다. 변경을 요청한 사용자가 승인할 수 없는 경우 머지 권한이 있는 누구나 변경 요청을 **우회됨**으로 설정할 수 있으므로 개발을 계속할 수 있습니다.

이 새 기능에 대한 피드백을 [이슈 455339](https://gitlab.com/gitlab-org/gitlab/-/issues/455339)에 남겨주세요.

### 취약성 설명 {#vulnerability-explanation}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/application_security/analyze/duo.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10642)

{{< /details >}}

취약성 설명은 이제 GitLab Duo Chat의 일부이며 일반 공개됩니다. 취약성 설명을 사용하면 모든 SAST 취약성에서 대화를 열어 취약성을 더 잘 이해하고 악용 방법을 확인하며 잠재적 수정을 검토할 수 있습니다.

### OAuth 2.0 기기 인증 부여 지원 {#oauth-20-device-authorization-grant-support}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/oauth2.md#device-authorization-grant-flow) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/332682)

{{< /details >}}

GitLab은 이제 [OAuth 2.0 기기 인증 부여 흐름](https://datatracker.ietf.org/doc/html/rfc8628)을 지원합니다. 이 흐름을 통해 브라우저 상호 작용이 불가능한 입력 제한 기기에서 GitLab 자격 증명을 안전하게 인증할 수 있습니다. 이는 헤드리스 서버 또는 UI가 없거나 제한된 기타 기기에서 GitLab 서비스를 사용하려는 사용자에게 기기 인증 부여 흐름을 이상적으로 만듭니다. 기여해주신 [John Parent](https://kitware.com/)에게 감사드립니다!

### 파이프라인 실행 정책 유형 {#pipeline-execution-policy-type}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/pipeline_execution_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13266)

{{< /details >}}

파이프라인 실행 정책 유형은 사용자가 일반 CI 작업, 스크립트 및 지침의 시행을 지원할 수 있게 하는 새로운 유형의 [보안 정책](../../user/application_security/policies/_index.md)입니다.

파이프라인 실행 정책 유형을 통해 보안 및 규정 준수 팀은 사용자 지정 [GitLab 보안 스캔 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs), [GitLab 또는 파트너 지원 CI 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates), 타사 보안 스캔 템플릿, CI 작업을 통한 사용자 지정 보고 규칙 또는 GitLab CI를 통한 사용자 지정 스크립트/규칙을 시행할 수 있습니다.

파이프라인 실행 정책에는 두 가지 모드가 있습니다: 주입 및 덮어쓰기. *주입* 모드는 작업을 프로젝트의 CI/CD 파이프라인에 주입합니다. *덮어쓰기* 모드는 프로젝트의 CI/CD 파이프라인 구성을 바꿉니다.

모든 GitLab 정책과 마찬가지로 시행은 정책을 작성하고 관리하는 지정된 보안 및 규정 준수 팀 구성원이 중앙에서 관리할 수 있습니다. [첫 번째 파이프라인 실행 정책을 생성하여 시작하는 방법 알아보기](../../user/application_security/policies/pipeline_execution_policies.md)!

### 파이프라인 시크릿 검색에서 사용자 정의 규칙 집합 지원 확대 {#expanded-support-of-custom-rulesets-in-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/336395)

{{< /details >}}

파이프라인 시크릿 검색에서 사용자 정의 규칙 집합 지원을 확대했습니다.

두 가지 새로운 유형의 통과, `git` 및 `url`를 사용하여 원격 규칙 집합을 구성할 수 있습니다. 이는 여러 프로젝트에 걸쳐 규칙 집합 구성을 공유하는 것과 같은 워크플로우를 관리하기가 더 쉬워집니다.

이러한 새로운 유형의 통과 중 하나를 사용하여 기본 구성을 원격 규칙 집합으로 확장할 수도 있습니다.

분석기는 이제 다음을 지원합니다:

- 미리 정의된 규칙을 바꾸기 위해 단일 구성으로 최대 20개의 통과를 연결합니다.
- 통과에 환경 변수 포함.
- 통과를 로드할 때 시간 초과 설정.
- 규칙 집합 구성에서 TOML 구문 검증.

### 워크스페이스에서 사용 가능한 GitLab Duo Chat 및 코드 제안 {#gitlab-duo-chat-and-code-suggestions-available-in-workspaces}

<!-- categories: Workspaces, Duo Chat, Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo/_index.md)

{{< /details >}}

[GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md)과 [코드 제안](../../user/project/repository/code_suggestions/_index.md)을 이제 워크스페이스에서 사용할 수 있습니다! 빠른 답변이나 효율적인 코드 개선을 원하든 Duo Chat과 코드 제안은 생산성을 높이고 워크플로우를 간소화하여 워크스페이스에서 원격 개발을 그 어느 때보다 더 효율적이고 효과적으로 만들도록 설계되었습니다.

## 규모 및 배포 {#scale-and-deployments}

### 그룹 개요의 정렬 및 필터링 개선 {#improved-sorting-and-filtering-in-group-overview}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/_index.md#view-a-group) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437013)

{{< /details >}}

그룹 개요 페이지의 정렬 및 필터링 기능을 업데이트했습니다. 검색 요소는 이제 전체 페이지에 걸쳐 확장되므로 검색 문자열을 더 잘 볼 수 있습니다. 정렬 옵션을 `Name`, `Created date`, `Updated date` 및 `Stars`로 표준화했습니다.

이러한 변경 사항에 대한 피드백을 [이슈 438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322)에서 환영합니다.

### 그룹 API를 사용하여 그룹이 초대된 그룹 나열 {#list-groups-that-a-group-was-invited-to-using-the-groups-api}

<!-- categories: Source Code Management, Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/groups.md#list-shared-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424959)

{{< /details >}}

그룹이 초대된 그룹을 나열하는 새로운 엔드포인트를 그룹 API에 추가했습니다. 이 기능은 [그룹이 초대된 프로젝트를 나열하는 엔드포인트](../../api/groups.md#list-shared-projects)를 보완하므로 이제 그룹이 추가된 모든 그룹과 프로젝트의 완전한 개요를 얻을 수 있습니다. 엔드포인트는 분당 사용자당 60개 요청으로 속도 제한됩니다.

이 커뮤니티 기여에 대해 [@imskr](https://gitlab.com/imskr)에게 감사합니다!

### 한 번에 하나의 토론으로 할 일 항목 해결 {#resolve-to-do-items-one-discussion-at-a-time}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/todos.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/461111)

{{< /details >}}

GitLab 이슈에 대한 토론은 바빠질 수 있습니다. GitLab은 귀하와 관련된 댓글에 대한 할 일 항목을 발생시켜 이러한 대화를 관리하는 데 도움을 주며 이슈에 대해 조치를 취할 때 자동으로 항목을 해결합니다.

이전에는 이슈의 스레드에 대해 조치를 취할 때 여러 다른 스레드에서 언급되었더라도 모든 할 일 항목이 해결되었습니다. 이제 GitLab은 상호 작용한 스레드에 대한 할 일 항목만 해결합니다.

### UI에서 가져온 항목 표시 {#indicate-imported-items-in-ui}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/import/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13825)

{{< /details >}}

[다른 SCM 솔루션](../../user/import/_index.md)에서 GitLab으로 프로젝트를 가져올 수 있습니다. 그러나 프로젝트 항목이 가져왔는지 또는 GitLab 인스턴스에서 생성되었는지 알기 어려웠습니다.

이 릴리스에서는 작성자가 특정 사용자로 식별되는 GitHub, Gitea, Bitbucket Server 및 Bitbucket Cloud에서 가져온 항목에 시각적 표시기를 추가했습니다. 예를 들어 머지 리퀘스트, 이슈 및 메모입니다.

### 삭제된 브랜치는 Jira 개발 패널에서 제거됨 {#deleted-branches-are-removed-from-jira-development-panel}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/jira/development_panel.md#feature-availability) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/351625)

{{< /details >}}

이전에 [Jira용 GitLab Cloud 앱](../../integration/jira/connect-app.md)을 사용할 때 GitLab에서 브랜치를 삭제하면 해당 브랜치는 여전히 Jira 개발 패널에 나타났습니다. 해당 브랜치를 선택하면 GitLab에서 `404` 오류가 발생했습니다.

이 릴리스부터 GitLab에서 삭제된 브랜치는 Jira 개발 패널에서 제거됩니다.

### 명령 팔레트를 사용하여 프로젝트 설정 찾기 {#find-project-settings-by-using-the-command-palette}

<!-- categories: Settings, Global Search -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/command_palette.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/448637)

{{< /details >}}

GitLab은 프로젝트, 그룹, 인스턴스 및 개인적으로 많은 설정을 제공합니다. 찾고 있는 설정을 찾으려면 UI의 여러 다른 영역을 클릭하면서 시간을 보내야 하는 경우가 많습니다.

이 릴리스에서는 이제 명령 팔레트에서 프로젝트 설정을 검색할 수 있습니다. 프로젝트를 방문하고 **Search or go to…**을(를) 선택한 후 `>`로 명령 모드를 입력하고 **보호된 태그**와 같은 설정 섹션의 이름을 입력하여 시도해보세요. 결과를 선택하여 설정 자체로 바로 이동합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 병합 커밋 메시지 생성이 이제 GA {#merge-commit-message-generation-now-ga}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)

{{< /details >}}

커밋 메시지를 작성하는 것은 미래의 사용자들이 코드베이스에 대해 무엇이 변경되었는지, 왜 변경되었는지를 이해하도록 보장하는 중요한 부분입니다. 효과적으로 변경 사항을 전달하고 변경했을 수 있는 모든 것을 고려하는 메시지를 생각해내기는 어렵습니다.

GitLab Duo를 사용한 머지 커밋 생성은 이제 일반 공개되어 모든 머지 리퀘스트가 품질 좋은 커밋 메시지를 갖도록 보장하는 데 도움이 됩니다. 병합하기 전에 병합 위젯에서 **커밋 메시지 수정**을(를) 선택한 다음 **커밋 메시지 생성** 옵션을 사용하여 커밋 메시지를 초안화합니다.

이 새로운 GitLab Duo 기능은 프로젝트의 커밋 히스토리가 미래 개발자를 위한 귀중한 리소스가 되도록 하는 좋은 방법입니다.

### CLI용 GitLab Duo가 이제 GA {#gitlab-duo-for-the-cli-now-ga}

<!-- categories: GitLab CLI -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](https://docs.gitlab.com/cli/)

{{< /details >}}

CLI용 GitLab Duo는 이제 모든 사용자가 일반 공개됩니다. 이제 `ask` GitLab Duo를 통해 필요에 맞는 `git` 명령을 찾는 데 도움을 받을 수 있습니다.

`glab duo ask <git question>`을(를) 사용하여 GitLab Duo가 목표를 달성할 수 있는 형식화된 `git` 명령을 제공하도록 합니다. GitLab CLI는 명령, 동작 방식, 전달되는 모든 플래그에 대한 정보를 포함한 추가 세부 사항을 제공합니다. 그 후 명령을 실행하고 워크플로우에서 직접 출력을 얻을 수 있습니다.

GitLab CLI의 `ask` 명령은 약간의 추가 도움이 필요한 `git` 명령으로 워크플로우를 빠르게 수행하는 좋은 방법입니다.

### LFS용 순수 SSH 전송 프로토콜 {#pure-ssh-transfer-protocol-for-lfs}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/lfs/_index.md#pure-ssh-transfer-protocol) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11872)

{{< /details >}}

2021년 9월에 [`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021)이 HTTP 대신 SSH를 전송 프로토콜로 사용하기 위한 지원을 릴리스했습니다. `git-lfs` 3.0.0 이전에는 HTTP가 유일하게 지원되는 전송 프로토콜이었으므로 GitLab에서 `git-lfs`을(를) 사용할 수 없었습니다. 이 릴리스에서 `git-lfs`에 대한 전송 프로토콜로 SSH over HTTP 지원을 활성화할 수 있는 기능을 제공하게 되어 매우 기쁩니다.

이 기여를 해주신 [Kyle Edwards](https://gitlab.com/KyleFromKitware)와 [Joe Snyder](https://gitlab.com/joe-snyder)에게 감사드립니다!

### 배포 및 보호 환경에 대한 승인이 감사 이벤트를 트리거함 {#deployments-and-approvals-to-protected-environments-trigger-an-audit-event}

<!-- categories: Continuous Delivery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/audit_event_types.md#continuous-delivery) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/456687)

{{< /details >}}

배포 승인과 같은 배포 이벤트의 접근 가능한 기록은 규정 준수 관리에 필수적입니다. 지금까지 GitLab은 배포 관련 감사 이벤트를 제공하지 않았으므로 규정 준수 관리자는 사용자 정의 도구를 사용하거나 GitLab에서 직접 데이터를 검색해야 했습니다. GitLab은 이제 세 가지 감사 이벤트를 제공합니다:

- `deployment_started`은 배포 작업을 시작한 사람과 시작된 시간을 기록합니다.
- `deployment_approved`은 배포 작업을 승인한 사람과 승인된 시간을 기록합니다.
- `deployment_rejected`은 배포 작업을 거부한 사람과 거부된 시간을 기록합니다.

### 하위 그룹 규정 준수 센터에서 프레임워크 할당 {#assigning-frameworks-at-subgroup-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_projects_report.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/469004)

{{< /details >}}

규정 준수 센터는 규정 준수 팀이 규정 준수 표준 준수 보고, 위반 보고 및 그룹에 대한 규정 준수 프레임워크를 관리하기 위한 중앙 위치입니다.

이전에는 규정 준수 센터의 모든 관련 기능이 최상위 그룹에서만 사용 가능했습니다. 이는 하위 그룹의 경우 소유자가 최상위 그룹의 규정 준수 센터에서 제공하는 기능에 접근할 수 없음을 의미했습니다.

이러한 주요 통증 지점을 해결하기 위해 하위 그룹에 대한 규정 준수 프레임워크를 할당 및 할당 해제할 수 있는 기능을 추가했습니다. 이제 그룹 소유자는 이미 사용 가능한 전체 최상위 그룹 수준 규정 준수 센터 대시보드 외에도 하위 그룹 수준에서 규정 준수 태세를 시각화할 수 있습니다.

### "스캔 실행 정책"을 확장하여 각 GitLab 분석기에 대해 `latest` 템플릿을 실행 {#expand-scan-execution-policies-to-run-latest-templates-for-each-gitlab-analyzer}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/scan_execution_policies.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415427)

{{< /details >}}

[스캔 실행 정책](../../user/application_security/policies/scan_execution_policies.md)이 확장되어 정책 규칙을 정의할 때 `default`와 `latest` GitLab 템플릿 중에서 선택할 수 있습니다. `default`는 현재 동작을 반영하지만 지정된 보안 분석기의 최신 템플릿에서만 사용 가능한 기능을 사용하도록 정책을 `latest`로 업데이트할 수 있습니다.

`latest` 템플릿을 활용하면 `latest` 템플릿에서 활성화된 다른 규칙과 함께 머지 리퀘스트 파이프라인에 스캔이 시행되도록 할 수 있습니다. 이전에는 브랜치 파이프라인 또는 지정된 일정으로 제한되었습니다.

참고: 정책을 수정하기 전에 `default`과 `latest` 템플릿 간의 모든 변경 사항을 검토하여 이것이 요구 사항에 맞는지 확인하세요!

### 여러 액세스 토큰이 만료되는 날짜 식별 {#identify-dates-when-multiple-access-tokens-expire}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../security/tokens/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467313)

{{< /details >}}

관리자는 이제 여러 액세스 토큰이 만료되는 날짜를 식별하는 스크립트를 실행할 수 있습니다. 이 스크립트를 [토큰 문제 해결 페이지](../../security/tokens/token_troubleshooting.md)의 다른 스크립트와 함께 사용하여 토큰 순환을 아직 구현하지 않은 경우 만료 날짜가 다가오는 대량의 토큰을 식별하고 확장할 수 있습니다.

### OAuth 인증 화면 개선 {#oauth-authorization-screen-improvements}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/oauth_provider.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/462655)

{{< /details >}}

OAuth 인증 화면은 이제 부여하는 인증을 더 명확하게 설명합니다. 또한 GitLab에서 제공하는 애플리케이션을 위한 "GitLab에서 확인함" 섹션도 포함됩니다. 이전에는 응용 프로그램이 GitLab에서 제공했는지 여부에 관계없이 사용자 환경이 동일했습니다. 이 새로운 기능은 추가 신뢰 계층을 제공합니다.

### 간소화된 인스턴스 관리자 설정 {#streamlined-instance-administrator-setup}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/458985)

{{< /details >}}

새로운 GitLab 설치를 위한 관리자 설정 환경이 간소화되고 더욱 안전해졌습니다. 초기 관리자 루트 이메일 주소가 이제 임의로 설정되며 관리자는 이 이메일 주소를 액세스할 수 있는 계정으로 변경해야 합니다. 이전에는 이 단계가 지연될 수 있었고 관리자는 이메일 주소 변경을 잊을 수 있었습니다.

### Snowflake 데이터 커넥터에 추가된 사용자 API {#user-api-added-to-the-snowflake-data-connector}

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../integration/snowflake.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

GitLab 17.2에서는 Snowflake Marketplace 앱에서 사용할 수 있는 [GitLab 데이터 커넥터](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector)에 [사용자 API](../../api/users.md#list-all-users)에 대한 지원을 추가했습니다. 이제 사용자 API를 사용하여 자체 관리 GitLab 인스턴스에서 Snowflake로 사용자 데이터를 스트리밍할 수 있습니다.

### Google Cloud 통합을 위한 간소화된 설정 {#simplified-setup-for-google-cloud-integration}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../tutorials/set_up_gitlab_google_integration/_index.md#secure-your-usage-with-google-cloud-identity-and-access-management-iam) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/454343)

{{< /details >}}

Google Cloud IAM 통합을 위해 워크로드 자격 증명 페더레이션을 설정할 때 Google Cloud CLI 명령을 이제 기본적으로 사용할 수 있습니다. 이전에는 안내식 설정이 cURL 명령을 통해 다운로드한 스크립트를 사용했습니다. 또한 설정 프로세스를 더 잘 설명하기 위해 도움말 텍스트가 추가되었습니다. 이러한 개선 사항은 그룹 소유자가 Google Cloud IAM 통합을 더 빨리 설정하는 데 도움이 됩니다.

### 위키 페이지 제목 및 경로 필드 분리 {#separate-wiki-page-title-and-path-fields}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)

{{< /details >}}

GitLab 17.2에서는 위키 페이지 제목이 경로와 분리됩니다. 이전 릴리스에서는 페이지 제목이 변경되면 경로도 변경되어 페이지 링크가 끊어질 수 있었습니다. 이제 위키 페이지의 제목이 변경되어도 경로는 변경되지 않습니다. 위키 페이지 경로가 변경되어도 자동 리디렉션이 설정되어 손상된 링크를 방지합니다.

### 위키 사이드바 개선 {#improvements-to-the-wiki-sidebar}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/281570)

{{< /details >}}

GitLab 17.2는 위키가 사이드바를 표시하는 방식에 여러 가지 개선 사항을 추가합니다. 이제 위키는 사이드바에 모든 페이지(최대 5000개)를 표시하고, 목차(TOC)를 표시하며, 페이지를 빠르게 찾을 수 있는 검색 표시줄을 제공합니다.

이전에는 사이드바에 TOC가 없어 페이지의 섹션으로 이동하기가 어려웠습니다. 새로운 TOC 기능은 페이지 구조를 명확하게 보고 다양한 섹션으로 빠르게 이동하여 사용성을 크게 향상시키는 데 도움이 됩니다.

검색 표시줄을 추가하면 콘텐츠 발견이 더 쉬워집니다. 그리고 사이드바가 이제 모든 페이지를 표시하므로 전체 위키를 원활하게 탐색할 수 있습니다.

### Terraform 모듈 레지스트리의 문서 모듈 {#document-modules-in-the-terraform-module-registry}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/packages/terraform_module_registry/_index.md#view-terraform-modules) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

Terraform 모듈 레지스트리가 이제 Readme 파일을 표시합니다! 이 매우 요청된 기능으로 각 모듈의 목적, 구성 및 요구 사항을 투명하게 문서화할 수 있습니다.

이전에는 이 중요한 정보를 다른 출처에서 검색해야 했으므로 모듈을 제대로 평가하고 사용하기 어려웠습니다. 이제 모듈 설명서를 쉽게 사용할 수 있으므로 모듈을 사용하기 전에 모듈의 기능을 빠르게 이해할 수 있습니다. 이 접근성은 조직 전체에서 Terraform 코드를 자신감 있게 공유하고 재사용할 수 있도록 권장합니다.

### 이슈 이벤트 웹후크에 유형 속성 추가 {#add-type-attribute-to-issues-events-webhook}

<!-- categories: Team Planning, Notifications, Incident Management, Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md#work-item-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467415)

{{< /details >}}

이슈, 작업, 인시던트, 요구사항, 목표 및 주요 결과는 모두 **Issues Events** 웹후크 카테고리에서 페이로드를 트리거합니다. 지금까지 이벤트 페이로드 내에서 웹후크를 트리거한 객체의 유형을 빠르게 결정할 수 있는 방법이 없었습니다. 이 릴리스는 **Issues events**, **댓글**, **Confidential issues events** 및 **이모티콘 이벤트** 트리거 내의 페이로드에서 사용 가능한 `object_attributes.type` 속성을 도입합니다.

### Go, Java 및 Python용 베타 버전으로 제공되는 GitLab Advanced SAST {#gitlab-advanced-sast-available-in-beta-for-go-java-and-python}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

GitLab Advanced SAST는 이제 Ultimate 고객을 위한 베타 기능으로 제공됩니다. Advanced SAST는 파일 간, 함수 간 분석을 사용하여 더 높은 품질의 결과를 제공합니다. 이제 Go, Java 및 Python을 지원합니다.

베타 단계에서는 기존 SAST 분석기를 교체하지 않는 테스트 프로젝트에서 Advanced SAST를 실행하는 것이 좋습니다. Advanced SAST를 활성화하려면 [지침](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)을(를) 참조하세요. GitLab 17.2부터 Advanced SAST는 [`SAST.latest` CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml)에 포함됩니다.

이는 우리의 반복적인 [Oxeye 기술 통합](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/)의 일부입니다. 향후 릴리스에서 Advanced SAST를 General Availability로 이동하고 [다른 언어](https://gitlab.com/groups/gitlab-org/-/epics/14312)에 대한 지원을 추가하며 취약성이 어떻게 흐르는지 추적하는 새로운 UI 요소를 도입할 계획입니다. [이슈 466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322)에서 모든 테스트 피드백을 환영합니다.

### API 보안 테스트는 이제 서명된 인증 요청을 지원합니다 {#api-security-testing-now-supports-signed-authentication-requests}

<!-- categories: API Security -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/api_security_testing/configuration/variables.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

API 보안은 이미 스캐너가 보낸 요청을 수정할 수 있는 "덮어쓰기"에 대한 지원을 포함합니다. 그러나 이러한 덮어쓰기는 미리 설정해야 하므로 요청 자체를 기반으로 변경할 수 없습니다. GitLab 17.2는 각 요청을 보내기 전에 호출되는 C# 스크립트를 제공하기 위해 사용자를 허용하는 "요청당 스크립트" (`APISEC_PER_REQUEST_SCRIPT`)를 추가합니다. 이는 인증 형식으로 요청에 "서명"하기 위한 지원을 제공합니다.

### 컨테이너 스캔: 지속적 취약성 스캔 OS 지원 {#container-scanning-continuous-vulnerability-scanning-os-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/container_scanning/continuous_container_scanning/_index.md#supported-package-types) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

컨테이너 스캔용 지속적 취약성 스캔 MVC에 대한 후속 조치로 17.2 기간에 APK 및 RPM 운영 체제 패키지 버전에 대한 지원을 추가했습니다.

이 향상은 분석기가 [APK](https://gitlab.com/gitlab-org/gitlab/-/issues/428703) 및 [RPM](https://gitlab.com/gitlab-org/gitlab/-/issues/428941) 운영 체제 purl 유형에 대한 패키지 버전을 비교하여 컨테이너 스캔 권고에 대한 지속적 취약성 스캔을 완벽하게 지원할 수 있게 합니다.

참고로 캐럿이 포함된 RPM 버전 (`^`)은 지원되지 않습니다. 이러한 버전을 지원하기 위한 작업은 이 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/459969)에서 추적되고 있습니다.

### DAST 분석기 업데이트 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/browser/checks/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/13411)

{{< /details >}}

17.2 릴리스 마일스톤 동안 다음 업데이트를 게시했습니다.

1. 세 가지 새로운 확인을 추가했습니다:

- 확인 506.1은 Polyfill.io CDN 인수로 인해 손상되었을 가능성이 높은 요청 URL을 식별하는 수동 확인입니다.
- 확인 384.1은 세션 고정 약점을 식별하는 수동 확인으로, 악의적인 행위자가 유효한 세션 식별자를 재사용할 수 있게 합니다.
- 확인 16.11은 프로덕션 서버에서 TRACE HTTP 디버깅 방법이 활성화되어 있는 경우를 식별하는 활성 확인으로, 민감한 정보를 실수로 노출할 수 있습니다.

1. 오탐을 줄이기 위해 다음 버그를 해결했습니다:

- DAST 확인 614.1(Secure 속성 없는 민감한 쿠키) 및 1004.1(HttpOnly 속성 없는 민감한 쿠키)은 더 이상 사이트가 과거의 만료 날짜를 설정하여 쿠키를 지운 경우 결과를 생성하지 않습니다.
- DAST 확인 1336.1(서버 측 템플릿 주입)은 더 이상 500 HTTP 응답 상태 코드에 의존하여 공격 성공을 판단하지 않습니다.

1. 다음 개선 사항을 추가했습니다:

- 모든 응답 헤더가 이제 DAST 취약성 결과에서 증거로 제시됩니다. 이 추가 컨텍스트는 결과 심사에 소비되는 시간을 줄입니다.
- Sitemap.xml 파일이 이제 추가 URL에 대해 크롤링되어 대상 웹사이트의 더 나은 커버리지를 제공합니다.

### API 퍼즈 테스트는 이제 서명된 인증 요청을 지원합니다 {#api-fuzz-testing-now-supports-signed-authentication-requests}

<!-- categories: Fuzz Testing -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/api_fuzzing/configuration/variables.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

API Fuzzing은 이미 스캐너가 보낸 요청을 수정할 수 있는 "덮어쓰기"에 대한 지원을 포함합니다. 그러나 이러한 덮어쓰기는 미리 설정해야 하므로 요청 자체를 기반으로 변경할 수 없습니다. GitLab 17.2는 각 요청을 보내기 전에 호출되는 C# 스크립트를 제공하기 위해 사용자를 허용하는 "요청당 스크립트" (`FUZZAPI_PER_REQUEST_SCRIPT`)를 추가합니다. 이는 인증 형식으로 요청에 "서명"하기 위한 지원을 제공합니다.

### 이제 자체 관리용으로 사용할 수 있는 시크릿 푸시 보호 및 잠재적 누출에 대한 경고 개선 {#secret-push-protection-now-available-for-self-managed-and-improved-warnings-of-potential-leaks}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/secret_detection/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13107)

{{< /details >}}

17.2 릴리스 마일스톤 동안 다음 업데이트를 게시했습니다:

- 시크릿 푸시 보호 베타는 이제 자체 관리 고객이 사용할 수 있습니다. 관리자가 [기능을 인스턴스 전체에서 활성화](../../user/application_security/secret_detection/secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance)한 후 문서를 따라 [프로젝트에 대한 푸시 보호를 활성화](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project)하세요.
- [텍스트 콘텐츠의 잠재적 누출에 대한 경고](../../user/application_security/secret_detection/client/_index.md)는 더 많은 세부 사항으로 보강되어 이슈, 에픽 또는 MR의 설명 또는 댓글에서 누출될 시크릿 유형을 더 쉽게 이해할 수 있습니다.

### 파이프라인 일정의 정렬 옵션 {#sort-options-for-pipeline-schedules}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/pipelines/schedules.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/37246)

{{< /details >}}

이제 설명, ref, 다음 실행, 생성 날짜 및 업데이트 날짜로 파이프라인 일정 목록을 정렬할 수 있습니다.

### `rules:changes:compare_to`은 이제 CI/CD 변수를 지원합니다 {#ruleschangescompare_to-now-supports-cicd-variables}

<!-- categories: Pipeline Composition, Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#ruleschangescompare_to) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/369916)

{{< /details >}}

GitLab 15.3에서 [`compare_to` 키워드](../../ci/yaml/_index.md#ruleschangescompare_to)를 `rules:change`에 대해 도입했습니다. 이를 통해 비교할 정확한 ref를 정의할 수 있게 되었습니다. GitLab 17.2부터 이제 이 키워드로 CI/CD 변수를 사용할 수 있으므로 여러 작업에서 `compare_to` 값을 더 쉽게 정의하고 재사용할 수 있습니다.

### GitLab Runner 17.2 {#gitlab-runner-172}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab Runner 17.2를 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 경량의 확장성 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [AWS EC2 인스턴스용 GitLab Runner fleeting 플러그인(GA)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29222)
- [Runner `livenessProbe` 및 `readinessProbe`의 구성을 허용](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/545)
- [Kubernetes 실행기의 `umask 0000` 명령을 활성화 및 비활성화하는 기능](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28867)
- [GitLab Runner Operator용 Red Hat OpenShift 4.16 지원](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/203)

#### 버그 수정 {#bug-fixes}

- [GitLab Runner 업그레이드는 모든 캐시 볼륨을 제거합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30876)

모든 변경 사항의 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-2-stable/CHANGELOG.md)를 참조하세요.

### 워크스페이스용 새로운 에이전트 인증 전략 {#new-agent-authorization-strategy-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

이 릴리스에서 워크스페이스에 대한 새로운 인증 전략을 구현하여 레거시 전략의 한계를 해결하면서 그룹 소유자 및 관리자에게 더 많은 제어 및 유연성을 제공합니다. 새로운 인증 전략으로 그룹 소유자 및 관리자는 워크스페이스를 호스팅하는 데 사용할 클러스터 에이전트를 제어할 수 있습니다.

원활한 전환을 보장하기 위해 레거시 인증 전략의 사용자는 자동으로 새 전략으로 마이그레이션됩니다. 워크스페이스를 지원하는 기존 에이전트는 이러한 에이전트가 있는 루트 그룹에서 자동으로 허용됩니다. 루트 그룹의 다른 그룹에서 이러한 에이전트가 허용된 경우에도 이 마이그레이션이 발생합니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.2)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
