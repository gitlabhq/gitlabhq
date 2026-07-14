---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Options et outils de récupération de Gitaly Cluster (Praefect)
---

Gitaly Cluster (Praefect) peut récupérer après une défaillance du nœud primaire et des dépôts indisponibles. Gitaly Cluster (Praefect) peut effectuer une récupération de données et dispose d'outils pour la base de données de suivi Praefect.

## Gérer les nœuds Gitaly sur un Gitaly Cluster (Praefect) {#manage-gitaly-nodes-on-a-gitaly-cluster-praefect}

Vous pouvez ajouter et remplacer des nœuds Gitaly sur un Gitaly Cluster (Praefect).

### Ajouter de nouveaux nœuds Gitaly {#add-new-gitaly-nodes}

Pour ajouter un nouveau nœud Gitaly :

1. Installez le nouveau nœud Gitaly en suivant la [documentation](configure.md#gitaly).
1. Ajoutez le nouveau nœud à votre [configuration Praefect](configure.md#praefect) sous `praefect['virtual_storages']`.
1. Reconfigurez et redémarrez Praefect en exécutant les commandes suivantes :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

Le comportement de réplication dépend de votre paramètre de facteur de réplication.

#### Facteur de réplication personnalisé {#custom-replication-factor}

Si un facteur de réplication personnalisé est défini, Praefect ne réplique pas automatiquement les dépôts existants vers le nouveau nœud Gitaly. Vous devez définir le [facteur de réplication](configure.md#configure-replication-factor) pour chaque dépôt à l'aide de la commande Praefect `set-replication-factor`. Les nouveaux dépôts sont répliqués en fonction du [facteur de réplication](configure.md#configure-replication-factor).

#### Facteur de réplication par défaut {#default-replication-factor}

Si le facteur de réplication par défaut est utilisé, Praefect réplique automatiquement toutes les données vers tout nouveau nœud Gitaly ajouté à la configuration afin de maintenir le facteur de réplication.

### Remplacer un nœud Gitaly existant {#replace-an-existing-gitaly-node}

Vous pouvez remplacer un nœud Gitaly existant par un nouveau nœud portant le même nom ou un nom différent. Avant de supprimer l'ancien nœud :

- Si un facteur de réplication est défini, il doit être supérieur à 1 pour éviter toute perte de données.
- Si aucun facteur de réplication n'est défini, les dépôts sont répliqués sur chaque nœud du stockage virtuel.

Lorsqu'un nœud Gitaly primaire est supprimé, les dépôts gérés par ce nœud deviennent indisponibles jusqu'à ce que :

- Le nœud soit remplacé et répliqué.
- Un nouveau nœud de remplacement devienne disponible et contienne les données du nœud primaire remplacé.

Pendant que le nœud est indisponible, les requêtes de lecture vers les dépôts affectés échouent avec des erreurs `404`. Gitaly résout automatiquement cette situation lors de la prochaine tentative d'écriture sur les dépôts affectés en déclenchant un basculement pour établir un nouveau nœud primaire.

#### Avec un nœud portant le même nom {#with-a-node-with-the-same-name}

Pour utiliser le même nom pour le nœud de remplacement, utilisez le [vérificateur de dépôt](configure.md#enable-deletions) afin d'analyser le stockage et de supprimer les enregistrements de métadonnées orphelins. [Priorisez manuellement la vérification](configure.md#prioritize-verification-manually) du stockage remplacé pour accélérer le processus.

#### Avec un nœud portant un nom différent {#with-a-node-with-a-different-name}

Les étapes pour remplacer un nœud par un nœud portant un nom différent dans Gitaly Cluster (Praefect) dépendent de la définition ou non d'un [facteur de réplication](configure.md#configure-replication-factor).

Si un facteur de réplication personnalisé est défini, utilisez [`praefect set-replication-factor`](configure.md#configure-replication-factor) pour redéfinir le facteur de réplication par dépôt afin d'obtenir un nouveau stockage attribué.

Par exemple, si deux nœuds du stockage virtuel ont un facteur de réplication de 2 et qu'un nouveau nœud (`gitaly-3`) est ajouté, vous devez augmenter le facteur de réplication à 3 :

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage default -relative-path @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git -replication-factor 3

current assignments: gitaly-1, gitaly-2, gitaly-3
```

Cela garantit que le dépôt est répliqué vers le nouveau nœud et que la table `repository_assignments` est mise à jour avec le nom du nouveau nœud Gitaly.

Si le [facteur de réplication par défaut](configure.md#configure-replication-factor) est défini, les nouveaux nœuds ne sont pas automatiquement inclus dans la réplication. Vous devez suivre les étapes décrites précédemment.

Après avoir [vérifié](#check-for-data-loss) que le dépôt a bien été répliqué vers le nouveau nœud :

1. Supprimez le nœud `gitaly-1` de la [configuration Praefect](configure.md#praefect) sous `praefect['virtual_storages']`.
1. Reconfigurez et redémarrez Praefect :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

L'état de la base de données faisant référence à l'ancien nœud Gitaly peut être ignoré.

Une alternative consiste à réattribuer tous les dépôts de l'ancien stockage vers le nouveau, après avoir configuré le nouveau nœud Gitaly :

1. Connectez-vous à la base de données Praefect :

   ```shell
   /opt/gitlab/embedded/bin/psql -h <psql host> -U <user> -d <database name>
   ```

1. Mettez à jour la table `repository_assignments` pour remplacer l'ancien nom du nœud Gitaly (par exemple, `old-gitaly`) par le nouveau nom du nœud Gitaly (par exemple, `new-gitaly`) :

   ```sql
   UPDATE repository_assignments SET storage='new-gitaly' WHERE storage='old-gitaly';
   ```

Cela déclencherait les jobs de réplication appropriés pour ramener le système à l'état souhaité.

## Défaillance du nœud primaire {#primary-node-failure}

Gitaly Cluster (Praefect) récupère après une défaillance du nœud Gitaly primaire en promouvant un secondaire sain comme nouveau primaire. Gitaly Cluster (Praefect) :

- Élit un secondaire sain disposant d'une copie entièrement à jour du dépôt comme nouveau primaire.
- Si aucun secondaire entièrement à jour n'est disponible, élit le secondaire ayant le moins d'écritures non répliquées depuis le primaire comme nouveau primaire.
- Le dépôt devient indisponible s'il n'existe aucune copie entièrement à jour sur des secondaires sains. Utilisez la [sous-commande Praefect `dataloss`](#check-for-data-loss) pour le détecter.

### Dépôts indisponibles {#unavailable-repositories}

Un dépôt est indisponible si toutes ses répliques à jour sont indisponibles. Les dépôts indisponibles ne sont pas accessibles via Praefect afin d'éviter de servir des données obsolètes susceptibles de perturber les outils automatisés.

### Vérifier les pertes de données {#check-for-data-loss}

La sous-commande Praefect `dataloss` identifie les dépôts indisponibles. Cela permet d'identifier les pertes de données potentielles et les dépôts qui ne sont plus accessibles parce que toutes leurs copies de répliques à jour sont indisponibles.

Les paramètres suivants sont disponibles :

- `-virtual-storage` qui spécifie quel stockage virtuel vérifier. Comme ils peuvent nécessiter l'intervention d'un administrateur, le comportement par défaut est d'afficher les dépôts indisponibles.
- [`-partially-unavailable`](#unavailable-replicas-of-available-repositories) qui spécifie si les dépôts disponibles mais dont certaines copies attribuées sont indisponibles doivent être inclus dans la sortie.

> [!note]
> `dataloss` est encore en [bêta](../../../policy/development_stages_support.md#beta) et le format de sortie est susceptible de changer.

Pour vérifier les dépôts dont les primaires sont obsolètes ou les dépôts indisponibles, exécutez :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>]
```

Chaque stockage virtuel configuré est vérifié si aucun n'est spécifié :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss
```

Les dépôts qui n'ont pas de copies saines et entièrement à jour disponibles sont listés dans la sortie. Les informations suivantes sont affichées pour chaque dépôt :

- Le chemin relatif d'un dépôt vers le répertoire de stockage identifie chaque dépôt et regroupe les informations associées.
- `(unavailable)` est affiché à côté du chemin disque si le dépôt est indisponible.
- Le champ primaire liste le primaire actuel du dépôt. Si le dépôt n'a pas de primaire, le champ affiche `No Primary`.
- Les stockages synchronisés (In-Sync Storages) listent les répliques qui ont répliqué la dernière écriture réussie et toutes les écritures qui la précèdent.
- Les stockages obsolètes (Outdated Storages) listent les répliques qui contiennent une copie obsolète du dépôt. Les répliques qui n'ont aucune copie du dépôt mais qui devraient en contenir une sont également listées ici. Le nombre maximum de modifications manquantes dans la réplique est indiqué à côté de la réplique. Il est important de noter que les répliques obsolètes peuvent être entièrement à jour ou contenir des modifications ultérieures, mais Praefect ne peut pas le garantir.

Les informations supplémentaires incluent :

- Le fait qu'un nœud soit attribué pour héberger le dépôt est indiqué avec le statut de chaque nœud. `assigned host` est affiché à côté des nœuds attribués pour stocker le dépôt. Le texte est omis si le nœud contient une copie du dépôt mais n'est pas attribué pour le stocker. Ces copies ne sont pas maintenues synchronisées par Praefect, mais peuvent servir de sources de réplication pour mettre à jour les copies attribuées.
- `unhealthy` est affiché à côté des copies situées sur des nœuds Gitaly non sains.

Exemple de sortie :

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (unavailable):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-2, assigned host, unhealthy
      Outdated Storages:
        gitaly-1 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

Une confirmation est affichée lorsque chaque dépôt est disponible. Par exemple :

```shell
Virtual storage: default
  All repositories are available!
```

#### Répliques indisponibles de dépôts disponibles {#unavailable-replicas-of-available-repositories}

Pour également lister les informations sur les dépôts disponibles mais indisponibles depuis certains nœuds attribués, utilisez le drapeau `-partially-unavailable`.

Un dépôt est disponible s'il existe une réplique saine et à jour disponible. Certaines des répliques secondaires attribuées peuvent être temporairement indisponibles pendant qu'elles attendent de répliquer les dernières modifications.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>] [-partially-unavailable]
```

Exemple de sortie :

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git:
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-1, assigned host
      Outdated Storages:
        gitaly-2 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

Avec le drapeau `-partially-unavailable` défini, une confirmation est affichée si chaque réplique attribuée est entièrement à jour et saine.

Par exemple :

```shell
Virtual storage: default
  All repositories are fully available on all assigned storages!
```

### Vérifier les sommes de contrôle des dépôts {#check-repository-checksums}

Pour vérifier les sommes de contrôle du dépôt d'un projet sur tous les nœuds Gitaly, exécutez la [tâche Rake des répliques](../../raketasks/praefect.md#replica-checksums) sur le nœud GitLab principal.

### Accepter la perte de données {#accept-data-loss}

> [!warning]
> `accept-dataloss` entraîne une perte de données permanente en écrasant d'autres versions du dépôt. Les [efforts de récupération](#data-recovery) des données doivent être effectués avant de l'utiliser.

S'il n'est pas possible de remettre en ligne l'une des répliques à jour, vous devrez peut-être accepter une perte de données. Lors de l'acceptation d'une perte de données, Praefect marque la réplique choisie du dépôt comme la dernière version et la réplique vers les autres nœuds Gitaly attribués. Ce processus écrase toute autre version du dépôt, donc des précautions s'imposent.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss
-virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

### Activer les écritures ou accepter la perte de données {#enable-writes-or-accept-data-loss}

> [!warning]
> `accept-dataloss` entraîne une perte de données permanente en écrasant d'autres versions du dépôt. Les [efforts de récupération](#data-recovery) des données doivent être effectués avant de l'utiliser.

Praefect fournit les sous-commandes suivantes pour réactiver les écritures ou accepter une perte de données. S'il n'est pas possible de remettre en ligne l'un des nœuds à jour, vous devrez peut-être accepter une perte de données :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss -virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

Lors de l'acceptation d'une perte de données, Praefect :

1. Marque la copie choisie du dépôt comme la dernière version.
1. Réplique la copie vers les autres nœuds Gitaly attribués.

   Ce processus écrase toute autre copie du dépôt, donc des précautions s'imposent.

## Récupération de données {#data-recovery}

Si un nœud Gitaly échoue dans ses jobs de réplication pour quelque raison que ce soit, il finit par héberger des versions obsolètes des dépôts affectés. Praefect fournit des outils pour la réconciliation automatique. Ces outils réconcilent les dépôts obsolètes pour les remettre entièrement à jour.

Praefect réconcilie automatiquement les dépôts qui ne sont pas à jour. Par défaut, cette opération est effectuée toutes les cinq minutes. Pour chaque dépôt obsolète sur un nœud Gitaly sain, Praefect choisit une réplique aléatoire et entièrement à jour du dépôt sur un autre nœud Gitaly sain à partir duquel répliquer. Un job de réplication n'est planifié que s'il n'y a pas d'autres jobs de réplication en attente pour le dépôt cible.

La fréquence de réconciliation peut être modifiée via la configuration. La valeur peut être toute [valeur de durée Go](https://pkg.go.dev/time#ParseDuration) valide. Les valeurs inférieures à 0 désactivent la fonctionnalité.

Exemples :

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '5m', # the default value
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '30s', # reconcile every 30 seconds
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '0', # disable the feature
   },
}
```

### Supprimer manuellement des dépôts {#manually-remove-repositories}

La sous-commande Praefect `remove-repository` supprime un dépôt d'un Gitaly Cluster (Praefect), ainsi que tout l'état associé à un dépôt donné, notamment :

- Les dépôts sur disque sur tous les nœuds Gitaly concernés.
- Tout état de base de données suivi par Praefect.

Par défaut, la commande fonctionne en mode simulation (dry-run). Par exemple :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository>
```

- Remplacez `<virtual-storage>` par le nom du stockage virtuel contenant le dépôt.
- Remplacez `<repository>` par le chemin relatif du dépôt à supprimer.
- Ajoutez `-db-only` pour supprimer l'entrée de la base de données de suivi Praefect sans supprimer le dépôt sur disque. Utilisez cette option pour supprimer les entrées de base de données orphelines et protéger les données du dépôt sur disque contre la suppression lorsqu'un dépôt valide est spécifié par erreur. Si l'entrée de base de données est supprimée accidentellement, effectuez un nouveau suivi du dépôt avec la [commande `track-repository`](#manually-add-a-single-repository-to-the-tracking-database).
- Ajoutez `-apply` pour exécuter la commande en dehors du mode simulation et supprimer le dépôt. Par exemple :

  ```shell
  sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository> -apply
  ```

- `-virtual-storage` est le stockage virtuel dans lequel se trouve le dépôt. Les stockages virtuels sont configurés dans `/etc/gitlab/gitlab.rb` sous `praefect['configuration']['virtual_storage]` et se présentent comme suit :

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  Dans cet exemple, le stockage virtuel à spécifier est `default` ou `storage-1`.

- `-repository` est le chemin relatif du dépôt dans le stockage [commençant par `@hashed`](../../repository_storage_paths.md#hashed-storage). Par exemple :

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

Des parties du dépôt peuvent continuer à exister après l'exécution de `remove-repository`. Cela peut être dû à :

- Une erreur de suppression.
- Un appel RPC en cours ciblant le dépôt.

Si cela se produit, exécutez à nouveau `remove-repository`.

## Maintenance de la base de données de suivi Praefect {#praefect-tracking-database-maintenance}

Les tâches de maintenance courantes sur la base de données de suivi Praefect sont documentées dans cette section.

### Lister les dépôts non suivis {#list-untracked-repositories}

La sous-commande Praefect `list-untracked-repositories` liste les dépôts du Gitaly Cluster (Praefect) qui répondent aux deux critères suivants :

- Existent pour au moins un stockage Gitaly.
- Ne sont pas suivis dans la base de données de suivi Praefect.

Ajoutez l'option `-older-than` pour éviter d'afficher les dépôts qui :

- Sont en cours de création.
- Pour lesquels un enregistrement n'existe pas encore dans la base de données de suivi Praefect.

Remplacez `<duration>` par une durée (par exemple, `5s`, `10m`, ou `1h`). Par défaut, `6h`.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories -older-than <duration>
```

Seuls les dépôts dont la date de création est antérieure à la durée spécifiée sont pris en compte.

La commande génère en sortie :

- Le résultat vers `STDOUT` et les journaux de la commande.
- Les erreurs vers `STDERR`.

Chaque entrée est une chaîne JSON complète avec un saut de ligne à la fin (configurable à l'aide du drapeau `-delimiter`). Par exemple :

```plaintext
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567890.git"}
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567891.git"}
```

### Ajouter manuellement un seul dépôt à la base de données de suivi {#manually-add-a-single-repository-to-the-tracking-database}

> [!warning]
> En raison d'un [problème connu](https://gitlab.com/gitlab-org/gitaly/-/issues/5402), dans GitLab 16.0 et versions antérieures, vous ne pouvez pas ajouter des dépôts à la base de données de suivi Praefect avec des chemins de réplique générés par Praefect (`@cluster`). Ces dépôts ne sont pas associés au chemin de dépôt utilisé par GitLab et sont inaccessibles.

La sous-commande Praefect `track-repository` ajoute des dépôts sur disque à la base de données de suivi Praefect pour être suivis.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage <virtual-storage> -authoritative-storage <storage-name> -relative-path <repository> -replica-path <disk_path> -replicate-immediately
```

- `-virtual-storage` est le stockage virtuel dans lequel se trouve le dépôt. Les stockages virtuels sont configurés dans `/etc/gitlab/gitlab.rb` sous `praefect['configuration'][:virtual_storage]` et se présentent comme suit :

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  Dans cet exemple, le stockage virtuel à spécifier est `default` ou `storage-1`.

- `-relative-path` est le chemin relatif dans le stockage virtuel. Généralement [commençant par `@hashed`](../../repository_storage_paths.md#hashed-storage). Par exemple :

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

- `-replica-path` est le chemin relatif sur le stockage physique. Peut commencer par [`@cluster` ou correspondre à `relative_path`](../../repository_storage_paths.md#gitaly-cluster-praefect-storage).
- `-authoritative-storage` est le stockage que nous souhaitons que Praefect traite comme le primaire. Obligatoire si la [réplication par dépôt](configure.md#configure-replication-factor) est définie comme stratégie de réplication.
- `-replicate-immediately` entraîne la réplication immédiate du dépôt vers ses secondaires par la commande. Sinon, les jobs de réplication sont planifiés pour exécution dans la base de données et sont récupérés par un processus d'arrière-plan Praefect.

La commande génère en sortie :

- Les résultats vers `STDOUT` et les journaux de la commande.
- Les erreurs vers `STDERR`.

Cette commande échoue si :

- Le dépôt est déjà suivi par la base de données de suivi Praefect.
- Le dépôt n'existe pas sur disque.

### Ajouter manuellement plusieurs dépôts à la base de données de suivi {#manually-add-many-repositories-to-the-tracking-database}

> [!warning]
> En raison d'un [problème connu](https://gitlab.com/gitlab-org/gitaly/-/issues/5402), dans GitLab 16.0 et versions antérieures, vous ne pouvez pas ajouter des dépôts à la base de données de suivi Praefect avec des chemins de réplique générés par Praefect (`@cluster`). Ces dépôts ne sont pas associés au chemin de dépôt utilisé par GitLab et sont inaccessibles.

Les migrations utilisant l'API ajoutent automatiquement des dépôts à la base de données de suivi Praefect.

Si vous copiez manuellement des dépôts depuis une infrastructure existante, vous pouvez utiliser la sous-commande Praefect `track-repositories`. Cette sous-commande ajoute de grandes quantités de dépôts sur disque à la base de données de suivi Praefect.

```shell
# Omnibus GitLab install
sudo gitlab-ctl praefect track-repositories --input-path /path/to/input.json

# Source install
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repositories -input-path /path/to/input.json
```

La commande valide que toutes les entrées :

- Sont correctement formatées et contiennent les champs requis.
- Correspondent à un dépôt Git valide sur disque.
- Ne sont pas suivies dans la base de données de suivi Praefect.

Si une entrée ne passe pas ces vérifications, la commande s'interrompt avant de tenter de suivre un dépôt.

- `input-path` est le chemin vers un fichier contenant une liste de dépôts formatés sous forme d'objets JSON délimités par des sauts de ligne. Les objets doivent contenir les clés suivantes :
  - `relative_path` : correspond à `repository` dans [`track-repository`](#manually-add-a-single-repository-to-the-tracking-database).
  - `authoritative-storage` : le stockage que Praefect doit traiter comme le primaire.
  - `virtual-storage` : le stockage virtuel dans lequel se trouve le dépôt.

    Par exemple :

    ```json
    {"relative_path":"@hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git","replica_path":"@cluster/fe/d3/1","authoritative_storage":"gitaly-1","virtual_storage":"default"}
    {"relative_path":"@hashed/f8/9f/f89f8d0e735a91c5269ab08d72fa27670d000e7561698d6e664e7b603f5c4e40.git","replica_path":"@cluster/7b/28/2","authoritative_storage":"gitaly-2","virtual_storage":"default"}
    ```

- `-replicate-immediately`, entraîne la réplication immédiate du dépôt vers ses secondaires par la commande. Sinon, les jobs de réplication sont planifiés pour exécution dans la base de données et sont récupérés par un processus d'arrière-plan Praefect.

### Lister les détails des stockages virtuels {#list-virtual-storage-details}

La sous-commande Praefect `list-storages` liste les stockages virtuels et leurs nœuds de stockage associés. Si un stockage virtuel est :

- Spécifié à l'aide de `-virtual-storage`, il liste uniquement les nœuds de stockage du stockage virtuel spécifié.
- Non spécifié, tous les stockages virtuels et leurs nœuds de stockage associés sont listés au format tabulaire.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-storages -virtual-storage <virtual_storage_name>
```

La commande génère en sortie :

- Le résultat vers `STDOUT` et les journaux de la commande.
- Les erreurs vers `STDERR`.
