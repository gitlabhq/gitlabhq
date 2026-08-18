---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitHub을 OAuth 2.0 인증 공급자로 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스를 GitHub.com 및 GitHub Enterprise와 통합할 수 있습니다. GitHub에서 프로젝트를 가져오거나 GitHub 자격 증명으로 GitLab에 로그인할 수 있습니다.

## GitHub에서 OAuth 앱 생성 {#create-an-oauth-app-in-github}

GitHub OmniAuth 공급자를 활성화하려면 GitHub에서 OAuth 2.0 클라이언트 ID 및 클라이언트 시크릿이 필요합니다:

1. GitHub에 로그인하세요.
1. [OAuth 앱 생성](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)을 수행하고 다음 정보를 제공하세요:
   - GitLab 인스턴스의 URL(예: `https://gitlab.example.com`)입니다.
   - 권한 부여 콜백 URL(예: `https://gitlab.example.com/users/auth`)입니다. GitLab 인스턴스에서 기본이 아닌 포트를 사용하는 경우 포트 번호를 포함하세요.

### 보안 취약성 확인 {#check-for-security-vulnerabilities}

일부 통합의 경우 [OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/) 취약성이 GitLab 계정을 손상시킬 수 있습니다. 이 취약성을 완화하려면 권한 부여 콜백 URL에 `/users/auth`을 추가하세요.

그러나 GitHub는 `redirect_uri`의 하위 도메인 부분을 검증하지 않습니다. 따라서 웹사이트의 모든 하위 도메인에서 발생하는 하위 도메인 인수, XSS 또는 오픈 리디렉션이 covert redirect 공격을 가능하게 할 수 있습니다.

## GitLab에서 GitHub OAuth 활성화 {#enable-github-oauth-in-gitlab}

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `github`을 단일 로그인 공급자로 추가하세요. 이를 통해 기존 GitLab 계정이 없는 사용자를 위해 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 다음 정보를 사용하여 GitLab 구성 파일을 편집합니다:

   | GitHub 설정 | GitLab 구성 파일의 값 | 설명             |
   |----------------|----------------------------------------|-------------------------|
   | 클라이언트 ID      | `YOUR_APP_ID`                          | OAuth 2.0 클라이언트 ID     |
   | 클라이언트 시크릿  | `YOUR_APP_SECRET`                      | OAuth 2.0 클라이언트 시크릿 |
   | URL            | `https://github.example.com/`          | GitHub 배포 URL   |

   - Linux 패키지 설치의 경우:

     1. `/etc/gitlab/gitlab.rb` 파일을 여세요.

        GitHub.com의 경우 다음 섹션을 업데이트합니다:

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            args: { scope: "user:email" }
          }
        ]
        ```

        GitHub Enterprise의 경우 다음 섹션을 업데이트하고 `https://github.example.com/`을 GitHub URL로 바꾸세요:

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            url: "https://github.example.com/",
            args: { scope: "user:email" }
          }
        ]
        ```

     1. 파일을 저장하고 GitLab을 [재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

   - 자체 컴파일된 설치의 경우:

     1. `config/gitlab.yml` 파일을 여세요.

        GitHub.com의 경우 다음 섹션을 업데이트합니다:

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            args: { scope: 'user:email' } }
        ```

        GitHub Enterprise의 경우 다음 섹션을 업데이트하고 `https://github.example.com/`을 GitHub URL로 바꾸세요:

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            url: "https://github.example.com/",
            args: { scope: 'user:email' } }
        ```

     1. 파일을 저장하고 GitLab을 [다시 시작](../administration/restart_gitlab.md#self-compiled-installations)합니다.

1. GitLab 로그인 페이지를 새로 고칩니다. GitHub 아이콘이 로그인 양식 아래에 표시됩니다.
1. 아이콘을 선택하세요. GitHub에 로그인하고 GitLab 애플리케이션을 승인하세요.

## 문제 해결 {#troubleshooting}

### 자체 서명된 인증서가 있는 GitHub Enterprise에서의 가져오기 실패 {#imports-from-github-enterprise-with-a-self-signed-certificate-fail}

자체 서명된 인증서를 사용하여 GitHub Enterprise에서 프로젝트를 가져올 때 가져오기가 실패합니다.

이 이슈를 해결하려면 SSL 검증을 비활성화해야 합니다:

1. 구성 파일에서 `verify_ssl`을 `false`로 설정하세요.

   - Linux 패키지 설치의 경우:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "github",
         # label: "Provider name", # optional label for login button, defaults to "GitHub"
         app_id: "YOUR_APP_ID",
         app_secret: "YOUR_APP_SECRET",
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: "user:email" }
       }
     ]
     ```

   - 자체 컴파일된 설치의 경우:

     ```yaml
     - { name: 'github',
         # label: 'Provider name', # optional label for login button, defaults to "GitHub"
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET',
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: 'user:email' } }
     ```

1. GitLab 서버에서 전역 Git `sslVerify` 옵션을 `false`로 변경하세요.

   - [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) 이상을 실행하는 Linux 패키지 설치의 경우:

     ```ruby
     gitaly['gitconfig'] = [
        {key: "http.sslVerify", value: "false"},
     ]
     ```

   - GitLab 15.2 이하를 실행하는 Linux 패키지 설치의 경우(레거시 방법):

     ```ruby
     omnibus_gitconfig['system'] = { "http" => ["sslVerify = false"] }
     ```

   - [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) 이상을 실행하는 자체 컴파일된 설치의 경우 Gitaly 구성(`gitaly.toml`)을 편집하세요:

     ```toml
     [[git.config]]
     key = "http.sslVerify"
     value = "false"
     ```

   - GitLab 15.2 이하를 실행하는 자체 컴파일된 설치의 경우(레거시 방법):

     ```shell
     git config --global http.sslVerify false
     ```

1. Linux 패키지를 사용하여 설치한 경우 [GitLab을 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)하거나 자체 컴파일한 설치의 경우 [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)하세요.

### GitHub Enterprise를 사용한 로그인 시 500 오류 반환 {#signing-in-using-github-enterprise-returns-a-500-error}

이 오류는 GitLab 인스턴스와 GitHub Enterprise 간의 네트워크 연결 이슈로 인해 발생할 수 있습니다.

연결 이슈를 확인하려면:

1. GitLab 서버의 [`production.log`](../administration/logs/_index.md#productionlog)로 이동하여 다음 오류를 찾으세요:

   ``` plaintext
   Faraday::ConnectionFailed (execution expired)
   ```

1. [Rails 콘솔 시작](../administration/operations/rails_console.md#starting-a-rails-console-session)을 수행하고 다음 명령을 실행하세요. `<github_url>`을 GitHub Enterprise 인스턴스의 URL로 바꾸세요:

   ```ruby
   uri = URI.parse("https://<github_url>") # replace `GitHub-URL` with the real one here
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true
   http.verify_mode = 1
   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

1. 유사한 `execution expired` 오류가 반환되면 이는 오류가 연결 이슈로 인해 발생했음을 확인합니다. GitLab 서버가 GitHub Enterprise 인스턴스에 도달할 수 있는지 확인하세요.

### 기존 GitLab 계정 없이 GitHub 계정을 사용한 로그인은 허용되지 않습니다 {#signing-in-using-your-github-account-without-a-pre-existing-gitlab-account-is-not-allowed}

GitLab에 로그인하면 다음 오류가 표시됩니다:

```plaintext
Signing in using your GitHub account without a pre-existing
GitLab account is not allowed. Create a GitLab account first,
and then connect it to your GitHub account
```

이 이슈를 해결하려면 GitLab에서 GitHub 로그인을 활성화해야 합니다:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택하세요.
1. 왼쪽 사이드바에서 **액세스** > **비밀번호와 인증**을 선택하세요.
1. **서비스 로그인** 섹션에서 **Connect to GitHub**을 선택하세요.
