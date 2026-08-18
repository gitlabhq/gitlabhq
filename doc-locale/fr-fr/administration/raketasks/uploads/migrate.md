---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake de migration des uploads
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Il existe une tâche Rake pour migrer les uploads entre différents types de stockage.

- Migrez tous les uploads avec [`gitlab:uploads:migrate:all`](#all-in-one-rake-task) ou
- Pour migrer uniquement des types d'uploads spécifiques, utilisez [`gitlab:uploads:migrate`](#individual-rake-tasks).

## Migrer vers le stockage d'objets {#migrate-to-object-storage}

Après avoir [configuré le stockage d'objets](../../uploads.md#using-object-storage) pour les uploads vers GitLab, utilisez cette tâche pour migrer les uploads existants du stockage local vers le stockage distant.

Tout le traitement est effectué dans un worker en arrière-plan et ne nécessite aucun **temps d'arrêt**.

En savoir plus sur l'utilisation du [stockage d'objets avec GitLab](../../object_storage.md).

### Tâche Rake tout-en-un {#all-in-one-rake-task}

GitLab fournit une tâche Rake wrapper qui migre tous les fichiers uploadés (par exemple, les avatars, logos, pièces jointes et favicon) vers le stockage d'objets en une seule étape. La tâche wrapper appelle des tâches Rake individuelles pour migrer les fichiers relevant de chacune de ces catégories, une par une.

Ces [tâches Rake individuelles](#individual-rake-tasks) sont décrites dans la section suivante.

Pour migrer tous les uploads du stockage local vers le stockage d'objets, exécutez :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
gitlab-rake "gitlab:uploads:migrate:all"
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate:all
```

{{< /tab >}}

{{< /tabs >}}

Vous pouvez éventuellement suivre la progression et vérifier que tous les uploads ont bien été migrés à l'aide de la [console PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database) :

- `sudo gitlab-rails dbconsole --database main` pour les installations via le package Linux.
- `sudo -u git -H psql -d gitlabhq_production` pour les installations compilées manuellement.

Vérifiez que `objectstg` ci-dessous (où `store=2`) correspond au nombre total d'artefacts :

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

total | filesystem | objectstg
------+------------+-----------
   2409 |          0 |      2409
```

Vérifiez qu'il n'y a aucun fichier sur le disque dans le dossier `uploads` :

```shell
sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
```

### Tâches Rake individuelles {#individual-rake-tasks}

Si vous avez déjà exécuté la [tâche Rake tout-en-un](#all-in-one-rake-task), il n'est pas nécessaire d'exécuter ces tâches individuelles.

La tâche Rake utilise trois paramètres pour trouver les uploads à migrer :

| Paramètre        | Type          | Description                                            |
|:-----------------|:--------------|:-------------------------------------------------------|
| `uploader_class` | string        | Type de l'uploader à migrer.                  |
| `model_class`    | string        | Type du modèle à migrer.                     |
| `mount_point`    | string/symbol | Nom de la colonne du modèle sur laquelle l'uploader est monté. |

> [!note]
> Ces paramètres sont principalement internes à la structure de GitLab ; vous pouvez consulter la liste des tâches ci-dessous. Après avoir exécuté ces tâches individuelles, nous vous recommandons d'exécuter la [tâche Rake tout-en-un](#all-in-one-rake-task) pour migrer les uploads non inclus dans les types répertoriés.

Cette tâche accepte également une variable d'environnement que vous pouvez utiliser pour remplacer la taille de lot par défaut :

| Variable | Type    | Description                                       |
|:---------|:--------|:--------------------------------------------------|
| `BATCH`  | integer | Spécifie la taille du lot. Par défaut : 200. |

L'exemple suivant montre comment exécuter `gitlab:uploads:migrate` pour des types d'uploads individuels.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
# gitlab-rake gitlab:uploads:migrate[uploader_class, model_class, mount_point]

# Avatars
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
gitlab-rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
gitlab-rake "gitlab:uploads:migrate[FileUploader, Project]"
gitlab-rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
gitlab-rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action, :image_v432x230]"
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

Utilisez `RAILS_ENV=production` pour chaque tâche.

```shell
# sudo -u git -H bundle exec rake gitlab:uploads:migrate

# Avatars
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, Project]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action]"
```

{{< /tab >}}

{{< /tabs >}}

## Migrer vers le stockage local {#migrate-to-local-storage}

Si vous devez désactiver le [stockage d'objets](../../object_storage.md) pour quelque raison que ce soit, vous devez d'abord migrer vos données hors du stockage d'objets et les rapatrier dans votre stockage local.

> [!warning]
> **Un temps d'arrêts étendu est nécessaire** afin qu'aucun nouveau fichier ne soit créé dans le stockage d'objets pendant la migration. Un paramètre de configuration permettant de migrer du stockage d'objets vers des fichiers locaux avec seulement un bref moment d'indisponibilité pour les changements de configuration est suivi [dans ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/30979).
>
> **De plus,** dans GitLab cloud-native, il est généralement peu sûr de migrer des données vers le stockage local, car il est éphémère et non partagé avec tous les conteneurs d'applications GitLab Rails.

### Tâche Rake tout-en-un {#all-in-one-rake-task-1}

GitLab fournit une tâche Rake wrapper qui migre tous les fichiers uploadés (par exemple, les avatars, logos, pièces jointes et favicon) vers le stockage local en une seule étape. La tâche wrapper appelle des tâches Rake individuelles pour migrer les fichiers relevant de chacune de ces catégories, une par une.

Pour plus de détails sur ces tâches Rake, reportez-vous aux [tâches Rake individuelles](#individual-rake-tasks). Gardez à l'esprit que le nom de la tâche dans ce cas est `gitlab:uploads:migrate_to_local`.

Pour migrer les uploads du stockage d'objets vers le stockage local :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
gitlab-rake "gitlab:uploads:migrate_to_local:all"
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate_to_local:all
```

{{< /tab >}}

{{< /tabs >}}

Après avoir exécuté la tâche Rake, vous pouvez désactiver le stockage d'objets en annulant les modifications décrites dans les instructions pour [configurer le stockage d'objets](../../uploads.md#using-object-storage).
