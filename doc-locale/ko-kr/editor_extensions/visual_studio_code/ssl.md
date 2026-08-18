---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 자체 서명된 인증서를 사용하여 VS Code 확장 프로그램 사용
---

GitLab 인스턴스가 자체 서명된 SSL 인증서를 사용하더라도 VS Code용 GitLab 확장 프로그램을 계속 사용할 수 있습니다.

프록시를 사용하여 GitLab 인스턴스에 연결하는 경우 [이슈 314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314)에서 알려주세요. 이 단계를 완료한 후에도 연결 문제가 있으면 [에픽 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)를 검토하세요. 이 에픽은 VS Code용 GitLab 확장 프로그램의 모든 기존 SSL 문제를 연결합니다.

## 자체 서명된 CA를 사용하여 확장 프로그램 사용 {#use-the-extension-with-a-self-signed-ca}

전제 조건:

- GitLab 인스턴스가 자체 서명된 인증 기관(CA)으로 서명된 인증서를 사용합니다.
- VS Code용 GitLab 버전이 6.51.1 이상입니다.
- VS Code 버전이 1.101.2(2025년 5월) 이상입니다.
- `gitlab.ca` VS Code 설정을 사용하고 있지 않습니다.

1. 확장 프로그램이 작동하도록 CA 인증서가 시스템에 올바르게 추가되었는지 확인합니다. VS Code는 시스템 인증서 저장소를 읽고 모든 노드 `http` 요청을 변경하여 인증서를 신뢰합니다:

   ```mermaid
   %%{init: { "fontFamily": "GitLab Sans" }}%%
   graph LR
      accTitle: Self-signed certificate chain
      accDescr: Shows a self-signed CA that signs the GitLab instance certificate.

      A[Self-signed CA] -- signed --> B[Your GitLab instance certificate]
   ```

   GitLab 인스턴스 인증서의 CA는 신뢰할 수 있는 CA로 명시적으로 지정되어야 합니다. 중간 인증서가 사용되는 경우 이러한 인증서를 시스템에서 사용할 수 있어야 합니다. 전체 인증서 체인의 유효성 검사가 성공하지 못하면 확장 프로그램 내의 네트워크 연결이 인증에 실패합니다.

   자세한 내용은 Visual Studio Code 이슈 추적기에서 [WSL에 Python 지원을 설치할 때 자체 서명된 인증서 오류](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815)를 참조하세요.

1. VS Code `settings.json`에서 `"http.systemCertificates": true`를 설정합니다. 기본값은 `true`이므로 이 값을 변경할 필요가 없을 수 있습니다.
1. 운영 체제에 대한 다음 섹션의 지침을 완료합니다.

### Windows {#windows}

> [!note]
> 이 지침은 Windows 10 및 VS Code 1.60.0에서 테스트되었습니다.

인증서 저장소에서 자체 서명된 CA를 볼 수 있는지 확인합니다:

1. 명령 프롬프트를 엽니다.
1. `certmgr`를 실행합니다.
1. **Trusted Root Certification Authorities** > **인증서**에서 인증서를 볼 수 있는지 확인합니다.

### Linux {#linux}

> [!note]
> 이 지침은 Arch Linux `5.14.3-arch1-1` 및 VS Code 1.60.0에서 테스트되었습니다.

1. 운영 체제 도구를 사용하여 자체 서명된 CA를 시스템에 추가할 수 있는지 확인합니다:
   - `update-ca-trust` (Fedora, RHEL, CentOS)
   - `update-ca-certificates` (Ubuntu, Debian, OpenSUSE, SLES)
   - `trust` (Arch)
1. CA 인증서가 `/etc/ssl/certs/ca-certificates.crt` 또는 `/etc/ssl/certs/ca-bundle.crt`에 있는지 확인합니다. VS Code는 [이 위치를 확인](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815)합니다.

### MacOS {#macos}

> [!note]
> 이 지침은 macOS Tahoe 26, VS Code 1.101.2 및 VS Code용 GitLab 6.51.1에서 테스트되었습니다.

키체인에서 자체 서명된 CA를 볼 수 있는지 확인합니다:

1. **Finder** > **응용 프로그램** > **Utilities** > **Keychain Access**으로 이동합니다.
1. 왼쪽 열에서 **시스템**을 선택합니다.
1. 목록에서 자체 서명된 CA 인증서를 찾습니다.
1. 인증서를 마우스 오른쪽 단추로 클릭하고 **Get Info**를 선택합니다.
1. **Trust** 섹션을 확장합니다.
1. **Secure Sockets Layer (SSL)** 옵션이 '항상 신뢰'로 설정되었는지 확인합니다.
