---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limitation de la simultanéité
---

Pour éviter de surcharger les serveurs exécutant Gitaly, vous pouvez limiter la simultanéité des éléments suivants :

- RPC.
- Objets pack.

Ces limites peuvent être fixes ou définies de manière adaptative.

> [!warning]
> L'activation de limites sur votre environnement doit être effectuée avec prudence et uniquement dans certaines circonstances, par exemple pour se protéger contre un trafic inattendu. Lorsqu'elles sont atteintes, les limites entraînent des déconnexions qui ont un impact négatif sur les utilisateurs. Pour des performances cohérentes et stables, vous devez d'abord explorer d'autres options, telles que l'ajustement des spécifications des nœuds et [la révision des grands dépôts](../../user/project/repository/monorepos/_index.md) ou des charges de travail.

## Limiter la simultanéité des RPC {#limit-rpc-concurrency}

Lors du clonage ou du tirage de dépôts, divers RPC s'exécutent en arrière-plan. En particulier, les RPC Git pack :

- `SSHUploadPackWithSidechannel` (pour Git SSH).
- `PostUploadPackWithSidechannel` (pour Git HTTP).

Ces RPC peuvent consommer une grande quantité de ressources, ce qui peut avoir un impact significatif dans des situations telles que :

- Trafic anormalement élevé.
- Exécution contre des [grands dépôts](../../user/project/repository/monorepos/_index.md) qui ne suivent pas les meilleures pratiques.

Vous pouvez empêcher ces processus de surcharger votre serveur Gitaly dans ces scénarios en utilisant les limites de simultanéité dans le fichier de configuration Gitaly. Par exemple :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
      {
         rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
   ],
}
```

- `rpc` est le nom du RPC pour lequel définir une limite de simultanéité par dépôt.
- `max_per_repo` est le nombre maximum d'appels RPC en cours pour le RPC donné par dépôt.
- `max_queue_wait` est la durée maximale pendant laquelle une requête peut attendre dans la file d'attente de simultanéité avant d'être prise en charge par Gitaly.
- `max_queue_size` est la taille maximale que la file d'attente de simultanéité (par méthode RPC) peut atteindre avant que les requêtes ne soient rejetées par Gitaly.

Cela limite le nombre d'appels RPC en cours pour les RPC donnés. La limite est appliquée par dépôt. Dans l'exemple précédent :

- Chaque dépôt servi par le serveur Gitaly peut avoir au maximum 20 appels RPC `PostUploadPackWithSidechannel` et `SSHUploadPackWithSidechannel` simultanés en cours.
- Si une autre requête arrive pour un dépôt qui a épuisé ses 20 emplacements, cette requête est mise en file d'attente.
- Si une requête attend dans la file d'attente pendant plus d'1 seconde, elle est rejetée avec une erreur.
- Si la file d'attente dépasse 10, les requêtes suivantes sont rejetées avec une erreur.

> [!note]
> Lorsque ces limites sont atteintes, les utilisateurs sont déconnectés.

Vous pouvez observer le comportement de cette file d'attente à l'aide des journaux Gitaly et de Prometheus. Pour plus d'informations, consultez la [documentation correspondante](monitoring.md#monitor-gitaly-concurrency-limiting).

### Limites séparées pour les requêtes non authentifiées {#separate-limits-for-unauthenticated-requests}

{{< history >}}

- Introduit dans GitLab 18.7 [avec un flag](../../operations/feature_flags.md) nommé `gitaly_limit_unauthenticated`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible pour les tests, mais n'est pas prête pour une utilisation en production.

Par défaut, les limites de simultanéité RPC s'appliquent à toutes les requêtes, quel que soit le statut d'authentification. Cependant, vous pouvez configurer des limites séparées et plus restrictives pour les requêtes non authentifiées afin de protéger votre serveur Gitaly contre les abus potentiels ou l'épuisement des ressources provenant du trafic anonyme.

Lorsque vous configurez le champ `unauthenticated` pour un RPC, Gitaly utilise des limiteurs séparés :

- **Authenticated requests** utilisent les limites de simultanéité principales (configurées au niveau supérieur de la configuration RPC).
- **Requêtes non authentifiées** utilisent les limites spécifiées dans le champ `unauthenticated`.

Cette séparation vous permet de :

- Appliquer des limites plus strictes au trafic non authentifié tout en maintenant un débit plus élevé pour les utilisateurs authentifiés.
- Se protéger contre les scénarios de déni de service provenant de clonages ou de tirages anonymes.
- Garantir que les utilisateurs authentifiés ont un accès prioritaire aux ressources Gitaly.

Si vous ne configurez pas le champ `unauthenticated`, toutes les requêtes (authentifiées et non authentifiées) partagent les mêmes limites de simultanéité.

#### Quand utiliser des limites non authentifiées séparées {#when-to-use-separate-unauthenticated-limits}

Envisagez de configurer des limites non authentifiées séparées lorsque :

- Votre instance GitLab autorise l'accès public aux dépôts et connaît un trafic anonyme élevé.
- Vous souhaitez prioriser les utilisateurs authentifiés pendant les périodes de forte charge.
- Vous devez vous protéger contre les abus potentiels provenant de sources non authentifiées.
- Vous observez une contention de ressources entre les requêtes authentifiées et non authentifiées.

#### Configurer des limites statiques pour les requêtes non authentifiées {#configure-static-limits-for-unauthenticated-requests}

L'exemple suivant montre comment configurer des limites statiques séparées pour les requêtes authentifiées et non authentifiées :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         # Limits for authenticated requests
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
         # Separate limits for unauthenticated requests
         unauthenticated: {
            max_per_repo: 5,
            max_queue_wait: '500ms',
            max_queue_size: 5,
         },
      },
   ],
}
```

Dans cet exemple :

- Les requêtes authentifiées peuvent avoir jusqu'à 20 opérations simultanées par dépôt.
- Les requêtes non authentifiées sont limitées à 5 opérations simultanées par dépôt.
- Les requêtes non authentifiées ont un temps d'attente en file d'attente plus court (500ms contre 1s) et une file d'attente plus petite (5 contre 10).

#### Configurer des limites adaptatives pour les requêtes non authentifiées {#configure-adaptive-limits-for-unauthenticated-requests}

Le champ `unauthenticated` prend en charge à la fois les limites de simultanéité statiques et adaptatives, tout comme la configuration principale. Vous pouvez configurer des limites adaptatives pour les requêtes non authentifiées :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         # Adaptive limits for authenticated requests
         adaptive: true,
         min_limit: 10,
         initial_limit: 20,
         max_limit: 40,
         max_queue_wait: '1s',
         max_queue_size: 10,
         # Adaptive limits for unauthenticated requests
         unauthenticated: {
            adaptive: true,
            min_limit: 2,
            initial_limit: 5,
            max_limit: 10,
            max_queue_wait: '500ms',
            max_queue_size: 5,
         },
      },
   ],
}
```

Cette configuration permet aux limites authentifiées et non authentifiées de s'adapter indépendamment en fonction de l'utilisation des ressources système, tout en maintenant la séparation entre les deux types de trafic.

## Limiter la simultanéité des pack-objects {#limit-pack-objects-concurrency}

Gitaly déclenche des processus `git-pack-objects` lors de la gestion du trafic SSH et HTTPS pour cloner ou tirer des dépôts. Ces processus génèrent un `pack-file` et peuvent consommer une quantité significative de ressources, en particulier dans des situations telles qu'un trafic anormalement élevé ou des tirages simultanés depuis un grand dépôt. Sur GitLab.com, nous observons également des problèmes avec des clients disposant de connexions Internet lentes.

Vous pouvez empêcher ces processus de surcharger votre serveur Gitaly en définissant des limites de simultanéité pack-objects dans le fichier de configuration Gitaly. Ce paramètre limite le nombre de processus pack-object en cours par adresse IP distante.

> [!warning]
> N'activez ces limites sur votre environnement qu'avec prudence et uniquement dans certaines circonstances, par exemple pour vous protéger contre un trafic inattendu. Lorsqu'elles sont atteintes, ces limites déconnectent les utilisateurs. Pour des performances cohérentes et stables, vous devez d'abord explorer d'autres options, telles que l'ajustement des spécifications des nœuds et [la révision des grands dépôts](../../user/project/repository/monorepos/_index.md) ou des charges de travail.

Exemple de configuration :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_concurrency' => 15,
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
}
```

- `max_concurrency` est le nombre maximum de processus pack-object en cours par clé.
- `max_queue_length` est la taille maximale que la file d'attente de simultanéité (par clé) peut atteindre avant que les requêtes ne soient rejetées par Gitaly.
- `max_queue_wait` est la durée maximale pendant laquelle une requête peut attendre dans la file d'attente de simultanéité avant d'être prise en charge par Gitaly.

Dans l'exemple précédent :

- Chaque IP distante peut avoir au maximum 15 processus pack-object simultanés en cours sur un nœud Gitaly.
- Si une autre requête arrive d'une IP qui a épuisé ses 15 emplacements, cette requête est mise en file d'attente.
- Si une requête attend dans la file d'attente pendant plus d'1 minute, elle est rejetée avec une erreur.
- Si la file d'attente dépasse 200, les requêtes suivantes sont rejetées avec une erreur.

Lorsque le cache pack-object est activé, la limitation des pack-objects n'intervient que si le cache est manqué. Pour plus d'informations, consultez [Cache pack-objects](configure_gitaly.md#pack-objects-cache).

Vous pouvez observer le comportement de cette file d'attente à l'aide des journaux Gitaly et de Prometheus. Pour plus d'informations, consultez [Surveiller la limitation de la simultanéité des pack-objects Gitaly](monitoring.md#monitor-gitaly-pack-objects-concurrency-limiting).

## Étalonnage des limites de simultanéité {#calibrating-concurrency-limits}

Lors de la définition des limites de simultanéité, vous devez choisir des valeurs appropriées en fonction de vos modèles de charge de travail spécifiques. Cette section fournit des conseils sur la façon d'étalonner ces limites efficacement.

### Utilisation des métriques Prometheus et des journaux pour l'étalonnage {#using-prometheus-metrics-and-logs-for-calibration}

Les métriques Prometheus fournissent des informations quantitatives sur les modèles d'utilisation et l'impact de chaque type de RPC sur les ressources des nœuds Gitaly. Plusieurs métriques clés sont particulièrement utiles pour cette analyse :

- Métriques de consommation des ressources par RPC. Gitaly délègue la plupart des opérations lourdes aux processus `git` ; la commande généralement appelée est donc le binaire Git. Gitaly expose les métriques collectées à partir de ces commandes sous forme de journaux et de métriques Prometheus.
  - `gitaly_command_cpu_seconds_total` - Somme du temps CPU passé par délégation, avec des labels pour `grpc_service`, `grpc_method`, `cmd` et `subcmd`.
  - `gitaly_command_real_seconds_total` - Somme du temps réel passé par délégation, avec des labels similaires.
- Métriques de limitation récentes par RPC :
  - `gitaly_concurrency_limiting_in_progress` - Nombre de requêtes simultanées en cours de traitement.
  - `gitaly_concurrency_limiting_queued` - Nombre de requêtes pour un RPC d'un dépôt donné en état d'attente.
  - `gitaly_concurrency_limiting_acquiring_seconds` - Durée pendant laquelle une requête attend en raison des limites de simultanéité avant le traitement.

Ces métriques fournissent une vue d'ensemble de l'utilisation des ressources à un moment donné. La métrique `gitaly_command_cpu_seconds_total` est particulièrement efficace pour identifier les RPC spécifiques qui consomment des ressources CPU importantes. Des métriques supplémentaires sont disponibles pour une analyse plus détaillée, comme décrit dans [Surveillance de Gitaly](monitoring.md).

Bien que les métriques capturent les modèles globaux d'utilisation des ressources, elles ne fournissent généralement pas de ventilations par dépôt. Par conséquent, les journaux servent de source de données complémentaire. Pour analyser les journaux :

1. Filtrez les journaux par RPC à fort impact identifiés.
1. Agrégez les journaux filtrés par dépôt ou projet.
1. Visualisez les résultats agrégés sur un graphique de séries chronologiques.

Cette approche combinée utilisant à la fois les métriques et les journaux offre une visibilité complète sur l'utilisation des ressources à l'échelle du système et les modèles spécifiques aux dépôts. Des outils d'analyse tels que Kibana ou des plateformes similaires d'agrégation de journaux peuvent faciliter ce processus.

### Ajustement des limites {#adjusting-limits}

Si vous constatez que vos limites initiales ne sont pas suffisamment efficaces, vous devrez peut-être les ajuster. Avec la limitation adaptative, les limites précises sont moins critiques car le système s'ajuste automatiquement en fonction de l'utilisation des ressources.

N'oubliez pas que les limites de simultanéité sont délimitées par dépôt. Une limite de 30 signifie autoriser au maximum 30 requêtes en cours simultanées par dépôt. Si la limite est atteinte, les requêtes sont mises en file d'attente et ne sont rejetées que si la file d'attente est pleine ou si le temps d'attente maximum est atteint.

## Limitation adaptative de la simultanéité {#adaptive-concurrency-limiting}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/10734) dans GitLab 16.6.

{{< /history >}}

Gitaly prend en charge deux limites de simultanéité :

- Une [limite de simultanéité RPC](#limit-rpc-concurrency), qui vous permet de configurer un nombre maximum de requêtes en cours simultanées pour chaque RPC Gitaly. La limite est délimitée par RPC et par dépôt.
- Une [limite de simultanéité Pack-objects](#limit-pack-objects-concurrency), qui restreint le nombre de requêtes simultanées de transfert de données Git par IP.

Si cette limite est dépassée, soit :

- La requête est mise en file d'attente.
- La requête est rejetée si la file d'attente est pleine ou si la requête reste dans la file d'attente trop longtemps.

Ces deux limites de simultanéité peuvent être configurées de manière statique. Bien que les limites statiques puissent produire de bons résultats de protection, elles présentent certains inconvénients :

- Les limites statiques ne conviennent pas à tous les modèles d'utilisation. Il n'existe pas de valeur universelle. Si la limite est trop basse, les grands dépôts sont impactés négativement. Si la limite est trop élevée, la protection est essentiellement perdue.
- Il est fastidieux de maintenir une valeur raisonnable pour la limite de simultanéité, surtout lorsque la charge de travail de chaque dépôt évolue dans le temps.
- Une requête peut être rejetée même si le serveur est inactif car le taux ne tient pas compte de la charge sur le serveur.

Vous pouvez surmonter tous ces inconvénients et conserver les avantages de la limitation de simultanéité en configurant des limites de simultanéité adaptatives. Les limites de simultanéité adaptatives sont optionnelles et s'appuient sur les deux types de limitation de simultanéité. Il utilise l'algorithme d'augmentation additive/diminution multiplicative (AIMD). Chaque limite adaptative :

- Augmente progressivement jusqu'à une certaine limite supérieure pendant le fonctionnement normal du processus.
- Diminue rapidement lorsque la machine hôte rencontre un problème de ressources.

Ce mécanisme offre une certaine marge de manœuvre à la machine pour « respirer » et accélère les requêtes en cours.

![Graphique montrant une limite de simultanéité adaptative Gitaly ajustée en fonction de l'utilisation des ressources système en suivant l'algorithme AIMD](img/gitaly_adaptive_concurrency_limit_v16_6.png)

Le limiteur adaptatif étalonne les limites toutes les 30 secondes et :

- Augmente les limites d'un jusqu'à atteindre la limite supérieure.
- Diminue les limites de moitié lorsque le cgroup de niveau supérieur présente soit une utilisation de la mémoire dépassant 90 %, à l'exclusion des caches de pages hautement évictables, soit une limitation du CPU pendant 50 % ou plus du temps d'observation.

Sinon, les limites augmentent d'un jusqu'à atteindre la limite supérieure.

La limitation adaptative est activée individuellement pour chaque RPC ou cache pack-objects. Cependant, les limites sont étalonnées en même temps. La limitation adaptative dispose des configurations suivantes :

- `adaptive` définit si l'adaptativité est activée.
- `max_limit` est la limite de simultanéité maximale. Gitaly augmente la limite actuelle jusqu'à atteindre ce nombre. Il doit s'agir d'une valeur généreuse que le système peut pleinement prendre en charge dans des conditions normales.
- `min_limit` est la limite de simultanéité minimale du RPC configuré. Lorsque la machine hôte rencontre un problème de ressources, Gitaly réduit rapidement la limite jusqu'à atteindre cette valeur. Définir `min_limit` à 0 pourrait complètement arrêter le traitement, ce qui est généralement indésirable.
- `initial_limit` fournit un point de départ raisonnable entre ces extrêmes.

### Activer l'adaptativité pour la simultanéité RPC {#enable-adaptiveness-for-rpc-concurrency}

Prérequis :

- Étant donné que la limitation adaptative dépend des [groupes de contrôle](configure_gitaly.md#control-groups), les groupes de contrôle doivent être activés avant d'utiliser la limitation adaptative.

Voici un exemple de configuration d'une limite adaptative pour la simultanéité RPC :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
    # ...
    cgroups: {
        # Minimum required configuration to enable cgroups support.
        repositories: {
            count: 1
        },
    },
    concurrency: [
        {
            rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
            max_queue_wait: '1s',
            max_queue_size: 10,
            adaptive: true,
            min_limit: 10,
            initial_limit: 20,
            max_limit: 40
        },
        {
            rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
            max_queue_wait: '10s',
            max_queue_size: 20,
            adaptive: true,
            min_limit: 10,
            initial_limit: 50,
            max_limit: 100
        },
   ],
}
```

Pour plus d'informations, consultez [Simultanéité RPC](#limit-rpc-concurrency).

### Activer l'adaptativité pour la simultanéité pack-objects {#enable-adaptiveness-for-pack-objects-concurrency}

Prérequis :

- Étant donné que la limitation adaptative dépend des [groupes de contrôle](configure_gitaly.md#control-groups), les groupes de contrôle doivent être activés avant d'utiliser la limitation adaptative.

Voici un exemple de configuration d'une limite adaptative pour la simultanéité pack-objects :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
   'adaptive' => true,
   'min_limit' => 10,
   'initial_limit' => 20,
   'max_limit' => 40
}
```

Pour plus d'informations, consultez [Simultanéité pack-objects](#limit-pack-objects-concurrency).

### Étalonnage des limites de simultanéité adaptatives {#calibrating-adaptive-concurrency-limits}

La limitation adaptative de la simultanéité est très différente de la façon habituelle dont GitLab protège les ressources Gitaly. Plutôt que de s'appuyer sur des seuils statiques qui peuvent être soit trop restrictifs, soit trop permissifs, la limitation adaptative répond intelligemment aux conditions réelles des ressources en temps réel.

Cette approche élimine la nécessité de trouver des valeurs de seuil « parfaites » par un étalonnage approfondi, comme décrit dans [Étalonnage des limites de simultanéité](#calibrating-concurrency-limits). Lors de scénarios d'échec, le limiteur adaptatif réduit les limites de manière exponentielle (par exemple, 60 → 30 → 15 → 10), puis se rétablit automatiquement en augmentant progressivement les limites lorsque le système se stabilise.

Lors de l'étalonnage des limites adaptatives, vous pouvez prioriser la flexibilité sur la précision.

#### Catégories RPC et exemples de configuration {#rpc-categories-and-configuration-examples}

Les RPC Gitaly coûteux, qui doivent être protégés, peuvent être classés en deux types généraux :

- Opérations de données Git pures.
- RPC sensibles au temps.

Chaque type présente des caractéristiques distinctes qui influencent la façon dont les limites de simultanéité doivent être configurées. Les exemples suivants illustrent le raisonnement derrière la configuration des limites. Ils peuvent également être utilisés comme point de départ.

##### Opérations de données Git pures {#pure-git-data-operations}

Ces RPC impliquent des opérations Git pull, push et fetch, et possèdent les caractéristiques suivantes :

- Processus de longue durée.
- Utilisation significative des ressources.
- Coûteux en calcul.
- Non sensibles au temps. Une latence supplémentaire est généralement acceptable.

Les RPC dans `SmartHTTPService` et `SSHService` appartiennent à la catégorie des opérations de données Git pures. Un exemple de configuration :

```ruby
{
  rpc: "/gitaly.SmartHTTPService/PostUploadPackWithSidechannel", # or `/gitaly.SmartHTTPService/SSHUploadPackWithSidechannel`
  adaptive: true,
  min_limit: 10,  # Minimum concurrency to maintain even under extreme load
  initial_limit: 40,  # Starting concurrency when service initializes
  max_limit: 60,  # Maximum concurrency under ideal conditions
  max_queue_wait: "60s",
  max_queue_size: 300
}
```

##### RPC sensibles au temps {#time-sensitive-rpcs}

Ces RPC servent GitLab lui-même et d'autres clients avec des caractéristiques différentes :

- Généralement partie de requêtes HTTP en ligne ou de jobs Sidekiq en arrière-plan.
- Profils de latence plus courts.
- Généralement moins gourmands en ressources.

Pour ces RPC, la configuration du délai d'expiration dans GitLab doit informer le paramètre `max_queue_wait`. Par exemple, `get_tree_entries` a généralement un délai d'expiration moyen de 30 secondes dans GitLab :

```ruby
{
  rpc: "/gitaly.CommitService/GetTreeEntries",
  adaptive: true,
  min_limit: 5,  # Minimum throughput maintained under resource pressure
  initial_limit: 10,  # Initial concurrency setting
  max_limit: 20,  # Maximum concurrency under optimal conditions
  max_queue_size: 50,
  max_queue_wait: "30s"
}
```

### Surveillance de la limitation adaptative {#monitoring-adaptive-limiting}

Pour observer le comportement des limites adaptatives dans les environnements de production, consultez les outils de surveillance et les métriques décrits dans [Surveiller la limitation adaptative de la simultanéité Gitaly](monitoring.md#monitor-gitaly-adaptive-concurrency-limiting). L'observation du comportement des limites adaptatives permet de confirmer que les limites répondent correctement aux pressions des ressources et s'ajustent comme prévu.
