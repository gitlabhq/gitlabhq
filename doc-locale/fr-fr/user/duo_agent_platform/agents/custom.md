---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agents personnalisés
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) dans GitLab 18.5 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `global_ai_catalog`. Activé sur GitLab.com.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/580307) de l'activation dans les groupes dans GitLab 18.7 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `ai_catalog_agents`. Activé sur GitLab.com.
- [Passé](https://gitlab.com/gitlab-org/gitlab/-/issues/568176) en version bêta dans GitLab 18.7.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217802) du feature flag `ai_catalog_agents` dans GitLab 18.9.
- Le feature flag `global_ai_catalog` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135) dans la version 18.10.
- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20743) de l'activation directement dans les projets en tant que chargé de maintenance dans GitLab 18.10 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `ai_catalog_project_level_enablement`. Activé par défaut sur GitLab.com, GitLab Self-Managed et GitLab Dedicated.
- Disponible sur l’édition Gratuite sur GitLab.com avec des GitLab Credits dans GitLab 18.10.
- Le feature flag `ai_catalog_project_level_enablement` supprimé dans GitLab 18.11.

{{< /history >}}

Les agents utilisent l'IA pour effectuer des tâches et répondre à des questions complexes. Créez des agents personnalisés pour accomplir des tâches spécifiques, comme la création de merge requests ou la revue de code. Vous pouvez également utiliser le catalogue d'IA pour découvrir des agents créés par GitLab.

Lorsque vous êtes prêt à interagir avec un agent, activez-le et commencez à l'utiliser avec GitLab Duo Chat dans l'interface GitLab, VS Code et les IDE JetBrains.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../_index.md#prerequisites).
- Avoir les [agents personnalisés activés](#turn-custom-agents-on-or-off).

## Visibilité des agents {#agent-visibility}

{{< history >}}

- Les rôles pouvant consulter les agents privés ont été [étendus](https://gitlab.com/gitlab-org/gitlab/-/work_items/582507) dans GitLab 18.7.

{{< /history >}}

Lorsque vous créez un agent personnalisé, vous sélectionnez un projet pour le gérer et choisissez si l'agent est public ou privé.

Agents publics :

- Peuvent être consultés par n'importe qui et peuvent être activés dans tout projet répondant aux prérequis.

Agents privés :

- Ne peuvent être consultés que par les membres du projet de gestion disposant du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner.
- Ne peuvent pas être activés dans des projets autres que le projet de gestion.

Vous ne pouvez pas rendre un agent public privé si l'agent est actuellement activé.

## Afficher les agents de votre projet {#view-the-agents-for-your-project}

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour afficher la liste des agents associés à votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Agents**.
   - Pour afficher les agents activés dans le projet, sélectionnez l'onglet **Activé**.
   - Pour afficher les agents gérés par le projet, sélectionnez l'onglet **Gérés**.

Sélectionnez un agent pour afficher ses détails.

## Créer un agent {#create-an-agent}

Vous pouvez créer un agent à partir d'un projet ou en utilisant le catalogue d'IA.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

{{< tabs >}}

{{< tab title="Depuis un projet" >}}

Pour créer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Agents**.
1. Sélectionnez **Nouvel agent**.
1. Sous **Informations de base** :
   1. Dans **Nom affiché**, saisissez un nom pour l'agent.
   1. Dans **Description**, saisissez une description pour l'agent.
1. Sous **Visibilité et accès**, pour **Visibilité**, sélectionnez **Privé** ou **Public**.
1. Sous **Prompts**, dans **Invite système**, saisissez un prompt système pour définir la personnalité, l'expertise et le comportement de l'agent.
1. Facultatif. Sous **Available tools**, dans la liste déroulante **Outils**, sélectionnez les outils auxquels l'agent peut accéder. Par exemple, pour que l'agent crée des tickets automatiquement, sélectionnez **Créer un ticket**.

   > [!note]
   > Certains outils nécessitent l'extension IDE et ne sont pas disponibles dans l'interface web. Pour plus d'informations, consultez la liste des [outils d'agent](tools.md).
1. Sélectionnez **Créer un agent**.

{{< /tab >}}

{{< tab title="Depuis le catalogue d'IA" >}}

Pour créer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** > **Explorer**.
1. Sélectionnez **Catalogue d'IA**, puis sélectionnez l'onglet **Agents**.
1. Sélectionnez **Nouvel agent**.
1. Sous **Informations de base** :
   1. Dans **Nom affiché**, saisissez un nom pour l'agent.
   1. Dans **Description**, saisissez une description pour l'agent.
1. Sous **Visibilité et accès** :
   1. Dans la liste déroulante **Géré par**, sélectionnez un projet pour l'agent.
   1. Pour **Visibilité**, sélectionnez **Privé** ou **Public**.
1. Sous **Prompts**, dans **Invite système**, saisissez un prompt système pour définir la personnalité, l'expertise et le comportement de l'agent.
1. Facultatif. Sous **Available tools**, dans la liste déroulante **Outils**, sélectionnez les outils auxquels l'agent peut accéder. Par exemple, pour que l'agent crée des tickets automatiquement, sélectionnez **Créer un ticket**.

   Pour obtenir la liste des outils disponibles, consultez les [définitions des outils intégrés](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ai/catalog/built_in_tool_definitions.rb).
1. Sélectionnez **Créer un agent**.

{{< /tab >}}

{{< /tabs >}}

L'agent apparaît dans le catalogue d'IA. Pour utiliser l'agent avec Chat, vous devez l'activer.

## Activer un agent {#enable-an-agent}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/600526) de l'activation d'un agent public pour plusieurs projets dans GitLab 19.2 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `ai_catalog_bulk_item_consumer_create`. Activé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Activez un agent pour l'utiliser avec Chat.

Lorsque vous activez un agent dans un projet, il est simultanément activé dans le groupe principal de ce projet.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

{{< tabs >}}

{{< tab title="Depuis le projet gérant" >}}

Pour activer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Agents**.
1. Sélectionnez l'onglet **Gérés**, puis sélectionnez l'agent que vous souhaitez activer.
1. Dans le coin supérieur droit, sélectionnez **Activer**.
1. Sous **Projet**, sélectionnez le projet dans lequel vous souhaitez activer l'agent.
1. Sélectionnez **Activer**.

{{< /tab >}}

{{< tab title="Depuis le catalogue d'IA" >}}

Pour activer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** > **Explorer**.
1. Sélectionnez **Catalogue d'IA**, puis sélectionnez l'onglet **Agents**.
1. Sélectionnez l'agent que vous souhaitez activer.
1. Dans le coin supérieur droit, sélectionnez **Activer**.
1. Sous **Projet**, sélectionnez le projet dans lequel vous souhaitez activer l'agent.

   Pour activer un agent public dans plusieurs projets, dans la liste déroulante **Projet**, sélectionnez les projets concernés. Vous pouvez sélectionner jusqu'à 100 projets.

1. Sélectionnez **Activer**.

{{< /tab >}}

{{< /tabs >}}

L'agent apparaît dans les pages **IA** > **Agents** du groupe et du projet. Les membres de tout projet du groupe principal peuvent désormais activer l'agent dans leur projet.

Dans le projet, vous pouvez démarrer une nouvelle discussion avec l'agent. Pour plus d'informations, consultez [sélectionner un agent](../../gitlab_duo_chat/agentic_chat.md#select-an-agent).

### Activer dans un projet {#enable-in-a-project}

Si un agent est déjà activé dans un groupe principal, vous pouvez l'activer dans les projets du groupe.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.
- L'agent doit être activé dans le groupe principal du projet.

Pour activer un agent dans un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Agents**.
1. Dans le coin supérieur droit, sélectionnez **Enable agent from group**.
1. Dans la liste déroulante, sélectionnez l'agent que vous souhaitez activer.
1. Sélectionnez **Activer**.

L'agent apparaît dans la page **IA** > **Agents** du projet.

Dans le projet, vous pouvez démarrer une nouvelle discussion avec l'agent.

## Utiliser un agent {#use-an-agent}

Vous pouvez utiliser un agent personnalisé dans l'interface GitLab, VS Code et les IDE JetBrains.

### Dans l'interface GitLab {#in-the-gitlab-ui}

Prérequis :

- Activez l'agent dans le projet dans lequel vous souhaitez l'utiliser.

Pour utiliser un agent personnalisé dans l'interface GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet ou groupe.
1. Ouvrez un ticket, un epic ou une merge request.
1. Dans la barre latérale GitLab Duo, sélectionnez **Ajouter une discussion** ({{< icon name="pencil-square" >}}).
1. Dans la liste déroulante, sélectionnez l'agent personnalisé.

   Une conversation Chat s'ouvre dans la barre latérale GitLab Duo située à droite de l'écran.
1. Saisissez votre question ou votre demande.

### Dans VS Code {#in-vs-code}

Prérequis :

- Activez l'agent dans le projet dans lequel vous souhaitez l'utiliser.
- Installez et configurez [GitLab pour VS Code](../../../editor_extensions/visual_studio_code/setup.md) version 6.47.0 ou ultérieure.
- Définir un [espace de nommage GitLab Duo par défaut](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Pour utiliser un agent personnalisé dans VS Code :

1. Dans VS Code, dans la barre latérale gauche, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Sélectionnez l'onglet **Chat**.
1. Dans la liste déroulante **Nouvelle discussion** ({{< icon name="duo-chat-new" >}}), sélectionnez l'agent personnalisé.
1. Saisissez votre question ou votre demande.

### Dans les IDE JetBrains {#in-jetbrains-ides}

Prérequis :

- Activez l'agent dans le projet dans lequel vous souhaitez l'utiliser.
- Installez et configurez le [plugin GitLab Duo pour les IDE JetBrains](../../../editor_extensions/jetbrains_ide/setup.md) version 3.19.0 ou ultérieure.
- Définir un [espace de nommage GitLab Duo par défaut](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Tout d'abord, activez la GitLab Duo Agent Platform :

1. Dans votre IDE JetBrains, accédez à **Paramètres** > **Outils** > **GitLab Duo**.
1. Sous **GitLab Duo Agent Platform**, cochez la case **Activer GitLab Duo Agent Platform**.
1. Redémarrez votre IDE si vous y êtes invité.

Ensuite, pour utiliser un agent personnalisé :

1. Dans votre IDE JetBrains, dans la barre d'outils de droite, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Sélectionnez l'onglet **Chat**.
1. Dans la liste déroulante **Nouvelle discussion** ({{< icon name="duo-chat-new" >}}), sélectionnez l'agent personnalisé.
1. Saisissez votre question ou votre demande.

## Désactiver un agent {#disable-an-agent}

Prérequis :

- Pour les groupes, vous devez avoir le rôle Maintainer ou Owner.
- Pour les projets, vous devez avoir le rôle Maintainer ou Owner.

Pour désactiver un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Agents**.
1. Trouvez l'agent que vous souhaitez supprimer et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Désactiver**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Désactiver**.

L'agent n'apparaît plus dans le projet et n'est plus disponible dans Chat.

## Dupliquer un agent {#duplicate-an-agent}

Pour apporter des modifications à un agent sans écraser l'original, créez une copie d'un agent existant.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour dupliquer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** > **Explorer**.
1. Sélectionnez **Catalogue d'IA**, puis sélectionnez l'onglet **Agents**.
1. Sélectionnez l'agent que vous souhaitez dupliquer.
1. Dans le coin supérieur droit, sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Dupliquer**.
1. Facultatif. Modifiez les champs que vous souhaitez changer.
1. Sélectionnez **Créer un agent**.

## Modifier un agent {#edit-an-agent}

Modifiez un agent pour changer sa configuration.

Prérequis :

- Vous devez être membre du projet gérant et avoir le rôle Maintainer ou Owner.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Agents**.
1. Sélectionnez l'agent que vous souhaitez modifier.
1. Dans le coin supérieur droit, sélectionnez **Éditer**.
1. Modifiez les champs que vous souhaitez changer, puis sélectionnez **Sauvegarder les modifications**.

## Masquer un agent {#hide-an-agent}

Masquez un agent pour le retirer du catalogue d'IA.

Une fois un agent masqué, les utilisateurs ne peuvent plus l'activer. Ils peuvent toutefois continuer à interagir avec l'agent dans les groupes et les projets dans lesquels il est déjà activé.

Prérequis :

- Vous devez être membre du projet gérant et avoir le rôle Maintainer ou Owner.

Pour masquer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Agents**.
1. Trouvez l'agent que vous souhaitez masquer et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Masquer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Confirmer**.

## Supprimer un agent {#delete-an-agent}

Supprimez un agent pour le retirer définitivement de l'instance.

Prérequis :

- Être administrateur.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre projet.
1. Sélectionnez **IA** > **Agents**.
1. Trouvez l'agent que vous souhaitez supprimer et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer**.

## Activer ou désactiver les agents personnalisés {#turn-custom-agents-on-or-off}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0.

{{< /history >}}

Par défaut, les agents personnalisés sont activés. Vous pouvez les activer ou les désactiver pour un groupe principal ou pour une instance.

Lorsque les agents personnalisés sont désactivés :

- Les utilisateurs ne peuvent pas créer, activer, désactiver ni exécuter d'agents personnalisés.
- Les agents personnalisés existants ne sont plus visibles dans le projet sous **IA** > **Agents** > **Activé**.
- Les agents personnalisés créés dans le projet apparaissent sous **IA** > **Agents** > **Gérés**, mais ne peuvent pas être exécutés.
- Les [agents par défaut](foundational_agents/_index.md) et les [agents externes](external.md) restent disponibles.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Agents et flux personnalisés et externes**, cochez ou décochez la case **Autoriser les agents personnalisés**.
1. Sélectionnez **Enregistrer les modifications**.

Ce paramètre s'applique en cascade à tous les sous-groupes du groupe.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Être administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Agents et flux personnalisés et externes**, cochez ou décochez la case **Autoriser les agents personnalisés**.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque le paramètre au niveau de l'instance est désactivé, les paramètres au niveau du groupe ne peuvent pas le remplacer.

{{< /tab >}}

{{< /tabs >}}
