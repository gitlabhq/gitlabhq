---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez GitLab Duo Agentic Chat pour répondre à des questions complexes et créer ou modifier des fichiers de manière autonome.
title: GitLab Duo Agentic Chat
---

{{< details >}}

- Niveau : [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../duo_agent_platform/model_selection.md#default-models)
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- VS Code [introduit sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917) dans GitLab 18.1 en tant qu'[expérience](../../policy/development_stages_support.md) avec un [flag](../../administration/feature_flags/_index.md) nommé `duo_agentic_chat`. Désactivé par défaut.
- VS Code [activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688) dans GitLab 18.2.
- Interface GitLab UI [introduite sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/546140) dans GitLab 18.2 [avec les flags](../../administration/feature_flags/_index.md) nommés `duo_workflow_workhorse` et `duo_workflow_web_chat_mutation_tools`. Les deux flags sont activés par défaut.
- Le feature flag `duo_agentic_chat` est activé par défaut dans GitLab 18.2.
- Les JetBrains IDEs [introduits](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077) dans GitLab 18.2.
- Passage en bêta dans GitLab 18.2.
- Visual Studio pour Windows [introduit](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245) dans GitLab 18.3.
- [Ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) à GitLab Duo Core dans GitLab 18.3.
- Les feature flags `duo_workflow_workhorse` et `duo_workflow_web_chat_mutation_tools` [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487) dans GitLab 18.4.
- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/19213) de GitLab Duo Agent Platform sur GitLab Self-Managed (à la fois avec des [modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md) et des modèles GitLab connectés au cloud) dans GitLab 18.4 en tant qu'[expérience](../../policy/development_stages_support.md#experiment) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `self_hosted_agent_platform`. Désactivé par défaut.
- GitLab Duo Agent Platform sur GitLab Self-Managed est passé d'expérience à [bêta](https://gitlab.com/groups/gitlab-org/-/epics/19402) dans GitLab 18.5.
- [Mise à jour du LLM par défaut](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541) vers Claude Sonnet 4.5 dans GitLab 18.6.
- Le feature flag `self_hosted_agent_platform` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951) dans GitLab 18.7.
- [Mise à jour du LLM par défaut](https://gitlab.com/groups/gitlab-org/-/epics/19998) vers Claude Haiku 4.5 dans GitLab 18.7.
- [Disponible en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/581872) dans GitLab 18.8 avec des [flags](../../administration/feature_flags/_index.md) nommés `agentic_chat_ga` et `ai_duo_agent_platform_ga_rollout_self_managed`. Les deux flags sont activés par défaut. Le feature flag `duo_agentic_chat` est supprimé.
- Les feature flags [`self_hosted_agent_platform`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589), [`agentic_chat_ga`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219679) et [`ai_duo_agent_platform_ga_rollout_self_managed`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219679) sont supprimés dans GitLab 18.10.
- Disponible sur le niveau Free sur GitLab.com avec GitLab Credits dans GitLab 18.10.

{{< /history >}}

GitLab Duo Agentic Chat est une version améliorée de GitLab Duo Non-Agentic Chat. Ce nouveau Chat peut effectuer des actions de manière autonome en votre nom, pour vous aider à répondre aux questions complexes de façon plus complète.

Tandis que le Chat non-agentique répond aux questions en fonction d'un seul contexte, le Chat agentique recherche, récupère et combine des informations provenant de plusieurs sources dans vos projets GitLab pour fournir des réponses plus complètes et pertinentes.

Le Chat agentique peut :

- Rechercher dans les projets pour trouver des tickets, des merge requests et d'autres artefacts pertinents à l'aide d'une recherche par mots-clés (pas une recherche sémantique).
- Accéder aux fichiers de votre projet local sans spécifier manuellement les chemins de fichiers.
- Créer et modifier des fichiers à plusieurs endroits.
- Récupérer des ressources telles que des tickets, des merge requests et des pipelines CI/CD.
- Analyser plusieurs sources pour fournir des réponses complètes. Utilisez le [Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md) pour vous connecter à des sources de données et des outils externes.
- Fournir des réponses personnalisées en utilisant vos règles personnalisées.
- Créer des commits, lorsque vous utilisez le Chat dans l'interface GitLab UI.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [GitLab Duo Chat (agentique)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ).
<!-- Video published on 2025-06-02 -->

## Utiliser GitLab Duo Chat {#use-gitlab-duo-chat}

Vous pouvez utiliser GitLab Duo Chat dans :

- L'interface GitLab UI.
- VS Code.
- Un JetBrains IDE.
- Visual Studio pour Windows.

### Utiliser GitLab Duo Chat dans l'interface GitLab UI {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- La capacité du Chat à mémoriser votre conversation la plus récente a été [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653) dans GitLab 18.4.
- Nouvelle navigation et barre latérale GitLab Duo introduites sur GitLab.com dans GitLab 18.6 avec un [flag](../../administration/feature_flags/_index.md) nommé `paneled_view`. Activé(e) par défaut.
- Instructions de navigation précédentes supprimées dans GitLab 18.7.
- Nouvelle navigation et barre latérale GitLab Duo [généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049) dans GitLab 18.8. Le feature flag `paneled_view` est supprimé.

{{< /history >}}

Prérequis :

- Remplir les [prérequis de GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- Définir un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Pour utiliser le Chat dans l'interface GitLab UI :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale GitLab Duo, sélectionnez **Ajouter une discussion** ({{< icon name="pencil-square" >}}) ou **GitLab Duo Chat actuel** ({{< icon name="duo-chat" >}}).

   Si vous avez sélectionné une nouvelle discussion, dans la liste déroulante, sélectionnez un agent.

   Une conversation Chat s'ouvre dans la barre latérale GitLab Duo sur le côté droit de votre écran.
1. Sous la zone de texte du chat, vérifiez que le bouton bascule **Agentique** est activé.
1. Saisissez votre question dans la zone de texte du chat et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.
   - Vous pouvez fournir un [contexte](../duo_agent_platform/context.md#gitlab-duo-agentic-chat) supplémentaire pour votre chat.
   - Il peut falloir quelques secondes pour que le chat AI interactif produise une réponse.
1. Facultatif. Vous pouvez :
   - Poser une question de suivi.
   - Démarrer [une autre conversation](#have-multiple-conversations).

Si vous rechargez la page Web sur laquelle vous vous trouvez, ou si vous accédez à une autre page Web, le Chat mémorise votre conversation la plus récente, et cette conversation est toujours active dans le tiroir Chat.

### Utiliser GitLab Duo Chat dans VS Code {#use-gitlab-duo-chat-in-vs-code}

Prérequis :

- [Installer et configurer l'extension GitLab pour VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.15.1 ou ultérieure.
- Remplir les [prérequis de GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- Définir un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Activer GitLab Duo Chat :

1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Sélectionnez **Extensions** > **GitLab** > **GitLab Duo**.
1. Sous **GitLab › Duo Agent Platform : Activé**, cochez la case **Activer GitLab Duo Agent Platform**.

Ensuite, pour utiliser GitLab Duo Chat :

1. Dans la barre latérale gauche, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Sélectionnez l'onglet **Chat**.
1. Sélectionnez **Actualiser la page** si vous y êtes invité.
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

### Utiliser GitLab Duo Chat dans les JetBrains IDEs {#use-gitlab-duo-chat-in-jetbrains-ides}

Prérequis :

- [Installer et configurer le plugin GitLab Duo pour JetBrains IDEs](../../editor_extensions/jetbrains_ide/setup.md) version 3.11.1 ou ultérieure.
- Remplir les [prérequis de GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- Définir un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Activer GitLab Duo Chat :

1. Dans votre JetBrains IDE, accédez à **Paramètres** > **Outils** > **GitLab Duo**.
1. Sous **GitLab Duo Agent Platform**, cochez la case **Activer GitLab Duo Agent Platform**.
1. Redémarrez votre IDE si vous y êtes invité.

Ensuite, pour utiliser GitLab Duo Chat :

1. Dans la barre d'outils de la fenêtre de droite, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Sélectionnez l'onglet **Chat**.
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

### Utiliser GitLab Duo Chat dans Visual Studio {#use-gitlab-duo-chat-in-visual-studio}

Prérequis :

- Installer et configurer l'[extension GitLab pour Visual Studio](../../editor_extensions/visual_studio/setup.md) version 0.60.0 ou ultérieure.
- Remplir les [prérequis de GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- Définir un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Activer GitLab Duo Chat :

1. Dans Visual Studio, accédez à **Outils** > **Options** > **GitLab**.
1. Sous **GitLab**, sélectionnez **Général**.
1. Pour **Activer Agentic Duo Chat**, sélectionnez **Vrai**, puis **OK**.

Ensuite, pour utiliser GitLab Duo Chat :

1. Sélectionnez **Extensions** > **GitLab** > **Ouvrir Agentic Chat**.
1. Dans la zone de message, saisissez votre question et appuyez sur **Entrée**.

## Afficher l'historique du chat {#view-the-chat-history}

{{< history >}}

- Historique du chat [introduit](https://gitlab.com/groups/gitlab-org/-/epics/17922) sur les IDEs dans GitLab 18.2.
- [Ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/556875) pour l'interface GitLab UI dans GitLab 18.3.

{{< /history >}}

Pour afficher votre historique de chat :

- Dans l'interface GitLab UI, dans la barre latérale GitLab Duo, sélectionnez **Historique GitLab Duo Chat** ({{< icon name="history" >}}).

- Dans votre IDE, dans le coin supérieur droit de la zone de message, sélectionnez **Historique de discussion** ({{< icon name="history" >}}).

Dans l'interface GitLab UI, toutes les conversations de votre historique de chat sont visibles.

Dans votre IDE, les 20 dernières conversations sont visibles. [L'issue 1308](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308) propose de modifier cela.

## Avoir plusieurs conversations {#have-multiple-conversations}

{{< history >}}

- Conversations multiples [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/556875) dans GitLab 18.3.
- La capacité de recherche dans l'historique de chat de l'interface GitLab UI [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/582513) dans GitLab 18.9.

{{< /history >}}

Vous pouvez avoir un nombre illimité de conversations simultanées avec GitLab Duo Chat.

Vos conversations se synchronisent entre GitLab Duo Chat dans l'interface GitLab UI et votre IDE.

1. Ouvrez GitLab Duo Chat dans l'interface GitLab UI ou votre IDE.
1. Saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.
1. Créer une nouvelle conversation Chat :

   - Dans l'interface GitLab UI, vous pouvez effectuer l'une des opérations suivantes :

     - Pour créer une nouvelle conversation avec un agent spécifique :
       1. Dans la barre latérale GitLab Duo, sélectionnez **Ajouter une discussion** ({{< icon name="pencil-square" >}}).
       1. Dans la liste déroulante, sélectionnez un agent.
     - Pour créer une nouvelle conversation avec le même agent que la conversation existante, dans la zone de message, saisissez `/new` et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

     Une nouvelle conversation Chat remplace la conversation existante.
   - Sous la zone de texte Chat, vérifiez que le bouton bascule **Agentique** est activé.
   - Dans votre IDE, dans le coin supérieur droit de la zone de message, sélectionnez **Nouvelle discussion** ({{< icon name="plus" >}}).
1. Saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.
1. Pour afficher toutes vos conversations, consultez votre [historique de chat](#view-the-chat-history).
1. Pour basculer entre les conversations, dans votre historique de chat, sélectionnez la conversation appropriée.
1. Pour rechercher une conversation spécifique dans l'historique de chat :
   - Interface GitLab UI :  Dans la zone de texte **Rechercher un fil de discussion**, saisissez votre terme de recherche.
   - IDE : Dans la zone de texte **Rechercher dans les discussions**, saisissez votre terme de recherche.

En raison des limites de la fenêtre de contexte du LLM, les conversations sont tronquées à 200 000 tokens (environ 800 000 caractères) chacune.

## Supprimer une conversation {#delete-a-conversation}

{{< history >}}

- La possibilité de supprimer une conversation a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/545289) dans GitLab 18.2.

{{< /history >}}

1. Dans l'interface GitLab UI ou votre IDE, sélectionnez l'[historique de chat](#view-the-chat-history).
1. Dans l'historique, sélectionnez **Supprimer cette discussion** ({{< icon name="remove" >}}).

Les conversations individuelles expirent et sont automatiquement supprimées après 30 jours d'inactivité.

## Personnaliser GitLab Duo Chat dans votre environnement local {#customize-gitlab-duo-chat-in-your-local-environment}

Personnalisez le comportement de GitLab Duo Chat dans votre environnement local en fournissant des instructions qui reflètent votre style de codage, les pratiques de votre équipe et les exigences de votre projet.

GitLab Duo Chat prend en charge deux approches :

- [Règles personnalisées](../duo_agent_platform/customize/custom_rules.md) dans `chat-rules.md` :  Pour GitLab uniquement. Idéal pour les préférences personnelles et les normes d'équipe.
- [Règles partagées dans `AGENTS.md`](../duo_agent_platform/customize/agents_md.md) : Pour GitLab et d'autres outils d'IA prenant en charge la spécification `AGENTS.md`. Idéal pour le contexte de projet, l'organisation des monorepos et les conventions spécifiques aux répertoires.

Vous pouvez utiliser les deux fichiers simultanément. GitLab Duo Chat applique les instructions de tous les fichiers de règles disponibles.

Apprenez-en davantage sur la façon de [personnaliser GitLab Duo](../duo_agent_platform/customize/_index.md).

## Sélectionner un modèle {#select-a-model}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19251) dans GitLab 18.4 en tant que fonctionnalité [bêta](../../policy/development_stages_support.md#beta) avec un [flag](../../administration/feature_flags/_index.md) appelé `ai_user_model_switching`. Désactivé par défaut.
- [Activé](https://gitlab.com/gitlab-org/gitlab/-/issues/560319) dans GitLab 18.4.
- [Disponible sur GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/19344) dans GitLab 18.6.
- [Ajouté](https://gitlab.com/groups/gitlab-org/-/epics/19345) à VS Code et aux JetBrains IDEs dans GitLab 18.6.
- Le feature flag `ai_user_model_switching` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214042) dans GitLab 18.7.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/569140) dans GitLab 18.8.

{{< /history >}}

Lorsque vous utilisez le Chat dans l'interface GitLab UI, VS Code ou un JetBrains IDE, vous pouvez sélectionner le modèle à utiliser pour les conversations.

Si vous ouvrez un chat précédent depuis l'historique de chat et continuez cette conversation, le Chat utilise le modèle que vous avez précédemment sélectionné.

Si vous sélectionnez un nouveau modèle dans une conversation existante, le Chat crée une nouvelle conversation.

Prérequis :

{{< tabs >}}

{{< tab title=GitLab.com >}}

- Le propriétaire du groupe principal n'a pas sélectionné de modèle pour GitLab Duo Agent Platform. Si un [modèle a été sélectionné pour le groupe](../gitlab_duo/model_selection.md), vous ne pouvez pas modifier le modèle pour le Chat.
- Vous devez utiliser le Chat dans le groupe principal. Vous ne pouvez pas modifier le modèle si vous accédez au Chat dans l'organisation.

{{< /tab >}}

{{< tab title="Self-managed" >}}

- L'administrateur n'a pas sélectionné de modèle pour l'instance. Si un modèle a été sélectionné pour l'instance, vous ne pouvez pas modifier le modèle pour le Chat.
- Votre instance doit être connectée à la GitLab AI Gateway.

{{< /tab >}}

{{< /tabs >}}

Pour sélectionner un modèle :

- Dans l'interface GitLab UI :
  1. Sous la zone de texte du chat, vérifiez que le bouton bascule **Agentique** est activé.
  1. Sélectionnez un modèle dans la liste déroulante.
- Dans votre IDE :
  1. Dans la barre latérale, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
  1. Sélectionnez l'onglet **Chat**.
  1. Sélectionnez un modèle dans la liste déroulante.

## Sélectionner un agent {#select-an-agent}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/562708) dans GitLab 18.4.
- [Ajouté](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2196) à VS Code et aux JetBrains IDEs dans GitLab 18.5.

{{< /history >}}

Lorsque vous utilisez le Chat dans un projet dans l'interface GitLab UI, VS Code ou un JetBrains IDE, vous pouvez sélectionner un agent spécifique pour le Chat.

Prérequis :

- Dans votre projet, [un agent du catalogue d'IA doit être activé](../duo_agent_platform/agents/custom.md#enable-an-agent).
- Vous devez être membre du projet dans lequel l'agent est activé.
- Pour VS Code, [installez et configurez l'extension GitLab pour VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.49.12 ou ultérieure.
- Pour un JetBrains IDE, [installez et configurez le plugin GitLab Duo pour JetBrains IDEs](../../editor_extensions/jetbrains_ide/setup.md) version 3.22.0 ou ultérieure.

Pour sélectionner un agent :

1. Dans l'interface GitLab UI ou votre IDE, ouvrez une nouvelle conversation dans GitLab Duo Chat.
1. Dans l'interface GitLab UI, sous la zone de texte Chat, vérifiez que le bouton bascule **Agentique** est activé.
1. Dans la liste déroulante, sélectionnez un agent. Si vous n'avez configuré aucun agent, il n'y a pas de liste déroulante et le Chat utilise l'agent GitLab Duo par défaut.
1. Saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

Après avoir créé une conversation avec un agent :

- La conversation mémorise l'agent que vous avez sélectionné. Vous ne pouvez pas sélectionner un agent différent pour cette conversation.
- Si vous utilisez l'historique de chat pour revenir à la même conversation, celle-ci utilise le même agent.
- Si vous revenez à une conversation et que l'agent associé n'est plus disponible, vous ne pouvez pas continuer cette conversation.

## Mise en cache des prompts {#prompt-caching}

{{< history >}}

- Introduit dans GitLab 18.7.

{{< /history >}}

La mise en cache des prompts est activée par défaut et ne fonctionne que lorsque le modèle Chat agentique sélectionné est d'Anthropic ou est un modèle Anthropic servi via Vertex.

Lorsque la mise en cache des prompts est activée, les données des prompts de chat sont temporairement stockées en mémoire par le fournisseur du modèle.

La mise en cache des prompts améliore considérablement la latence en évitant le retraitement des données de prompt et d'entrée mises en cache.

Vous pouvez [désactiver la mise en cache des prompts](../gitlab_duo/data_usage.md#turn-off-prompt-caching) :

- Sur GitLab.com : Pour un groupe principal.
- Sur GitLab Self-Managed : Pour une instance.

Ce paramètre s'applique à toutes les fonctionnalités de GitLab Duo Agent Platform.

## Approbations d'outils {#tool-approvals}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/20519) dans GitLab 19.0
  - Introduit dans [GitLab for VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.72.0) 6.72.0
  - Introduit dans [le plugin GitLab Duo pour JetBrains IDEs](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases/v3.33.0) 3.33.0
  - Introduit dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0.

{{< /history >}}

Avant que le Chat agentique puisse utiliser un outil en votre nom, il requiert votre approbation. Par défaut, chaque invocation d'outil requiert une approbation.

Si vous faites confiance à un outil et souhaitez simplifier votre flux de travail, vous pouvez l'approuver une seule fois pour toute la session.

Les approbations de session s'appliquent uniquement au Chat, pas aux flows.

### Gérer les approbations d'outils {#manage-tool-approvals}

Les propriétaires et les administrateurs peuvent contrôler si les utilisateurs peuvent approuver des outils pour une session. Les paramètres se propagent de l'instance au groupe, puis au projet.

Configurez l'une des options suivantes pour un groupe ou une instance :

- **Activé(e) par défaut** : Les utilisateurs peuvent approuver des outils une fois pour une session. Les groupes et sous-groupes peuvent désactiver cette option.
- **Désactivé(e) par défaut** : (par défaut) Les utilisateurs doivent approuver chaque invocation d'outil. Les groupes et sous-groupes peuvent activer cette option.
- **Toujours désactivée** : Les utilisateurs ne peuvent pas approuver des outils pour une session. Les groupes et sous-groupes ne peuvent pas remplacer ce paramètre.

#### Gérer les paramètres par défaut {#manage-default-settings}

Configurez le paramètre d'approbation d'outils par défaut pour votre instance ou votre groupe principal.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Le rôle Owner pour le groupe principal.

Pour configurer les paramètres d'approbation d'outils par défaut :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Dans la liste déroulante **Approbation des outils pour la session**, sélectionnez l'option de votre choix.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Accès administrateur.

Pour configurer les paramètres d'approbation d'outils par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Sélectionnez **GitLab Duo**.
1. Dans la liste déroulante **Approbation des outils pour la session**, sélectionnez l'option de votre choix.

{{< /tab >}}

{{< tab title="GitLab Dedicated" >}}

Prérequis :

- Accès administrateur.

Pour configurer les paramètres d'approbation d'outils par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Sélectionnez **GitLab Duo**.
1. Dans la liste déroulante **Approbation des outils pour la session**, sélectionnez l'option de votre choix.

{{< /tab >}}

{{< /tabs >}}

#### Gérer les paramètres de groupe ou de projet {#manage-group-or-project-settings}

Configurez les paramètres d'approbation d'outils pour un groupe ou un projet spécifique.

Prérequis :

- Le rôle Owner pour le groupe, ou le rôle Maintainer pour le projet.

Pour configurer les paramètres d'approbation d'outils :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe ou projet.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Pour les groupes, dans la liste déroulante **Approbation des outils pour la session**, sélectionnez votre option préférée.
1. Pour les projets, cochez ou décochez la case **Autoriser l'approbation des outils pour la session**.

### Approuver des outils dans votre environnement local {#approve-tools-in-your-local-environment}

Prérequis :

- Les approbations d'outils sont activées pour votre groupe ou instance.
- Pour GitLab Duo Chat dans votre environnement local, installez et configurez l'un des éléments suivants :
  - [GitLab for VS Code](../../editor_extensions/visual_studio_code/setup.md) 6.72.0 ou version ultérieure.
  - [Plugin GitLab Duo pour JetBrains IDEs](../../editor_extensions/jetbrains_ide/setup.md) 3.33.0 ou version ultérieure.
  - [GitLab Duo CLI](../gitlab_duo_cli/_index.md) 8.80.0 ou version ultérieure.

Pour approuver un outil pour votre session actuelle :

1. Lorsqu'une invite d'approbation d'outil apparaît, sélectionnez la liste déroulante à côté du bouton d'approbation.
1. Sélectionnez **Autoriser pour la session**.

L'approbation persiste pour le reste de la session Chat et est réinitialisée lorsque vous démarrez une nouvelle conversation.

## Comparaison des fonctionnalités du Chat {#chat-feature-comparison}

| Fonctionnalité                                              | GitLab Duo Non-Agentic Chat |                                                         GitLab Duo Agentic Chat                                                                                                           |
| ------------                                            |------|                                                         -------------                                                                                                          |
| Poser des questions générales de programmation |                       Oui  |                                                          Oui                                                                                                                   |
| Obtenir des réponses sur un fichier ouvert dans l'éditeur |     Oui  |                                                          Oui. Indiquez le chemin du fichier dans votre question.                                                                   |
| Fournir un contexte sur des fichiers spécifiés |                   Oui. Utilisez `/include` pour ajouter un fichier à la conversation. <sup>1</sup> |        Oui. Indiquez le chemin du fichier dans votre question.                                                                   |
| Rechercher de manière autonome dans le contenu du projet |                    Non |                                                            Oui                                                                                                                   |
| Créer et modifier des fichiers de manière autonome |              Non |                                                            Oui. Demandez-lui de modifier des fichiers. Notez qu'il peut écraser les modifications que vous avez apportées manuellement et que vous n'avez pas encore committées.  |
| Récupérer des tickets et des merge requests sans spécifier d'identifiants |          Non |                                                            Oui. Recherchez selon d'autres critères. Par exemple, le titre ou le responsable d'une merge request ou d'un ticket.                                       |
| Combiner des informations provenant de plusieurs sources |               Non |                                                            Oui                                                                                                                   |
| Analyser les journaux de pipeline |                                   Oui. Nécessite le module complémentaire GitLab Duo Enterprise. |                          Oui                                                                                                                   |
| Redémarrer une conversation |                                  Oui. Utilisez `/new` ou `/reset`. |                             Oui. Utilisez `/new` ou, si vous êtes dans l'interface, `/reset`.                                                                                       |
| Supprimer une conversation |                                   Oui, dans l'historique de chat.|                                             Oui, dans l'historique de chat                                                                                                            |
| Créer des tickets et des merge requests |                                   Non |                                                            Oui                                                                                                                   |
| Utiliser les commandes Git en lecture seule |                                                 Non |                                                            Oui                                                  |
| Utiliser les commandes Git en écriture |                                                 Non |                                                            Oui, interface uniquement                                                  |
| Exécuter des commandes Shell |                                      Non |                                                            Oui, IDEs uniquement                                                                                                        |
| Exécuter des outils MCP |                                      Non |                                                            Oui, IDEs uniquement                                                                                                          |
| Approuver des outils pour une session |                        Non |                                                            Oui, IDEs uniquement                                                                                                          |

**Notes de bas de page** :

1. Non disponible lors de l'utilisation de GitLab Duo Non-Agentic Chat dans le Web IDE.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec GitLab Duo Chat, vous pouvez rencontrer des problèmes.

Pour plus d'informations sur la résolution de ces problèmes, consultez [Dépannage](troubleshooting.md).

## Commentaires {#feedback}

Vos commentaires sont précieux pour nous aider à améliorer cette fonctionnalité. Partagez votre expérience dans [l'issue 542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198).

## Sujets connexes {#related-topics}

- [Blog : GitLab Duo Chat gets agentic AI makeover](https://about.gitlab.com/blog/gitlab-duo-chat-gets-agentic-ai-makeover/)
