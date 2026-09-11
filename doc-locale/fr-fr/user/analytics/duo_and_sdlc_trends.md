---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo et tendances SDLC
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta pour GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) dans GitLab 16.11 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `ai_impact_analytics_dashboard`. Désactivées par défaut.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/issues/451873) dans GitLab 17.2. Suppression du feature flag `ai_impact_analytics_dashboard`.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- Déplacé de GitLab Ultimate vers GitLab Premium dans la version 18.2.
- Modifié pour prendre en charge Amazon Q dans GitLab 18.2.1.
- Tableau des métriques de pipeline [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/550356) dans GitLab 18.4.
- Renommé de `AI impact analytics` en `GitLab Duo and SDLC trends` dans GitLab 18.4.
- Modifié pour ne plus exiger de modules complémentaires dans GitLab 18.7.

{{< /history >}}

Cette fonctionnalité est en version bêta pour GitLab Self-Managed. Pour plus d'informations, consultez l'[epic 51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51).

GitLab Duo et tendances SDLC mesurent l'impact de GitLab Duo sur les performances du cycle de vie du développement logiciel (SDLC). Ce tableau de bord offre une visibilité sur les métriques SDLC clés dans le contexte de l'adoption de l'IA pour les projets ou les groupes. Vous pouvez utiliser le tableau de bord pour mesurer quelles métriques se sont améliorées grâce à vos investissements dans l'IA.

Utilisez GitLab Duo et tendances SDLC pour :

- Suivre les tendances SDLC en lien avec votre parcours GitLab Duo : examinez comment les tendances d'utilisation de GitLab Duo dans un projet ou un groupe influencent d'autres métriques de productivité cruciales, telles que le temps moyen jusqu'à la fusion et les statistiques CI/CD. Les métriques d'utilisation de GitLab Duo sont affichées pour les six derniers mois, mois en cours inclus.
- Surveiller l'adoption des fonctionnalités GitLab Duo : suivez l'utilisation des sièges et des fonctionnalités dans un projet ou un groupe au cours des 30 derniers jours.

Le tableau suivant répertorie la disponibilité des métriques GitLab Duo et SDLC :

| Fonctionnalité | Requiert GitLab Duo Pro ou Enterprise | Requiert [ClickHouse](../../integration/clickhouse.md) |
|---------|:-----------------------:|:-------------------:|
| Tableau de bord GitLab Duo et tendances SDLC | {{< yes >}} | {{< yes >}} |
| API `AiMetrics` | {{< yes >}} | {{< yes >}} |
| API `AiUserMetrics` | {{< yes >}} | {{< yes >}} |
| API `AiUsageData` | {{< no >}} | {{< no >}} (PostgreSQL uniquement) |

Pour apprendre à optimiser l'utilisation de vos licences, consultez [les modules complémentaires GitLab Duo](../../subscriptions/subscription-add-ons.md).

Pour en savoir plus sur GitLab Duo et les tendances SDLC, consultez l'article de blog [Developing GitLab Duo : AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [GitLab Duo AI Impact Dashboard](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn).
<!-- Video published on 2025-03-06 -->

## Métriques clés {#key-metrics}

{{< history >}}

- La métrique d'utilisation de GitLab Duo Chat a été [remplacée](https://gitlab.com/gitlab-org/gitlab/-/issues/587301) par les sessions GitLab Duo Agentic Chat dans GitLab 18.10.
- La métrique d'engagement des sièges GitLab Duo attribués a été [remplacée](https://gitlab.com/gitlab-org/gitlab/-/work_items/587298) par les utilisateurs GitLab Duo dans GitLab 18.10.
- La métrique d'utilisation des suggestions de code GitLab Duo a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/work_items/592813), passant d'un taux en pourcentage à un nombre absolu d'utilisateurs dans GitLab 18.10.
- La métrique du taux d'acceptation des suggestions de code a été [remplacée](https://gitlab.com/gitlab-org/gitlab/-/work_items/587300) par les Personnes ayant utilisé des agents/flux GitLab Duo dans GitLab 18.11.
- Les indicateurs de tendance ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/590535) dans GitLab 19.0.
- La métrique des utilisateurs des suggestions de code a été [remplacée](https://gitlab.com/gitlab-org/gitlab/-/work_items/587299) par les Utilisateurs et utilisatrices avancés de GitLab Duo dans GitLab 19.0.
- La métrique Pipelines utilisant les fonctionnalités GitLab Duo a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/587308) dans GitLab 19.2.

{{< /history >}}

- **Utilisateurs GitLab Duo** : nombre d'utilisateurs ayant utilisé au moins une fonctionnalité GitLab Duo ou GitLab Duo Agent Platform au cours des 30 derniers jours.
- **Utilisateurs et utilisatrices avancés de GitLab Duo** : nombre d'utilisateurs ayant utilisé au moins trois fonctionnalités GitLab Duo au cours des 30 derniers jours.
- **Personnes ayant utilisé des agents/flux GitLab Duo** : nombre d'utilisateurs ayant utilisé au moins un agent ou flow GitLab Duo au cours des 30 derniers jours.
- **GitLab Duo Agent chat sessions** : nombre de sessions de chat initiées dans GitLab Duo Agent Platform au cours des 30 derniers jours.
- **Pipelines utilisant les fonctionnalités GitLab Duo** : pourcentage de pipelines CI/CD ayant utilisé une ou plusieurs fonctionnalités GitLab Duo lors de leur exécution au cours des 30 derniers jours.

## Tendances des métriques {#metric-trends}

Le tableau **Tendances des métriques** affiche les métriques des six derniers mois, avec les valeurs mensuelles, les variations en pourcentage au cours des six derniers mois et les graphiques sparkline de tendance.

Les métriques affichent un indicateur de tendance montrant la variation en pourcentage par rapport à la période précédente. Si aucune donnée n'est disponible pour la période précédente, la variation en pourcentage affiche **n/a**.

Les valeurs en vert indiquent des changements positifs, et les valeurs en rouge indiquent des changements négatifs. Les icônes à côté des valeurs indiquent les tendances à la hausse {{< icon name="trend-up" >}} ou les tendances à la baisse {{< icon name="trend-down" >}}.

Les tendances à la hausse sont positives (vert) pour certaines métriques (comme la [fréquence de déploiement](dora_metrics.md#deployment-frequency)), mais négatives (rouge) pour d'autres (comme le [temps médian jusqu'à la fusion](merge_request_analytics.md)).

### Métriques d'utilisation de GitLab Duo {#gitlab-duo-usage-metrics}

{{< history >}}

- L'utilisation de Root Cause Analysis de GitLab Duo a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/513252) dans GitLab 18.1 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `duo_rca_usage_rate`. Désactivées par défaut.
- L'utilisation de Root Cause Analysis de GitLab Duo a été [activée sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543987) dans GitLab 18.3.
- L'utilisation de Root Cause Analysis de GitLab Duo est [disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/issues/556726) dans GitLab 18.4. Suppression du feature flag `duo_rca_usage_rate`.
- L'utilisation des fonctionnalités GitLab Duo a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207562) dans GitLab 18.6.
- Les demandes et commentaires de revue de code GitLab Duo ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/573979) dans GitLab 18.7.
- Les chats et flows GitLab Duo Agent Platform ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/583375) dans GitLab 18.7.
- Les métriques GitLab Duo Code Suggestions, Non-Agentic Chat et Root Cause Analysis ont été [modifiées](https://gitlab.com/gitlab-org/gitlab/-/issues/589605), passant de taux en pourcentage à des nombres absolus d'utilisateurs dans GitLab 18.10.

{{< /history >}}

- **Utilisation des fonctionnalités** : nombre d'utilisateurs ayant utilisé au moins une fonctionnalité GitLab Duo ou GitLab Duo Agent Platform.
- **Chats Agent Platform** : nombre de sessions de chat initiées via GitLab Duo Agent Platform.
- **Flux Agent Platform** : nombre de flows d'agents (hors chats) exécutés via GitLab Duo Agent Platform.
- **Utilisation du chat non agentique** : nombre d'utilisateurs ayant utilisé le Non-Agentic Chat.
- **Utilisation de l'analyse des causes profondes** : nombre d'utilisateurs ayant utilisé Root Cause Analysis.
- **Demandes de revue de code** : nombre de demandes de revue de code effectuées sur des merge requests. Cela inclut les demandes initiées par les auteurs de merge requests et par les non-auteurs.
- **Commentaires de revue de code** : nombre de commentaires de revue de code publiés sur les diffs de merge requests.
- **Utilisation des suggestions de code** : nombre d'utilisateurs ayant utilisé Code Suggestions. Sur GitLab.com, les données sont mises à jour toutes les cinq minutes. GitLab comptabilise l'utilisation de Code Suggestions uniquement si l'utilisateur a effectué un push de code vers le projet au cours du mois en cours.
- **Taux d'acceptation des suggestions de code** : pourcentage de suggestions de code fournies par GitLab Duo qui ont été acceptées par les contributeurs.

### Métriques de développement {#development-metrics}

- [**Durée d'exécution**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**Temps médian jusqu'à la fusion**](merge_request_analytics.md)
- [**Fréquence de déploiement**](dora_metrics.md#deployment-frequency)
- [**Débit des requêtes de fusion**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**Vulnérabilités critiques au fil du temps**](../application_security/vulnerability_report/_index.md)
- [**Nombre de contributeurs**](../profile/contributions_calendar.md#user-contribution-events)

### Métriques de pipeline {#pipeline-metrics}

Le tableau des métriques de pipeline affiche les métriques des pipelines exécutés dans le projet sélectionné.

- **Nombre total de cycles de pipelines** : nombre d'exécutions de pipelines dans le projet.
- **Durée médiane** : durée médiane (en minutes) d'une exécution de pipeline.
- **Taux de réussite** : pourcentage d'exécutions de pipelines terminées avec succès.
- **Taux d’échec** : pourcentage d'exécutions de pipelines terminées avec des échecs.

## Pipelines utilisant GitLab Duo Agent Platform {#pipelines-using-gitlab-duo-agent-platform}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/587303) dans GitLab 19.0

{{< /history >}}

Le graphique **Pipelines using GitLab Duo Agent Platform** affiche le nombre de pipelines exécutés au cours des 180 derniers jours, agrégés par mois. Le graphique montre :

- **Avec Agent Platform** : nombre de pipelines déclenchés par GitLab Duo Agent Platform.
- **Tous les pipelines** : nombre total de pipelines exécutés dans l'espace de nommage.

## Acceptation des suggestions de code GitLab Duo par langage {#gitlab-duo-code-suggestions-acceptance-by-language}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/454809) dans GitLab 18.5

{{< /history >}}

Le graphique **GitLab Duo Code Suggestions acceptance by language** affiche le nombre de suggestions de code acceptées par langage de programmation pour les 30 derniers jours.

Survolez une barre pour afficher, pour chaque langage :

- **Suggestions acceptées** : nombre de suggestions acceptées par les utilisateurs.
- **Suggestions affichées** : nombre de suggestions affichées aux utilisateurs.
- **Taux d'acceptation** : pourcentage de suggestions acceptées. Calculé comme le nombre de suggestions de code acceptées divisé par le nombre total de suggestions de code affichées.

## Acceptation des suggestions de code GitLab Duo par IDE {#gitlab-duo-code-suggestions-acceptance-by-ide}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/550064) dans GitLab 18.7

{{< /history >}}

Le graphique **GitLab Duo Code Suggestions acceptance by IDE** affiche le nombre de suggestions de code acceptées par IDE pour les 30 derniers jours.

Survolez une barre pour afficher, pour chaque IDE :

- **Suggestions acceptées** : nombre de suggestions acceptées par les utilisateurs.
- **Suggestions affichées** : nombre de suggestions affichées aux utilisateurs.
- **Taux d'acceptation** : pourcentage de suggestions acceptées. Calculé comme le nombre de suggestions de code acceptées divisé par le nombre total de suggestions de code affichées.

## Tendances du volume de génération de code {#code-generation-volume-trends}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/573972) dans GitLab 18.5

{{< /history >}}

Le graphique **Code generation volume trends** affiche le volume de code généré via Code Suggestions au cours des 180 derniers jours, agrégé par mois. Le graphique montre :

- **Lignes de code acceptées** : lignes de code issues de Code Suggestions qui ont été acceptées.
- **Lignes de code affichées** : lignes de code affichées dans Code Suggestions.

## Demandes de revue de code GitLab Duo par rôle {#gitlab-duo-code-review-requests-by-role}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/574003) dans GitLab 18.7

{{< /history >}}

Le graphique **GitLab Duo Code Review requests by role** affiche le nombre de demandes de revue de code au cours des 180 derniers jours, agrégées par mois. Le graphique montre :

- **Review requests by authors** : nombre de demandes de revue de code effectuées par l'auteur de la merge request. Cela inclut les revues de code demandées automatiquement via les paramètres du projet et manuellement dans la merge request par l'auteur.
- **Review requests by non-authors** : nombre de demandes de revue de code effectuées par des utilisateurs autres que l'auteur de la merge request. Par exemple, des relecteurs qui demandent à GitLab Duo de revoir les modifications de la merge request.

Un taux d'adoption élevé par les auteurs indique que les équipes adoptent des workflows de revue automatisés.

## Sentiment des commentaires de revue de code GitLab Duo {#gitlab-duo-code-review-comments-sentiment}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/574005) dans GitLab 18.8

{{< /history >}}

Le graphique **GitLab Duo Code Review comments sentiment** affiche le sentiment des commentaires de revue de code au cours des 180 derniers jours, mesuré par les taux de réactions positives (👍) et négatives (👎). Le graphique montre :

- **Approval rate** : le pourcentage de commentaires de revue de code ayant reçu des réactions positives (👍).
- **Disapproval rate** : le pourcentage de commentaires de revue de code ayant reçu des réactions négatives (👎).

Lors de l'interprétation de vos données d'analyse, gardez à l'esprit que :

- Un biais de négativité est attendu. Les utilisateurs ont tendance à signaler les problèmes, mais reconnaissent rarement les bonnes suggestions, même lorsqu'ils les appliquent.
- Les faibles taux de réaction sont courants. Concentrez-vous sur l'amélioration du code et sur la rapidité des revues.
- La hausse des taux de désapprobation (👎) signale des problèmes. Des taux de désapprobation stables ou en baisse indiquent une adoption saine de GitLab Duo Code Review.

## Retour des utilisateurs GitLab Duo par fonctionnalité {#returning-gitlab-duo-users-by-feature}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/576752) dans GitLab 19.2

{{< /history >}}

Le graphique **Returning GitLab Duo users by feature** affiche le taux de rétention au cours des 180 derniers jours pour chaque fonctionnalité GitLab Duo : Code Suggestions, GitLab Duo Chat, Root cause analysis et GitLab Duo Code Review.

Survolez un point pour afficher, pour la fonctionnalité et la période sélectionnées :

- **Retention rate** : pourcentage d'utilisateurs de la période précédente qui utilisent à nouveau la fonctionnalité lors de la période sélectionnée. Calculé comme le nombre d'utilisateurs récurrents lors de la période sélectionnée divisé par le nombre d'utilisateurs lors de la période précédente.

Le graphique commence à partir de la deuxième période de la plage de dates sélectionnée. La première période n'affiche pas de taux de rétention car il n'existe pas de période antérieure à laquelle la comparer.

## Métriques GitLab Duo par utilisateur {#gitlab-duo-metrics-by-user}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/574420) dans GitLab 18.7

{{< /history >}}

Les tableaux de métriques utilisateurs affichent l'utilisation des différentes fonctionnalités GitLab Duo par chaque utilisateur au cours des 30 derniers jours.

- **GitLab Duo Code Suggestions usage by user** : nombre de suggestions de code acceptées et taux d'acceptation des suggestions de code.
- **GitLab Duo Code Review usage by user** : nombre de revues de code demandées en tant qu'auteur de la merge request auprès de GitLab Duo, et nombre de réactions (:thumbsup: et :thumbsdown:) aux commentaires de revue de code.
- **GitLab Duo Root Cause Analysis usage by user** : nombre de demandes de dépannage auprès de GitLab Duo.
- **GitLab Duo usage by user** : nombre d'événements GitLab Duo effectués par l'utilisateur.
- **Flows usage by user** : nombre de fois qu'un utilisateur déclenche un flow spécifique.

## Afficher les tendances GitLab Duo et SDLC {#view-gitlab-duo-and-sdlc-trends}

Prérequis :

- Vous devez disposer au minimum du rôle Reporter pour le groupe.
- Le groupe doit être un groupe principal.
- GitLab Duo Code Suggestions doit être activé.
- Pour GitLab Self-Managed, [ClickHouse pour les analyses de contribution](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse) doit être configuré.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Sélectionnez **GitLab Duo and SDLC trends**.

Pour récupérer les métriques GitLab Duo et SDLC, vous pouvez également utiliser les [API GraphQL](../../api/graphql/duo_and_sdlc_trends.md) `AiMetrics`, `AiUserMetrics` et `AiUsageData`.

## Disponibilité des données de métriques {#metric-data-availability}

Le tableau suivant affiche les versions de GitLab à partir desquelles le calcul des données d'utilisation a commencé pour les métriques GitLab Duo :

| Métrique GitLab Duo | Début du calcul des données |
|--------|------------------------------|
| Utilisation des suggestions de code | GitLab 16.11 |
| Utilisation de Root Cause Analysis | GitLab 18.0 |
| Demandes et commentaires de revue de code | GitLab 18.3 |
| Chats et flows Agent Platform | GitLab 18.7 |
