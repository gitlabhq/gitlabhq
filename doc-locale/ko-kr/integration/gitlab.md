---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 서버를 GitLab.com과 통합하세요
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab.com에서 프로젝트를 가져오고 GitLab.com 계정으로 GitLab 인스턴스에 로그인하세요.

GitLab.com OmniAuth 제공자를 활성화하려면 GitLab.com에 애플리케이션을 등록해야 합니다. GitLab.com이 사용할 수 있도록 애플리케이션 ID와 비밀 키를 생성합니다.

1. GitLab.com에 로그인하세요.
1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택하세요.
1. 왼쪽 사이드바에서 **액세스** > **응용 프로그램**을 선택하세요.
1. **새 애플리케이션 추가**에 필요한 세부 정보를 입력하세요.
   - 이름: 아무거나 입력할 수 있습니다. `<Organization>'s GitLab` 또는 `<Your Name>'s GitLab` 같은 것이나 다른 설명적인 이름을 고려해 보세요.
   - 리다이렉트 URI:

     ```plaintext
     # You can also use a non-SSL URL, but you should use SSL URLs.
     https://your-gitlab.example.com/import/gitlab/callback
     https://your-gitlab.example.com/users/auth/gitlab/callback
     ```

   첫 번째 링크는 가져오기 기능에 필요하고 두 번째는 인증에 필요합니다.

   다음 조건에 해당하는 경우:

   - 가져오기 기능을 사용할 계획이라면 범위를 그대로 둘 수 있습니다.
   - 이 애플리케이션을 인증용으로만 사용하려면 더 최소한의 범위 집합을 사용해야 합니다. `read_user`이(가) 충분합니다.

1. **애플리케이션 저장**을 선택하세요.
1. **애플리케이션 ID**와 **비밀**이 보일 것입니다. 설정을 계속하는 동안 이 페이지를 열어 두세요.
1. GitLab 서버에서 설정 파일을 열어 보세요.

   Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H editor config/gitlab.yml
   ```

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `gitlab`을 단일 로그인 공급자로 추가하세요. 이를 통해 기존 GitLab 계정이 없는 사용자를 위해 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 제공자 설정을 추가하세요:

   **GitLab.com**에 대해 인증하는 Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       # label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user" } # optional: defaults to the scopes of the application
     }
   ]
   ```

   또는 다른 GitLab 인스턴스에 대해 인증하는 Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user", # optional: defaults to the scopes of the application
               client_options: { site: "https://gitlab.example.com" } }
     }
   ]
   ```

   **GitLab.com**에 대해 인증하는 자체 컴파일 설치의 경우:

   ```yaml
   - { name: 'gitlab',
       # label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
   ```

   또는 다른 GitLab 인스턴스에 대해 인증하는 자체 컴파일 설치의 경우:

   ```yaml
   - { name: 'gitlab',
       label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { "client_options": { "site": 'https://gitlab.example.com' } }
   ```

   > [!note]
   > GitLab 15.1 이상에서 `site` 매개변수는 `/api/v4` 접미사가 필요합니다. GitLab 15.2 이상으로 업그레이드한 후 이 접미사를 제거해야 합니다.
1. `'YOUR_APP_ID'`을(를) GitLab.com 애플리케이션 페이지의 애플리케이션 ID로 변경하세요.
1. `'YOUR_APP_SECRET'`을(를) GitLab.com 애플리케이션 페이지의 비밀로 변경하세요.
1. 설정 파일을 저장하세요.
1. 적절한 방법을 사용하여 이러한 변경 사항을 구현하세요:
   - Linux 패키지 설치의 경우 [GitLab 재설정](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하세요.
   - 자체 컴파일 설치의 경우 [GitLab 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)을 수행하세요.

로그인 페이지에는 이제 일반 로그인 양식 다음에 GitLab.com 아이콘이 있어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작하세요. GitLab.com이 사용자에게 로그인하고 GitLab 애플리케이션을 승인하도록 요청합니다. 모든 것이 잘 진행되면 사용자가 GitLab 인스턴스로 반환되어 로그인됩니다.

## 로그인 시 액세스 권한 축소 {#reduce-access-privileges-on-sign-in}

{{< history >}}

- GitLab 14.8에서 [기능 플래그](../administration/feature_flags/_index.md)로 도입되었으며 이름은 `omniauth_login_minimal_scopes`입니다. 기본적으로 비활성화되었습니다.
- GitLab 14.9에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/351331)되었습니다.
- [기능 플래그 `omniauth_login_minimal_scopes`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83453)은 GitLab 15.2에서 제거되었습니다.

{{< /history >}}

GitLab 인스턴스를 인증에 사용하면 OAuth 애플리케이션을 로그인에 사용할 때 액세스 권한을 축소할 수 있습니다.

모든 OAuth 애플리케이션은 인증 매개변수 `gl_auth_type=login`을(를) 사용하여 애플리케이션의 목적을 광고할 수 있습니다. 애플리케이션이 `api` 또는 `read_api`로 설정된 경우 액세스 토큰은 더 높은 권한이 필요하지 않으므로 로그인을 위해 `read_user`로 발급됩니다.

GitLab OAuth 클라이언트는 이 매개변수를 전달하도록 설정되어 있지만 다른 애플리케이션도 전달할 수 있습니다.
