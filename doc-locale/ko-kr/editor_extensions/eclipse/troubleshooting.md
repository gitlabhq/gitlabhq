---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Eclipse에서 GitLab Duo를 연결하고 사용합니다.
title: Eclipse 문제 해결
---

{{< details >}}

- 티어:  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- [GitLab 17.11에서 실험에서 베타로 변경되었습니다](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163).
- GitLab 19.0의 일부로 2026년 5월 21일부터 GitLab Duo Core 고객을 대상으로 GitLab Duo Non-Agentic Chat 액세스가 제거됨(`no_duo_classic_for_duo_core_users` 기능 플래그 사용). 기본적으로 활성화됨.

{{< /history >}}

> [!disclaimer]

이 페이지의 단계로 문제가 해결되지 않으면 Eclipse 플러그인 프로젝트의 [열린 이슈 목록](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)을 확인합니다. 이슈가 문제와 일치하면 해당 이슈를 업데이트하세요. 일치하는 이슈가 없으면 [새 이슈를 생성](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/new)하고 [필수 지원 정보](#required-information-for-support)를 포함합니다.

## 오류 로그 검토 {#review-the-error-log}

1. IDE의 메뉴 표시줄에서 **Window**를 선택합니다.
1. **Show View**를 확장한 다음 **Error Log**를 선택합니다.
1. `gitlab-eclipse-plugin` 플러그인을 참조하는 오류를 검색합니다.

## Eclipse 워크스페이스 로그 파일 찾기 {#locate-the-eclipse-workspace-log-file}

`.log`이라는 Eclipse 워크스페이스 로그 파일은 `<your-eclipse-workspace>/.metadata` 디렉토리에 위치합니다.

## GitLab Language Server 디버그 로그 활성화 {#enable-gitlab-language-server-debug-logs}

GitLab Language Server 디버그 로그를 활성화하려면:

1. IDE에서 환경설정을 엽니다:
   - macOS의 경우 **Eclipse** > **설정**을 선택합니다.
   - Windows 또는 Linux의 경우 **Window** > **환경설정**을 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Language Server Log Level**에서 `debug`을 입력합니다.
1. **Apply and Close**를 선택합니다.

디버그 로그는 `language_server.log` 파일에서 사용할 수 있습니다. 이 파일을 보려면 다음 중 하나를 수행하세요:

- 다음 디렉토리로 이동하여 `<user>`과(와) `<eclipse-version>`를 적절한 값으로 바꿉니다:
  - macOS의 경우: `/Users/<user>/eclipse-workspace/.metadata/.plugins/com.gitlab.eclipse.gitlab-eclipse-plugin`
  - Windows의 경우: `<drive>:\Users\<user>\eclipse-workspace\.metadata\.plugins\com.gitlab.eclipse.gitlab-eclipse-plugin`
  - Linux의 경우: `/home/<user>/eclipse-workspace/.metadata/.plugins/com.gitlab.eclipse.gitlab-eclipse-plugin`
- **Error Log**를 엽니다. `Language server logs saved to: <file>.` 로그를 검색합니다. 여기서 `<file>`은(는) `language_server.log` 파일의 절대 경로입니다.

## 지원에 필요한 정보 {#required-information-for-support}

지원 요청을 생성할 때 다음 정보를 제공합니다:

1. 현재 GitLab for Eclipse 플러그인 버전입니다.
   1. IDE에서 `About Eclipse` 대화 상자를 엽니다.
      - macOS의 경우 **Eclipse** > **About Eclipse**를 선택합니다.
      - Windows 또는 Linux의 경우 **도움말** > **About Eclipse IDE**를 선택합니다.
   1. **Installation details**를 선택합니다.
   1. **GitLab for Eclipse**를 찾고 **버전** 값을 복사합니다.
1. Eclipse 버전입니다.
   1. IDE에서 `About Eclipse` 대화 상자를 엽니다.
      - macOS의 경우 **Eclipse** > **About Eclipse**를 선택합니다.
      - Windows 또는 Linux의 경우 **도움말** > **About Eclipse IDE**를 선택합니다.
1. 운영 체제입니다.
1. GitLab.com, GitLab Self-Managed 또는 GitLab Dedicated 인스턴스를 사용하고 있습니까?
1. 프록시를 사용하고 있습니까?
1. 자체 서명 인증서를 사용하고 있습니까?
1. Eclipse 워크스페이스 로그입니다.
1. Language Server 디버그 로그입니다.
1. 해당하는 경우 이슈의 비디오 또는 스크린샷입니다.
1. 해당하는 경우 이슈를 재현하는 단계입니다.
1. 해당하는 경우 이슈를 해결하려고 시도한 단계입니다.

## 인증서 오류 {#certificate-errors}

머신이 프록시를 통해 GitLab 인스턴스에 연결하면 Eclipse에서 SSL 인증서 오류가 발생할 수 있습니다. GitLab Duo는 시스템 저장소에서 인증서를 감지하려고 시도하지만 Language Server는 할 수 없습니다. Language Server에서 인증서에 대한 오류가 표시되면 인증 기관(CA) 인증서를 전달하는 옵션을 활성화해 보세요:

이를 수행하려면:

1. IDE의 오른쪽 아래 모서리에서 GitLab 아이콘을 선택하세요.
1. 대화 상자에서 **Show Settings**를 선택하세요. 이것은 **설정** 대화 상자를 **도구** > **GitLab Duo**로 엽니다.
1. **GitLab Language Server**를 선택하여 섹션을 확장하세요.
1. **HTTP Agent Options**을 선택하여 확장하세요.
1. 다음 중 하나를 수행합니다.
   - **Language Server** 아래에서 **CA certificate**에 대해 **탐색**을 선택하고 CA 인증서가 포함된 `.pem` 파일을 선택합니다.
   - **연결** 아래에서 **Ignore Certificate Errors** 확인란을 선택합니다.
1. **Apply and Close**를 선택합니다.

### 인증서 오류 무시 {#ignore-certificate-errors}

GitLab Duo가 계속 연결에 실패하면 인증서 오류를 무시해야 할 수도 있습니다. 디버그 모드를 활성화한 후 GitLab Language Server 로그에서 오류가 표시될 수 있습니다:

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

설계상 이 설정은 보안 위험을 나타냅니다. 이 오류는 잠재적 보안 위반을 알려줍니다. 프록시가 문제의 원인임을 절대적으로 확신하는 경우에만 이 설정을 활성화해야 합니다.

전제 조건:

- 시스템 브라우저에서 인증서 체인을 확인했거나 머신 관리자가 이 오류를 무시해도 안전함을 확인했습니다.

이를 수행하려면:

1. SSL 인증서에 대한 Eclipse 설명서를 참조합니다.
1. IDE에서 환경설정을 엽니다:
   - macOS의 경우 **Eclipse** > **설정**을 선택합니다.
   - Windows 또는 Linux의 경우 **Window** > **환경설정**을 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. 기본 브라우저가 **URL to GitLab instance** 값을 신뢰하는지 확인합니다.
1. **Ignore certificate errors** 확인란을 선택합니다.
1. **Verify Setup**을 선택합니다.
1. **Apply and Close**를 선택합니다.
