---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Generic OAuth2 gem을 OAuth 2.0 인증 공급자로 사용하기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> 공급자가 OpenID 사양을 지원하는 경우 인증 공급자로 [`omniauth-openid-connect`](../administration/auth/oidc.md)를 사용해야 합니다.

[`omniauth-oauth2-generic` gem](https://gitlab.com/satorix/omniauth-oauth2-generic)은 GitLab과 OAuth 2.0 공급자 또는 이 gem과 호환되는 모든 OAuth 2.0 공급자 간의 단일 로그온(SSO)을 지원합니다.

이 전략을 통해 OmniAuth SSO 프로세스를 구성할 수 있습니다:

1. 전략은 클라이언트를 인증 URL(**configurable**)로 지정된 ID 및 키와 함께 전달합니다.
1. OAuth 2.0 공급자는 요청, 사용자 및 (선택적으로) 사용자 프로필에 액세스하기 위한 권한 부여의 인증을 처리합니다.
1. OAuth 2.0 공급자는 클라이언트를 GitLab으로 다시 전달합니다. 여기서 전략은 액세스 토큰을 검색합니다.
1. 전략은 액세스 토큰을 사용하여 **configurable**한 "사용자 프로필" URL에서 사용자 정보를 요청합니다.
1. 전략은 **configurable**한 형식을 사용하여 응답에서 사용자 정보를 구문 분석합니다.
1. GitLab은 반환된 사용자를 찾거나 생성하고 사용자를 로그인시킵니다.

이 전략:

- 단일 로그온에만 사용할 수 있으며, 모든 OAuth 2.0 공급자에 의해 부여된 다른 액세스는 제공하지 않습니다. 예를 들어 프로젝트 또는 사용자를 가져오기합니다.
- GitLab 같은 클라이언트-서버 애플리케이션에 가장 일반적인 권한 부여 그래프 흐름만 지원합니다.
- 둘 이상의 URL에서 사용자 정보를 가져올 수 없습니다.
- JWT 형식의 액세스 토큰에서 사용자 정보를 가져올 수 없습니다.
- JSON을 제외한 사용자 정보 형식으로 테스트되지 않았습니다.

## OAuth 2.0 공급자 구성 {#configure-the-oauth-20-provider}

공급자를 구성하려면:

1. 인증할 OAuth 2.0 공급자에 애플리케이션을 등록합니다.

   애플리케이션을 등록할 때 제공하는 리다이렉트 URI는 다음과 같아야 합니다:

   ```plaintext
   http://your-gitlab.host.com/users/auth/oauth2_generic/callback
   ```

   이제 클라이언트 ID 및 클라이언트 시크릿을 가져올 수 있습니다. 이들이 나타나는 위치는 공급자마다 다릅니다. 이를 애플리케이션 ID 및 애플리케이션 시크릿이라고 할 수도 있습니다.
1. GitLab 서버에서 다음 단계를 완료합니다.

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `oauth2_generic`을 단일 로그인 공급자로 추가하세요. 이를 통해 기존 GitLab 계정이 없는 사용자를 위해 Just-In-Time 계정 프로비저닝이 활성화됩니다.
   1. `/etc/gitlab/gitlab.rb`을 편집하여 공급자의 구성을 추가합니다. 예를 들어:

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          name: "oauth2_generic",
          label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
          app_id: "<your_app_client_id>",
          app_secret: "<your_app_client_secret>",
          args: {
            client_options: {
              site: "<your_auth_server_url>",
              user_info_url: "/oauth2/v1/userinfo",
              authorize_url: "/oauth2/v1/authorize",
              token_url: "/oauth2/v1/token"
            },
            user_response_structure: {
              root_path: [],
              id_path: ["sub"],
              attributes: {
                email: "email",
                name: "name"
              }
            },
            authorize_params: {
              scope: "openid profile email"
            },
            strategy_class: "OmniAuth::Strategies::OAuth2Generic"
          }
        }
      ]
      ```

   1. 파일을 저장하고 GitLab을 다시 구성합니다.

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

   1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `oauth2_generic`을 단일 로그인 공급자로 추가하세요. 이를 통해 기존 GitLab 계정이 없는 사용자를 위해 Just-In-Time 계정 프로비저닝이 활성화됩니다.
   1. Helm 값을 내보냅니다:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용하기 위해 다음 콘텐츠를 `oauth2_generic.yaml` 파일에 배치합니다:

      ```yaml
      name: "oauth2_generic"
      label: "Provider name" # optional label for login button defaults to "Oauth2 Generic"
      app_id: "<your_app_client_id>"
      app_secret: "<your_app_client_secret>"
      args:
        client_options:
          site: "<your_auth_server_url>"
          user_info_url: "/oauth2/v1/userinfo"
          authorize_url: "/oauth2/v1/authorize"
          token_url: "/oauth2/v1/token"
        user_response_structure:
          root_path: []
          id_path: ["sub"]
          attributes:
            email: "email"
            name: "name"
        authorize_params:
          scope: "openid profile email"
        strategy_class: "OmniAuth::Strategies::OAuth2Generic"
      ```

   1. Kubernetes Secret을 생성합니다:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-oauth2-generic --from-file=provider=oauth2_generic.yaml
      ```

   1. `gitlab_values.yaml`을 편집하고 공급자 구성을 추가합니다:

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-oauth2-generic
      ```

   1. 파일을 저장하고 새 값을 적용합니다:

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   {{< /tab >}}

   {{< tab title="Self-compiled(source)" >}}

   1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `oauth2_generic`을 단일 로그인 공급자로 추가하세요. 이를 통해 기존 GitLab 계정이 없는 사용자를 위해 Just-In-Time 계정 프로비저닝이 활성화됩니다.
   1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다.

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: "oauth2_generic",
                label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
                app_id: "<your_app_client_id>",
                app_secret: "<your_app_client_secret>",
                args: {
                  client_options: {
                    site: "<your_auth_server_url>",
                    user_info_url: "/oauth2/v1/userinfo",
                    authorize_url: "/oauth2/v1/authorize",
                    token_url: "/oauth2/v1/token"
                  },
                  user_response_structure: {
                    root_path: [],
                    id_path: ["sub"],
                    attributes: {
                      email: "email",
                      name: "name"
                    }
                  },
                  authorize_params: {
                    scope: "openid profile email"
                  },
                  strategy_class: "OmniAuth::Strategies::OAuth2Generic"
                }
              }
      ```

   1. 파일을 저장하고 GitLab을 다시 시작합니다.

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   {{< /tab >}}

   {{< /tabs >}}

로그인 페이지에 일반 로그인 양식 아래에 새 아이콘이 표시되어야 합니다. 해당 아이콘을 선택하여 공급자의 인증 프로세스를 시작합니다. 이는 브라우저를 OAuth 2.0 공급자의 인증 페이지로 전달합니다. 모든 것이 정상적으로 진행되면 GitLab 인스턴스로 돌아가 로그인됩니다.
