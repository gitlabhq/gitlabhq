---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Maintenance
description: Tâches de maintenance pour les dépôts Git.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab prend en charge et automatise les tâches de maintenance dans les dépôts Git afin de s'assurer qu'ils peuvent être servis de la manière la plus efficace possible. Les tâches de maintenance comprennent :

- La compression des objets et des révisions Git.
- La suppression des objets inaccessibles.
- La suppression des données obsolètes comme les fichiers verrou.
- La maintenance des structures de données qui améliorent les performances.
- La mise à jour des pools d'objets pour améliorer la déduplication des objets entre les duplications.

> [!warning]
> N'exécutez pas manuellement des commandes Git pour effectuer des opérations de maintenance dans des dépôts Git contrôlés par GitLab. Cela peut entraîner la corruption des dépôts et la perte de données.

## Stratégie de maintenance {#housekeeping-strategy}

Gitaly peut effectuer des tâches de maintenance dans un dépôt Git de deux façons :

- [La maintenance agressive](#eager-housekeeping) exécute des tâches de maintenance spécifiques indépendamment de l'état du dépôt.
- [La maintenance heuristique](#heuristical-housekeeping) exécute des tâches de maintenance sur la base d'un ensemble d'heuristiques qui déterminent les tâches de maintenance à exécuter en fonction de l'état du dépôt.

### Maintenance agressive {#eager-housekeeping}

La stratégie de maintenance « agressive » exécute des tâches de maintenance dans un dépôt indépendamment de l'état du dépôt. Il s'agit de la stratégie par défaut utilisée par le [déclencheur manuel](#manual-trigger) et le déclencheur basé sur les push.

La stratégie de maintenance agressive est contrôlée par l'application GitLab. En fonction du déclencheur qui a provoqué l'exécution du job de maintenance, GitLab demande à Gitaly d'effectuer des tâches de maintenance spécifiques. Gitaly effectue ces tâches même si le dépôt est dans un état optimisé. Par conséquent, cette stratégie peut s'avérer inefficace dans les grands dépôts où l'exécution des tâches de maintenance peut être lente.

### Maintenance heuristique {#heuristical-housekeeping}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitaly/-/issues/2634) dans GitLab 14.9 pour le [déclencheur manuel](#manual-trigger) et le déclencheur basé sur les push [avec un indicateur](feature_flags/_index.md) nommé `optimized_housekeeping`. Activé par défaut.
- [Activée sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/353607) dans GitLab 14.10.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661) dans GitLab 15.8. Indicateur de feature flag `optimized_housekeeping` supprimé.

{{< /history >}}

La stratégie de maintenance heuristique (ou « opportuniste ») analyse l'état du dépôt et exécute des tâches de maintenance uniquement lorsqu'elle détecte qu'une ou plusieurs structures de données sont insuffisamment optimisées. Il s'agit de la stratégie utilisée par la [maintenance planifiée](#scheduled-housekeeping).

La maintenance heuristique utilise les informations suivantes pour décider des tâches à exécuter :

- Le nombre d'objets isolés et obsolètes.
- Le nombre de fichiers pack contenant des objets déjà compressés.
- Le nombre de références isolées.
- La présence d'un commit-graph.

La décision de savoir si l'une des structures de données analysées doit être optimisée est basée sur la taille du dépôt :

- Les objets sont reconditionnés d'autant plus fréquemment que la taille totale de tous les objets est importante.
- Les références sont reconditionnées moins fréquemment au fur et à mesure que leur nombre total augmente.

Gitaly procède ainsi pour compenser le fait que l'optimisation de ces structures de données prend plus de temps à mesure qu'elles grossissent. Il est particulièrement important, dans les grands monodépôts (qui reçoivent beaucoup de trafic), d'éviter de les optimiser trop fréquemment.

Vous pouvez modifier la fréquence à laquelle Gitaly est invité à optimiser un dépôt.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Maintenance du dépôt**.
1. Dans la section **Maintenance**, configurez les options de maintenance.
1. Sélectionnez **Sauvegarder les modifications**.

- **Activer la maintenance automatique du dépôt** : Demander régulièrement à Gitaly d'exécuter l'optimisation du dépôt. Si vous désactivez ce paramètre pendant une longue période, l'accès au dépôt Git sur votre serveur GitLab deviendra plus lent et vos dépôts utiliseront plus d'espace disque.
- **Optimisez la période de dépôt** : Nombre de push Git après lesquels Gitaly est invité à optimiser un dépôt.

## Exécution des tâches de maintenance {#running-housekeeping-tasks}

GitLab dispose de différentes façons d'exécuter les tâches de maintenance :

- L'administrateur d'un projet peut [déclencher manuellement](#manual-trigger) des tâches de maintenance du dépôt.
- GitLab peut planifier automatiquement des tâches de maintenance après un certain nombre de push Git.
- GitLab peut [planifier un job](#scheduled-housekeeping) qui exécute des tâches de maintenance pour tous les dépôts dans un intervalle de temps configurable.

### Déclencheur manuel {#manual-trigger}

Les administrateurs de dépôts peuvent déclencher manuellement des tâches de maintenance dans un dépôt. En général, cela n'est pas nécessaire car GitLab sait exécuter automatiquement les tâches de maintenance. Le déclencheur manuel peut être utile dans les cas suivants :

- Un dépôt est réputé nécessiter une maintenance.
- La planification automatique des tâches de maintenance basée sur les push a été désactivée.

Pour déclencher manuellement des tâches de maintenance :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres avancés**.
1. Sélectionnez **Démarrer la maintenance**.

Cela démarre un worker de traitement en arrière-plan asynchrone pour le dépôt du projet. Le worker de traitement en arrière-plan demande à Gitaly d'effectuer un certain nombre d'optimisations.

La maintenance [supprime également les fichiers LFS non référencés](raketasks/cleanup.md#remove-unreferenced-lfs-files) de votre projet tous les `200` push, libérant ainsi de l'espace de stockage pour votre projet.

### Élaguer les objets inaccessibles {#prune-unreachable-objects}

Les objets inaccessibles sont élагués dans le cadre de la maintenance planifiée. Cependant, vous pouvez également déclencher un élagage manuel. Le déclenchement de la maintenance élague les objets inaccessibles avec une période de grâce de deux semaines. Lorsque vous déclenchez manuellement l'élagage des objets inaccessibles, la période de grâce est réduite à 30 minutes.

> [!warning]
> L'élagage des objets inaccessibles ne garantit pas la suppression des secrets divulgués et d'autres informations sensibles. Pour savoir comment supprimer des secrets qui ont été commités mais pas poussés, consultez le [tutoriel de suppression d'un secret dans vos commits](../user/application_security/secret_detection/remove_secrets_tutorial.md). De plus, vous pouvez [supprimer les blobs individuellement](../user/project/repository/repository_size.md#remove-blobs). Référez-vous à cette documentation pour connaître les éventuelles conséquences de cette opération.
>
> Si un processus concurrent (comme `git push`) a créé un objet mais n'a pas encore créé de référence à cet objet, votre dépôt peut être corrompu si une référence à l'objet est ajoutée après la suppression de l'objet. La période de grâce existe pour réduire la probabilité de telles conditions de concurrence. Par exemple, si vous poussez fréquemment de nombreux objets volumineux sur une connexion parfois très lente, le risque lié à l'élagage des objets inaccessibles est bien plus élevé que dans un environnement d'entreprise où le projet n'est accessible que depuis l'intérieur de l'entreprise avec une connexion performante. Tenez compte du profil d'utilisation du projet lorsque vous utilisez cette option et choisissez une période de faible activité.

Pour déclencher un élagage manuel des objets inaccessibles :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres avancés**.
1. Sélectionnez **Démarrer la maintenance**.
1. Attendez 30 minutes que l'opération se termine.
1. Revenez à la page où vous avez sélectionné **Démarrer la maintenance**, puis sélectionnez **Élaguer les objets inaccessibles**.

### Maintenance planifiée {#scheduled-housekeeping}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Bien que GitLab effectue automatiquement des tâches de maintenance en fonction du nombre de push, il ne maintient pas les dépôts qui ne reçoivent aucun push. Par conséquent, les dépôts dormants ou les dépôts qui ne reçoivent que des requêtes en lecture peuvent ne pas bénéficier des améliorations apportées à la stratégie de maintenance des dépôts.

Les administrateurs peuvent activer un job en arrière-plan qui effectue la maintenance de tous les dépôts à un intervalle personnalisable pour remédier à cette situation. Ce job en arrière-plan traite tous les dépôts hébergés par un nœud Gitaly dans un ordre aléatoire et effectue de manière agressive des tâches de maintenance sur eux. Le nœud Gitaly cesse de traiter les dépôts si cela prend plus longtemps que l'intervalle configuré.

#### Configurer la maintenance planifiée {#configure-scheduled-housekeeping}

La maintenance en arrière-plan des dépôts Git est configurée dans Gitaly. Par défaut, Gitaly effectue la maintenance des dépôts en arrière-plan tous les jours à 12h00 pour une durée de 10 minutes.

Vous pouvez modifier cette valeur par défaut dans la configuration de Gitaly.

Pour les environnements avec Gitaly Cluster (Praefect), l'heure de début de la maintenance planifiée peut être décalée entre les nœuds Gitaly afin que la maintenance planifiée ne s'exécute pas simultanément sur plusieurs nœuds.

Si une exécution de maintenance planifiée atteint la `duration` spécifiée, les tâches en cours sont annulées de manière progressive. Lors des exécutions suivantes de maintenance planifiée, Gitaly mélange aléatoirement la liste des dépôts à traiter.

L'extrait suivant active la maintenance quotidienne des dépôts en arrière-plan à partir de 23h00 pendant 1 heure pour le stockage `default` :

{{< tabs >}}

{{< tab title="Self-compiled (source)" >}}

```toml
[daily_maintenance]
start_hour = 23
start_minute = 00
duration = 1h
storages = ["default"]
```

Utilisez l'extrait suivant pour désactiver complètement la maintenance des dépôts en arrière-plan :

```toml
[daily_maintenance]
disabled = true
```

{{< /tab >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitaly['configuration'] = {
  daily_maintenance: {
    disabled: false,
    start_hour: 23,
    start_minute: 00,
    duration: '1h',
    storages: ['default'],
  },
}
```

Utilisez l'extrait suivant pour désactiver complètement la maintenance des dépôts en arrière-plan :

```ruby
gitaly['configuration'] = {
  daily_maintenance: {
    disabled: true,
  },
}
```

{{< /tab >}}

{{< /tabs >}}

Lorsque la maintenance planifiée est exécutée, vous pouvez voir les entrées suivantes dans votre [journal Gitaly](logs/_index.md#gitaly-logs) :

```json
# When the scheduled housekeeping starts
{"level":"info","msg":"maintenance: daily scheduled","pid":197260,"scheduled":"2023-09-27T13:10:00+13:00","time":"2023-09-27T00:08:31.624Z"}

# When the scheduled housekeeping completes
{"actual_duration":321181874818,"error":null,"level":"info","max_duration":"1h0m0s","msg":"maintenance: daily completed","pid":197260,"time":"2023-09-27T00:15:21.182Z"}
```

La valeur `actual_duration` (en nanosecondes) indique la durée d'exécution de la maintenance planifiée. Dans l'exemple précédent, la maintenance planifiée s'est terminée en un peu plus de 5 minutes.

## Dépôts de pools d'objets {#object-pool-repositories}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Les dépôts de pools d'objets sont utilisés par GitLab pour dédupliquer les objets entre les duplications d'un dépôt. Lors de la création de la première duplication, nous :

1. Créons un dépôt de pool d'objets contenant tous les objets du dépôt sur le point d'être dupliqué.
1. Associons le dépôt à ce nouveau pool d'objets en utilisant le mécanisme des alternates de Git.
1. Reconditionnons le dépôt afin qu'il utilise les objets du pool d'objets. Il peut ainsi abandonner sa propre copie des objets.

Toutes les duplications de ce dépôt peuvent désormais se lier au pool d'objets et n'ont donc à conserver que les objets qui divergent du dépôt principal.

GitLab doit effectuer des opérations de maintenance spéciales dans les pools d'objets :

- Gitaly ne peut jamais supprimer les objets inaccessibles des pools d'objets car ils pourraient être utilisés par l'une des duplications qui y sont connectées.
- Gitaly doit maintenir tous les objets accessibles pour la même raison. Les pools d'objets maintiennent donc des références aux objets inaccessibles « pendants » afin qu'ils ne soient jamais supprimés.
- GitLab doit mettre à jour les pools d'objets régulièrement pour intégrer les nouveaux objets qui ont été ajoutés dans le dépôt principal. Dans le cas contraire, un pool d'objets devient de moins en moins efficace pour dédupliquer les objets.

Ces opérations de maintenance sont effectuées par le RPC spécialisé `FetchIntoObjectPool` qui gère toutes ces tâches spéciales tout en exécutant les tâches de maintenance habituelles que nous exécutons pour les dépôts Git standard.

Les pools d'objets sont optimisés automatiquement chaque fois que le membre principal fait l'objet d'une collecte de mémoire (garbage collection). Par conséquent, la cadence peut être configurée en utilisant la même période de GC Git dans ce projet.

Si vous devez invoquer manuellement le RPC depuis une [console Rails](operations/rails_console.md), vous pouvez appeler `project.pool_repository.object_pool.fetch`. Il s'agit d'une tâche potentiellement longue, bien que Gitaly expire après environ 8 heures.
