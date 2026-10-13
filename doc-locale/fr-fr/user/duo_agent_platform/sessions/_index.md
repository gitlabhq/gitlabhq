---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Affichez et gérez le statut et les données d'exécution des agents et flows que vous avez exécutés."
title: Sessions
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les sessions affichent le statut et les données d'exécution des agents et flows que vous avez exécutés.

Les sessions sont créées par GitLab Duo Agentic Chat et les flows par défaut dans l'IDE ou l'interface utilisateur. Voici quelques exemples :

- Les flows exécutés sur un runner, comme le [flow Fix CI/CD Pipeline](../flows/foundational_flows/fix_pipeline.md). Ces sessions sont visibles dans l'interface utilisateur sous **IA** > **Sessions**.
- Les flows qui s'exécutent dans l'IDE, comme le [flow Software Development](../flows/foundational_flows/software_development.md). Ces sessions sont visibles dans l'IDE, dans l'onglet **Flux**, sous **Sessions**.
- Sessions créées par GitLab Duo Chat. Ces sessions sont visibles dans la barre latérale droite en sélectionnant **Historique GitLab Duo Chat**.
- Les flows invoqués par des déclencheurs. Ces sessions sont visibles dans l'interface utilisateur sous **IA** > **Sessions**.

## Afficher les sessions de votre projet {#view-sessions-for-your-project}

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour afficher les sessions de votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Sessions**.
1. Sélectionnez une session pour afficher plus de détails.

## Afficher les sessions que vous avez déclenchées {#view-sessions-youve-triggered}

Pour afficher les sessions que vous avez déclenchées :

1. Dans la barre latérale droite, sélectionnez **Sessions GitLab Duo**.
1. Sélectionnez une session pour afficher plus de détails.
1. Facultatif. Filtrez les détails pour afficher tous les journaux ou uniquement un sous-ensemble concis.

## Sessions GitLab Duo Agentic Chat {#gitlab-duo-agentic-chat-sessions}

Les chats étant interactifs, ils nécessitent une séparation plus claire dans l'interface utilisateur. Vous pouvez considérer l'historique des chats comme une vue filtrée des sessions existant exclusivement pour les chats.

Pour parcourir et changer de session de chat dans le CLI GitLab Duo, consultez [changer de session](../../gitlab_duo_cli/use.md#switch-sessions).

## Annuler une session en cours {#cancel-a-running-session}

Vous pouvez annuler une session en cours d'exécution ou en attente d'une entrée. Pour annuler une session :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **IA** > **Sessions**.
1. Dans l'onglet **Détails**, faites défiler jusqu'en bas.
1. Sélectionnez **Annuler la session**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Annuler la session** pour confirmer.

Après l'annulation :

- Le statut de la session passe à **Arrêté(e)**.
- La session ne peut pas être reprise ni redémarrée.

## Examiner et contrôler les actions de l'agent {#review-and-control-agent-actions}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Votre flow personnalisé doit inclure un [`HumanInputComponent`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md#humaninputcomponent) dans son YAML de définition de flow.

Lorsqu'un flow atteint un point de contrôle d'interaction humaine, l'exécution se met en pause et la session attend votre entrée.

### Notifications d'approbation {#approval-notifications}

Lorsqu'un flow se met en pause à un point de contrôle, GitLab vous notifie de deux façons :

- **Élément de la liste de tâches** : un élément de la liste de tâches intitulé **Approbation de Duo Workflow requise** est ajouté à **Votre travail** > **Liste des pense-bêtes**. L'élément renvoie directement à la session dans laquelle vous pouvez agir. GitLab marque automatiquement l'élément de la liste de tâches comme terminé lorsque vous approuvez, rejetez ou modifiez la demande, ou lorsque le workflow est annulé ou arrêté.
- **E-mail** : une notification par e-mail est envoyée avec le nom du workflow, le projet auquel il appartient, un récapitulatif des actions effectuées et de la demande en attente, ainsi qu'un lien direct vers l'interface d'approbation.

### Répondre à un point de contrôle d'agent {#respond-to-an-agent-checkpoint}

Pour examiner et répondre à un point de contrôle d'agent :

1. Dans la barre latérale GitLab Duo, sélectionnez **Sessions**.
1. Sélectionnez la session en attente de votre examen.
1. Examinez les actions effectuées par l'agent et ses prochaines étapes proposées.
1. Sélectionnez l'une des options suivantes :
   - **Approuver** : permettre à l'agent de poursuivre avec ses actions planifiées.
   - **Rejeter** : arrêter immédiatement l'exécution du flow.
   - **Modifier** : envoyer un retour d'information ou une suggestion à l'agent. L'agent retourne au point de contrôle pour un nouvel examen.

## Rétention des sessions {#session-retention}

Les sessions sont automatiquement supprimées 30 jours après la dernière activité. La période de rétention est réinitialisée à chaque fois que vous interagissez avec la session. Par exemple, si vous interagissez avec une session tous les 20 jours, elle ne sera jamais supprimée automatiquement.

Dans l'IDE, vous pouvez également supprimer manuellement des sessions avant l'expiration de la période de rétention de 30 jours.
