---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for Visual Studio 확장 프로그램의 일반적인 문제를 해결하는 방법을 알아봅니다.
title: GitLab for Visual Studio 확장 프로그램 문제 해결
---

이 페이지의 단계로 문제가 해결되지 않으면 확장 프로그램의 [열린 이슈 목록](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/?sort=created_date&state=opened&first_page_size=100)을 확인하세요. 이슈가 문제와 일치하면 해당 이슈를 업데이트하세요. 일치하는 이슈가 없으면 [새로운 이슈를 생성](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/new)하세요.

## GitLab Duo 기능이 표시되지 않음 {#gitlab-duo-features-do-not-appear}

GitLab Duo Chat 또는 GitLab Duo Code Suggestions가 Visual Studio에서 사용할 수 없는 경우:

- [전제 조건](setup.md#configure-gitlab-duo)을 충족하고 필요한 설정이 활성화되었는지 확인하세요.
- [Admin 모드가 비활성화됨](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)을 확인하세요.
- GitLab Duo Agentic Chat이 활성화되어 있는지 확인합니다:
  1. Visual Studio에서 **Tools** > **Options** > **GitLab**으로 이동합니다.
  1. **GitLab** 아래에서 **General**을 선택합니다.
  1. **Enable Agentic Duo Chat**이 **True**로 설정되어 있는지 확인하세요.
- Code Suggestions이 활성화되어 있는지 확인합니다:
  1. Visual Studio의 하단 상태 표시줄에서 GitLab 아이콘의 도구 설명을 확인하여 기능의 현재 상태를 확인하세요.
  1. Code Suggestions이 활성화되지 않으면 위쪽 표시줄에서 **Extensions** > **GitLab** > **Toggle Code Suggestions**을 선택하세요.

Code Suggestions에 대한 지원은 [Code Suggestions 문제 해결](../../user/project/repository/code_suggestions/troubleshooting.md#microsoft-visual-studio-troubleshooting)을 참조하세요.

## 네트워크 문제 {#network-issues}

GitLab Duo에서 `HTTP/1.1` 응답이 로그의 `/-/cable` WebSocket 끝점 대신 표시되면 WebSocket 연결이 차단될 수 있습니다.

GitLab 인스턴스는 IDE 클라이언트로부터의 인바운드 WebSocket 연결을 허용해야 합니다. 문제가 의심되면 네트워크 관리자에게 [GitLab 인스턴스로의 WebSocket 트래픽 허용](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)을 요청하세요.

## 더 많은 로그 보기 {#view-more-logs}

더 많은 로그는 **GitLab Extension Output** 창에서 사용할 수 있습니다:

1. Visual Studio에서 위쪽 표시줄의 **도구** > **옵션** 메뉴로 이동하세요.
1. **GitLab** 옵션을 찾고 **로그 수준**을 **디버그**로 설정하세요.
1. **보기** > **Output**으로 이동하여 확장 프로그램 로그를 엽니다. 드롭다운 목록에서 **GitLab Extension**을 로그 필터로 선택하세요.
1. 디버그 로그에 유사한 출력이 포함되어 있는지 확인하세요:

   ```shell
   GetProposalManagerAsync: Code suggestions enabled. ContentType (csharp) or file extension (cs) is supported.
   GitlabProposalSourceProvider.GetProposalSourceAsync
   ```

### 활동 로그 보기 {#view-activity-log}

확장 프로그램이 로드되지 않거나 충돌하는 경우 활동 로그에서 오류를 확인하세요. 활동 로그는 다음 위치에서 사용할 수 있습니다:

```plaintext
C:\Users\WINDOWS_USERNAME\AppData\Roaming\Microsoft\VisualStudio\VS_VERSION\ActivityLog.xml
```

디렉터리 경로에서 다음 값을 바꾸세요:

- `WINDOWS_USERNAME`: Windows 사용자 이름입니다.
- `VS_VERSION`: Visual Studio 설치의 버전입니다.

## 지원에 필요한 정보 {#required-information-for-support}

지원팀에 문의하기 전에 최신 GitLab 확장 프로그램이 설치되어 있는지 확인하세요. Visual Studio는 자동으로 최신 버전의 확장 프로그램으로 업데이트됩니다.

영향을 받은 사용자로부터 이 정보를 수집하여 버그 보고서에 제공하세요:

1. 사용자에게 표시되는 오류 메시지입니다.
1. 워크플로 및 언어 서버 로그:
   1. [디버그 로그 활성화](#view-more-logs)합니다.
   1. [로그 파일 검색](#view-activity-log)합니다.
1. 진단 출력:
   1. Visual Studio가 열려 있는 상태에서 위쪽 배너의 **도움말** > **About Microsoft Visual Studio**를 선택하세요.
   1. 대화 상자에서 **Copy Info**를 선택하여 이 섹션의 필요한 모든 정보를 클립보드로 복사하세요.
1. 시스템 세부 정보:
   1. Visual Studio가 열려 있는 상태에서 위쪽 배너의 **도움말** > **About Microsoft Visual Studio**를 선택하세요.
   1. 대화 상자에서 **System Info**를 선택하여 더 자세한 정보를 확인하세요.
   1. **OS type and version**에 대해: `OS Name`과(와) `Version`을(를) 복사하세요.
   1. **Machine specifications (CPU, RAM)**의 경우: `Processor`과(와) `Installed Physical Memory (RAM)` 섹션을 복사하세요.
1. 영향 범위를 설명하세요. 영향을 받는 사용자가 몇 명입니까?
1. 오류를 재현하는 방법을 설명하세요. 가능하면 스크린 녹화를 포함하세요.
1. 다른 GitLab Duo 기능이 어떻게 영향을 받는지 설명하세요:
   - Code Suggestions이 작동합니까?
   - Web IDE의 GitLab Duo Chat이 응답을 반환합니까?
1. 확장 프로그램 격리 테스트를 수행하세요. 다른 확장 프로그램이 문제를 야기하는지 확인하기 위해 다른 모든 확장 프로그램을 비활성화(또는 제거)해 보세요. 이것은 문제가 당사 확장 프로그램과 관련이 있는지 아니면 외부 소스에서 비롯되었는지 확인하는 데 도움이 됩니다.
