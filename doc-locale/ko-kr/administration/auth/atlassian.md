---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Atlassian을 OAuth 2.0 인증 제공자로 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Atlassian OmniAuth 제공자를 암호 없는 인증으로 활성화하려면 Atlassian에 애플리케이션을 등록해야 합니다.

## Atlassian 애플리케이션 등록 {#atlassian-application-registration}

1. [Atlassian 개발자 콘솔](https://developer.atlassian.com/console/myapps/)로 이동하고 Atlassian 계정으로 로그인하여 애플리케이션을 관리합니다.
1. **Create a new app**를 선택합니다.
1. 'GitLab' 같은 앱 이름을 선택하고 **생성**을 선택합니다.
1. `Client ID` 및 `Secret`를 [GitLab 구성](#gitlab-configuration) 단계를 위해 기록해 둡니다.
1. 왼쪽 사이드바의 **APIS AND FEATURES** 아래에서 **OAuth 2.0 (3LO)**를 선택합니다.
1. `https://gitlab.example.com/users/auth/atlassian_oauth2/callback` 형식을 사용하여 GitLab 콜백 URL을 입력하고 **변경사항 저장**을 선택합니다.
1. 왼쪽 사이드바의 **APIS AND FEATURES** 아래에서 **\+ Add**를 선택합니다.
1. **Jira platform REST API**에 대해 **추가**를 선택한 후 **구성**을 선택합니다.
1. 다음 범위 옆에 **추가**를 선택합니다:
   - **View Jira issue data**
   - **View user profiles**
   - **Create and manage issues**

## GitLab 구성 {#gitlab-configuration}

1. GitLab 서버에서 구성 파일을 엽니다:

   Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. [공통 설정](../../integration/omniauth.md#configure-common-settings)을 구성하여 `atlassian_oauth2`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. Atlassian의 제공자 구성을 추가합니다:

   Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
     }
   ]
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
   - { name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
    }
   ```

1. `<your_client_id>` 및 `<your_client_secret>`를 [애플리케이션 등록](#atlassian-application-registration) 중에 받은 클라이언트 자격증명으로 변경합니다.
1. 구성 파일을 저장합니다.
1. 변경 사항을 적용하려면:
   - Linux 패키지를 사용하여 설치한 경우 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - 자체 컴파일하여 설치한 경우 [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에는 이제 일반 로그인 양식 아래에 Atlassian 아이콘이 있어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작합니다.

모든 작업이 제대로 진행되면 사용자는 Atlassian 자격증명을 사용하여 GitLab에 로그인됩니다.
