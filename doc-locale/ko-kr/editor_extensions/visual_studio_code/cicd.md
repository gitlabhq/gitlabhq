---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장 프로그램을 사용하여 IDE에서 직접 CI/CD 파이프라인을 관리합니다.
title: VS Code 확장에서의 CI/CD 파이프라인
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab VS Code 확장 6.14.0 및 GitLab 18.1 이상에서 [도입](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)되었습니다.
- GitLab 18.1 이상에 대해 [다운스트림 파이프라인 로그](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)가 추가되었습니다.

{{< /history >}}

프로젝트에서 GitLab CI/CD 파이프라인을 사용하는 경우 GitLab VS Code 확장을 사용하여 IDE에서 직접 파이프라인을 시작, 모니터링 및 업데이트할 수 있습니다.

## 전제 조건 {#prerequisites}

- [확장 인증](setup.md#connect-to-gitlab)을 수행하고 GitLab의 리포지토리에 연결합니다.

## 파이프라인 모니터링 및 관리 {#monitor-and-manage-pipelines}

확장을 사용하여 프로젝트의 파이프라인을 모니터링하고 관리합니다.

전제 조건:

- 프로젝트에서 CI/CD 파이프라인을 사용합니다.
- 현재 Git 브랜치에 대한 머지 리퀘스트가 있습니다.
- 현재 Git 브랜치의 가장 최근 커밋에는 CI/CD 파이프라인이 있습니다.

### 파이프라인 상태 보기 {#view-pipeline-status}

브랜치 파이프라인의 상태를 보려면 VS Code의 아래쪽 상태 표시줄을 확인합니다.

![가장 최근 파이프라인이 실패했음을 보여주는 아래쪽 상태 표시줄](img/status_bar_pipeline_v17_6.png)

가능한 상태는 다음과 같습니다.

- 파이프라인 취소됨
- 파이프라인 실패
- 파이프라인 통과
- 파이프라인 보류 중
- 파이프라인 실행 중
- 파이프라인 건너뜀
- 파이프라인이 아직 실행되지 않은 경우 파이프라인 없음.

### 파이프라인 관리 {#manage-pipelines}

GitLab에서 CI/CD 파이프라인을 시작, 모니터링 및 디버깅하려면:

1. VS Code의 아래쪽 상태 표시줄에서 파이프라인 상태를 선택하여 **명령 팔레트**를 열고 사용 가능한 작업에 액세스합니다.
1. 원하는 을 선택하고 프롬프트를 따릅니다.

   - **현재 브랜치에서 새 파이프라인 생성**
   - **마지막 파이프라인 취소**
   - **최신 파이프라인에서 아티팩트 다운로드**
   - **마지막 파이프라인 재시도**
   - **GitLab에서 최신 파이프라인 보기**

### CI/CD 작업 출력 보기 {#view-cicd-job-output}

현재 브랜치에 대한 CI/CD 작업의 출력을 보려면:

1. 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택하세요.
1. **현재 브랜치의 경우**를 확장하여 가장 최근 파이프라인을 봅니다.
1. 작업을 선택하여 새 VS Code 탭에서 엽니다.

   ![통과 및 실패한 CI/CD 작업을 포함하는 파이프라인](img/view_job_output_v17_6.png)

다운스트림 파이프라인의 작업 로그를 열려면:

1. 브랜치 파이프라인 작업 목록 아래에서 다운스트림 파이프라인을 찾습니다.
1. 화살표 아이콘을 선택하여 다운스트림 파이프라인 정보를 확장하거나 축소합니다.
1. 다운스트림 파이프라인을 선택하여 새 VS Code 탭에서 작업 로그를 엽니다.

### 파이프라인 경고 관리 {#manage-pipeline-alerts}

확장은 현재 브랜치의 파이프라인이 완료될 때 VS Code에 경고를 표시할 수 있습니다.

![파이프라인 실패를 보여주는 경고](img/pipeline_alert_v19_0.png)

파이프라인 경고를 켜거나 끄려면:

1. VS Code에서 **설정** 편집기를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. 구성에 따라 **사용자** 또는 **워크스페이스** 설정을 선택합니다.
1. **확장** > **GitLab** > **기타**를 선택하세요.
1. **GitLab 아래에서 파이프라인 업데이트 알림 표시** 확인란을 선택하거나 선택 해제합니다.

## CI/CD 구성 관리 {#manage-your-cicd-configuration}

확장은 프로젝트의 CI/CD 구성을 생성하고 관리하는 데 사용할 수 있는 도구를 제공합니다.

### CI/CD 변수 자동 완성 {#autocomplete-cicd-variables}

CI/CD 구성 파일을 작성하거나 편집할 때 자동 완성을 사용하여 변수를 빠르게 찾습니다.

전제 조건:

- CI/CD 구성 파일의 이름이 `.gitlab-ci`로 시작하고 `.yml` 또는 `.yaml`로 끝납니다. 예를 들어 `.gitlab-ci.yml` 또는 `.gitlab-ci.production.yml`

변수를 자동 완성하려면:

1. VS Code에서 `.gitlab-ci.yml` 파일을 열고 파일의 탭이 포커스 상태인지 확인합니다.
1. 변수 이름을 입력하기 시작합니다. 확장이 자동 완성 옵션을 표시합니다.
1. 옵션을 선택하여 사용합니다.

   ![문자열에 대해 표시된 자동 완성 옵션](img/ci_variable_autocomplete_v16_6.png)

### GitLab CI/CD 구성 테스트 {#test-gitlab-cicd-configuration}

프로젝트의 GitLab CI/CD 구성을 로컬에서 테스트하려면:

1. VS Code에서 `.gitlab-ci.yml` 파일을 열고 파일의 탭이 포커스 상태인지 확인합니다.
1. **명령 팔레트**를 엽니다.
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. `GitLab: Validate GitLab CI Config`를 입력하고 <kbd>Enter</kbd>를 누르세요.

확장이 구성에 문제가 감지되면 경고를 표시합니다.

### 병합된 구성 파일 표시 {#show-merged-configuration-file}

모든 `includes`와 참조가 해결된 상태로 병합된 CI/CD 구성 파일의 미리보기를 보려면:

1. VS Code에서 `.gitlab-ci.yml` 파일을 열고 파일의 탭이 포커스 상태인지 확인합니다.
1. 오른쪽 위에서 **병합된 GitLab CI/CD 구성 표시**를 선택합니다.

   ![병합된 결과를 보기 위한 아이콘을 표시하는 VS Code 애플리케이션](img/show_merged_configuration_v17_6.png)

VS Code는 전체 정보와 함께 새 탭 (`.gitlab-ci (Merged).yml`)을 엽니다.

## 관련 항목 {#related-topics}

- [CI/CD를 사용하여 애플리케이션 빌드](../../topics/build_your_application.md)
