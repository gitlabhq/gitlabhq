---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장 프로그램의 설정 및 명령입니다.
title: GitLab for VS Code 확장 프로그램 설정 및 명령
---

GitLab for VS Code 확장 프로그램은 VS Code 명령 팔레트와 통합되며, 기존 Git용 VS Code 통합을 확장하고 구성 옵션을 제공합니다.

## 명령 팔레트 명령 {#command-palette-commands}

이 확장 프로그램은 [명령 팔레트](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette)에서 트리거할 수 있는 여러 명령 세트를 제공합니다:

### 프로젝트 및 코드 관리 {#manage-projects-and-code}

- `GitLab: Authenticate`
- [`GitLab: Compare Current Branch with Default Branch`](projects.md#compare-with-default-branch): 브랜치를 리포지토리의 기본 브랜치와 비교하고 GitLab에서 변경 사항을 봅니다.
- `GitLab: Open Current Project on GitLab`
- [`GitLab: Open Remote Repository`](remote_urls.md): 원격 GitLab 리포지토리를 브라우저에서 봅니다.
- `GitLab: Pipeline Actions - View, Create, Retry, or Cancel`
- `GitLab: Remove Account from VS Code`
- `GitLab: Validate GitLab Accounts`

### 이슈 및 머지 리퀘스트 관리 {#manage-issues-and-merge-requests}

- [`GitLab: Advanced Search (Issues, Merge Requests, Commits, Comments...)`](projects.md#search-issues-and-merge-requests)
- `GitLab: Copy Link to Active File on GitLab`
- `GitLab: Create New Issue on Current Project`
- `GitLab: Create New Merge Request on Current Project`: 머지 리퀘스트 페이지를 열어 머지 리퀘스트를 생성합니다.
- [`GitLab: Open Active File on GitLab`](projects.md#open-current-file-in-gitlab-ui): GitLab에서 활성 파일을 보고, 활성 줄 번호와 선택한 텍스트 블록을 강조 표시합니다.
- `GitLab: Open Merge Request for Current Branch`
- [`GitLab: Search Project Issues (Supports Filters)`](projects.md#search-issues-and-merge-requests).
- [`GitLab: Search Project Merge Requests (Supports Filters)`](projects.md#search-issues-and-merge-requests).
- `GitLab: Show Issues Assigned to Me`: GitLab에서 자신에게 할당된 이슈를 엽니다.
- `GitLab: Show Merge Requests Assigned to Me`: GitLab에서 자신에게 할당된 머지 리퀘스트를 엽니다.

### CI/CD 파이프라인 관리 {#manage-cicd-pipelines}

- [`GitLab: Show Merged GitLab CI/CD Configuration`](cicd.md#show-merged-configuration-file): GitLab CI/CD 구성 파일 `.gitlab-ci.yml`의 미리 보기를 표시하며, 모든 포함 항목이 해결됩니다.
- [`GitLab: Validate GitLab CI/CD Configuration`](cicd.md#test-gitlab-cicd-configuration): GitLab CI/CD 구성 파일 `.gitlab-ci.yml`을(를) 테스트합니다.

### AI 지원 기능 {#ai-assisted-features}

- `GitLab: Restart GitLab Language Server`
- `GitLab: Show Duo Workflow`
- `GitLab: Toggle Code Suggestions`
- `GitLab: Toggle Code Suggestions for current language`

### 기타 기능 {#other-features}

- `GitLab: Apply Snippet Patch`
- `GitLab: Clone Wiki`
- [`GitLab: Create Snippet`](projects.md#create-a-snippet): 전체 파일 또는 선택 항목에서 공개, 내부 또는 비공개 코드 조각을 생성합니다.
- [`GitLab: Create Snippet Patch`](projects.md#create-a-patch-file): 전체 파일 또는 선택 항목에서 `.patch` 파일을 생성합니다.
- [`GitLab: Insert Snippet`](projects.md#insert-a-snippet): 단일 파일 또는 다중 파일 프로젝트 코드 조각을 삽입합니다.
- `GitLab: Publish Workspace to GitLab`
- `GitLab: Refresh Sidebar`
- `GitLab: Show Extension Logs`
- `GitLab: View Security Finding Details`
- `GitLab: Focus on For current branch View`
- `GitLab: Focus on Issues and Merge Requests View`
- `GitLab: Diagnostics`: GitLab for VS Code 확장 프로그램의 자세한 설정 페이지를 엽니다.

## 명령 통합 {#command-integrations}

이 확장 프로그램은 VS Code에서 제공하는 일부 명령과도 통합됩니다:

- `Git: Clone`: 설정한 모든 GitLab 인스턴스에서 프로젝트를 검색하고 복제합니다. 자세한 정보는 다음을 참조하세요.
  - [GitLab 프로젝트 복제](remote_urls.md#clone-a-git-project) (확장 프로그램 설명서).
  - [리포지토리 복제](https://code.visualstudio.com/docs/sourcecontrol/overview#_cloning-a-repository) (VS Code 설명서).
- `Git: Add Remote...`: 설정한 모든 GitLab 인스턴스에서 기존 프로젝트를 원격으로 추가합니다.

## 확장 프로그램 설정 {#extension-settings}

VS Code에서 설정을 변경하는 방법을 알아보려면 [사용자 및 워크스페이스 설정](https://code.visualstudio.com/docs/configure/settings)에 대한 VS Code 설명서를 참조하세요.

GitLab 인스턴스에 연결하기 위해 자체 서명된 인증서를 사용하는 경우 [사용자 지정 인증 기관에 대한 확장 프로그램 구성](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/user/custom-certificates.md)을(를) 참조하세요.

| 설정 | 기본값 | 정보 |
| ------- | ------- | ----------- |
| `gitlab.customQueries` | 적용 안 됨 | GitLab 패널에 표시되는 항목을 검색하는 검색 쿼리를 정의합니다. 자세한 내용은 [사용자 지정 쿼리 설명서](custom_queries.md)를 참조하세요. |
| `gitlab.authentication.oauthClientIds` | 적용 안 됨 | [설정](setup.md#authenticate-with-gitlab) 중에 사용할 OAuth 클라이언트 ID (GitLab 인스턴스 URL 기준). |
| `gitlab.debug` | 거짓 | `true`일 때 디버그 모드를 활성화합니다. 디버그 모드는 확장 프로그램이 축소된 코드를 이해하기 위해 소스 맵을 사용하므로 오류 스택 추적을 개선합니다. 디버그 모드는 [확장 프로그램 로그](troubleshooting.md#view-debug-logs)에 디버그 로그 메시지도 표시합니다. |
| `gitlab.duo.enabledWithoutGitlabProject` | 참 | `true`일 때 확장 프로그램이 프로젝트의 `duoFeaturesEnabledForProject` 설정을 검색할 수 없으면 GitLab Duo 기능이 활성화된 상태로 유지됩니다. `false`일 때 확장 프로그램이 프로젝트의 `duoFeaturesEnabledForProject` 설정을 검색할 수 없으면 모든 GitLab Duo 기능이 비활성화됩니다. [`duoFeaturesEnabledForProject` 설정](#duofeaturesenabledforproject)을(를) 참조하세요. |
| `gitlab.duoAgentPlatform.defaultNamespace` | 적용 안 됨 | 확장 프로그램이 GitLab 프로젝트 세부 정보를 가져올 수 없을 때 GitLab Duo Agent Platform의 기본 그룹 또는 네임스페이스 경로. |
| `gitlab.duoCodeSuggestions.additionalLanguages` | 적용 안 됨 | (실험 중.) GitLab Duo 코드 제안에 대해 공식적으로 지원되는 언어 목록을 확장하려면 [언어 식별자](https://code.visualstudio.com/docs/languages/identifiers#_known-language-identifiers) 배열을 제공하세요. 추가된 언어에 대한 코드 제안 품질이 최적이 아닐 수 있습니다. |
| `gitlab.duoCodeSuggestions.enabled` | 참 | `true`일 때 AI 지원 제안을 위해 코드 제안을 활성화합니다. |
| `gitlab.duoCodeSuggestions.enabledSupportedLanguages` | 적용 안 됨 | 코드 제안을 활성화할 지원되는 언어입니다. 기본적으로 지원되는 모든 언어가 활성화됩니다. |
| `gitlab.duoCodeSuggestions.openTabsContext` | 참 | `true`일 때 열린 탭 간에 컨텍스트를 전송하여 코드 제안을 개선할 수 있습니다. |
| `gitlab.keybindingHints.enabled` | 참 | GitLab Duo의 키 바인딩 힌트를 활성화합니다. |
| `gitlab.pipelineGitRemoteName` | null | 파이프라인이 있는 GitLab 리포지토리에 해당하는 Git 원격의 이름입니다. `null`이거나 비어 있으면 확장 프로그램이 비 파이프라인 기능에 동일한 원격을 사용합니다. |
| `gitlab.showPipelineUpdateNotifications` | 거짓 | `true`일 때 파이프라인이 완료되면 경고를 표시합니다. |

### `duoFeaturesEnabledForProject` {#duofeaturesenabledforproject}

`duoFeaturesEnabledForProject` 설정은 다음 경우에 사용할 수 없습니다:

- 프로젝트가 확장 프로그램에서 설정되지 않았습니다.
- 프로젝트가 현재 계정과 다른 GitLab 인스턴스에 있습니다.
- 작업 중인 파일 또는 폴더가 접근 권한이 있는 GitLab 프로젝트의 일부가 아닙니다.
