---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarder GitLab exécuté dans un conteneur Docker
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez créer une sauvegarde GitLab avec :

```shell
docker exec -t <container name> gitlab-backup create
```

Pour plus d'informations, consultez [Sauvegarder et restaurer GitLab](../../administration/backup_restore/_index.md).

Si votre configuration GitLab est entièrement fournie à l'aide de la variable d'environnement `GITLAB_OMNIBUS_CONFIG` (en suivant les étapes [« Pre-configure Docker Container »](configuration.md#pre-configure-docker-container)), les paramètres de configuration ne sont pas stockés dans le fichier `gitlab.rb` et vous n'avez donc pas besoin de sauvegarder le fichier `gitlab.rb`.

> [!warning]
> Pour éviter les [étapes complexes](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost) lors de la récupération de GitLab à partir d'une sauvegarde, vous devez également suivre les instructions de la section [Sauvegarde du fichier des secrets GitLab](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files). Le fichier des secrets est stocké soit dans le fichier `/etc/gitlab/gitlab-secrets.json` à l'intérieur du conteneur, soit dans le fichier `$GITLAB_HOME/config/gitlab-secrets.json` [sur l'hôte du conteneur](installation.md#create-a-directory-for-the-volumes).

## Créer une sauvegarde de base de données {#create-a-database-backup}

Avant de mettre à niveau GitLab, créez une sauvegarde de la base de données uniquement. Si vous rencontrez des problèmes lors de la mise à niveau de GitLab, vous pouvez restaurer la sauvegarde de la base de données pour annuler la mise à niveau. Pour créer une sauvegarde de la base de données, exécutez cette commande :

```shell
docker exec -t <container name> gitlab-backup create SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state
```

La sauvegarde est écrite dans `/var/opt/gitlab/backups`, qui doit se trouver sur un [volume monté par Docker](installation.md#create-a-directory-for-the-volumes).

Pour plus d'informations sur l'utilisation de la sauvegarde pour annuler une mise à niveau, consultez [annuler une instance Docker](../../update/package/downgrade.md#roll-back-a-docker-instance).
