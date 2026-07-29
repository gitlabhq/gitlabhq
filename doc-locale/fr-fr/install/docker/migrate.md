---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer une instance GitLab sur package Linux vers Docker
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Migrez votre instance GitLab sur package Linux existante vers Docker en utilisant l'une des deux approches suivantes :

- **Reuse existing data directories** : déplacez les répertoires de données existants vers les chemins de volume Docker. Utilisez cette approche pour conserver vos données en place sans cycle complet de sauvegarde et restauration.
- **Back up and restore** : créez une sauvegarde GitLab sur l'instance du package Linux, configurez une nouvelle instance Docker et restaurez-y les données. Utilisez cette approche pour une migration propre qui prend en charge la restauration si nécessaire.

## Prérequis {#prerequisites}

- Les versions de GitLab sur l'instance du package Linux et l'image Docker doivent correspondre. Si nécessaire, mettez à niveau votre instance du package Linux avant de migrer vers Docker.
- [Docker installé](installation.md) sur le serveur cible.

## Réutiliser les répertoires de données existants {#reuse-existing-data-directories}

Migrez une instance GitLab sur package Linux vers Docker en réutilisant les répertoires de données existants.

### Arrêter l'instance du package Linux {#stop-the-linux-package-instance}

Arrêtez tous les services GitLab :

```shell
sudo gitlab-ctl stop
```

### Préparer les répertoires de volume {#prepare-the-volume-directories}

La façon dont vous préparez les répertoires de volume dépend de l'emplacement où Docker s'exécute :

- Si Docker s'exécute sur le même serveur que l'instance du package Linux, vous pouvez monter les répertoires existants directement sans les copier. Définissez les chemins de volume dans votre fichier Docker Compose aux emplacements du package Linux :

  ```yaml
  volumes:
    - '/etc/gitlab:/etc/gitlab'
    - '/var/log/gitlab:/var/log/gitlab'
    - '/var/opt/gitlab:/var/opt/gitlab'
  ```

- Si vous migrez vers un serveur différent, ou souhaitez conserver les volumes Docker séparés des chemins du package Linux, copiez d'abord les répertoires vers un nouvel emplacement.

  1. Définissez `$GITLAB_HOME` sur le répertoire cible :

     ```shell
     export GITLAB_HOME=/srv/gitlab
     sudo mkdir -p $GITLAB_HOME
     ```

  1. Copiez (ou déplacez) les répertoires de données, de journaux et de configuration :

     ```shell
     sudo cp -a /var/opt/gitlab $GITLAB_HOME/data
     sudo cp -a /var/log/gitlab $GITLAB_HOME/logs
     sudo cp -a /etc/gitlab     $GITLAB_HOME/config
     ```

     Pour déplacer au lieu de copier, utilisez `mv` à la place de `cp -a`.

> [!warning]
> Ne modifiez pas la propriété des répertoires hôtes en `root:root` avant de démarrer le conteneur. Cela empêche le démarrage du conteneur et empêche le script `update-permissions` de corriger la propriété par la suite.

Vérifiez que le répertoire du dépôt existe et est un répertoire réel, et non un lien symbolique brisé :

```shell
ls -la $GITLAB_HOME/data/git-data/repositories
```

Si le répertoire est manquant ou constitue un lien symbolique brisé, créez-le :

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
```

### Aligner les identifiants utilisateur et groupe {#align-user-and-group-identifiers}

L'image Docker GitLab inclut un script intégré appelé `update-permissions` qui définit la propriété correcte sur tous les répertoires GitLab. Si l'instance du package Linux a utilisé des UID différents de ceux attendus par l'image Docker (soit les valeurs par défaut du système d'exploitation qui varient selon la distribution, soit des [valeurs explicitement configurées](https://docs.gitlab.com/omnibus/settings/configuration/#specify-numeric-user-and-group-identifiers)), exécutez `update-permissions` depuis un conteneur temporaire avec vos volumes montés avant de démarrer le conteneur. Cela corrige la propriété avant le premier démarrage :

```shell
docker run --rm \
  -v <config_path>:/etc/gitlab \
  -v <logs_path>:/var/log/gitlab \
  -v <data_path>:/var/opt/gitlab \
  --entrypoint /bin/bash \
  gitlab/gitlab-ee:<version> \
  -c "update-permissions"
```

Remplacez `<config_path>`, `<logs_path>` et `<data_path>` par les chemins hôtes que vous avez identifiés dans [Préparer les répertoires de volume](#prepare-the-volume-directories).

### Démarrer GitLab dans Docker {#start-gitlab-in-docker}

Suivez les [instructions d'installation](installation.md) pour créer un fichier Docker Compose ou une commande Docker Engine qui monte les répertoires que vous avez préparés :

```yaml
volumes:
  - '$GITLAB_HOME/config:/etc/gitlab'
  - '$GITLAB_HOME/logs:/var/log/gitlab'
  - '$GITLAB_HOME/data:/var/opt/gitlab'
```

Une fois le conteneur démarré, exécutez reconfigure :

```shell
docker exec -it <container_name> gitlab-ctl reconfigure
```

Vérifiez l'installation :

```shell
docker exec -it <container_name> gitlab-rake gitlab:check
```

## Sauvegarder l'instance du package Linux et restaurer vers l'instance Docker {#back-up-the-linux-package-instance-and-restore-to-the-docker-instance}

### Créer une sauvegarde sur l'instance du package Linux {#create-a-backup-on-the-linux-package-instance}

Avant d'arrêter votre instance du package Linux, créez une sauvegarde :

```shell
sudo gitlab-backup create
```

Copiez votre fichier de secrets vers un emplacement sécurisé :

```shell
sudo cp /etc/gitlab/gitlab-secrets.json /your/backup/location/
```

Pour plus d'informations, consultez [Sauvegarder GitLab](../../administration/backup_restore/backup_gitlab.md).

### Arrêter l'instance du package Linux {#stop-the-linux-package-instance-1}

Arrêtez tous les services GitLab :

```shell
sudo gitlab-ctl stop
```

### Configurer l'instance Docker {#set-up-the-docker-instance}

Suivez les [instructions d'installation](installation.md) pour configurer une nouvelle instance Docker. Définissez `$GITLAB_HOME` sur le répertoire que vous créez pour les volumes, par exemple :

```shell
export GITLAB_HOME=/srv/gitlab
```

Démarrez le conteneur une fois pour initialiser les répertoires de volume, puis arrêtez-le avant de restaurer :

```shell
docker compose up -d
docker compose stop
```

### Restaurer la sauvegarde {#restore-the-backup}

1. Copiez l'archive de sauvegarde dans le volume de données Docker :

   ```shell
   sudo cp <timestamp>_gitlab_backup.tar $GITLAB_HOME/data/backups/
   ```

1. Copiez le fichier de secrets dans le volume de configuration Docker :

   ```shell
   sudo cp gitlab-secrets.json $GITLAB_HOME/config/gitlab-secrets.json
   ```

1. Démarrez le conteneur et exécutez la restauration :

   ```shell
   docker compose start
   docker exec -it <container_name> gitlab-backup restore BACKUP=<timestamp>
   ```

1. Reconfigurez et redémarrez une fois la restauration terminée :

   ```shell
   docker exec -it <container_name> gitlab-ctl reconfigure
   docker exec -it <container_name> gitlab-ctl restart
   ```

1. Vérifiez l'installation :

   ```shell
   docker exec -it <container_name> gitlab-rake gitlab:check
   ```

## Dépannage {#troubleshooting}

Lors de la migration d'une instance GitLab sur package Linux vers Docker, vous pourriez rencontrer les problèmes suivants.

### Erreurs de permissions après le démarrage {#permission-errors-after-starting}

Si le conteneur démarre mais signale des erreurs de permissions, exécutez :

```shell
sudo docker exec <container_name> update-permissions
sudo docker restart <container_name>
```

Cela se produit lorsque l'instance du package Linux a utilisé des UID différents pour les comptes système de ceux attendus par l'image Docker. Pour éviter cela, exécutez `update-permissions` avant le démarrage comme décrit dans [Aligner les identifiants utilisateur et groupe](#align-user-and-group-identifiers).

### Erreurs lors de la réutilisation de données d'une autre instance {#errors-when-reusing-data-from-another-instance}

Lors de la réutilisation de données d'une autre instance, vous pourriez rencontrer les problèmes suivants.

#### Erreur `stat: missing operand` au démarrage {#stat-missing-operand-error-on-startup}

Cette erreur se produit lorsque le conteneur ne trouve pas le répertoire `git-data/repositories` :

```plaintext
stat: missing operand
Expected process to exit with [0], but received '1'
Ran stat --printf='%U' $(readlink -f /var/opt/gitlab/git-data/repositories) returned 1
```

Sur l'hôte, créez le répertoire manquant, puis redémarrez le conteneur :

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
sudo docker restart <container_name>
```

#### Le conteneur se ferme immédiatement et la boucle de redémarrage bloque `docker exec` {#container-exits-immediately-and-restart-loop-blocks-docker-exec}

Si le conteneur se ferme immédiatement après le démarrage, vous ne pouvez pas utiliser `docker exec` pour effectuer des investigations ou exécuter `update-permissions`. À la place, exécutez `update-permissions` directement en utilisant la même commande depuis [Aligner les identifiants utilisateur et groupe](#align-user-and-group-identifiers), qui démarre un conteneur temporaire avec vos volumes montés et corrige la propriété sans nécessiter que le conteneur principal soit en cours d'exécution.
