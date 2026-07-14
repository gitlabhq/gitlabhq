---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Guide pour définir la taille de l'architecture de référence et les ajustements spécifiques aux composants."
title: "Évaluer la taille de l'architecture de référence"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour sélectionner une architecture de référence appropriée, vous devez adopter une approche systématique pour évaluer et dimensionner les environnements GitLab en fonction des architectures de référence.

Pour déterminer l'architecture de référence appropriée et les ajustements spécifiques aux composants requis, les informations suivantes vous aident à analyser :

- Les modèles de requêtes par seconde (RPS).
- Les caractéristiques de charge de travail.
- La saturation des ressources.

## Avant de commencer {#before-you-begin}

Vous pouvez utiliser ces informations si vous disposez d'un environnement complexe pour sélectionner une architecture de référence appropriée. Vous n'aurez peut-être pas besoin de ce niveau de détail et vous pouvez évaluer la taille de votre environnement en utilisant les [informations pour les environnements moins complexes](_index.md).

> [!note]
> Besoin de conseils d'experts ? Dimensionner correctement votre architecture est essentiel pour des performances optimales. Notre équipe [Professional Services](https://about.gitlab.com/professional-services/) peut évaluer votre architecture spécifique et fournir des recommandations personnalisées pour l'optimisation des performances, de la stabilité et de la disponibilité.

Pour suivre cette documentation, vous devez avoir déployé la surveillance Prometheus avec l'instance GitLab. Prometheus fournit les métriques précises nécessaires à une évaluation correcte du dimensionnement.

Si vous n'avez pas encore configuré Prometheus :

1. Configurez la surveillance avec [Prometheus](../monitoring/prometheus/_index.md). La documentation sur l'architecture de référence fournit des détails sur la configuration de Prometheus pour chaque taille d'environnement. Pour GitLab cloud-native, vous pouvez utiliser le chart Helm [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) pour configurer la collecte des métriques.
1. Collectez des données pendant 7 à 14 jours pour recueillir des modèles de données significatifs.
1. Lisez le reste de ces informations.

Si vous ne pouvez pas configurer la surveillance Prometheus :

- [Comparez les spécifications de l'environnement actuel](#analyze-current-environment-and-validate-recommendations) à l'architecture de référence la plus proche pour estimer le dimensionnement.
- Utilisez [GitLab RPS Analyzer](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/gitlab-rps-analyzer#gitlab-rps-analyzer) pour évaluer la taille de l'architecture de référence à l'aide des journaux GitLabSOS ou KubeSOS. Notez cependant que cette méthode est moins fiable que les métriques.

Si vous effectuez une migration depuis d'autres plateformes, les requêtes PromQL suivantes ne peuvent pas être appliquées sans les métriques GitLab existantes. Cependant, la méthodologie générale d'évaluation reste valide :

1. Estimez l'architecture de référence la plus proche en fonction de la charge de travail attendue.
1. Identifiez les [charges de travail supplémentaires](_index.md#additional-workloads) anticipées.
1. Évaluez le nombre de grands dépôts
1. Intégrez les projections de croissance.
1. Sélectionnez une architecture de référence avec une [marge appropriée](_index.md#if-in-doubt-start-large-monitor-and-then-scale-down).

### Exécution des requêtes PromQL {#running-promql-queries}

L'exécution des requêtes PromQL dépend de la solution de surveillance que vous utilisez. Comme indiqué dans la [documentation sur la surveillance Prometheus](../monitoring/prometheus/_index.md#how-prometheus-works), les données de surveillance sont accessibles soit en se connectant directement à Prometheus, soit en utilisant un outil de tableau de bord comme Grafana.

## Déterminer votre taille de référence {#determine-your-baseline-size}

Les requêtes par seconde (RPS) constituent la métrique principale pour dimensionner l'infrastructure GitLab. Différents types de trafic (API, Web, opérations Git) sollicitent différents composants, chacun est donc analysé séparément pour déterminer les véritables besoins en capacité.

### Extraire les métriques de trafic de pointe {#extract-peak-traffic-metrics}

Exécutez ces requêtes pour comprendre votre charge maximale. Ces requêtes vous montrent :

- Les pics absolus, qui correspondent au pic le plus élevé observé. Les pics absolus représentent les scénarios les plus défavorables.
- Les pics soutenus, qui correspondent au 95e percentile et sont considérés comme votre niveau « chargé » typique. Les pics soutenus révèlent les périodes de charge élevée typiques.

Si les pics absolus sont de rares anomalies, un dimensionnement pour la charge soutenue peut être approprié.

Ajustez les plages de temps dans les requêtes en fonction de la rétention (remplacez `[7d]` par `[30d]` si un historique plus long est disponible).

> [!note]
> Pour les environnements à forte activité, les requêtes `max_over_time` ou `quantile_over_time` peuvent expirer. Si cela se produit, supprimez la fonction d'agrégation externe et visualisez la requête interne avec un graphique. Par exemple, pour le pic de trafic API, utilisez :
>
> ```prometheus
> sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))
> ```
>
> Identifiez ensuite visuellement les valeurs de pic à partir des résultats représentés graphiquement sur votre période de surveillance.

#### Interroger les pics absolus {#query-absolute-peaks}

Pour identifier le RPS maximum observé sur la période de temps spécifiée :

1. Exécutez ces requêtes :

   - Pic de trafic API, pour mesurer les requêtes API de pointe provenant de l'automatisation, des outils externes et des webhooks :

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - Pic de trafic Web, pour mesurer les interactions d'interface utilisateur de pointe des utilisateurs dans les navigateurs :

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Pic de pull et de clonage Git, pour mesurer les opérations de clonage et de récupération de dépôt de pointe :

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Pic de push Git, pour mesurer les opérations de push de code de pointe :

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. Enregistrez les résultats.

#### Interroger les pics soutenus {#query-sustained-peaks}

Pour identifier les niveaux de charge élevée typiques en filtrant les pics rares :

1. Exécutez ces requêtes :

   - Pic soutenu API :

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - Pic soutenu Web :

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Pic soutenu de pull et de clonage Git :

     ```prometheus
     quantile_over_time(0.95,
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Pic soutenu de push Git :

     ```prometheus
     quantile_over_time(0.95,
      (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
      sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. Enregistrez les résultats.

### Mapper le trafic aux architectures de référence {#map-traffic-to-reference-architectures}

Pour mapper le trafic aux architectures de référence, en utilisant les résultats que vous avez enregistrés précédemment :

1. Consultez les [architectures de référence disponibles](_index.md#available-reference-architectures) pour voir quelle architecture de référence chaque type de trafic suggère.
1. Remplissez un tableau d'analyse. Utilisez le tableau suivant comme guide :

   | Type de trafic       | RPS de pointe | AR suggérée pour le pic     | RPS soutenu | AR suggérée pour le soutenu |
   |:-------------------|:---------|:----------------------|:--------------|:-----------------------|
   | API                | \________ | \_\_\_\_\_ (jusqu'à \_\__ RPS) | \_____________ | \_\_\_\_\_ (jusqu'à \_\_\__ RPS) |
   | Web                | \________ | \_\_\_\_\_ (jusqu'à \_\__ RPS) | \_____________ | \_\_\_\_\_ (jusqu'à \_\_\__ RPS) |
   | Pull et clonage Git | \________ | \_\_\_\_\_ (jusqu'à \_\__ RPS) | \_____________ | \_\_\_\_\_ (jusqu'à \_\_\__ RPS) |
   | Push Git           | \________ | \_\_\_\_\_ (jusqu'à \_\__ RPS) | \_____________ | \_\_\_\_\_ (jusqu'à \_\_\__ RPS) |

1. Comparez toutes les architectures de référence dans la colonne **Peak Suggested RA** et sélectionnez la taille la plus grande. Répétez l'opération pour la colonne **Sustained Suggested RA**.
1. Documentez la référence :
   - AR de pic la plus grande suggérée.
   - AR soutenue la plus grande suggérée.

### Choisir une architecture de référence {#choose-a-reference-architecture}

À ce stade, il existe deux tailles candidates d'architecture de référence :

- Une basée sur les pics absolus.
- Une basée sur la charge soutenue.

Pour choisir une architecture de référence :

1. Si le pic et le soutenu suggèrent la même AR, utilisez cette AR.
1. Si le pic suggère une AR plus grande que le soutenu. Calculez l'écart. Le RPS de pointe est-il dans une fourchette de 10 à 15 % de la limite supérieure de l'AR soutenue ?

Directives générales :

- Si le RPS de pointe dépasse la limite de l'AR soutenue de moins de 10 à 15 %, l'AR soutenue peut être envisagée avec un risque acceptable car les architectures de référence disposent d'une marge intégrée.
- Au-delà de 15 %, commencez avec l'AR basée sur le pic, puis surveillez et ajustez si les métriques permettent une réduction de taille.
  - Exemple 1 :  Le pic est de 110 RPS, l'AR Large gère « jusqu'à 100 RPS » → 10 % au-dessus → Large devrait suffire (les architectures de référence ont une marge intégrée)
  - Exemple 2 :  Le pic est de 150 RPS, l'AR Large gère « jusqu'à 100 RPS » → 50 % au-dessus → Utilisez X-Large (jusqu'à 200 RPS)
  - Exemple 3 :  Le pic est de 100 RPS (Large/100 RPS) mais le soutenu est de 50 RPS (Medium/60 RPS). Les graphiques RPS bruts montrent que les pics d'automatisation causent des pointes tandis que la charge est inférieure à 50 RPS la plupart du temps. L'utilisateur évalue s'il faut commencer de manière conservatrice avec Large puis réduire la taille, ou commencer avec Medium avec une [mise à l'échelle spécifique à la charge de travail](#identify-component-adjustments) (risque plus élevé).

Pour les environnements inférieurs à 40 RPS et où la haute disponibilité (HA) est une exigence, consultez la [section haute disponibilité](_index.md#high-availability-ha) pour déterminer si le passage à l'architecture 60 RPS / 3 000 utilisateurs avec des réductions prises en charge est nécessaire.

### Avant de continuer {#before-you-proceed}

Ayant terminé cette section, vous avez établi votre taille d'architecture de référence de base. Cela constitue la fondation, mais les sections suivantes déterminent si une charge de travail spécifique nécessite des ajustements de composants au-delà de la configuration standard.

Avant de continuer, assurez-vous d'avoir documenté les détails que vous avez recueillis dans cette section. Vous pouvez utiliser ce qui suit comme guide :

```markdown
Reference architecture assessment summary:

- Selected reference architecture: _____
- Justification based on _____ RPS [absolute/sustained]

| Traffic Type       | Peak RPS | Sustained RPS (95th) |
|:-------------------|:---------|:---------------------|
| API                | ________ | ____________________ |
| Web                | ________ | ____________________ |
| Git pull and clone | ________ | ____________________ |
| Git push           | ________ | ____________________ |

Highest RPS Peak timestamp for workload analysis: _____
```

## Comprendre la composition RPS et les modèles de charge de travail {#understanding-rps-composition-and-workload-patterns}

Le RPS total est la métrique principale de dimensionnement, mais la composition de la charge de travail a un impact significatif sur les besoins en ressources des composants. Différents types de requêtes sollicitent différents composants avec des intensités variables.

### Répartition du RPS par type de requête {#rps-breakdown-by-request-type}

Les cibles RPS de l'architecture de référence supposent une composition de charge de travail typique basée sur des données de production :

- **API requests** (~80 % du RPS total) - Automatisation, intégrations, webhooks et outils pilotés par API
- **Web requests** (~10 % du RPS total) - Interactions d'interface utilisateur, navigation dans les pages et actions pilotées par l'utilisateur
- **Git operations** (~10 % du RPS total) - Clonages et pulls de dépôt, avec des taux de push plus faibles

**Atypical compositions** \- Environnements où un type de requête dépasse significativement les proportions typiques (peuvent nécessiter des ajustements spécifiques aux composants même dans les plages RPS cibles)

### Identification des modèles de charge de travail atypiques {#identifying-atypical-workload-patterns}

Utilisez les requêtes d'extraction RPS de la section [Extraire les métriques de trafic de pointe](#extract-peak-traffic-metrics) pour comprendre la composition de votre charge de travail. Comparez votre distribution aux modèles typiques :

**API-heavy workloads** (API > 90 % du RPS total) :

- Forte automatisation, intégrations étendues ou outillage piloté par API
- Impact principal :  Rails (Webservice), PostgreSQL, Gitaly
- À envisager :  Capacité Webservice/Rails accrue, réplicas en lecture de la base de données

**Web-heavy workloads** (Web > 20 % du RPS total) :

- Large base d'utilisateurs actifs avec une interaction intensive de l'interface utilisateur
- Impact principal :  Rails (Webservice), PostgreSQL
- À envisager :  Capacité Webservice accrue, optimisation de la base de données

**Git-intensive workloads** (Git > 15 % du RPS total ou taux de pull nettement supérieurs à la normale pour votre taille) :

- Grandes équipes avec des pulls fréquents, des modèles de monodépôt ou des workflows intensifs CI/CD avec des clonages de dépôt
- Impact principal :  Gitaly, bande passante réseau
- À envisager :  Mise à l'échelle verticale de Gitaly, optimisation du dépôt, machines virtuelles améliorées pour le réseau

### Approche d'évaluation {#assessment-approach}

1. Extraire la répartition RPS à l'aide des requêtes PromQL fournies
1. Calculer le pourcentage du total pour chaque type de requête
1. Identifier si un type dépasse significativement les proportions typiques
1. Si atypique, consultez [Identifier les ajustements de composants](#identify-component-adjustments) pour obtenir des conseils de mise à l'échelle

> [!note]
> Les petites variations (différence de 5 à 10 RPS dans n'importe quelle catégorie) ne nécessitent pas de modifications d'architecture. Surveillez les métriques de saturation réelles des composants (CPU, mémoire, profondeurs de file d'attente) en production plutôt que de prendre des décisions basées uniquement sur des comparaisons RPS. Les composants présentant une utilisation soutenue inférieure à 70 % disposent généralement d'une capacité suffisante, quelles que soient les variations mineures du RPS.

## Identifier les ajustements de composants {#identify-component-adjustments}

L'évaluation de la charge de travail identifie des modèles d'utilisation spécifiques qui nécessitent des ajustements de composants au-delà de l'architecture de référence de base. Alors que le RPS détermine la taille globale, les modèles de charge de travail déterminent la forme. Deux environnements avec un RPS identique peuvent avoir des besoins en ressources très différents.

Différentes charges de travail sollicitent différentes parties de l'architecture GitLab :

- Les environnements intensifs CI/CD traitant des milliers de jobs tout en maintenant un RPS modéré sollicitent Sidekiq et Gitaly.
- Les environnements avec une automatisation API étendue présentant un RPS élevé mais concentrant la charge sur les couches de base de données et Rails.

### Analyser les principaux points de terminaison pendant la charge de pointe {#analyze-top-endpoints-during-peak-load}

En utilisant l'horodatage de pointe de la section précédente, identifiez quels points de terminaison ont reçu le plus de trafic pendant la charge maximale.

> [!note]
> Si vos métriques RPS montrent un trafic constamment élevé pendant les heures creuses (> 50 % du pic), cela suggère une automatisation intensive au-delà des modèles typiques. Par exemple, un trafic de pointe atteignant 100 RPS pendant les heures de bureau mais maintenant 50+ RPS pendant les nuits et les week-ends indique une charge de travail automatisée significative. Tenez-en compte lors de l'[évaluation des ajustements de composants](#determine-component-adjustments).

1. Exécutez cette requête avec la visualisation activée (diagramme à barres pour la distribution dans le temps, ou diagramme circulaire pour la distribution générale) :

   ```prometheus
   topk(20,
     sum by (controller, action) (
       rate(gitlab_transaction_duration_seconds_count{controller!~"HealthController|MetricsController", action!~".*/internal/.*"}[1m])
     )
   )
   ```

1. Examinez les résultats pour la distribution des principaux points de terminaison pendant le pic RPS absolu. Les résultats peuvent présenter :

   - Aucun modèle de point de terminaison visible. Dans ce cas, continuez avec l'architecture de référence sélectionnée précédemment. Assurez-vous qu'une surveillance robuste est en place pour mesurer l'impact de tout changement de charge de travail.
   - Une majorité d'utilisation intensive de l'API pour le trafic non-Git. Dans ce cas, les webhooks et les appels API de tickets, de groupes et de projets indiquent un modèle intensif en base de données.
   - Une majorité de points de terminaison liés à Git ou à Sidekiq. Dans ce cas, les diffs de merge request, les jobs de pipeline, les branches, les commits, les opérations sur les fichiers, les jobs CI/CD, l'analyse de sécurité et les opérations d'importation indiquent un modèle intensif Sidekiq/Gitaly.

1. Enregistrez les résultats :

   ```markdown
   Workload pattern identified:

   - [ ] Database-intensive
   - [ ] Sidekiq- or Gitaly-intensive
   - [ ] None detected
   ```

### Déterminer les ajustements de composants {#determine-component-adjustments}

Les indicateurs ci-dessus fournissent des signaux initiaux de charges de travail supplémentaires. En raison de la marge intégrée dans les architectures de référence, ces charges de travail peuvent être gérées sans ajustements. Cependant, si des indicateurs forts existent et que des niveaux élevés d'automatisation sont connus, envisagez les ajustements suivants.

En fonction du modèle de charge de travail identifié précédemment, différents composants nécessitent une mise à l'échelle :

| Type de charge de travail              | Quand appliquer                                                                                                                                                                                | Composants à mettre à l'échelle |
|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------|
| Intensif en base de données         | <ul><li>Utilisation intensive de l'API pour le trafic non-Git (webhooks, tickets, groupes et projets)</li><li>[Charges de travail d'automatisation ou d'intégration étendues](_index.md#additional-workloads) connues</li></ul> | <ul><li>Augmenter les ressources Rails</li><li>[Mise à l'échelle de la base de données](#database-scaling)</li></ul> |
| Intensif Sidekiq/Gitaly\** | <ul><li>Opérations Git intensives, jobs CI/CD, analyse de sécurité, opérations d'importation et hooks de serveur Git</li><li>Modèles d'utilisation intensifs CI/CD connus</li></ul>                                      | <ul><li>Augmenter les spécifications Sidekiq</li><li>Mise à l'échelle verticale de Gitaly</li><li>[Mise à l'échelle de la base de données](#database-scaling)</li><li>Avancé :  Configurer des [classes de job](../sidekiq/processing_specific_job_classes.md) spécifiques</li></ul> |

#### Conseils de mise à l'échelle {#scaling-guidance}

Les ajustements de ressources varient en fonction de l'intensité de la charge de travail et des métriques de saturation :

1. Commencez par 1,25x à 1,5x les ressources actuelles.
1. Affinez en fonction des données de surveillance après la mise en œuvre.

Si vous prévoyez de déployer GitLab cloud-native, les modèles de charge de travail identifiés dans cette évaluation ont des implications supplémentaires pour la configuration Kubernetes :

- Trafic élevé pendant les heures creuses. Assurez-vous que le nombre minimum de pods est suffisant pour la charge de base plutôt que de permettre une mise à l'échelle à zéro pendant les périodes calmes. Par exemple, avec 100 RPS pendant les heures de bureau et un RPS constant de 50 la nuit causé par l'automatisation, la configuration du nombre minimum de pods doit être alignée avec la charge de base pendant les heures creuses.
- Pics de trafic rapides. Les paramètres HPA par défaut peuvent ne pas être suffisamment rapides pour la mise à l'échelle. Surveillez le comportement de mise à l'échelle des pods lors du déploiement initial pour éviter la mise en file d'attente des requêtes pendant ces transitions. Par exemple, un pic rapide de 50 à 200 RPS causé par une montée en charge des heures calmes aux heures de travail ou un pic d'automatisation spécifique.

##### Mise à l'échelle de la base de données {#database-scaling}

La stratégie de mise à l'échelle de la base de données dépend des caractéristiques de la charge de travail et peut nécessiter plusieurs approches :

1. Mise à l'échelle verticale pour répondre aux contraintes de capacité immédiates, qui :
   - Est requise pour les charges de travail à forte écriture car les réplicas ne réduisent pas la charge principale.
   - Fournit une augmentation immédiate de la capacité pour les opérations de lecture et d'écriture.
1. [Équilibrage de charge de la base de données](../postgresql/database_load_balancing.md) (recommandé) avec des réplicas en lecture, qui :
   - Est particulièrement bénéfique pour les charges de travail à forte lecture (85 à 95 % de lectures).
   - Distribue le trafic de lecture sur plusieurs nœuds.
   - Peut être ajouté en combinaison avec la mise à l'échelle verticale.
1. Continuez la mise à l'échelle verticale si les performances en écriture restent un goulot d'étranglement.

Utilisez cette requête Prometheus pour identifier la distribution lecture/écriture :

```prometheus
# Percentage of READ operations
(
  (sum(rate(gitlab_transaction_db_count_total[5m])) - sum(rate(gitlab_transaction_db_write_count_total[5m]))) /
  sum(rate(gitlab_transaction_db_count_total[5m]))
) * 100
```

### Avant de continuer {#before-you-proceed-1}

Ayant terminé cette section, vous avez identifié les modèles de charge de travail et déterminé les ajustements de composants requis.

Avant de continuer, enregistrez l'évaluation complète de la charge de travail :

```markdown
Workload pattern identified:

- [ ] Database-intensive
- [ ] Sidekiq- or Gitaly-intensive
- [ ] None detected
- Component adjustments needed: _____
```

Dans la section suivante, vous évaluez les caractéristiques de données spéciales qui pourraient nécessiter des considérations d'infrastructure supplémentaires.

## Évaluer les exigences d'infrastructure spéciales {#assess-special-infrastructure-requirements}

Les caractéristiques des dépôts et les modèles d'utilisation du réseau peuvent avoir un impact significatif sur les performances de GitLab au-delà de ce que les métriques RPS révèlent.

Les grands monodépôts, les fichiers binaires étendus et les opérations intensives en réseau nécessitent des ajustements d'infrastructure que le dimensionnement standard ne prend pas en compte.

### Grands monodépôts {#large-monorepos}

Les grands monodépôts (plusieurs gigaoctets ou plus) changent fondamentalement la façon dont les opérations Git s'exécutent. Un seul clonage d'un dépôt de 10 Go consomme plus de ressources que des centaines de clonages de dépôts typiques.

Ces dépôts affectent non seulement Gitaly, mais aussi Rails, Sidekiq et la base de données selon la charge de travail.

Le processus de profilage se concentre sur l'identification des dépôts qui dépassent significativement les tailles typiques :

- Monodépôts moyens :  2 Go - 10 Go. Ces dépôts nécessitent des ajustements modestes.
- Grands monodépôts : > 10 Go. Ces dépôts nécessitent des modifications d'infrastructure importantes.

Pour identifier la taille d'un dépôt :

1. Accédez aux [quotas d'utilisation](../../user/storage_usage_quotas.md#view-storage) d'un projet.
1. Examinez le [type de stockage **Dépôt**](../../user/project/repository/repository_size.md).
1. Calculez le nombre de projets avec des dépôts de plus de 2 Go et de plus de 10 Go.
1. Enregistrez les résultats :

   ```plaintext
   Number of medium monorepos (2GB - 10GB): _____
   Number of large monorepos (>10GB): _____
   ```

#### Ajustements d'infrastructure pour les monodépôts {#infrastructure-adjustments-for-monorepos}

Les grands dépôts nécessitent à la fois une mise à l'échelle verticale et des ajustements opérationnels. Ces dépôts affectent les performances sur l'ensemble de la pile, des opérations Git et de l'utilisation du CPU à la consommation de mémoire et à la bande passante réseau.

| Scénario                 | Ajustements de composants |
|:-------------------------|:----------------------|
| Plusieurs monodépôts moyens | <ul><li>Gitaly :  Spécifications 1,5x à 2x</li><li>Rails :  Spécifications 1,25x à 1,5x</li></ul> |
| Grands monodépôts          | <ul><li>Gitaly :  Spécifications 2x à 4x</li><li>Rails :  Spécifications 1,5x à 2x</li><li>Envisagez de fragmenter le monodépôt vers un nœud Gitaly dédié</li></ul> |

Des stratégies d'optimisation supplémentaires pour les environnements de monodépôt sont documentées dans [Améliorer les performances des monodépôts](../../user/project/repository/monorepos/_index.md), notamment Git LFS pour les fichiers binaires et le clonage superficiel.

### Charges de travail intensives en réseau {#network-heavy-workloads}

La saturation du réseau cause des problèmes uniques qui sont souvent difficiles à diagnostiquer. Contrairement aux goulots d'étranglement CPU ou mémoire qui affectent des opérations spécifiques, la saturation du réseau peut provoquer des délais d'expiration apparemment aléatoires dans toutes les fonctions GitLab.

Sources courantes de charge réseau :

- Utilisation intensive du registre de conteneurs (grandes images, pulls fréquents).
- Opérations LFS (fichiers binaires, ressources médias).
- Grands artefacts CI/CD (sorties de build, résultats de tests).
- Clonages de monodépôts (en particulier dans les pipelines CI/CD).

#### Mesurer l'utilisation du réseau {#measure-network-usage}

Calculez la consommation réseau de pointe et de base pour identifier les goulots d'étranglement potentiels. Évaluez les deux pour distinguer les pics occasionnels (gérés par la capacité en rafale) du trafic soutenu élevé (nécessitant des machines virtuelles améliorées pour le réseau).

1. Exécutez les requêtes suivantes :

   ```prometheus
   # Outbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))


   # Inbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))

   ```

1. Enregistrez les pics de pointe et la base de référence typique observés sur votre période de surveillance :

   ```plaintext
   Peak outbound traffic: _____ Gbps (baseline: _____ Gbps)
   Peak inbound traffic: _____ Gbps (baseline: _____ Gbps)
   ```

#### Exigences de capacité réseau {#network-capacity-requirements}

Les seuils ci-dessous sont des directives approximatives uniquement. Les garanties de bande passante réseau réelles varient considérablement selon le fournisseur de cloud et le type de machine virtuelle. Vérifiez toujours les spécifications réseau (limites de base et en rafale) pour vos types d'instances spécifiques afin de vous assurer qu'elles s'alignent avec vos modèles de charge de travail.

En fonction des mesures de trafic sortant et entrant :

| Charge réseau | Seuil | Pourquoi ce seuil                                                 | Action requise |
|:-------------|:----------|:-------------------------------------------------------------------|:----------------|
| Standard     | < 1 Gbps   | Dans la bande passante de base de la plupart des instances standard               | Instances standard suffisantes |
| Modéré     | 1-3 Gbps  | Peut dépasser la base AWS mais dans les instances standard GCP/Azure    | <ul><li>AWS :  Surveiller la limitation, peut nécessiter une amélioration réseau</li><li>GCP/Azure :  Instances standard généralement suffisantes</li></ul> |
| Élevé         | 3-10 Gbps | Dépasse la base AWS. Approche les limites de certaines instances standard | <ul><li>AWS :  Machines virtuelles améliorées pour le réseau requises</li><li>GCP/Azure :  Vérifier les spécifications de bande passante de l'instance</li></ul> |
| Très élevé    | > 10 Gbps  | Dépasse les capacités de la plupart des instances standard                        | <ul><li>Machines virtuelles améliorées pour le réseau requises chez tous les fournisseurs</li><li>Pour les grands artefacts, désactivez le [téléchargement via proxy d'objet](../object_storage.md#proxy-download)</li></ul> |

### Avant de continuer {#before-you-proceed-2}

Avant de continuer, enregistrez l'évaluation complète du profilage des données :

```txt
Data Profile Summary:
- Medium monorepos (2GB-10GB): _____
- Large monorepos (>10GB): _____
- Gitaly adjustments needed: _____
- Rails adjustments needed: _____
- Peak outbound traffic: _____ Gbps (sustained baseline: _____ Gbps)
- Peak inbound traffic: _____ Gbps (sustained baseline: _____ Gbps)
- Network infrastructure changes: _____
```

## Analyser l'environnement actuel et valider les recommandations {#analyze-current-environment-and-validate-recommendations}

Comprendre l'environnement existant fournit un contexte crucial pour les recommandations :

- Si l'environnement actuel gère la charge de travail sans problèmes de performances, il sert de validation précieuse pour les estimations de dimensionnement.
- À l'inverse, les environnements présentant des problèmes de performances nécessitent une analyse approfondie pour éviter de perpétuer un sous-dimensionnement.

### Documenter l'environnement actuel {#document-the-current-environment}

Collectez des données d'environnement complètes pour établir l'état actuel :

- Détails de l'architecture :
  - Type : haute disponibilité (HA) ou sans haute disponibilité (non-HA).
  - Méthode de déploiement :  Package Linux ou GitLab cloud-native.
- Spécifications des composants :
  - Nombre de nœuds et spécifications pour chaque composant.
  - Configurations personnalisées ou déviations.

### Identifier l'architecture de référence la plus proche {#identify-the-nearest-reference-architecture}

1. Comparez l'environnement actuel aux [architectures de référence disponibles](_index.md). Tenez compte de ce qui suit :

   - Ressources de calcul totales par composant.
   - Distribution des nœuds et modèle d'architecture (HA vs non-HA).
   - Spécifications des composants par rapport aux tailles d'architecture de référence.

1. Enregistrez vos résultats :

   ```plaintext
   Nearest Reference Architecture: _____
   Custom configurations or deviations:
   - _____
   - _____
   ```

### Comparer l'environnement actuel à l'architecture recommandée {#compare-current-environment-to-recommended-architecture}

Comparez l'environnement actuel à l'architecture de référence recommandée que vous avez développée à partir des sections précédentes. Si l'environnement actuel :

- N'a pas de problèmes de performances et les ressources actuelles < AR recommandée :
  - Les recommandations sont conservatrices et offrent une marge pour l'avenir.
  - Procédez avec l'AR recommandée.
  - Surveillez après la mise en œuvre pour détecter les opportunités d'optimisation potentielles.
- N'a pas de problèmes de performances et les ressources actuelles ≈ AR recommandée :
  - Validation solide de votre évaluation de dimensionnement.
  - L'environnement actuel confirme que la taille recommandée est appropriée.
- N'a pas de problèmes de performances et les ressources actuelles > AR recommandée :
  - L'environnement actuel pourrait être sur-provisionné ou avoir des raisons valides pour des ressources supplémentaires qui doivent être analysées. Vérifiez l'[utilisation des ressources](../monitoring/prometheus/_index.md#sample-prometheus-queries) CPU/mémoire sur Rails, Gitaly, la base de données et Sidekiq.

    Une faible utilisation (< 40 %) suggère un sur-provisionnement. Une utilisation élevée peut indiquer des exigences de charge de travail spécifiques non capturées dans l'analyse RPS.
  - Vérifiez si les recommandations doivent être ajustées pour des exigences non découvertes.

Si l'environnement actuel présente des problèmes de performances :

- Utilisez les spécifications actuelles uniquement comme référence minimale. Les recommandations des sections précédentes devraient dépasser les spécifications actuelles.
- Si les recommandations sont significativement inférieures aux spécifications actuelles, examinez :
  - Les modèles de charge de travail non capturés dans l'évaluation.
  - Les goulots d'étranglement spécifiques aux composants nécessitant une mise à l'échelle ciblée.

### Avant de continuer {#before-you-proceed-3}

Ayant terminé cette section, vous avez analysé l'environnement actuel et comparé avec les recommandations.

Avant de continuer, enregistrez la comparaison complète de l'environnement :

```plaintext
Current Environment Analysis:
- Current RA (nearest): _____
- Recommended RA (from RPS and workload analysis): _____
- Resource comparison: [ ] Current < Recommended [ ] Current ≈ Recommended [ ] Current > Recommended
- Performance status: [ ] No issues [ ] Has issues
- Adjustments needed: _____
- Notes: _____
```

Dans la section suivante, vous évaluez les projections de croissance pour vous assurer que le dimensionnement reste approprié dans le temps.

## Planifier la capacité future {#plan-for-future-capacity}

Les modifications d'infrastructure nécessitent un délai important pour l'approvisionnement, la migration et les tests. L'estimation de la croissance garantit que l'architecture recommandée reste viable tout au long de la période de mise en œuvre et au-delà.

Les tendances historiques combinées aux plans d'affaires fournissent les projections de croissance les plus précises.

### Analyser les modèles de croissance historiques {#analyze-historical-growth-patterns}

Les modèles de croissance passés peuvent aider à prédire la trajectoire future mieux que les projections d'affaires :

1. Comparez le RPS actuel à celui d'il y a 6 à 12 mois en utilisant les informations dans [votre taille de référence](#determine-your-baseline-size).
1. Identifiez les tendances d'accélération ou de décélération de la croissance.

### Intégrer les facteurs de planification commerciale {#incorporate-business-planning-factors}

Changements d'affaires attendus qui ont un impact sur les besoins en infrastructure :

- Expansion ou consolidation des équipes.
- Nouveaux développements de projets.
- Activité de développement accrue sur les projets existants.

Évaluez si l'un de ces facteurs (ou d'autres changements organisationnels) pourrait affecter la charge sur l'environnement et nécessiter des ajustements d'infrastructure. Documentez les changements pertinents et leur calendrier prévu.

#### Déterminer la stratégie de tampon de croissance {#determine-growth-buffer-strategy}

En fonction des tendances historiques et des projections d'affaires, sélectionnez la stratégie d'adaptation à la croissance appropriée :

- Croissance stable ou minimale :  Continuez la surveillance. Les architectures de référence incluent une marge intégrée.
- Croissance modérée :  Planifiez une AR dimensionnée pour gérer le RPS futur projeté.
- Croissance significative anticipée :  Envisagez un dimensionnement pour le RPS futur projeté plutôt que le RPS actuel.

### Avant de continuer {#before-you-proceed-4}

Ayant terminé cette section, les projections de croissance sont intégrées dans la décision de dimensionnement.

Enregistrez l'analyse complète de la croissance :

```plaintext
Growth Assessment Summary:
- Historical RPS comparison: _____
- Business growth factors: _____
- Growth category: [ ] Stable/Minimal [ ] Moderate [ ] Significant
- Strategy: [ ] Current RA sufficient [ ] Size for projected growth
```

Dans la section suivante, vous compilez tous les résultats en recommandations finales d'architecture.

## Compiler les résultats {#compile-findings}

Compilez les résultats de toutes les sections précédentes pour déterminer l'architecture de référence optimale et les ajustements requis.

### Déterminer l'architecture finale {#determine-final-architecture}

Rassemblez les résultats clés de chaque section pour former la décision de dimensionnement :

1. Commencez par l'architecture de référence identifiée sur la base de l'[analyse RPS](#determine-your-baseline-size).
1. Appliquez les ajustements de composants nécessaires en fonction des [modèles de charge de travail](#identify-component-adjustments) et des [caractéristiques des données](#assess-special-infrastructure-requirements). Ignorez cette étape si aucun modèle n'est identifié ou si la configuration standard est suffisante.
1. Validez par rapport à l'[état actuel](#analyze-current-environment-and-validate-recommendations). Si l'environnement actuel fonctionne bien mais dépasse les recommandations, documentez les raisons. S'il présente des problèmes de performances, assurez-vous que les recommandations dépassent les spécifications actuelles.
1. Tenez compte de la [croissance dans votre plan de capacité future](#plan-for-future-capacity). Déterminez si l'AR actuelle est suffisante ou si un dimensionnement pour la croissance projetée est nécessaire.

### Documenter la recommandation finale {#document-final-recommendation}

Sur la base de l'évaluation complète, enregistrez la recommandation d'architecture complète :

```plaintext
Final Architecture Recommendation
==================================

- Selected RA: [Size] based on [Absolute/Sustained] Peak RPS of [value]
- Component adjustments required:
  - [ ] No adjustments needed - standard RA configuration sufficient
  - [ ] Adjustments required:
      - Rails: _____
      - Sidekiq: _____
      - Database: _____
      - Gitaly: _____
      - Network considerations: □ Standard instances □ Network-optimized instances
- Selected RA is aligned with existing environment: [Yes/No/Not applicable]
- Growth accommodation: [Current RA sufficient / Sized up for growth]

Assessment Summary:
├── RPS Analysis
│   ├── Absolute Peak RPS: _____ → Baseline RA: _____
│   └── Sustained Peak RPS: _____ → Sustained RA: _____
├── Workload Type
│   └── Type: [ ] Database-Intensive [ ] Sidekiq-Intensive [ ] None
├── Data Profile
│   ├── Large repos (>2GB): _____ | Monorepos (>10GB): _____
│   └── Network: Peak _____ Gbps | Baseline _____ Gbps
├── Current State
│   ├── Nearest RA: _____
|   └── Discrepancies and customizations: _____
└── Growth
    ├── Growth projection: _____
    └── Growth buffer strategy: _____
```

Ayant complété toutes les sections, l'évaluation du dimensionnement est terminée. La recommandation finale comprend :

- La taille de l'architecture de référence de base.
- Ajustements spécifiques aux composants
- Stratégie d'adaptation à la croissance.

La surveillance régulière reste essentielle pour valider les hypothèses et ajuster l'infrastructure à mesure que les modèles de charge de travail évoluent.
