---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 강화 - 운영 체제 권장 사항
---

일반 하드닝 가이드라인은 [주요 하드닝 설명서](hardening.md)에 설명되어 있습니다.

기본 운영 체제를 구성하여 전체 보안을 강화할 수 있습니다. GitLab Self-Managed 같은 제어된 환경에서는 추가 단계가 필요하며, 실제로 특정 배포에는 필수입니다. FedRAMP은 이러한 배포의 한 예입니다.

## SSH 구성 {#ssh-configuration}

### SSH 클라이언트 구성 {#ssh-client-configuration}

클라이언트 액세스(GitLab 인스턴스 또는 기본 운영 체제 중 하나)의 경우, SSH 키 생성에 대한 몇 가지 권장 사항을 다음과 같습니다. 첫 번째는 일반적인 SSH 키입니다:

```shell
ssh-keygen -a 64 -t ed25519 -f ~/.ssh/id_ed25519 -C "ED25519 Key"
```

FIPS 준수 SSH 키의 경우 다음을 사용합니다:

```shell
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "RSA FIPS-compliant Key"
```

### SSH 서버 구성 {#ssh-server-configuration}

운영 체제 수준에서 SSH 액세스를 허용하는 경우(일반적으로 OpenSSH를 통해) `sshd_config` 파일의 구성 옵션 예는 다음과 같습니다(정확한 위치는 운영 체제에 따라 다를 수 있지만 일반적으로 `/etc/ssh/sshd_config`입니다):

```shell
#
# Example sshd config file. This supports public key authentication and
# turns off several potential security risk areas
#
PubkeyAuthentication yes
PasswordAuthentication yes
UsePAM yes
UseDNS no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
PermitTunnel no
PermitRootLogin no

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# Change default of 120 seconds to 60
LoginGraceTime 60

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Protocol adjustments, these would be needed/recommended in a FIPS or
# FedRAMP deployment, and use only strong and proven algorithm choices
Protocol 2
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
HostKeyAlgorithms ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521
KexAlgorithms ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521
Macs hmac-sha2-256,hmac-sha2-512

```

## 방화벽 규칙 {#firewall-rules}

방화벽 규칙의 경우 TCP 포트 `80`와 `443`만 기본 사용을 위해 열면 됩니다. 기본적으로 `5050`는 컨테이너 레지스트리에 대한 원격 액세스를 위해 열려 있습니다. 그러나 강화된 환경에서는 대부분 다른 호스트에 있을 수 있으며, 일부 환경에서는 완전히 열려 있지 않을 수도 있습니다. 따라서 포트 `80`와 `443`만 권장되며, 포트 `80`는 `443`로 리다이렉션하는 데만 사용되어야 합니다.

FedRAMP 같은 진정한 강화되거나 격리된 환경의 경우, 방화벽 규칙을 조정하여 액세스하는 네트워크를 제외한 모든 포트를 제한해야 합니다. 예를 들어 IP 주소가 `192.168.1.2`이고 모든 인증된 클라이언트도 `192.168.1.0/24`에 있는 경우, 다른 방화벽을 통해 액세스가 제한되어 있어도 포트 `80`와 `443`에 대한 액세스를 `192.168.1.0/24` 만으로 제한합니다(보안 제한으로).

GitLab Self-Managed 인스턴스를 설치하는 경우, 설치가 시작되기 전에 방화벽 규칙을 구현하고 관리자 및 설치자에게만 액세스를 제한한 다음 인스턴스가 설치되고 적절히 강화된 후에만 사용자를 위해 추가 IP 주소 범위를 추가합니다.

`iptables` 또는 `ufw` 사용은 호스트 기반으로 포트 `80`과 `443` 액세스를 구현하고 시행하기 위해 허용되며, 그렇지 않으면 GCP Google Compute 또는 AWS Security Groups를 통한 클라우드 기반 방화벽 규칙 사용이 이를 시행합니다. 다른 모든 포트는 차단되어야 하거나 최소한 특정 범위로 제한되어야 합니다. 포트에 대한 자세한 내용은 [패키지 기본값](../administration/package_information/defaults.md)을 참조합니다.

## GitLab 인스턴스에서 아웃바운드 연결 허용 {#allow-outbound-connections-from-the-gitlab-instance}

 아웃바운드 및 인바운드 설정을 모두 확인합니다:

- 방화벽 및 HTTP/S 프록시 서버는 `cloud.gitlab.com`와 `customers.gitlab.com`에 대한 아웃바운드 연결을 포트 `443`에서 `https://`와 함께 허용해야 합니다. 이러한 호스트는 Cloudflare로 보호됩니다. 방화벽 설정을 업데이트하여 [Cloudflare가 게시하는 IP 범위 목록](https://www.cloudflare.com/ips/)의 모든 IP 주소로의 트래픽을 허용합니다.
- HTTP/S 프록시를 사용하려면 `gitLab_workhorse`과 `gitLab_rails` 모두 필요한 [웹 프록시 환경 변수](https://docs.gitlab.com/omnibus/settings/environment-variables/)를 설정해야 합니다.
- 다중 노드 GitLab 설치에서 모든 **레일** 및 **Sidekiq** 노드에 HTTP/S 프록시를 구성합니다.
- GitLab Self-Managed에서 GitLab Duo를 구성하려면 [GitLab 인스턴스에서 GitLab Duo로의 아웃바운드 연결을 허용](../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)합니다.

### 방화벽 추가 {#firewall-additions}

다양한 서비스를 활성화하여 외부 액세스가 필요할 수 있으며(예: Sidekiq) 네트워크 액세스를 열어야 합니다. 이러한 유형의 서비스를 특정 IP 주소 또는 특정 클래스 C로 제한합니다. 계층화된 추가 예방 조치로, 가능한 경우 이러한 추가 서비스를 GitLab의 특정 노드 또는 서브네트워크로 제한합니다.

## 커널 조정 {#kernel-adjustments}

커널 조정은 `/etc/sysctl.conf`을 편집하거나 `/etc/sysctl.d/`의 파일 중 하나를 편집하여 수행할 수 있습니다. 커널 조정은 공격 위협을 완전히 제거하지는 못하지만 보안의 추가 계층을 추가합니다. 다음 참고 사항은 이러한 조정의 일부 장점을 설명합니다.

```shell
## Kernel tweaks for sysctl.conf ##
##
## The following help mitigate out of bounds, null pointer dereference, heap and
## buffer overflow bugs, use-after-free etc from being exploited. It does not 100%
## fix the issues, but seriously hampers exploitation.
##
# Default is 65536. Higher values provide stronger protection against NULL-pointer dereference exploits.
# Use 4096 only if required for application compatibility, as it reduces the range of protected low memory addresses.
vm.mmap_min_addr=4096
# Default is 0, randomize virtual address space in memory, makes vuln exploitation
# harder
kernel.randomize_va_space=2
# Restrict kernel pointer access (for example, cat /proc/kallsyms) for exploit assistance
kernel.kptr_restrict=2
# Restrict verbose kernel errors in dmesg
kernel.dmesg_restrict=1
# Restrict eBPF
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
# Prevent common use-after-free exploits
vm.unprivileged_userfaultfd=0
# Mitigation CVE-2024-1086 by preventing unprivileged users from creating namespaces
kernel.unprivileged_userns_clone=0

## Networking tweaks ##
##
## Prevent common attacks at the IP stack layer
##
# Prevent SYNFLOOD denial of service attacks
net.ipv4.tcp_syncookies=1
# Prevent time wait assassination attacks
net.ipv4.tcp_rfc1337=1
# IP spoofing/source routing protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.accept_ra=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
# IP redirection protection
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
```
