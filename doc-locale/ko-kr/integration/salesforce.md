---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Salesforce를 OAuth 2.0 인증 제공자로 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스를 [Salesforce](https://www.salesforce.com/)와 통합하여 사용자가 자신의 Salesforce 계정으로 GitLab 인스턴스에 로그인할 수 있도록 활성화할 수 있습니다.

## Salesforce 연결된 앱 만들기 {#create-a-salesforce-connected-app}

Salesforce OmniAuth 제공자를 활성화하려면 GitLab 인스턴스의 Salesforce 자격증명을 사용해야 합니다. 자격증명(클라이언트 ID 및 클라이언트 암호 쌍)을 얻으려면 Salesforce에서 [연결된 앱을 만들어야](https://help.salesforce.com/s/articleView?language=en_US&id=sf.connected_app_create.htm&type=5) 합니다.

1. [Salesforce](https://login.salesforce.com/)에 로그인합니다.
1. 설정에서 빠른 찾기 상자에 `App Manager`을 입력하고 **App Manager**를 선택한 다음 **New Connected App**을 선택합니다.
1. 다음 필드에 애플리케이션 세부 정보를 입력합니다:
   - **Connected App Name** 및 **API Name**: 모든 값으로 설정할 수 있지만 `<Organization>'s GitLab`, `<Your Name>'s GitLab` 또는 설명적인 다른 값을 고려하세요.
   - **Contact Email**: Salesforce에서 귀사 또는 지원팀에 문의할 때 사용할 연락처 이메일을 입력합니다.
   - **Description (설명)**: 애플리케이션 설명입니다.

   ![Salesforce App Details](img/salesforce_app_details_v11_11.png)
1. **API (Enable OAuth Settings)**를 선택한 다음 **Enable OAuth Settings**를 선택합니다.
1. 다음 필드에 애플리케이션 세부 정보를 입력합니다:
   - **콜백 URL**: GitLab 설치의 콜백 URL입니다. 예를 들어, `https://gitlab.example.com/users/auth/salesforce/callback`입니다.
   - **Selected OAuth Scopes**: `Access your basic information (id, profile, email, address, phone)` 및 `Allow access to your unique identifier (openid)`을 오른쪽 열로 이동합니다.

   ![Salesforce OAuth App Details](img/salesforce_oauth_app_details_v11_11.png)
1. **저장**을 선택합니다.
1. GitLab 서버에서 구성 파일을 엽니다.

   Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `salesforce`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 제공자 구성을 추가합니다. Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "salesforce",
       # label: "Provider name", # optional label for login button, defaults to "Salesforce"
       app_id: "SALESFORCE_CLIENT_ID",
       app_secret: "SALESFORCE_CLIENT_SECRET"
     }
   ]
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   - { name: 'salesforce',
       # label: 'Provider name', # optional label for login button, defaults to "Salesforce"
       app_id: 'SALESFORCE_CLIENT_ID',
       app_secret: 'SALESFORCE_CLIENT_SECRET'
   }
   ```

1. `SALESFORCE_CLIENT_ID`을 Salesforce 연결된 애플리케이션 페이지의 Consumer Key로 변경합니다.
1. `SALESFORCE_CLIENT_SECRET`을 Salesforce 연결된 애플리케이션 페이지의 Consumer Secret으로 변경합니다.

   ![Salesforce App Secret Details](img/salesforce_app_secret_details_v11_11.png)
1. 구성 파일을 저장합니다.
1. 변경 사항을 적용하려면:
   - Linux 패키지를 사용하여 설치한 경우 [GitLab을 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - 자체 컴파일된 설치의 경우 [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에서 이제 일반 로그인 양식 아래에 Salesforce 아이콘이 있어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작합니다. Salesforce에서 사용자에게 로그인하고 GitLab 애플리케이션을 승인하도록 요청합니다. 모든 작업이 잘 진행되면 사용자가 GitLab으로 반환되고 로그인됩니다.

> [!note]
> GitLab은 각 신규 사용자의 이메일 주소를 요구합니다. 사용자가 Salesforce를 사용하여 로그인한 후 GitLab에서 사용자를 프로필 페이지로 리디렉션하며, 사용자는 이메일을 제공하고 이메일을 확인해야 합니다.
