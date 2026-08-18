---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장을 사용하여 보안 스캔을 수행하고 검토합니다.
title: GitLab for VS Code에서 애플리케이션 보안
---

GitLab for VS Code 확장을 사용하여 애플리케이션에서 보안 취약성을 확인합니다. 보안 조사 결과를 검토하고 IDE에서 직접 정적 애플리케이션 보안 테스트(SAST)를 실행합니다.

## 보안 조사 결과 보기 {#view-security-findings}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- GitLab for VS Code 3.74.0 이상
- [Security Risk Management](https://about.gitlab.com/features/?stage=secure) 기능을 포함하는 프로젝트. 예: 정적 애플리케이션 보안 테스트(SAST), 동적 애플리케이션 보안 테스트(DAST), 컨테이너 스캔 또는 종속성 검사
- 구성된 [security risk management](../../user/application_security/secure_your_application.md) 기능

보안 조사 결과를 보려면 다음을 수행합니다:

1. VS Code의 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택하세요.
1. 현재 브랜치 섹션에서 **보안 스캔**을 확장합니다.
1. **New findings** 또는 **Fixed findings** 중 하나를 선택합니다.
1. 심각도 수준을 선택합니다.
1. 조사 결과를 선택하여 VS Code 탭에서 엽니다.

## 정적 애플리케이션 보안 테스트(SAST) {#static-application-security-testing-sast}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- VS Code 확장 5.31에서 [도입](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1675)되었습니다.

{{< /history >}}

VS Code의 정적 애플리케이션 보안 테스트(SAST)는 활성 파일의 취약성을 감지합니다. 조기 감지를 통해 변경 사항을 기본 브랜치에 병합하기 전에 취약성을 해결할 수 있습니다.

SAST 스캔을 트리거하면 활성 파일의 콘텐츠가 GitLab으로 전달되고 SAST 취약성 규칙에 대해 확인됩니다. GitLab은 스캔 결과를 **GitLab**({{< icon name="tanuki" >}}) 확장 패널에 표시합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> SAST 스캔 설정 방법에 대해 알아보려면 GitLab Unfiltered의 [SAST scanning in VS Code](https://www.youtube.com/watch?v=s-qOSQO0i-8)를 참조하세요.
<!-- Video published on 2025-02-10 -->

### SAST 스캔 활성화 {#enable-sast-scanning}

실시간 SAST 스캔을 활성화하려면 다음을 수행합니다:

1. **Extensions** > **GitLab**을 선택합니다.
1. **관리**({{< icon name="settings" >}})를 선택한 후 **설정** > **Code Security**를 선택합니다.
1. **Enable Real-time SAST scan** 확인란을 선택합니다.
1. 선택 사항. 파일을 저장할 때 활성 파일의 SAST 스캔을 활성화하려면 **Enable scanning on file save** 확인란을 선택합니다.

### SAST 스캔 수행 {#perform-sast-scanning}

전제 조건:

- GitLab for VS Code 5.31.0 이상
- 확장은 [GitLab으로 인증](setup.md#authenticate-with-gitlab)됩니다.
- 실시간 SAST 스캔이 활성화되어 있습니다.

VS Code에서 파일의 SAST 스캔을 수행하려면 다음을 수행합니다:

1. 파일을 엽니다.
1. 다음 중 하나로 SAST 스캔을 트리거합니다:
   - 파일을 저장합니다(파일 저장 시 스캔을 활성화한 경우).
   - 왼쪽 사이드바에서 **GitLab**({{< icon name="tanuki" >}}) > **GitLab remote scan (SAST)**를 선택합니다. 섹션 상단에서 **Scan current file** 버튼을 선택합니다.
   - 명령 팔레트 사용:
     1. 명령 팔레트를 여세요:
        - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
        - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
     1. **GitLab: Run Remote Scan (SAST)**을 검색한 후 <kbd>Enter</kbd>를 누릅니다.
1. SAST 스캔 결과를 확인합니다.
   1. VS Code의 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택하세요.
   1. GitLab remote scan (SAST) 섹션을 확장합니다. SAST 스캔 결과가 심각도 순서(내림차순)로 나열됩니다.
   1. 조사 결과를 선택하여 세부 정보를 검토합니다.
