---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "세컨더리 Geo 사이트 설정을 완료하려면 시크릿, SSH 키를 복제하고 새로운 사이트를 프라이머리에 추가하여 데이터 동기화를 시작하세요."
title: 새로운 세컨더리 사이트 구성
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!note]
> **세컨더리** Geo 사이트 설정의 마지막 단계입니다. 설정 프로세스의 단계는 문서화된 순서대로 완료해야 합니다. 그렇지 않은 경우 진행하기 전에 [이전의 모든 단계를 완료](../setup/_index.md#using-linux-package-installations)하세요.

**세컨더리** 사이트를 구성하는 기본 단계는 다음과 같습니다:

1. **프라이머리**와 **세컨더리** 사이트 간에 필요한 구성을 복제합니다.
1. 각 **세컨더리** 사이트에서 추적 데이터베이스를 구성합니다.
1. 각 **세컨더리** 사이트에서 GitLab을 시작합니다.

이 문서는 첫 번째 항목에 중점을 둡니다. 테스트/프로덕션 환경에서 실행하기 전에 모든 단계를 먼저 읽어보시기를 권장합니다.

**both primary and secondary sites**에 대한 필수 조건:

- [데이터베이스 복제 설정](../setup/database.md)
- [승인된 SSH 키의 빠른 조회 구성](../../operations/fast_ssh_key_lookup.md)

> [!note]
> **Do not** **세컨더리** 사이트에 대한 사용자 지정 인증을 설정합니다. 이는 **프라이머리** 사이트에서 처리됩니다. **운영자** 영역에 대한 액세스가 필요한 모든 변경 사항은 **프라이머리** 사이트에서 수행해야 합니다. **세컨더리** 사이트는 읽기 전용 복제본이기 때문입니다.

## 1단계 GitLab 시크릿 값을 수동으로 복제 {#step-1-manually-replicate-secret-gitlab-values}

GitLab은 `/etc/gitlab/gitlab-secrets.json` 파일에 여러 시크릿 값을 저장하며, 이는 사이트의 모든 노드에서 동일해야 합니다. 사이트 간에 자동으로 복제할 수 있는 방법이 있을 때까지([issue #3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789) 참조), 이들은 **all nodes of the secondary site**로 수동으로 복제되어야 합니다.

1. **Rails node on your primary**로 SSH 접속하고 아래 명령을 실행하세요:

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   이것은 복제해야 할 시크릿을 JSON 형식으로 표시합니다.

1. **into each node on your secondary Geo site** SSH 접속하고 `root` 사용자로 로그인하세요:

   ```shell
   sudo -i
   ```

1. 기존 시크릿을 백업합니다:

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. `/etc/gitlab/gitlab-secrets.json`을 **Rails node on your primary**에서 **each node on your secondary**로 복사하거나, 노드 간에 파일 내용을 복사-붙여넣기하세요:

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. 파일 권한이 올바른지 확인하세요:

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. 변경 사항이 적용되도록 **each Rails, Sidekiq and Gitaly nodes on your secondary**를 재구성하세요:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

## 2단계 **프라이머리** 사이트의 SSH 호스트 키를 수동으로 복제 {#step-2-manually-replicate-the-primary-sites-ssh-host-keys}

GitLab은 시스템 설치 SSH 데몬과 통합되어 있으며, 일반적으로 `git`라는 이름의 사용자를 지정하여 모든 액세스 요청을 처리합니다.

[재해 복구](../disaster_recovery/_index.md) 상황에서 GitLab 시스템 관리자는 **세컨더리** 사이트를 **프라이머리** 사이트로 승격시킵니다. **프라이머리** 도메인에 대한 DNS 레코드도 새로운 **프라이머리** 사이트(이전 **세컨더리** 사이트)를 가리키도록 업데이트해야 합니다. 그렇게 하면 Git 리모트 및 API URL을 업데이트할 필요가 없습니다.

이로 인해 새로 승격된 **프라이머리** 사이트에 대한 모든 SSH 요청이 SSH 호스트 키 불일치로 인해 실패합니다. 이를 방지하려면 프라이머리 SSH 호스트 키를 **세컨더리** 사이트로 수동으로 복제해야 합니다.

SSH 호스트 키 경로는 사용 중인 소프트웨어에 따라 다릅니다:

- OpenSSH를 사용하는 경우 경로는 `/etc/ssh`입니다.
- [`gitlab-sshd`](../../operations/gitlab_sshd.md)을 사용하는 경우 경로는 `/var/opt/gitlab/gitlab-sshd`입니다.

다음 단계에서 `<ssh_host_key_path>`을 사용 중인 것으로 바꾸세요:

1. **each Rails node on your secondary**로 SSH 접속하고 `root` 사용자로 로그인하세요:

   ```shell
   sudo -i
   ```

1. 기존 SSH 호스트 키를 백업합니다:

   ```shell
   find <ssh_host_key_path> -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. **프라이머리** 사이트에서 SSH 호스트 키를 복사하세요:

   SSH 트래픽을 처리하는 **nodes on your primary** 중 하나에 **root** 사용자로 액세스할 수 있는 경우(일반적으로 GitLab Rails 애플리케이션 노드):

   ```shell
   # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
   scp root@<primary_node_fqdn>:<ssh_host_key_path>/ssh_host_*_key* <ssh_host_key_path>
   ```

   `sudo` 권한이 있는 사용자를 통해서만 액세스할 수 있는 경우:

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz <ssh_host_key_path>/ssh_host_*_key*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
   tar zxvf ~/geo-host-key.tar.gz -C <ssh_host_key_path>
   ```

1. **each Rails node on your secondary**에서 파일 권한이 올바른지 확인하세요:

   ```shell
   chown root:root <ssh_host_key_path>/ssh_host_*_key*
   chmod 0600 <ssh_host_key_path>/ssh_host_*_key
   ```

1. 키 지문 일치를 확인하려면 각 사이트의 프라이머리 및 세컨더리 노드 모두에서 다음 명령을 실행하세요:

   ```shell
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   다음과 같은 출력을 받아야 하며, 두 노드에서 동일해야 합니다:

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

1. 기존 프라이빗 키에 대한 올바른 공개 키가 있는지 확인하세요:

   ```shell
   # This will print the fingerprint for private keys:
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in <ssh_host_key_path>/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   > [!note]
   > 프라이빗 키 및 공개 키 명령의 출력은 동일한 지문을 생성해야 합니다.

1. OpenSSH의 경우 `sshd` 또는 **each Rails node on your secondary**의 `gitlab-sshd` 서비스를 다시 시작하세요:

   - OpenSSH의 경우:

     ```shell
     # Debian or Ubuntu installations
     sudo service ssh reload

     # CentOS installations
     sudo service sshd reload
     ```

   - `gitlab-sshd`의 경우:

     ```shell
     sudo gitlab-ctl restart gitlab-sshd
     ```

1. SSH가 여전히 작동하는지 확인하세요.

   새로운 터미널에서 GitLab **세컨더리** 서버로 SSH 접속하세요. 연결할 수 없는 경우 이전 단계에 따라 권한이 올바른지 확인하세요.

## 3단계 **세컨더리** 사이트 추가 {#step-3-add-the-secondary-site}

1. **each Rails and Sidekiq node on your secondary**로 SSH 접속하고 root로 로그인하세요:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 사이트에 대해 **unique** 이름을 추가하세요. 다음 단계에서 이것이 필요합니다:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. 변경 사항이 적용되도록 **each Rails and Sidekiq node on your secondary**를 재구성하세요:

   ```shell
   gitlab-ctl reconfigure
   ```

1. 프라이머리 노드 GitLab 인스턴스로 이동하세요:
   1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
   1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
   1. **사이트 추가**를 선택하세요. ![Geo 구성 인터페이스에서 세컨더리 사이트 추가](img/adding_a_secondary_v15_8.png)
   1. **이름**에 `/etc/gitlab/gitlab.rb`의 `gitlab_rails['geo_node_name']`에 대한 값을 입력하세요. 이 값들은 항상 **exactly** 일치해야 하며, 문자 대 문자로 일치해야 합니다.
   1. **외부 URL**에 `/etc/gitlab/gitlab.rb`의 `external_url`에 대한 값을 입력하세요. 이 값들은 항상 일치해야 하지만, 하나는 `/`로 끝나고 다른 하나는 끝나지 않아도 상관없습니다.
   1. 선택사항. **내부 URL (옵션)**에 세컨더리 사이트에 대한 내부 URL을 입력하세요.
   1. 선택사항. **세컨더리** 사이트에서 복제해야 할 그룹 또는 스토리지 샤드를 선택하세요. 모두 복제하려면 빈 상태로 두세요. 자세한 내용은 [선택적 동기화](selective_synchronization.md)를 참조하세요.
   1. **변경사항 저장**을 선택하여 **세컨더리** 사이트를 추가하세요.
1. **each Rails, and Sidekiq node on your secondary**로 SSH 접속하고 서비스를 다시 시작하세요:

   ```shell
   gitlab-ctl restart
   ```

   Geo 설정에 일반적인 문제가 있는지 확인하세요:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   확인 중 하나라도 실패하면 [문제 해결 문서](troubleshooting/_index.md)를 확인하세요.

1. **Rails or Sidekiq server on your primary**로 SSH 접속하고 root로 로그인하여 **세컨더리** 사이트에 연결할 수 있는지 확인하거나 Geo 설정에 일반적인 문제가 있는지 확인하세요:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   확인 중 하나라도 실패하면 [문제 해결 문서](troubleshooting/_index.md)를 확인하세요.

**세컨더리** 사이트가 Geo 관리 페이지에 추가되고 다시 시작되면, 사이트는 **backfill**이라고 알려진 프로세스에서 **프라이머리** 사이트에서 누락된 데이터 복제를 자동으로 시작합니다. 한편, **프라이머리** 사이트는 각 **세컨더리** 사이트에 모든 변경 사항을 알리기 시작하므로 **세컨더리** 사이트가 이러한 알림에 즉시 대응할 수 있습니다.

세컨더리 사이트가 실행 중이고 액세스 가능한지 확인하세요. 프라이머리 사이트와 동일한 자격 증명을 사용하여 세컨더리 사이트에 로그인할 수 있습니다.

### 프라이머리 및 세컨더리 URL을 허용된 ActionCable 출처로 추가 {#add-primary-and-secondary-urls-as-allowed-actioncable-origins}

이 단계는 프라이머리 및 세컨더리 사이트에서 웹소켓이 원활하게 작동하도록 합니다.

1. 사이트의 **external URLs**(프라이머리 및 세컨더리)을 수집하세요. 관리자 영역의 사이트 페이지에서 찾을 수 있습니다. 위 섹션에서 언급했듯이.
1. **primary site**의 각 Rails 및 Sidekiq 노드로 SSH 접속하고 root로 로그인하세요:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하여 1단계에서 수집한 URL을 `action_cable_allowed_origins` 설정에 추가하세요:

   ```ruby
   gitlab_rails['action_cable_allowed_origins'] = ['https://secondary.example.com', 'https://primary.example.com']
   ```

1. 변경 사항을 적용하려면 각 Rails 및 Sidekiq 노드를 재구성하고 서비스를 다시 시작하세요:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

## 4단계 (선택 사항) 사용자 지정 인증서 사용 {#step-4-optional-using-custom-certificates}

다음의 경우 이 단계를 안전하게 건너뛸 수 있습니다:

- **프라이머리** 사이트가 공개 CA에서 발급한 HTTPS 인증서를 사용합니다.
- **프라이머리** 사이트는 CA에서 발급한(자체 서명된 것이 아닌) HTTPS 인증서가 있는 외부 서비스에만 연결됩니다.

### 인바운드 연결을 위한 사용자 지정 또는 자체 서명된 인증서 {#custom-or-self-signed-certificate-for-inbound-connections}

GitLab Geo **프라이머리** 사이트가 [인바운드 HTTPS 연결을 보호하기 위한 사용자 지정 또는 자체 서명된 인증서](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)를 사용하는 경우, 이는 단일 도메인 또는 다중 도메인 인증서일 수 있습니다.

인증서 유형을 기반으로 올바른 인증서를 설치하세요:

- **Multi-domain certificate** (프라이머리 및 세컨더리 사이트 도메인 모두 포함):  인증서를 `/etc/gitlab/ssl`에서 **세컨더리** 사이트의 모든 **Rails, Sidekiq, and Gitaly** 노드에 설치하세요.
- **Single-domain certificate** (각 Geo 사이트 도메인에 특정한 인증서):  **세컨더리** 사이트의 도메인에 대해 유효한 인증서를 생성하고 `/etc/gitlab/ssl`에 설치하세요. [이러한 지침](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)에 따라 **세컨더리** 사이트의 모든 **Rails, Sidekiq, and Gitaly** 노드에서 수행하세요.

### 사용자 지정 인증서를 사용하는 외부 서비스에 연결 {#connecting-to-external-services-that-use-custom-certificates}

외부 서비스에 대한 자체 서명된 인증서의 복사본을 **프라이머리** 사이트의 모든 노드의 신뢰 저장소에 추가해야 하며, 이는 서비스에 액세스해야 합니다.

**세컨더리** 사이트가 동일한 외부 서비스에 액세스할 수 있으려면, 이 인증서를 **세컨더리** 사이트의 신뢰 저장소에 추가해야 합니다.

**프라이머리** 사이트가 [인바운드 HTTPS 연결을 위한 사용자 지정 또는 자체 서명된 인증서](#custom-or-self-signed-certificate-for-inbound-connections)를 사용하는 경우, **프라이머리** 사이트의 인증서를 **세컨더리** 사이트의 신뢰 저장소에 추가해야 합니다:

1. **Rails, Sidekiq, and Gitaly node on your secondary**로 SSH 접속하고 root로 로그인하세요:

   ```shell
   sudo -i
   ```

1. **프라이머리** 사이트에서 신뢰하는 인증서를 복사하세요:

   SSH 트래픽을 처리하는 **프라이머리** 사이트의 노드 중 하나에 root 사용자로 액세스할 수 있는 경우:

   ```shell
   scp root@<primary_site_node_fqdn>:/etc/gitlab/trusted-certs/* /etc/gitlab/trusted-certs
   ```

   sudo 권한이 있는 사용자를 통해서만 액세스할 수 있는 경우:

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-trusted-certs.tar.gz /etc/gitlab/trusted-certs/*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_node_fqdn>:geo-trusted-certs.tar.gz .
   tar zxvf ~/geo-trusted-certs.tar.gz -C /etc/gitlab/trusted-certs
   ```

1. 업데이트된 **Rails, Sidekiq, and Gitaly node in your secondary**를 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 5단계 **세컨더리** 사이트의 올바른 작동 확인 {#step-5-verify-proper-functioning-of-the-secondary-site}

**세컨더리** 사이트에 **프라이머리** 사이트에 사용한 것과 동일한 자격 증명으로 로그인할 수 있습니다. 로그인한 후:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. **세컨더리** Geo 사이트로 올바르게 식별되었는지 그리고 Geo가 활성화되었는지 확인하세요.

초기 복제에는 시간이 걸릴 수 있습니다. 사이트 상태 또는 '백필'이 아직 진행 중일 수 있습니다. 브라우저에서 **프라이머리** 사이트의 **Geo 사이트** 대시보드에서 각 Geo 사이트의 동기화 프로세스를 모니터링할 수 있습니다.

![세컨더리 사이트의 Geo 대시보드](img/geo_dashboard_v14_0.png)

설치가 제대로 작동하지 않으면 [문제 해결 문서](troubleshooting/_index.md)를 확인하세요.

대시보드에서 명백해질 수 있는 두 가지 주요 문제는 다음과 같습니다:

1. 데이터베이스 복제가 제대로 작동하지 않음.
1. 인스턴스 간 알림이 작동하지 않음. 그 경우 다음 중 하나일 수 있습니다:
   - 사용자 지정 인증서 또는 사용자 지정 CA를 사용 중입니다([문제 해결 문서](troubleshooting/_index.md) 참조).
   - 인스턴스가 방화벽으로 보호되어 있습니다(방화벽 규칙을 확인하세요).

**세컨더리** 사이트를 비활성화하면 동기화 프로세스가 중지됩니다.

리포지토리 스토리지가 **프라이머리** 사이트에서 여러 리포지토리 샤드에 대해 사용자 지정된 경우, 각 **세컨더리** 사이트에서 동일한 구성을 복제해야 합니다.

사용자들에게 [Geo 사이트 사용 가이드](usage.md)를 참조하도록 안내하세요.

현재 동기화되는 항목은 다음과 같습니다:

- Git 리포지토리.
- 위키.
- LFS 객체.
- 이슈, 머지 리퀘스트, 스니펫 및 댓글 첨부 파일.
- 사용자, 그룹 및 프로젝트 아바타.

## 문제 해결 {#troubleshooting}

[문제 해결 문서](troubleshooting/_index.md)를 참조하세요.
