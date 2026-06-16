---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration des fichiers sécurisés
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) et feature flag `ci_secure_files` supprimé dans GitLab 15.7.

{{< /history >}}

Vous pouvez stocker en toute sécurité jusqu'à 100 fichiers à utiliser dans les pipelines CI/CD en tant que fichiers sécurisés. Ces fichiers sont stockés en toute sécurité en dehors du dépôt de votre projet et ne sont pas soumis au contrôle de version. Il est sûr de stocker des informations sensibles dans ces fichiers. Les fichiers sécurisés prennent en charge les types de fichiers texte brut et binaire, et doivent faire 5 Mo ou moins.

L'emplacement de stockage de ces fichiers peut être configuré à l'aide des options décrites ci-dessous, mais les emplacements par défaut sont :

- `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files` pour les installations utilisant le package Linux.
- `/home/git/gitlab/shared/ci_secure_files` pour les installations auto-compilées.

Utilisez la configuration [de stockage d'objets externe](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files) pour les installations du [chart Helm GitLab](https://docs.gitlab.com/charts/).

## Désactivation des fichiers sécurisés {#disabling-secure-files}

Vous pouvez désactiver les fichiers sécurisés sur l'ensemble de l'instance GitLab. Vous pouvez souhaiter désactiver les fichiers sécurisés pour réduire l'espace disque ou pour supprimer l'accès à la fonctionnalité.

Pour désactiver les fichiers sécurisés, suivez les étapes ci-dessous selon votre installation.

Prérequis :

- Vous devez être administrateur.

**For Linux package installations**

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['ci_secure_files_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

**For self-compiled installations**

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   ci_secure_files:
     enabled: false
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Utilisation du stockage local {#using-local-storage}

La configuration par défaut utilise le stockage local. Pour modifier l'emplacement où les fichiers sécurisés sont stockés localement, suivez les étapes ci-dessous.

**For Linux package installations**

1. Pour modifier le chemin de stockage, par exemple en `/mnt/storage/ci_secure_files`, modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['ci_secure_files_storage_path'] = "/mnt/storage/ci_secure_files"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

**For self-compiled installations**

1. Pour modifier le chemin de stockage, par exemple en `/mnt/storage/ci_secure_files`, modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   ci_secure_files:
     enabled: true
     storage_path: /mnt/storage/ci_secure_files
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Utilisation du stockage d'objets {#using-object-storage}

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Au lieu de stocker les fichiers sécurisés sur disque, vous devriez utiliser [l'une des options de stockage d'objets prises en charge](../object_storage.md#object-storage-provider-support). Cette configuration repose sur des informations d'identification valides déjà configurées.

### Stockage d'objets consolidé {#consolidated-object-storage}

{{< history >}}

- La prise en charge du stockage d'objets consolidé a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149873) dans GitLab 17.0.

{{< /history >}}

L'utilisation de la [forme consolidée](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form) du stockage d'objets est recommandée.

### Stockage d'objets spécifique au stockage {#storage-specific-object-storage}

Les paramètres suivants sont :

- Imbriqués sous `ci_secure_files:` puis `object_store:` pour les installations auto-compilées.
- Précédés par `ci_secure_files_object_store_` pour les installations avec le package Linux.

| Paramètre | Description | Valeur par défaut |
|---------|-------------|---------|
| `enabled` | Activer/désactiver le stockage d'objets | `false` |
| `remote_directory` | Le nom du compartiment où les fichiers sécurisés sont stockés | |
| `connection` | Diverses options de connexion décrites ci-dessous | |

### Paramètres de connexion compatibles S3 {#s3-compatible-connection-settings}

Consultez [les paramètres de connexion disponibles pour différents fournisseurs](../object_storage.md#configure-the-connection-settings).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes, en utilisant les valeurs souhaitées :

   ```ruby
   gitlab_rails['ci_secure_files_object_store_enabled'] = true
   gitlab_rails['ci_secure_files_object_store_remote_directory'] = "ci_secure_files"
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   > [!note]
   > Si vous utilisez des profils AWS IAM, veillez à omettre la clé d'accès AWS et les paires clé/valeur de clé d'accès secrète :

   ```ruby
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [Migrez tous les états locaux existants vers le stockage d'objets](#migrate-to-object-storage).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   ci_secure_files:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "ci_secure_files"  # The bucket name
       connection:
         provider: AWS  # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. [Migrez tous les états locaux existants vers le stockage d'objets](#migrate-to-object-storage).

{{< /tab >}}

{{< /tabs >}}

### Migrer vers le stockage d'objets {#migrate-to-object-storage}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/125) dans GitLab 16.1.

{{< /history >}}

> [!warning]
> Il n'est pas possible de migrer les fichiers sécurisés du stockage d'objets vers le stockage local, alors procédez avec prudence.

Pour migrer les fichiers sécurisés vers le stockage d'objets, suivez les instructions ci-dessous.

- Pour les installations avec le package Linux :

  ```shell
  sudo gitlab-rake gitlab:ci_secure_files:migrate
  ```

- Pour les installations auto-compilées :

  ```shell
  sudo -u git -H bundle exec rake gitlab:ci_secure_files:migrate RAILS_ENV=production
  ```
