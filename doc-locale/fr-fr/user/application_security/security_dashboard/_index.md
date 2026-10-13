---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tableaux de bord de sécurité
description: "Tableaux de bord de sécurité, tendances des vulnérabilités, évaluations de projets et métriques."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Nouveau tableau de bord avec la recherche avancée [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/570504) dans GitLab 18.6 [avec des feature flags](../../../administration/feature_flags/_index.md) nommés `project_security_dashboard_new` et `group_security_dashboard_new`. Les flags sont désactivés par défaut.
- Nouveau tableau de bord avec la recherche avancée [activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574) dans GitLab 18.7.
- Nouveau tableau de bord avec la recherche avancée [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661) dans GitLab 18.8. Suppression des feature flags `project_security_dashboard_new` et `group_security_dashboard_new`.

{{< /history >}}

GitLab 18.6 a introduit une version améliorée des tableaux de bord de sécurité qui utilisent la [gestion avancée des vulnérabilités](../vulnerability_report/_index.md#advanced-vulnerability-management).

Les nouveaux tableaux de bord sont activés par défaut sur GitLab.com et GitLab Dedicated. Les utilisateurs de GitLab Self-Managed doivent activer la gestion avancée des vulnérabilités pour accéder aux nouveaux tableaux de bord.

Si votre organisation n'a pas activé la gestion avancée des vulnérabilités, consultez les [tableaux de bord de sécurité hérités](#legacy-security-dashboards).

## Tableaux de bord de sécurité {#security-dashboards}

{{< history >}}

- Nouveau tableau de bord utilisant la [gestion avancée des vulnérabilités](../vulnerability_report/_index.md#advanced-vulnerability-management) [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/570504) dans GitLab 18.6 [avec des feature flags](../../../administration/feature_flags/_index.md) nommés `project_security_dashboard_new` et `group_security_dashboard_new`. Les flags sont désactivés par défaut.
- Nouveau tableau de bord [activé sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574) dans GitLab 18.7.
- Nouveau tableau de bord [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661) dans GitLab 18.8. Suppression des feature flags `project_security_dashboard_new` et `group_security_dashboard_new`.

{{< /history >}}

Utilisez les tableaux de bord de sécurité pour évaluer la posture de sécurité de vos applications. GitLab vous fournit un ensemble de métriques, d'évaluations et de graphiques pour les vulnérabilités détectées par les [scanners de sécurité](../detect/_index.md) exécutés sur votre projet. Les tableaux de bord de sécurité fournissent les données suivantes :

- Tendances des vulnérabilités sur une période de 30, 60 ou 90 jours pour tous les projets d'un groupe.
- Le nombre total de vulnérabilités ouvertes par gravité.
- Le score de risque total pour comparer le risque lié aux vulnérabilités entre les projets.

### Prérequis {#prerequisites}

Pour afficher le tableau de bord de sécurité d'un projet ou d'un groupe, vous devez disposer des éléments suivants :

- Le rôle Developer ou supérieur pour le groupe ou le projet.
- Au moins un [scanner de sécurité](../detect/_index.md) configuré dans votre projet.
- Un scan de sécurité réussi effectué sur la [branche par défaut](../../project/repository/branches/default.md) de votre projet.
- Au moins une vulnérabilité détectée dans le projet.
- [Gestion avancée des vulnérabilités](../vulnerability_report/_index.md#advanced-vulnerability-management) avec la [Recherche avancée](../../search/advanced_search.md) activée.

> [!note]
> Les tableaux de bord de sécurité affichent les résultats des scans provenant du pipeline le plus récemment terminé sur la [branche par défaut](../../project/repository/branches/default.md). Les tableaux de bord sont mis à jour avec les résultats des pipelines terminés exécutés sur la branche par défaut. Ils n'incluent pas les vulnérabilités découvertes dans les pipelines d'autres branches non fusionnées.

### Consultation du tableau de bord de sécurité {#viewing-the-security-dashboard}

Le tableau de bord de sécurité affiche des graphiques et des panneaux filtrables alimentés par les données des vulnérabilités détectées dans la branche par défaut. Les graphiques et les panneaux n'incluent que les vulnérabilités ouvertes (dont le statut est « Nécessite un triage » ou « Confirmé ») et excluent celles qui ne sont plus détectées.

Vous pouvez afficher un tableau de bord de sécurité pour un projet ou un groupe. Chaque tableau de bord offre un point de vue unique sur votre posture de sécurité.

Les deux tableaux de bord incluent :

- [Graphiques](#charts)
  - [Vulnérabilités au fil du temps](#vulnerabilities-over-time)
  - [Panneaux de gravité des vulnérabilités](#vulnerability-severity-panel)
  - [Score de risque](#risk-score-panel)
  - [Vulnérabilités par âge](#vulnerabilities-by-age)
  - [Top 10 des CWE](#top-10-cwes)
  - [Entonnoir de triage et de correction SAST](#sast-triage-and-remediation-funnel)
- [Filtrer l'ensemble du tableau de bord](#filter-the-entire-dashboard)
- [Exporter sous forme de fichier PDF](#export-as-pdf)

Pour afficher un tableau de bord de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Tableau de bord de sécurité**.

### Tableau de bord de sécurité du projet {#project-security-dashboard}

Le tableau de bord de sécurité du projet affiche les vulnérabilités détectées dans la branche par défaut du projet. Il inclut :

- Le graphique [**Vulnérabilités au fil du temps**](#vulnerabilities-over-time), qui inclut jusqu'à 90 jours d'historique.
- Les [**Severity panels**](#vulnerability-severity-panel), qui affichent les vulnérabilités ouvertes par gravité.
- Le panneau [**Score de risque**](#risk-score-panel), qui affiche le risque de sécurité global du projet.
- Le graphique [**Vulnérabilités par âge**](#vulnerabilities-by-age), qui regroupe les vulnérabilités ouvertes par tranches d'âge.
- Le graphique [**Top 10 des CWE**](#top-10-cwes), qui affiche les 10 CWE les plus courants.
- Le graphique [**Entonnoir de triage et de correction SAST**](#sast-triage-and-remediation-funnel), qui montre la progression des vulnérabilités SAST critiques et élevées depuis leur détection jusqu'à leur correction, y compris les étapes gérées par GitLab Duo.

Les vulnérabilités ouvertes sont celles dont le statut est « Nécessite un triage » ou « Confirmé ». Les vulnérabilités fermées dont le statut est « Rejeté » ou « Résolu » ne sont pas incluses dans ces graphiques.

![Tableau de bord de sécurité du projet](img/project_security_dashboard_v18_5.png)

### Tableau de bord de sécurité du groupe {#group-security-dashboard}

Le tableau de bord de sécurité du groupe fournit une vue d'ensemble des vulnérabilités trouvées dans les branches par défaut de tous les projets d'un groupe et de ses sous-groupes. Le tableau de bord de sécurité du groupe fournit les éléments suivants :

- Le graphique [**Vulnérabilités au fil du temps**](#vulnerabilities-over-time), qui inclut jusqu'à 90 jours d'historique.
- Les [**Severity panels**](#vulnerability-severity-panel), qui affichent les vulnérabilités ouvertes par gravité.
- Le panneau [**Score de risque**](#risk-score-panel), qui affiche le risque total et le risque pour chaque projet.
- Le graphique [**Vulnérabilités par âge**](#vulnerabilities-by-age), qui regroupe les vulnérabilités ouvertes par tranches d'âge.
- Le graphique [**Top 10 des CWE**](#top-10-cwes), qui affiche les 10 CWE les plus courants.
- Le graphique [**Entonnoir de triage et de correction SAST**](#sast-triage-and-remediation-funnel), qui montre la progression des vulnérabilités SAST critiques et élevées depuis leur détection jusqu'à leur correction, y compris les étapes gérées par GitLab Duo.

### Graphiques {#charts}

Les tableaux de bord de sécurité comprennent plusieurs graphiques qui vous aident à comprendre les vulnérabilités de vos projets et groupes et à agir en conséquence.

#### Vulnérabilités au fil du temps {#vulnerabilities-over-time}

Le graphique **Vulnérabilités au fil du temps** est disponible sur les tableaux de bord de projet et de groupe. Il affiche les tendances des vulnérabilités ouvertes sur des périodes de 30, 60 ou 90 jours. La plage par défaut est de 30 jours. GitLab conserve les données de vulnérabilités pendant 365 jours.

Utilisez le graphique pour identifier quand les vulnérabilités ont été introduites et comment elles évoluent au fil du temps.

Pour afficher les détails :

1. Survolez un point de données pour voir le nombre de vulnérabilités pour ce jour.
1. Utilisez le **time frame selector** pour basculer entre 30, 60 ou 90 jours.
1. Faites glisser les poignées de plage ({{< icon name="scroll-handle" >}}) pour zoomer sur une période spécifique.
1. Utilisez le menu déroulant pour filtrer par **Gravité** (par exemple, **Critique**, **Niveau élevé**, **Niveau moyen**)
1. Utilisez les boutons pour regrouper les données selon l'une des options suivantes :
   - **Gravité** : critique, élevé, moyen, faible, info et inconnu.
   - **Type de rapport** : SAST, DAST et analyse des dépendances et autres.
1. Pour explorer des données au-delà de 90 jours, mais dans les 365 derniers jours, utilisez l'[API GraphQL `SecurityMetrics.vulnerabilitiesOverTime`](../../../api/graphql/reference/_index.md#securitymetricsvulnerabilitiesovertime)

![vulnérabilités au fil du temps](img/vulnerabilities_over_time_chart_v18_5.png)

#### Panneau de gravité des vulnérabilités {#vulnerability-severity-panel}

Le panneau de gravité des vulnérabilités affiche le nombre total de vulnérabilités ouvertes par [gravité](../vulnerabilities/severities.md).

Pour afficher les détails :

1. Dans le panneau de gravité, localisez la gravité que vous souhaitez analyser.
1. Sélectionnez **Afficher**.
   - Le rapport de vulnérabilités s'ouvre et n'inclut que les vulnérabilités de cette gravité.
   - Les filtres de niveau de page que vous avez définis sont également appliqués.

![niveau de gravité](img/security_dashboard_severity_panels_v18_5.png)

#### Panneau Score de risque {#risk-score-panel}

{{< history >}}

- Panneau Score de risque pour les tableaux de bord de groupe :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/570504) dans GitLab 18.6 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `security_dashboard_risk_score`. Désactivées par défaut.
  - [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574) dans GitLab 18.7.
  - [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661) dans GitLab 18.8. Suppression du feature flag `security_dashboard_risk_score`.
- Graphique Score de risque pour les tableaux de bord de projet :
  - [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/591112) dans GitLab 18.11.

{{< /history >}}

Le panneau Score de risque affiche le risque de sécurité global du groupe ou du projet. Le panneau dispose de deux vues :

1. La vue **Global** (par défaut) affiche le score de risque total du groupe :
   - La jauge circulaire affiche le score de risque calculé au centre.
   - Les barres de couleur indiquent le niveau de risque :
     - Vert : risque faible
     - Jaune : risque moyen
     - Orange : risque élevé
     - Rouge : risque critique
1. Sélectionnez **Projet** pour comparer les scores de risque de chaque projet :
   - Chaque tuile de projet est codée par couleur selon le niveau de risque du projet.
   - Survolez une tuile pour voir les détails, notamment le nom du projet et le score de risque.
   - Sélectionnez une vignette, puis sélectionnez le nom du projet pour ouvrir le rapport de vulnérabilités de ce projet.

![vue par défaut du tableau de bord de sécurité](img/group_security_dashboard_risk_score_v18_6.png)

![Vue grille projet du tableau de bord de sécurité](img/group_security_dashboard_total_risk_score_project_v18_6.png)

Les scores de risque sont calculés à partir de plusieurs facteurs, notamment :

- Gravité des vulnérabilités
- Âge des vulnérabilités
- Statut KEV (Known Exploited Vulnerabilities)
- Score EPSS (Exploit Prediction Scoring System)

#### Vulnérabilités par âge {#vulnerabilities-by-age}

{{< history >}}

- Graphique Vulnérabilités par âge pour les tableaux de bord de projet :
  - [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/590979) dans GitLab 18.11.

{{< /history >}}

Le graphique **Vulnérabilités par âge** est disponible sur les tableaux de bord de groupe et de projet. Il affiche la distribution des vulnérabilités non résolues en fonction du temps écoulé depuis leur première détection. Vous pouvez regrouper les vulnérabilités par gravité ou par type de rapport, ce qui vous aide à identifier les endroits où des activités de remédiation peuvent être nécessaires.

Pour afficher les détails :

1. Survolez un point de données pour voir le nombre de vulnérabilités pour ce groupe d'âge.
1. Utilisez la liste déroulante pour filtrer par **Gravité** (par exemple, **Critique**, **Niveau élevé**, **Niveau moyen**)
1. Utilisez les boutons pour regrouper les données selon l'une des options suivantes :
   - **Gravité** : critique, élevé, moyen, faible, info et inconnu.
   - **Type de rapport** : SAST, DAST et analyse des dépendances et autres.

![vulnérabilités par âge](img/vulnerabilities_by_age_chart_v18_9.png)

#### Top 10 des CWE {#top-10-cwes}

{{< history >}}

- [Introduits](https://gitlab.com/groups/gitlab-org/-/work_items/17422) dans GitLab 18.11 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `new_security_dashboard_vulnerabilities_by_identifier`. Activés par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/592130) dans GitLab 19.0. Suppression du feature flag `new_security_dashboard_vulnerabilities_by_identifier`.

{{< /history >}}

Le graphique **Top 10 des CWE** est disponible sur les tableaux de bord de groupe et de projet. Il affiche les 10 identifiants CWE les plus courants associés aux vulnérabilités ouvertes dans le groupe ou le projet.

Pour afficher les détails :

1. Survolez un point de données pour voir le nombre total de vulnérabilités de chaque type CWE.
1. Utilisez la liste déroulante pour filtrer par **Gravité** (par exemple, **Critique**, **Niveau moyen**, ou **Niveau élevé**).

![top 10 des CWE](img/group_security_dashboard_top_10_cwes_v18_11.png)

#### Entonnoir de triage et de correction SAST {#sast-triage-and-remediation-funnel}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239423) dans GitLab 19.3 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `security_dashboard_agentic_adoption`. Activés par défaut.

{{< /history >}}

Le graphique **Entonnoir de triage et de correction SAST** est disponible sur les tableaux de bord de groupe et de projet. Il montre la progression des vulnérabilités SAST critiques et élevées à travers le triage et la remédiation sur une période de 30, 60 ou 90 jours. La plage par défaut est de 30 jours.

L'entonnoir comporte jusqu'à quatre étapes. Chaque étape indique le nombre de vulnérabilités qui l'atteignent :

- **Vulnérabilités SAST critiques et élevées** : vulnérabilités détectées par SAST.
- **Vrai positif** : vulnérabilités confirmées comme de vrais positifs par [la détection de faux positifs SAST](../vulnerabilities/false_positive_detection.md).
- **Vulnérabilités liées à des MR générées par l'IA** : vulnérabilités avec une merge request créée par [Agentic SAST Vulnerability Resolution](../vulnerabilities/agentic_vulnerability_resolution.md).
- **Vulnérabilités corrigées** : vulnérabilités corrigées par une merge request fusionnée créée par l'IA.

Utilisez le sélecteur de période pour faire basculer l'entonnoir entre 30, 60 ou 90 jours.

![Entonnoir de triage et de correction SAST](img/sast_triage_and_remediation_funnel_v19_3.png)

Les trois dernières étapes utilisent GitLab Duo. Pour alimenter ces étapes :

- Activez GitLab Duo pour le groupe et ses projets.
- Configurez la [détection de faux positifs SAST](../vulnerabilities/false_positive_detection.md).
- Configurez la [résolution agentique des vulnérabilités SAST](../vulnerabilities/agentic_vulnerability_resolution.md).

Lorsqu'une de ces fonctionnalités est désactivée, l'entonnoir remplace les étapes concernées par un message expliquant quelle fonctionnalité activer. Le message diffère selon qu'il s'agit d'un tableau de bord de projet ou de groupe, et selon la fonctionnalité indisponible.

![Entonnoir de triage et de correction SAST avec des fonctionnalités désactivées](img/sast_triage_and_remediation_funnel_empty_state_v19_3.png)

### Filtrer l'ensemble du tableau de bord {#filter-the-entire-dashboard}

Vous pouvez filtrer les résultats à deux niveaux :

- **Filtres du tableau de bord** : s'appliquent à l'ensemble du tableau de bord. Tous les graphiques sont mis à jour lorsque vous utilisez ces filtres.
- **Chart and panel filters** : s'appliquent uniquement au graphique ou au panneau que vous consultez.

Les filtres disponibles pour le tableau de bord incluent :

- **Type de rapport** : filtrez par scanner, notamment SAST, DAST, analyse des dépendances et autres.
- **Projet** : limitez les résultats à des projets spécifiques. Disponible uniquement pour les tableaux de bord de sécurité de groupe.

Sur le tableau de bord de sécurité du groupe, vous pouvez également filtrer par :

- **Attributs de sécurité** : filtrez par les attributs de sécurité appliqués à vos projets, qui incluent des catégories pour l'impact métier, l'application, l'unité commerciale, l'exposition à Internet et la localisation. Ces filtres peuvent être inclusifs (en utilisant l'opérateur **fait partie de**) ou exclusifs (en utilisant l'opérateur **ne fait pas partie de**). Pour configurer vos attributs de sécurité et les appliquer aux projets, consultez [les attributs de sécurité](../attributes/_index.md).

Comportement des filtres du tableau de bord :

- Les filtres s'appliquent immédiatement à tous les graphiques et panneaux du tableau de bord.
- Les filtres que vous appliquez continuent de s'appliquer tout au long de votre session, sauf si vous les supprimez.
- Lorsque vous ouvrez un rapport de vulnérabilités depuis le tableau de bord, les filtres actifs sont automatiquement appliqués au rapport de vulnérabilités.

Pour appliquer un filtre à l'ensemble du tableau de bord :

1. Dans la barre de filtres en haut du tableau de bord, sélectionnez **Filter results...**.
1. Dans la liste déroulante, choisissez le type de filtre.
1. Sélectionnez une ou plusieurs valeurs de filtre.

### Exporter sous forme de fichier PDF {#export-as-pdf}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224664) dans GitLab 18.10 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `new_security_dashboard_pdf_export`. Désactivées par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/589201) dans GitLab 18.11.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/589201) dans GitLab 19.0. Suppression du feature flag `new_security_dashboard_pdf_export`.

{{< /history >}}

Vous pouvez exporter le tableau de bord de sécurité au format PDF pour l'utiliser dans des rapports et des présentations. L'export capture l'état actuel de tous les graphiques et panneaux du tableau de bord, y compris les filtres actifs.

Pour exporter le tableau de bord au format PDF :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Tableau de bord de sécurité**.
1. Facultatif. Appliquez des filtres pour personnaliser les données incluses dans l'export.
1. Sélectionnez **Exporter sous forme de fichier PDF**.

## Tableaux de bord de sécurité hérités {#legacy-security-dashboards}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Les clients GitLab Self-Managed qui n'ont pas activé la gestion avancée des vulnérabilités ne peuvent pas accéder aux derniers tableaux de bord de sécurité. Dans ce cas, vous avez toujours accès aux tableaux de bord de sécurité hérités.

Les tableaux de bord de sécurité permettent d'évaluer la posture de sécurité de vos applications. GitLab vous fournit un ensemble de métriques, d'évaluations et de graphiques pour les vulnérabilités détectées par les [scanners de sécurité](../detect/_index.md) exécutés sur votre projet. Le tableau de bord de sécurité fournit des données telles que :

- Tendances des vulnérabilités sur une période de 30, 60 ou 90 jours pour tous les projets d'un groupe
- Une note alphabétique pour chaque projet en fonction de la gravité des vulnérabilités
- Le nombre total de vulnérabilités détectées au cours des 365 derniers jours, y compris leur gravité

Utilisez les données du tableau de bord de sécurité pour améliorer votre posture de sécurité. Par exemple, la vue sur 365 jours montre quels jours ont connu un pic de vulnérabilités. Examinez les modifications de code de ces jours pour effectuer une analyse des causes profondes et définir de meilleures politiques afin de prévenir les vulnérabilités futures.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Security Dashboard - Advanced Security Testing](https://www.youtube.com/watch?v=Uo-pDns1OpQ).

## Prérequis pour les tableaux de bord hérités {#prerequisites-for-the-legacy-dashboards}

Pour afficher les tableaux de bord de sécurité, les éléments suivants sont requis :

- Vous devez disposer du rôle Developer pour le groupe ou le projet.
- Au moins un [scanner de sécurité](../detect/_index.md) configuré dans votre projet.
- Un scan de sécurité réussi effectué sur la [branche par défaut](../../project/repository/branches/default.md) de votre projet.
- Au moins 1 vulnérabilité détectée dans le projet.

> [!note]
> Les tableaux de bord de sécurité affichent les résultats des scans provenant du pipeline le plus récemment terminé sur la [branche par défaut](../../project/repository/branches/default.md). Les tableaux de bord sont mis à jour avec les résultats des pipelines terminés exécutés sur la branche par défaut ; ils n'incluent pas les vulnérabilités découvertes dans les pipelines d'autres branches non fusionnées.

## Consultation du tableau de bord de sécurité hérité {#viewing-the-legacy-security-dashboard}

Le tableau de bord de sécurité est accessible aux niveaux du projet, du groupe et du Security Center. Chaque tableau de bord offre un point de vue unique sur votre posture de sécurité.

### Tableau de bord de sécurité du projet {#project-security-dashboard-1}

Le tableau de bord de sécurité du projet affiche le nombre total de vulnérabilités détectées au fil du temps, avec jusqu'à 365 jours de données historiques pour un projet donné. Le tableau de bord est une vue historique des vulnérabilités ouvertes dans la branche par défaut. Les vulnérabilités ouvertes sont uniquement celles dont le statut est `Needs triage` ou `Confirmed` (les vulnérabilités dont le statut est `Dismissed` ou `Resolved` sont exclues).

Pour afficher le tableau de bord de sécurité d'un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Tableau de bord de sécurité**.
1. Filtrez et recherchez ce dont vous avez besoin.
   - Pour filtrer le graphique par gravité, sélectionnez le nom de la légende.
   - Pour afficher une période spécifique, utilisez les poignées de plage temporelle ({{< icon name="scroll-handle" >}}).
   - Pour afficher une zone spécifique du graphique, sélectionnez l'icône la plus à gauche ({{< icon name="marquee-selection" >}}) et faites glisser sur le graphique.
   - Pour réinitialiser la plage d'origine, sélectionnez **Remove Selection** ({{< icon name="redo" >}}).

![Tableau de bord de sécurité du projet](img/project_security_dashboard_v16_6.png)

#### Téléchargement du graphique de vulnérabilités {#downloading-the-vulnerability-chart}

Vous pouvez télécharger une image du graphique de vulnérabilités depuis le tableau de bord de sécurité du projet pour l'utiliser dans des documentations, des présentations, etc. Pour télécharger l'image du graphique de vulnérabilités :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Tableau de bord de sécurité**.
1. Sélectionnez **Save chart as an image** ({{< icon name="download" >}}).

Vous êtes invité à télécharger l'image au format SVG.

### Tableau de bord de sécurité du groupe {#group-security-dashboard-1}

Le tableau de bord de sécurité du groupe fournit une vue d'ensemble des vulnérabilités trouvées dans les branches par défaut de tous les projets d'un groupe et de ses sous-groupes. Le tableau de bord de sécurité du groupe fournit les éléments suivants :

- Tendances des vulnérabilités sur une période de 30, 60 ou 90 jours
- Une note alphabétique pour chaque projet du groupe en fonction de sa vulnérabilité ouverte de gravité la plus élevée. Les notes alphabétiques sont attribuées selon les critères suivants :

| Note | Description                                     |
| ----- | ----------------------------------------------- |
| **V** | Une ou plusieurs vulnérabilités `critical`          |
| **D** | Une ou plusieurs vulnérabilités `high` ou `unknown` |
| **C** | Une ou plusieurs vulnérabilités `medium`            |
| **B** | Une ou plusieurs vulnérabilités `low`               |
| **A** | Aucune vulnérabilité                            |

Pour afficher le tableau de bord de sécurité du groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurité** > **Tableau de bord de sécurité**.
1. Survolez le graphique **Vulnérabilités au fil du temps** pour obtenir plus de détails sur les vulnérabilités.
   - Vous pouvez afficher les tendances des vulnérabilités sur une période de 30, 60 ou 90 jours (la valeur par défaut est 90 jours).
   - Pour afficher des données agrégées au-delà d'une période de 90 jours, utilisez l'[API GraphQL `VulnerabilitiesCountByDay`](../../../api/graphql/reference/_index.md#vulnerabilitiescountbyday). GitLab conserve les données pendant 365 jours.

1. Sélectionnez les flèches sous la section **État de la sécurité du projet** pour voir quels projets correspondent à une note alphabétique particulière :
   - Vous pouvez voir combien de vulnérabilités d'une gravité particulière sont trouvées dans un projet
   - Vous pouvez sélectionner le nom d'un projet pour accéder directement à son tableau de bord de sécurité

![Tableau de bord de sécurité du groupe](img/group_security_dashboard_v16_6.png)

## Métriques de vulnérabilités dans le tableau de bord des flux de valeur {#vulnerability-metrics-in-the-value-streams-dashboard}

Des métriques de vulnérabilités supplémentaires sont disponibles dans le panneau de comparaison du [tableau de bord des flux de valeur](../../analytics/value_streams_dashboard.md), qui vous aide à comprendre l'exposition aux risques de sécurité dans le contexte des workflows de distribution logicielle de votre organisation.

## Sujets connexes {#related-topics}

- [Centre de sécurité](../security_center/_index.md)
- [Rapports de vulnérabilités](../vulnerability_report/_index.md)
- [Page de vulnérabilité](../vulnerabilities/_index.md)
- [Résolution automatique des vulnérabilités](../policies/vulnerability_management_policy.md)
