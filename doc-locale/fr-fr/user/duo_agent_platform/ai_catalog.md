---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez, activez et gérez des agents et des flows depuis un catalogue centralisé."
title: "Catalogue d'IA"
---

{{< details >}}

- Niveau :  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM :  Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) dans GitLab 18.5 [avec un flag](../../administration/feature_flags/_index.md) nommé `global_ai_catalog`. Activé sur GitLab.com en tant qu'[expérience](../../policy/development_stages_support.md).
- La prise en charge des agents externes a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610) dans GitLab 18.6 avec un flag nommé `ai_catalog_third_party_flows`. Activé sur GitLab.com en tant qu'[expérience](../../policy/development_stages_support.md).
- [Passé](https://gitlab.com/gitlab-org/gitlab/-/issues/568176) en version bêta dans GitLab 18.7.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.
- Le feature flag `global_ai_catalog` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135) dans la version 18.10.
- Disponible sur le niveau Free sur GitLab.com avec des GitLab Credits dans GitLab 18.10.

{{< /history >}}

Le catalogue d'IA est une liste centrale d'agents et de flows. Ajoutez ces agents et flows à votre projet pour commencer à orchestrer des tâches d'IA agentique.

Utilisez le catalogue d'IA pour :

- Découvrez les agents et les flows créés par l'équipe GitLab et les membres de la communauté.
- Créez des agents personnalisés et des flows, et partagez-les avec d'autres utilisateurs.
- Activez des agents et des flows dans vos projets pour les utiliser sur toute la plateforme GitLab Duo Agent Platform.

## Afficher le catalogue d'IA {#view-the-ai-catalog}

{{< history >}}

- Possibilité d'utiliser la barre latérale GitLab Duo pour afficher le catalogue d'IA [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/592493) dans GitLab 18.11.

{{< /history >}}

Prérequis :

- Respectez les [prérequis de la plateforme GitLab Duo Agent Platform](_index.md#prerequisites).
- Sur GitLab Self-Managed, [activez GitLab Duo pour l'instance](turn_on_off.md#for-an-instance).
- Pour activer des agents et des flows depuis le catalogue d'IA :
  - Dans un groupe, vous devez disposer du rôle Maintainer ou Owner.
  - Dans un projet, vous devez disposer du rôle Maintainer ou Owner.

Pour afficher le catalogue d'IA, vous pouvez :

- Utiliser la barre supérieure :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** > **Explorer**.
  1. Sélectionnez **Catalogue d'IA**.

- Utiliser la barre latérale GitLab Duo :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
  1. Dans la barre latérale GitLab Duo, sélectionnez **Catalogue IA GitLab Duo** ({{< icon name="tanuki-ai" >}}).

Une liste d'agents s'affiche.

Sur GitLab Self-Managed, les agents suivants ne sont pas affichés dans le catalogue d'IA :

- Les agents personnalisés créés sur GitLab.com.
- Les agents externes gérés par GitLab qui n'ont pas été [ajoutés à l'instance](agents/external.md#add-gitlab-managed-agents-to-other-instances).

Pour afficher les flows disponibles, sélectionnez l'onglet **Flux**.

## Versions des agents et des flows {#agent-and-flow-versions}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/20022) dans GitLab 18.7.

{{< /history >}}

Chaque agent personnalisé et flow dans le catalogue d'IA conserve un historique des versions. Lorsque vous modifiez la configuration d'un élément, GitLab crée automatiquement une nouvelle version. Les agents par défaut et les flows n'utilisent pas la gestion des versions.

GitLab utilise la gestion sémantique de version pour indiquer la portée des modifications. Par exemple, un agent peut avoir un numéro de version tel que `1.0.0` ou `1.1.0`. GitLab gère la gestion sémantique de version automatiquement. Les mises à jour des agents ou des flows incrémentent toujours la version mineure.

La gestion des versions garantit que vos projets et groupes continuent d'utiliser une configuration stable et testée d'un agent ou d'un flow. Cela évite que des modifications inattendues n'affectent vos workflows.

### Création de versions {#creating-versions}

GitLab crée une version lorsque vous :

- Mettez à jour le prompt système d'un agent personnalisé.
- Modifiez la configuration d'un agent externe ou d'un flow.

Pour garantir un comportement cohérent, les versions sont immuables.

### Épinglage de version {#version-pinning}

{{< history >}}

- Le projet qui gère un agent ou un flow utilise toujours la dernière version de cet élément, [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/583024) dans GitLab 18.10.

{{< /history >}}

Lorsque vous activez un élément du catalogue d'IA :

- Dans un groupe, GitLab épingle la dernière version.
- Dans un projet qui ne gère pas cet élément, GitLab épingle la même version que le groupe principal du projet.

L'épinglage de version signifie que :

- Votre projet ou groupe utilise une version fixe de l'élément.
- Les mises à jour de l'agent ou du flow dans le catalogue d'IA n'affectent pas votre configuration.
- Vous contrôlez le moment auquel adopter de nouvelles versions.

Cette approche offre stabilité et prévisibilité pour vos workflows optimisés par l'IA.

Lorsque vous activez un élément du catalogue d'IA dans le projet qui gère cet élément, GitLab n'épingle pas de version. À la place, le projet gestionnaire utilise toujours la dernière version de l'élément.

Si vous avez activé un agent ou un flow dans son projet gestionnaire avant GitLab 18.10, votre configuration reste à la version épinglée.

Après avoir effectué votre première mise à jour vers la dernière version, GitLab utilise automatiquement la dernière version à partir de ce moment.

### Afficher la version actuelle {#view-the-current-version}

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner.

Pour afficher la version actuelle d'un agent ou d'un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez :
   - **IA** > **Agents**
   - **IA** > **Flux**
1. Sélectionnez l'agent ou le flow pour afficher ses détails.

La page de détails affiche :

- La version épinglée utilisée par votre projet ou groupe.
- L'identifiant de version. Par exemple, `1.2.0`.
- Les détails de la configuration de cette version spécifique.

### Mettre à jour vers la dernière version {#update-to-the-latest-version}

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner.

Pour que votre groupe ou projet utilise la dernière version d'un agent ou d'un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez :
   - **IA** > **Agents**
   - **IA** > **Flux**
1. Sélectionnez l'agent ou le flow que vous souhaitez mettre à jour.
1. Examinez attentivement la dernière version. Pour mettre à jour, sélectionnez **Voir la dernière version** > **Update to `<x.y.z>`**.

## Restreindre le catalogue d'IA à une hiérarchie de groupes {#restrict-the-ai-catalog-to-a-group-hierarchy}

{{< details >}}

- Offre :  GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617) dans GitLab 19.0.

{{< /history >}}

Dans un groupe principal, vous pouvez restreindre le catalogue d'IA afin que, pour un projet dans cette hiérarchie de groupes, les utilisateurs puissent uniquement voir, activer et exécuter :

- Les agents par défaut et flows maintenus par GitLab.
- Les agents et flows publics appartenant à des projets dans la même hiérarchie de groupe principal.
- Les agents et flows privés appartenant au projet lui-même.

Les agents et flows appartenant à des projets en dehors de la hiérarchie sont :

- Masqués du catalogue d'IA.
- Bloqués pour toute activation.
- Bloqués pour toute exécution, même si un projet les a précédemment activés.

Vous pouvez configurer ce paramètre uniquement sur un groupe principal. Il s'applique à tous les projets de cette hiérarchie. Les modifications apportées à ce paramètre sont enregistrées dans le journal d'audit.

Prérequis :

- Vous devez disposer du rôle Owner pour le groupe principal.

Pour restreindre le catalogue d'IA à votre hiérarchie de groupes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Dans la section **Données et vie privée**, sous **Catalogue d'IA**, cochez la case **Restrict the AI Catalog to this group**.
1. Sélectionnez **Sauvegarder les modifications**.

## Sujets connexes {#related-topics}

- [Agents](agents/_index.md)
- [Agents externes](agents/external.md)
