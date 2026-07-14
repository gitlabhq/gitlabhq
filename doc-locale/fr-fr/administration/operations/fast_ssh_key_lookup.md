---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
description: "Configurez une méthode d'autorisation SSH plus rapide pour les instances GitLab avec de nombreux utilisateurs."
title: Recherche rapide des clés SSH
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque le nombre d'utilisateurs augmente, les opérations SSH deviennent lentes car OpenSSH effectue une recherche linéaire dans le fichier `authorized_keys` pour authentifier les utilisateurs. Ce processus nécessite un temps important et des E/S disque considérables, ce qui retarde les utilisateurs qui tentent de pousser vers un dépôt ou d'en tirer des données. Si les utilisateurs ajoutent ou suppriment fréquemment des clés, le système d'exploitation peut ne pas mettre en cache le fichier `authorized_keys`, ce qui entraîne des lectures répétées sur le disque.

Au lieu d'utiliser le fichier `authorized_keys`, vous pouvez configurer GitLab Shell pour rechercher des clés SSH. C'est plus rapide car la recherche est indexée dans la base de données GitLab.

> [!note]
> Pour les utilisateurs standard (sans clé de déploiement), envisagez d'utiliser des [certificats SSH](ssh_certificates.md). Ils sont plus rapides que les recherches dans la base de données, mais ne remplacent pas directement le fichier `authorized_keys`.

## La recherche rapide est requise pour Geo {#fast-lookup-is-required-for-geo}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Contrairement à [Cloud Native GitLab](https://docs.gitlab.com/charts/), par défaut, les installations de paquets Linux gèrent un fichier `authorized_keys` situé dans le répertoire personnel de l'utilisateur `git`. Pour la plupart des installations, ce fichier se trouve sous `/var/opt/gitlab/.ssh/authorized_keys`. Utilisez cette commande pour localiser le fichier `authorized_keys` sur votre système :

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

Le fichier `authorized_keys` contient toutes les clés SSH publiques des utilisateurs autorisés à accéder à GitLab. Cependant, pour maintenir une source unique de vérité, [Geo](../geo/_index.md) doit être configuré pour effectuer des recherches d'empreintes SSH avec une recherche dans la base de données.

Lorsque vous [configurez Geo](../geo/setup/_index.md), vous devez suivre les étapes ci-dessous pour les nœuds primaire et secondaire. Ne sélectionnez pas **Écrire sur le fichier `authorized keys`** sur le nœud primaire, car cela est reflété automatiquement sur le secondaire si la réplication de la base de données fonctionne.

## Configurer la recherche rapide {#set-up-fast-lookup}

GitLab Shell fournit un moyen d'autoriser les utilisateurs SSH avec une recherche rapide et indexée dans la base de données GitLab. GitLab Shell utilise l'empreinte de la clé SSH pour vérifier si l'utilisateur est autorisé à accéder à GitLab.

La recherche rapide peut être activée avec les serveurs SSH suivants :

- [`gitlab-sshd`](gitlab_sshd.md)
- OpenSSH

Vous pouvez exécuter les deux services simultanément en utilisant des ports séparés pour chaque service.

### Avec `gitlab-sshd` {#with-gitlab-sshd}

Pour les informations de configuration, consultez [`gitlab-sshd`](gitlab_sshd.md). Une fois `gitlab-sshd` activé, GitLab Shell et `gitlab-sshd` sont configurés pour utiliser la recherche rapide automatiquement.

### Avec OpenSSH {#with-openssh}

Prérequis :

- OpenSSH 6.9 ou version ultérieure, car `AuthorizedKeysCommand` doit accepter une empreinte. Pour vérifier votre version, exécutez `sshd -V`.
- Accès administrateur.

Pour configurer la recherche rapide avec OpenSSH :

1. Ajoutez ce qui suit à votre fichier `sshd_config` :

   ```plaintext
   Match User git    # Apply the AuthorizedKeysCommands to the git user only
     AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
     AuthorizedKeysCommandUser git
   Match all    # End match, settings apply to all users again
   ```

   Ce fichier se trouve généralement dans :

   - Installations de paquets Linux : `/etc/ssh/sshd_config`
   - Installations Docker : `/assets/sshd_config`
   - Installations compilées manuellement :  Si vous avez suivi les instructions pour [installer GitLab Shell depuis les sources](../../install/self_compiled/_index.md#install-gitlab-shell), la commande devrait se trouver à `/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check`. Envisagez de créer un script wrapper ailleurs, car cette commande doit appartenir à `root` et ne doit pas être modifiable par un groupe ou d'autres utilisateurs. Envisagez également de modifier la propriété de cette commande si nécessaire, mais cela peut nécessiter des changements de propriété temporaires lors des mises à niveau de `gitlab-shell`.

1. Rechargez OpenSSH :

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. Vérifiez que SSH fonctionne :

   1. Commentez la clé de votre utilisateur dans le fichier `authorized_keys`. Pour ce faire, commencez la ligne par `#`.
   1. Depuis votre machine locale, tentez de tirer un dépôt ou exécutez :

      ```shell
      ssh -T git@gitlab.example.com
      ```

      Un tirage réussi ou un [message de bienvenue](../../user/ssh.md#verify-your-ssh-connection) signifie que GitLab a trouvé la clé dans la base de données car la clé n'est pas présente dans le fichier.

En cas d'échecs de recherche, le fichier `authorized_keys` est toujours analysé. Les performances de Git SSH peuvent toujours être lentes pour de nombreux utilisateurs, tant que le fichier volumineux existe.

Pour résoudre ce problème, vous pouvez désactiver les écritures dans le fichier `authorized_keys` :

1. Vérifiez que SSH fonctionne. Cette étape est importante, car sinon le fichier devient rapidement obsolète.
1. Désactivez les écritures dans le fichier `authorized_keys` :

   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Sélectionnez **Paramètres** > **Réseau**.
   1. Développez **Optimisation des performances**.
   1. Décochez la case **Utiliser le fichier `authorized_keys` pour authentifier les clés SSH**.
   1. Sélectionnez **Sauvegarder les modifications**.

1. Vérifiez la modification :

   1. Supprimez votre clé SSH dans l'interface utilisateur.
   1. Ajoutez une nouvelle clé.
   1. Essayez de tirer un dépôt.

1. Sauvegardez et supprimez votre fichier `authorized_keys`. Les clés des utilisateurs actuels sont déjà présentes dans la base de données, il n'est donc pas nécessaire d'effectuer une migration ni de demander aux utilisateurs de rajouter leurs clés.

### Comment revenir à l'utilisation du fichier `authorized_keys` {#how-to-go-back-to-using-the-authorized_keys-file}

Cette présentation est succincte. Référez-vous aux instructions précédentes pour plus de contexte.

1. Activez les écritures dans le fichier `authorized_keys`.
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
   1. Développez **Optimisation des performances**.
   1. Cochez la case **Utiliser le fichier `authorized_keys` pour authentifier les clés SSH**.
1. [Reconstruire le fichier `authorized_keys`](../raketasks/maintenance.md#rebuild-authorized_keys-file).
1. Supprimez les lignes `AuthorizedKeysCommand` de `/etc/ssh/sshd_config` ou de `/assets/sshd_config` si vous utilisez Docker depuis une installation de paquets Linux.
1. Rechargez `sshd` : `sudo service sshd reload`.

## Prise en charge de SELinux {#selinux-support}

GitLab prend en charge les recherches dans la base de données `authorized_keys` avec [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux).

Comme la politique SELinux est statique, GitLab ne prend pas en charge la modification des ports du serveur web interne. Les administrateurs devraient créer un fichier `.te` spécial pour l'environnement, car il n'est pas généré dynamiquement.

### Documentation complémentaire {#additional-documentation}

Une documentation technique complémentaire pour `gitlab-sshd` peut être trouvée dans la documentation de GitLab Shell.

## Dépannage {#troubleshooting}

### Trafic SSH lent ou charge CPU élevée {#ssh-traffic-slow-or-high-cpu-load}

Si votre trafic SSH est [lent](https://github.com/linux-pam/linux-pam/issues/270) ou entraîne une charge CPU élevée :

- Vérifiez la taille de `/var/log/btmp`.
- Assurez-vous qu'il fait l'objet d'une rotation régulière ou après avoir atteint une certaine taille.

Si ce fichier est très volumineux, la recherche rapide SSH de GitLab peut provoquer l'atteinte du goulot d'étranglement plus fréquemment, réduisant ainsi encore davantage les performances. Envisagez de désactiver [`UsePAM` dans votre `sshd_config`](https://linux.die.net/man/5/sshd_config) pour éviter de lire `/var/log/btmp` en totalité.

L'exécution de `strace` et `lsof` sur un processus `sshd: git` en cours d'exécution retourne des informations de débogage. Pour obtenir un `strace` sur une connexion Git via SSH en cours pour l'IP `x.x.x.x`, exécutez :

```plaintext
sudo strace -s 10000 -p $(sudo netstat -tp | grep x.x.x.x | egrep 'ssh.*: git' | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```

Ou obtenez un `lsof` pour un processus Git via SSH en cours d'exécution :

```plaintext
sudo lsof -p $(sudo netstat -tp | egrep 'ssh.*: git' | head -1 | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```
