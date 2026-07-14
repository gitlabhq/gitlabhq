---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Recherche d'utilisateurs avec la commande OpenSSH AuthorizedPrincipalsCommand"
description: "Configurez les principaux autorisés pour l'authentification par certificat SSH."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'authentification SSH par défaut pour les instances GitLab Self-Managed exige que les utilisateurs téléversent leurs clés publiques SSH avant de pouvoir utiliser le transport SSH.

Dans les environnements centralisés, tels que les environnements d'entreprise, cette exigence peut créer une surcharge opérationnelle. C'est particulièrement vrai lorsque les clés SSH sont temporaires, par exemple des clés qui expirent 24 heures après leur émission.

Dans ces configurations, un processus automatisé externe doit constamment téléverser de nouvelles clés vers GitLab.

> [!warning]
> OpenSSH version 6.9+ est requise car `AuthorizedKeysCommand` doit être en mesure d'accepter une empreinte digitale. Vérifiez la version d'OpenSSH sur votre serveur.

Si vous utilisez `gitlab-sshd` à la place d'OpenSSH, vous pouvez configurer l'authentification par certificat SSH au niveau de l'instance directement dans le fichier de configuration `gitlab-sshd` sans nécessiter OpenSSH. Pour plus d'informations, consultez [Certificats SSH au niveau de l'instance avec `gitlab-sshd`](gitlab_sshd_ssh_certificates.md).

Si vous êtes propriétaire d'un groupe GitLab.com, vous devriez plutôt utiliser une fonctionnalité de certificat SSH à portée de groupe qui utilise le serveur SSH GitLab et ne nécessite pas de configuration OpenSSH. Pour plus d'informations, consultez [gérer les certificats SSH de groupe](../../user/group/ssh_certificates.md).

## Pourquoi utiliser les certificats OpenSSH ? {#why-use-openssh-certificates}

Lorsque vous utilisez des certificats OpenSSH, les informations indiquant quel utilisateur GitLab possède la clé sont encodées dans la clé elle-même. OpenSSH garantit que les utilisateurs ne peuvent pas falsifier ces informations, car ils doivent avoir accès à la clé de signature privée de l'AC.

Lorsque cette configuration est correctement effectuée, elle supprime entièrement l'obligation de téléverser les clés SSH des utilisateurs sur GitLab.

## Configuration de la recherche de certificats SSH via GitLab Shell {#setting-up-ssh-certificate-lookup-via-gitlab-shell}

La procédure complète de configuration des certificats SSH dépasse la portée de ce document. Consultez [le `PROTOCOL.certkeys` d'OpenSSH](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?annotate=HEAD) pour comprendre son fonctionnement, par exemple [la documentation RedHat à ce sujet](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_openssh_certificate_authentication).

Nous supposons que vous avez déjà configuré des certificats SSH et que vous avez ajouté le `TrustedUserCAKeys` de votre AC à votre `sshd_config`, par exemple :

```plaintext
TrustedUserCAKeys /etc/security/mycompany_user_ca.pub
```

En général, `TrustedUserCAKeys` ne serait pas délimité par un `Match User git` dans une telle configuration, car il serait également utilisé pour les connexions système au serveur GitLab lui-même, mais votre configuration peut varier. Si l'AC est uniquement utilisée pour GitLab, envisagez de placer ceci dans la section `Match User git` (décrite ci-dessous).

Les certificats SSH émis par cette AC **doivent** avoir un « ID de la clé » correspondant au nom d'utilisateur de cet utilisateur sur GitLab, par exemple (certaines sorties ont été omises pour des raisons de concision) :

```shell
$ ssh-add -L | grep cert | ssh-keygen -L -f -

(stdin):1:
        Type: ssh-rsa-cert-v01@openssh.com user certificate
        Public key: RSA-CERT SHA256:[...]
        Signing CA: RSA SHA256:[...]
        Key ID: "aearnfjord"
        Serial: 8289829611021396489
        Valid: from 2018-07-18T09:49:00 to 2018-07-19T09:50:34
        Principals:
                sshUsers
                [...]
        [...]
```

Techniquement, ce n'est pas strictement vrai ; par exemple, il pourrait s'agir de `prod-aearnfjord` si c'est un certificat SSH avec lequel vous vous connectez habituellement aux serveurs en tant qu'utilisateur `prod-aearnfjord`, mais vous devrez alors spécifier votre propre `AuthorizedPrincipalsCommand` pour effectuer ce mappage au lieu d'utiliser notre valeur par défaut fournie.

L'aspect important est qu'`AuthorizedPrincipalsCommand` doit être en mesure d'effectuer le mappage entre l'« ID de la clé » et un nom d'utilisateur GitLab, car la commande par défaut fournie suppose qu'il existe un mappage 1:1 entre les deux. L'objectif principal est de nous permettre d'extraire un nom d'utilisateur GitLab à partir de la clé elle-même, au lieu de nous appuyer sur quelque chose comme le mappage par défaut entre clé publique et nom d'utilisateur.

Ensuite, dans votre `sshd_config`, configurez `AuthorizedPrincipalsCommand` pour l'utilisateur `git`. Vous pourrez probablement utiliser celle fournie par défaut avec GitLab :

```plaintext
Match User git
    AuthorizedPrincipalsCommandUser root
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers
```

Cette commande génère une sortie ressemblant à ceci :

```shell
command="/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell username-{KEY_ID}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty {PRINCIPAL}
```

Où `{KEY_ID}` est l'argument `%i` passé au script (par exemple, `aeanfjord`), et `{PRINCIPAL}` est le principal qui lui est passé (par exemple, `sshUsers`).

Vous devez personnaliser la partie `sshUsers` de cette commande. Il doit s'agir d'un principal dont la présence dans la clé est garantie pour tous les utilisateurs pouvant se connecter à GitLab, ou vous devez fournir une liste de principaux dont l'un est présent pour l'utilisateur, par exemple :

```plaintext
    [...]
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers windowsUsers
```

## Principaux et sécurité {#principals-and-security}

Vous pouvez fournir autant de principaux que vous le souhaitez ; ceux-ci sont convertis en plusieurs lignes de sortie `authorized_keys`, comme décrit dans la documentation `AuthorizedPrincipalsFile` dans `sshd_config(5)`.

En général, lorsque l'on utilise `AuthorizedKeysCommand` avec OpenSSH, le principal est un « groupe » autorisé à se connecter à ce serveur. Cependant, avec GitLab, il est uniquement utilisé pour satisfaire l'exigence d'OpenSSH en la matière ; nous nous soucions effectivement uniquement que l'« ID de la clé » soit correct. Une fois extrait, GitLab applique ses propres ACL pour cet utilisateur (par exemple, les projets auxquels l'utilisateur peut accéder).

Il est donc acceptable d'être trop généreux dans ce que vous acceptez. Par exemple, si l'utilisateur n'a pas accès à GitLab, une erreur est générée avec un message indiquant qu'il s'agit d'un utilisateur invalide.

## Interaction avec le fichier `authorized_keys` {#interaction-with-the-authorized_keys-file}

Si les certificats SSH sont configurés comme décrit précédemment, ils peuvent être utilisés avec le fichier `authorized_keys` afin que le fichier `authorized_keys` serve de solution de secours.

Lorsqu'`AuthorizedPrincipalsCommand` est incapable d'authentifier un utilisateur, OpenSSH revient à la vérification du fichier `~/.ssh/authorized_keys` ou à l'utilisation de `AuthorizedKeysCommand`. Par conséquent, vous pourriez encore avoir besoin d'utiliser [la recherche rapide des clés SSH autorisées dans la base de données](fast_ssh_key_lookup.md) avec des certificats SSH.

Pour la plupart des utilisateurs, les certificats SSH gèrent l'authentification à l'aide d'`AuthorizedPrincipalsCommand`, le fichier `~/.ssh/authorized_keys` servant principalement de solution de secours pour des cas spécifiques tels que les clés de déploiement. Cependant, selon votre configuration, vous pourriez constater que l'utilisation exclusive d'`AuthorizedPrincipalsCommand` pour les utilisateurs classiques est suffisante. Dans ces cas, le fichier `authorized_keys` n'est nécessaire que pour l'accès automatisé par clé de déploiement ou d'autres scénarios spécifiques.

Tenez compte de l'équilibre entre le nombre de clés pour les utilisateurs classiques (surtout si elles sont fréquemment renouvelées) et les clés de déploiement pour vous aider à déterminer si le maintien de la solution de secours `authorized_keys` est nécessaire pour votre environnement.

## Autres mises en garde relatives à la sécurité {#other-security-caveats}

Les utilisateurs peuvent toujours contourner l'authentification par certificat SSH en téléversant manuellement une clé publique SSH sur leur profil, en s'appuyant sur la solution de secours `~/.ssh/authorized_keys` pour l'authentifier.

Il existe un [ticket ouvert](https://gitlab.com/gitlab-org/gitlab/-/issues/23260) pour ajouter un paramètre empêchant les utilisateurs de téléverser des clés SSH qui ne sont pas des clés de déploiement.

Vous pouvez créer une vérification pour appliquer cette restriction vous-même. Par exemple, fournissez un `AuthorizedKeysCommand` personnalisé qui vérifie si l'ID de clé découvert renvoyé par `gitlab-shell-authorized-keys-check` est une clé de déploiement ou non (toutes les clés qui ne sont pas des clés de déploiement doivent être refusées).

## Désactivation de l'avertissement global concernant les utilisateurs sans clés SSH {#disabling-the-global-warning-about-users-lacking-ssh-keys}

Par défaut, GitLab affiche un avertissement « Vous ne pourrez pas effectuer un pull ou push du code du projet via SSH » aux utilisateurs qui n'ont pas téléversé de clé SSH sur leur profil.

Cela est contre-productif lors de l'utilisation de certificats SSH, car les utilisateurs ne sont pas censés téléverser leurs propres clés.

Pour désactiver cet avertissement globalement, accédez à « Paramètres de l'application » -> « Paramètres et limites du compte » et désactivez le paramètre « Afficher le message concernant la clé SSH aux utilisateurs ».

Ce paramètre a été ajouté spécifiquement pour être utilisé avec des certificats SSH, mais peut être désactivé sans les utiliser si vous souhaitez masquer l'avertissement pour une autre raison.
