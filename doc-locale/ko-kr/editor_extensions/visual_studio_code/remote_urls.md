---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 원격 URL 형식
---

VS Code에서는 Git 리포지토리를 복제하거나 읽기 전용 모드로 탐색할 수 있습니다.

GitLab 원격 URL에는 다음 매개변수가 필요합니다:

- `instanceUrl`: GitLab 인스턴스 URL이며, `https://` 또는 `http://`을 포함하지 않습니다.
  - GitLab 인스턴스에서 [상대 URL을 사용](../../install/relative_url.md)하는 경우, URL에 상대 URL을 포함하세요.
  - 예를 들어, 인스턴스 `example.com/gitlab`에서 프로젝트 `templates/ui`의 브랜치 `main`에 대한 URL은 `gitlab-remote://example.com/gitlab/<label>?project=templates/ui&ref=main`입니다.
- `label`: Visual Studio Code가 이 워크스페이스 폴더의 이름으로 사용하는 텍스트입니다:
  - 인스턴스 URL 바로 뒤에 나타나야 합니다.
  - `/` 또는 `?`와 같이 이스케이프되지 않은 URL 구성 요소를 포함할 수 없습니다.
  - 도메인 루트에 설치된 인스턴스(예: `https://gitlab.com`)의 경우 레이블은 첫 번째 경로 요소여야 합니다.
  - 리포지토리의 루트를 참조하는 URL의 경우 레이블은 마지막 경로 요소여야 합니다.
  - VS Code는 레이블 뒤에 나타나는 모든 경로 요소를 리포지토리 내부의 경로로 처리합니다. 예를 들어, `gitlab-remote://gitlab.com/GitLab/app?project=gitlab-org/gitlab&ref=master`은(는) GitLab.com의 `gitlab-org/gitlab` 리포지토리의 `app` 디렉터리를 참조합니다.
- `projectId`: 프로젝트의 숫자 ID(예: `5261717`) 또는 네임스페이스(`gitlab-org/gitlab-vscode-extension`)일 수 있습니다. 인스턴스에서 리버스 프록시를 사용하는 경우 `projectId`을(를) 숫자 ID로 지정합니다. 자세한 내용은 [이슈 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775)을(를) 참조하세요.
- `gitReference`: 리포지토리 브랜치 또는 커밋 SHA입니다.

그러면 매개변수는 다음 순서로 배치됩니다:

```plaintext
gitlab-remote://<instanceUrl>/<label>?project=<projectId>&ref=<gitReference>
```

예를 들어, 주 GitLab 프로젝트의 `projectId`은(는) `278964`이므로 주 GitLab 프로젝트의 원격 URL은 다음과 같습니다:

```plaintext
gitlab-remote://gitlab.com/<label>?project=278964&ref=master
```

## Git 프로젝트 복제 {#clone-a-git-project}

GitLab for VS Code는 `Git: Clone` 명령을 확장합니다. GitLab 프로젝트의 경우, HTTPS 또는 Git URL로 복제할 수 있습니다.

전제 조건:

- GitLab 인스턴스에서 검색 결과를 반환하려면 해당 GitLab 인스턴스에 [액세스 토큰을 추가](setup.md#authenticate-with-gitlab)해야 합니다.
- 검색에서 결과로 반환되려면 프로젝트의 구성원이어야 합니다.

GitLab 프로젝트를 검색하고 복제하려면:

1. 다음을 눌러 Command Palette를 엽니다:
   - MacOS: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Windows: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. **Git: 명령을 실행합니다: 복제** 명령을 실행합니다.
1. 리포지토리 소스로 GitHub 또는 GitLab을 선택합니다.
1. **리포지토리 이름**을(를) 검색한 후 선택합니다.
1. 리포지토리를 복제할 로컬 폴더를 선택합니다.
1. GitLab 리포지토리를 복제하는 경우 복제 방법을 선택합니다:
   - Git으로 복제하려면 `user@hostname.com`로 시작하는 URL을 선택합니다.
   - HTTPS로 복제하려면 `https://`로 시작하는 URL을 선택합니다. 이 방법은 액세스 토큰을 사용하여 리포지토리를 복제하고, 커밋을 페치하고, 커밋을 푸시합니다.
1. 복제된 리포지토리를 열지 아니면 현재 VS Code 워크스페이스에 추가할지 선택합니다.

## 리포지토리를 읽기 전용 모드로 탐색 {#browse-a-repository-in-read-only-mode}

이 확장 프로그램을 사용하면 GitLab 리포지토리를 복제하지 않고 읽기 전용 모드로 탐색할 수 있습니다.

전제 조건:

- 해당 GitLab 인스턴스에 대해 [액세스 토큰을 등록](setup.md#authenticate-with-gitlab)했습니다.

GitLab 리포지토리를 읽기 전용 모드로 탐색하려면:

1. 다음을 눌러 Command Palette를 엽니다:
   - MacOS: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Windows: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. **GitLab: 명령을 실행합니다: 원격 리포지토리 열기** 명령을 실행합니다.
1. **Open in current window**, **Open in new window**, 또는 **Add to workspace**를 선택합니다.
1. 리포지토리를 추가하려면 `Enter gitlab-remote URL`을(를) 선택한 후 원하는 프로젝트의 `gitlab-remote://` URL을 입력합니다.
1. 이미 추가한 리포지토리를 보려면 **프로젝트 선택하세요**를 선택한 후 드롭다운 목록에서 원하는 프로젝트를 선택합니다.
1. 드롭다운 목록에서 보려는 Git 브랜치를 선택한 후 <kbd>Enter</kbd>를 눌러 확인합니다.

`gitlab-remote` URL을 VS Code 워크스페이스 파일에 추가하려면 VS Code 문서의 [Workspace file](https://code.visualstudio.com/docs/editor/multi-root-workspaces#_workspace-file)을(를) 참조하세요.
