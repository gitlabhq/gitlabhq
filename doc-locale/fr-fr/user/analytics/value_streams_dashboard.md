---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Affichez les métriques DevSecOps (telles que DORA et les vulnérabilités) dans l'ensemble de votre organisation sur un tableau de bord personnalisable."
title: Tableau de bord des chaînes de valeur
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086) de GitLab Ultimate vers GitLab Premium dans la version 18.2.

{{< /history >}}

Le tableau de bord des chaînes de valeur est un tableau de bord personnalisable que vous pouvez utiliser pour identifier les tendances, les schémas et les opportunités d'amélioration de la transformation numérique. L'interface centralisée du tableau de bord des chaînes de valeur fait office de source unique de vérité (SSOT), permettant à toutes les parties prenantes d'accéder aux mêmes métriques pertinentes pour l'organisation et de les consulter. Le tableau de bord des chaînes de valeur comprend des panneaux qui visualisent les métriques suivantes :

- [Métriques DORA](dora_metrics.md)
- [Value Stream Analytics (VSA) : métriques de flux](../group/value_stream_analytics/_index.md)
- [Vulnérabilités](../application_security/vulnerability_report/_index.md)
- Suggestions de code GitLab Duo

Avec le tableau de bord des chaînes de valeur, vous pouvez :

- Suivre et comparer les métriques répertoriées précédemment sur une période donnée.
- Identifier rapidement les tendances à la baisse.
- Comprendre l'exposition aux risques de sécurité.
- Explorer en détail les projets ou les métriques individuels afin de prendre des mesures d'amélioration.
- Comprendre l'impact de l'intégration de l'IA dans le cycle de vie du développement logiciel (SDLC) et démontrer le retour sur investissement (ROI) des investissements dans GitLab Duo.

Pour une démonstration interactive, consultez [la visite guidée du produit Value Stream Management](https://gitlab.navattic.com/vsm).

Pour afficher le tableau de bord des chaînes de valeur en tant que tableau de bord d'analyse pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Dans la liste des tableaux de bord disponibles, sélectionnez **Tableau de bord des chaînes de valeur**.

> [!note]
> Les données affichées dans le tableau de bord des chaînes de valeur sont collectées en continu en arrière-plan. Si vous passez à l'édition Ultimate, vous accédez aux données historiques et pouvez consulter les métriques relatives aux usages et aux performances passés de GitLab.

## Panneaux {#panels}

Les panneaux du tableau de bord des chaînes de valeur disposent d'une configuration par défaut, mais vous pouvez également personnaliser les panneaux du tableau de bord.

### Vue d'ensemble {#overview}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/439699) dans GitLab 16.7 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `group_analytics_dashboard_dynamic_vsd`. Désactivées par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/432185) dans GitLab 17.0.
- Le feature flag `group_analytics_dashboard_dynamic_vsd` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/441206) dans GitLab 17.0.

{{< /history >}}

La vue d'ensemble offre une vision globale de l'activité des espaces de nommage de niveau supérieur en visualisant les métriques DevOps clés :

- Un panneau de métadonnées d'espace de nommage qui affiche le nom, le type et la visibilité de l'espace de nommage.
- Une rangée de panneaux à statistique unique affichant les compteurs d'utilisation.

Le tableau suivant présente les compteurs d'utilisation disponibles pour les ressources dans les espaces de nommage de groupe et de projet :

| Compteur d'utilisation    | Visualisation          | Groupe       | Projet     |
|----------------|------------------------|-------------|-------------|
| Sous-groupes      | `groups_count`         | {{< yes >}} | {{< no >}}  |
| Projets       | `projects_count`       | {{< yes >}} | {{< no >}}  |
| Utilisateurs          | `users_count`          | {{< yes >}} | {{< no >}}  |
| Les tickets         | `issues_count`         | {{< yes >}} | {{< yes >}} |
| Les merge requests | `merge_requests_count` | {{< yes >}} | {{< yes >}} |
| Pipelines      | `pipelines_count`      | {{< yes >}} | {{< yes >}} |

Les données affichées dans la vue d'ensemble sont collectées par traitement par lots. GitLab stocke les compteurs d'enregistrements pour chaque sous-groupe dans la base de données, puis agrège ces compteurs pour fournir des métriques pour le groupe principal. Les données sont agrégées mensuellement, aux alentours de la fin du mois, dans la mesure du possible en fonction de la charge sur les systèmes GitLab.

Pour plus d'informations, consultez l'[epic 10417](https://gitlab.com/groups/gitlab-org/-/epics/10417#iterations-path).

### Comparaison des métriques DevSecOps {#devsecops-metrics-comparison}

{{< history >}}

- La métrique de nombre de contributeurs au niveau du projet a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/474119) sur GitLab.com dans GitLab 18.0.
- Les tableaux de comparaison des métriques DevSecOps ont été [migrés](https://gitlab.com/gitlab-org/gitlab/-/issues/541489) vers la visualisation `ai_impact_table` dans GitLab 18.5.

{{< /history >}}

Les panneaux de comparaison des métriques DevSecOps affichent les métriques d'un groupe ou d'un projet sur les six derniers mois. Ces visualisations vous aident à comprendre si les métriques DevSecOps clés s'améliorent d'un mois à l'autre. Le tableau de bord des chaînes de valeur affiche trois panneaux de comparaison des métriques DevSecOps :

- Métriques du cycle de vie
- Métriques DORA (Ultimate uniquement)
- Métriques de sécurité (Ultimate uniquement, au moins le rôle **Développeur**)

Dans chaque panneau de comparaison, vous pouvez :

- Comparer les performances entre les groupes, les projets et les équipes en un coup d'œil.
- Identifier les équipes et les projets qui sont les plus grands contributeurs de valeur, qui surperforment ou qui sous-performent.
- Explorer en détail les métriques pour une analyse approfondie.

Lorsque vous survolez une métrique, une info-bulle affiche une explication de la métrique et un lien vers la page de documentation correspondante.

La colonne **Changement en %** indique également un pourcentage d'augmentation ou de diminution de la valeur de la métrique par rapport au mois précédent, comparé à six mois auparavant.

La colonne **Tendance** affiche des graphiques sparkline pour vous aider à identifier des schémas dans les tendances des métriques (comme les variations saisonnières) au fil du temps. La couleur du graphique sparkline varie du bleu au vert, où le vert indique une tendance positive et le bleu une tendance négative.

### Score DORA Performers {#dora-performers-score}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Le panneau Score DORA Performers est un graphique à barres au niveau du groupe qui visualise le statut des niveaux de performance DevOps de l'organisation dans différents projets pour le dernier mois civil complet.

![Un graphique à barres avec les métriques DORA pour un groupe](img/vsd_dora_performers_score_v17_7.png)

Le graphique présente une décomposition des scores DORA de votre projet, [classés](https://cloud.google.com/blog/products/devops-sre/dora-2022-accelerate-state-of-devops-report-now-out) comme élevés, moyens ou faibles. Le graphique agrège tous les projets enfants du groupe.

Les barres du graphique affichent le nombre total de projets par catégorie de score, calculé mensuellement. Pour exclure des données du graphique (par exemple, **Non inclus(e)**), sélectionnez la série à exclure dans la légende. Le survol de chaque barre affiche une boîte de dialogue expliquant la définition du score.

Par exemple, si un projet obtient un score élevé pour la fréquence de déploiement (vélocité), cela signifie qu'il effectue un ou plusieurs déploiements en production par jour.

| Métrique                  | Élevé | Moyen  | Faible  | Description |
|-------------------------|------|---------|------|-------------|
| Fréquence de déploiement    | ≥ 30  | 1-29    | < 1  | Le nombre de déploiements en production par jour |
| Délai d'exécution des modifications   | ≤ 7   | 8-29    | ≥ 30  | Le nombre de jours entre la validation du code et son exécution réussie en production |
| Délai de restauration du service | ≤ 1   | 2-6     | ≥ 7   | Le nombre de jours pour restaurer le service lorsqu'un incident de service ou un défaut impactant les utilisateurs survient |
| Taux d'échec des modifications     | ≤ 15 % | 16-44 % | ≥ 45 % | Le pourcentage de modifications en production ayant entraîné une dégradation du service |

Pour en savoir plus, consultez l'article de blog [Inside DORA Performers score in GitLab Value Streams Dashboard](https://about.gitlab.com/blog/inside-dora-performers-score-in-gitlab-value-streams-dashboard/).

#### Filtrer le panneau par sujet de projet {#filter-the-panel-by-project-topic}

Lorsque vous personnalisez des tableaux de bord avec une configuration YAML, vous pouvez filtrer les projets affichés par [sujets](../project/project_topics.md) attribués.

```yaml
panels:
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-custom-group
      filters:
        projectTopics:
          - JavaScript
          - Vue.js
```

Si plusieurs sujets sont fournis, tous les sujets doivent correspondre pour que le projet soit inclus dans les résultats.

### Projets par métrique DORA {#projects-by-dora-metric}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/408516) dans GitLab 17.7

{{< /history >}}

Le panneau **Projects by DORA metric** est un tableau au niveau du groupe qui liste le statut des niveaux de performance DevOps de l'organisation dans les projets.

Le tableau liste tous les projets avec leurs métriques DORA, en agrégeant les données des projets enfants dans les groupes et sous-groupes. Les métriques sont agrégées pour le dernier mois civil complet.

Vous pouvez trier les projets par valeurs de métriques, ce qui vous aide à identifier les projets aux performances élevées, moyennes et faibles. Pour approfondir votre analyse, vous pouvez sélectionner un nom de projet pour accéder à la page de ce projet.

![Un tableau avec les métriques DORA pour différents projets](img/vsd_projects_dora_metrics_v17_7.png)

## Activer ou désactiver l'agrégation en arrière-plan de la vue d'ensemble {#enable-or-disable-overview-background-aggregation}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour activer ou désactiver l'agrégation des compteurs de la vue d'ensemble pour le tableau de bord des chaînes de valeur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe. Ce groupe doit être au niveau supérieur.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Données d'analyse**.
1. Dans **Tableau de bord des chaînes de valeur**, cochez ou décochez la case **Activer l'agrégation en arrière-plan de la vue d'ensemble pour le tableau de bord des chaînes de valeur**.

Pour récupérer les compteurs d'utilisation agrégés dans le groupe, utilisez l'[API GraphQL](../../api/graphql/reference/_index.md#groupvaluestreamdashboardusageoverview).

## Afficher le tableau de bord des chaînes de valeur {#view-the-value-streams-dashboard}

Prérequis :

- Vous devez disposer du rôle Reporter, Développeur, Mainteneur ou Propriétaire pour le groupe ou le projet.
- L'agrégation en arrière-plan de la vue d'ensemble doit être activée.
- Pour afficher la métrique du nombre de contributeurs dans le panneau de comparaison, vous devez [configurer ClickHouse](../../integration/clickhouse.md).
- Pour suivre les déploiements en production, le groupe ou le projet doit disposer d'un environnement dans le [niveau de déploiement de production](../../ci/environments/_index.md#deployment-tier-of-environments).
- Pour mesurer le temps de cycle, [les tickets doivent être liés de manière croisée depuis les messages de commit](../project/issues/crosslinking_issues.md#from-commit-messages).

### Pour les groupes {#for-groups}

Pour afficher le tableau de bord des chaînes de valeur pour un groupe :

- Depuis les tableaux de bord d'analyse :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
  1. Sélectionnez **Analyse** > **Tableaux de bord d'analyse**.
- Depuis Value Stream Analytics :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
  1. Sélectionnez **Analyse** > **Données d'analyse des chaînes de valeur**.
  1. Sous la zone de texte **Filtrer les résultats**, dans la ligne **Métriques du cycle de vie**, sélectionnez **Value Streams Dashboard / DORA**.
  1. Facultatif. Pour ouvrir la nouvelle page, ajoutez ce chemin `/analytics/dashboards/value_streams_dashboard` à l'URL du groupe (par exemple, `https://gitlab.com/groups/gitlab-org/-/analytics/dashboards/value_streams_dashboard`).

### Pour les projets {#for-projects}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137483) dans GitLab 16.7 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `project_analytics_dashboard_dynamic_vsd`. Désactivées par défaut.
- Le feature flag `project_analytics_dashboard_dynamic_vsd` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/441207) dans GitLab 17.5.

{{< /history >}}

Pour afficher le tableau de bord des chaînes de valeur en tant que tableau de bord d'analyse pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Dans la liste des tableaux de bord disponibles, sélectionnez **Tableau de bord des chaînes de valeur**.

## Planifier des rapports {#schedule-reports}

Vous pouvez planifier des rapports à l'aide du composant CI/CD [Value Streams Dashboard Scheduled Reports tool](https://gitlab.com/components/vsd-reports-generator). Cet outil permet de gagner du temps et des efforts en éliminant le besoin de rechercher manuellement le bon tableau de bord avec les données pertinentes, afin que vous puissiez vous concentrer sur l'analyse des informations. En planifiant des rapports, vous pouvez vous assurer que les décideurs de votre organisation reçoivent des informations proactives, opportunes et pertinentes.

L'outil Scheduled Reports collecte les métriques des projets ou des groupes via l'API GraphQL publique de GitLab, puis génère un rapport en GitLab Flavored Markdown et ouvre un ticket dans un projet spécifié. Le ticket inclut un tableau de métriques comparatives au format Markdown.

Consultez un [exemple de rapport planifié](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report). Pour en savoir plus, consultez l'article de blog [New Scheduled Reports Generation tool simplifies value stream management](https://about.gitlab.com/blog/new-scheduled-reports-generation-tool-simplifies-value-stream-management/).

## Personnaliser les panneaux du tableau de bord {#customize-dashboard-panels}

Vous pouvez personnaliser le tableau de bord des chaînes de valeur et configurer les sous-groupes et les projets à inclure dans la page.

Pour personnaliser le contenu par défaut de la page, vous devez créer un fichier de configuration YAML dans un projet de votre choix. Dans ce fichier, vous pouvez définir divers paramètres, tels que le titre, la description et le nombre de panneaux. Le fichier est piloté par un schéma et géré avec des systèmes de contrôle de version tels que Git. Cela permet de suivre et de maintenir un historique des modifications de configuration, de revenir à des versions précédentes si nécessaire et de collaborer efficacement avec les membres de l'équipe. Les paramètres de requête peuvent toujours être utilisés pour remplacer la configuration YAML.

Avant de personnaliser les panneaux du tableau de bord, vous devez sélectionner un projet pour stocker votre fichier de configuration YAML.

Prérequis :

- Vous devez disposer du rôle Mainteneur ou Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Données d'analyse**.
1. Sélectionnez le projet dans lequel vous souhaitez stocker votre fichier de configuration YAML.
1. Sélectionnez **Enregistrer les modifications**.

Après avoir configuré le projet, configurez le fichier de configuration :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet que vous avez sélectionné à l'étape précédente.
1. Dans la branche par défaut, créez le fichier de configuration : `.gitlab/analytics/dashboards/value_streams/value_streams.yaml`.
1. Dans le fichier de configuration `value_streams.yaml`, renseignez les options de configuration :

| Champ                                      | Description |
|--------------------------------------------|-------------|
| `title`                                    | Nom personnalisé du panneau |
| `queryOverrides` (anciennement `data`)         | Remplace les paramètres de requête de données spécifiques à chaque visualisation. |
| `namespace` (sous-champ de `queryOverrides`) | Chemin du groupe ou du projet à utiliser pour le panneau |
| `filters` (sous-champ de `queryOverrides`)   | Filtre la requête pour chaque type de visualisation pris en charge. |
| `visualization`                            | Le type de visualisation à afficher. Les options prises en charge sont `ai_impact_table`, `dora_performers_score`, `namespace_metadata` et les compteurs d'utilisation. |
| `gridAttributes`                           | La taille et le positionnement du panneau |
| `xPos` (sous-champ de `gridAttributes`)      | Position horizontale du panneau |
| `yPos` (sous-champ de `gridAttributes`)      | Position verticale du panneau |
| `width` (sous-champ de `gridAttributes`)     | Largeur du panneau (max. 12) |
| `height` (sous-champ de `gridAttributes`)    | Hauteur du panneau |

```yaml
# version - The latest version of the analytics dashboard schema
version: '2'

# title - Change the title of the Value Streams Dashboard.
title: 'Custom Dashboard title'

# description - Change the description of the Value Streams Dashboard. [optional]
description: 'Custom description'

# panels - List of panels that contain panel settings.
#   title - Change the title of the panel.
#   visualization - The type of visualization to be rendered
#   gridAttributes - The size and positioning of the panel
#   queryOverrides.namespace - The Group or Project path to use for the chart panel
#   queryOverrides.filters.includeMetrics - Shows rows by metric ID in the table panel.
panels:
  - title: 'Group usage overview'
    visualization: namespace_metadata
    gridAttributes:
      yPos: 0
      xPos: 0
      height: 4
      width: 12
  - title: 'Groups'
    visualization: groups_count
    gridAttributes:
      yPos: 4
      xPos: 0
      height: 4
      width: 4
  - title: 'Issues'
    visualization: issues_count
    gridAttributes:
      yPos: 4
      xPos: 4
      height: 4
      width: 4
  - title: 'Merge requests'
    visualization: merge_requests_count
    gridAttributes:
      yPos: 4
      xPos: 8
      height: 4
      width: 4
  - title: 'Group dora and issue metrics'
    visualization: ai_impact_table
    queryOverrides:
      namespace: group
      filters:
        includeMetrics:
          - deployment_frequency
          - deploys
    gridAttributes:
      yPos: 8
      xPos: 0
      height: 12
      width: 12
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-project
      filters:
        projectTopics:
          - ruby
          - javascript
    gridAttributes:
      yPos: 20
      xPos: 0
      height: 12
      width: 12
```

### Filtres de visualisation pris en charge {#supported-visualization-filters}

Le sous-champ `filters` du champ `queryOverrides` peut être utilisé pour personnaliser les données affichées dans un panneau.

#### Filtres du panneau de comparaison des métriques DevSecOps {#devsecops-metrics-comparison-panel-filters}

Filtres pour la visualisation `ai_impact_table`.

| Filtre           | Description                                                                       | Valeurs prises en charge                          |
|------------------|-----------------------------------------------------------------------------------|-------------------------------------------|
| `includeMetrics` | Affiche les lignes par ID de métrique dans le panneau de tableau. Est prioritaire sur `excludeMetrics`. | N'importe quel `ID` parmi les [métriques disponibles](#dashboard-metrics-and-drill-down-reports). |
| `excludeMetrics` | Masque les lignes par ID de métrique dans le panneau de tableau.                                     | N'importe quel `ID` parmi les [métriques disponibles](#dashboard-metrics-and-drill-down-reports). |

#### Filtres du panneau Score DORA Performers {#dora-performers-score-panel-filters}

Filtres pour la visualisation `dora_performers_score`.

| Filtre          | Description                                                                               | Valeurs prises en charge |
|-----------------|-------------------------------------------------------------------------------------------|------------------|
| `projectTopics` | Filtre les projets affichés en fonction de leurs sujets attribués | N'importe quel sujet de groupe disponible |

#### Filtres de panneaux supplémentaires (obsolètes) {#additional-panel-filters-deprecated}

##### Filtres du graphique DORA {#dora-chart-filters}

> [!warning]
> La visualisation `dora_chart` a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206417) dans GitLab 18.5.

Filtres pour la visualisation `dora_chart`.

| Filtre   | Description                                  | Valeurs prises en charge |
|----------|----------------------------------------------|------------------|
| `labels` | Filtre les données par labels                       | N'importe quel label de groupe disponible. Le filtrage par label est pris en charge par les métriques suivantes : `lead_time`, `cycle_time`, `issues`, `issues_completed`, `merge_request_throughput`, `median_time_to_merge`. |

##### Filtres de la vue d'ensemble de l'utilisation {#usage-overview-filters}

> [!warning]
> La visualisation `usage_overview` a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/work_items/594892) dans GitLab 19.2. Utilisez plutôt la visualisation `namespace_metadata` et les statistiques uniques de compteurs d'utilisation.

Filtres pour la visualisation `usage_overview`.

Pour les espaces de nommage de groupe et de sous-groupe :

| Filtre    | Description                                                    | Valeurs prises en charge |
|-----------|----------------------------------------------------------------|------------------|
| `include` | Limite les métriques retournées, affiche toutes les métriques disponibles par défaut | `groups`, `projects`, `issues`, `merge_requests`, `pipelines`, `users` |

Pour les espaces de nommage de projet :

| Filtre    | Description                                                    | Valeurs prises en charge |
|-----------|----------------------------------------------------------------|------------------|
| `include` | Limite les métriques retournées, affiche toutes les métriques disponibles par défaut | `issues`, `merge_requests`, `pipelines` |

## Métriques du tableau de bord et rapports d'exploration {#dashboard-metrics-and-drill-down-reports}

{{< history >}}

- Les métriques d'utilisation de Code Suggestions, Non-Agentic Chat et Root Cause Analysis ont été [mises à jour](https://gitlab.com/gitlab-org/gitlab/-/issues/589605) pour afficher les compteurs absolus d'utilisateurs au lieu des taux en pourcentage dans GitLab 18.10.

{{< /history >}}

Le tableau suivant fournit une vue d'ensemble des métriques disponibles dans le tableau de bord des chaînes de valeur, accompagnées de leurs descriptions et du nom du rapport d'exploration dans lequel elles sont affichées.

| Métrique                            | Description                                                                                                          | Rapport d'exploration | ID |
|-----------------------------------|----------------------------------------------------------------------------------------------------------------------| ----------------- | -- |
| Fréquence de déploiement              | Nombre moyen de déploiements en production par jour. Cette métrique mesure la fréquence à laquelle de la valeur est livrée aux utilisateurs finaux. | Onglet **Fréquence de déploiement** | `deployment_frequency` |
| Délai d'exécution des modifications             | Le temps nécessaire pour livrer avec succès un commit en production. Cette métrique reflète l'efficacité des pipelines CI/CD.   | Onglet **Durée d'exécution** | `lead_time_for_changes` |
| Délai de restauration du service           | Le temps qu'il faut à une organisation pour se remettre d'une défaillance en production.                                           | Onglet **Délai de restauration du service** | `time_to_restore_service` |
| Taux d'échec des modifications               | Pourcentage de déploiements ayant provoqué un incident en production.                                                      | Onglet **Taux d'échec des modifications** | `change_failure_rate` |
| Durée d'exécution                         | Temps médian entre la création d'un ticket et sa clôture.                                                                      | Value Stream Analytics | `lead_time` |
| Temps de cycle                        | Temps médian entre le premier commit de la merge request d'un ticket lié et la clôture de ce ticket.                 | Section **Métriques du cycle de vie** dans Value Stream Analytics | `cycle_time` |
| Tickets créés                    | Nombre de nouveaux tickets créés.                                                                                        | Analyse des tickets | `issues` |
| Tickets clôturés                     | Nombre de tickets clôturés par mois.                                                                                    | Analyse des tickets | `issues_completed` |
| Nombre de déploiements                 | Nombre total de déploiements en production.                                                                               | Analyse des merge requests | `deploys` |
| Débit des merge requests          | Le nombre de merge requests fusionnées par mois.                                                                        | Analyse de la productivité | `merge_request_throughput` |
| Délai médian avant fusion              | Temps médian entre la création d'une merge request et sa fusion.                                                  | Analyse de la productivité | `median_time_to_merge` |
| Nombre de contributeurs                 | Nombre d'utilisateurs uniques ayant contribué dans le groupe au cours du mois.                                                      | Analyse des contributions | `contributor_count` |
| Vulnérabilités critiques au fil du temps | Vulnérabilités critiques au fil du temps dans le projet ou le groupe                                                               | Rapport de vulnérabilités | `vulnerability_critical` |
| Vulnérabilités élevées au fil du temps    | Vulnérabilités élevées au fil du temps dans le projet ou le groupe                                                                   | Rapport de vulnérabilités | `vulnerability_high` |
| Total des exécutions de pipelines               | Le nombre total de pipelines ayant été exécutés pendant la période sélectionnée.                                             | Analyse CI/CD | `pipeline_count` |
| Durée médiane des pipelines          | Le temps médian d'exécution des pipelines.                                                                  | Analyse CI/CD | `pipeline_duration_median` |
| Taux de réussite des pipelines             | Le pourcentage de pipelines s'étant terminés avec succès.                                                             | Analyse CI/CD | `pipeline_success_rate` |
| Taux d'échec des pipelines             | Le pourcentage de pipelines ayant échoué.                                                                             | Analyse CI/CD | `pipeline_failed_rate` |
| Utilisation des fonctionnalités                     | Nombre de contributeurs ayant utilisé une fonctionnalité GitLab Duo.                                                              |  | `duo_used_count` |
| Utilisation de Code Suggestions            | Nombre d'utilisateurs ayant utilisé Code Suggestions.                                                                           |  | `code_suggestions_users_count` |
| Taux d'acceptation de Code Suggestions  | Suggestions de code acceptées sur le total des suggestions de code générées.                                                   |  | `code_suggestions_acceptance_rate` |
| Utilisation de Non-Agentic Chat          | Nombre d'utilisateurs ayant utilisé Non-Agentic Chat.                                                                     |  | `duo_chat_users_count` |
| Utilisation de Root Cause Analysis         | Nombre d'utilisateurs ayant utilisé Root Cause Analysis.                                                                        |  | `duo_rca_users_count` |

## Métriques avec Jira {#metrics-with-jira}

Les métriques suivantes ne dépendent pas de l'utilisation de Jira :

- Fréquence de déploiement DORA
- Délai d'exécution des modifications DORA
- Nombre de déploiements
- Débit des merge requests
- Délai médian avant fusion
- Vulnérabilités
