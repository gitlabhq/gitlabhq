---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab에서 OIDC/OAuth 테스트
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab에서 OIDC/OAuth를 테스트하려면 다음을 수행해야 합니다:

1. [OIDC/OAuth 활성화](#enable-oidcoauth-in-gitlab)
1. [클라이언트 애플리케이션을 사용하여 OIDC/OAuth 테스트](#test-oidcoauth-with-your-client-application)
1. [OIDC/OAuth 인증 확인](#verify-oidcoauth-authentication)

## 필수 요구 사항 {#prerequisites}

GitLab에서 OIDC/OAuth를 테스트하기 전에 다음을 수행해야 합니다:

- 공개적으로 액세스 가능한 인스턴스가 있어야 합니다.
- 해당 인스턴스의 관리자여야 합니다.
- OIDC/OAuth를 테스트하는 데 사용할 클라이언트 애플리케이션이 있어야 합니다.

## GitLab에서 OIDC/OAuth 활성화 {#enable-oidcoauth-in-gitlab}

먼저 GitLab 인스턴스에서 OIDC/OAuth 애플리케이션을 만들어야 합니다. 다음을 수행하세요:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **응용 프로그램**을 선택합니다.
1. **새 애플리케이션 추가**를 선택합니다.
1. 이름, 리다이렉트 URI 및 허용된 범위를 포함하여 클라이언트 애플리케이션의 세부 정보를 입력합니다.
1. `openid` 범위가 활성화되어 있는지 확인합니다.
1. **애플리케이션 저장**을 선택하여 새 OAuth 애플리케이션을 만듭니다.

## 클라이언트 애플리케이션을 사용하여 OIDC/OAuth 테스트 {#test-oidcoauth-with-your-client-application}

GitLab에서 OAuth 애플리케이션을 만든 후 이를 사용하여 OIDC/OAuth를 테스트할 수 있습니다:

1. <https://openidconnect.net>을 OIDC/OAuth 플레이그라운드로 사용할 수 있습니다.
1. GitLab에서 로그아웃합니다.
1. 클라이언트 애플리케이션을 방문하고 이전 단계에서 만든 GitLab OAuth 애플리케이션을 사용하여 OIDC/OAuth 플로우를 시작합니다.
1. 프롬프트에 따라 GitLab에 로그인하고 클라이언트 애플리케이션이 GitLab 계정에 액세스할 수 있도록 승인합니다.
1. OIDC/OAuth 플로우를 완료한 후 클라이언트 애플리케이션은 GitLab에 인증하는 데 사용할 수 있는 액세스 토큰을 받아야 합니다.

## OIDC/OAuth 인증 확인 {#verify-oidcoauth-authentication}

OIDC/OAuth 인증이 GitLab에서 제대로 작동하는지 확인하려면 다음을 수행할 수 있습니다:

1. 이전 단계에서 받은 액세스 토큰이 유효하고 GitLab으로 인증하는 데 사용할 수 있는지 확인합니다. GitLab에 테스트 API 요청을 만들고 액세스 토큰을 사용하여 인증하여 이를 수행할 수 있습니다. 예를 들어:

   ```shell
   curl --header "Authorization: Bearer <access_token>" https://mygitlabinstance.com/api/v4/user
   ```

    `<access_token>`을 이전 단계에서 받은 실제 액세스 토큰으로 바꿉니다. API 요청이 성공하고 인증된 사용자의 정보를 반환하면 OIDC/OAuth 인증이 제대로 작동하고 있습니다.

1. OAuth 애플리케이션에서 지정한 범위가 제대로 적용되고 있는지 확인합니다. 특정 범위가 필요한 API 요청을 만들고 예상대로 성공 또는 실패하는지 확인하여 이를 수행할 수 있습니다.

이제 완료되었습니다! 이 단계를 통해 클라이언트 애플리케이션을 사용하여 GitLab 인스턴스에서 OIDC/OAuth 인증을 테스트할 수 있습니다.
