---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez une alternative légère à OpenSSH pour votre instance GitLab.
title: '`gitlab-sshd`'
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

`gitlab-sshd` est [un serveur SSH autonome](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd) écrit en Go. Il s'agit d'une alternative légère à OpenSSH. Il fait partie du package `gitlab-shell` et gère les [opérations SSH](https://gitlab.com/gitlab-org/gitlab-shell/-/blob/71a7f34a476f778e62f8fe7a453d632d395eaf8f/doc/features.md).

Alors qu'OpenSSH utilise une approche de shell restreint, `gitlab-sshd` :

- Fonctionne comme une application serveur multi-thread moderne.
- Utilise des appels de procédures distantes (RPC) au lieu du protocole de transport SSH.
- Utilise moins de mémoire qu'OpenSSH.
- Prend en charge la [restriction d'accès aux groupes par adresse IP](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address) pour les applications s'exécutant derrière un proxy.

Pour plus de détails sur l'implémentation, consultez [l'article de blog](https://about.gitlab.com/blog/why-we-have-implemented-our-own-sshd-solution-on-gitlab-sass/).

Si vous envisagez de passer d'OpenSSH à `gitlab-sshd`, tenez compte des points suivants :

- Protocole PROXY : `gitlab-sshd` prend en charge le protocole PROXY, ce qui lui permet de s'exécuter derrière des serveurs proxy tels que HAProxy. Cette fonctionnalité n'est pas activée par défaut, mais [peut être activée](#proxy-protocol-support).
- Certificats SSH : `gitlab-sshd` prend en charge l'authentification par certificat SSH au niveau de l'instance en utilisant des clés CA de confiance configurées dans `config.yml`. Pour plus d'informations, consultez [Certificats SSH au niveau de l'instance avec `gitlab-sshd`](gitlab_sshd_ssh_certificates.md).
- Codes de récupération 2FA : `gitlab-sshd` ne prend pas en charge la régénération des codes de récupération 2FA. Toute tentative d'exécution de `2fa_recovery_codes` génère l'erreur : `remote: ERROR: Unknown command: 2fa_recovery_codes`. Consultez [la discussion](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/766#note_1906707753) pour plus de détails.

Les capacités de GitLab Shell vont au-delà des opérations Git et peuvent être utilisées pour diverses interactions SSH avec GitLab.

## Activer `gitlab-sshd` {#enable-gitlab-sshd}

Pour utiliser `gitlab-sshd` :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Les instructions suivantes permettent d'activer `gitlab-sshd` sur un port différent de celui d'OpenSSH :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_sshd['enable'] = true
   gitlab_sshd['listen_address'] = '[::]:2222' # Adjust the port accordingly
   ```

1. Facultatif. Par défaut, les installations de packages Linux génèrent des clés d'hôte SSH pour `gitlab-sshd` si elles n'existent pas dans `/var/opt/gitlab/gitlab-sshd`. Si vous souhaitez désactiver cette génération automatique, ajoutez cette ligne :

   ```ruby
   gitlab_sshd['generate_host_keys'] = false
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Par défaut, `gitlab-sshd` s'exécute en tant qu'utilisateur `git`. Par conséquent, `gitlab-sshd` ne peut pas s'exécuter sur des numéros de port privilégiés inférieurs à 1024. Cela signifie que les utilisateurs doivent accéder à Git via le port `gitlab-sshd`, ou utiliser un équilibreur de charge qui dirige le trafic SSH vers le port `gitlab-sshd` pour masquer cela.

Les utilisateurs peuvent voir des avertissements concernant les clés d'hôte, car les clés d'hôte nouvellement générées diffèrent des clés d'hôte OpenSSH. Envisagez de désactiver la génération des clés d'hôte et de copier les clés d'hôte OpenSSH existantes dans `/var/opt/gitlab/gitlab-sshd` si cela pose problème.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Les instructions suivantes permettent de passer d'OpenSSH à `gitlab-sshd` :

1. Définissez l'option `sshDaemon` des charts `gitlab-shell` sur [`gitlab-sshd`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options). Par exemple :

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
   ```

1. Effectuez une mise à niveau Helm.

Par défaut, `gitlab-sshd` écoute :

- Les requêtes externes sur le port 22 (`global.shell.port`).
- Les requêtes internes sur le port 2222 (`gitlab.gitlab-shell.service.internalPort`).

Vous pouvez [configurer différents ports dans le chart Helm](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#configuration).

{{< /tab >}}

{{< /tabs >}}

## Prise en charge du protocole PROXY {#proxy-protocol-support}

Les équilibreurs de charge placés devant `gitlab-sshd` obligent GitLab à signaler l'adresse IP du proxy au lieu de l'adresse IP du client. Pour obtenir la véritable adresse IP, `gitlab-sshd` prend en charge le [protocole PROXY](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Pour activer le protocole PROXY :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_sshd['proxy_protocol'] = true
   # Proxy protocol policy ("use", "require", "reject", "ignore"), "use" is the default value
   gitlab_sshd['proxy_policy'] = "use"
   ```

   Pour plus d'informations sur les options `gitlab_sshd['proxy_policy']`, consultez la [bibliothèque `go-proxyproto`](https://github.com/pires/go-proxyproto/blob/4ba2eb817d7a57a4aafdbd3b82ef0410806b533d/policy.go#L20-L35).

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Définissez les [options `gitlab.gitlab-shell.config`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options). Par exemple :

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         proxyProtocol: true
         proxyPolicy: "use"
   ```

1. Effectuez une mise à niveau Helm.

{{< /tab >}}

{{< /tabs >}}
