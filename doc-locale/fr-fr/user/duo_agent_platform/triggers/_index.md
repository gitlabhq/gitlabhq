---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créez et gérez des déclencheurs pour contrôler le moment où les flows s'exécutent dans votre projet."
title: Déclencheurs
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 18.3 [avec un flag](../../../administration/feature_flags/_index.md) nommé `ai_flow_triggers`. Activé par défaut.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634) dans GitLab 18.8 pour nécessiter un [flag](../../../administration/feature_flags/_index.md) supplémentaire nommé `ai_catalog_create_third_party_flows`. Désactivé par défaut.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.

{{< /history >}}

> [!flag]
> Pour modifier l'emplacement de votre fichier de configuration de flow, vous devez activer un feature flag. Pour plus d'informations, consultez l'historique.

Un déclencheur détermine le moment où un flow ou un agent externe s'exécute. Un déclencheur ne peut pas être créé pour un agent personnalisé ou un agent par défaut.

Par exemple, vous pouvez spécifier des flows à déclencher lorsque vous les mentionnez dans une discussion, ou lorsque vous les assignez comme relecteur.

## Créer un déclencheur {#create-a-trigger}

{{< history >}}

- Les types d'événements **Assigner** et **Assigner un relecteur** [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/567787) dans GitLab 18.5.
- Le type d'événement déclencheur Événements du pipeline [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797) dans GitLab 18.9 en tant qu'[expérience](../../../policy/development_stages_support.md) avec un [flag](../../../administration/feature_flags/_index.md) nommé `ai_flow_trigger_pipeline_hooks`. Désactivé par défaut.
- Le type d'événement déclencheur **Merge request prête** [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454) dans GitLab 19.0 avec un [flag](../../../administration/feature_flags/_index.md) nommé `merge_request_ready_flow_trigger`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour créer un déclencheur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Déclencheurs**.
1. Sélectionnez **Nouveau déclencheur de flow**.
1. Dans **Description**, saisissez une description pour le déclencheur.
1. Dans la liste déroulante **Types d'événements**, sélectionnez un ou plusieurs types d'événements :
   - **Mentionne** : Lorsque l'utilisateur du compte de service est mentionné dans un commentaire sur un ticket ou une merge request.
   - **Assigner** : Lorsque l'utilisateur du compte de service est assigné à un ticket ou une merge request.
   - **Assigner un relecteur** : Lorsque l'utilisateur du compte de service est assigné comme relecteur à une merge request.
   - **Événements du pipeline** : Lorsqu'un pipeline change d'état. Les états possibles sont `created`, `started`, `succeeded` et `failed`.
   - **Merge request prête** : Lorsqu'une merge request en brouillon est marquée comme prête pour la relecture.
1. Dans la liste déroulante **Compte de service**, sélectionnez un utilisateur comme [identité composite](../composite_identity.md).
1. Pour **Source de configuration**, sélectionnez l'une des options suivantes :
   - **Catalogue d'IA** : Parmi les flows configurés pour ce projet, sélectionnez un flow que le déclencheur doit exécuter.
   - **Chemin de configuration** : Saisissez le chemin vers le fichier de configuration du flow (par exemple, `.gitlab/duo/flows/claude.yaml`). Pour afficher cette option, le flag `ai_catalog_create_third_party_flows` doit être activé.
1. Sélectionnez **Créer un déclencheur de flow**.

Le déclencheur apparaît maintenant dans **IA** > **Déclencheurs**.

### Modifier un déclencheur {#edit-a-trigger}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Déclencheurs**.
1. Pour le déclencheur que vous souhaitez modifier, sélectionnez **Modifier le déclencheur de flow** ({{< icon name="pencil" >}}).
1. Effectuez les modifications et sélectionnez **Sauvegarder les modifications**.

### Supprimer un déclencheur {#delete-a-trigger}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Déclencheurs**.
1. Pour le déclencheur que vous souhaitez modifier, sélectionnez **Supprimer le déclencheur de flow** ({{< icon name="remove" >}}).
1. Dans la boîte de dialogue de confirmation, sélectionnez **OK**.
