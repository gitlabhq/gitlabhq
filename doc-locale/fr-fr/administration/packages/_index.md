---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration du registre de paquets GitLab
description: Administrer le registre de paquets.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour utiliser GitLab comme dépôt privé pour divers gestionnaires de paquets courants, utilisez le registre de paquets. Vous pouvez créer et publier des paquets, qui peuvent être utilisés comme dépendances dans des projets en aval.

## Formats pris en charge {#supported-formats}

Le registre de paquets prend en charge les formats suivants :

| Type de paquet                                                       | Version de GitLab |
|--------------------------------------------------------------------|----------------|
| [Composer](../../user/packages/composer_repository/_index.md)      | 13.2+          |
| [Conan 1](../../user/packages/conan_1_repository/_index.md)        | 12.6+          |
| [Conan 2](../../user/packages/conan_2_repository/_index.md)        | 18.1+          |
| [Go](../../user/packages/go_proxy/_index.md)                       | 13.1+          |
| [Maven](../../user/packages/maven_repository/_index.md)            | 11.3+          |
| [npm](../../user/packages/npm_registry/_index.md)                  | 11.7+          |
| [NuGet](../../user/packages/nuget_repository/_index.md)            | 12.8+          |
| [PyPI](../../user/packages/pypi_repository/_index.md)              | 12.10+         |
| [Paquets génériques](../../user/packages/generic_packages/_index.md) | 13.5+          |
| [Helm Charts](../../user/packages/helm_repository/_index.md)       | 14.1+          |

Le registre de paquets est également utilisé pour stocker les [données du registre de modèles](../../user/project/ml/model_registry/_index.md).

## Contributions acceptées {#accepting-contributions}

Le tableau suivant répertorie les formats de paquets qui ne sont pas pris en charge. Envisagez de contribuer à GitLab pour ajouter la prise en charge de ces formats.

<!-- vale gitlab_base.Spelling = NO -->

| Format | Statut |
| ------ | ------ |
| Chef      | [\#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [\#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [\#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [\#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [Brouillon : Merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50438) |
| Opkg      | [\#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [\#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [\#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [\#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| RubyGems  | [\#803](https://gitlab.com/gitlab-org/gitlab/-/issues/803) |
| SBT       | [\#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Terraform | [Brouillon : Merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834) |
| Vagrant   | [\#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab_base.Spelling = YES -->

## Limites de débit {#rate-limits}

Lors du téléchargement de paquets en tant que dépendances dans des projets en aval, de nombreuses requêtes sont effectuées via l'API Packages. Vous pouvez donc atteindre les limites de débit appliquées aux utilisateurs et aux adresses IP. Pour résoudre ce problème, vous pouvez définir des limites de débit spécifiques pour l'API Packages. Pour plus de détails, consultez les [limites de débit du registre de paquets](../settings/package_registry_rate_limits.md).

## Activer ou désactiver le registre de paquets {#enable-or-disable-the-package-registry}

Le registre de paquets est activé par défaut. Pour le désactiver :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Change to true to enable packages - enabled by default if not defined
   gitlab_rails['packages_enabled'] = false
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       packages:
         enabled: false
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['packages_enabled'] = false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     packages:
       enabled: false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Modifier le chemin de stockage {#change-the-storage-path}

Par défaut, les paquets sont stockés localement, mais vous pouvez modifier l'emplacement local par défaut ou même utiliser un stockage d'objets.

### Modifier le chemin de stockage local {#change-the-local-storage-path}

Par défaut, les paquets sont stockés dans un chemin local, relatif à l'installation de GitLab :

- Linux package (Omnibus) : `/var/opt/gitlab/gitlab-rails/shared/packages/`
- Self-compiled (source) : `/home/git/gitlab/shared/packages/`

Pour modifier le chemin de stockage local :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['packages_storage_path'] = "/mnt/packages"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     packages:
       enabled: true
       storage_path: /mnt/packages
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

Si des paquets étaient déjà stockés dans l'ancien chemin de stockage, déplacez tout depuis l'ancien vers le nouvel emplacement pour vous assurer que les paquets existants restent accessibles :

```shell
mv /var/opt/gitlab/gitlab-rails/shared/packages/* /mnt/packages/
```

Docker et Kubernetes n'utilisent pas le stockage local.

- Pour le Helm chart (Kubernetes) :  Utilisez plutôt le stockage d'objets.
- Pour Docker :  Le répertoire `/var/opt/gitlab/` est déjà monté dans un répertoire sur l'hôte. Il n'est pas nécessaire de modifier le chemin de stockage local à l'intérieur du conteneur.

### Utiliser le stockage d'objets {#use-object-storage}

Au lieu de vous fier au stockage local, vous pouvez utiliser un stockage d'objets pour stocker les paquets.

Pour plus d'informations, consultez comment utiliser les [paramètres consolidés de stockage d'objets](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Migrer des paquets entre le stockage d'objets et le stockage local {#migrate-packages-between-object-storage-and-local-storage}

Après avoir configuré le stockage d'objets, vous pouvez utiliser les tâches suivantes pour migrer des paquets entre le stockage local et le stockage distant. Le traitement est effectué par un worker en arrière-plan et ne nécessite aucun temps d'arrêt.

#### Migrer vers le stockage d'objets {#migrate-to-object-storage}

La tâche de migration déplace les fichiers de paquets et les caches de métadonnées vers le stockage d'objets : les fichiers de paquets (`packages_package_files`), les caches de métadonnées Helm (`packages_helm_metadata_caches`), les caches de métadonnées NPM (`packages_npm_metadata_caches`) et les symboles NuGet (`packages_nuget_symbols`). Si vous avez déjà exécuté la migration et qu'il reste des fichiers pour l'un de ces types, réexécutez la tâche ; elle migrera tous les fichiers locaux restants.

1. Migrez les paquets vers le stockage d'objets :

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate"
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:packages:migrate
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Suivez la progression et vérifiez que tous les paquets ont été migrés avec succès à l'aide de la console PostgreSQL :

   {{< tabs >}} {{< tab title="Linux package (Omnibus) 14.1 et antérieur" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}} {{< tab title="Linux package (Omnibus) 14.2 et ultérieur" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}} {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}} {{< /tabs >}}

1. Vérifiez que tous les paquets ont été migrés vers le stockage d'objets avec la requête SQL suivante. Le nombre de `objectstg` doit être identique à `total` :

   ```sql
   SELECT count(*) AS total,
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem,
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg
   FROM packages_package_files;
   ```

   Exemple de résultat :

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |          0 |        34
   ```

1. Enfin, vérifiez qu'il n'y a aucun fichier sur le disque dans le répertoire `packages` :

   {{< tabs >}} {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< /tabs >}}

#### Migrer du stockage d'objets vers le stockage local {#migrate-from-object-storage-to-local-storage}

Les mêmes types sont migrés que lors du passage au stockage d'objets (fichiers de paquets, caches de métadonnées Helm, caches de métadonnées NPM et symboles NuGet).

1. Migrez les paquets du stockage d'objets vers le stockage local :

   {{< tabs >}} {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}} {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}} {{< /tabs >}}

1. Suivez la progression et vérifiez que tous les paquets ont été migrés avec succès à l'aide de la console PostgreSQL :

   {{< tabs >}} {{< tab title="Linux package (Omnibus) 14.1 et antérieur" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}} {{< tab title="Linux package (Omnibus) 14.2 et ultérieur" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}} {{< tab title="Self-compiled (source)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}} {{< /tabs >}}

1. Vérifiez que tous les paquets ont été migrés vers le stockage local avec la requête SQL suivante. Le nombre de `filesystem` doit être identique à `total` :

   ```sql
   SELECT count(*) AS total,
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem,
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg
   FROM packages_package_files;
   ```

   Exemple de résultat :

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |         34 |         0
   ```

1. Enfin, vérifiez que les fichiers existent dans le répertoire `packages` :

   {{< tabs >}} {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< /tabs >}}
