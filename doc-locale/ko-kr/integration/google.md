---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google OAuth 2.0을 OAuth 2.0 인증 공급자로 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Google OAuth 2.0 OmniAuth 공급자를 활성화하려면 Google에 애플리케이션을 등록해야 합니다. Google이 사용할 클라이언트 ID와 보안 키를 생성합니다.

Google OAuth를 활성화하려면 다음을 구성해야 합니다:

- Google Cloud Resource Manager
- Google API Console
- GitLab 서버

## Google Cloud Resource Manager 구성 {#configure-the-google-cloud-resource-manager}

1. [Google Cloud Resource Manager](https://console.cloud.google.com/cloud-resource-manager)로 이동합니다.
1. **CREATE PROJECT**을 선택합니다.
1. **프로젝트 이름**에 `GitLab`을 입력합니다.
1. **프로젝트 ID**는 Google이 기본적으로 무작위로 생성된 프로젝트 ID를 제공합니다. 이 무작위로 생성된 ID를 사용하거나 새 ID를 생성할 수 있습니다. 새 ID를 생성하는 경우 모든 Google Developer 등록 애플리케이션에 고유해야 합니다.

목록에서 새 프로젝트를 보려면 페이지를 새로 고칩니다.

## Google API Console 구성 {#configure-the-google-api-console}

1. [Google API Console](https://console.developers.google.com/apis/dashboard)로 이동합니다.
1. 왼쪽 상단 모서리에서 이전에 생성한 프로젝트를 선택합니다.
1. **OAuth consent screen**을 선택하고 필드를 완료합니다.
1. **인증 정보** > **Create credentials** > **OAuth client ID**를 선택합니다.
1. 필드를 완성합니다:
   - **Application type**: **Web application**을 선택합니다.
   - **Name (이름)**: 기본 이름을 사용하거나 고유한 이름을 입력합니다.
   - **Authorized JavaScript origins**: `https://gitlab.example.com`를 입력합니다.
   - **Authorized redirect URIs**: 도메인 이름을 입력한 후 콜백 URI를 한 번에 하나씩 입력합니다:

     ```plaintext
     https://gitlab.example.com/users/auth/google_oauth2/callback
     https://gitlab.example.com/-/google_api/auth/callback
     ```

1. 클라이언트 ID와 클라이언트 보안이 표시됩니다. 나중에 필요하므로 이를 적어두거나 이 페이지를 열어 두십시오.
1. [Google Kubernetes Engine](../user/infrastructure/clusters/_index.md)에 액세스하도록 프로젝트를 활성화하려면 다음도 활성화해야 합니다:
   - Google Kubernetes Engine API
   - Cloud Resource Manager API
   - Cloud Billing API

   이렇게 하려면:

   1. [Google API Console](https://console.developers.google.com/apis/dashboard)로 이동합니다.
   1. 페이지 상단에서 **ENABLE APIS AND SERVICES**를 선택합니다.
   1. 이전에 언급한 각 API를 찾습니다. API 페이지에서 **ENABLE**를 선택합니다. API가 완전히 작동하는 데 몇 분이 걸릴 수 있습니다.

## GitLab 서버 구성 {#configure-the-gitlab-server}

1. 구성 파일을 엽니다.

   Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `google_oauth2`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 제공자 구성을 추가합니다.

   Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "google_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Google"
       app_id: "<YOUR_APP_ID>",
       app_secret: "<YOUR_APP_SECRET>",
       args: { access_type: "offline", approval_prompt: "" }
     }
   ]
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   - { name: 'google_oauth2',
       # label: 'Provider name', # optional label for login button, defaults to "Google"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { access_type: 'offline', approval_prompt: '' } }
   ```

1. `<YOUR_APP_ID>`을 Google Developer 페이지의 클라이언트 ID로 바꿉니다.
1. `<YOUR_APP_SECRET>`을 Google Developer 페이지의 클라이언트 보안으로 바꿉니다.
1. Google이 원시 IP 주소를 허용하지 않으므로 GitLab이 정규화된 도메인 이름을 사용하도록 구성했는지 확인합니다.

   Linux 패키지 설치의 경우:

   ```ruby
   external_url 'https://gitlab.example.com'
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   gitlab:
     host: https://gitlab.example.com
   ```

1. 구성 파일을 저장합니다.
1. 변경 사항을 적용하려면:
   - Linux 패키지를 사용하여 설치한 경우 [GitLab을 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - 자체 컴파일된 설치의 경우 [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에 일반 로그인 양식 아래에 Google 아이콘이 표시됩니다. 아이콘을 선택하여 인증 프로세스를 시작합니다. Google은 사용자에게 GitLab 애플리케이션에 로그인하고 권한을 부여하도록 요청합니다. 모든 것이 잘 진행되면 사용자가 GitLab으로 돌아가 로그인됩니다.
