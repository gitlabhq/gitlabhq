---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Inventaire de sécurité
description: "Visibilité au niveau du groupe des ressources, de la couverture par les scanners et des vulnérabilités."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16484) en tant que [version bêta](../../../policy/development_stages_support.md) dans GitLab 18.2 avec un flag nommé `security_inventory_dashboard`. Activés par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619) dans GitLab 18.9. Le feature flag `security_inventory_dashboard` a été supprimé.
- Les comptages de vulnérabilités ont [changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/600455) dans GitLab 19.2 pour exclure les vulnérabilités qui ne sont plus détectées, alignant ainsi l'inventaire de sécurité avec le tableau de bord de sécurité.

{{< /history >}}

Utilisez l'inventaire de sécurité pour visualiser les ressources que vous devez sécuriser et comprendre les actions à entreprendre pour améliorer la sécurité. Une expression courante en sécurité est : « vous ne pouvez pas sécuriser ce que vous ne pouvez pas voir ». L'inventaire de sécurité offre une visibilité sur la posture de sécurité des groupes principaux de votre organisation, vous aide à identifier les lacunes de couverture et vous permet de prendre des décisions de priorisation efficaces et basées sur les risques.

L'inventaire de sécurité affiche :

- Vos groupes, sous-groupes et projets.
- La couverture des scanners de sécurité pour chaque projet, quelle que soit la manière dont le scanner est activé. La couverture par les outils reflète le statut d'analyse du pipeline le plus récent sur la branche par défaut. Les scanners de sécurité comprennent :
  - Test statique de sécurité des applications (SAST)
  - Analyse des dépendances
  - Analyse des conteneurs
  - Détection des secrets
  - Test dynamique de sécurité des applications (DAST)
  - Analyse de l'Infrastructure as Code (IaC)
- Le nombre de vulnérabilités dans chaque groupe ou projet, trié par niveau de gravité. Le comptage exclut les vulnérabilités qui ne sont plus détectées.

Suivez le développement de l'inventaire de sécurité dans l'[epic 16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939). Partagez [vos commentaires](https://gitlab.com/gitlab-org/gitlab/-/issues/553062) au fur et à mesure du développement de cette fonctionnalité.

## Afficher l'inventaire de sécurité {#view-the-security-inventory}

Prérequis :

- Vous devez disposer du rôle Responsable sécurité, Développeur, Mainteneur ou Propriétaire dans le groupe pour afficher l'inventaire de sécurité.

Pour afficher l'inventaire de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Inventaire de sécurité**.
1. Effectuez l'une des actions suivantes :
   - Pour afficher les sous-groupes, les projets et les ressources de sécurité d'un groupe, sélectionnez le groupe.
   - Pour afficher la couverture du scanner d'un groupe ou d'un projet, recherchez le groupe ou le projet.

## Couverture des scanners {#scanner-coverage}

{{< history >}}

- Le statut Périmées a été [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/596022) dans GitLab 19.0

{{< /history >}}

Le statut du scanner de sécurité est évalué lorsqu'un pipeline de branche par défaut se termine. Chaque scanner de sécurité affiche l'un des statuts de couverture suivants pour chaque projet ou groupe :

- **Non activé** : le scanner n'est pas configuré.
- **Activé** : le scanner est configuré et s'est exécuté avec succès.
- **Échec** : le scanner a été exécuté mais ne s'est pas terminé avec succès.
- **Périmées** : un scanner précédemment activé n'a pas été exécuté lors des trois derniers pipelines consécutifs.

## Filtrer les projets dans l'inventaire de sécurité {#filter-projects-in-the-security-inventory}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/552224) dans GitLab 18.5 [avec le feature flag](../../../administration/feature_flags/_index.md) `security_inventory_filtering`. Activés par défaut.
- Le feature flag `security_inventory_filtering` a été supprimé dans GitLab 19.4.

{{< /history >}}

Vous pouvez filtrer les projets dans l'inventaire de sécurité pour vous concentrer sur des domaines d'intérêt spécifiques. Les filtres suivants sont disponibles :

- **Nombre de vulnérabilités** : filtrez les projets en fonction du nombre de vulnérabilités identifiées. Par exemple, affichez les projets avec `critical vulnerabilities ≥ 10`.
- **Couverture par les outils** : filtrez les projets selon le statut des analyseurs de sécurité (comme **activé**, **non activé** ou **en échec**). Par exemple, affichez les projets où `Advanced SAST = enabled`.
- **Nom du projet** : recherchez des projets spécifiques par nom.

Ces filtres vous permettent d'affiner les résultats dans les inventaires volumineux et facilitent l'identification des projets nécessitant une attention immédiate.

## Sujets connexes {#related-topics}

- [Tableau de bord de sécurité](../security_dashboard/_index.md)
- [Rapports de vulnérabilités](../vulnerability_report/_index.md)
- Références GraphQL :
  - [AnalyzerGroupStatusType](../../../api/graphql/reference/_index.md#analyzergroupstatustype) \- Comptages pour chaque statut d'analyseur dans le groupe et les sous-groupes.
  - [AnalyzerProjectStatusType](../../../api/graphql/reference/_index.md#analyzerprojectstatustype) \- Statut de l'analyseur (succès/échec) pour les projets.
  - [VulnerabilityNamespaceStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitynamespacestatistictype) \- Comptages pour chaque gravité de vulnérabilité dans le groupe et ses sous-groupes.
  - [VulnerabilityStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitystatistictype) \- Comptages pour chaque gravité de vulnérabilité dans le projet.

## Dépannage {#troubleshooting}

Lorsque vous utilisez l'inventaire de sécurité, vous pouvez rencontrer les problèmes suivants :

### Élément de menu Inventaire de sécurité manquant {#security-inventory-menu-item-missing}

Certains utilisateurs ne disposent pas des autorisations requises pour accéder à l'élément de menu **Inventaire de sécurité**. L'élément de menu s'affiche uniquement pour les groupes lorsque l'utilisateur authentifié dispose du rôle Responsable sécurité, Développeur, Mainteneur ou Propriétaire.
