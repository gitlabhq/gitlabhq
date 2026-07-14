---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 인스턴스를 위해 OpenSSH의 가벼운 대안을 구성합니다.
title: '`gitlab-sshd`'
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

`gitlab-sshd`은 Go로 작성된 [독립 실행형 SSH 서버](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd)입니다. OpenSSH의 가벼운 대안입니다. `gitlab-shell` 패키지의 일부이며 [SSH 작업](https://gitlab.com/gitlab-org/gitlab-shell/-/blob/71a7f34a476f778e62f8fe7a453d632d395eaf8f/doc/features.md)을 처리합니다.

OpenSSH는 제한된 셸 방식을 사용하는 반면 `gitlab-sshd`은:

- 최신 멀티스레드 서버 애플리케이션으로 작동합니다.
- SSH 전송 프로토콜 대신 원격 프로시저 호출(RPC)을 사용합니다.
- OpenSSH보다 적은 메모리를 사용합니다.
- 프록시 뒤에서 실행되는 애플리케이션을 위해 [IP 주소별 그룹 액세스 제한](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address)을 지원합니다.

구현에 대한 자세한 내용은 [블로그 글](https://about.gitlab.com/blog/why-we-have-implemented-our-own-sshd-solution-on-gitlab-sass/)을 참조하세요.

OpenSSH에서 `gitlab-sshd`로 전환을 고려 중이라면 다음을 고려하세요:

- PROXY 프로토콜: `gitlab-sshd`은 PROXY 프로토콜을 지원하므로 HAProxy와 같은 프록시 서버 뒤에서 실행될 수 있습니다. 이 기능은 기본적으로 활성화되지 않지만 [활성화할 수 있습니다](#proxy-protocol-support).
- SSH 인증서: `gitlab-sshd`은 `config.yml`에서 구성된 신뢰할 수 있는 CA 키를 사용하여 인스턴스 수준의 SSH 인증서 인증을 지원합니다. 자세한 내용은 [`gitlab-sshd`를 사용한 인스턴스 수준의 SSH 인증서](gitlab_sshd_ssh_certificates.md)를 참조하세요.
- 2FA 복구 코드: `gitlab-sshd`은 2FA 복구 코드 재생성을 지원하지 않습니다. `2fa_recovery_codes`를 실행하려고 하면 오류가 발생합니다: `remote: ERROR: Unknown command: 2fa_recovery_codes`. 자세한 내용은 [토론](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/766#note_1906707753)을 참조하세요.

GitLab Shell의 기능은 Git 작업을 초과하며 GitLab과의 다양한 SSH 기반 상호 작용에 사용할 수 있습니다.

## `gitlab-sshd` 활성화 {#enable-gitlab-sshd}

`gitlab-sshd`을 사용하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

다음 지침은 `gitlab-sshd`을 OpenSSH와 다른 포트에서 활성화합니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_sshd['enable'] = true
   gitlab_sshd['listen_address'] = '[::]:2222' # Adjust the port accordingly
   ```

1. 선택사항. 기본적으로 Linux 패키지 설치는 `gitlab-sshd`에 대한 SSH 호스트 키를 생성합니다(키가 `/var/opt/gitlab/gitlab-sshd`에 존재하지 않는 경우). 이 자동 생성을 비활성화하려면 다음 줄을 추가하세요:

   ```ruby
   gitlab_sshd['generate_host_keys'] = false
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

기본적으로 `gitlab-sshd`은 `git` 사용자로 실행됩니다. 따라서 `gitlab-sshd`은 1024보다 낮은 권한 있는 포트 번호에서 실행할 수 없습니다. 이는 사용자가 `gitlab-sshd` 포트로 Git에 액세스하거나 SSH 트래픽을 `gitlab-sshd` 포트로 보내는 로드 밸런서를 사용해야 함을 의미합니다.

사용자는 새로 생성된 호스트 키가 OpenSSH 호스트 키와 다르기 때문에 호스트 키 경고를 볼 수 있습니다. 이것이 문제인 경우 호스트 키 생성을 비활성화하고 기존 OpenSSH 호스트 키를 `/var/opt/gitlab/gitlab-sshd`에 복사하는 것을 고려하세요.

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

다음 지침은 OpenSSH를 `gitlab-sshd`로 전환합니다:

1. `gitlab-shell` 차트의 `sshDaemon` 옵션을 [`gitlab-sshd`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options)로 설정합니다. 예를 들어:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
   ```

1. Helm 업그레이드를 수행합니다.

기본적으로 `gitlab-sshd`은 다음을 수신합니다:

- 포트 22의 외부 요청(`global.shell.port`).
- 포트 2222의 내부 요청(`gitlab.gitlab-shell.service.internalPort`).

[Helm 차트에서 다양한 포트를 구성](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#configuration)할 수 있습니다.

{{< /tab >}}

{{< /tabs >}}

## PROXY 프로토콜 지원 {#proxy-protocol-support}

`gitlab-sshd` 앞의 로드 밸런서는 GitLab이 클라이언트 IP 주소 대신 프록시 IP 주소를 보고하도록 합니다. 실제 IP 주소를 얻으려면 `gitlab-sshd`는 [PROXY 프로토콜](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)을 지원합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

PROXY 프로토콜을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_sshd['proxy_protocol'] = true
   # Proxy protocol policy ("use", "require", "reject", "ignore"), "use" is the default value
   gitlab_sshd['proxy_policy'] = "use"
   ```

   `gitlab_sshd['proxy_policy']` 옵션에 대한 자세한 내용은 [`go-proxyproto` 라이브러리](https://github.com/pires/go-proxyproto/blob/4ba2eb817d7a57a4aafdbd3b82ef0410806b533d/policy.go#L20-L35)를 참조하세요.

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [`gitlab.gitlab-shell.config` 옵션](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options)을 설정합니다. 예를 들어:

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         proxyProtocol: true
         proxyPolicy: "use"
   ```

1. Helm 업그레이드를 수행합니다.

{{< /tab >}}

{{< /tabs >}}
