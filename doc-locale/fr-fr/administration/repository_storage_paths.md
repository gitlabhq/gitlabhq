---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Stockage du dépôt
description: Comment GitLab stocke les données du dépôt.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab stocke les [dépôts](../user/project/repository/_index.md) sur le stockage du dépôt. Le stockage du dépôt est soit :

- Un stockage physique configuré avec un `gitaly_address` qui pointe vers un [nœud Gitaly](gitaly/_index.md).
- [Stockage virtuel](gitaly/praefect/_index.md#virtual-storage) qui stocke les dépôts sur un cluster Gitaly (Praefect).

> [!warning]
> Le stockage du dépôt pourrait être configuré en tant que `path` pointant directement vers le répertoire où les dépôts sont stockés. L'accès direct de GitLab à un répertoire contenant des dépôts est obsolète. Vous devez configurer GitLab pour accéder aux dépôts via un stockage physique ou virtuel.

Pour plus d'informations sur :

- La configuration de Gitaly, voir [Configurer Gitaly](gitaly/configure_gitaly.md).
- La configuration du cluster Gitaly (Praefect), voir [Configurer le cluster Gitaly (Praefect)](gitaly/praefect/configure.md).

## Stockage haché {#hashed-storage}

Le stockage haché enregistre les projets sur disque dans un emplacement basé sur un hachage de l'ID du projet. Cela rend la structure des dossiers immuable et élimine la nécessité de synchroniser l'état des URL avec la structure du disque. Cela signifie que le renommage d'un groupe, d'un utilisateur ou d'un projet :

- Ne coûte que la transaction de base de données.
- Prend effet immédiatement.

Le hachage aide également à répartir les dépôts plus uniformément sur le disque. Le répertoire de niveau supérieur contient moins de dossiers que le nombre total d'espaces de nommage de niveau supérieur.

Le format de hachage est basé sur la représentation hexadécimale d'un SHA256, calculé avec `SHA256(project.id)`. Le dossier de niveau supérieur utilise les deux premiers caractères, suivi d'un autre dossier avec les deux caractères suivants. Ils sont tous deux stockés dans un dossier spécial `@hashed` afin de pouvoir coexister avec les projets de stockage legacy existants. Par exemple :

```ruby
# Project's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"

# Wiki's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Traduire les chemins de stockage hachés {#translate-hashed-storage-paths}

Le dépannage des problèmes liés aux dépôts Git, l'ajout de hooks et d'autres tâches nécessitent de traduire entre le nom de projet lisible par l'humain et le chemin de stockage haché. Vous pouvez traduire :

- À partir d'un [nom de projet vers son chemin haché](#from-project-name-to-hashed-path).
- À partir d'un [chemin haché vers le nom d'un projet](#from-hashed-path-to-project-name).

#### Du nom de projet au chemin haché {#from-project-name-to-hashed-path}

{{< history >}}

- Le champ **Chemin relatif** [renommé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416) depuis **Chemin relatif Gitaly** dans GitLab 16.3.

{{< /history >}}

Les administrateurs peuvent rechercher le chemin haché d'un projet à partir de son nom ou de son ID en utilisant :

- La [zone **Admin**](admin_area.md#administering-projects).
- Une console Rails.

Pour rechercher le chemin haché d'un projet dans la zone **Admin** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets** et sélectionnez le projet.
1. Localisez le champ **Chemin relatif**. La valeur est similaire à :

   ```plaintext
   "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
   ```

Pour rechercher le chemin haché d'un projet à l'aide d'une console Rails :

1. Démarrez une [console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez une commande similaire à cet exemple (utilisez soit l'ID du projet, soit son nom) :

   ```ruby
   Project.find(16).disk_path
   Project.find_by_full_path('group/project').disk_path
   ```

#### Du chemin haché au nom du projet {#from-hashed-path-to-project-name}

Les administrateurs peuvent rechercher le nom d'un projet à partir de son chemin relatif haché en utilisant :

- Une console Rails.
- Le fichier `config` dans le répertoire `*.git`.

Pour rechercher le nom d'un projet à l'aide de la console Rails :

1. Démarrez une [console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez une commande similaire à cet exemple :

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project
   ```

La chaîne entre guillemets dans cette commande est l'arborescence de répertoires que vous pouvez trouver sur votre serveur GitLab. Par exemple, sur une installation de package Linux par défaut, il s'agirait de `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git` avec `.git` supprimé de la fin du nom de répertoire.

La sortie inclut l'ID du projet et le nom du projet. Par exemple :

```plaintext
=> #<Project id:16 it/supportteam/ticketsystem>
```

#### Du chemin haché au chemin complet d'un projet {#from-hashed-path-to-full-path-of-a-project}

Pour rechercher le chemin complet d'un projet à l'aide de la console Rails :

1. Démarrez une [console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez une commande similaire à cet exemple :

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project.full_path
   ```

   Dans l'exemple, la chaîne entre guillemets dans cette commande est l'arborescence de répertoires sur votre serveur GitLab. Par exemple, sur une installation de package Linux par défaut, cette chaîne serait `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`, avec `.git` supprimé de la fin du nom de répertoire.

La sortie inclut le chemin complet du projet. Par exemple :

```plaintext
=> "it/supportteam/ticketsystem"
```

### Pools d'objets hachés {#hashed-object-pools}

Les pools d'objets sont des dépôts utilisés pour dédupliquer les [duplications de projets publics et internes](../user/project/repository/forking_workflow.md) et contiennent les objets du projet source. En utilisant `objects/info/alternates`, le projet source et les duplications utilisent le pool d'objets pour les objets partagés. Pour plus d'informations, consultez les informations sur la déduplication d'objets Git dans la documentation de développement GitLab.

Les objets sont déplacés du projet source vers le pool d'objets lorsque la maintenance est exécutée sur le projet source. Les dépôts du pool d'objets sont stockés de manière similaire aux dépôts ordinaires dans un répertoire appelé `@pools` au lieu de `@hashed`

```ruby
# object pool paths
"@pools/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"
```

> [!warning]
> N'exécutez pas `git prune` ou `git gc` dans les dépôts du pool d'objets, qui sont stockés dans le répertoire `@pools`. Cela peut entraîner une perte de données dans les dépôts ordinaires qui dépendent du pool d'objets.

### Traduire les chemins de stockage du pool d'objets hachés {#translate-hashed-object-pool-storage-paths}

Pour rechercher le pool d'objets d'un projet à l'aide d'une console Rails :

1. Démarrez une [console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez une commande similaire à l'exemple suivant :

   ```ruby
   project_id = 1
   pool_repository = Project.find(project_id).pool_repository
   pool_repository = Project.find_by_full_path('group/project').pool_repository

   # Get more details about the pool repository
   pool_repository.source_project
   pool_repository.member_projects
   pool_repository.shard
   pool_repository.disk_path
   ```

### Stockage du wiki de groupe {#group-wiki-storage}

Contrairement aux wikis de projet qui sont stockés dans le répertoire `@hashed`, les wikis de groupe sont stockés dans un répertoire appelé `@groups`. Comme les wikis de projet, les wikis de groupe suivent la convention de dossier de stockage haché, mais utilisent un hachage de l'ID de groupe plutôt que de l'ID de projet.

Par exemple :

```ruby
# group wiki paths
"@groups/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Stockage du cluster Gitaly (Praefect) {#gitaly-cluster-praefect-storage}

Si le cluster Gitaly (Praefect) est utilisé, Praefect gère les emplacements de stockage. Le chemin interne utilisé par Praefect pour le dépôt diffère du chemin haché. Pour plus d'informations, voir [Chemins de répliques générés par Praefect](gitaly/praefect/_index.md#praefect-generated-replica-paths).

### Cache des archives de fichiers du dépôt {#repository-file-archive-cache}

Les utilisateurs peuvent télécharger une archive dans des formats tels que `.zip` ou `.tar.gz` d'un dépôt en utilisant :

- L'interface utilisateur de GitLab.
- L'[API Repositories](../api/repositories.md#retrieve-file-archive-from-a-repository).

GitLab stocke cette archive dans un cache dans un répertoire sur le serveur GitLab.

L'emplacement du cache dépend de votre méthode d'installation :

- Pour les instances de package Linux, le répertoire par défaut pour le cache d'archives de fichiers est `/var/opt/gitlab/gitlab-rails/shared/cache/archive`. Vous pouvez configurer cela avec le paramètre `gitlab_rails['gitlab_repository_downloads_path']` dans `/etc/gitlab/gitlab.rb`.
- Pour les instances Helm chart, le cache est stocké dans `/srv/gitlab/shared/cache/archive`. Le répertoire ne peut pas être configuré.

Un job d'arrière-plan exécuté sur Sidekiq nettoie périodiquement les archives obsolètes de ce répertoire. Pour cette raison, ce répertoire doit être accessible par tous les nœuds Sidekiq et GitLab Workhorse. Si Sidekiq ne peut pas accéder au même répertoire utilisé par GitLab Workhorse, [le disque contenant le répertoire se remplit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6005).

Si vous ne souhaitez pas utiliser un montage partagé pour Sidekiq et GitLab Workhorse, vous pouvez plutôt configurer un job `cron` séparé pour supprimer les fichiers de ce répertoire.

Vous pouvez également désactiver entièrement le cache :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Pour désactiver le cache :

1. Définissez la variable d'environnement `WORKHORSE_ARCHIVE_CACHE_DISABLED` sur tous les nœuds qui exécutent Puma :

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_rails['env'] = { 'WORKHORSE_ARCHIVE_CACHE_DISABLED' => '1' }
   ```

1. Reconfigurez les nœuds mis à jour pour que la modification prenne effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Pour désactiver le cache, vous pouvez utiliser `--set gitlab.webservice.extraEnv.WORKHORSE_ARCHIVE_CACHE_DISABLED="1"`, ou spécifier ce qui suit dans votre fichier de valeurs :

```yaml
gitlab:
  webservice:
    extraEnv:
      WORKHORSE_ARCHIVE_CACHE_DISABLED: "1"
```

{{< /tab >}}

{{< /tabs >}}

### Prise en charge du stockage d'objets {#object-storage-support}

Ce tableau indique quels objets stockables peuvent être stockés dans chaque type de stockage :

| Objet stockable  | Stockage haché | Compatible S3 |
|:-----------------|:---------------|:--------------|
| Dépôt       | Oui            | -             |
| Pièces jointes      | Oui            | -             |
| Avatars          | Non             | -             |
| Pages            | Non             | -             |
| Registre Docker  | Non             | -             |
| Journaux de job CI/CD   | Non             | -             |
| Artefacts CI/CD  | Non             | Oui           |
| Cache CI/CD      | Non             | Oui           |
| Objets LFS      | Similaire        | Oui           |
| Pools de dépôts | Oui            | -             |

Les fichiers stockés dans un point de terminaison compatible S3 peuvent avoir les mêmes avantages que le [stockage haché](#hashed-storage), à condition qu'ils ne soient pas préfixés par `#{namespace}/#{project_name}`. C'est vrai pour le cache CI/CD et les objets LFS.

#### Avatars {#avatars}

Chaque fichier est stocké dans un répertoire correspondant à l'`id` qui lui est attribué dans la base de données. Le nom de fichier est toujours `avatar.png` pour les avatars d'utilisateurs. Lorsqu'un avatar est remplacé, le modèle `Upload` est détruit et un nouveau est créé avec un `id` différent.

#### Artefacts CI/CD {#cicd-artifacts}

Les artefacts CI/CD sont compatibles S3.

#### Objets LFS {#lfs-objects}

[Les objets LFS dans GitLab](../topics/git/lfs/_index.md) implémentent un schéma de stockage similaire utilisant deux caractères et des dossiers à deux niveaux, suivant l'implémentation Git :

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

Les objets LFS sont également [compatibles S3](lfs/_index.md#storing-lfs-objects-in-remote-object-storage).

## Configurer l'emplacement de stockage des nouveaux dépôts {#configure-where-new-repositories-are-stored}

Après avoir [configuré plusieurs stockages de dépôts](https://docs.gitlab.com/omnibus/settings/configuration/#store-git-data-in-an-alternative-directory), vous pouvez choisir où les nouveaux dépôts sont stockés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Stockage du dépôt**.
1. Saisissez des valeurs dans les champs **Nœuds de stockage pour les nouveaux dépôts**.
1. Sélectionnez **Sauvegarder les modifications**.

Chaque chemin de stockage de dépôt peut se voir attribuer un poids de 0 à 100. Lorsqu'un nouveau projet est créé, ces poids sont utilisés pour déterminer l'emplacement de stockage sur lequel le dépôt est créé.

Plus le poids d'un chemin de stockage de dépôt donné est élevé par rapport aux autres chemins de stockage de dépôts, plus il est souvent choisi (`(storage weight) / (sum of all weights) * 100 = chance %`).

Par défaut, si les poids des dépôts n'ont pas été configurés auparavant :

- `default` a un poids de `100`.
- Tous les autres stockages ont un poids de `0`.

> [!note]
> Si tous les poids de stockage sont `0` (par exemple, lorsque `default` n'existe pas), GitLab tente de créer de nouveaux dépôts sur `default`, quelle que soit la configuration ou si `default` existe. Consultez [le ticket de suivi](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) pour plus d'informations.

## Déplacer des dépôts {#move-repositories}

Pour déplacer un dépôt vers un stockage de dépôt différent (par exemple, de `default` vers `storage2`), utilisez le même processus que pour [la migration vers le cluster Gitaly (Praefect)](gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect).
