---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Traitement de classes de jobs spécifiques
---

> [!warning]
> Il s'agit de paramètres avancés. Bien qu'ils soient utilisés sur GitLab.com, la plupart des instances GitLab devraient simplement ajouter plus de processus qui écoutent toutes les files d'attente. Il s'agit de la même approche décrite dans les [architectures de référence](../reference_architectures/_index.md).

La plupart des instances GitLab devraient avoir [tous les processus à l'écoute de toutes les files d'attente](extra_sidekiq_processes.md#start-multiple-processes).

Une autre alternative consiste à utiliser des [règles de routage](#routing-rules) qui dirigent des classes de jobs spécifiques à l'intérieur de l'application vers les noms de files d'attente que vous configurez. Ensuite, les processus Sidekiq n'ont besoin d'écouter qu'une poignée des files d'attente configurées. Cela réduit la charge sur Redis, ce qui est important pour les déploiements à très grande échelle.

## Règles de routage {#routing-rules}

{{< history >}}

- [Valeur de règle de routage par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97908) introduite dans GitLab 15.4.
- Les sélecteurs de file d'attente [remplacés par des règles de routage](https://gitlab.com/gitlab-org/gitlab/-/issues/390787) dans GitLab 17.0.

{{< /history >}}

> [!note]
> Les jobs de messagerie ne peuvent pas être routés par les règles de routage et vont toujours dans la file d'attente `mailers`. Lorsque vous utilisez des règles de routage, assurez-vous qu'au moins un processus écoute la file d'attente `mailers`. Généralement, celle-ci peut être placée à côté de la file d'attente `default`.

Nous recommandons à la plupart des instances GitLab d'utiliser des règles de routage pour gérer leurs files d'attente Sidekiq. Cela permet aux administrateurs de choisir des noms de files d'attente uniques pour des groupes de classes de jobs en fonction de leurs attributs. La syntaxe est un tableau ordonné de paires de `[query, queue]` :

1. La requête est une [requête de correspondance de worker](#worker-matching-query).
1. Le nom de la file d'attente doit être un nom de file d'attente Sidekiq valide. Si le nom de la file d'attente est `nil` ou une chaîne vide, le worker est routé vers la file d'attente générée par le nom du worker à la place. (Voir la [liste des classes de jobs disponibles](#list-of-available-job-classes) pour plus d'informations). Le nom de la file d'attente n'a pas besoin de correspondre à un nom de file d'attente existant dans la liste des classes de jobs disponibles.
1. La première requête correspondant à un worker est choisie pour ce worker ; les règles ultérieures sont ignorées.

### Migration des règles de routage {#routing-rules-migration}

Une fois les règles de routage Sidekiq modifiées, vous devez faire attention à la migration pour éviter de perdre des jobs entièrement, en particulier dans un système avec de longues files d'attente de jobs. La migration peut être effectuée en suivant les étapes de migration mentionnées dans [Migration de jobs Sidekiq](sidekiq_job_migration.md).

### Règles de routage dans une architecture mise à l'échelle {#routing-rules-in-a-scaled-architecture}

Les règles de routage doivent être identiques sur tous les nœuds GitLab (en particulier les nœuds GitLab Rails et Sidekiq) car elles font partie de la configuration de l'application.

### Exemple détaillé {#detailed-example}

Il s'agit d'un exemple complet destiné à montrer différentes possibilités. Un [exemple de chart Helm est également disponible](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#queues). Il ne s'agit pas de recommandations.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   sidekiq['routing_rules'] = [
     # Route all non-CPU-bound workers that are high urgency to `high-urgency` queue
     ['resource_boundary!=cpu&urgency=high', 'high-urgency'],
     # Route all database, gitaly and global search workers that are throttled to `throttled` queue
     ['feature_category=database,gitaly,global_search&urgency=throttled', 'throttled'],
     # Route all workers having contact with outside world to a `network-intensive` queue
     ['has_external_dependencies=true|feature_category=hooks|tags=network', 'network-intensive'],
     # Wildcard matching, route the rest to `default` queue
     ['*', 'default']
   ]
   ```

   Le `queue_groups` peut ensuite être défini pour correspondre à ces noms de files d'attente générés. Par exemple :

   ```ruby
   sidekiq['queue_groups'] = [
     # Run two high-urgency processes
     'high-urgency',
     'high-urgency',
     # Run one process for throttled, network-intensive
     'throttled,network-intensive',
     # Run one 'catchall' process on the default and mailers queues
     'default,mailers'
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Requête de correspondance de worker {#worker-matching-query}

GitLab fournit une syntaxe de requête pour faire correspondre un worker en fonction de ses attributs utilisés par les règles de routage. Une requête comprend deux composants :

- Les attributs qui peuvent être sélectionnés.
- Les opérateurs utilisés pour construire une requête.

### Attributs disponibles {#available-attributes}

La requête de correspondance de file d'attente repose sur les attributs du worker, décrits dans le guide de style Sidekiq dans la documentation de développement GitLab. Nous prenons en charge les requêtes basées sur un sous-ensemble d'attributs de worker :

- `feature_category` - la catégorie de fonctionnalité GitLab à laquelle appartient la file d'attente. Par exemple, la file d'attente `merge` appartient à la catégorie `source_code_management`.
- `has_external_dependencies` - indique si la file d'attente se connecte ou non à des services externes. Par exemple, tous les importeurs ont cet attribut défini sur `true`.
- `urgency` - importance que les jobs de cette file d'attente s'exécutent rapidement. Peut être `high`, `low` ou `throttled`. Par exemple, la file d'attente `authorized_projects` est utilisée pour actualiser les autorisations des utilisateurs et a une urgence `high`.
- `worker_name` - le nom du worker. Utilisez cet attribut pour sélectionner un worker spécifique. Retrouvez tous les noms disponibles dans [les listes de classes de jobs](#list-of-available-job-classes) ci-dessous.
- `name` - le nom de la file d'attente généré à partir du nom du worker. Utilisez cet attribut pour sélectionner une file d'attente spécifique. Comme il est généré à partir du nom du worker, il ne change pas en fonction du résultat des autres règles de routage.
- `resource_boundary` - si la file d'attente est liée par `cpu`, `memory` ou `unknown`. Par exemple, le `ProjectExportWorker` est limité par la mémoire car il doit charger les données en mémoire avant de les enregistrer pour l'exportation.
- `tags` - annotations de courte durée pour les files d'attente. Celles-ci sont censées changer fréquemment d'une release à l'autre et peuvent être entièrement supprimées.
- `queue_namespace` - certains workers sont regroupés par un espace de nommage, et `name` est préfixé par `<queue_namespace>:`. Par exemple, pour un `name` de file d'attente de `cronjob:admin_email`, `queue_namespace` est `cronjob`. Utilisez cet attribut pour sélectionner un groupe de workers.

`has_external_dependencies` est un attribut booléen : seule la chaîne exacte `true` est considérée comme vraie, et tout le reste est considéré comme faux.

`tags` est un ensemble, ce qui signifie que `=` vérifie les ensembles intersectants et que `!=` vérifie les ensembles disjoints. Par exemple, `tags=a,b` sélectionne les files d'attente qui ont les tags `a`, `b` ou les deux. `tags!=a,b` sélectionne les files d'attente qui n'ont aucun de ces tags.

### Opérateurs disponibles {#available-operators}

Les règles de routage prennent en charge les opérateurs suivants, listés du plus élevé au plus bas niveau de priorité :

- `|` - l'opérateur logique `OR`. Par exemple, `query_a|query_b` (où `query_a` et `query_b` sont des requêtes composées des autres opérateurs ici) inclut les files d'attente correspondant à l'une ou l'autre requête.
- `&` - l'opérateur logique `AND`. Par exemple, `query_a&query_b` (où `query_a` et `query_b` sont des requêtes composées des autres opérateurs ici) inclut uniquement les files d'attente correspondant aux deux requêtes.
- `!=` - l'opérateur `NOT IN`. Par exemple, `feature_category!=issue_tracking` exclut toutes les files d'attente de la catégorie de fonctionnalité `issue_tracking`.
- `=` - l'opérateur `IN`. Par exemple, `resource_boundary=cpu` inclut toutes les files d'attente liées au CPU.
- `,` - l'opérateur de concaténation d'ensembles. Par exemple, `feature_category=continuous_integration,pages` inclut toutes les files d'attente de la catégorie `continuous_integration` ou de la catégorie `pages`. Cet exemple est également possible avec l'opérateur OR, mais permet une plus grande concision, tout en ayant une priorité inférieure.

La priorité des opérateurs pour cette syntaxe est fixe : il n'est pas possible de donner à `AND` une priorité supérieure à `OR`.

Comme avec la syntaxe standard de groupe de files d'attente documentée précédemment, un seul `*` comme groupe de files d'attente entier sélectionne toutes les files d'attente.

### Tester les règles de routage dans la console Rails {#test-routing-rules-in-the-rails-console}

Vous pouvez vérifier quels workers correspondent à une requête donnée en exécutant ce qui suit dans la [console Rails](../operations/rails_console.md) :

```ruby
matcher = Gitlab::SidekiqConfig::WorkerMatcher.new("feature_category=global_search")
Gitlab::SidekiqConfig.workers
  .select { |w| matcher.match?(w.to_yaml) }
  .map(&:klass)
```

Remplacez la chaîne de requête par n'importe quelle requête de correspondance de worker valide pour tester différentes règles de routage.

Voir la [liste des classes de jobs disponibles](#list-of-available-job-classes) pour trouver les paramètres de requête qui vous conviennent.

### Liste des classes de jobs disponibles {#list-of-available-job-classes}

Pour obtenir la liste des classes de jobs et des files d'attente Sidekiq existantes, consultez les fichiers suivants :

- [Files d'attente pour toutes les éditions GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
- [Files d'attente pour les éditions GitLab Enterprise uniquement](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)
