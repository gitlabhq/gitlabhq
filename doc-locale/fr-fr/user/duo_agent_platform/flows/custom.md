---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flows personnalisés
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM : Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- Introduction en tant que [version expérimentale](../../../policy/development_stages_support.md) dans GitLab 18.4 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `ai_catalog_flows`. Désactivés par défaut.
- Passé en [version bêta](../../../policy/development_stages_support.md) dans GitLab 18.7.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/569060) dans GitLab 18.7.
- [Activé sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/work_items/569060) dans GitLab 18.8.
- Le feature flag `ai_catalog_flows` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216969) dans GitLab 18.8.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797) du déclencheur Événements du pipeline dans GitLab 18.9 en tant que [version expérimentale](../../../policy/development_stages_support.md) avec un [feature flag](../../../administration/feature_flags/_index.md) nommé `ai_flow_trigger_pipeline_hooks`. Désactivés par défaut.
- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20743) de l'activation directement dans les projets en tant que chargé de maintenance dans GitLab 18.10 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `ai_catalog_project_level_enablement`. Activé par défaut sur GitLab.com, GitLab Self-Managed et GitLab Dedicated.
- Disponible sur l’édition Gratuite sur GitLab.com avec des GitLab Credits dans GitLab 18.10.
- Le feature flag `ai_catalog_project_level_enablement` supprimé dans GitLab 18.11.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454) du type d'événement de déclencheur **Requête de fusion prête** dans GitLab 19.0 avec un [feature flag](../../../administration/feature_flags/_index.md) nommé `merge_request_ready_flow_trigger`. Désactivés par défaut.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/592455) du type d'événement de déclencheur **Conflit de code dans une merge request** dans GitLab 19.1.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237081) du type d'événement de déclencheur **Requête de fusion** avec l'action **Approuvé** dans GitLab 19.1.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/work_items/587272) du feature flag `ai_flow_trigger_pipeline_hooks` dans GitLab 19.1.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/599985) du type d'événement de déclencheur **Élément de travail créé** dans GitLab 19.1.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/598421) du type d'événement de déclencheur **Requête de fusion prête** dans GitLab 19.1. Le feature flag `merge_request_ready_flow_trigger` a été supprimé.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/599983) du type d'événement de déclencheur **Statut de l'élément de travail modifié** dans GitLab 19.2.
- Le feature flag `ai_catalog_flows` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239459) dans GitLab 19.2.
- Passé en [disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/602415) dans GitLab 19.2.

{{< /history >}}

Les flows personnalisés sont des workflows alimentés par l'IA que vous créez et configurez pour automatiser des tâches complexes à plusieurs étapes dans vos projets GitLab.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../_index.md#prerequisites).
- Avoir les [flows personnalisés activés](#turn-custom-flows-on-or-off).

## Visibilité des flows {#flow-visibility}

{{< history >}}

- Les rôles pouvant consulter les flows privés ont été [étendus](https://gitlab.com/gitlab-org/gitlab/-/work_items/582507) dans GitLab 18.7.

{{< /history >}}

Lorsque vous créez un flow personnalisé, vous sélectionnez un projet pour le gérer et choisissez si le flow est public ou privé.

Flows publics :

- Peuvent être consultés par n'importe qui sur l'instance et peuvent être activés dans tout projet répondant aux prérequis.

Flows privés :

- Ne peuvent être consultés que par :
  - Les membres du projet gérant qui ont le rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner.
  - Les utilisateurs ayant le rôle Owner pour le groupe principal.
- Ne peuvent pas être activés dans des projets autres que le projet gérant, ni dans des groupes autres que le groupe principal.

Vous ne pouvez pas changer un flow public en privé si le flow est activé.

## Afficher les flows pour votre projet {#view-the-flows-for-your-project}

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour afficher la liste des flows associés à votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Flows**.
   - Pour afficher les flows activés dans le projet, sélectionnez l'onglet **Activé**.
   - Pour afficher les flows gérés par le projet, sélectionnez l'onglet **Gérés**.

Sélectionnez un flow pour afficher ses détails.

## Créer un flow {#create-a-flow}

Vous pouvez créer un flow depuis un projet ou en utilisant le catalogue d'IA.

> [!note]
> Vous ne pouvez pas définir un flow personnalisé pour appeler un agent personnalisé spécifique depuis un projet ou le catalogue d'IA. Les flows personnalisés créent et utilisent leurs propres agents en fonction de leur configuration YAML.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

{{< tabs >}}

{{< tab title="Depuis un projet" >}}

Pour créer un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Flows**.
1. Sélectionnez **Nouveau flow**.
1. Sous **Informations de base** :
   1. Dans **Nom affiché**, saisissez un nom.
   1. Dans **Description**, saisissez une description.
1. Sous **Visibilité et accès**, pour **Visibilité**, sélectionnez **Privé** ou **Public**.
1. Sous **Configuration** :
   1. Sélectionnez **Flux**.
   1. Dans l'éditeur, saisissez la configuration de votre flow :

      - Pour plus d'informations sur la syntaxe et le schéma YAML, consultez [le schéma YAML de flow personnalisé](custom_flows_schema.md).
1. Sélectionnez **Créer un flow**.

{{< /tab >}}

{{< tab title="Depuis le catalogue d'IA" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** > **Explorer**.
1. Sélectionnez **Catalogue d'IA**, puis sélectionnez l'onglet **Flows**.
1. Sélectionnez **Nouveau flow**.
1. Sous **Informations de base** :
   1. Dans **Nom affiché**, saisissez un nom.
   1. Dans **Description**, saisissez une description.
1. Sous **Visibilité et accès**, pour **Visibilité**, sélectionnez **Privé** ou **Public**.
1. Sous **Configuration** :
   1. Sélectionnez **Flux**.
   1. Dans l'éditeur, saisissez la configuration de votre flow :

      - Pour plus d'informations sur la syntaxe et le schéma YAML, consultez [le schéma YAML de flow personnalisé](custom_flows_schema.md).
1. Sélectionnez **Créer un flow**.

{{< /tab >}}

{{< /tabs >}}

Le flow apparaît dans le catalogue d'IA.

## Activer un flow {#enable-a-flow}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/600526) de l'activation d'un flow public pour plusieurs projets dans GitLab 19.2 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `ai_catalog_bulk_item_consumer_create`. Activé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Activez un flow pour le déclencher depuis un ticket, une merge request ou une discussion.

Lorsque vous activez un flow dans un projet :

- Le flow est activé dans le groupe principal de ce projet en même temps.
- Vous ajoutez un [déclencheur](../triggers/_index.md) pour spécifier quels événements déclenchent le flow. Certains événements déclencheurs impliquent l'utilisateur du compte de service. Pour plus d'informations, consultez [l'identité composite](../composite_identity.md).

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

{{< tabs >}}

{{< tab title="Depuis le projet gérant" >}}

Pour activer un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Flows**.
1. Sélectionnez l'onglet **Gérés**, puis sélectionnez le flow que vous souhaitez activer.
1. Dans le coin supérieur droit, sélectionnez **Activer**.
1. Sous **Projet**, sélectionnez le projet dans lequel vous souhaitez activer le flow.
1. Pour **Ajouter des déclencheurs**, sélectionnez :
   - Les [types d'événements qui déclenchent le flow](../triggers/_index.md#trigger-event-types).
   - Si nécessaire pour le type d'événement déclencheur, une action d'événement déclencheur.
1. Sélectionnez **Activer**.

{{< /tab >}}

{{< tab title="Depuis le catalogue d'IA" >}}

Pour activer un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** > **Explorer**.
1. Sélectionnez **Catalogue d'IA**, puis sélectionnez l'onglet **Flows**.
1. Sélectionnez le flow que vous souhaitez activer.
1. Dans le coin supérieur droit, sélectionnez **Activer**.
1. Sous **Projet**, sélectionnez le projet dans lequel vous souhaitez activer le flow.

   Pour activer un flow public pour plusieurs projets, depuis la liste déroulante **Projet**, sélectionnez les projets concernés. Vous pouvez sélectionner jusqu'à 100 projets.

1. Pour **Ajouter des déclencheurs**, sélectionnez :
   - Les [types d'événements qui déclenchent le flow](../triggers/_index.md#trigger-event-types).
   - Si nécessaire pour le type d'événement déclencheur, une action d'événement déclencheur.
1. Sélectionnez **Activer**.

{{< /tab >}}

{{< /tabs >}}

Le flow apparaît dans les pages **IA** > **Flows** du groupe et du projet. Les membres de tout projet du groupe principal peuvent désormais activer le flow dans leur projet.

Un compte de service est créé dans le groupe. Le nom du compte suit cette convention de nommage : `ai-<flow>-<group>`.

### Activer dans un projet {#enable-in-a-project}

Si un flow est déjà activé dans un groupe principal, vous pouvez l'activer dans les projets du groupe.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.
- Le flow doit être activé dans le groupe principal du projet.

Pour activer un flow dans un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Flows**.
1. Dans le coin supérieur droit, sélectionnez **Enable flow from group**.
1. Dans la liste déroulante, sélectionnez le flow que vous souhaitez activer.
1. Pour **Ajouter des déclencheurs**, sélectionnez :
   - Les [types d'événements qui déclenchent le flow](../triggers/_index.md#trigger-event-types).
   - Si nécessaire pour le type d'événement déclencheur, une action d'événement déclencheur.
1. Sélectionnez **Activer**.

Le flow apparaît dans la liste **IA** > **Flows** du projet.

Le compte de service du groupe principal est ajouté au projet. Ce compte se voit attribuer le rôle Developer.

## Désactiver un flow {#disable-a-flow}

Prérequis :

- Pour les groupes, vous devez avoir le rôle Maintainer ou Owner.
- Pour les projets, vous devez avoir le rôle Maintainer ou Owner.

Pour désactiver un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Flows**.
1. Trouvez le flow que vous souhaitez supprimer et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Désactiver**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Désactiver**.

Le flow n'apparaît plus dans le projet ou le groupe et ne peut plus être exécuté. Tous les comptes de service ou déclencheurs associés au flow sont également supprimés.

## Utiliser un flow {#use-a-flow}

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- Le flow doit être activé dans le projet.

Pour utiliser un flow :

1. Dans votre projet, ouvrez un ticket, une merge request ou un epic.
1. Pour déclencher le flow, mentionnez, assignez ou demandez une revue à l'utilisateur du compte de service du flow. Par défaut, l'utilisateur porte le nom `ai-<flow>-<group>`.

   Par exemple, si vous activez un flow appelé `Security scanner` dans le groupe `GitLab Duo`, l'utilisateur du compte de service est `ai-security-scanner-gitlab-duo`.
1. Une fois que le flow a terminé la tâche, vous voyez une confirmation, ainsi qu'un changement prêt à fusionner ou un commentaire en ligne.

> [!warning]
> Le compte de service peut accéder à tous les projets qui répondent aux deux critères suivants :
>
> - Vous y avez accès.
> - Le flow y a été ajouté.

## Dupliquer un flow {#duplicate-a-flow}

Pour apporter des modifications à un flow sans écraser l'original, créez une copie d'un flow existant.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour dupliquer un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** > **Explorer**.
1. Sélectionnez **Catalogue d'IA**, puis sélectionnez l'onglet **Flows**.
1. Sélectionnez le flow que vous souhaitez dupliquer.
1. Dans le coin supérieur droit, sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Dupliquer**.
1. Facultatif. Modifiez les champs que vous souhaitez changer.
1. Sélectionnez **Créer un flow**.

## Modifier un flow {#edit-a-flow}

Modifiez un flow pour changer sa configuration.

Prérequis :

- Vous devez être membre du projet gérant et avoir le rôle Maintainer ou Owner.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Flows**.
1. Sélectionnez le flow que vous souhaitez modifier.
1. Dans le coin supérieur droit, sélectionnez **Éditer**.
1. Modifiez les champs que vous souhaitez changer, puis sélectionnez **Sauvegarder les modifications**.

## Masquer un flow {#hide-a-flow}

Masquez un flow pour le retirer du catalogue d'IA.

Une fois que vous avez masqué un flow, les utilisateurs ne peuvent plus l'activer. Cependant, ils peuvent toujours le déclencher dans les groupes et projets où il est déjà activé.

Prérequis :

- Vous devez être membre du projet gérant et avoir le rôle Maintainer ou Owner.

Pour masquer un flow :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Flows**.
1. Trouvez le flow que vous souhaitez masquer et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Masquer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Confirmer**.

## Supprimer un flow {#delete-a-flow}

Supprimez un flow pour le retirer définitivement de l'instance.

Prérequis :

- Être administrateur.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Flows**.
1. Trouvez le flow que vous souhaitez supprimer et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer**.

## Partage de groupe et flows {#group-sharing-and-flows}

Lorsque vous activez un flow dans un groupe, un compte de service associé est automatiquement créé. Le compte de service :

- Utilise [l'authentification par identité composite](../composite_identity.md) pour garantir que le flow ne peut jamais accéder à plus que l'utilisateur qui l'exécute.
- Est ajouté en tant que membre à tout projet sous le groupe principal qui active le flow, afin que le flow ne puisse pas accéder aux ressources en dehors de ce groupe.
- Bénéficie d'un accès aux groupes supplémentaires partagés avec le groupe principal. Le compte de service est traité comme n'importe quel autre membre du groupe pour le partage de groupe.

> [!note]
> Le partage de comptes de service de flow entre plusieurs groupes principaux peut créer des autorisations d'accès non souhaitées et des risques de sécurité.

## Activer ou désactiver les flows personnalisés {#turn-custom-flows-on-or-off}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0.

{{< /history >}}

Par défaut, les flows personnalisés sont activés. Vous pouvez les activer ou les désactiver pour un groupe principal ou pour une instance.

Lorsque les flows personnalisés sont désactivés :

- Les utilisateurs ne peuvent pas créer, activer, désactiver ou exécuter des flows personnalisés.
- Les flows personnalisés existants ne sont plus visibles dans le projet sous **IA** > **Flows** > **Activé**.
- Les flows personnalisés créés dans le projet apparaissent sous **IA** > **Flows** > **Gérés**, mais ne peuvent pas être exécutés.
- Les [flows par défaut](foundational_flows/_index.md) restent disponibles.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Agents et flux personnalisés et externes**, cochez ou décochez la case **Autoriser les flux personnalisés**.
1. Sélectionnez **Enregistrer les modifications**.

Ce paramètre s'applique en cascade à tous les sous-groupes du groupe.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Être administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Agents et flux personnalisés et externes**, cochez ou décochez la case **Autoriser les flux personnalisés**.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque le paramètre au niveau de l'instance est désactivé, les paramètres au niveau du groupe ne peuvent pas le remplacer.

{{< /tab >}}

{{< /tabs >}}
