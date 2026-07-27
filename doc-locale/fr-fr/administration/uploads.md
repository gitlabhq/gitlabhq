---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration des uploads
description: Administrer le stockage des uploads.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les uploads représentent toutes les données utilisateur pouvant être envoyées à GitLab sous forme de fichier unique. Par exemple, les avatars et les pièces jointes aux notes sont des uploads. Les uploads sont essentiels au fonctionnement de GitLab et ne peuvent donc pas être désactivés.

> [!note]
> Les pièces jointes ajoutées aux commentaires ou aux descriptions sont supprimées **uniquement** lorsque le projet ou le groupe parent est supprimé. Les pièces jointes restent dans le stockage de fichiers même lorsque le commentaire ou la ressource (comme un ticket, une merge request, un epic) où elles ont été uploadées est supprimé(e).

## Utilisation du stockage local {#using-local-storage}

Il s'agit de la configuration par défaut. Pour modifier l'emplacement où les uploads sont stockés localement, suivez les étapes de cette section en fonction de votre méthode d'installation :

> [!note]
> Pour des raisons historiques, les uploads pour l'ensemble de l'instance (par exemple le [favicon](appearance.md#customize-the-favicon)) sont stockés dans un répertoire de base, qui est par défaut `uploads/-/system`. Il est fortement déconseillé de modifier le répertoire de base sur une installation GitLab existante.

Pour les installations avec le package Linux :

_Les uploads sont stockés par défaut dans `/var/opt/gitlab/gitlab-rails/uploads`._

1. Pour modifier le chemin de stockage, par exemple vers `/mnt/storage/uploads`, modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['uploads_directory'] = "/mnt/storage/uploads"
   ```

   Ce paramètre s'applique uniquement si vous n'avez pas modifié le répertoire `gitlab_rails['uploads_storage_path']`.

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Pour les installations compilées à partir des sources :

_Les uploads sont stockés par défaut dans `/home/git/gitlab/public/uploads`._

1. Pour modifier le chemin de stockage, par exemple vers `/mnt/storage/uploads`, modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   uploads:
     storage_path: /mnt/storage
     base_dir: uploads
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Utilisation du stockage objet {#using-object-storage}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous ne souhaitez pas utiliser le disque local sur lequel GitLab est installé pour stocker les uploads, vous pouvez utiliser à la place un fournisseur de stockage d'objets comme AWS S3. Cette configuration nécessite que des identifiants AWS valides soient déjà configurés.

[En savoir plus sur l'utilisation du stockage d'objets avec GitLab](object_storage.md).

### Paramètres du stockage d'objets {#object-storage-settings}

Cette section décrit le format de configuration spécifique au stockage. Vous devriez utiliser les [paramètres de stockage d'objets consolidés](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form) à la place.

Pour les installations compilées manuellement, les paramètres suivants sont imbriqués sous `uploads:` puis sous `object_store:`. Pour les installations avec le package Linux, ils sont préfixés par `uploads_object_store_`.

| Paramètre | Description | Valeur par défaut |
|---------|-------------|---------|
| `enabled` | Activer/désactiver le stockage d'objets | `false` |
| `remote_directory` | Le nom du bucket où les uploads sont stockés| |
| `proxy_download` | Définissez sur `true` pour activer le proxy pour tous les fichiers servis. Cette option permet de réduire le trafic sortant en autorisant les clients à télécharger directement depuis le stockage distant au lieu de proxyfier toutes les données | `false` |
| `connection` | Différentes options de connexion décrites ci-dessous | |

#### Paramètres de connexion {#connection-settings}

Consultez [les paramètres de connexion disponibles pour les différents fournisseurs](object_storage.md#configure-the-connection-settings).

Pour les installations avec le package Linux :

_Les uploads sont stockés par défaut dans `/var/opt/gitlab/gitlab-rails/uploads`._

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes en remplaçant par les valeurs souhaitées :

   ```ruby
   gitlab_rails['uploads_object_store_enabled'] = true
   gitlab_rails['uploads_object_store_remote_directory'] = "uploads"
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   Si vous utilisez des profils AWS IAM, veillez à omettre la clé d'accès AWS et les paires clé/valeur de clé d'accès secrète.

   ```ruby
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Migrez tous les uploads locaux existants vers le stockage d'objets à l'aide de la [tâche Rake `gitlab:uploads:migrate:all`](raketasks/uploads/migrate.md).

Pour les installations compilées à partir des sources :

_Les uploads sont stockés par défaut dans `/home/git/gitlab/public/uploads`._

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes, en veillant à utiliser les [paramètres appropriés pour votre fournisseur](object_storage.md#configure-the-connection-settings) :

   ```yaml
   uploads:
     object_store:
       enabled: true
       remote_directory: "uploads" # The bucket name
       connection: # The lines in this block depend on your provider
         provider: AWS
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.
1. Migrez tous les uploads locaux existants vers le stockage d'objets à l'aide de la [tâche Rake `gitlab:uploads:migrate:all`](raketasks/uploads/migrate.md).
