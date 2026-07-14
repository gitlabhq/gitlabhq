---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AWS Cognito를 OAuth 2.0 인증 공급자로 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Amazon Web Services(AWS) Cognito를 사용하면 새 사용자가 계정을 생성하고, 로그인하고, GitLab 인스턴스에 액세스할 수 있습니다. 다음 설명서는 AWS Cognito를 OAuth 2.0 공급자로 활성화합니다.

## AWS Cognito 구성 {#configure-aws-cognito}

[AWS Cognito](https://aws.amazon.com/cognito/) OAuth 2.0 OmniAuth 공급자를 활성화하려면 Cognito에 애플리케이션을 등록합니다. 이 프로세스는 애플리케이션의 클라이언트 ID와 클라이언트 보안 암호를 생성합니다. AWS Cognito를 인증 공급자로 활성화하려면 다음 단계를 완료합니다. 나중에 구성하는 설정을 수정할 수 있습니다.

1. [AWS 콘솔](https://console.aws.amazon.com/console/home)에 로그인합니다.
1. **서비스** 메뉴에서 **Cognito**를 선택합니다.
1. **Manage User Pools**를 선택한 다음 오른쪽 위 모서리에서 **Create a user pool**을 선택합니다.
1. 사용자 풀 이름을 입력한 다음 **Step through settings**을 선택합니다.
1. **How do you want your end users to sign in?** 아래에서 **Email address or phone number**를 선택하고 **Allow email addresses**을 선택합니다.
1. **Which standard attributes do you want to require?** 아래에서 **email**을 선택합니다.
1. 나머지 설정을 필요에 맞게 구성합니다. 기본 설정에서 이러한 설정은 GitLab 구성에 영향을 주지 않습니다.
1. **App clients** 설정에서:
   1. **Add an app client**를 선택합니다.
   1. **App client name**을 추가합니다.
   1. **Enable username password based authentication** 체크박스를 선택합니다.
1. **Create app client**을 선택합니다.
1. 이메일 전송을 위한 AWS Lambda 함수를 설정하고 사용자 풀 생성을 완료합니다.
1. 사용자 풀을 생성한 후 **App client settings**으로 이동하여 필수 정보를 제공합니다:

   - **Enabled Identity Providers** \- 모두 선택
   - **콜백 URL** - `https://<your_gitlab_instance_url>/users/auth/cognito/callback`
   - **Allowed OAuth Flows** \- 인증 코드 부여
   - **Allowed OAuth 2.0 Scopes** - `email`, `openid`, 및 `profile`

1. 앱 클라이언트 설정에 대한 변경 사항을 저장합니다.
1. **Domain name** 아래에 AWS Cognito 애플리케이션의 AWS 도메인 이름을 포함합니다.
1. **App Clients** 아래에서 앱 클라이언트 ID를 찾습니다. **세부 정보 보기**를 선택하여 앱 클라이언트 보안 암호를 표시합니다. 이러한 값은 OAuth 2.0 클라이언트 ID 및 클라이언트 보안 암호에 해당합니다. 이러한 값을 저장합니다.

## GitLab 구성 {#configure-gitlab}

1. [공통 설정](../../integration/omniauth.md#configure-common-settings)을 구성하여 `cognito`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. GitLab 서버에서 구성 파일을 엽니다. Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

1. 다음 코드 블록에서 다음 매개 변수에 AWS Cognito 애플리케이션 정보를 입력합니다:

   - `app_id`:  클라이언트 ID입니다.
   - `app_secret`:  클라이언트 보안 암호입니다.
   - `site`:  Amazon 도메인 및 지역입니다.

   `/etc/gitlab/gitlab.rb` 파일에 코드 블록을 포함합니다:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['cognito']
   gitlab_rails['omniauth_providers'] = [
     {
       name: "cognito",
       label: "Provider name", # optional label for login button, defaults to "Cognito"
       icon: nil,   # Optional icon URL
       app_id: "<client_id>",
       app_secret: "<client_secret>",
       args: {
         scope: "openid profile email",
         client_options: {
           site: "https://<your_domain>.auth.<your_region>.amazoncognito.com",
           authorize_url: "/oauth2/authorize",
           token_url: "/oauth2/token",
           user_info_url: "/oauth2/userInfo"
         },
         user_response_structure: {
           root_path: [],
           id_path: ["sub"],
           attributes: { nickname: "email", name: "email", email: "email" }
         },
         name: "cognito",
         strategy_class: "OmniAuth::Strategies::OAuth2Generic"
       }
     }
   ]
   ```

1. 구성 파일을 저장합니다.
1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

로그인 페이지에 이제 정규 로그인 양식 아래에 Cognito 옵션이 표시되어야 합니다. 이 옵션을 선택하여 인증 프로세스를 시작합니다. AWS Cognito가 GitLab 애플리케이션에 로그인하고 권한을 부여하라는 메시지를 표시합니다. 권한 부여가 성공하면 GitLab 인스턴스로 리디렉션되어 로그인됩니다.

자세한 내용은 [일반 설정 구성](../../integration/omniauth.md#configure-common-settings)을 참조하세요.
