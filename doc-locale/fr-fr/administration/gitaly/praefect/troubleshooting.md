---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage du cluster Gitaly (Praefect)
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Reportez-vous aux informations ci-dessous pour résoudre les problèmes du cluster Gitaly (Praefect). Pour plus d'informations sur le dépannage de Gitaly, consultez [Dépannage de Gitaly](../troubleshooting.md).

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Vérifier l'intégrité du cluster {#check-cluster-health}

La sous-commande Praefect `check` exécute une série de vérifications pour déterminer l'intégrité du cluster Gitaly (Praefect).

```shell
gitlab-ctl praefect check
```

Si Praefect est déployé à l'aide du chart Praefect, exécutez directement le binaire.

```shell
/usr/local/bin/praefect check
```

Les sections suivantes décrivent les vérifications effectuées.

### Migrations Praefect {#praefect-migrations}

Étant donné que les migrations de base de données doivent être à jour pour que Praefect fonctionne correctement, vérifie si les migrations Praefect sont à jour.

Si cette vérification échoue :

1. Consultez la table `schema_migrations` dans la base de données pour voir quelles migrations ont été exécutées.
1. Exécutez `praefect sql-migrate` pour mettre les migrations à jour.

### Connectivité des nœuds et accès au disque {#node-connectivity-and-disk-access}

Vérifie si Praefect peut atteindre tous ses nœuds Gitaly, et si chaque nœud Gitaly dispose d'un accès en lecture et en écriture à tous ses stockages.

Si cette vérification échoue :

1. Confirmez que les adresses réseau et les jetons sont correctement configurés :
   - Dans la configuration de Praefect.
   - Dans la configuration de chaque nœud Gitaly.
1. Sur les nœuds Gitaly, vérifiez que le processus `gitaly` est exécuté en tant que `git`. Il peut y avoir un problème de permissions empêchant Gitaly d'accéder à ses répertoires de stockage.
1. Confirmez qu'il n'y a aucun problème avec le réseau qui connecte Praefect aux nœuds Gitaly.

### Accès en lecture et en écriture à la base de données {#database-read-and-write-access}

Vérifie si Praefect peut lire et écrire dans la base de données.

Si cette vérification échoue :

1. Vérifiez si la base de données Praefect est en mode de récupération. En mode de récupération, les tables peuvent être en lecture seule. Pour vérifier, exécutez :

   ```sql
   select pg_is_in_recovery()
   ```

1. Confirmez que l'utilisateur que Praefect utilise pour se connecter à PostgreSQL dispose d'un accès en lecture et en écriture à la base de données.
1. Vérifiez si la base de données a été placée en mode lecture seule. Pour vérifier, exécutez :

   ```sql
   show default_transaction_read_only
   ```

### Dépôts inaccessibles {#inaccessible-repositories}

Vérifie combien de dépôts sont inaccessibles parce qu'il leur manque une affectation primaire, ou parce que leur nœud primaire est indisponible.

Si cette vérification échoue :

1. Vérifiez si des nœuds Gitaly sont hors service. Exécutez `praefect ping-nodes` pour vérifier.
1. Vérifiez s'il y a une charge élevée sur la base de données Praefect. Si la base de données Praefect répond lentement, les contrôles d'intégrité peuvent ne pas être persistés dans la base de données, ce qui amène Praefect à considérer les nœuds comme non sains.

## Erreurs Praefect dans les journaux {#praefect-errors-in-logs}

Si vous recevez une erreur, consultez `/var/log/gitlab/gitlab-rails/production.log`.

Voici les erreurs courantes et leurs causes potentielles :

- Code de réponse 500
  - `ActionView::Template::Error (7:permission denied)`
    - `praefect['configuration'][:auth][:token]` et `gitlab_rails['gitaly_token']` ne correspondent pas sur le serveur GitLab.
    - La configuration de stockage `gitlab_rails['repositories_storages']` est manquante sur le serveur Sidekiq.
  - `Unable to save project. Error: 7:permission denied`
    - Le jeton secret dans `praefect['configuration'][:virtual_storage]` sur le serveur GitLab ne correspond pas à la valeur dans `gitaly['auth_token']` sur un ou plusieurs serveurs Gitaly.
- Code de réponse 503
  - `GRPC::Unavailable (14:failed to connect to all addresses)`
    - GitLab n'a pas pu atteindre Praefect.
  - `GRPC::Unavailable (14:all SubCons are in TransientFailure...)`
    - Praefect ne peut pas atteindre un ou plusieurs de ses nœuds Gitaly enfants. Essayez d'exécuter le vérificateur de connexion Praefect pour diagnostiquer le problème.

## Base de données Praefect soumise à une charge CPU élevée {#praefect-database-experiencing-high-cpu-load}

Voici quelques raisons courantes pour lesquelles la base de données Praefect peut subir une utilisation élevée du CPU :

- Les collectes de métriques Prometheus [exécutent une requête coûteuse](https://gitlab.com/gitlab-org/gitaly/-/issues/3796). Définissez `praefect['configuration'][:prometheus_exclude_database_from_default_metrics] = true` dans `gitlab.rb`.
- [La mise en cache de distribution des lectures](configure.md#reads-distribution-caching) est désactivée, ce qui augmente le nombre de requêtes effectuées vers la base de données lorsque le trafic utilisateur est élevé. Assurez-vous que la mise en cache de distribution des lectures est activée.

## Déterminer le nœud Gitaly primaire {#determine-primary-gitaly-node}

Pour déterminer le nœud primaire d'un dépôt, utilisez la sous-commande [`praefect metadata`](#view-repository-metadata).

## Afficher les métadonnées du dépôt {#view-repository-metadata}

Gitaly Cluster (Praefect) gère une [base de données de métadonnées](_index.md#components) contenant des informations sur les dépôts stockés dans le cluster. Utilisez la sous-commande `praefect metadata` pour inspecter les métadonnées à des fins de dépannage.

Vous pouvez récupérer les métadonnées d'un dépôt de l'une des manières suivantes :

- Stockage virtuel et [chemin relatif](../../repository_storage_paths.md#from-project-name-to-hashed-path).
- [ID de dépôt attribué par Praefect](_index.md#praefect-generated-replica-paths).

{{< tabs >}}

{{< tab title="Stockage virtuel et chemin relatif" >}}

Pour récupérer les métadonnées d'un dépôt à partir de son stockage virtuel et de son chemin relatif :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets** et sélectionnez le projet.
1. Notez les valeurs de **Nom de stockage** et **Chemin relatif** pour le projet.
1. Avec ces valeurs, exécutez la commande suivante :

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage <virtual-storage> -relative-path <relative-path>
   ```

{{< /tab >}}

{{< tab title="ID de dépôt attribué par Praefect" >}}

> [!note]
> Un ID de dépôt n'est pas identique à un ID de projet.

Pour récupérer les métadonnées d'un dépôt à partir de son ID de dépôt attribué par Praefect :

1. Notez le dernier composant du chemin de réplique du dépôt. Par exemple, pour `@cluster/repositories/6f/96/54771`, l'ID du dépôt est `54771`.
1. Avec cette valeur, exécutez la commande suivante :

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id <repository-id>
   ```

{{< /tab >}}

{{< /tabs >}}

### Exemples {#examples}

Pour récupérer les métadonnées d'un dépôt avec le stockage virtuel `default` et le chemin relatif `@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git` :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage default -relative-path @hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git
```

Pour récupérer les métadonnées d'un dépôt avec un ID de dépôt attribué par Praefect égal à 1 :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id 1
```

L'un ou l'autre de ces exemples récupère les métadonnées suivantes pour un exemple de dépôt :

```plaintext
Repository ID: 54771
Virtual Storage: "default"
Relative Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Replica Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Primary: "gitaly-1"
Generation: 1
Replicas:
- Storage: "gitaly-1"
  Assigned: true
  Generation: 1, fully up to date
  Healthy: true
  Valid Primary: true
  Verified At: 2021-04-01 10:04:20 +0000 UTC
- Storage: "gitaly-2"
  Assigned: true
  Generation: 0, behind by 1 changes
  Healthy: true
  Valid Primary: false
  Verified At: unverified
- Storage: "gitaly-3"
  Assigned: true
  Generation: replica not yet created
  Healthy: false
  Valid Primary: false
  Verified At: unverified
```

### Métadonnées disponibles {#available-metadata}

Les métadonnées récupérées par `praefect metadata` incluent les champs des tableaux suivants.

| Champ             | Description                                                                                                        |
|:------------------|:-------------------------------------------------------------------------------------------------------------------|
| `Repository ID`   | ID unique permanent attribué au dépôt par Praefect. Différent de l'ID que GitLab utilise pour les dépôts.      |
| `Virtual Storage` | Nom du stockage virtuel dans lequel le dépôt est stocké.                                                           |
| `Relative Path`   | Chemin du dépôt dans le stockage virtuel.                                                                          |
| `Replica Path`    | Emplacement sur le disque du nœud Gitaly où sont stockées les répliques du dépôt.                                                |
| `Primary`         | Nœud primaire actuel du dépôt.                                                                                 |
| `Generation`      | Utilisé par Praefect pour suivre les modifications du dépôt. Chaque écriture dans le dépôt incrémente la génération du dépôt. |
| `Replicas`        | Liste des répliques qui existent ou dont l'existence est prévue.                                                            |

Pour chaque réplique, les métadonnées suivantes sont disponibles :

| Champ `Replicas` | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|:-----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Storage`        | Nom du stockage Gitaly contenant la réplique.                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Assigned`       | Indique si la réplique est supposée exister dans le stockage. Peut être `false` si un nœud Gitaly est supprimé du cluster ou si le stockage contient une copie supplémentaire après que le facteur de réplication du dépôt a été diminué.                                                                                                                                                                                                                       |
| `Generation`     | Dernière génération confirmée de la réplique. Elle indique :<br><br>\- La réplique est entièrement à jour si la génération correspond à celle du dépôt.<br>\- La réplique est obsolète si la génération de la réplique est inférieure à celle du dépôt.<br>- `replica not yet created` si la réplique n'existe pas encore du tout dans le stockage.                                                                                                          |
| `Healthy`        | Indique si le nœud Gitaly hébergeant cette réplique est considéré comme sain par le consensus des nœuds Praefect.                                                                                                                                                                                                                                                                                                                               |
| `Valid Primary`  | Indique si la réplique est apte à servir de nœud primaire. Si le nœud primaire du dépôt n'est pas un nœud primaire valide, un basculement se produit lors de la prochaine écriture dans le dépôt s'il existe une autre réplique qui est un nœud primaire valide. Une réplique est un nœud primaire valide si :<br><br>\- Elle est stockée sur un nœud Gitaly sain.<br>\- Elle est entièrement à jour.<br>\- Elle n'est pas ciblée par un job de suppression en attente résultant d'une diminution du facteur de réplication.<br>\- Elle est assignée. |
| `Verified At` | Indique la dernière vérification réussie de la réplique par le [worker de vérification](configure.md#repository-verification). Si la réplique n'a pas encore été vérifiée, `unverified` est affiché à la place de l'heure de la dernière vérification réussie. |

### La commande échoue avec 'repository not found' {#command-fails-with-repository-not-found}

Si la valeur fournie pour `-virtual-storage` est incorrecte, la commande renvoie l'erreur suivante :

```plaintext
get metadata: rpc error: code = NotFound desc = repository not found
```

Les exemples documentés spécifient `-virtual-storage default`. Vérifiez le paramètre serveur Praefect `praefect['configuration'][:virtual_storage]` dans `/etc/gitlab/gitlab.rb`.

## Vérifier que les dépôts sont synchronisés {#check-that-repositories-are-in-sync}

Dans [certains cas](_index.md#known-issues), la base de données Praefect peut se désynchroniser avec les nœuds Gitaly sous-jacents. Pour vérifier qu'un dépôt donné est entièrement synchronisé sur tous les nœuds, exécutez la [tâche Rake `gitlab:praefect:replicas`](../../raketasks/praefect.md#replica-checksums) sur votre nœud Rails. Cette tâche Rake calcule la somme de contrôle du dépôt sur tous les nœuds Gitaly.

La commande [Praefect `dataloss`](recovery.md#check-for-data-loss) vérifie uniquement l'état du dépôt dans la base de données Praefect et ne peut pas être utilisée pour détecter les problèmes de synchronisation dans ce scénario.

### La commande `dataloss` affiche les dépôts `@failed-geo-sync` comme non synchronisés {#dataloss-command-shows-failed-geo-sync-repositories-as-out-of-sync}

`@failed-geo-sync` est un chemin hérité utilisé sur GitLab 16.1 et versions antérieures par Geo lorsque la synchronisation du projet échouait et a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/375640).

Sur GitLab 16.2 et versions ultérieures, vous pouvez supprimer ce chemin en toute sécurité. Les répertoires `@failed-geo-sync` se trouvent sous [le chemin du dépôt](../../repository_storage_paths.md) sur les nœuds Gitaly.

## Erreurs 'relation does not exist' {#relation-does-not-exist-errors}

Par défaut, les tables de la base de données Praefect sont créées automatiquement par la tâche `gitlab-ctl reconfigure`.

Cependant, les tables de la base de données Praefect ne sont pas créées lors de la reconfiguration initiale et peuvent générer des erreurs indiquant que des relations n'existent pas, si l'une des conditions suivantes s'applique :

- La commande `gitlab-ctl reconfigure` n'est pas exécutée.
- Des erreurs surviennent pendant l'exécution.

Par exemple :

- `ERROR:  relation "node_status" does not exist at character 13`
- `ERROR:  relation "replication_queue_lock" does not exist at character 40`
- Cette erreur :

  ```json
  {"level":"error","msg":"Error updating node: pq: relation \"node_status\" does not exist","pid":210882,"praefectName":"gitlab1x4m:0.0.0.0:2305","time":"2021-04-01T19:26:19.473Z","virtual_storage":"praefect-cluster-1"}
  ```

Pour résoudre ce problème, la migration du schéma de base de données peut être effectuée à l'aide de la sous-commande `sql-migrate` de la commande `praefect` :

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-migrate
praefect sql-migrate: OK (applied 21 migrations)
```

## Les requêtes échouent avec des erreurs 'repository scoped: invalid Repository' {#requests-fail-with-repository-scoped-invalid-repository-errors}

Cela indique que le nom de stockage virtuel utilisé dans la [configuration Praefect](configure.md#praefect) ne correspond pas au nom de stockage utilisé dans le [paramètre `gitaly['configuration'][:storage][<index>][:name]`](configure.md#gitaly) pour GitLab.

Résolvez ce problème en faisant correspondre les noms de stockage virtuel utilisés dans les configurations Praefect et GitLab.

## Problèmes de performances du cluster Gitaly (Praefect) sur les plateformes cloud {#gitaly-cluster-praefect-performance-issues-on-cloud-platforms}

Praefect ne nécessite pas beaucoup de CPU ni de mémoire, et peut s'exécuter sur de petites machines virtuelles. Les services cloud peuvent imposer d'autres limites sur les ressources que les petites machines virtuelles peuvent utiliser, comme les entrées/sorties disque et le trafic réseau.

Les nœuds Praefect génèrent beaucoup de trafic réseau. Les symptômes suivants peuvent être observés si leur bande passante réseau a été limitée par le service cloud :

- Mauvaises performances des opérations Git.
- Latence réseau élevée.
- Utilisation élevée de la mémoire par Praefect.

Solutions possibles :

- Provisionnez de plus grandes machines virtuelles pour bénéficier de quotas de trafic réseau plus importants.
- Utilisez les outils de surveillance et de journalisation de votre service cloud pour vérifier que les nœuds Praefect n'épuisent pas leurs quotas de trafic.

## `gitlab-ctl reconfigure` échoue avec une erreur de configuration Praefect {#gitlab-ctl-reconfigure-fails-with-a-praefect-configuration-error}

Si `gitlab-ctl reconfigure` échoue, vous pourriez voir cette erreur :

```plaintext
STDOUT: praefect: configuration error: error reading config file: toml: cannot store TOML string into a Go int
```

Cette erreur se produit lorsque `praefect['database_port']` ou `praefect['database_direct_port']` sont configurés sous forme de chaîne de caractères au lieu d'un entier.

## Erreurs de réplication courantes {#common-replication-errors}

Voici quelques erreurs de réplication courantes avec des solutions possibles.

### Le fichier de verrouillage existe {#lock-file-exists}

Les fichiers de verrouillage sont utilisés pour empêcher plusieurs mises à jour de la même référence. Parfois, les fichiers de verrouillage deviennent obsolètes et la réplication échoue avec l'erreur `error: cannot lock ref`.

Pour effacer les fichiers `*.lock` obsolètes, vous pouvez déclencher `OptimizeRepositoryRequest` sur la [console Rails](../../operations/rails_console.md) :

```ruby
p = Project.find <Project ID>
client = Gitlab::GitalyClient::RepositoryService.new(p.repository)
client.optimize_repository
```

Si le déclenchement de `OptimizeRepositoryRequest` ne fonctionne pas, inspectez les fichiers manuellement pour confirmer la date de création et décider si le fichier `*.lock` peut être supprimé manuellement. Tout fichier de verrouillage créé il y a plus de 24 heures peut être supprimé en toute sécurité.

### Erreurs Git `fsck` {#git-fsck-errors}

Les dépôts Gitaly contenant des objets invalides peuvent entraîner des échecs de réplication avec des erreurs dans les journaux Gitaly tels que :

- `exit status 128, stderr: "fatal: git upload-pack: not our ref"`.
- `"fatal: bad object 58....e0f... ssh://gitaly/internal.git did not send all necessary objects`.

Tant qu'un des nœuds Gitaly dispose encore d'une copie saine du dépôt, ces problèmes peuvent être résolus en :

1. [Supprimant le dépôt de la base de données Praefect](recovery.md#manually-remove-repositories).
1. Utilisant la [sous-commande Praefect `track-repository`](recovery.md#manually-add-a-single-repository-to-the-tracking-database) pour le retracer.

La copie du dépôt du nœud Gitaly faisant autorité sera utilisée pour écraser les copies sur tous les autres nœuds Gitaly. Assurez-vous qu'une sauvegarde récente du dépôt a été effectuée avant d'exécuter ces commandes.

1. Déplacez le mauvais dépôt hors de son emplacement :

   ```shell
   run `mv <REPOSITORY_PATH> <REPOSITORY_PATH>.backup`
   ```

   Par exemple :

   ```shell
   mv /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335 /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335.backup
   ```

1. Exécutez les commandes Praefect pour déclencher la réplication :

   ```shell
   # Validate you have the correct repository.
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only

   # Run again with '--apply' flag to remove repository from the Praefect tracking database
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only --apply

   # Re-track the repository, overwriting the secondary nodes
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage gitaly -authoritative-storage '<healthy_gitaly>' -relative-path '<relative_path>' -replica-path '<replica_path>'-replicate-immediately
   ```

### La réplication échoue silencieusement {#replication-fails-silently}

Si le [Praefect `dataloss`](recovery.md#check-for-data-loss) affiche des [dépôts partiellement indisponibles](recovery.md#unavailable-replicas-of-available-repositories), et que la [commande `accept-dataloss`](recovery.md#accept-data-loss) ne parvient pas à synchroniser le dépôt sans qu'aucune erreur ne soit présente dans les journaux, cela peut être dû à une incohérence dans la base de données Praefect dans le champ `repository_id` de la table `storage_repositories`. Pour vérifier l'existence d'une incohérence :

1. Connectez-vous à la base de données Praefect.
1. Exécutez la requête suivante :

   ```sql
   select * from storage_repositories where relative_path = '<relative-path>';
   ```

   Remplacez `<relative-path>` par le chemin du dépôt [commençant par `@hashed`](../../repository_storage_paths.md#hashed-storage).

### Le répertoire alternatif n'existe pas {#alternate-directory-does-not-exists}

GitLab utilise le mécanisme d'alternates Git pour la déduplication. `alternates` est un fichier texte qui pointe vers le répertoire `objects` d'un dépôt `@pool` pour récupérer les objets. Si ce fichier pointe vers un chemin invalide, la réplication peut échouer avec l'une des erreurs suivantes :

- `"error":"no alternates directory exists", "warning","msg":"alternates file does not point to valid git repository"`
- `"error":"unexpected alternates content:`
- `remote: error: unable to normalize alternate object path`

Pour analyser la cause de cette erreur :

1. Vérifiez si le projet fait partie d'un pool en utilisant la [console Rails](../../operations/rails_console.md) :

   ```ruby
   project = Project.find_by_id(<project id>)
   project.pool_repository
   ```

1. Vérifiez si le chemin du dépôt pool existe sur le disque et qu'il correspond au contenu du fichier `alternates`.
1. Vérifiez si le chemin dans le fichier `alternates` est accessible depuis le répertoire `objects` dans le projet.

Après avoir effectué ces vérifications, contactez le support GitLab avec les informations collectées.

### Les projets sont bloqués en état lecture seule après l'échec de déplacements de stockage de dépôts {#projects-are-stuck-in-read-only-state-after-failed-repository-storage-moves}

Lors de l'utilisation de l'Horizontal Pod Autoscaler (HPA) avec des pods Sidekiq, les déplacements de stockage de dépôt peuvent échouer silencieusement en raison de la mise à l'échelle des pods pendant l'exécution du job. Si un déplacement de stockage de dépôt a échoué en raison de ce problème, les projets en échec peuvent rester bloqués dans un état lecture seule.

Pour récupérer les dépôts affectés :

1. [Réinitialiser les projets affectés à l'état lecture-écriture](../../read_only_gitlab.md#make-the-repositories-read-only).
1. [Désactiver le HPA pour les pods Sidekiq](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#disable-hpa-scaling)
1. [Réexécuter les déplacements de stockage à l'aide de l'API REST](../../operations/moving_repositories.md) pour les projets individuels.
1. Restaurez la configuration HPA une fois la migration terminée.
