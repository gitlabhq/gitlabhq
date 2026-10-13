---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Attributs de sécurité
description: "Les attributs de sécurité permettent aux équipes de sécurité d'appliquer des labels de métadonnées personnalisés aux projets et aux groupes, ce qui leur permet de filtrer et de hiérarchiser les risques de sécurité en fonction du contexte métier."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18010) dans GitLab 18.5 avec les flags nommés `security_context_labels` et `security_categories_and_attributes`. Désactivées par défaut. Cette fonctionnalité a été introduite en [version bêta](../../../policy/development_stages_support.md)
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/551226) dans GitLab 18.6.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619) dans GitLab 18.9. Suppression du feature flag `security_inventory_dashboard`.

{{< /history >}}

Les équipes de sécurité peuvent désormais appliquer des métadonnées spécifiques à leur organisation et à leurs besoins métier aux projets à l'aide des attributs de sécurité.

Les attributs de sécurité sont organisés par catégories selon les critères suivants :

- Impact métier
- Application
- Unité commerciale
- Exposition Internet
- Emplacement

En appliquant ces attributs à l'ensemble de vos projets, vous pouvez identifier beaucoup plus rapidement les projets nécessitant une action, en fonction de la posture de risque et des besoins métier de votre organisation. Grâce aux attributs de sécurité, vous pouvez :

- Identifier les projets critiques qui nécessitent une couverture d'analyse renforcée.
- Examiner la couverture d'analyse pour chaque application ou unité commerciale.
- Localiser les projets qui contribuent aux applications publiquement accessibles et exposées.

Suivez le développement de l'inventaire de sécurité dans l'[epic 16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939). Partagez [vos commentaires](https://gitlab.com/gitlab-org/gitlab/-/issues/553062) au fur et à mesure du développement de cette fonctionnalité.

## Gérer les attributs de sécurité pour les groupes {#manage-security-attributes-for-groups}

Prérequis :

- Vous devez disposer du rôle Responsable sécurité, Maintainer ou Owner dans le groupe principal (espace de nommage) pour gérer les attributs de sécurité.

Pour gérer les attributs de sécurité d'un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.

## Gérer les attributs de sécurité pour les projets {#manage-security-attributes-for-projects}

Prérequis :

- Vous devez disposer du rôle Responsable sécurité, Maintainer ou Owner dans le groupe principal (espace de nommage) pour gérer les attributs de sécurité.

Pour gérer les attributs de sécurité d'un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Sélectionnez l'onglet **Attributs de sécurité**.

## Sujets connexes {#related-topics}

- [Inventaire de sécurité](../security_inventory/_index.md)
- [Tableau de bord de sécurité](../security_dashboard/_index.md)
- [Rapports de vulnérabilité](../vulnerability_report/_index.md)

## Dépannage {#troubleshooting}

Lorsque vous utilisez les attributs de sécurité, vous pouvez rencontrer les problèmes suivants.

### Élément de menu Configuration de la sécurité manquant {#security-configuration-menu-item-missing}

Les utilisateurs peuvent ne pas disposer des autorisations requises pour accéder à l'élément de menu **Configuration de la sécurité**, même s'ils sont Responsable sécurité, Maintainer ou Owner dans ce groupe.

L'élément de menu s'affiche uniquement pour les groupes lorsque l'utilisateur authentifié dispose du rôle Responsable sécurité, Maintainer ou Owner dans le groupe principal (espace de nommage) qui contient le sous-groupe.

Pour gérer les attributs de sécurité, demandez à un mainteneur d'effectuer les modifications de configuration ou sollicitez le rôle Maintainer auprès de votre administrateur.
