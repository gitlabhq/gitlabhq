---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hardening - Operating System Recommendations
---

General hardening guidelines are outlined in the [main hardening documentation](hardening.md).

You can configure the underlying operating system to increase overall security. In a
controlled environment such as GitLab Self-Managed it requires additional
steps, and in fact is often required for certain deployments. FedRAMP is an example of
such a deployment.

## SSH Configuration

### SSH Client Configuration

For client access (either to the GitLab instance or to the underlying operating
system), here are a couple of recommendations for SSH key generation. The first one
is a typical SSH key:

```shell
ssh-keygen -a 64 -t ed25519 -f ~/.ssh/id_ed25519 -C "ED25519 Key"
```

For a FIPS-compliant SSH key, use the following:

```shell
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "RSA FIPS-compliant Key"
```

### SSH Server Configuration

At the operating system level, if you are allowing SSH access (typically through
OpenSSH), here is an example of configuration options for the `sshd_config` file
(the exact location may vary depending on the operating system but it is usually
`/etc/ssh/sshd_config`):

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

# Change default od 120 seconds to 60
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

## Firewall Rules

For firewall rules, only TCP ports `80` and `443` need to be open for basic usage. By
default, `5050` is open for remote access to the container registry, however in a
hardened environment this would most likely exist on a different host, and in some
environments not open at all. Hence, the recommendation is for ports `80` and `443`
only, and port `80` should only be used to redirect to `443`.

For a truly hardened or isolated environment such as FedRAMP, you should adjust the firewall rules to restrict all ports except to those networks
accessing it. For example, if the IP address is `192.168.1.2` and all of the authorized
clients are also on `192.168.1.0/24`, restrict access to ports `80` and `443` to just
`192.168.1.0/24` only (as a safety restriction), even if access is restricted
elsewhere with another firewall.

Ideally, if you're installing a self-managed instance, you should implement the firewall rules before the installation begins with access restricted to the admins and installers, and only add additional ranges of IP addresses for
users after the instance is installed and properly hardened.

Usage of `iptables` or `ufw` is acceptable to implement and enforce port `80` and `443`
access on a per-host basis, otherwise usage of cloud-based firewall rules through GCP
Google Compute or AWS Security Groups should enforce this. All other ports should
be blocked, or at least restricted to specific ranges. For more information on ports, see
[Package Defaults](../administration/package_information/defaults.md).

### Firewall Additions

It is possible that various services may be enabled that require external access
(for example Sidekiq) and need network access to be opened up. Restrict these types
of services to specific IP addresses, or a specific Class C. As a layered and added
precaution, where possible restrict these extra services to specific nodes or
sub-networks in GitLab.

## Kernel Adjustments

Kernel adjustments can be made by editing `/etc/sysctl.conf`, or one of the files in
`/etc/sysctl.d/`. Kernel adjustments do not completely eliminate the threat of an
attack, but add an extra layer of security. The following notes explain
some of the advantages for these adjustments.

```shell
## Kernel tweaks for sysctl.conf ##
##
## The following help mitigate out of bounds, null pointer dereference, heap and
## buffer overflow bugs, use-after-free etc from being exploited. It does not 100%
## fix the issues, but seriously hampers exploitation.
##
# Default is 65536, 4096 helps mitigate memory issues used in exploitation
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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
