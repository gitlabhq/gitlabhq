---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 Sidekiq 인스턴스 구성
description: 외부 Sidekiq 인스턴스를 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 패키지에 포함된 Sidekiq를 사용하여 외부 Sidekiq 인스턴스를 구성할 수 있습니다. Sidekiq는 Redis, PostgreSQL 및 Gitaly 인스턴스에 대한 연결이 필요합니다.

## GitLab 인스턴스에서 PostgreSQL, Gitaly 및 Redis에 대한 TCP 액세스 구성 {#configure-tcp-access-for-postgresql-gitaly-and-redis-on-the-gitlab-instance}

기본적으로 GitLab은 UNIX 소켓을 사용하며 TCP를 통해 통신하도록 설정되지 않습니다. 이를 변경하려면:

1. [TCP/IP에서 수신 대기하도록 패키지된 PostgreSQL 서버 구성](https://docs.gitlab.com/omnibus/settings/database/#configure-packaged-postgresql-server-to-listen-on-tcpip) 및 Sidekiq 서버 IP 주소를 `postgresql['md5_auth_cidr_addresses']`에 추가
1. [TCP를 통해 번들된 Redis에 도달 가능하게 만들기](https://docs.gitlab.com/omnibus/settings/redis/#making-the-bundled-redis-reachable-via-tcp)
1. GitLab 인스턴스에서 `/etc/gitlab/gitlab.rb` 파일을 편집하고 다음을 추가합니다:

   ```ruby
   ## Gitaly
   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces
      listen_addr: '0.0.0.0:8075',
      auth: {
         ## Set up the Gitaly token as a form of authentication because you are accessing Gitaly over the network
         ## https://docs.gitlab.com/administration/gitaly/configure_gitaly/#about-the-gitaly-token
         token: 'abc123secret',
      },
   }

   gitlab_rails['gitaly_token'] = 'abc123secret'

   # Password to Authenticate Redis
   gitlab_rails['redis_password'] = 'redis-password-goes-here'
   ```

1. `reconfigure`을 실행합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `PostgreSQL` 서버를 다시 시작합니다:

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

## Sidekiq 인스턴스 설정 {#set-up-sidekiq-instance}

[사용자의 참조 아키텍처](../reference_architectures/_index.md#available-reference-architectures)를 찾고 Sidekiq 인스턴스 설정 세부 정보를 따르세요.

## 공유 스토리지가 있는 여러 Sidekiq 노드 구성 {#configure-multiple-sidekiq-nodes-with-shared-storage}

NFS와 같은 공유 파일 스토리지가 있는 여러 Sidekiq 노드를 실행하는 경우 서버 간에 일치하도록 UID 및 GID를 지정해야 합니다. UID 및 GID를 지정하면 파일 시스템의 권한 이슈가 방지됩니다. 이 조언은 [Geo 설정에 대한 조언](../geo/replication/multiple_servers.md#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site)과 유사합니다.

여러 Sidekiq 노드를 설정하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 외부 Sidekiq를 사용할 때 컨테이너 레지스트리 구성 {#configure-the-container-registry-when-using-an-external-sidekiq}

컨테이너 레지스트리를 사용 중이고 Sidekiq와 다른 노드에서 실행 중인 경우 아래 단계를 따르세요.

1. `/etc/gitlab/gitlab.rb`을 편집하고 레지스트리 URL을 구성합니다:

   ```ruby
   gitlab_rails['registry_api_url'] = "https://registry.example.com"
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 컨테이너 레지스트리가 호스팅되는 인스턴스에서 `registry.key` 파일을 Sidekiq 노드에 복사합니다.

## Sidekiq 메트릭 서버 구성 {#configure-the-sidekiq-metrics-server}

Sidekiq 메트릭을 수집하려면 Sidekiq 메트릭 서버를 활성화합니다. 메트릭을 `localhost:8082/metrics`에서 사용 가능하게 만들려면:

메트릭 서버를 구성하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   sidekiq['metrics_enabled'] = true
   sidekiq['listen_address'] = "localhost"
   sidekiq['listen_port'] = 8082

   # Optionally log all the metrics server logs to log/sidekiq_exporter.log
   sidekiq['exporter_log_enabled'] = true
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### HTTPS 활성화 {#enable-https}

{{< history >}}

- GitLab 15.2에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/364771).

{{< /history >}}

HTTP 대신 HTTPS를 통해 메트릭을 제공하려면 내보내기 설정에서 TLS를 활성화합니다:

1. `/etc/gitlab/gitlab.rb`을 편집하여 다음 줄을 추가(또는 찾아서 주석 해제)합니다:

   ```ruby
   sidekiq['exporter_tls_enabled'] = true
   sidekiq['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   sidekiq['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

TLS를 활성화하면 이전에 설명한 대로 동일한 `port`과 `address`가 사용됩니다. 메트릭 서버는 HTTP와 HTTPS를 동시에 제공할 수 없습니다.

## 상태 확인 구성 {#configure-health-checks}

상태 확인 프로브를 사용하여 Sidekiq를 관찰하려면 Sidekiq 상태 확인 서버를 활성화합니다. 상태 확인을 `localhost:8092`에서 사용 가능하게 만들려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   sidekiq['health_checks_enabled'] = true
   sidekiq['health_checks_listen_address'] = "localhost"
   sidekiq['health_checks_listen_port'] = 8092
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

상태 확인에 대한 자세한 내용은 [Sidekiq 상태 확인 페이지](sidekiq_health_check.md)를 참조하세요.

## LDAP 및 사용자 또는 그룹 동기화 구성 {#configure-ldap-and-user-or-group-synchronization}

사용자 및 그룹 관리를 위해 LDAP를 사용하는 경우 LDAP 동기화 작업자뿐만 아니라 Sidekiq 노드에 LDAP 구성을 추가해야 합니다. LDAP 구성 및 LDAP 동기화 작업자가 Sidekiq 노드에 적용되지 않으면 사용자 및 그룹이 자동으로 동기화되지 않습니다.

GitLab용 LDAP 구성에 대한 자세한 내용은 다음을 참조하세요:

- [GitLab LDAP 구성 문서](../auth/ldap/_index.md#configure-ldap)
- [LDAP 동기화 문서](../auth/ldap/ldap_synchronization.md#adjust-ldap-sync-schedule)

Sidekiq에 대해 동기화 작업자를 사용하여 LDAP를 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['prevent_ldap_sign_in'] = false
   gitlab_rails['ldap_servers'] = {
   'main' => {
   'label' => 'LDAP',
   'host' => 'ldap.mydomain.com',
   'port' => 389,
   'uid' => 'sAMAccountName',
   'encryption' => 'simple_tls',
   'verify_certificates' => true,
   'bind_dn' => '_the_full_dn_of_the_user_you_will_bind_with',
   'password' => '_the_password_of_the_bind_user',
   'tls_options' => {
      'ca_file' => '',
      'ssl_version' => '',
      'ciphers' => '',
      'cert' => '',
      'key' => ''
   },
   'timeout' => 10,
   'active_directory' => true,
   'allow_username_or_email_login' => false,
   'block_auto_created_users' => false,
   'base' => 'dc=example,dc=com',
   'user_filter' => '',
   'attributes' => {
      'username' => ['uid', 'userid', 'sAMAccountName'],
      'email' => ['mail', 'email', 'userPrincipalName'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
   },
   'lowercase_usernames' => false,

   # Enterprise Edition only
   # https://docs.gitlab.com/administration/auth/ldap/ldap_synchronization/
   'group_base' => '',
   'admin_group' => '',
   'external_groups' => [],
   'sync_ssh_keys' => false
   }
   }
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## SAML 그룹 동기화를 위해 SAML 그룹 구성 {#configure-saml-groups-for-saml-group-sync}

[SAML 그룹 동기화](../../user/group/saml_sso/group_sync.md) 를 사용하는 경우 모든 Sidekiq 노드에서 [SAML 그룹](../../integration/saml.md#configure-users-based-on-saml-group-membership)을 구성해야 합니다.

## 관련 항목 {#related-topics}

- [추가 Sidekiq 프로세스](extra_sidekiq_processes.md)
- [특정 작업 클래스 처리](processing_specific_job_classes.md)
- [Sidekiq 상태 확인](sidekiq_health_check.md)
- [GitLab-Sidekiq 차트 사용](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)

## 문제 해결 {#troubleshooting}

[Sidekiq 문제 해결 관리자 가이드](sidekiq_troubleshooting.md)를 참조하세요.
