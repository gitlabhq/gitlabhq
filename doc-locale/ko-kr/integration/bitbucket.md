---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 서버를 Bitbucket Cloud와 통합
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Bitbucket.org을 OAuth 2.0 공급자로 설정하여 Bitbucket.org 계정 자격 증명을 사용하여 GitLab에 로그인할 수 있습니다. 또한 Bitbucket.org에서 프로젝트를 가져올 수도 있습니다.

- Bitbucket.org을 OmniAuth 공급자로 사용하려면 [Bitbucket OmniAuth 공급자](#use-bitbucket-as-an-oauth-20-authentication-provider) 섹션을 따르세요.
- Bitbucket에서 프로젝트를 가져오려면 [Bitbucket OmniAuth 공급자](#use-bitbucket-as-an-oauth-20-authentication-provider) 및 [Bitbucket 프로젝트 가져오기](#bitbucket-project-import) 섹션을 모두 따르세요.

## Bitbucket을 OAuth 2.0 인증 공급자로 사용 {#use-bitbucket-as-an-oauth-20-authentication-provider}

Bitbucket OmniAuth 공급자를 활성화하려면 Bitbucket.org에 애플리케이션을 등록해야 합니다. Bitbucket은 사용할 애플리케이션 ID와 비밀 키를 생성합니다.

1. [Bitbucket.org](https://bitbucket.org)에 로그인하세요.
1. 개인 사용자 설정(**Bitbucket settings**) 또는 팀의 설정(**Manage team**)으로 이동하세요. 애플리케이션을 등록하는 방법은 귀하에게 달려 있습니다. 애플리케이션을 개인으로 등록하거나 팀으로 등록하는 것은 중요하지 않으며, 전적으로 귀하의 선택입니다.
1. 왼쪽 메뉴의 **Access Management** 아래에서 **OAuth**를 선택하세요.
1. **Add consumer**를 선택하세요.
1. 필수 세부 정보를 입력하세요:

   - **Name (이름)**: 아무것이나 가능합니다. `<Organization>'s GitLab` 또는 `<Your Name>'s GitLab` 같은 항목이나 다른 설명적인 항목을 고려하세요.
   - **Application description**: 선택 사항. 필요한 경우 입력하세요.
   - **콜백 URL**: (GitLab 버전 8.15 이상 필수) `https://gitlab.example.com/users/auth`와 같은 GitLab 설치 URL입니다. 이 필드를 비워두면 `Invalid redirect_uri` 메시지가 나타납니다.

     > [!warning]
     > [OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/) 공격을 방지하려면 Bitbucket 인증 콜백 URL의 끝에 `/users/auth`을 추가하세요. Bitbucket을 인증하고 Bitbucket 리포지토리에서 데이터를 가져오려면 이 인증 엔드포인트를 포함해야 합니다.

   - **URL**: `https://gitlab.example.com`와 같은 GitLab 설치 URL입니다.

1. 최소한 다음 권한을 부여하세요:

   - **계정**: `Email`, `Read`
   - **프로젝트**: `Read`
   - **리포지토리**: `Read`
   - **Pull Requests**: `Read`
   - **이슈**: `Read`
   - **Wikis**: `Read and write`

1. **저장**을 선택합니다.
1. 새로 생성한 OAuth 소비자를 선택하면 이제 OAuth 소비자 목록에서 **키** 및 **비밀**이 표시되어야 합니다. 설정을 계속하면서 이 페이지를 열어 둡니다.
1. GitLab 서버에서 설정 파일을 엽니다:

   ```shell
   # For Omnibus packages
   sudo editor /etc/gitlab/gitlab.rb

   # For installations from source
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Bitbucket 공급자 설정을 추가합니다:

   Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "bitbucket",
       # label: "Provider name", # optional label for login button, defaults to "Bitbucket"
       app_id: "<bitbucket_app_key>",
       app_secret: "<bitbucket_app_secret>",
       url: "https://bitbucket.org/"
     }
   ]
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   omniauth:
     enabled: true
     providers:
       - { name: 'bitbucket',
           # label: 'Provider name', # optional label for login button, defaults to "Bitbucket"
           app_id: '<bitbucket_app_key>',
           app_secret: '<bitbucket_app_secret>',
           url: 'https://bitbucket.org/'
         }
   ```

   `<bitbucket_app_key>`은 Bitbucket 애플리케이션 페이지의 **키**이고 `<bitbucket_app_secret>`은 **비밀**입니다.
1. 구성 파일을 저장합니다.
1. 변경 사항을 적용하려면 Linux 패키지를 사용하여 설치한 경우 [GitLab 재설정](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하거나, 자체 컴파일된 설치의 경우 [재시작](../administration/restart_gitlab.md#self-compiled-installations)을 수행하세요.

로그인 페이지에는 이제 일반 로그인 양식 아래에 Bitbucket 아이콘이 표시되어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작합니다. Bitbucket이 사용자에게 로그인하고 GitLab 애플리케이션을 승인하도록 요청합니다. 성공하면 사용자가 GitLab으로 돌아가 로그인됩니다.

> [!note]
> 다중 노드 아키텍처의 경우 프로젝트를 가져올 수 있도록 Bitbucket 공급자 설정을 Sidekiq 노드에도 포함해야 합니다.

## Bitbucket 프로젝트 가져오기 {#bitbucket-project-import}

이전 설정이 완료되면 Bitbucket을 사용하여 GitLab에 로그인하고 [프로젝트 가져오기를 시작](../user/import/bitbucket_cloud.md)할 수 있습니다.

Bitbucket에서 프로젝트를 가져오되 로그인을 활성화하지 않으려면 [**운영자** 영역에서 로그인 비활성화](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources)할 수 있습니다.
