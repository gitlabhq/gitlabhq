---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Gitaly를 두 가지 방법 중 하나로 구성할 수 있습니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 Gitaly 설정을 추가하거나 변경합니다. [Gitaly 구성 파일 예제](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example)를 참조하세요. 예제 파일의 설정을 Ruby로 변환해야 합니다.
1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. [Gitaly 차트](https://docs.gitlab.com/charts/charts/gitlab/gitaly/)를 구성합니다.
1. [Helm 릴리스 업그레이드](https://docs.gitlab.com/charts/installation/deployment/).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitaly/config.toml`을(를) 편집하고 Gitaly 설정을 추가하거나 변경합니다. [Gitaly 구성 파일 예제](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example)를 참조하세요.
1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

다음 구성 옵션도 사용할 수 있습니다:

- [TLS 지원](tls_support.md) 사용.
- [RPC 동시성](concurrency_limiting.md#limit-rpc-concurrency) 제한.
- [pack-objects 동시성](concurrency_limiting.md#limit-pack-objects-concurrency) 제한.

## Gitaly 토큰 정보 {#about-the-gitaly-token}

Gitaly 설명서 전체에서 참조되는 토큰은 관리자가 선택한 임의의 비밀번호일 뿐입니다. GitLab API 또는 기타 유사한 웹 API 토큰으로 생성된 토큰과는 관련이 없습니다.

## 자신의 서버에서 Gitaly 실행 {#run-gitaly-on-its-own-server}

기본적으로 Gitaly는 Gitaly 클라이언트와 동일한 서버에서 실행되며 이전에 설명한 대로 구성됩니다. 단일 서버 설치는 다음에서 사용하는 이 기본 구성으로 가장 잘 작동합니다:

- [Linux 패키지 설치](https://docs.gitlab.com/omnibus/).
- [자체 컴파일 설치](../../install/self_compiled/_index.md).

그러나 Gitaly는 자신의 서버에 배포할 수 있으며, 이는 여러 머신에 걸친 GitLab 설치에 도움이 될 수 있습니다.

> [!note]
> 자신의 서버에서 실행되도록 구성된 경우 Gitaly 서버는 클러스터의 Gitaly 클라이언트 이전에 [업그레이드](../../update/package/_index.md)되어야 합니다.

자신의 서버에서 Gitaly를 설정하는 프로세스는 다음과 같습니다:

1. [Gitaly 설치](#install-gitaly).
1. [인증 구성](#configure-authentication).
1. [Gitaly 서버 구성](#configure-gitaly-servers).
1. [Gitaly 클라이언트 구성](#configure-gitaly-clients).
1. [필요하지 않은 곳에서 Gitaly 비활성화](#disable-gitaly-where-not-required-optional)(선택 사항).

> [!note]
> [디스크 요구 사항](_index.md#disk-requirements)이 Gitaly 노드에 적용됩니다.

### 네트워크 아키텍처 {#network-architecture}

다음 목록은 Gitaly의 네트워크 아키텍처를 나타냅니다:

- GitLab Rails는 리포지토리를 [리포지토리 스토리지](../repository_storage_paths.md)로 분산합니다.
- `/config/gitlab.yml`은(는) 스토리지 이름에서 `(Gitaly address, Gitaly token)` 쌍으로의 맵을 포함합니다.
- `storage name` -> `(Gitaly address, Gitaly token)` 맵은 `/config/gitlab.yml`에서 Gitaly 네트워크 토폴로지의 단일 진실 공급원입니다.
- `(Gitaly address, Gitaly token)`은(는) Gitaly 서버에 해당합니다.
- Gitaly 서버는 하나 이상의 스토리지를 호스트합니다.
- Gitaly 클라이언트는 하나 이상의 Gitaly 서버를 사용할 수 있습니다.
- Gitaly 주소는 모든 Gitaly 클라이언트에서 올바르게 확인되도록 지정되어야 합니다.
- Gitaly 클라이언트는 다음과 같습니다:
  - Puma.
  - Sidekiq.
  - GitLab Workhorse.
  - GitLab Shell.
  - Elasticsearch 인덱서.
  - Gitaly 자체.
- Gitaly 서버는 `/config/gitlab.yml`에 지정된 대로 자신의 `(Gitaly address, Gitaly token)` 쌍을 사용하여 자신에게 RPC 호출을 수행할 수 있어야 합니다.
- 인증은 Gitaly와 GitLab Rails 노드 간에 공유되는 정적 토큰을 통해 수행됩니다.

다음 다이어그램은 Gitaly 서버와 GitLab Rails 간의 통신을 보여주며 HTTP 및 HTTPS 통신의 기본 포트를 표시합니다.

![두 개의 Gitaly 서버와 GitLab Rails이 정보를 교환합니다.](img/gitaly_network_v13_9.png)

> [!warning]
> Gitaly 서버는 Gitaly 네트워크 트래픽이 기본적으로 암호화되지 않으므로 공개 인터넷에 노출되어서는 안 됩니다. 방화벽의 사용을 강력히 권장하여 Gitaly 서버에 대한 액세스를 제한합니다. 다른 옵션은 [TLS 사용](tls_support.md)입니다.

다음 섹션에서는 비밀 토큰 `abc123secret`으로 두 개의 Gitaly 서버를 구성하는 방법을 설명합니다:

- `gitaly1.internal`.
- `gitaly2.internal`.

GitLab 설치에 세 개의 리포지토리 스토리지가 있다고 가정합니다:

- `default`.
- `storage1`.
- `storage2`.

원하는 경우 하나의 서버와 하나의 리포지토리 스토리지를 사용할 수 있습니다.

### Gitaly 설치 {#install-gitaly}

각 Gitaly 서버에서 다음 중 하나를 사용하여 Gitaly를 설치합니다:

- Linux 패키지 설치. [다운로드 및 설치](https://about.gitlab.com/install/)할 Linux 패키지를 원하지만 `EXTERNAL_URL=` 값을 제공하지 마세요.
- 자체 컴파일 설치. [Gitaly 설치](../../install/self_compiled/_index.md#install-gitaly)의 단계를 따릅니다.

### Gitaly 서버 구성 {#configure-gitaly-servers}

Gitaly 서버를 구성하려면 다음을 수행해야 합니다:

- 인증을 구성합니다.
- 스토리지 경로를 구성합니다.
- 네트워크 리스너를 활성화합니다.

`git` 사용자는 구성된 스토리지 경로에 대한 읽기, 쓰기 및 권한 설정이 가능해야 합니다.

Gitaly 토큰을 회전하는 동안 다운타임을 방지하려면 `gitaly['auth_transitioning']` 설정을 사용하여 인증을 임시로 비활성화할 수 있습니다. 자세한 내용은 [인증 전환 모드 활성화](#enable-auth-transitioning-mode)를 참조하세요.

#### 인증 구성 {#configure-authentication}

{{< history >}}

- `token_file`에 대한 지원은 GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitaly/-/issues/7083)되었습니다.

{{< /history >}}

Gitaly와 GitLab은 인증을 위해 두 개의 공유 비밀을 사용합니다:

- _Gitaly 토큰_: Gitaly에 대한 gRPC 요청을 인증하는 데 사용됩니다. GitLab 구성에서 직접 또는 토큰 파일에서 Gitaly 토큰을 지정할 수 있습니다. 토큰 파일을 사용하면 더 안전하며 시작 시 비밀을 구성으로 렌더링하는 것을 방지하므로 컨테이너화된 환경에 더 적합합니다. 토큰 파일은 다음을 수행해야 합니다:
  - 토큰 문자열만 포함합니다. 공백은 자동으로 제거됩니다.
  - `0600` 또는 `0400`의 파일 권한이 있습니다.
- _GitLab Shell 토큰_: GitLab Shell에서 GitLab 내부 API로의 인증 콜백에 사용됩니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. _Gitaly 토큰_을(를) 구성하려면 `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   - 토큰 파일을 사용할 때:

     ```ruby
     gitaly['configuration'] = {
        # ...
        auth: {
          # ...
          token_file: '/etc/gitlab/gitaly_token',
        },
     }
     ```

   - 토큰을 직접 지정할 때:

     ```ruby
     gitaly['configuration'] = {
        # ...
        auth: {
          # ...
          token: 'abc123secret',
        },
     }
     ```

   `token`과(와) `token_file`은(는) 상호 배타적입니다.

1. _GitLab Shell 토큰_을(를) 두 가지 방법 중 하나로 구성합니다:

   - 방법 1(권장): Gitaly 클라이언트에서 `/etc/gitlab/gitlab-secrets.json`을(를) 복사하여 Gitaly 서버 및 기타 Gitaly 클라이언트의 동일한 경로에 붙여넣습니다.

   - 방법 2:

     1. GitLab Rails을 실행하는 모든 노드에서 `/etc/gitlab/gitlab.rb`을(를) 편집합니다.
     1. `GITLAB_SHELL_SECRET_TOKEN`을(를) 실제 비밀로 바꿉니다:

        - GitLab 17.5 이상:

          ```ruby
          gitaly['gitlab_secret'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

        - GitLab 17.4 이하:

          ```ruby
          gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

     1. Gitaly를 실행하는 모든 노드에서 `/etc/gitlab/gitlab.rb`을(를) 편집합니다.
     1. `GITLAB_SHELL_SECRET_TOKEN`을(를) 실제 비밀로 바꿉니다:

        - GitLab 17.5 이상:

          ```ruby
          gitaly['gitlab_secret'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

        - GitLab 17.4 이하:

          ```ruby
          gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

     1. 이러한 변경 후 GitLab을 재구성합니다:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Gitaly 클라이언트에서 `/home/git/gitlab/.gitlab_shell_secret`을(를) 복사하여 Gitaly 서버(및 기타 Gitaly 클라이언트)의 동일한 경로에 붙여넣습니다.
1. Gitaly 클라이언트에서 `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   gitlab:
     gitaly:
       token: 'abc123secret'
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.
1. Gitaly 서버에서 `/home/git/gitaly/config.toml`을(를) 편집합니다:

   - 토큰 파일을 사용할 때:

     ```toml
     [auth]
     token_file = '/etc/gitaly/token'
     ```

   - 토큰을 직접 지정할 때:

     ```toml
     [auth]
     token = 'abc123secret'
     ```

   `token`과(와) `token_file`은(는) 상호 배타적입니다.

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

#### Gitaly 서버 구성 {#configure-gitaly-server}

<!--
Updates to example must be made at:

- <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation>
- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/gitaly/praefect/configure.md#praefect>
- All reference architecture pages
-->

Gitaly 서버를 구성합니다.

Gitaly에는 클라이언트(예: Rails 또는 Sidekiq)에서 제공하는 주소를 사용하여 자신에게 네트워크 호출을 수행하는 일부 RPC가 있습니다.

네트워크 구성으로 인해 Gitaly가 이 방식으로 자신에게 도달할 수 없는 경우(예를 들어 Gitaly가 헤어핀 연결을 지원하지 않는 로드 밸런서 뒤에 있음):

1. Gitaly 서버의 `/etc/hosts` 파일을 편집합니다.
1. 클라이언트에서 사용하는 Gitaly 주소를 Gitaly 서버의 자신의 IP 주소로 리디렉션하는 항목을 추가합니다. 예를 들어 `127.0.0.1 gitaly.example.com` 또는 `<local-ip> gitaly.example.com`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_kas['enable'] = false

   # If you run a separate monitoring node you can disable these services
   prometheus['enable'] = false
   alertmanager['enable'] = false

   # If you don't run a separate monitoring node you can
   # enable Prometheus access & disable these extra services.
   # This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
   # prometheus['listen_address'] = '0.0.0.0:9090'
   # prometheus['monitor_kubernetes'] = false

   # If you don't want to run monitoring services uncomment the following (not recommended)
   # node_exporter['enable'] = false

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   # Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from Gitaly client to Gitaly server.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces. You must use
      # firewalls to restrict access to this address/port.
      # Comment out following line if you only want to support TLS connections
      listen_addr: '0.0.0.0:8075',
      auth: {
        # ...
        #
        # Authentication token to ensure only authorized servers can communicate with
        # Gitaly server
        token: 'AUTH_TOKEN',
      },
   }
   ```

1. 각 해당 Gitaly 서버에 대해 `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   <!-- Updates to following example must also be made at <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation> -->

   `gitaly1.internal`에서:

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'default',
            path: '/var/opt/gitlab/git-data/repositories',
         },
         {
            name: 'storage1',
            path: '/mnt/gitlab/git-data/repositories',
         },
      ],
   }
   ```

   `gitaly2.internal`에서:

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'storage2',
            path: '/srv/gitlab/git-data/repositories',
         },
      ],
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. Gitaly가 GitLab 내부 API에 콜백을 수행할 수 있는지 확인합니다:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitaly/config.toml`을(를) 편집합니다:

   ```toml
   listen_addr = '0.0.0.0:8075'

   runtime_dir = '/var/opt/gitlab/gitaly'

   [logging]
   format = 'json'
   level = 'info'
   dir = '/var/log/gitaly'
   ```

1. 각 해당 Gitaly 서버에 대해 `/home/git/gitaly/config.toml`에 다음을 추가합니다:

   `gitaly1.internal`에서:

   ```toml
   [[storage]]
   name = 'default'
   path = '/var/opt/gitlab/git-data/repositories'

   [[storage]]
   name = 'storage1'
   path = '/mnt/gitlab/git-data/repositories'
   ```

   `gitaly2.internal`에서:

   ```toml
   [[storage]]
   name = 'storage2'
   path = '/srv/gitlab/git-data/repositories'
   ```

1. `/home/git/gitlab-shell/config.yml`을(를) 편집합니다:

   ```yaml
   gitlab_url: https://gitlab.example.com
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.
1. Gitaly가 GitLab 내부 API에 콜백을 수행할 수 있는지 확인합니다:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> 리포지토리 데이터를 GitLab 서버에서 Gitaly로 직접 복사하는 경우 메타데이터 파일(기본 경로 `/var/opt/gitlab/git-data/repositories/.gitaly-metadata`)이 전송에 포함되지 않도록 하세요. 이 파일을 복사하면 GitLab이 Gitaly 서버에서 호스팅되는 리포지토리에 대해 직접 디스크 액세스를 사용하여 `Error creating pipeline` 및 `Commit not found` 오류 또는 오래된 데이터가 발생합니다.

### Gitaly 클라이언트 구성 {#configure-gitaly-clients}

최종 단계로 Gitaly 클라이언트를 업데이트하여 로컬 Gitaly 서비스에서 방금 구성한 Gitaly 서버로 사용을 전환해야 합니다.

> [!note]
> GitLab은 `default` 리포지토리 스토리지를 구성해야 합니다. [이 제한 사항에 대해 자세히 알아봅니다](#gitlab-requires-a-default-repository-storage).

Gitaly 클라이언트가 Gitaly 서버에 도달하지 못하게 하는 모든 것이 모든 Gitaly 요청이 실패하게 할 수 있으므로 위험할 수 있습니다. 예를 들어 모든 종류의 네트워크, 방화벽 또는 이름 확인 문제.

Gitaly는 다음 가정을 합니다:

- 귀사의 `gitaly1.internal` Gitaly 서버는 Gitaly 클라이언트에서 `gitaly1.internal:8075`에서 도달할 수 있으며 해당 Gitaly 서버는 `/var/opt/gitlab/git-data` 및 `/mnt/gitlab/git-data`에 대한 읽기, 쓰기 및 권한 설정이 가능합니다.
- 귀사의 `gitaly2.internal` Gitaly 서버는 Gitaly 클라이언트에서 `gitaly2.internal:8075`에서 도달할 수 있으며 해당 Gitaly 서버는 `/srv/gitlab/git-data`에 대한 읽기, 쓰기 및 권한 설정이 가능합니다.
- 귀사의 `gitaly1.internal` 및 `gitaly2.internal` Gitaly 서버는 서로 도달할 수 있습니다.

일부를 로컬 Gitaly 서버(`gitaly_address` 없음)로, 일부를 원격 서버(`gitaly_address` 있음)로 정의하는 Gitaly 서버를 정의할 수 없습니다. [혼합 구성](#mixed-configuration)을 사용하지 않는 한입니다.

Gitaly 클라이언트를 두 가지 방법 중 하나로 구성합니다. 이 지침은 암호화되지 않은 연결용이지만 [TLS 지원](tls_support.md)을(를) 활성화할 수도 있습니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   # Use the same token value configured on all Gitaly servers
   gitlab_rails['gitaly_token'] = '<AUTH_TOKEN>'

   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   }
   ```

   또는 각 Gitaly 서버가 다른 인증 토큰을 사용하도록 구성된 경우:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_2>' },
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. Gitaly 클라이언트(예: Rails 애플리케이션)에서 `sudo gitlab-rake gitlab:gitaly:check`을(를) 실행하여 Gitaly 서버에 연결할 수 있는지 확인합니다.
1. 로그 끝까지 스크롤하여 요청을 확인합니다:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage1:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tcp://gitaly2.internal:8075
           gitaly_token: AUTH_TOKEN_2
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.
1. `sudo -u git -H bundle exec rake gitlab:gitaly:check RAILS_ENV=production`을(를) 실행하여 Gitaly 클라이언트가 Gitaly 서버에 연결할 수 있는지 확인합니다.
1. 로그 끝까지 스크롤하여 요청을 확인합니다:

   ```shell
   tail -f /home/git/gitlab/log/gitaly.log
   ```

{{< /tab >}}

{{< /tabs >}}

Gitaly 서버에서 Gitaly 로그를 끝까지 스크롤하면 들어오는 요청을 봐야 합니다. Gitaly 요청을 트리거하는 확실한 방법은 HTTP 또는 HTTPS를 통해 GitLab에서 리포지토리를 복제하는 것입니다.

> [!warning]
> [서버 훅](../server_hooks.md)이 리포지토리별로 또는 전역적으로 구성된 경우 이를 Gitaly 서버로 이동해야 합니다. Gitaly 서버가 여러 개인 경우 서버 훅을 모든 Gitaly 서버에 복사합니다.

#### 혼합 구성 {#mixed-configuration}

GitLab은 많은 Gitaly 서버 중 하나와 동일한 서버에 상주할 수 있지만 로컬 및 원격 구성을 혼합하는 구성을 지원하지 않습니다. 다음 설정은 다음 이유로 부정확합니다:

- 모든 주소는 다른 Gitaly 서버에서 도달 가능해야 합니다.
- `storage1`이(가) `gitaly_address`에 대한 Unix 소켓에 할당되어 있으므로 일부 Gitaly 서버에 대해 유효하지 않습니다.

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  'storage1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}
```

로컬 및 원격 Gitaly 서버를 결합하려면 로컬 Gitaly 서버에 대해 외부 주소를 사용하세요. 예를 들어:

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  # Address of the GitLab server that also has Gitaly running on it
  'storage1' => { 'gitaly_address' => 'tcp://gitlab.internal:8075' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}

gitaly['configuration'] = {
  # ...
  #
  # Make Gitaly accept connections on all network interfaces
  listen_addr: '0.0.0.0:8075',
  # Or for TLS
  tls_listen_addr: '0.0.0.0:9999',
  tls: {
    certificate_path:  '/etc/gitlab/ssl/cert.pem',
    key_path: '/etc/gitlab/ssl/key.pem',
  },
  storage: [
    {
      name: 'storage1',
      path: '/mnt/gitlab/git-data/repositories',
    },
  ],
}
```

`path`은(는) 로컬 Gitaly 서버의 스토리지 분할에 대해서만 포함될 수 있습니다. 제외된 경우 해당 스토리지 분할에 기본 Git 스토리지 디렉토리가 사용됩니다.

### GitLab에서 기본 리포지토리 스토리지가 필요합니다 {#gitlab-requires-a-default-repository-storage}

Gitaly 서버를 환경에 추가할 때 원본 `default` Gitaly 서비스를 바꾸려고 할 수 있습니다. 그러나 GitLab은 `default` 스토리지를 제거하도록 GitLab 애플리케이션 서버를 재구성할 수 없습니다. GitLab은 `default`라는 스토리지가 필요하기 때문입니다. [자세히 알아봅니다](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) 이 제한 사항에 대해.

이 제한 사항을 해결하려면:

1. 새 Gitaly 서비스에서 추가 스토리지 위치를 정의하고 추가 스토리지를 `default`이(가) 되도록 구성합니다. 스토리지 위치에는 작동하는 데이터베이스 마이그레이션이 필요한 작동 가능한 Gitaly 서비스가 있어야 합니다.
1. [**운영자** 영역](../repository_storage_paths.md#configure-where-new-repositories-are-stored)에서 `default`을(를) 0의 가중치로 설정하여 리포지토리가 저장되지 않도록 합니다.

### 필요하지 않은 곳에서 Gitaly 비활성화(선택 사항) {#disable-gitaly-where-not-required-optional}

Gitaly를 [원격 서비스로](#run-gitaly-on-its-own-server) 실행하는 경우 기본적으로 GitLab 서버에서 실행되는 로컬 Gitaly 서비스를 비활성화하고 필요한 곳에서만 실행하는 것을 고려하세요.

GitLab 인스턴스에서 Gitaly를 비활성화하는 것은 Gitaly가 GitLab 인스턴스와는 별개의 머신에서 실행되는 사용자 지정 클러스터 구성에서 GitLab을 실행할 때만 의미가 있습니다. 클러스터의 모든 머신에서 Gitaly를 비활성화하는 것은 유효한 구성이 아닙니다(일부 머신은 Gitaly 서버로 작동해야 함).

GitLab 서버에서 Gitaly를 비활성화하는 방법은 두 가지입니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitaly['enable'] = false
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/etc/default/gitlab`을(를) 편집합니다:

   ```shell
   gitaly_enabled=false
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

## Gitaly 수신 대기 인터페이스 변경 {#change-the-gitaly-listening-interface}

Gitaly가 수신 대기하는 인터페이스를 변경할 수 있습니다. Gitaly와 통신해야 하는 외부 서비스가 있을 때 수신 대기 인터페이스를 변경할 수 있습니다. 예를 들어 [정확한 코드 검색](../../integration/zoekt/_index.md)이 정확한 코드 검색이 활성화되었지만 실제 서비스가 다른 서버에서 실행 중일 때 Zoekt를 사용합니다.

`gitaly_token`은(는) `gitaly_token`이(가) Gitaly 서비스 인증에 사용되므로 비밀 문자열이어야 합니다. 이 비밀은 `openssl rand -base64 24`으로 생성하여 32자 임의의 문자열을 생성할 수 있습니다.

예를 들어 Gitaly 수신 대기 인터페이스를 `0.0.0.0:8075`로 변경하려면:

```ruby
# /etc/gitlab/gitlab.rb
# Add a shared token for Gitaly authentication
gitlab_shell['secret_token'] = 'your_secure_token_here'
gitlab_rails['gitaly_token'] = 'your_secure_token_here'

# Gitaly configuration
gitaly['gitlab_secret'] = 'your_secure_token_here'
gitaly['configuration'] = {
  listen_addr: '0.0.0.0:8075',
  auth: {
    token: 'your_secure_token_here',
  },
  storage: [
    {
      name: 'default',
      path: '/var/opt/gitlab/git-data/repositories',
    },
  ]
}

# Tell Rails where to find Gitaly
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://ip_address_here:8075' },
}

# Internal API URL (important for multi-server setups)
gitlab_rails['internal_api_url'] = 'http://ip_address_here'
```

## 제어 그룹 {#control-groups}

제어 그룹에 대한 정보는 [Cgroups](cgroups.md)를 참조하세요.

## 백그라운드 리포지토리 최적화 {#background-repository-optimization}

Git 리포지토리의 개체 데이터베이스에 데이터가 저장되는 방식은 시간이 지남에 따라 비효율적이 될 수 있으며, 이는 Git 작업을 느리게 합니다. Gitaly를 예약하여 최대 기간의 일일 백그라운드 작업을 실행하여 이러한 항목을 정리하고 성능을 향상시킬 수 있습니다.

> [!warning]
> 백그라운드 리포지토리 최적화는 실행 중에 호스트에 상당한 로드를 배치할 수 있습니다. 이것을 비업무 시간에 예약하고 기간을 짧게 유지해야 합니다(예: 30-60분).

백그라운드 리포지토리 최적화를 두 가지 방법 중 하나로 구성합니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 추가합니다:

```ruby
gitaly['configuration'] = {
  # ...
  daily_maintenance: {
    # ...
    start_hour: 4,
    start_minute: 30,
    duration: '30m',
    storages: ['default'],
  },
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 추가합니다:

```toml
[daily_maintenance]
start_hour = 4
start_minute = 30
duration = '30m'
storages = ["default"]
```

{{< /tab >}}

{{< /tabs >}}

## Gitaly 인증 토큰 회전 {#rotate-gitaly-authentication-token}

프로덕션 환경에서 자격 증명을 회전하는 것은 종종 다운타임이 필요하거나 중단을 야기하거나 둘 다 야기합니다.

그러나 Gitaly 자격 증명을 서비스 중단 없이 회전할 수 있습니다. Gitaly 인증 토큰 회전에는 다음이 포함됩니다:

- [인증 모니터링 확인](#verify-authentication-monitoring).
- [인증 전환 모드 활성화](#enable-auth-transitioning-mode).
- [Gitaly 인증 토큰 업데이트](#update-gitaly-authentication-token).
- [인증 실패가 없는지 확인](#ensure-there-are-no-authentication-failures).
- [인증 전환 모드 비활성화](#disable-auth-transitioning-mode).
- [인증 적용 확인](#verify-authentication-is-enforced).

이 절차는 단일 서버에서 GitLab을 실행하는 경우에도 작동합니다. 이 경우 Gitaly 서버와 Gitaly 클라이언트는 동일한 머신을 나타냅니다.

### 인증 모니터링 확인 {#verify-authentication-monitoring}

Gitaly 인증 토큰을 회전하기 전에 Prometheus를 사용하여 GitLab 설치의 [인증 동작을 모니터링](monitoring.md#queries)할 수 있는지 확인합니다.

그런 다음 절차의 나머지를 계속할 수 있습니다.

### 인증 전환 모드 활성화 {#enable-auth-transitioning-mode}

다음과 같이 인증 전환 모드로 전환하여 Gitaly 서버에서 Gitaly 인증을 임시로 비활성화합니다:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: true,
  },
}
```

이 변경을 수행한 후 [Prometheus 쿼리](#verify-authentication-monitoring)는 다음과 같은 항목을 반환해야 합니다:

```promql
{enforced="false",status="would be ok"}  4424.985419441742
```

`enforced="false"`이므로 새 토큰을 롤아웃하기 시작하는 것이 안전합니다.

### Gitaly 인증 토큰 업데이트 {#update-gitaly-authentication-token}

새 Gitaly 인증 토큰으로 업데이트하려면 각 Gitaly 클라이언트 및 Gitaly 서버에서:

1. 구성을 업데이트합니다:

   ```ruby
   # in /etc/gitlab/gitlab.rb
   gitaly['configuration'] = {
      # ...
      auth: {
         # ...
         token: '<new secret token>',
      },
   }
   ```

   `token_file`을(를) 사용 중이면 새 토큰으로 참조된 파일의 내용을 업데이트하세요. 구성 변경이 필요하지 않습니다. 토큰 파일은 시작 시 읽혀집니다.

1. Gitaly 재시작:

   ```shell
   gitlab-ctl restart gitaly
   ```

이 변경을 롤아웃하는 동안 [Prometheus 쿼리](#verify-authentication-monitoring)를 실행하면 `enforced="false",status="denied"` 카운터에 대한 0이 아닌 값이 표시됩니다.

### 인증 실패가 없는지 확인 {#ensure-there-are-no-authentication-failures}

새 토큰이 설정되고 관련된 모든 서비스가 재시작된 후 [임시로 다음 혼합](#verify-authentication-monitoring)이 표시됩니다:

- `status="would be ok"`.
- `status="denied"`.

새 토큰이 모든 Gitaly 클라이언트 및 Gitaly 서버에 의해 선택된 후 유일한 0이 아닌 레이트는 `enforced="false",status="would be ok"`이어야 합니다.

### 인증 전환 모드 비활성화 {#disable-auth-transitioning-mode}

Gitaly 인증을 다시 활성화하려면 인증 전환 모드를 비활성화합니다. 다음과 같이 Gitaly 서버에서 구성을 업데이트합니다:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: false,
  },
}
```

> [!warning]
> 이 단계를 완료하지 않으면 Gitaly 인증이 없습니다.

### 인증 적용 확인 {#verify-authentication-is-enforced}

[Prometheus 쿼리](#verify-authentication-monitoring)를 새로 고칩니다. 이제 시작할 때와 유사한 결과가 표시되어야 합니다. 예를 들어:

```promql
{enforced="true",status="ok"}  4424.985419441742
```

`enforced="true"`은(는) 인증이 적용되고 있음을 의미합니다.

## Pack-objects 캐시 {#pack-objects-cache}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Git 리포지토리에 대한 스토리지를 제공하는 서비스인 [Gitaly](_index.md)는 Git 페치 응답의 짧은 롤링 윈도우를 캐시하도록 구성할 수 있습니다. 이는 서버가 많은 CI 페치 트래픽을 수신할 때 서버 로드를 줄일 수 있습니다.

pack-objects 캐시는 `git pack-objects`을(를) 감싸고 PostUploadPack 및 SSHUploadPack Gitaly RPC를 사용하여 간접적으로 호출되는 Git의 내부 부분입니다. Gitaly는 사용자가 HTTP를 사용하여 Git 페치를 수행할 때 PostUploadPack을 실행하거나 사용자가 SSH를 사용하여 Git 페치를 수행할 때 SSHUploadPack을 실행합니다. 캐시가 활성화되면 PostUploadPack 또는 SSHUploadPack을 사용하는 모든 항목이 이것으로부터 이점을 얻을 수 있습니다. 다음과 독립적이며 영향을 받지 않습니다:

- 전송(HTTP 또는 SSH).
- Git 프로토콜 버전(v0 또는 v2).
- 전체 복제, 증분 페치, 얕은 복제 또는 부분 복제와 같은 페치 유형.

이 캐시의 강점은 동시 동일 페치를 중복 제거하는 기능입니다. 이것은:

- 많은 동시 작업이 있는 CI/CD 파이프라인을 실행하는 사용자가 있는 GitLab 인스턴스에 도움이 될 수 있습니다. 서버 CPU 사용률이 눈에 띄게 감소해야 합니다.
- 고유한 페치에는 전혀 도움이 되지 않습니다. 예를 들어 로컬 컴퓨터에 리포지토리를 복제하여 스팟 검사를 실행하는 경우 페치가 고유할 가능성이 높으므로 이 캐시로부터 이점을 볼 가능성이 낮습니다.

pack-objects 캐시는 로컬 캐시입니다. 이것은:

- 메타데이터를 활성화된 Gitaly 프로세스의 메모리에 저장합니다.
- 실제 Git 데이터를 캐싱하는 것을 로컬 스토리지의 파일에 저장합니다.

로컬 파일을 사용하면 운영 체제가 pack-objects 캐시 파일의 일부를 RAM에 자동으로 유지하여 더 빠르게 하는 이점이 있습니다.

pack-objects 캐시는 디스크 쓰기 IO에 상당한 증가로 이어질 수 있으므로 기본적으로 비활성화됩니다.

### 캐시 구성 {#configure-the-cache}

pack-objects 캐시에 사용할 수 있는 구성 설정입니다. 각 설정은 아래에서 더 자세히 설명합니다.

| 설정   | 기본값                                            | 설명                                                                                        |
|:----------|:---------------------------------------------------|:---------------------------------------------------------------------------------------------------|
| `enabled` | `false`                                            | 캐시를 켭니다. 끄면 Gitaly는 각 요청에 대해 전용 `git pack-objects` 프로세스를 실행합니다. |
| `dir`     | `<PATH TO FIRST STORAGE>/+gitaly/PackObjectsCache` | 캐시 파일이 저장되는 로컬 디렉토리입니다.                                                      |
| `max_age` | `5m`(5분)                                   | 이보다 오래된 캐시 항목이 제거되고 디스크에서 제거됩니다.                                   |
| `min_occurrences` | 1 | 캐시 항목이 생성되기 전에 키가 발생해야 하는 최소 횟수입니다. |

`/etc/gitlab/gitlab.rb`에서 설정:

```ruby
gitaly['configuration'] = {
  # ...
  pack_objects_cache: {
    enabled: true,
    # The default settings for "dir", "max_age" and "min_occurences" should be fine.
    # If you want to customize these, see details below.
  },
}
```

#### `enabled`은(는) `false`로 기본 설정됩니다. {#enabled-defaults-to-false}

캐시는 기본적으로 비활성화되어 있습니다. 경우에 따라 디스크에 쓰인 바이트 수가 [극단적으로 증가](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4010#note_534564684)할 수 있기 때문입니다. GitLab.com에서 우리는 리포지토리 스토리지 디스크가 이 추가 워크로드를 처리할 수 있음을 확인했습니다. 하지만 이것이 어디에나 사실이라고 가정할 수 없다고 생각했습니다.

#### 캐시 스토리지 디렉토리 `dir` {#cache-storage-directory-dir}

캐시는 파일을 저장할 디렉토리가 필요합니다. 이 디렉토리는 다음을 수행해야 합니다:

- 충분한 공간이 있는 파일 시스템에 있습니다. 캐시 파일 시스템이 공간을 부족해지면 모든 페치가 실패하기 시작합니다.
- 충분한 IO 대역폭이 있는 디스크에 있습니다. 캐시 디스크가 IO 대역폭을 부족해지면 모든 페치와 아마도 전체 서버가 느려집니다.

> [!warning]
> 지정된 디렉토리의 모든 기존 데이터가 제거됩니다. 기존 데이터가 있는 디렉토리를 사용하지 않도록 주의하세요.

기본적으로 캐시 스토리지 디렉토리는 구성 파일에 정의된 첫 번째 Gitaly 스토리지의 하위 디렉토리로 설정됩니다.

여러 Gitaly 프로세스는 캐시 스토리지에 동일한 디렉토리를 사용할 수 있습니다. 각 Gitaly 프로세스는 생성하는 캐시 파일 이름의 일부로 고유한 임의의 문자열을 사용합니다. 이것은 다음을 의미합니다:

- 충돌하지 않습니다.
- 다른 프로세스의 파일을 재사용하지 않습니다.

기본 디렉토리가 캐시 파일을 리포지토리 데이터와 동일한 파일 시스템에 넣더라도 이는 요구 사항이 아닙니다. 인프라에 더 적합한 경우 캐시 파일을 다른 파일 시스템에 넣을 수 있습니다.

디스크에서 필요한 IO 대역폭의 양은 다음에 달려 있습니다:

- Gitaly 서버의 리포지토리의 크기와 모양.
- 사용자가 생성하는 트래픽의 종류.

`gitaly_pack_objects_generated_bytes_total` 메트릭을 비관적인 추정치로 사용하여 캐시 히트율이 0%라고 가정할 수 있습니다.

필요한 공간의 양은 다음에 달려 있습니다:

- 사용자가 캐시에서 가져오는 초당 바이트.
- `max_age` 캐시 제거 창의 크기.

사용자가 100MB/s를 끌어당기고 5분 창을 사용하는 경우 평균적으로 `5*60*100 MB = 30 GB`의 데이터가 캐시 디렉토리에 있습니다. 이 평균은 예상 평균이지 보장이 아닙니다. 최고 크기는 이 평균을 초과할 수 있습니다.

#### 캐시 제거 윈도우 `max_age` {#cache-eviction-window-max_age}

`max_age` 구성 설정을 사용하면 캐시 히트 가능성과 캐시 파일이 사용하는 평균 스토리지 양을 제어할 수 있습니다. `max_age`보다 오래된 항목이 디스크에서 삭제됩니다.

제거는 진행 중인 요청을 방해하지 않습니다. 느린 연결을 통해 페치하는 데 걸리는 시간보다 `max_age`이(가) 짧은 것이 문제가 되지 않습니다. Unix 파일 시스템은 삭제된 파일을 읽는 모든 프로세스가 파일을 닫을 때까지 파일을 실제로 삭제하지 않기 때문입니다.

#### 최소 키 발생 횟수 `min_occurrences` {#minimum-key-occurrences-min_occurrences}

`min_occurrences` 설정은 새 캐시 항목을 생성하기 전에 동일한 요청이 발생해야 하는 빈도를 제어합니다. 기본값은 `1`이므로 고유한 요청은 캐시에 기록되지 않습니다.

다음을 수행하면:

- 이 숫자를 증가시키면 캐시 히트율이 감소하고 캐시가 더 적은 디스크 공간을 사용합니다.
- 이 숫자를 줄이면 캐시 히트율이 올라가고 캐시가 더 많은 디스크 공간을 사용합니다.

`min_occurrences`을(를) `1`로 설정해야 합니다. GitLab.com에서 0에서 1로 이동하면 캐시 히트율에 거의 영향을 주지 않으면서 캐시 디스크 공간의 50%가 절약되었습니다.

### 캐시 관찰 {#observe-the-cache}

{{< history >}}

- pack-objects 캐싱에 대한 로그는 GitLab 16.0에서 [변경](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5719)되었습니다.

{{< /history >}}

Prometheus 메트릭 및 로그 필드를 사용하여 캐시를 관찰할 수 있습니다.

#### Prometheus 메트릭 {#prometheus-metrics}

Gitaly는 pack-objects 캐시를 모니터링하기 위해 다음 Prometheus 메트릭을 내보냅니다:

| 메트릭 | 유형 | 설명 |
|:-------|:-----|:------------|
| `gitaly_pack_objects_served_bytes_total` | 카운터 | `git-pack-objects` 데이터 중 클라이언트에 제공되는 총 바이트 수 |
| `gitaly_pack_objects_cache_lookups_total` | 카운터 | 캐시 조회 횟수, `result` 레이블은 `hit` 또는 `miss`을(를) 나타냅니다. |
| `gitaly_pack_objects_generated_bytes_total` | 카운터 | `git-pack-objects`을(를) 실행하여 생성된 총 바이트 수 |

**Example Prometheus queries:**

캐시 히트율:

```promql
sum(rate(gitaly_pack_objects_cache_lookups_total{result="hit"}[5m])) /
sum(rate(gitaly_pack_objects_cache_lookups_total[5m]))
```

초당 캐시에서 제공되는 바이트:

```promql
rate(gitaly_pack_objects_served_bytes_total[5m])
```

초당 생성된 바이트(캐시 미스):

```promql
rate(gitaly_pack_objects_generated_bytes_total[5m])
```

캐시 효율(제공된 바이트 대 생성된 바이트):

```promql
rate(gitaly_pack_objects_served_bytes_total[5m]) /
rate(gitaly_pack_objects_generated_bytes_total[5m])
```

#### 로그 필드 {#log-fields}

이 로그는 gRPC 로그의 일부이며 호출이 실행될 때 발견될 수 있습니다.

| 필드 | 설명 |
|:---|:---|
| `pack_objects_cache.hit` | 현재 pack-objects 캐시가 `true` 또는 `false`인지 여부를 나타냅니다. |
| `pack_objects_cache.key` | pack-objects 캐시에 사용되는 캐시 키 |
| `pack_objects_cache.generated_bytes` | 쓰는 새 캐시의 크기(바이트) |
| `pack_objects_cache.served_bytes` | 제공되는 캐시의 크기(바이트) |
| `pack_objects.compression_statistics` | pack-objects 생성과 관련된 통계 |
| `pack_objects.enumerate_objects_ms` | 클라이언트가 보낸 개체를 열거하는 데 소요되는 총 시간(ms) |
| `pack_objects.prepare_pack_ms` | 클라이언트에게 다시 보내기 전에 packfile을 준비하는 데 소요되는 총 시간(ms) |
| `pack_objects.write_pack_file_ms` | 클라이언트에게 packfile을 다시 보내는 데 소요되는 총 시간(ms). 클라이언트의 인터넷 연결에 많이 의존합니다. |
| `pack_objects.written_object_count` | Gitaly가 클라이언트에게 반환하는 총 개체 수 |

다음의 경우:

- 캐시 미스, Gitaly는 `pack_objects_cache.generated_bytes` 및 `pack_objects_cache.served_bytes` 메시지를 모두 기록합니다. Gitaly는 pack-object 생성의 더 자세한 통계도 기록합니다.
- 캐시 히트, Gitaly는 `pack_objects_cache.served_bytes` 메시지만 기록합니다.

예:

```json
{
  "bytes":26186490,
  "correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
  "grpc.meta.deadline_type":"none",
  "grpc.method":"PackObjectsHook",
  "grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
  "grpc.request.glProjectPath":"root/gitlab-workhorse",
  "grpc.request.glRepository":"project-2",
  "grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
  "grpc.request.repoStorage":"default",
  "grpc.request.topLevelGroup":"@hashed",
  "grpc.service":"gitaly.HookService",
  "grpc.start_time":"2021-03-25T14:57:52.747Z",
  "level":"info",
  "msg":"finished unary call with code OK",
  "peer.address":"@",
  "pid":20961,
  "span.kind":"server",
  "system":"grpc",
  "time":"2021-03-25T14:57:53.543Z",
  "pack_objects.compression_statistics": "Total 145991 (delta 68), reused 6 (delta 2), pack-reused 145911",
  "pack_objects.enumerate_objects_ms": 170,
  "pack_objects.prepare_pack_ms": 7,
  "pack_objects.write_pack_file_ms": 786,
  "pack_objects.written_object_count": 145991,
  "pack_objects_cache.generated_bytes": 49533030,
  "pack_objects_cache.hit": "false",
  "pack_objects_cache.key": "123456789",
  "pack_objects_cache.served_bytes": 49533030,
  "peer.address": "127.0.0.1",
  "pid": 8813,
}
```

## `cat-file` 캐시 {#cat-file-cache}

많은 Gitaly RPC는 리포지토리에서 Git 개체를 찾아야 합니다. 대부분의 경우 `git cat-file --batch` 프로세스를 사용합니다. 더 나은 성능을 위해 Gitaly는 RPC 호출 전반에서 이러한 `git cat-file` 프로세스를 재사용할 수 있습니다. 이전에 사용한 프로세스는 [`git cat-file` 캐시](https://about.gitlab.com/blog/git-performance-on-nfs/#enter-cat-file-cache)에 보관됩니다. 이것이 사용하는 시스템 리소스의 양을 제어하려면 캐시로 이동할 수 있는 최대 cat-file 프로세스 수를 갖습니다.

기본 제한은 100 `cat-file`s이며, 이는 `git cat-file --batch` 및 `git cat-file --batch-check` 프로세스 쌍을 구성합니다. "너무 많은 열린 파일"에 대한 오류가 보이거나 새 프로세스를 만들 수 없으면 이 제한을 낮출 수 있습니다.

이상적으로 숫자는 표준 트래픽을 처리할 수 있을 만큼 충분히 커야 합니다. 제한을 높이면 전후의 캐시 히트율을 측정해야 합니다. 히트 비율이 개선되지 않으면 더 높은 제한이 의미 있는 차이를 만들지 못하고 있을 가능성이 높습니다. 히트율을 확인하는 Prometheus 쿼리의 예를 들어보겠습니다:

```plaintext
sum(rate(gitaly_catfile_cache_total{type="hit"}[5m])) / sum(rate(gitaly_catfile_cache_total{type=~"(hit)|(miss)"}[5m]))
```

Gitaly 구성 파일에서 `cat-file` 캐시를 구성합니다.

## GitLab UI 커밋에 대한 커밋 서명 구성 {#configure-commit-signing-for-gitlab-ui-commits}

{{< history >}}

- GitLab 16.3에서 서명된 GitLab UI 커밋에 대해 **검증됨** 배지 표시 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218) [플래그 포함](../feature_flags/_index.md) 이름 `gitaly_gpg_signing`. 기본적으로 비활성화됨.
- `rotated_signing_keys` 옵션에 지정된 여러 키를 사용한 서명 확인 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163).
- GitLab 17.0에서 GitLab Self-Managed 및 GitLab Dedicated에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876).

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서 기본적으로 이 기능을 사용할 수 있습니다. 기능을 숨기려면 관리자는 [기능 플래그 비활성화](../feature_flags/_index.md) 이름 `gitaly_gpg_signing`을(를) 수행할 수 있습니다. GitLab.com에서는 이 기능을 사용할 수 없습니다. GitLab Dedicated에서는 이 기능을 사용할 수 있습니다.

기본적으로 Gitaly는 GitLab UI를 사용하여 만든 커밋에 서명하지 않습니다. 예를 들어 사용하여 만든 커밋:

- 웹 편집기.
- 웹 IDE.
- 머지 리퀘스트.

Gitaly에서 커밋 서명을 활성화할 때:

- GitLab은 UI를 통해 모든 커밋에 서명합니다.
- 서명은 작성자의 신원이 아니라 커미터의 신원을 확인합니다.
- `committer_email` 및 `committer_name`을(를) 설정하여 커밋이 인스턴스에 의해 커밋되었음을 반영하도록 Gitaly를 구성할 수 있습니다. 예를 들어 GitLab.com에서는 이 구성 옵션이 `noreply@gitlab.com` 및 `GitLab`로 설정됩니다.

`rotated_signing_keys`은(는) 확인 전용으로 사용할 키 목록입니다. Gitaly는 구성된 `signing_key`을(를) 사용하여 웹 커밋을 확인한 다음 성공할 때까지 하나씩 회전된 키를 사용합니다. 다음 중 하나인 경우 `rotated_signing_keys` 옵션을 설정합니다:

- 서명 키가 회전됩니다.
- 여러 키를 지정하여 다른 인스턴스에서 프로젝트를 마이그레이션하고 웹 커밋을 **검증됨**으로 표시하려고 합니다.

Gitaly를 구성하여 GitLab UI로 만든 커밋에 서명하는 방법은 두 가지입니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. [GPG 키 생성](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key) 및 내보내기 또는 [SSH 키 생성](../../user/ssh.md#generate-an-ssh-key-pair). 최적의 성능을 위해 EdDSA 키를 사용합니다.

   GPG 키 내보내기:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   또는 SSH 키(암호 없음)를 생성합니다:

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Gitaly 노드에서 `/etc/gitlab/gitaly/`에 키를 복사하고 `git` 사용자가 파일을 읽을 수 있는 권한이 있는지 확인합니다.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `gitaly['git']['signing_key']`을(를) 구성합니다:

   ```ruby
   gitaly['configuration'] = {
      # ...
      git: {
        # ...
        committer_name: 'Your Instance',
        committer_email: 'noreply@yourinstance.com',
        signing_key: '/etc/gitlab/gitaly/signing_key.gpg',
        rotated_signing_keys: ['/etc/gitlab/gitaly/previous_signing_key.gpg'],
        # ...
      },
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. [GPG 키 생성](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key) 및 내보내기 또는 [SSH 키 생성](../../user/ssh.md#generate-an-ssh-key-pair). 최적의 성능을 위해 EdDSA 키를 사용합니다.

   GPG 키 내보내기:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   또는 SSH 키(암호 없음)를 생성합니다:

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Gitaly 노드에서 `/etc/gitlab`에 키를 복사합니다.
1. `/home/git/gitaly/config.toml`을(를) 편집하고 `signing_key`을(를) 구성합니다:

   ```toml
   [git]
   committer_name = "Your Instance"
   committer_email = "noreply@yourinstance.com"
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   rotated_signing_keys = ["/etc/gitlab/gitaly/previous_signing_key.gpg"]
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

## 사용자 지정 Git 구성 {#configure-custom-git-configuration}

Gitaly는 시스템 또는 사용자 수준의 Git 구성 파일을 읽지 않습니다. Gitaly 서버에서 사용자 지정 Git 구성을 제공하려면 `git.config` 설정을 사용합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집합니다:

```ruby
gitaly['configuration'] = {
  # ...
  git: {
    # ...
    config: [
      { key: "fsck.badDate", value: "ignore" },
      ...
    ],
  },
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집합니다:

```toml
[[git.config]]
key = "fsck.badDate"
value = "ignore"
```

{{< /tab >}}

{{< /tabs >}}

### Gitaly에서 설정한 Git 구성 {#git-configuration-set-by-gitaly}

Gitaly는 다음 Git 구성 값을 설정하며, `git.config` 설정을 사용하여 재정의할 수 없습니다:

- `advice.fetchShowForcedUpdates`
- `attr.tree`
- `bundle.heuristic`
- `bundle.mode`
- `bundle.version`
- `core.alternateRefsCommand`
- `core.autocrlf`
- `core.bigFileThreshold`
- `core.filesRefLockTimeout`
- `core.fsync`
- `core.fsyncMethod`
- `core.hooksPath`
- `core.packedRefsTimeout`
- `core.useReplaceRefs`
- `diff.noprefix`
- `fetch.fsck.badTimezone`
- `fetch.fsck.missingSpaceBeforeDate`
- `fetch.fsck.zeroPaddedFilemode`
- `fetch.fsckObjects`
- `fetch.negotiationAlgorithm`
- `fetch.recurseSubmodules`
- `fetch.writeCommitGraph`
- `fsck.badTimezone`
- `fsck.missingSpaceBeforeDate`
- `fsck.zeroPaddedFilemode`
- `gc.auto`
- `grep.threads`
- `http.<url>.extraHeader`
- `http.curloptResolve`
- `http.extraHeader`
- `http.followRedirects`
- `init.defaultBranch`
- `init.templateDir`
- `maintenance.auto`
- `pack.allowPackReuse`
- `pack.island`
- `pack.islandCore`
- `pack.threads`
- `pack.windowMemory`
- `pack.writeBitmapLookupTable`
- `pack.writeReverseIndex`
- `receive.advertisePushOptions`
- `receive.autogc`
- `receive.fsck.badTimezone`
- `receive.fsck.missingSpaceBeforeDate`
- `receive.fsck.zeroPaddedFilemode`
- `receive.hideRefs`
- `receive.procReceiveRefs`
- `remote.inmemory.fetch`
- `remote.inmemory.url`
- `remote.origin.fetch`
- `remote.origin.url`
- `repack.updateServerInfo`
- `repack.writeBitmaps`
- `transfer.bundleURI`
- `transfer.fsckObjects`
- `uploadpack.advertiseBundleURIs`
- `uploadpack.allowAnySHA1InWant`
- `uploadpack.allowFilter`
- `uploadpack.hideRefs`

## 외부 명령을 사용한 구성 생성 {#generate-configuration-using-an-external-command}

외부 명령을 사용하여 Gitaly 구성의 일부를 생성할 수 있습니다. 다음을 수행할 수 있습니다:

- 각 노드에 전체 구성을 배포하지 않고 노드를 구성합니다.
- 노드의 설정을 자동 검색하여 구성합니다. 예를 들어 DNS 항목을 사용합니다.
- 노드의 시작 시 비밀을 구성하여 일반 텍스트로 표시될 필요가 없습니다.

외부 명령을 사용하여 구성을 생성하려면 JSON 형식의 Gitaly 노드의 원하는 구성을 표준 출력에 덤프하는 스크립트를 제공해야 합니다.

예를 들어 다음 명령은 AWS 비밀을 사용하여 GitLab 내부 API에 연결하는 데 사용되는 HTTP 암호를 구성합니다:

```ruby
#!/usr/bin/env ruby
require 'json'
JSON.generate({"gitlab": {"http_settings": {"password": `aws get-secret-value --secret-id ...`}}})
```

그런 후 다음 두 가지 방법 중 하나로 Gitaly에 스크립트 경로를 알려야 합니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `config_command`을(를) 구성합니다:

```ruby
gitaly['configuration'] = {
    config_command: '/path/to/config_command',
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `config_command`을(를) 구성합니다:

```toml
config_command = "/path/to/config_command"
```

{{< /tab >}}

{{< /tabs >}}

구성 후 Gitaly는 시작 시 명령을 실행하고 표준 출력을 JSON으로 구문 분석합니다. 결과 구성은 다른 Gitaly 구성으로 다시 병합됩니다.

Gitaly는 다음 경우 시작에 실패합니다:

- 구성 명령이 실패합니다.
- 명령으로 생성된 출력을 유효한 JSON으로 구문 분석할 수 없습니다.

## 서버 측 백업 구성 {#configure-server-side-backups}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitaly/-/issues/4941).
- 최신 백업 대신 지정된 백업을 복원하기 위한 서버 측 지원 GitLab 16.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188).
- 증분 백업 생성을 위한 서버 측 지원 GitLab 16.6에서 [도입](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475).
- GitLab 17.0에서 Helm 차트 설치에 서버 측 지원이 추가되었습니다.

{{< /history >}}

리포지토리 백업은 각 리포지토리를 호스팅하는 Gitaly 노드가 백업 생성 및 객체 스토리지로 스트리밍을 담당하도록 구성할 수 있습니다. 이는 백업 생성 및 복원에 필요한 네트워크 리소스를 줄이는 데 도움이 됩니다.

각 Gitaly 노드를 백업을 위해 객체 스토리지에 연결하도록 구성해야 합니다.

서버 측 백업 구성 후 [서버 측 리포지토리 백업을 생성](../backup_restore/backup_gitlab.md#create-server-side-repository-backups)할 수 있습니다.

### Azure Blob 스토리지 구성 {#configure-azure-blob-storage}

백업을 위해 Azure Blob 스토리지를 구성하는 방법은 설치 유형에 따라 다릅니다. 자체 컴파일 설치의 경우 `AZURE_STORAGE_ACCOUNT` 및 `AZURE_STORAGE_KEY` 환경 변수를 GitLab 외부에서 설정해야 합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Helm 기반 배포의 경우 [Gitaly 차트의 서버 측 백업 설명서](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)를 참조하세요.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```toml
[backup]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Google Cloud 스토리지 구성 {#configure-google-cloud-storage}

Google Cloud 스토리지(GCP)는 응용 프로그램 기본 자격 증명을 사용하여 인증합니다. 다음 중 하나를 사용하여 각 Gitaly 서버에서 응용 프로그램 기본 자격 증명을 설정합니다:

- [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login) 명령.
- `GOOGLE_APPLICATION_CREDENTIALS` 환경 변수. 자체 컴파일 설치의 경우 GitLab 외부에서 환경 변수를 설정합니다.

자세한 내용은 [응용 프로그램 기본 자격 증명](https://cloud.google.com/docs/authentication/provide-credentials-adc)을(를) 참조하세요.

대상 버킷은 `go_cloud_url` 옵션을 사용하여 구성됩니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Helm 기반 배포의 경우 [Gitaly 차트의 서버 측 백업 설명서](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)를 참조하세요.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```toml
[backup]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### S3 스토리지 구성 {#configure-s3-storage}

S3 스토리지 인증을 구성하려면:

- AWS CLI로 인증하는 경우 기본 AWS 세션을 사용할 수 있습니다.
- 그렇지 않으면 `AWS_ACCESS_KEY_ID` 및 `AWS_SECRET_ACCESS_KEY` 환경 변수를 사용할 수 있습니다. 자체 컴파일 설치의 경우 GitLab 외부에서 환경 변수를 설정합니다.

자세한 내용은 [AWS 세션 설명서](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/)를 참조하세요.

대상 버킷 및 지역은 `go_cloud_url` 옵션을 사용하여 구성됩니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Helm 기반 배포의 경우 [Gitaly 차트의 서버 측 백업 설명서](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)를 참조하세요.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### S3 호환 서버 구성 {#configure-s3-compatible-servers}

S3 호환 서버는 S3과 유사하게 구성되며 `endpoint` 매개변수를 추가합니다.

지원되는 매개변수는 다음과 같습니다:

- `region`:  AWS 지역.
- `endpoint`:  엔드포인트 URL.
- `disabledSSL`:  `true`의 값은 SSL을 비활성화합니다.
- `s3ForcePathStyle`:  `true`의 값은 경로 스타일 주소 지정을 적용합니다.

{{< tabs >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Helm 기반 배포의 경우 [Gitaly 차트의 서버 측 백업 설명서](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)를 참조하세요.

{{< /tab >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => '<your_access_key_id>',
    'AWS_SECRET_ACCESS_KEY' => '<your_secret_access_key>'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`을(를) 구성합니다:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disableSSL=true&s3ForcePathStyle=true"
```

{{< /tab >}}

{{< /tabs >}}
