---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 강화 - 구성 권장 사항
---

일반 하드닝 가이드라인은 [주요 하드닝 설명서](hardening.md)에 설명되어 있습니다.

GitLab 인스턴스에 대한 일부 강화 권장 사항에는 추가 서비스 또는 구성 파일을 통한 제어가 포함됩니다. 알림으로, 구성 파일을 변경할 때마다 편집하기 전에 백업 사본을 만드세요. 또한 많은 변경을 진행하는 경우 모든 변경을 한 번에 수행하지 않고 각 변경 후에 테스트하여 모든 것이 작동하는지 확인하는 것이 좋습니다.

## NGINX {#nginx}

NGINX는 GitLab 인스턴스에 접근하는 데 사용되는 웹 인터페이스를 제공하는 데 사용됩니다. NGINX는 GitLab에 의해 제어되고 통합되므로 `/etc/gitlab/gitlab.rb` 파일을 수정하여 조정할 수 있습니다. NGINX 자체의 보안을 개선하는 데 도움이 되는 몇 가지 권장 사항은 다음과 같습니다:

1. [Diffie-Hellman 키](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_dhparam)를 생성합니다:

   ```shell
   sudo openssl dhparam -out /etc/gitlab/ssl/dhparam.pem 4096
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음을 추가합니다:

   ```ruby
   #
   # Only strong ciphers are used
   #
   nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256"
   #
   # Follow preferred ciphers and the order listed as preference
   #
   nginx['ssl_prefer_server_ciphers'] = "on"
   #
   # Only allow TLSv1.2 and TLSv1.3
   #
   nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"

   ##! **Recommended in: https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_cache'] = "builtin:1000 shared:SSL:10m"

   ##! **Default according to https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_timeout'] = "5m"

   # Should prevent logjam attack etc
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparam.pem" # changed from nil

   # Turn off session ticket reuse
   nginx['ssl_session_tickets'] = "off"
   # Pick our own curve instead of what openssl hands us
   nginx['ssl_ecdh_curve'] = "secp384r1"
   ```

1. GitLab을 재구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Consul {#consul}

Consul은 GitLab 환경에 통합될 수 있으며 더 큰 배포를 위한 것입니다. 일반적으로 1000명 미만의 사용자가 있는 자체 관리 및 독립형 배포의 경우 Consul이 필요하지 않을 수 있습니다. 필요한 경우 먼저 [Consul 설명서](../administration/consul.md)를 검토하되, 더 중요한 것은 통신 중에 암호화가 사용되는지 확인합니다. Consul에 대한 자세한 내용은 [HashiCorp 웹사이트](https://developer.hashicorp.com/consul/docs)를 방문하여 작동 방식을 이해하고 [암호화 보안](https://developer.hashicorp.com/consul/docs/security/encryption)에 대한 정보를 검토합니다.

## 환경 변수 {#environment-variables}

자체 관리 시스템에서 여러 [환경 변수](https://docs.gitlab.com/omnibus/settings/environment-variables/)를 사용자 정의할 수 있습니다. 보안 관점에서 활용할 수 있는 주요 환경 변수는 설치 프로세스 중 `GITLAB_ROOT_PASSWORD`입니다. 공개적으로 노출된 IP 주소가 있는 자체 관리 시스템을 설치하는 경우 암호가 강력한 것으로 설정되어 있는지 확인합니다. 역사적으로 모든 유형의 공개 서비스(GitLab이든 다른 애플리케이션이든)를 설정하면 그 시스템이 발견되는 즉시 기회 공격이 발생하므로 강화 프로세스는 설치 프로세스 중에 시작되어야 합니다.

[운영 체제 권장 사항](hardening_operating_system_recommendations.md)에서 언급했듯이 이상적으로는 GitLab 설치가 시작되기 전에 방화벽 규칙이 이미 준비되어 있어야 하지만, `GITLAB_ROOT_PASSWORD`를 통해 설치 전에 여전히 안전한 암호를 설정해야 합니다.

## Git 프로토콜 {#git-protocols}

권한이 있는 사용자만 Git 접근을 위해 SSH를 사용하고 있는지 확인하려면 `/etc/ssh/sshd_config` 파일에 다음을 추가합니다:

```shell
# Ensure only authorized users are using Git
AcceptEnv GIT_PROTOCOL
```

이를 통해 사용자는 SSH를 통해 `git` 작업을 수행할 수 있는 유효한 GitLab 계정이 없으면 SSH를 사용하여 프로젝트를 다운로드할 수 없습니다. 자세한 내용은 [Git 프로토콜 구성](../administration/git_protocol.md)을 참조합니다.

## 수신 이메일 {#incoming-email}

GitLab Self-Managed를 구성하여 GitLab 인스턴스에 등록된 사용자가 이메일을 주석 달기 또는 이슈를 생성하거나 머지 리퀘스트를 만드는 데 사용할 수 있도록 합니다. 강화된 환경에서는 이 기능이 외부 통신이 정보를 보내는 것을 포함하므로 구성하지 않아야 합니다.

이 기능이 필요한 경우 [수신 이메일 설명서](../administration/incoming_email.md)의 지침을 따르고 최대 보안을 보장하기 위한 다음 권장 사항을 따릅니다:

- 인스턴스에 대한 수신 이메일을 위해 특히 이메일 주소를 지정합니다.
- [이메일 부분 주소 지정](../administration/incoming_email.md)을 사용합니다.
- 사용자가 이메일을 보내는 데 사용하는 이메일 계정에는 다중 인증(MFA)이 필요하고 해당 계정에서 사용하도록 설정되어야 합니다.
- Postfix의 경우 [수신 이메일을 위해 Postfix 설정 설명서](../administration/reply_by_email_postfix_setup.md)를 따릅니다.

## Redis 복제 및 장애 조치 {#redis-replication-and-failover}

Redis는 Linux 패키지 설치에서 복제 및 장애 조치에 사용되며 확장이 해당 기능을 필요로 할 때 설정할 수 있습니다. 이 경우 Redis의 경우 TCP 포트 `6379`을 열고 Sentinel의 경우 `26379`을 엽니다. [복제 및 장애 조치 설명서](../administration/redis/replication_and_failover.md)를 따르되 모든 노드의 IP 주소를 기록하고 다른 노드만 해당 특정 포트에 접근할 수 있도록 노드 간의 방화벽 규칙을 설정합니다.

## Sidekiq 구성 {#sidekiq-configuration}

[외부 Sidekiq 구성 지침](../administration/sidekiq/_index.md)에는 IP 범위 구성에 대한 수많은 참조가 있습니다. [HTTPS 구성](../administration/sidekiq/_index.md#enable-https)을 반드시 수행해야 하며 해당 IP 주소를 Sidekiq이 통신하는 특정 시스템으로 제한하는 것을 고려합니다. 운영 체제 수준에서 방화벽 규칙도 조정해야 할 수 있습니다.

## S/MIME 이메일 서명 {#smime-signing-of-email}

GitLab 인스턴스가 사용자에게 이메일 알림을 보내도록 구성된 경우 S/MIME 서명을 구성하여 수신자가 이메일이 합법적인지 확인할 수 있도록 합니다. [발신 이메일 서명](../administration/smime_signing_email.md)의 지침을 따릅니다.

## 컨테이너 레지스트리 {#container-registry}

Lets Encrypt가 구성된 경우 컨테이너 레지스트리는 기본적으로 활성화됩니다. 이를 통해 프로젝트는 자신의 Docker 이미지를 저장할 수 있습니다. [컨테이너 레지스트리](../administration/packages/container_registry.md) 구성 지침을 따르면 새 프로젝트에서 자동 활성화를 제한하고 컨테이너 레지스트리를 완전히 비활성화하는 등의 작업을 수행할 수 있습니다. 액세스를 허용하기 위해 방화벽 규칙을 조정해야 할 수 있습니다. 완전히 독립형 시스템인 경우 컨테이너 레지스트리에 대한 액세스를 로컬호스트 전용으로 제한해야 합니다. 사용되는 포트 및 해당 구성의 구체적인 예는 설명서에도 포함되어 있습니다.
