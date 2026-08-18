---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration des états Terraform
description: Administrer le stockage des états Terraform.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab peut être utilisé comme backend pour les fichiers d'état [Terraform](../user/infrastructure/_index.md). Les fichiers sont chiffrés avant d'être stockés. Cette fonctionnalité est activée par défaut.

L'emplacement de stockage de ces fichiers est par défaut :

- `/var/opt/gitlab/gitlab-rails/shared/terraform_state` pour les installations avec le package Linux.
- `/home/git/gitlab/shared/terraform_state` pour les installations compilées à partir des sources.

Ces emplacements peuvent être configurés à l'aide des options décrites ci-dessous.

Utilisez la configuration de [stockage d'objets externe](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files) pour les installations de [GitLab Helm chart](https://docs.gitlab.com/charts/).

## Désactivation de l'état Terraform {#disabling-terraform-state}

Vous pouvez désactiver l'état Terraform sur l'ensemble de l'instance. Vous pourriez vouloir désactiver Terraform pour réduire l'espace disque, ou parce que votre instance n'utilise pas Terraform.

Lorsque l'administration des états Terraform est désactivée :

- Dans la barre latérale gauche, vous ne pouvez pas sélectionner **Opération** > **États Terraform**.
- Tous les jobs CI/CD qui accèdent à l'état Terraform échouent avec cette erreur :

  ```shell
  Error refreshing state: HTTP remote state endpoint invalid auth
  ```

Pour désactiver l'administration Terraform, suivez les étapes ci-dessous en fonction de votre installation.

Prérequis :

- Vous devez être administrateur.

Pour les installations avec le package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['terraform_state_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Pour les installations compilées à partir des sources :

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   terraform_state:
     enabled: false
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Utilisation du stockage local {#using-local-storage}

La configuration par défaut utilise le stockage local. Pour modifier l'emplacement où les fichiers d'état Terraform sont stockés localement, suivez les étapes ci-dessous.

Pour les installations avec le package Linux :

1. Pour modifier le chemin de stockage, par exemple en `/mnt/storage/terraform_state`, modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['terraform_state_storage_path'] = "/mnt/storage/terraform_state"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Pour les installations compilées à partir des sources :

1. Pour modifier le chemin de stockage, par exemple en `/mnt/storage/terraform_state`, modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   terraform_state:
     enabled: true
     storage_path: /mnt/storage/terraform_state
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Utilisation du stockage objet {#using-object-storage}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Plutôt que de stocker les fichiers d'état Terraform sur disque, nous recommandons l'utilisation de [l'une des options de stockage d'objets prises en charge](object_storage.md#object-storage-provider-support). Cette configuration repose sur des identifiants valides déjà configurés.

[En savoir plus sur l'utilisation du stockage d'objets avec GitLab](object_storage.md).

### Paramètres du stockage d'objets {#object-storage-settings}

Les paramètres suivants sont :

- Préfixés par `terraform_state_object_store_` sur les installations avec le package Linux.
- Imbriqués sous `terraform_state:` puis `object_store:` sur les installations compilées manuellement.

| Paramètre | Description | Valeur par défaut |
|---------|-------------|---------|
| `enabled` | Activer/désactiver le stockage d'objets | `false` |
| `remote_directory` | Le nom du compartiment où sont stockés les fichiers d'état Terraform | |
| `connection` | Différentes options de connexion décrites ci-dessous | |

### Migrer vers le stockage d'objets {#migrate-to-object-storage}

> [!warning]
> Il n'est pas possible de migrer les fichiers d'état Terraform du stockage d'objets vers le stockage local, veuillez donc procéder avec prudence. [Un ticket existe](https://gitlab.com/gitlab-org/gitlab/-/issues/350187) pour modifier ce comportement.

Pour migrer les fichiers d'état Terraform vers le stockage d'objets :

- Pour les installations avec le package Linux :

  ```shell
  gitlab-rake gitlab:terraform_states:migrate
  ```

- Pour les installations compilées à partir des sources :

  ```shell
  sudo -u git -H bundle exec rake gitlab:terraform_states:migrate RAILS_ENV=production
  ```

Vous pouvez éventuellement suivre la progression et vérifier que tous les fichiers d'état Terraform ont bien été migrés à l'aide de la [console PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database) :

- `sudo gitlab-rails dbconsole --database main` pour les installations avec le package Linux.
- `sudo -u git -H psql -d gitlabhq_production` pour les installations compilées à partir des sources.

Vérifiez que `objectstg` ci-dessous (où `file_store=2`) contient le nombre total de tous les états :

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM terraform_state_versions;

total | filesystem | objectstg
------+------------+-----------
   15 |          0 |      15
```

Vérifiez qu'il n'y a aucun fichier sur le disque dans le dossier `terraform_state` :

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/terraform_state -type f | grep -v tmp | wc -l
```

### Paramètres de connexion compatibles S3 {#s3-compatible-connection-settings}

Vous devriez utiliser les [paramètres de stockage d'objets consolidés](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form). Cette section décrit l'ancien format de configuration.

Consultez [les paramètres de connexion disponibles pour les différents fournisseurs](object_storage.md#configure-the-connection-settings).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes, en remplaçant par les valeurs souhaitées :

   ```ruby
   gitlab_rails['terraform_state_object_store_enabled'] = true
   gitlab_rails['terraform_state_object_store_remote_directory'] = "terraform"
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   > [!note]
   > Si vous utilisez des profils AWS IAM, veillez à omettre la clé d'accès AWS et les paires clé/valeur de clé d'accès secrète.

   ```ruby
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. [Migrer les états locaux existants vers le stockage d'objets](#migrate-to-object-storage)

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   terraform_state:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "terraform" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.
1. [Migrer les états locaux existants vers le stockage d'objets](#migrate-to-object-storage)

{{< /tab >}}

{{< /tabs >}}

### Trouver le chemin d'un fichier d'état Terraform {#find-a-terraform-state-file-path}

Les fichiers d'état Terraform sont stockés dans le chemin de répertoire haché du projet concerné.

Le format du chemin est `/var/opt/gitlab/gitlab-rails/shared/terraform_state/<path>/<to>/<projectHashDirectory>/<UUID>/0.tfstate`, où [UUID](https://gitlab.com/gitlab-org/gitlab/-/blob/dcc47a95c7e1664cb15bef9a70f2a4eefa9bd99a/app/models/terraform/state.rb#L33) est défini de façon aléatoire.

Pour trouver le chemin d'un fichier d'état :

1. Ajoutez `get-terraform-path` à votre shell :

   ```shell
   get-terraform-path() {
       PROJECT_HASH=$(echo -n $1 | openssl dgst -sha256 | sed 's/^.* //')
       echo "${PROJECT_HASH:0:2}/${PROJECT_HASH:2:2}/${PROJECT_HASH}"
   }
   ```

1. Exécutez `get-terraform-path <project_id>`.

   ```shell
   $ get-terraform-path 650
   20/99/2099a9b5f777e242d1f9e19d27e232cc71e2fa7964fc988a319fce5671ca7f73
   ```

Le chemin relatif s'affiche.

## Restauration des fichiers d'état Terraform à partir de sauvegardes {#restoring-terraform-state-files-from-backups}

Pour restaurer les fichiers d'état Terraform à partir de sauvegardes, vous devez avoir accès aux fichiers d'état chiffrés et à la base de données GitLab.

### Tables de base de données {#database-tables}

La table de base de données suivante permet de retrouver le chemin S3 associé à des projets spécifiques :

- `terraform_states` : Contient les informations d'état de base, y compris l'identifiant universel unique (UUID) pour chaque état.

### Structure des fichiers et composition du chemin {#file-structure-and-path-composition}

Les fichiers d'état sont stockés dans une structure de répertoires spécifique, où :

- Les trois premiers segments du chemin sont dérivés de la valeur de hachage SHA-256 de l'ID du projet.
- Chaque état possède un UUID stocké dans la table de base de données `terraform_states` qui fait partie du chemin.

Par exemple, pour un projet où :

- L'ID du projet est `12345`
- L'UUID de l'état est `example-uuid`

Si la valeur de hachage SHA-256 de `12345` est `5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5`, la structure de dossiers serait :

```plaintext
terraform/                                                                 <- configured Terraform storage directory
├─ 59/                                                                     <- first and second character of project ID hash
|  ├─ 94/                                                                  <- third and fourth character of project ID hash
|  |  ├─ 5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5/ <- full project ID hash
|  |  |  ├─ example-uuid/                                                  <- state UUID
|  |  |  |  ├─ 1.tf                                                        <- individual state versions
|  |  |  |  ├─ 2.tf
|  |  |  |  ├─ 3.tf
```

### Processus de déchiffrement {#decryption-process}

Les fichiers d'état sont chiffrés à l'aide de Lockbox et nécessitent les informations suivantes pour le déchiffrement :

- Le secret d'application `db_key_base`
- L'ID du projet

La clé de chiffrement est dérivée à la fois de `db_key_base` et de l'ID du projet. Si vous ne pouvez pas accéder à `db_key_base`, le déchiffrement n'est pas possible.

Pour savoir comment déchiffrer manuellement des fichiers, consultez la documentation de [Lockbox](https://github.com/ankane/lockbox).

Pour consulter le processus de génération des clés de chiffrement, voir le [code de l'outil de téléchargement d'état](https://gitlab.com/gitlab-org/gitlab/-/blob/e0137111fbbd28316f38da30075aba641e702b98/app/uploaders/terraform/state_uploader.rb#L43).
