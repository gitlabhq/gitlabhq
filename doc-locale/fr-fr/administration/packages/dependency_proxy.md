---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration du proxy de dépendances GitLab
description: "Guide de l'administrateur pour gérer un proxy de dépendances GitLab pour les artefacts amont fréquemment consultés, notamment les images de conteneurs et les packages."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) dans [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) de GitLab Premium vers GitLab Free dans la version 13.6.

{{< /history >}}

Vous pouvez utiliser GitLab comme proxy de dépendances pour les artefacts amont fréquemment consultés, notamment les images de conteneurs et les packages.

Il s'agit de la documentation d'administration. Pour savoir comment utiliser les proxies de dépendances, consultez :

- Le guide d'utilisation du [proxy de dépendances pour les images de conteneurs](../../user/packages/dependency_proxy/_index.md)
- Le guide d'utilisation du [registre virtuel](../../user/packages/virtual_registry/_index.md)

Le proxy de dépendances GitLab :

- Est activé par défaut.
- Peut être désactivé par un administrateur.

## Désactiver le proxy de dépendances {#turn-off-the-dependency-proxy}

Le proxy de dépendances est activé par défaut. Si vous êtes administrateur, vous pouvez désactiver le proxy de dépendances. Pour désactiver le proxy de dépendances, suivez les instructions correspondant à votre installation GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Une fois l'installation terminée, mettez à jour le global `appConfig` pour désactiver le proxy de dépendances :

```yaml
global:
  appConfig:
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection:
        secret:
        key:
```

Pour plus d'informations, consultez [Configure Charts using Globals](https://docs.gitlab.com/charts/charts/globals/#configure-appconfig-settings).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Une fois l'installation terminée, configurez la section `dependency_proxy` dans `config/gitlab.yml`. Définissez `enabled` sur `false` pour désactiver le proxy de dépendances :

   ```yaml
   dependency_proxy:
     enabled: false
   ```

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

### Installations GitLab multinœuds {#multi-node-gitlab-installations}

Suivez les étapes pour les installations avec le package Linux pour chaque nœud Web et Sidekiq.

## Activer le proxy de dépendances {#turn-on-the-dependency-proxy}

Le proxy de dépendances est activé par défaut, mais peut être désactivé par un administrateur. Pour le désactiver manuellement, suivez les instructions de la section [Désactiver le proxy de dépendances](#turn-off-the-dependency-proxy).

## Modification du chemin de stockage {#changing-the-storage-path}

Par défaut, les fichiers du proxy de dépendances sont stockés localement, mais vous pouvez modifier l'emplacement local par défaut ou même utiliser le stockage d'objets.

### Modification du chemin de stockage local {#changing-the-local-storage-path}

Les fichiers du proxy de dépendances pour les installations avec le package Linux sont stockés sous `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/` et pour les installations depuis les sources sous `shared/dependency_proxy/` (relatif au répertoire Git home).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez la section `dependency_proxy` dans `config/gitlab.yml` :

   ```yaml
   dependency_proxy:
     enabled: true
     storage_path: shared/dependency_proxy
   ```

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

### Utilisation du stockage d'objets {#using-object-storage}

Au lieu de vous appuyer sur le stockage local, vous pouvez utiliser les [paramètres de stockage d'objets consolidés](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form). Cette section décrit le format de configuration antérieur. [Les étapes de migration s'appliquent toujours](#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage).

[En savoir plus sur l'utilisation du stockage d'objets avec GitLab](../object_storage.md).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes (décommentez si nécessaire) :

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   gitlab_rails['dependency_proxy_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/dependency_proxy"
   gitlab_rails['dependency_proxy_object_store_enabled'] = true
   gitlab_rails['dependency_proxy_object_store_remote_directory'] = "dependency_proxy" # The bucket name.
   gitlab_rails['dependency_proxy_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
   gitlab_rails['dependency_proxy_object_store_connection'] = {
     ##
     ## If the provider is AWS S3, uncomment the following
     ##
     #'provider' => 'AWS',
     #'region' => 'eu-west-1',
     #'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     #'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
     ##
     ## If the provider is other than AWS (an S3-compatible one), uncomment the following
     ##
     #'host' => 's3.amazonaws.com',
     #'aws_signature_version' => 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
     #'endpoint' => 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
     #'path_style' => false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez la section `dependency_proxy` dans `config/gitlab.yml` (décommentez si nécessaire) :

   ```yaml
   dependency_proxy:
     enabled: true
     ##
     ## The location where build dependency_proxy are stored (default: shared/dependency_proxy).
     ##
     # storage_path: shared/dependency_proxy
     object_store:
       enabled: false
       remote_directory: dependency_proxy  # The bucket name.
       #  proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
       ##
       ## If the provider is AWS S3, use the following
       ##
         provider: AWS
         region: us-east-1
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         ##
         ## If the provider is other than AWS (an S3-compatible one), comment out the previous 4 lines and use the following instead:
         ##
         #  host: 's3.amazonaws.com'             # default: s3.amazonaws.com.
         #  aws_signature_version: 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
         #  endpoint: 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
         #  path_style: false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   ```

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

#### Migrer les blobs et les manifestes locaux du proxy de dépendances vers le stockage d'objets {#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage}

Après avoir [configuré le stockage d'objets](#using-object-storage), utilisez la tâche suivante pour migrer les blobs et les manifestes existants du proxy de dépendances du stockage local vers le stockage distant. Le traitement est effectué par un worker en arrière-plan et ne nécessite aucune interruption de service.

- Pour les installations avec le package Linux :

  ```shell
  sudo gitlab-rake "gitlab:dependency_proxy:migrate"
  ```

- Pour les installations compilées depuis les sources :

  ```shell
  RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:dependency_proxy:migrate
  ```

Vous pouvez éventuellement suivre la progression et vérifier que tous les blobs et manifestes du proxy de dépendances ont bien été migrés à l'aide de la [console PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database) :

- `sudo gitlab-rails dbconsole` pour les installations avec le package Linux exécutant la version 14.1 et antérieure.
- `sudo gitlab-rails dbconsole --database main` pour les installations avec le package Linux exécutant la version 14.2 et ultérieure.
- `sudo -u git -H psql -d gitlabhq_production` pour les instances compilées depuis les sources.

Vérifiez que `objectstg` (où `file_store = '2'`) contient le nombre total de blobs et de manifestes du proxy de dépendances pour chaque requête respective :

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_blobs;

total | filesystem | objectstg
------+------------+-----------
 22   |          0 |        22

gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_manifests;

total | filesystem | objectstg
------+------------+-----------
 10   |          0 |        10
```

Vérifiez qu'il n'y a pas de fichiers sur le disque dans le dossier `dependency_proxy` :

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/dependency_proxy -type f | grep -v tmp | wc -l
```

## Modification de l'expiration du JWT {#changing-the-jwt-expiration}

Le proxy de dépendances suit le [flux d'authentification par jeton Docker v2](https://distribution.github.io/distribution/spec/auth/token/), en émettant un JWT au client pour l'utiliser lors des requêtes de téléchargement. Le délai d'expiration du jeton est configurable à l'aide du paramètre d'application `container_registry_token_expire_delay`. Il peut être modifié depuis la console rails :

```ruby
# update the JWT expiration to 30 minutes
ApplicationSetting.update(container_registry_token_expire_delay: 30)
```

L'expiration par défaut et l'expiration sur GitLab.com est de 15 minutes.

## Utilisation du proxy de dépendances derrière un proxy {#using-the-dependency-proxy-behind-a-proxy}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes :

   ```ruby
   gitlab_workhorse['env'] = {
     "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
     "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
