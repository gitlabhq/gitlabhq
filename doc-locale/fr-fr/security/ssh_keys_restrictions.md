---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Configurer les restrictions des clés SSH
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`ssh-keygen` permet aux utilisateurs de créer des clés RSA avec seulement 768 bits, ce qui est bien en dessous des tailles de clés recommandées par des organismes de normalisation tels que le NIST américain, et n'est pas sécurisé. Certaines organisations déployant GitLab doivent imposer une force minimale des clés, soit pour satisfaire la politique de sécurité interne, soit pour des raisons de conformité réglementaire.

De même, GitLab recommande fortement d'utiliser ED25519, ED25519_SK, ECDSA, ECDSA_SK ou RSA plutôt que l'ancien DSA. Les administrateurs devraient sérieusement envisager de limiter les algorithmes de clés SSH autorisés afin de maintenir la sécurité.

GitLab vous permet de restreindre la technologie de clé SSH autorisée et de spécifier la longueur minimale de clé pour chaque technologie.

Prérequis :

- Disposer d'un accès administrateur.

Pour configurer les restrictions des clés SSH :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès** et définissez les valeurs souhaitées pour chaque type de clé :
   - **RSA SSH keys**.
   - **DSA SSH keys**.
   - **ECDSA SSH keys**.
   - **ED25519 SSH keys**.
   - **ECDSA_SK SSH keys**.
   - **ED25519_SK SSH keys**.
1. Sélectionnez **Enregistrer les modifications**.

Si une restriction est imposée sur un type de clé, les utilisateurs ne peuvent pas téléverser de nouvelles clés SSH qui ne satisfont pas à cette exigence. Toute clé existante qui ne satisfait pas à cette exigence est désactivée mais pas supprimée, et les utilisateurs ne peuvent pas effectuer de pull ou de push de code en l'utilisant.

Si vous avez une clé restreinte, une icône d'avertissement ({{< icon name="warning" >}}) est visible dans la section **Clés SSH** de votre profil. Pour savoir pourquoi cette clé est restreinte, survolez l'icône.

## Paramètres par défaut {#default-settings}

Par défaut, les paramètres de GitLab.com et de GitLab Self-Managed pour les [types de clés pris en charge](../user/ssh.md#supported-ssh-key-types) sont :

- Les clés SSH DSA sont interdites.
- Les clés SSH RSA sont autorisées.
- Les clés SSH ECDSA sont autorisées.
- Les clés SSH ED25519 sont autorisées.
- Les clés SSH ECDSA_SK sont autorisées.
- Les clés SSH ED25519_SK sont autorisées.

## Remplacer les paramètres SSH sur le serveur GitLab {#override-ssh-settings-on-the-gitlab-server}

GitLab s'intègre au démon SSH installé sur le système et désigne un utilisateur (généralement nommé `git`) par lequel toutes les requêtes d'accès sont traitées. Les utilisateurs qui se connectent au serveur GitLab via SSH sont identifiés par leur clé SSH plutôt que par leur nom d'utilisateur.

Les opérations du client SSH effectuées sur le serveur GitLab sont exécutées en tant que cet utilisateur. Vous pouvez modifier cette configuration SSH. Par exemple, vous pouvez spécifier une clé SSH privée pour que cet utilisateur l'utilise pour les requêtes d'authentification. Cependant, cette pratique n'est pas prise en charge et est fortement déconseillée car elle présente des risques de sécurité importants.

GitLab vérifie cette condition et vous redirige vers cette section si votre serveur est configuré de cette manière. Par exemple :

```shell
$ gitlab-rake gitlab:check

Git user has default SSH configuration? ... no
  Try fixing it:
  mkdir ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa.pub ~/gitlab-check-backup-1504540051
  For more information see:
  doc/user/ssh.md#overriding-ssh-settings-on-the-gitlab-server
  Please fix the error above and rerun the checks.
```

> [!warning]
> Supprimez la configuration personnalisée dès que possible. Ces personnalisations ne sont explicitement pas prises en charge et peuvent cesser de fonctionner à tout moment.

## Vérifier la propriété et les permissions SSH de GitLab {#verify-gitlab-ssh-ownership-and-permissions}

Le dossier et les fichiers SSH de GitLab doivent disposer des permissions suivantes :

- Le dossier `/var/opt/gitlab/.ssh/` doit appartenir au groupe `git` et à l'utilisateur `git`, avec les permissions définies à `700`.
- Le fichier `authorized_keys` doit avoir les permissions définies à `600`.
- Le fichier `authorized_keys.lock` doit avoir les permissions définies à `644`.

Pour vérifier que ces permissions sont correctes, exécutez la commande suivante :

```shell
stat -c "%a %n" /var/opt/gitlab/.ssh/.
```

### Définir les permissions {#set-permissions}

Si les permissions sont incorrectes, connectez-vous au serveur d'application et exécutez :

```shell
cd /var/opt/gitlab/
chown git:git /var/opt/gitlab/.ssh/
chmod 700  /var/opt/gitlab/.ssh/
chmod 600  /var/opt/gitlab/.ssh/authorized_keys
chmod 644  /var/opt/gitlab/.ssh/authorized_keys.lock
```
