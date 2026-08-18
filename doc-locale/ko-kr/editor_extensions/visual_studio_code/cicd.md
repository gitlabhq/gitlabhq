---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장 프로그램을 사용하여 IDE에서 직접 CI/CD 파이프라인을 관리합니다.
title: VS Code 확장의 프로그램에서 CI/CD 파이프라인
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab VS Code 확장 6.14.0 및 GitLab 18.1 이상에서 도입](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)되었습니다.
- GitLab 18.1 이상에 대해 [다운스트림 파이프라인 로그](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)가 추가되었습니다.

{{< /history >}}

프로젝트에서 GitLab CI/CD 을 사용하는 경우 GitLab VS Code 확장을 사용하여 IDE에서 직접 을 시작, 모니터링 및 업데이트할 수 있습니다.

## 전제 조건 {#prerequisites}

- [확장 인증](setup.md#connect-to-gitlab)을 수행하고 GitLab의 에 연결합니다.

## 모니터링 및 관리 {#monitor-and-manage-pipelines}

확장을 사용하여 프로젝트의 을 모니터링하고 관리합니다.

전제 조건:

- 프로젝트에서 CI/CD 을 사용합니다.
- 현재 Git 에 대한 가 있습니다.
- 현재 Git 의 가장 최근 에는 CI/CD 이 있습니다.

### 상태 보기 {#view-pipeline-status}

의 상태를 보려면 VS Code의 아래쪽 상태 표시줄을 확인합니다.

![가장 최근 파이프라인이 실패했음을 보여주는 아래쪽 상태 표시줄](img/status_bar_pipeline_v17_6.png)

가능한 상태는 다음과 같습니다:

- 취소됨
- 실패
- 통과
- 보류 중
- 실행 중
- 건너뜀
- 이 아직 실행되지 않은 경우 파이프라인이 없습니다.

### 관리 {#manage-pipelines}

GitLab에서 CI/CD 을 시작, 모니터링 및 디버깅하려면:

1. VS Code의 아래쪽 상태 표시줄에서 상태를 선택하여 **Command Palette**를 열고 사용 가능한 작업에 액세스합니다.
1. 원하는 을 선택하고 프롬프트를 따릅니다:

   - **Create New Pipeline from Current Branch**
   - **Cancel Last Pipeline**
   - **Download Artifacts from Latest Pipeline**
   - **Retry Last Pipeline**
   - **View Latest Pipeline on GitLab**

### CI/CD 출력 보기 {#view-cicd-job-output}

현재 에 대한 CI/CD 의 출력을 보려면:

1. 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택합니다.
1. **For current branch**를 확장하여 가장 최근 을 봅니다.
1. 을 선택하여 새 VS Code 탭에서 엽니다:

   ![통과 및 실패한 CI/CD 작업을 포함하는 파이프라인](img/view_job_output_v17_6.png)

의 를 열려면:

1. 목록 아래에서 을 찾습니다.
1. 화살표 아이콘을 선택하여 정보를 확장하거나 축소합니다.
1. 을 선택하여 새 VS Code 탭에서 를 엽니다.

### 경고 관리 {#manage-pipeline-alerts}

확장은 현재 의 이 완료될 때 VS Code에 경고를 표시할 수 있습니다:

![파이프라인 실패를 보여주는 경고](img/pipeline_alert_v19_0.png)

경고를 켜거나 끄려면:

1. VS Code에서 **설정** 편집기를 엽니다:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. 구성에 따라 **사용자** 또는 **Workspace** 설정을 선택합니다.
1. **Extensions** > **GitLab** > **기타**를 선택하세요.
1. **GitLab 아래에서: 업데이트 알림 표시**, 확인란을 선택하거나 선택 해제합니다.

## CI/CD 구성 관리 {#manage-your-cicd-configuration}

확장은 프로젝트의 CI/CD 구성을 생성하고 관리하는 데 사용할 수 있는 도구를 제공합니다.

### CI/CD 자동 완성 {#autocomplete-cicd-variables}

CI/CD 구성 파일을 작성하거나 편집할 때 자동 완성을 사용하여 를 빠르게 찾습니다.

전제 조건:

- CI/CD 구성 파일의 이름이 `.gitlab-ci`으로 시작하고 `.yml` 또는 `.yaml`으로 끝납니다. 예를 들어 `.gitlab-ci.yml` 또는 `.gitlab-ci.production.yml`

를 자동 완성하려면:

1. VS Code에서 `.gitlab-ci.yml` 파일을 열고 파일의 탭이 포커스 상태인지 확인합니다.
1. 이름을 입력하기 시작합니다. 확장이 자동 완성 옵션을 표시합니다.
1. 옵션을 선택하여 사용합니다:

   ![문자열에 대해 표시된 자동 완성 옵션](img/ci_variable_autocomplete_v16_6.png)

### GitLab CI/CD 구성 테스트 {#test-gitlab-cicd-configuration}

프로젝트의 GitLab CI/CD 구성을 로컬에서 테스트하려면:

1. VS Code에서 `.gitlab-ci.yml` 파일을 열고 파일의 탭이 포커스 상태인지 확인합니다.
1. **Command Palette**를 엽니다:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `GitLab: Validate GitLab CI Config`을 입력하고 <kbd>Enter</kbd>를 누르세요.

확장이 구성에 문제가 감지되면 경고를 표시합니다.

### 병합된 구성 파일 표시 {#show-merged-configuration-file}

병합된 CI/CD 구성 파일의 미리보기를 보려면 모든 `includes`과 참조가 해결됩니다:

1. VS Code에서 `.gitlab-ci.yml` 파일을 열고 파일의 탭이 포커스 상태인지 확인합니다.
1. 오른쪽 위에서 **Show Merged GitLab CI/CD Configuration**를 선택합니다:

   ![병합된 결과를 보기 위한 아이콘을 표시하는 VS Code 애플리케이션](img/show_merged_configuration_v17_6.png)

VS Code는 전체 정보와 함께 새 탭 (`.gitlab-ci (Merged).yml`)을 엽니다.

## 관련 항목 {#related-topics}

- [CI/CD를 사용하여 애플리케이션 빌드](../../topics/build_your_application.md)
