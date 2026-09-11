---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Analyse au niveau de l'instance, du groupe et du projet."
title: "Analyser l'utilisation de GitLab"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Les analyses au niveau du groupe ont été déplacées vers GitLab Premium dans la version 13.9.

{{< /history >}}

GitLab fournit des fonctionnalités d'analyse qui vous donnent des insights sur votre cycle de vie du développement logiciel. Utilisez ces fonctionnalités pour suivre la productivité, la qualité du code, les performances de déploiement et la sécurité. Les fonctionnalités d'analyse sont disponibles pour les instances, les groupes et les [projets](../project/settings/_index.md#turn-off-project-analytics), et nécessitent différents [rôles et permissions](../permissions.md#project-analytics). Ainsi, vous pouvez analyser les données à l'échelle qui compte pour votre équipe.

## Fonctionnalités d'analyse {#analytics-features}

### Analyses de visibilité et d'insight de bout en bout {#end-to-end-insight--visibility-analytics}

Utilisez ces fonctionnalités pour obtenir des insights sur l'ensemble de votre cycle de vie du développement logiciel.

| Fonctionnalité | Description | Niveau projet | Niveau groupe | Niveau instance |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Value Streams Dashboard](value_streams_dashboard.md) | Insights sur les tendances DevSecOps, les schémas et les opportunités d'amélioration de la transformation numérique. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Value Stream Management Analytics](../group/value_stream_analytics/_index.md) | Insights sur le délai de création de valeur grâce à des étapes personnalisables. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Adoption DevOps [par groupe](../group/devops_adoption/_index.md) et [par instance](../../administration/analytics/devops_adoption.md) | Maturité de l'organisation en matière d'adoption DevOps, avec l'adoption des fonctionnalités au fil du temps et la distribution des fonctionnalités par groupe. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Tendances d'utilisation](../../administration/analytics/usage_trends.md) | Vue d'ensemble des données d'instance et des évolutions du volume de données au fil du temps. | {{< no >}} | {{< no >}} | {{< yes >}} |
| [Insights](../project/insights/_index.md) | Rapports personnalisables pour explorer les tickets, les merge requests fusionnées et l'hygiène de triage. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Tableaux de bord Analytics](analytics_dashboards.md) | Tableaux de bord intégrés et personnalisables pour visualiser les données collectées. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### Analyses de productivité {#productivity-analytics}

Utilisez ces fonctionnalités pour obtenir des insights sur la productivité de votre équipe concernant les tickets et les merge requests.

| Fonctionnalité | Description | Niveau projet | Niveau groupe | Niveau instance |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Analyse des tickets](../group/issues_analytics/_index.md) | Visualisation des tickets créés chaque mois. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Analyse des merge requests](merge_request_analytics.md) | Vue d'ensemble des merge requests, avec le délai moyen de fusion, le débit et les détails d'activité. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Analyses de productivité](productivity_analytics.md) | Cycle de vie des merge requests, filtrable jusqu'au niveau de l'auteur. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Analyses de revue de code](code_review_analytics.md) | Merge requests ouvertes avec des informations sur l'activité des merge requests. | {{< yes >}} | {{< no >}} | {{< no >}} |

### Analyses pour les développeurs {#developer-analytics}

Utilisez ces fonctionnalités pour obtenir des insights sur la productivité des développeurs et la couverture du code.

| Fonctionnalité | Description | Niveau projet | Niveau groupe | Niveau instance |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Analyses des contributions](../group/contribution_analytics/_index.md) | Vue d'ensemble des [événements de contribution](../profile/contributions_calendar.md) effectués par les membres du groupe, avec un graphique à barres des événements push, des merge requests et des tickets. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Analyses des contributeurs](contributor_analytics.md) | Vue d'ensemble des commits effectués par les membres du projet, avec un graphique linéaire du nombre de commits. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Analyses du dépôt](../group/repositories_analytics/_index.md) | Langages de programmation utilisés dans le dépôt et statistiques de couverture du code. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### Analyses CI/CD {#cicd-analytics}

Utilisez ces fonctionnalités pour obtenir des insights sur les performances CI/CD.

| Fonctionnalité | Description | Niveau projet | Niveau groupe | Niveau instance |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Analyses CI/CD](ci_cd_analytics.md) | Durée du pipeline et succès ou échecs. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Métriques DORA](dora_metrics.md) | Métriques DORA au fil du temps. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### Analyses de sécurité {#security-analytics}

Utilisez ces fonctionnalités pour obtenir des insights sur les vulnérabilités de sécurité et les métriques.

| Fonctionnalité | Description | Niveau projet | Niveau groupe | Niveau instance |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Tableaux de bord de sécurité](../application_security/security_dashboard/_index.md) | Collection de métriques, d'évaluations et de graphiques pour les vulnérabilités détectées par les scanners de sécurité. | {{< yes >}} | {{< yes >}} | {{< no >}} |

## Glossaire des métriques {#metric-glossary}

Le glossaire suivant fournit des définitions pour les métriques de développement courantes utilisées dans les fonctionnalités d'analyse, et explique comment elles sont mesurées dans GitLab.

| Métrique | Définition | Mesure dans GitLab |
| ------ | ---------- | --------------------- |
| Délai moyen de changement (MTTC) | La durée moyenne entre l'idée et la livraison. | Depuis la création d'un ticket jusqu'au déploiement en production de la merge request associée. |
| Délai moyen de détection (MTTD) | La durée moyenne pendant laquelle un bug passe inaperçu en production. | Depuis le déploiement d'un bug en production jusqu'à la création d'un ticket pour le signaler. |
| Délai moyen de fusion (MTTM) | La durée de vie moyenne d'une merge request. | Depuis la création d'une merge request jusqu'à sa fusion. Exclut les merge requests qui sont fermées ou non fusionnées. Pour plus d'informations, consultez les [analyses des merge requests](merge_request_analytics.md). |
| Délai moyen de rétablissement/réparation/résolution/restauration (MTTR) | La durée moyenne pendant laquelle un bug n'est pas corrigé en production. | Depuis le déploiement d'un bug en production jusqu'au déploiement du correctif. |
| Vélocité | La charge totale des tickets accomplis sur une période donnée. La charge est généralement mesurée en points ou en poids, souvent par sprint. | Total des points ou du poids des tickets clôturés sur une période donnée. Par exemple, « 30 points par sprint ». |

Pour plus de définitions, consultez également les [métriques du Value Streams Dashboard et les rapports d'exploration](value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports).
