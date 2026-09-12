---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Renforcement de la sécurité - Recommandations sur le système d'exploitation"
---

Les directives générales de renforcement de la sécurité sont décrites dans la [documentation principale sur le renforcement de la sécurité](hardening.md).

Vous pouvez configurer le système d'exploitation sous-jacent pour améliorer la sécurité globale. Dans un environnement contrôlé tel que GitLab Self-Managed, des étapes supplémentaires sont nécessaires, et celles-ci sont en fait souvent requises pour certains déploiements. FedRAMP est un exemple d'un tel déploiement.

## Configuration SSH {#ssh-configuration}

### Configuration du client SSH {#ssh-client-configuration}

Pour l'accès client (à l'instance GitLab ou au système d'exploitation sous-jacent), voici quelques recommandations pour la génération de clés SSH. La première est une clé SSH classique :

```shell
ssh-keygen -a 64 -t ed25519 -f ~/.ssh/id_ed25519 -C "ED25519 Key"
```

Pour une clé SSH conforme à la norme FIPS, utilisez la commande suivante :

```shell
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "RSA FIPS-compliant Key"
```

### Configuration du serveur SSH {#ssh-server-configuration}

Au niveau du système d'exploitation, si vous autorisez l'accès SSH (généralement via OpenSSH), voici un exemple d'options de configuration pour le fichier `sshd_config` (l'emplacement exact peut varier selon le système d'exploitation, mais il est généralement `/etc/ssh/sshd_config`) :

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

## Règles de pare-feu {#firewall-rules}

Pour les règles de pare-feu, seuls les ports TCP `80` et `443` doivent être ouverts pour une utilisation de base. Par défaut, `5050` est ouvert pour l'accès distant au registre de conteneurs, mais dans un environnement renforcé, celui-ci sera très probablement hébergé sur un hôte différent, et dans certains environnements, il ne sera pas ouvert du tout. Ainsi, la recommandation est de n'utiliser que les ports `80` et `443`, et le port `80` ne doit être utilisé que pour rediriger vers `443`.

Pour un environnement véritablement renforcé ou isolé tel que FedRAMP, vous devez ajuster les règles de pare-feu afin de restreindre tous les ports, à l'exception de ceux auxquels les réseaux autorisés accèdent. Par exemple, si l'adresse IP est `192.168.1.2` et que tous les clients autorisés se trouvent également sur `192.168.1.0/24`, restreignez l'accès aux ports `80` et `443` uniquement à `192.168.1.0/24` (en tant que restriction de sécurité), même si l'accès est restreint ailleurs par un autre pare-feu.

Idéalement, si vous installez une instance GitLab Self-Managed, vous devez mettre en place les règles de pare-feu avant le début de l'installation, avec un accès restreint aux administrateurs et aux personnes en charge de l'installation, et n'ajouter des plages d'adresses IP supplémentaires pour les utilisateurs qu'une fois l'instance installée et correctement renforcée.

L'utilisation de `iptables` ou de `ufw` est acceptable pour implémenter et appliquer l'accès aux ports `80` et `443` sur une base par hôte ; sinon, l'utilisation des règles de pare-feu basées sur le cloud via GCP Google Compute ou AWS Security Groups doit l'assurer. Tous les autres ports doivent être bloqués, ou au moins restreints à des plages spécifiques. Pour plus d'informations sur les ports, consultez [Paramètres par défaut du package](../administration/package_information/defaults.md).

## Autoriser les connexions sortantes depuis l'instance GitLab {#allow-outbound-connections-from-the-gitlab-instance}

 Vérifiez vos paramètres sortants et entrants :

- Vos pare-feux et serveurs proxy HTTP/S doivent autoriser les connexions sortantes vers `cloud.gitlab.com` et `customers.gitlab.com` sur le port `443` avec `https://`. Ces hôtes sont protégés par Cloudflare. Mettez à jour vos paramètres de pare-feu pour autoriser le trafic vers toutes les adresses IP figurant dans la [liste des plages d'IP publiées par Cloudflare](https://www.cloudflare.com/ips/).
- Pour utiliser un proxy HTTP/S, `gitLab_workhorse` et `gitLab_rails` doivent tous deux avoir les [variables d'environnement du proxy web](https://docs.gitlab.com/omnibus/settings/environment-variables/) nécessaires définies.
- Dans les installations GitLab multinœuds, configurez le proxy HTTP/S sur tous les nœuds **Rails** et **Sidekiq**.
- Pour configurer GitLab Duo sur GitLab Self-Managed, [autorisez les connexions sortantes depuis l'instance GitLab vers GitLab Duo](../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo).

### Ajouts au pare-feu {#firewall-additions}

Il est possible que divers services nécessitant un accès externe soient activés (par exemple Sidekiq) et qu'ils aient besoin d'un accès réseau ouvert. Restreignez ces types de services à des adresses IP spécifiques ou à une classe C spécifique. À titre de précaution supplémentaire et en couches, restreignez, dans la mesure du possible, ces services supplémentaires à des nœuds ou sous-réseaux spécifiques dans GitLab.

## Ajustements du noyau {#kernel-adjustments}

Les ajustements du noyau peuvent être effectués en modifiant `/etc/sysctl.conf`, ou l'un des fichiers dans `/etc/sysctl.d/`. Les ajustements du noyau n'éliminent pas complètement la menace d'une attaque, mais ajoutent une couche de sécurité supplémentaire. Les notes suivantes expliquent certains des avantages de ces ajustements.

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
