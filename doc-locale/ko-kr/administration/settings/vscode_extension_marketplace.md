---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed 인스턴스의 기능을 위해 VS Code Extension Marketplace를 구성합니다.
title: VS Code Extension Marketplace 구성
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

VS Code Extension Marketplace는 Web IDE 및 워크스페이스의 기능을 향상시키는 확장 프로그램에 대한 액세스를 제공합니다. 관리자는 전체 인스턴스에 대해 마켓플레이스 액세스를 구성할 수 있습니다.

> [!note]
> VS Code Extension Marketplace에 액세스하려면 브라우저가 `*.cdn.web-ide.gitlab-static.net` 자산 호스트에 액세스할 수 있어야 합니다. 이 보안 요구 사항은 타사 확장 프로그램이 격리된 상태에서 실행되고 계정에 액세스할 수 없도록 보장합니다.

## VS Code Extension Marketplace 설정에 액세스 {#access-vs-code-extension-marketplace-settings}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

VS Code Extension Marketplace 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **VS Code Extension Marketplace**를 확장합니다.

## 확장 레지스트리 활성화 {#enable-the-extension-registry}

기본적으로 GitLab 인스턴스는 [Open VSX](https://open-vsx.org/) 확장 레지스트리를 사용하도록 구성됩니다. 이 기본 구성으로 확장 마켓플레이스를 활성화하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

확장 마켓플레이스를 활성화하려면:

1. [VS Code Extension Marketplace 설정](#access-vs-code-extension-marketplace-settings)으로 이동합니다.
1. **확장 마켓플레이스 활성화** 토글을 켭니다.

## 확장 레지스트리 수정 {#modify-the-extension-registry}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

확장 레지스트리를 수정하려면:

1. [VS Code Extension Marketplace 설정](#access-vs-code-extension-marketplace-settings)으로 이동합니다.
1. **확장 레지스트리 설정**을 확장합니다.
1. **Open VSX 확장 레지스트리 사용** 토글을 끕니다.
1. VS Code 확장 레지스트리의 **서비스 URL**, **항목 URL**, 및 **리소스 URL 템플릿**에 대한 전체 URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

확장 레지스트리를 수정한 후:

- 활성 Web IDE 또는 워크스페이스 세션은 새로 고쳐질 때까지 이전 레지스트리를 계속 사용합니다.
- 모든 사용자는 확장을 사용하기 전에 [계정을 새 레지스트리와 통합](../../user/profile/preferences.md#integrate-with-the-extension-marketplace)해야 합니다.
