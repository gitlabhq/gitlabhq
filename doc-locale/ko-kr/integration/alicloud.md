---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OmniAuth 인증 공급자로 AliCloud 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

AliCloud OAuth 2.0 OmniAuth 공급자를 활성화하고 AliCloud 계정을 사용하여 GitLab에 로그인할 수 있습니다.

## AliCloud 애플리케이션 생성 {#create-an-alicloud-application}

AliCloud 플랫폼에 로그인하고 이 플랫폼에서 애플리케이션을 생성합니다. AliCloud가 사용할 클라이언트 ID와 비밀 키를 생성합니다.

1. [AliCloud 플랫폼](https://account.aliyun.com/login/login.htm)에 로그인합니다.
1. [OAuth 애플리케이션 관리 페이지](https://ram.console.aliyun.com/applications)로 이동합니다.
1. **Create Application**을 선택합니다.
1. 애플리케이션 세부 정보를 입력합니다:

   - **Application Name**: 아무것이나 가능합니다.
   - **Display Name**: 아무것이나 가능합니다.
   - **콜백 URL**: 이 URL은`'GitLab instance URL' + '/users/auth/alicloud/callback'`의 형식으로 지정되어야 합니다. 예를 들어, `http://test.gitlab.com/users/auth/alicloud/callback`입니다.

   **저장**을 선택합니다.
1. 애플리케이션 세부 정보 페이지에서 OAuth 범위를 추가합니다:

   1. **Application Name** 열에서 생성한 애플리케이션의 이름을 선택합니다. 애플리케이션의 세부 정보 페이지가 열립니다.
   1. **Application OAuth Scopes** 탭 아래에서 **Add OAuth Scopes**를 선택합니다.
   1. **aliuid** 및 **profile** 확인란을 선택합니다.
   1. **확인**을 선택합니다.

   ![AliCloud OAuth 범위](img/alicloud_scope_v14_10.png)
1. 애플리케이션 세부 정보 페이지에서 비밀을 생성합니다:

   1. **App Secrets** 탭 아래에서 **Create Secret**을 선택합니다.
   1. 생성된 SecretValue를 복사합니다.

## GitLab에서 AliCloud OAuth 활성화 {#enable-alicloud-oauth-in-gitlab}

1. GitLab 서버에서 구성 파일을 엽니다.

   - Linux 패키지 설치의 경우:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - 자체 컴파일된 설치의 경우:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `alicloud`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 제공자 구성을 추가합니다. `YOUR_APP_ID`을(를) 애플리케이션 세부 정보 페이지의 ID로 바꾸고 `YOUR_APP_SECRET`을(를) AliCloud 애플리케이션을 등록할 때 얻은 **SecretValue**로 바꿉니다.

   - Linux 패키지 설치의 경우:

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "alicloud",
           app_id: "YOUR_APP_ID",
           app_secret: "YOUR_APP_SECRET"
         }
       ]
     ```

   - 자체 컴파일된 설치의 경우:

     ```yaml
     - { name: 'alicloud',
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET' }
     ```

1. 구성 파일을 저장합니다.
1. Linux 패키지를 사용하여 설치한 경우 [GitLab 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하거나, 소스에서 설치한 경우 [GitLab 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)을 수행합니다.
