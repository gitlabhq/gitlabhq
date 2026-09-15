---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Obtenez des informations sur les performances DevOps et identifiez les opportunités d'amélioration des workflows."
title: Métriques DevOps Research and Assessment (DORA)
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les métriques [DevOps Research and Assessment (DORA)](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance) fournissent des informations basées sur des données probantes concernant vos performances DevOps. Ces quatre mesures clés démontrent la rapidité avec laquelle votre équipe livre des changements et la façon dont ces changements se comportent en production. Lorsqu'elles sont suivies de manière cohérente, les métriques DORA mettent en évidence les opportunités d'amélioration tout au long de votre processus de livraison logicielle.

Utilisez les métriques DORA pour la prise de décisions stratégiques, pour justifier les investissements dans l'amélioration des processus auprès des parties prenantes, ou pour comparer les performances de votre équipe aux références du secteur afin d'identifier des avantages concurrentiels.

Les quatre métriques DORA mesurent deux aspects critiques du DevOps :

- **Velocity metrics** suivent la rapidité avec laquelle votre organisation livre des logiciels :
  - [Fréquence de déploiement](#deployment-frequency) : la fréquence à laquelle le code est déployé en production
  - [Délai d'exécution des changements](#lead-time-for-changes) : le temps qu'il faut au code pour atteindre la production
- **Stability metrics** mesurent la fiabilité de votre logiciel :
  - [Taux d'échec des changements](#change-failure-rate) : la fréquence à laquelle les déploiements causent des défaillances en production
  - [Délai de restauration du service](#time-to-restore-service) : la rapidité avec laquelle le service se rétablit après des défaillances

La double attention portée aux métriques de vélocité et de stabilité aide les responsables à trouver l'équilibre optimal entre rapidité et qualité dans leurs workflows de livraison.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une explication vidéo, voir [Métriques DORA : analyse des utilisateurs](https://www.youtube.com/watch?v=jYQSH4EY6_U) et [GitLab speed run : métriques DORA](https://www.youtube.com/watch?v=1BrcMV6rCDw).

## Fréquence de déploiement {#deployment-frequency}

La fréquence de déploiement correspond à la fréquence des déploiements réussis en production sur la plage de dates donnée (toutes les heures, quotidiennement, hebdomadairement, mensuellement ou annuellement).

Les responsables logiciels peuvent utiliser la métrique de fréquence de déploiement pour comprendre à quelle fréquence l'équipe déploie avec succès des logiciels en production, et à quelle vitesse les équipes peuvent répondre aux demandes des clients ou aux nouvelles opportunités de marché. Une fréquence de déploiement élevée signifie que vous pouvez obtenir des retours plus tôt et itérer plus rapidement pour livrer des améliorations et des fonctionnalités.

### Calcul de la fréquence de déploiement {#how-deployment-frequency-is-calculated}

Dans GitLab, la fréquence de déploiement est mesurée par le nombre moyen de déploiements par jour dans un environnement donné, en fonction de l'heure de fin du déploiement (sa propriété `finished_at`). GitLab calcule la fréquence de déploiement à partir du nombre de déploiements terminés au cours du jour donné. Seuls les déploiements réussis (`Deployment.statuses = success`) sont comptabilisés.

Le calcul prend en compte le `environment tier` de production ou les environnements nommés `production/prod`. L'environnement doit faire partie du niveau de déploiement de production pour que ses informations de déploiement apparaissent dans les graphiques.

Vous pouvez configurer les métriques DORA pour différents environnements en spécifiant `other` sous le paramètre `environment_tiers` dans le [fichier `.gitlab/insights.yml`](../project/insights/_index.md#configuration).

> [!note]
> La fréquence de déploiement est calculée comme la **moyenne (arithmétique)**, contrairement aux autres métriques DORA qui utilisent la médiane, celle-ci étant préférée car elle offre une vue plus précise et fiable des performances. Cette différence s'explique par le fait que la fréquence de déploiement a été ajoutée à GitLab avant l'adoption du cadre DORA, et que le calcul de cette métrique est resté inchangé lors de son intégration dans d'autres rapports. [Le ticket 499591](https://gitlab.com/gitlab-org/gitlab/-/issues/499591) propose d'offrir la possibilité de personnaliser la méthode de calcul pour chaque métrique, en choisissant entre la moyenne et la médiane.

### Comment améliorer la fréquence de déploiement {#how-to-improve-deployment-frequency}

La première étape consiste à évaluer la cadence des releases de code entre les groupes et les projets. Ensuite, vous devriez envisager :

- L'ajout de tests automatisés
- L'ajout de la validation automatisée du code
- La décomposition des changements en itérations plus petites

## Délai d'exécution des changements {#lead-time-for-changes}

Le délai d'exécution des changements correspond au temps nécessaire à un changement de code pour atteindre la production.

**Délai d'exécution des changements** n'est pas identique à **Durée d'exécution**. Dans l'analyse des flux de valeur, la durée d'exécution mesure le temps nécessaire pour qu'un travail sur un ticket passe du moment où il est demandé (ticket créé) au moment où il est accompli et livré (ticket fermé).

Pour les responsables logiciels, le délai d'exécution des changements reflète l'efficacité des pipelines CI/CD et visualise la rapidité avec laquelle le travail est livré aux clients. Au fil du temps, le délai d'exécution des changements devrait diminuer, tandis que les performances de votre équipe devraient augmenter. Un faible délai d'exécution des changements signifie des pipelines CI/CD plus efficaces.

### Calcul du délai d'exécution des changements {#how-lead-time-for-changes-is-calculated}

GitLab calcule le délai d'exécution des changements en fonction du nombre de secondes nécessaires pour livrer avec succès une merge request en production : depuis le moment de fusion de la merge request (lorsque le bouton de fusion est cliqué) jusqu'à l'exécution réussie du code en production, sans ajouter `coding_time` au calcul. Les données sont agrégées juste après la fin du déploiement, avec un léger délai.

Par défaut, le délai d'exécution des changements prend en charge la mesure d'une seule opération de branche avec plusieurs jobs de déploiement (par exemple, du développement à la mise en staging puis à la production sur la branche par défaut). Lorsqu'une merge request est fusionnée sur staging, puis sur production, GitLab les interprète comme deux merge requests déployées, et non une seule.

#### Déploiements se terminant avant la fusion {#deployments-finishing-before-merge}

Dans de rares cas, un déploiement peut se terminer avant que la merge request associée ne soit fusionnée.

Ce scénario peut se produire lorsque :

- Les processus de déploiement sont déclenchés indépendamment du workflow de fusion.
- Des interventions manuelles de déploiement se produisent avant la fin de la revue de code.

Dans cette situation, GitLab utilise la formule : `GREATEST(0, deployment_finished_at - merge_request_merged_at)`. La fonction `GREATEST` garantit que les valeurs de délai d'exécution ne sont jamais négatives, en renvoyant `0` au lieu d'une valeur négative. Cette fonction empêche les violations de contraintes de base de données tout en maintenant l'intégrité des données.

### Comment améliorer le délai d'exécution des changements {#how-to-improve-lead-time-for-changes}

La première étape consiste à évaluer l'efficacité des pipelines CI/CD entre les groupes et les projets. Ensuite, vous devriez envisager :

- L'utilisation de Value Stream Analytics pour identifier les goulots d'étranglement dans les processus
- La décomposition des changements en itérations plus petites
- L'ajout de l'automatisation
- L'amélioration des performances de vos pipelines

## Délai de restauration du service {#time-to-restore-service}

Le délai de restauration du service correspond au temps qu'il faut à une organisation pour se remettre d'une défaillance en production.

Pour les responsables logiciels, le délai de restauration du service reflète le temps qu'il faut à une organisation pour se remettre d'une défaillance en production. Un faible délai de restauration du service signifie que l'organisation peut prendre des risques avec de nouvelles fonctionnalités innovantes pour renforcer ses avantages concurrentiels et améliorer ses résultats commerciaux.

### Calcul du délai de restauration du service {#how-time-to-restore-service-is-calculated}

Dans GitLab, le délai de restauration du service est mesuré comme la durée médiane pendant laquelle un incident a été ouvert dans un environnement de production. GitLab calcule le nombre de secondes pendant lesquelles un incident a été ouvert dans un environnement de production au cours de la période donnée. Cela suppose que :

- Les [incidents GitLab](../../operations/incident_management/incidents.md) sont suivis.
- Tous les incidents sont liés à un environnement de production.
- Les incidents et les déploiements ont une relation strictement de un à un. Un incident est lié à un seul déploiement en production, et tout déploiement en production est lié à au plus un incident.

### Comment améliorer le délai de restauration du service {#how-to-improve-time-to-restore-service}

La première étape consiste à évaluer la réponse de l'équipe et le rétablissement après des interruptions et des pannes de service, entre les groupes et les projets. Ensuite, vous devriez envisager :

- L'amélioration de l'observabilité de l'environnement de production
- L'amélioration des workflows de réponse
- L'amélioration de la fréquence de déploiement et du délai d'exécution des changements afin que les correctifs puissent atteindre la production plus efficacement

## Taux d'échec des changements {#change-failure-rate}

Le taux d'échec des changements correspond à la fréquence à laquelle un changement provoque une défaillance en production.

Les responsables logiciels peuvent utiliser la métrique de taux d'échec des changements pour obtenir des informations sur la qualité du code livré. Un taux d'échec des changements élevé peut indiquer un processus de déploiement inefficace ou une couverture insuffisante des tests automatisés.

### Calcul du taux d'échec des changements {#how-change-failure-rate-is-calculated}

Dans GitLab, le taux d'échec des changements est mesuré comme le pourcentage de déploiements qui causent un incident en production au cours d'une période donnée. GitLab calcule le taux d'échec des changements comme le nombre d'incidents divisé par le nombre de déploiements dans un environnement de production. Ce calcul suppose que :

- Les [incidents GitLab](../../operations/incident_management/incidents.md) sont suivis.
- Tous les incidents sont des incidents de production, quel que soit l'environnement.
- Le taux d'échec des changements est principalement utilisé comme suivi de stabilité de haut niveau, c'est pourquoi, au cours d'un jour donné, tous les incidents et déploiements sont agrégés en un taux journalier combiné. L'ajout de relations spécifiques entre les déploiements et les incidents est proposé dans [le ticket 444295](https://gitlab.com/gitlab-org/gitlab/-/issues/444295).
- Le taux d'échec des changements calcule les incidents en double comme des entrées séparées, ce qui entraîne un double comptage. [Le ticket 480920](https://gitlab.com/gitlab-org/gitlab/-/issues/480920) propose une solution pour un calcul plus précis.

Par exemple, si vous avez 10 déploiements (en considérant un déploiement par jour) avec deux incidents le premier jour et un incident le dernier jour, votre taux d'échec des changements est de 0,3.

### Comment améliorer le taux d'échec des changements {#how-to-improve-change-failure-rate}

La première étape consiste à évaluer la qualité et la stabilité, entre les groupes et les projets. Ensuite, vous devriez envisager :

- Trouver le bon équilibre entre la stabilité et le débit (fréquence de déploiement et délai d'exécution des changements), sans sacrifier la qualité pour la rapidité
- L'amélioration de l'efficacité des processus de revue de code
- L'ajout de tests automatisés

## Règles de calcul personnalisées DORA {#dora-custom-calculation-rules}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561) dans GitLab 15.4 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `dora_configuration`. Désactivées par défaut. Cette fonctionnalité est une [version expérimentale](../../policy/development_stages_support.md).

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Cette fonctionnalité est une [version expérimentale](../../policy/development_stages_support.md). Pour rejoindre la liste des utilisateurs testant cette fonctionnalité, [voici un flux de test suggéré](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561#steps-to-check-on-localhost). Si vous trouvez un bug, [ouvrez un ticket ici](https://gitlab.com/groups/gitlab-org/-/epics/11490). Pour partager vos cas d'utilisation et vos commentaires, commentez dans [l'epic 11490](https://gitlab.com/groups/gitlab-org/-/epics/11490).

### Règle multi-branches pour le délai d'exécution des changements {#multi-branch-rule-for-lead-time-for-changes}

Contrairement au [calcul par défaut du délai d'exécution des changements](#how-lead-time-for-changes-is-calculated), cette règle de calcul permet de mesurer des opérations multi-branches avec un seul job de déploiement pour chaque opération. Par exemple, depuis le job de développement sur la branche de développement, vers le job de staging sur la branche de staging, jusqu'au job de production sur la branche de production.

Cette règle de calcul a été implémentée en mettant à jour la table `dora_configurations` avec les branches cibles qui font partie du flux de développement. Ainsi, GitLab peut reconnaître les branches comme une seule et filtrer les autres merge requests.

Cette configuration modifie la façon dont les métriques DORA quotidiennes sont calculées pour le projet sélectionné, mais n'affecte pas les autres projets, groupes ou utilisateurs.

Cette fonctionnalité prend en charge uniquement la propagation au niveau du projet.

Pour ce faire, exécutez la commande suivante dans la console Rails :

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
Dora::Configuration.create!(project: my_project, branches_for_lead_time_for_changes: ['master', 'main'])
```

Pour mettre à jour une configuration existante, exécutez la commande suivante :

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
record = Dora::Configuration.where(project: my_project).first
record.branches_for_lead_time_for_changes = ['development', 'staging', 'master', 'main']
record.save!
```

## Mesurer les métriques DORA {#measure-dora-metrics}

### Sans utiliser les pipelines GitLab CI/CD {#without-using-gitlab-cicd-pipelines}

La fréquence de déploiement est calculée sur la base des enregistrements de déploiement, qui sont créés pour les déploiements push classiques. Ces enregistrements de déploiement ne sont pas créés pour les déploiements pull, par exemple lorsque des images de conteneur sont connectées à GitLab avec un agent.

Pour suivre les métriques DORA dans ces cas, vous pouvez [créer un enregistrement de déploiement](../../api/deployments.md#create-a-deployment) à l'aide de l'API Deployments. Vous devez définir le nom de l'environnement où le niveau de déploiement est configuré, car la variable de niveau est spécifiée pour l'environnement donné, et non pour les déploiements. Pour plus d'informations, consultez comment [suivre les déploiements d'un outil de déploiement externe](../../ci/environments/external_deployment_tools.md).

### Avec Jira {#with-jira}

- La fréquence de déploiement et le délai d'exécution des changements sont calculés sur la base de GitLab CI/CD et des merge requests (MR), et ne nécessitent pas de données Jira.
- Le délai de restauration du service et le taux d'échec des changements nécessitent les [incidents GitLab](../../operations/incident_management/manage_incidents.md) pour le calcul. Pour plus d'informations, consultez comment mesurer ces métriques [avec des incidents externes](#with-external-incidents) et le [guide du réplicateur d'incidents Jira](https://gitlab.com/smathur/jira-incident-replicator).

### Avec des incidents externes {#with-external-incidents}

Vous pouvez mesurer le délai de restauration du service et le taux d'échec des changements pour la gestion des incidents.

Pour PagerDuty, vous pouvez [configurer un webhook](../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook) pour créer automatiquement un incident GitLab pour chaque incident PagerDuty. Cette configuration nécessite d'apporter des modifications à la fois dans PagerDuty et dans GitLab.

Pour les autres outils de gestion des incidents, vous pouvez configurer l'[intégration HTTP](../../operations/incident_management/integrations.md#alerting-endpoints) et l'utiliser pour effectuer automatiquement :

1. [Créer un incident lorsqu'une alerte est déclenchée](../../operations/incident_management/manage_incidents.md#automatically-when-an-alert-is-triggered).
1. [Fermer les incidents via des alertes de récupération](../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts).

## Fonctionnalités d'analyse {#analytics-features}

Les métriques DORA sont affichées dans les fonctionnalités d'analyse suivantes :

- Le [tableau de bord des flux de valeur](value_streams_dashboard.md) inclut le [panneau de comparaison des métriques DORA](value_streams_dashboard.md#devsecops-metrics-comparison) et le [panneau de score des performers DORA](value_streams_dashboard.md#dora-performers-score).
- Les [graphiques d'analyse CI/CD](ci_cd_analytics.md) affichent l'historique des métriques DORA dans le temps.
- Les [rapports Insights](../project/insights/_index.md) offrent la possibilité de créer des graphiques personnalisés avec les [paramètres de requête DORA](../project/insights/_index.md#dora-query-parameters).
- L'[API GraphQL](../../api/graphql/reference/_index.md) (avec l'[explorateur GraphQL interactif](../../api/graphql/_index.md#interactive-graphql-explorer)) et l'[API REST](../../api/dora/metrics.md) permettent de récupérer les données de métriques.

## Disponibilité par projet et groupe {#project-and-group-availability}

Le tableau suivant présente un aperçu de la disponibilité des métriques DORA dans les projets et les groupes.

| Métrique                    | Niveau             | Commentaires |
|---------------------------|-------------------|----------|
| `deployment_frequency`    | Projet           | Unité en nombre de déploiements. |
| `deployment_frequency`    | Groupe             | Unité en nombre de déploiements. La méthode d'agrégation est la moyenne.  |
| `lead_time_for_changes`   | Projet           | Unité en secondes. La méthode d'agrégation est la médiane. |
| `lead_time_for_changes`   | Groupe             | Unité en secondes. La méthode d'agrégation est la médiane. |
| `time_to_restore_service` | Projet et groupe | Unité en jours. La méthode d'agrégation est la médiane. |
| `change_failure_rate`     | Projet et groupe | Pourcentage de déploiements. |

## Agrégation des données {#data-aggregation}

Le tableau suivant présente un aperçu de l'agrégation des données des métriques DORA dans différents graphiques.

| Nom de la métrique | Valeurs mesurées | Agrégation des données dans le [tableau de bord des flux de valeur](value_streams_dashboard.md) | Agrégation des données dans les [graphiques d'analyse CI/CD](ci_cd_analytics.md) | Agrégation des données dans les [rapports Insights personnalisés](../project/insights/_index.md#dora-query-parameters) |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| Fréquence de déploiement | Nombre de déploiements réussis | moyenne quotidienne par mois | moyenne quotidienne | `day` (par défaut) ou `month` |
| Délai d'exécution des changements | Nombre de secondes pour livrer avec succès un commit en production | médiane quotidienne par mois | temps médian |  `day` (par défaut) ou `month` |
| Délai de restauration du service | Nombre de secondes pendant lesquelles un incident a été ouvert           | médiane quotidienne par mois | médiane quotidienne | `day` (par défaut) ou `month` |
| Taux d'échec des changements | pourcentage de déploiements qui causent un incident en production | médiane quotidienne par mois | pourcentage de déploiements échoués | `day` (par défaut) ou `month` |
