---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: 도움말 페이지 메시지 사용자 지정
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

큰 조직에서는 누구에게 문의할지 또는 도움을 받을 수 있는 위치에 대한 정보를 제공하는 것이 유용합니다. 이 정보를 GitLab `/help` 페이지에서 사용자 지정하고 표시할 수 있습니다.

## 전제 조건 {#prerequisites}

관리자 액세스 권한이 있어야 합니다.

## 도움말 페이지에 도움말 메시지 추가 {#add-a-help-message-to-the-help-page}

도움말 메시지를 추가할 수 있으며, 이 메시지는 GitLab `/help` 페이지의 상단에 표시됩니다(예: <https://gitlab.com/help>):

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **도움말 페이지**를 펼칩니다.
1. **도움말 페이지에 표시할 추가 텍스트**에서 `/help`에 표시할 정보를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

이제 `/help`에서 메시지를 볼 수 있습니다.

> [!note]
> 기본적으로 `/help`는 인증되지 않은 사용자에게 표시됩니다. 그러나 [**공개** 표시 수준](visibility_and_access_controls.md#restrict-visibility-levels)이 제한되면 `/help`는 인증된 사용자에게만 표시됩니다.

## 로그인 페이지에 도움말 메시지 추가 {#add-a-help-message-to-the-sign-in-page}

{{< history >}}

- 로그인 페이지에 표시할 추가 텍스트는 GitLab 17.0에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/410885).

{{< /history >}}

로그인 페이지에 도움말 메시지를 추가하려면 [로그인 및 등록 페이지 사용자 지정](../appearance.md#customize-your-sign-in-and-register-pages)을 참조하세요.

## 도움말 페이지에서 마케팅 관련 항목 숨기기 {#hide-marketing-related-entries-from-the-help-page}

GitLab 마케팅 관련 항목이 도움말 페이지에 표시될 수 있습니다. 이러한 항목을 숨기려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **도움말 페이지**를 펼칩니다.
1. **도움말 페이지에서 마케팅 관련 항목 숨기기** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자 정의 지원 페이지 URL 설정 {#set-a-custom-support-page-url}

사용자가 다음을 수행할 때 사용자를 리디렉션할 사용자 정의 URL을 지정할 수 있습니다:

- **도움말** > **지원**을 선택합니다.
- 도움말 페이지에서 **도움이 필요하면 웹 사이트 참조하세요.**을 선택합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **도움말 페이지**를 펼칩니다.
1. **지원 페이지 URL** 텍스트 상자에 URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## `/help` 페이지 리디렉션 {#redirect-help-pages}

모든 `/help` 링크를 [필요한 요구 사항](#destination-requirements)을 충족하는 대상으로 리디렉션할 수 있습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **도움말 페이지**를 펼칩니다.
1. **문서 페이지 URL** 텍스트 상자에 URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

**문서 페이지 URL** 텍스트 상자가 비어 있으면 GitLab 인스턴스는 GitLab의 [`doc` 디렉터리](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)에서 제공하는 기본 문서 버전을 표시합니다.

### 대상 요구 사항 {#destination-requirements}

`/help`을 리디렉션할 때 GitLab은 다음을 수행합니다:

- 지정된 URL을 리디렉션의 기본 URL로 사용합니다.
- 다음을 수행하여 전체 URL을 구성합니다:
  - 버전 번호(`${VERSION}`)를 추가합니다.
  - 문서 경로를 추가합니다.
  - `.md` 파일 확장자를 제거합니다.

예를 들어 URL이 `https://docs.gitlab.com`로 설정되면 `/help/administration/settings/help_page.md`에 대한 요청이 `https://docs.gitlab.com/${VERSION}/administration/settings/help_page`로 리디렉션됩니다.
